import 'package:flutter_test/flutter_test.dart';
import 'package:mn_family_app/models/employee_model.dart';
import 'package:mn_family_app/models/konar_tasks_catalog.dart';
import 'package:mn_family_app/services/firebase_employee_service.dart';

ProfileCompletion _mockCompletion() => ProfileCompletion(
      percentage: 100,
      isAuthorized: true,
      photoVerified: true,
      addressVerified: true,
      kycVerified: true,
      sopRolesAcknowledged: true,
    );

void main() {
  group('Department Collection Name Resolution', () {
    test('resolves standard and custom department collection names', () {
      expect(
        FirebaseEmployeeService.getDepartmentCollectionName('Online Department'),
        equals('online_department_employees'),
      );
      expect(
        FirebaseEmployeeService.getDepartmentCollectionName('Online'),
        equals('online_department_employees'),
      );
      expect(
        FirebaseEmployeeService.getDepartmentCollectionName('Offline Department'),
        equals('offline_department_employees'),
      );
      expect(
        FirebaseEmployeeService.getDepartmentCollectionName('offline department'),
        equals('offline_department_employees'),
      );
      expect(
        FirebaseEmployeeService.getDepartmentCollectionName('Jewelry Manufacturing'),
        equals('jewelry_manufacturing_employees'),
      );
      expect(
        FirebaseEmployeeService.getDepartmentCollectionName('Retail Operations'),
        equals('retail_operations_employees'),
      );
      expect(
        FirebaseEmployeeService.getDepartmentCollectionName(''),
        equals('online_department_employees'),
      );
    });
  });

  group('Employee Model - Team Lead Perks & Custom Roles', () {
    test('Offline Department Team Lead receives all TL perks and retains exact ID', () {
      final offlineTl = Employee(
        id: '56',
        name: 'Anbu Chelvan',
        dept: 'Offline Department',
        role: 'Team Lead',
        roleType: 'team_lead',
        empNo: '56',
        email: 'anbu@mnj.com',
        phone: '9876543210',
        avatar: 'https://example.com/avatar.png',
        initials: 'AC',
        doj: 'Today',
        experienceYears: 'Confirmed Corporate Staff',
        experienceCategory: 'standard',
        profileCompletion: _mockCompletion(),
        status: 'Active',
        ragStatus: 'Green',
        lastActive: 'Just now',
      );

      // Perks & Privileges
      expect(offlineTl.isTeamLead, isTrue, reason: 'Must be recognized as Team Lead');
      expect(offlineTl.hasAttendanceAndGrooming, isFalse,
          reason: 'Must be exempt from showroom punching and grooming, matching Praveenkumar');
      expect(offlineTl.isOtm, isFalse, reason: 'Is an Offline TL, not Online TL');
      expect(offlineTl.displayEmpId, equals('56'),
          reason: 'Must retain their actual employee ID 56 instead of being overwritten to MN-TL1002');
    });

    test('Online Team Lead Praveenkumar retains full TL perks and legacy ID', () {
      final onlineTl = Employee(
        id: 'MN-TL1002',
        name: 'Praveenkumar M',
        dept: 'Online Department',
        role: 'Team Lead',
        roleType: 'team_lead',
        empNo: 'MN-TL1002',
        email: 'praveen@mnj.com',
        phone: '9876543211',
        avatar: 'https://example.com/avatar.png',
        initials: 'PM',
        doj: 'Today',
        experienceYears: 'Confirmed Corporate Staff',
        experienceCategory: 'standard',
        profileCompletion: _mockCompletion(),
        status: 'Active',
        ragStatus: 'Green',
        lastActive: 'Just now',
      );

      expect(onlineTl.isTeamLead, isTrue);
      expect(onlineTl.isOtm, isTrue);
      expect(onlineTl.hasAttendanceAndGrooming, isFalse);
      expect(onlineTl.displayEmpId, equals('MN-TL1002'));
    });

    test('Regular employee in Offline Department has attendance/grooming and custom role', () {
      final billingStaff = Employee(
        id: '57',
        name: 'Kavitha R',
        dept: 'Offline Department',
        role: 'Billing Specialist',
        roleType: 'employee',
        empNo: '57',
        email: 'kavitha@mnj.com',
        phone: '9876543212',
        avatar: 'https://example.com/avatar.png',
        initials: 'KR',
        doj: 'Today',
        experienceYears: 'Confirmed Corporate Staff',
        experienceCategory: 'standard',
        profileCompletion: _mockCompletion(),
        status: 'Active',
        ragStatus: 'Green',
        lastActive: 'Just now',
      );

      expect(billingStaff.isTeamLead, isFalse);
      expect(billingStaff.hasAttendanceAndGrooming, isTrue);
      expect(billingStaff.displayEmpId, equals('57'));
      expect(billingStaff.role, equals('Billing Specialist'));
      expect(billingStaff.dept, equals('Offline Department'));
    });
  });

  group('KonarTaskCatalog - Dynamic SOP Generation', () {
    test('Generates leadership SOP tasks for Offline Department Team Lead', () {
      final roleCode = KonarTaskCatalog.resolveRoleCode('Team Lead', 'anbu@mnj.com', '56', 'Offline Department');
      expect(roleCode, equals('TL'));

      final tasks = KonarTaskCatalog.getStandardTasksForEmployee(
        '56',
        roleCode,
        'Anbu Chelvan',
        'Team Lead',
        'Offline Department',
      );

      expect(tasks, isNotEmpty);
      expect(tasks.length, greaterThanOrEqualTo(4));
      expect(tasks.any((t) => t.id.startsWith('KONAR-TL-')), isTrue);
      expect(tasks.any((t) => t.title.contains('Offline Department Opening Readiness')), isTrue);
      expect(tasks.any((t) => t.title.contains('Vault Custody') || t.title.contains('Audits')), isTrue);
    });

    test('Generates tailored role-based SOP tasks for custom role employees', () {
      final roleCode = KonarTaskCatalog.resolveRoleCode('Billing Specialist', 'kavitha@mnj.com', '57', 'Offline Department');
      expect(roleCode, equals('GEN'));

      final tasks = KonarTaskCatalog.getStandardTasksForEmployee(
        '57',
        roleCode,
        'Kavitha R',
        'Billing Specialist',
        'Offline Department',
      );

      expect(tasks, isNotEmpty);
      expect(tasks.length, greaterThanOrEqualTo(3));
      expect(tasks.any((t) => t.id.startsWith('KONAR-GEN-')), isTrue);
      expect(tasks.any((t) => t.title.contains('Billing Specialist')), isTrue);
      expect(tasks.any((t) => t.category == 'Daily Operations'), isTrue);
    });

    test('Role code resolution handles Offline Department TL properly', () {
      expect(
        KonarTaskCatalog.resolveRoleCode('Team Lead', 'anbu@mnj.com', '56', 'Offline Department'),
        equals('TL'),
      );
      expect(
        KonarTaskCatalog.resolveRoleCode('Operations Lead', 'lead@mnj.com', '58', 'Retail Operations'),
        equals('TL'),
      );
      expect(
        KonarTaskCatalog.resolveRoleCode('Billing Specialist', 'kavitha@mnj.com', '57', 'Offline Department'),
        equals('GEN'),
      );
    });
  });

  group('Dynamic Department Allocation & Creation', () {
    test('routes arbitrary new department to dedicated collection and assigns tailored SOPs', () {
      const newDept = 'Quality Control & Hallmarking';
      final colName = FirebaseEmployeeService.getDepartmentCollectionName(newDept);
      expect(colName, equals('quality_control_hallmarking_employees'));

      final qcStaff = Employee(
        id: '88',
        name: 'Suresh Kumar',
        dept: newDept,
        role: 'Senior Hallmarking Inspector',
        roleType: 'employee',
        empNo: '88',
        email: 'suresh.qc@mnj.com',
        phone: '9845012345',
        avatar: 'https://example.com/avatar.png',
        initials: 'SK',
        doj: 'Today',
        experienceYears: '5+ yrs Hallmarking',
        experienceCategory: 'expert',
        profileCompletion: _mockCompletion(),
        status: 'Active',
        ragStatus: 'Green',
        lastActive: 'Just now',
      );

      expect(qcStaff.dept, equals('Quality Control & Hallmarking'));
      expect(qcStaff.isTeamLead, isFalse);

      final roleCode = KonarTaskCatalog.resolveRoleCode(
        qcStaff.role,
        qcStaff.email,
        qcStaff.id,
        qcStaff.dept,
      );
      final tasks = KonarTaskCatalog.getStandardTasksForEmployee(
        qcStaff.id,
        roleCode,
        qcStaff.name,
        qcStaff.role,
        qcStaff.dept,
      );

      expect(tasks, isNotEmpty);
      expect(tasks.any((t) => t.title.contains('Senior Hallmarking Inspector')), isTrue);
    });
  });
}
