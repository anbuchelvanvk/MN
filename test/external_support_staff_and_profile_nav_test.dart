import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/core/widgets/quick_pillar_nav_row.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/pillars/profile_pillar_screen.dart';
import 'package:mn_family_app/views/pillars/attendance_pillar_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('External Support Staff [Online] & Profile Navigation Tests', () {
    test('All 5 External Support Staff from Konar Book are registered with correct specs', () {
      final eco = EcosystemProvider();

      final expectedStaff = [
        (id: 'EXT-VPE', name: 'Aravinda Samy', roleCode: 'VPE'),
        (id: 'EXT-AC', name: 'Midhun Kumar', roleCode: 'AC'),
        (id: 'EXT-OSS', name: 'Subash', roleCode: 'OSS'),
        (id: 'EXT-DVP', name: 'K B Eshwar', roleCode: 'DVP'),
        (id: 'EXT-CC', name: 'Sam Roy', roleCode: 'CC'),
      ];

      for (final spec in expectedStaff) {
        final staff = eco.employees.firstWhere(
          (e) => e.id == spec.id,
          orElse: () => throw Exception('Staff ${spec.name} with ID ${spec.id} not found in ecosystem!'),
        );

        expect(staff.name, spec.name);
        expect(staff.dept, 'External Support Staff [Online]');
        expect(staff.isExternalSupport, isTrue);
        // Excluded from showroom biometric attendance and grooming
        expect(staff.hasAttendanceAndGrooming, isFalse);
        // Clean straight-cut role
        expect(staff.straightCutRole, spec.roleCode);
        // Not counted as absent
        expect(eco.isEmployeeAbsent(staff.id), isFalse);

        // Konar Book tasks must be populated
        final tasks = eco.tasks.where((t) => t.empId == staff.id).toList();
        expect(tasks.isNotEmpty, isTrue, reason: 'Staff ${spec.name} must have standard Konar Book tasks assigned');
      }
    });

    test('TL Praveenkumar, HR, and CEO have designated authority over External Support Staff', () {
      final eco = EcosystemProvider();

      for (final id in ['EXT-VPE', 'EXT-AC', 'EXT-OSS', 'EXT-DVP', 'EXT-CC']) {
        final tl = eco.getTeamLeadForEmployee(id);
        expect(tl, isNotNull);
        expect(tl!.id, 'MN-TL1002', reason: 'OTM Praveenkumar M is the designated Team Lead for online external contractors');
      }

      // They must be part of operationsDeptTasks (managed by TL Praveenkumar)
      final opsTasks = eco.operationsDeptTasks;
      final extTaskIds = opsTasks.where((t) => t.empId.startsWith('EXT-')).toList();
      expect(extTaskIds.isNotEmpty, isTrue);
    });

    testWidgets('QuickPillarNavRow Profile button navigates directly to ProfilePillarScreen', (tester) async {
      final eco = EcosystemProvider();
      // Ensure CEO is active (where attendance is exempt)
      eco.setActiveEmpId('MN-CEO01');

      await tester.pumpWidget(
        ChangeNotifierProvider<EcosystemProvider>.value(
          value: eco,
          child: const MaterialApp(
            home: Scaffold(
              body: QuickPillarNavRow(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Work pillar button
      final workFinder = find.widgetWithText(InkWell, 'Work');
      expect(workFinder, findsOneWidget);

      // Tap Work button
      await tester.tap(workFinder);
      await tester.pumpAndSettle();

      // Must navigate to ProfilePillarScreen (Pillar 3 Work & Operations Suite)
      expect(find.byType(ProfilePillarScreen), findsOneWidget);
      expect(find.text('WORK & OPERATIONS'), findsOneWidget);
    });

    testWidgets('AttendancePillarScreen displays Exemption card for External Support Staff', (tester) async {
      final eco = EcosystemProvider();
      eco.setActiveEmpId('EXT-VPE');

      await tester.pumpWidget(
        ChangeNotifierProvider<EcosystemProvider>.value(
          value: eco,
          child: const MaterialApp(
            home: AttendancePillarScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EXTERNAL SUPPORT STAFF [ONLINE]'), findsOneWidget);
      expect(find.textContaining('Exempt from Retail Showroom Attendance & Grooming'), findsOneWidget);
    });
  });
}
