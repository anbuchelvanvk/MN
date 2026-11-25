import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/models/employee_model.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';

Future<EcosystemProvider> signIn(String email) async {
  final eco = EcosystemProvider();
  await eco.loginWithFirebase(email: email, password: 'x');
  return eco;
}

String? hire(EcosystemProvider eco, String id, String name, String dept,
        {String roleType = 'employee', String? roleCode}) =>
    eco.addNewEmployee(
      name: name,
      role: roleCode == 'AHR' ? 'Assistant HR' : (roleType == 'hr' ? 'HR Manager' : 'Staff'),
      roleType: roleType,
      roleCode: roleCode,
      dept: dept,
      phone: '9876501$id',
      email: '${name.toLowerCase().replaceAll(' ', '')}@mnj.com',
      experienceCategory: 'standard',
      experienceYears: '1',
      customEmpId: id,
      empNo: id,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('first sign-in access comes from the role', () {
    test('CEO has every department and every perk', () {
      final p = RolePermissions.defaultForRole(roleType: 'ceo', roleCode: 'CEO');
      expect(p.hasAllDepartments, isTrue);
      expect(p.canManageRoles && p.canHireStaff && p.canApproveLeave, isTrue);
    });

    test('HR gets HR tools for Administration and Online, not all departments', () {
      final p = RolePermissions.defaultForRole(roleType: 'hr', roleCode: 'HR');
      expect(p.canAccessHrPortal && p.canHireStaff && p.canRelieveStaff && p.canApproveLeave, isTrue);
      expect(p.hasAllDepartments, isFalse);
      expect(p.departmentAccess, containsAll(['Administration Department', 'Online Department']));
      expect(p.canManageRoles, isFalse);
    });

    test('Asst. HR gets day-to-day HR work only', () {
      final p = RolePermissions.defaultForRole(roleType: 'hr', roleCode: 'AHR');
      expect(p.canAccessHrPortal && p.canManageAttendance && p.canAuditGrooming && p.canResetPasswords, isTrue);
      expect(p.canHireStaff || p.canRelieveStaff || p.canApproveLeave || p.canSendAnnouncements, isFalse);
    });

    test('team lead and employee get no HR perks', () {
      final tl = RolePermissions.defaultForRole(roleType: 'team_lead', roleCode: 'TL');
      final emp = RolePermissions.defaultForRole(roleType: 'employee', roleCode: 'GEN');
      expect(tl.canAccessDeptHeadPortal && tl.canAssignTasksToOthers, isTrue);
      expect(tl.canHireStaff || emp.canHireStaff || emp.canAccessHrPortal, isFalse);
    });

    test('a saved permission map keeps working and fills new perks from the role', () {
      final p = RolePermissions.fromMap({'canAccessHrPortal': true}, roleType: 'hr', roleCode: 'HR');
      expect(p.canHireStaff, isTrue);
      final ceo = RolePermissions.fromMap({'departmentAccess': ['Online Department']}, roleType: 'ceo', roleCode: 'CEO');
      expect(ceo.hasAllDepartments, isTrue, reason: 'the CEO never loses all-department access');
    });

    test('a newly hired Asst. HR signs in with Asst. HR access', () async {
      final eco = await signIn('ceoofmn@mnjpark.com');
      expect(hire(eco, '301', 'Divya R', Employee.administrationDept, roleType: 'hr', roleCode: 'AHR'), isNull);
      final e = eco.employees.firstWhere((x) => x.id == '301');
      expect(e.isHr, isTrue);
      expect(e.dept, Employee.administrationDept);
      expect(e.permissions.canAccessHrPortal, isTrue);
      expect(e.permissions.canHireStaff, isFalse);
    });
  });

  group('Administration Department', () {
    test('old names all become Administration Department', () {
      for (final n in ['Administration', 'HR & People Ops', 'Executive Board', 'HR & Administration']) {
        expect(Employee.normalizeDept(n), 'Administration Department');
      }
      expect(Employee.normalizeDept('Online Department'), 'Online Department');
    });

    test('HR and the CEO are in it, and it is listed', () {
      final eco = EcosystemProvider();
      expect(eco.availableDepartments, contains('Administration Department'));
      expect(eco.employees.firstWhere((e) => e.id == '7').dept, 'Administration Department');
      expect(eco.employees.firstWhere((e) => e.id == 'MN-CEO01').dept, 'Administration Department');
    });
  });

  group('only the CEO has every department', () {
    test('HR cannot create departments; the CEO can', () async {
      final hr = await signIn('hr@mnj.com');
      expect(await hr.createNewDepartment('Showroom Floor'), isFalse);
      expect(hr.notificationMessage, contains('Only the CEO'));
      final ceo = await signIn('ceoofmn@mnjpark.com');
      expect(await ceo.createNewDepartment('Showroom Floor'), isTrue);
    });

    test('HR works only in granted departments', () async {
      final eco = await signIn('ceoofmn@mnjpark.com');
      await eco.createNewDepartment('Showroom Floor');
      expect(hire(eco, '310', 'Floor One', 'Showroom Floor'), isNull);
      expect(eco.employeesInMyScope.any((e) => e.id == '310'), isTrue, reason: 'the CEO sees every department');

      await eco.loginWithFirebase(email: 'hr@mnj.com', password: 'x');
      // Default HR access: Administration + Online, not the new department
      expect(eco.canManageDepartment('Online Department'), isTrue);
      expect(eco.canManageDepartment('Showroom Floor'), isFalse);
      expect(eco.employeesInMyScope.any((e) => e.id == '310'), isFalse);
      expect(eco.employeesInMyScope.any((e) => e.isCeo), isFalse);
      expect(hire(eco, '311', 'Floor Two', 'Showroom Floor'), contains('only hire into departments'));
      expect(hire(eco, '312', 'New HR', Employee.administrationDept, roleType: 'hr'), contains('Only the CEO'));
      expect(hire(eco, '313', 'Online New', 'Online Department'), isNull);
    });

    test('perks switched off by the CEO are enforced', () async {
      final eco = await signIn('hr@mnj.com');
      final idx = eco.employees.indexWhere((e) => e.id == '7');
      final hrEmp = eco.employees[idx];
      hrEmp.permissions = hrEmp.permissions.copyWith(canHireStaff: false, canRelieveStaff: false);
      expect(hire(eco, '320', 'Someone', 'Online Department'), contains('permission to hire'));
      expect(eco.relieveEmployee('33'), isFalse);
      expect(eco.notificationMessage, contains('permission to relieve'));
    });
  });
}
