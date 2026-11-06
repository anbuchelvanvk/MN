import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mn_family_app/core/widgets/assign_tasks_to_others_modal.dart';
import 'package:mn_family_app/core/widgets/role_app_bar.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/auth/login_screen.dart';
import 'package:mn_family_app/core/theme/app_colors.dart';

void main() {
  group('Switch Role vs Logout Workflow Tests', () {
    testWidgets('Switch Role pushes Switch Account screen with back button and active user banner without logging out', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final eco = EcosystemProvider();
      eco.setActiveEmpId('MN-TL1002'); // Praveenkumaar M (Team Lead)

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EcosystemProvider>.value(
            value: eco,
            child: Builder(
              builder: (ctx) => Scaffold(
                appBar: RoleAppBar(
                  roleName: 'Team Lead',
                  userName: '${eco.currentEmployee.name} (Team Lead)',
                  roleColor: AppColors.statusBlue,
                  roleIcon: Icons.shield_outlined,
                  // onRoleSwitch is omitted so it uses the default switch account handler
                ),
                body: const Center(child: Text('TL Dashboard Content')),
              ),
            ),
          ),
        ),
      );

      // Verify on TL dashboard
      expect(find.text('TL Dashboard Content'), findsOneWidget);
      expect(find.text('Switch Role'), findsOneWidget);

      // Tap Switch Role
      await tester.tap(find.text('Switch Role'));
      await tester.pumpAndSettle();

      // Verify we are on the Switch Account screen
      expect(find.text('Switch Account'), findsWidgets);
      expect(find.text('Back to Current Account'), findsOneWidget);
      expect(find.textContaining('ACTIVE ACCOUNT'), findsOneWidget);
      expect(find.textContaining('Praveenkumaar M'), findsWidgets);

      // Tap Back to Current Account
      await tester.tap(find.text('Back to Current Account'));
      await tester.pumpAndSettle();

      // Verify we are returned safely to the TL dashboard with session intact
      expect(find.text('TL Dashboard Content'), findsOneWidget);
      expect(eco.activeEmpId, 'MN-TL1002');
    });

    testWidgets('Hamburger menu Switch Role pushes Switch Account screen without logging out', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final eco = EcosystemProvider();
      eco.setActiveEmpId('MN-CEO01');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EcosystemProvider>.value(
            value: eco,
            child: Builder(
              builder: (ctx) => Scaffold(
                appBar: RoleAppBar(
                  roleName: 'CEO Suite',
                  userName: 'M N Naveenraaj (CEO)',
                  roleColor: AppColors.goldBright,
                  roleIcon: Icons.workspace_premium_outlined,
                ),
                body: const Center(child: Text('CEO Dashboard Content')),
              ),
            ),
          ),
        ),
      );

      // Open hamburger menu
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Tap Switch Role inside hamburger sheet (last widget with this text)
      await tester.tap(find.text('Switch Role').last);
      await tester.pumpAndSettle();

      // Verify on Switch Account screen
      expect(find.text('Switch Account'), findsWidgets);
      expect(find.text('Back to Current Account'), findsOneWidget);

      // Press Back
      await tester.tap(find.text('Back to Current Account'));
      await tester.pumpAndSettle();

      // Verify back on CEO dashboard
      expect(find.text('CEO Dashboard Content'), findsOneWidget);
      expect(eco.activeEmpId, 'MN-CEO01');
    });
  });

  group('Categorized Task Assignee Dropdown Tests (CEO, HR, TL)', () {
    testWidgets('Assignee dropdown shows No Active Recipients when all team members are off duty', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final eco = EcosystemProvider();
      eco.setActiveEmpId('MN-TL1002'); // Team Lead Praveenkumaar

      // Mark Gokulakrishnan absent (has tasks to reassign)
      eco.toggleEmployeeAbsentStatus('MN-1003', isAbsent: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<EcosystemProvider>.value(
              value: eco,
              child: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => AssignTasksToOthersModal.show(ctx, defaultAbsentEmpId: 'MN-1003'),
                  child: const Text('Open Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      // Open the batch dropdown
      final dropdowns = find.byType(DropdownButtonFormField<String>);
      expect(dropdowns, findsWidgets);

      // Tap the first assignee dropdown
      await tester.tap(dropdowns.first);
      await tester.pumpAndSettle();

      // Verify Active category header is present
      expect(find.textContaining('ACTIVE / ON DUTY STAFF'), findsWidgets);

      // Verify "No Active Recipients" placeholder is present because team members are off duty
      expect(find.text('No Active Recipients'), findsWidgets);

      // Verify Off Duty category header is present
      expect(find.textContaining('OFF DUTY STAFF'), findsWidgets);

      // Verify off duty employees are listed
      expect(find.textContaining('Off Duty'), findsWidgets);
    });

    testWidgets('Assignee dropdown shows active employees under Active header when staff is present', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final eco = EcosystemProvider();
      eco.setActiveEmpId('MN-TL1002'); // Team Lead Praveenkumaar

      // Mark Kaaviya (MN-1007) manually present
      eco.toggleEmployeeAbsentStatus('MN-1007', isAbsent: false);
      // Mark Gokulakrishnan absent
      eco.toggleEmployeeAbsentStatus('MN-1003', isAbsent: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<EcosystemProvider>.value(
              value: eco,
              child: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => AssignTasksToOthersModal.show(ctx, defaultAbsentEmpId: 'MN-1003'),
                  child: const Text('Open Modal With Active Staff'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal With Active Staff'));
      await tester.pumpAndSettle();

      // Open the batch dropdown
      final dropdowns = find.byType(DropdownButtonFormField<String>);
      await tester.tap(dropdowns.first);
      await tester.pumpAndSettle();

      // Verify Kaaviya is shown On Duty under Active header
      expect(find.textContaining('Kaaviya'), findsWidgets);
      expect(find.textContaining('On Duty'), findsWidgets);
    });
  });
}

