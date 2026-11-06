import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mn_family_app/core/widgets/role_app_bar.dart';
import 'package:mn_family_app/core/widgets/export_audit_modal.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/services/export_audit_service.dart';
import 'package:mn_family_app/views/pillars/attendance_pillar_screen.dart';

void main() {
  group('Team Lead Export & Role Restrictions Test', () {
    testWidgets('RoleAppBar hides export button when onExportPressed is null (Employee)', (tester) async {
      final eco = EcosystemProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EcosystemProvider>.value(
            value: eco,
            child: Scaffold(
              appBar: RoleAppBar(
                roleName: 'Employee',
                userName: 'Nisha M (Staff)',
                roleColor: Colors.blue,
                roleIcon: Icons.person,
                onRoleSwitch: () {},
                onExportPressed: null, // Employee has NO export option!
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Export icon should NOT be found
      expect(find.byTooltip('Export CSV Audit'), findsNothing);
    });

    testWidgets('Team Lead export modal is strictly scoped to team members and excludes Master Ledger', (tester) async {
      final eco = EcosystemProvider();
      eco.setActiveEmpId('MN-TL1002'); // Team Lead Praveenkumaar

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<EcosystemProvider>.value(
              value: eco,
              child: const ExportAuditModal(isTeamLead: true),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Title should say 'Export Team Audit'
      expect(find.text('Export Team Audit'), findsOneWidget);
      expect(find.text('Team Tasks & Attendance'), findsOneWidget);

      // 2. Master Ledger and 5 Pillars should NOT be present
      expect(find.text('Master Ledger'), findsNothing);
      expect(find.text('5 Family Pillars'), findsNothing);

      // 3. Team datasets should be available
      expect(find.text('Team Tasks'), findsOneWidget);
      expect(find.text('Team Attendance'), findsOneWidget);
      expect(find.text('Team Directory'), findsOneWidget);

      // 4. Verify CSV generation is scoped to team members
      final csv = ExportAuditService.instance.generateCsv(
        eco: eco,
        datasetType: ExportDatasetType.tasks,
        timeSpan: ExportTimeSpan.thisWeek,
        isTeamLead: true,
        allowedEmpIds: ['MN-1007', 'MN-1008', 'MN-TL1002'],
      );

      expect(csv, contains('MN JEWEL PARK - TEAM OPERATIONAL AUDIT REPORT'));
      expect(csv, contains('DEPARTMENT:'));
      // Should not contain CEO/HR private data
      expect(csv, isNot(contains('ceoofmn@mnjpark.com')));
    });

    testWidgets('AttendancePillarScreen has PUNCH AUDIT without TRAIL and high-contrast gateway card', (tester) async {
      final eco = EcosystemProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EcosystemProvider>.value(
            value: eco,
            child: const AttendancePillarScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Verify 'PUNCH AUDIT' is present (even if offstage in scroll view) and 'BIOMETRIC PUNCH AUDIT TRAIL' is removed
      expect(find.text('PUNCH AUDIT', skipOffstage: false), findsOneWidget);
      expect(find.text('BIOMETRIC PUNCH AUDIT TRAIL', skipOffstage: false), findsNothing);

      // Verify Gateway card has high-contrast 'Green Factor' and 'Attendance Pending'
      expect(find.text('Green Factor', skipOffstage: false), findsOneWidget);
      expect(find.text('Attendance Pending', skipOffstage: false), findsOneWidget);
    });
  });
}
