import 'package:flutter_test/flutter_test.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Employee Profile Edit & Firebase Persistence Tests', () {
    late EcosystemProvider eco;

    setUp(() {
      eco = EcosystemProvider();
    });

    test('updateEmployeePersonalDetails updates name, initials, gender and personal fields in memory', () async {
      // Find Praveenkumar M
      final initialEmp = eco.employees.firstWhere((e) => e.id == 'MN-TL1002');
      expect(initialEmp.name, 'Praveenkumar M');

      // Update name to Praveenkumar M with updated phone, DOB, and Gender
      await eco.updateEmployeePersonalDetails(
        empId: 'MN-TL1002',
        name: 'Praveenkumar M',
        phone: '+91 94420 99999',
        dob: '1994-08-15',
        relationshipStatus: 'Married',
        anniversaryDate: '2021-11-20',
        gender: 'Male',
      );

      final updatedEmp = eco.employees.firstWhere((e) => e.id == 'MN-TL1002');
      expect(updatedEmp.name, 'Praveenkumar M');
      expect(updatedEmp.initials, 'PM');
      expect(updatedEmp.phone, '+91 94420 99999');
      expect(updatedEmp.gender, 'Male');
      expect(updatedEmp.relationshipStatus, 'Married');
      expect(updatedEmp.anniversaryDate, '2021-11-20');
    });

    test('recalculates initials dynamically when employee name changes', () async {
      await eco.updateEmployeePersonalDetails(
        empId: 'MN-TL1002',
        name: 'Kumar Shanmugam',
        phone: '+91 94420 99999',
        dob: '1994-08-15',
        relationshipStatus: 'Single',
        gender: 'Male',
      );

      final updatedEmp = eco.employees.firstWhere((e) => e.id == 'MN-TL1002');
      expect(updatedEmp.name, 'Kumar Shanmugam');
      expect(updatedEmp.initials, 'KS');
    });

    test('Employee model copyWith preserves updated fields', () {
      final emp = eco.employees.firstWhere((e) => e.id == 'MN-TL1002');
      final cloned = emp.copyWith(
        name: 'Praveenkumar M',
        gender: 'Male',
        phone: '+91 98765 43210',
      );

      expect(cloned.name, 'Praveenkumar M');
      expect(cloned.gender, 'Male');
      expect(cloned.phone, '+91 98765 43210');
      expect(cloned.id, 'MN-TL1002');
      expect(cloned.email, 'praveenkumarotm@mnj.com');
    });
  });
}

