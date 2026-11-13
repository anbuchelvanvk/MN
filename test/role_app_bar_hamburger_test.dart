import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mn_family_app/core/widgets/role_app_bar.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';

void main() {
  group('RoleAppBar Hamburger Toggle Button & Menu Tests', () {
    testWidgets('Renders hamburger toggle button without cramping title', (tester) async {
      final eco = EcosystemProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EcosystemProvider>.value(
            value: eco,
            child: Scaffold(
              appBar: RoleAppBar(
                roleName: 'CEO Suite',
                userName: 'M N Naveenraaj (CEO)',
                roleColor: Colors.amber,
                roleIcon: Icons.workspace_premium_outlined,
                onRoleSwitch: () {},
                onExportPressed: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Brand title should be present
      expect(find.text('MN JEWEL PARK'), findsOneWidget);
      expect(find.text('EXECUTIVE SUITE'), findsOneWidget);

      // Hamburger button should be present
      expect(find.byKey(const ValueKey('role_app_bar_hamburger')), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

      // Previous cramped icons should NOT be cluttering the top bar
      expect(find.text('MN Family Pillars'), findsNothing);
      expect(find.text('Export Audit Report'), findsNothing);
    });

    testWidgets('Tapping hamburger opens neat menu with all options and logout', (tester) async {
      final eco = EcosystemProvider();
      bool exportCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EcosystemProvider>.value(
            value: eco,
            child: Scaffold(
              appBar: RoleAppBar(
                roleName: 'CEO Suite',
                userName: 'M N Naveenraaj (CEO)',
                roleColor: Colors.amber,
                roleIcon: Icons.workspace_premium_outlined,
                onRoleSwitch: () {},
                onExportPressed: () => exportCalled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Tap the hamburger button
      await tester.tap(find.byKey(const ValueKey('role_app_bar_hamburger')));
      await tester.pumpAndSettle();

      // Check all options inside the menu sheet
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Refresh App'), findsOneWidget);
      expect(find.text('MN Family Pillars'), findsOneWidget);
      expect(find.text('Export Audit Report'), findsOneWidget);
      expect(find.text('Switch Role'), findsWidgets); // Both top strip and menu
      expect(find.text('Logout'), findsOneWidget);

      // Tap Export Audit Report
      await tester.tap(find.text('Export Audit Report'));
      await tester.pumpAndSettle();

      expect(exportCalled, isTrue);
    });
  });
}
