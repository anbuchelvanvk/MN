import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/pillars/health_pillar_screen.dart';
import 'package:mn_family_app/views/pillars/family_pillar_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Leadership Employee Activities Inspector Tests', () {
    testWidgets('Health Pillar shows staff inspector for CEO and HR, but hidden for employee', (tester) async {
      final provider = EcosystemProvider();

      // 1. CEO Login: Should see "EMPLOYEE HEALTH ACTIVITIES" gateway button
      provider.setActiveRole('ceo');
      provider.setActiveEmpId('MN-CEO01');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EcosystemProvider>.value(
            value: provider,
            child: const HealthPillarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EMPLOYEE HEALTH ACTIVITIES'), findsOneWidget);
      expect(find.text('Inspect'), findsOneWidget);

      // Dedicated EmployeeHealthActivitiesScreen displays employee selector
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EcosystemProvider>.value(
            value: provider,
            child: const EmployeeHealthActivitiesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('SELECT EMPLOYEE'), findsOneWidget);
      expect(find.text('Mohankumar G'), findsWidgets);

      // 2. HR Login: Should see "EMPLOYEE HEALTH ACTIVITIES"
      provider.setActiveRole('hr');
      provider.setActiveEmpId('MN-HR1001');
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EcosystemProvider>.value(
            value: provider,
            child: const HealthPillarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('EMPLOYEE HEALTH ACTIVITIES'), findsOneWidget);

      // 3. Regular Employee Login: Inspector section must be HIDDEN
      provider.setActiveRole('employee');
      provider.setActiveEmpId('6');
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EcosystemProvider>.value(
            value: provider,
            child: const HealthPillarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('EMPLOYEE HEALTH ACTIVITIES'), findsNothing);
    });

    testWidgets('Family Pillar shows staff inspector for CEO and HR, but hidden for employee', (tester) async {
      final provider = EcosystemProvider();

      // 1. CEO Login: Should see "EMPLOYEE FAMILY ACTIVITIES" gateway button
      provider.setActiveRole('ceo');
      provider.setActiveEmpId('MN-CEO01');

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EcosystemProvider>.value(
            value: provider,
            child: const FamilyPillarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EMPLOYEE FAMILY ACTIVITIES'), findsOneWidget);
      expect(find.text('Inspect'), findsOneWidget);

      // Dedicated EmployeeFamilyActivitiesScreen displays employee selector
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EcosystemProvider>.value(
            value: provider,
            child: const EmployeeFamilyActivitiesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('SELECT EMPLOYEE'), findsOneWidget);
      expect(find.text('Mohankumar G'), findsWidgets);

      // 2. HR Login: Should see "EMPLOYEE FAMILY ACTIVITIES"
      provider.setActiveRole('hr');
      provider.setActiveEmpId('MN-HR1001');
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EcosystemProvider>.value(
            value: provider,
            child: const FamilyPillarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('EMPLOYEE FAMILY ACTIVITIES'), findsOneWidget);

      // 3. Regular Employee Login: Inspector section must be HIDDEN
      provider.setActiveRole('employee');
      provider.setActiveEmpId('6');
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EcosystemProvider>.value(
            value: provider,
            child: const FamilyPillarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('EMPLOYEE FAMILY ACTIVITIES'), findsNothing);
    });

    test('Document Vault has NO fake standardDefaultDocs and returns empty when unsubmitted', () {
      final provider = EcosystemProvider();

      // For employee 6 (Gokulakrishnan K) who has not uploaded certificates to database:
      final docs = provider.getEmployeeDocuments('6');
      expect(docs.isEmpty, isTrue, reason: 'Must not inject mock 10th/12th/Degree marksheets!');

      // Staff vault count must be 0 when no staff have uploaded real documents
      expect(provider.allStaffDocsCount, equals(0));
      expect(provider.allStaffSubmittedCount, equals(0));
    });
  });
}
