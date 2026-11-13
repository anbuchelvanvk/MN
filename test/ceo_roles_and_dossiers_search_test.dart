import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/ceo/ceo_subpages.dart';

Widget wrapWithApp({required Widget child, EcosystemProvider? eco}) {
  return ChangeNotifierProvider<EcosystemProvider>.value(
    value: eco ?? EcosystemProvider(),
    child: MaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CEO Roles & Privileges and Staff Dossiers Tests', () {
    testWidgets('CeoRolesPrivilegesScreen builds without dropdown assertion error and allows selecting staff', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final eco = EcosystemProvider();
      await tester.pumpWidget(wrapWithApp(child: const CeoRolesPrivilegesScreen(), eco: eco));
      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Roles & Privileges'), findsOneWidget);
      expect(find.text('EXECUTIVE GOVERNANCE'), findsOneWidget);
      expect(find.text('ASSIGNED DESIGNATION'), findsOneWidget);

      // Verify Mohankumar G is in the carousel/list
      final mohanFinder = find.text('Mohankumar');
      expect(mohanFinder, findsWidgets);

      // Tap on Mohankumar G to select him (whose role is 'HR Manager & Operations Custodian')
      await tester.tap(mohanFinder.first);
      await tester.pumpAndSettle();

      // Verify that Mohankumar G's role and details load properly without assertion crash
      expect(find.textContaining('Mohankumar G'), findsWidgets);
      expect(find.textContaining('HR Manager & Operations Custodian'), findsWidgets);

      // Tap Save button
      final saveBtn = find.text('Confirm & Save Role Allocation');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Updated Mohankumar G'), findsOneWidget);
    });

    testWidgets('CeoStaffDossiersScreen renders search bar and filters staff accurately', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final eco = EcosystemProvider();
      await tester.pumpWidget(wrapWithApp(child: const CeoStaffDossiersScreen(), eco: eco));
      await tester.pumpAndSettle();

      // Verify headers
      expect(find.text('Staff Dossiers'), findsOneWidget);
      expect(find.text('COMPANY EMPLOYEE DOSSIERS'), findsOneWidget);

      // Verify search bar presence
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Both CEO and Mohankumar should initially be visible
      expect(find.text('M N Naveenraaj'), findsOneWidget);
      expect(find.text('Mohankumar G'), findsOneWidget);

      // Filter by "Mohan"
      await tester.enterText(searchField, 'Mohan');
      await tester.pumpAndSettle();

      // Mohankumar should be visible, CEO should be filtered out
      expect(find.text('Mohankumar G'), findsOneWidget);
      expect(find.text('M N Naveenraaj'), findsNothing);

      // Filter by ID "MN-CEO01"
      await tester.enterText(searchField, 'MN-CEO01');
      await tester.pumpAndSettle();

      expect(find.text('M N Naveenraaj'), findsOneWidget);
      expect(find.text('Mohankumar G'), findsNothing);

      // Filter by non-existent name
      await tester.enterText(searchField, 'NonExistentStaffMember123');
      await tester.pumpAndSettle();

      expect(find.text('No staff members found'), findsOneWidget);
      expect(find.textContaining('No staff matched "NonExistentStaffMember123"'), findsOneWidget);

      // Clear search
      final clearBtn = find.byIcon(Icons.close);
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      // Both should be back
      expect(find.text('M N Naveenraaj'), findsOneWidget);
      expect(find.text('Mohankumar G'), findsOneWidget);
    });
  });
}

