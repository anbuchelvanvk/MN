import 'package:flutter_test/flutter_test.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/models/konar_book_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HR Login & Identity Resolution Tests', () {
    test('hr@mnj.com strictly resolves to Mohankumar G (ID: 7) and never Mithra M', () async {
      final eco = EcosystemProvider();

      // 1. Authenticate with hr@mnj.com credentials
      final detectedRole = await eco.loginWithFirebase(
        email: 'hr@mnj.com',
        password: 'test-password',
      );

      expect(detectedRole, 'hr');
      expect(eco.activeRole, 'hr');
      expect(eco.activeEmpId, '7');

      // 2. Verify currentEmployee is strictly Mohankumar G
      final emp = eco.currentEmployee;
      expect(emp.id, '7');
      expect(emp.name, contains('Mohankumar'));
      expect(emp.isHr, isTrue);
      expect(emp.isCeo, isFalse);
      expect(emp.role, contains('HR'));
      expect(emp.email, 'hr@mnj.com');

      // 3. Ensure Mithra M is NOT returned
      expect(emp.name.toLowerCase().contains('mithra'), isFalse);
      expect(emp.id == '33', isFalse);
    });

    test('currentEmployee fallback for HR role never returns Mithra M or first non-CEO', () async {
      final eco = EcosystemProvider();
      // Session state is only set once authentication completes
      await eco.loginWithFirebase(email: 'hr@mnj.com', password: 'test-password');
      final emp = eco.currentEmployee;

      expect(emp.name, contains('Mohankumar'));
      expect(emp.initials, 'MG');
      expect(emp.id, '7');
    });
  });

  group('Department Deletion & Workforce Reallocation Tests', () {
    test('Deleting department with reallocation moves employees and removes old dept', () async {
      final eco = EcosystemProvider();
      await eco.loginWithFirebase(email: 'ceoofmn@mnjpark.com', password: 'test-password');

      // Create a test department
      await eco.createNewDepartment('Boutique Operations');
      expect(eco.availableDepartments, contains('Boutique Operations'));

      // Allocate an employee to Boutique Operations
      final targetEmp = eco.employees.firstWhere((e) => e.id == '65');
      await eco.allocateEmployeeRole(
        empId: targetEmp.id,
        newRole: 'Boutique Associate',
        newDept: 'Boutique Operations',
      );

      final updatedEmp = eco.employees.firstWhere((e) => e.id == '65');
      expect(updatedEmp.dept, 'Boutique Operations');

      // Execute reallocation workflow: Delete 'Boutique Operations' and reallocate staff to 'Online Department'
      await eco.deleteDepartmentWithWorkflow(
        deptName: 'Boutique Operations',
        deleteEmployees: false,
        reallocateToDept: 'Online Department',
      );

      // Verify old department is completely gone from availableDepartments
      expect(eco.availableDepartments.contains('Boutique Operations'), isFalse);

      // Verify the employee's department was updated to 'Online Department'
      final reallocatedEmp = eco.employees.firstWhere((e) => e.id == '65');
      expect(reallocatedEmp.dept, 'Online Department');
    });

    test('Deleting department with deleteEmployees permanently purges employees and dept', () async {
      final eco = EcosystemProvider();
      await eco.loginWithFirebase(email: 'ceoofmn@mnjpark.com', password: 'test-password');

      // Create a temporary department
      await eco.createNewDepartment('Temporary Staging');
      expect(eco.availableDepartments, contains('Temporary Staging'));

      // Allocate staff
      await eco.allocateEmployeeRole(
        empId: '67',
        newRole: 'Staging Staff',
        newDept: 'Temporary Staging',
      );
      expect(eco.employees.firstWhere((e) => e.id == '67').dept, 'Temporary Staging');

      // Execute delete department along with employees
      await eco.deleteDepartmentWithWorkflow(
        deptName: 'Temporary Staging',
        deleteEmployees: true,
      );

      // Verify department is permanently removed
      expect(eco.availableDepartments.contains('Temporary Staging'), isFalse);
      expect(eco.employees.any((e) => e.id == '67'), isFalse);
    });
  });

  group('KONAR Book Visibility & Deletion Tests', () {
    test('KONAR Book visibility toggle works and defaults to true', () async {
      final eco = EcosystemProvider();
      final defaultBook = KonarBookModel.defaultOnlineDepartment();
      expect(defaultBook.isVisible, isTrue);

      // Toggle visibility to false
      await eco.toggleKonarBookVisibility(defaultBook.id, false);
      final book = eco.konarBooks.firstWhere((b) => b.id == defaultBook.id);
      expect(book.isVisible, isFalse);

      // Toggle back to true
      await eco.toggleKonarBookVisibility(defaultBook.id, true);
      final restoredBook = eco.konarBooks.firstWhere((b) => b.id == defaultBook.id);
      expect(restoredBook.isVisible, isTrue);
    });

    test('Deleting KONAR Book removes it from konarBooks directory', () async {
      final eco = EcosystemProvider();
      final bookToDelete = KonarBookModel(
        id: 'test_department',
        department: 'Test Department',
        departmentCode: 'TD',
        title: 'Test Department Book',
        description: 'Test manual',
        version: 'v1.0',
        lastUpdated: DateTime.now(),
        updatedByName: 'CEO',
        updatedByRole: 'CEO',
        updatedByEmpId: 'MN-CEO01',
        sections: [],
      );

      eco.konarBooks.add(bookToDelete);
      await eco.deleteKonarBook('test_department');

      expect(eco.konarBooks.any((b) => b.id == 'test_department'), isFalse);
    });
  });
}
