import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/ceo/admin_role_access_management_screen.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('RBAC Admin & Role Access Management Tests', () {
    test('EcosystemProvider successfully updates employee role and permissions', () async {
      final eco = EcosystemProvider();

      // Find an employee to update (e.g., ECE)
      final eceBefore = eco.employees.firstWhere((e) => e.roleCode == 'ECE');
      expect(eceBefore.canAccessCeoSuite, isFalse);
      expect(eceBefore.canManageRoles, isFalse);

      // Grant additional permissions to ECE
      final newPermissions = eceBefore.permissions.copyWith(
        canAccessCeoSuite: true,
        canManageRoles: true,
        canExportAudit: true,
      );

      await eco.updateEmployeeRoleAndAccess(
        employeeId: eceBefore.id,
        newRoleCode: 'ECE-LEAD',
        newRoleType: 'employee',
        newRole: 'Senior E-Commerce Lead',
        newDept: 'Technology',
        permissions: newPermissions,
      );

      final eceAfter = eco.employees.firstWhere((e) => e.id == eceBefore.id);
      expect(eceAfter.roleCode, equals('ECE-LEAD'));
      expect(eceAfter.role, equals('Senior E-Commerce Lead'));
      expect(eceAfter.canAccessCeoSuite, isTrue);
      expect(eceAfter.canManageRoles, isTrue);
      expect(eceAfter.canExportAudit, isTrue);
    });

    test('CEO Lockout Protection: Cannot revoke CEO Suite or Role Management from CEO', () async {
      final eco = EcosystemProvider();
      final ceo = eco.employees.firstWhere((e) => e.id == 'MN-CEO01');
      expect(ceo.canAccessCeoSuite, isTrue);
      expect(ceo.canManageRoles, isTrue);

      // Attempting to revoke CEO Suite permission must throw ArgumentError
      final revokedSuitePerms = ceo.permissions.copyWith(
        canAccessCeoSuite: false,
      );

      expect(
        () => eco.updateEmployeeRoleAndAccess(
          employeeId: 'MN-CEO01',
          newRoleCode: 'CEO',
          newRoleType: 'ceo',
          newRole: ceo.role,
          newDept: ceo.dept,
          permissions: revokedSuitePerms,
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Attempting to revoke Manage Roles permission must throw ArgumentError
      final revokedManageRolesPerms = ceo.permissions.copyWith(
        canManageRoles: false,
      );

      expect(
        () => eco.updateEmployeeRoleAndAccess(
          employeeId: 'MN-CEO01',
          newRoleCode: 'CEO',
          newRoleType: 'ceo',
          newRole: ceo.role,
          newDept: ceo.dept,
          permissions: revokedManageRolesPerms,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    testWidgets('AdminRoleAccessManagementScreen renders and lists staff members', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final eco = EcosystemProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EcosystemProvider>.value(
            value: eco,
            child: const AdminRoleAccessManagementScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify title & banner
      expect(find.text('Role & Access Control'), findsOneWidget);
      expect(find.text('Access Policy & Governance'), findsOneWidget);

      // Verify search bar is present
      expect(find.byType(TextField), findsOneWidget);

      // Verify staff cards are displayed
      expect(find.textContaining('STAFF DIRECTORY'), findsOneWidget);
      expect(find.text('M N Naveenraaj'), findsOneWidget);
      expect(find.text('Mohankumar G'), findsOneWidget);
    });
  });
}
