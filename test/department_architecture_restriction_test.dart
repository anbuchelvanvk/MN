import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/models/profile_pillar_models.dart';
import 'package:mn_family_app/views/ceo/admin_role_access_management_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Company Department Architecture Restrictions Tests', () {
    test('availableDepartments strictly contains only Online Department and HR & Administration', () {
      final eco = EcosystemProvider();
      final depts = eco.availableDepartments;

      // Must strictly contain the two official company departments
      expect(depts, contains('Online Department'));
      expect(depts, contains('HR & Administration'));

      // Must NOT contain Offline Department or separate Administration
      expect(depts.contains('Offline Department'), isFalse);
      expect(depts.contains('Offline'), isFalse);
      expect(depts.contains('Administration'), isFalse);

      // Default registered departments must only have 2 departments
      expect(depts.length, equals(2));
    });

    test('RoleAllocationConfig.availableDepartments strictly restricted to 2 departments', () {
      final depts = RoleAllocationConfig.availableDepartments;
      expect(depts, contains('Online Department'));
      expect(depts, contains('HR & Administration'));
      expect(depts.contains('Offline Department'), isFalse);
      expect(depts.contains('Administration'), isFalse);
      expect(depts.length, equals(2));
    });

    testWidgets('AdminRoleAccessManagementScreen shows only All, Online Dept, and HR & Admin filter chips', (tester) async {
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

      // Check Department Filter Chips
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Online Department'), findsOneWidget);
      expect(find.text('HR & Administration'), findsOneWidget);

      // Verify that 'Offline Department' chip does NOT exist
      expect(find.text('Offline Department'), findsNothing);
      expect(find.text('Administration'), findsNothing);
    });
  });
}
