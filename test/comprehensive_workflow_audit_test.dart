import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/ceo/ceo_suite_screen.dart';
import 'package:mn_family_app/views/hr/hr_portal_screen.dart';
import 'package:mn_family_app/views/dept_head/dept_head_portal_screen.dart';
import 'package:mn_family_app/views/employee/employee_portal_screen.dart';
import 'package:mn_family_app/views/konar/konar_book_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Comprehensive Role Workflow Audit', () {
    late EcosystemProvider provider;

    setUp(() {
      provider = EcosystemProvider();
    });

    // ==========================================
    // 1. CEO WORKFLOW AUDIT
    // ==========================================
    testWidgets('1. CEO Complete Workflow Test', (WidgetTester tester) async {
      // Step 1: Login as CEO
      final detectedRole = await provider.loginWithFirebase(
        email: 'ceoofmn@mnjpark.com',
        password: 'adminnaandhan',
      );
      expect(detectedRole, 'ceo');
      expect(provider.activeEmpId, 'MN-CEO01');
      expect(provider.isCeo, isTrue);
      expect(provider.currentEmployee.name, 'M N Naveenraaj');

      // Step 2: Pump CeoSuiteScreen
      await tester.pumpWidget(
        ChangeNotifierProvider<EcosystemProvider>.value(
          value: provider,
          child: const MaterialApp(home: CeoSuiteScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify CEO Identity & Navigation
      expect(find.textContaining('M N Naveenraaj'), findsWidgets);
      expect(find.textContaining('CEO'), findsWidgets);

      // Step 3: Test Workforce Role & Department Update
      final targetStaff = provider.employees.firstWhere((e) => e.id == 'MN-TL1002');
      expect(targetStaff.name, 'Praveenkumar M');

      provider.allocateEmployeeRole(
        empId: 'MN-TL1002',
        newRole: 'Senior Online Team Manager',
        newDept: 'Online Department',
        perks: ['Can Assign Works to Others', 'Can Approve Negotiation Discounts'],
      );

      final updatedStaff = provider.employees.firstWhere((e) => e.id == 'MN-TL1002');
      expect(updatedStaff.role, 'Senior Online Team Manager');

      // Step 4: CEO reviews and resolves inter-department blockers
      provider.raiseBlocker(
        raisedByDept: 'Sales',
        raisedByName: 'Kaaviya OS1',
        blockingDept: 'Operations',
        issue: 'Custom choker casting delayed by 2 days',
      );
      expect(provider.blockers.length, greaterThan(0));
      final blockerId = provider.blockers.first.id;

      provider.resolveBlocker(blockerId);
      final resolved = provider.blockers.firstWhere((b) => b.id == blockerId);
      expect(resolved.status, 'resolved');

      // Step 5: CEO emergency permissions approval
      provider.requestEmergencyPermission(
        empId: 'MN-TL1002',
        hours: 1.5,
        reason: 'Emergency client visit',
        requesterRole: 'Team Lead',
      );
      expect(provider.permissionRecords.isNotEmpty, isTrue);
      final testPerm = provider.permissionRecords.first;
      expect(testPerm.status, equals('Pending HR & CEO'));

      provider.ceoApprovePermission(testPerm.id);
      final updatedPerm = provider.permissionRecords.firstWhere((p) => p.id == testPerm.id);
      expect(updatedPerm.status, contains('Approved'));

      // Step 6: CEO adds executive personal note
      provider.addPersonalNote(
        title: 'Board Strategy Q4',
        content: 'Review fine jewellery omnichannel margins and expansion.',
        isPinned: true,
      );
      expect(provider.myPersonalNotes.any((n) => n.title.contains('Board Strategy Q4')), isTrue);
    });

    // ==========================================
    // 2. HR WORKFLOW AUDIT
    // ==========================================
    testWidgets('2. HR Complete Workflow Test', (WidgetTester tester) async {
      // Step 1: Login as HR
      final detectedRole = await provider.loginWithFirebase(
        email: 'hr@mnj.com',
        password: 'hr@mnj123',
      );
      expect(detectedRole, 'hr');
      expect(provider.activeEmpId, '7');
      expect(provider.currentEmployee.name, 'Mohankumar G');

      // Step 2: Pump HrPortalScreen
      await tester.pumpWidget(
        ChangeNotifierProvider<EcosystemProvider>.value(
          value: provider,
          child: const MaterialApp(home: HrPortalScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify HR Identity
      expect(find.textContaining('Mohankumar G'), findsWidgets);
      expect(find.textContaining('HR Admin'), findsWidgets);

      // Step 3: Add new hire
      final initialCount = provider.employees.length;
      provider.addNewEmployee(
        name: 'Aishwarya Rajesh',
        role: 'Jewellery Design Associate',
        dept: 'Online Department',
        phone: '+91 98450 99887',
        email: 'aishwarya@mnj.com',
        experienceCategory: 'fresher',
        experienceYears: '0 yrs',
        trainerName: 'Praveenkumar M',
      );
      expect(provider.employees.length, initialCount + 1);

      final newHire = provider.employees.firstWhere((e) => e.email == 'aishwarya@mnj.com');
      expect(newHire.experienceCategory, 'fresher');

      // Step 4: HR Attendance & Tuesday Holiday rules verification
      final attendanceList = provider.allEmployeesTodayAttendance;
      expect(attendanceList.isNotEmpty, isTrue);

      // Step 5: HR Broadcast announcement dispatch
      provider.broadcastUniversalAnnouncement(
        title: 'Q4 Luxury Exhibition Briefing',
        message: 'All departments must attend tomorrow 9:30 AM briefing.',
        category: 'hr',
      );
      expect(
        provider.companyNotifications.any((n) => n.title.contains('Q4 Luxury Exhibition')),
        isTrue,
      );

      // Step 6: HR Relieve employee workflow
      final success = provider.relieveEmployee(newHire.id);
      expect(success, isTrue);
      expect(provider.employees.any((e) => e.id == newHire.id), isFalse);
    });

    // ==========================================
    // 3. TEAM LEAD (TL) WORKFLOW AUDIT
    // ==========================================
    testWidgets('3. Team Lead Complete Workflow Test', (WidgetTester tester) async {
      // Step 1: Login as TL Praveenkumar M
      final detectedRole = await provider.loginWithFirebase(
        email: 'praveenkumarotm@mnj.com',
        password: 'praveen@mnj123',
      );
      expect(detectedRole, 'dept_head');
      expect(provider.activeEmpId, 'MN-TL1002');
      expect(provider.currentEmployee.name, 'Praveenkumar M');

      // Step 2: Pump DeptHeadPortalScreen
      await tester.pumpWidget(
        ChangeNotifierProvider<EcosystemProvider>.value(
          value: provider,
          child: const MaterialApp(home: DeptHeadPortalScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify TL Identity & Team Scope
      expect(find.textContaining('Praveenkumar M'), findsWidgets);
      expect(find.textContaining('Team Lead'), findsWidgets);

      // Step 3: TL Assigns task to team member
      provider.assignTask(
        empId: '6', // Gokulakrishnan K (OSH)
        assignedByName: 'Praveenkumar M',
        assignedByRole: 'team_lead',
        title: 'Review evening Instagram reel comments',
        category: 'Customer Engagement',
        priority: 'High',
        due: '06:00 PM',
      );

      final gokulTasks = provider.getTasksForEmployee('6');
      expect(gokulTasks.any((t) => t.title.contains('Review evening Instagram reel')), isTrue);

      // Step 4: TL KONAR Book viewing & 5 architectures verification
      final konarBook = provider.onlineDeptKonarBook;
      expect(konarBook.sections.length, 5);
      expect(konarBook.sections[0].title, '01 PURPOSE');
      expect(konarBook.sections[1].title, '02 GOALS');
      expect(konarBook.sections[2].title, '03 PROCESS');
      expect(konarBook.sections[3].title, '04 STRUCTURE');
      expect(konarBook.sections[4].title, '05 SYSTEM');

      // TL updates KONAR book version
      final updatedBook = konarBook.copyWith(
        version: 'v2.5',
        updatedByName: 'Praveenkumar M',
        updatedByRole: 'Online Team Manager',
        updatedByEmpId: 'MN-TL1002',
      );
      await provider.updateKonarBook(
        updatedBook,
        updaterName: 'Praveenkumar M',
        updaterRole: 'Online Team Manager',
      );
      expect(provider.onlineDeptKonarBook.version, 'v2.5');
    });

    // ==========================================
    // 4. EMPLOYEE WORKFLOW AUDIT
    // ==========================================
    testWidgets('4. Employee Complete Workflow Test', (WidgetTester tester) async {
      // Step 1: Login as Employee (Gokulakrishnan K - OSH)
      final detectedRole = await provider.loginWithFirebase(
        email: 'gokulakrishnanosh@mnj.com',
        password: 'gokul@mnj123',
      );
      expect(detectedRole, 'employee');
      expect(provider.activeEmpId, '6');
      expect(provider.currentEmployee.name, 'Gokulakrishnan K');

      // Step 2: Pump EmployeePortalScreen
      await tester.pumpWidget(
        ChangeNotifierProvider<EcosystemProvider>.value(
          value: provider,
          child: const MaterialApp(home: EmployeePortalScreen()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Employee Identity
      expect(find.textContaining('Gokulakrishnan K'), findsWidgets);

      // Step 3: Complete SOP Task & verify state update
      final myTasks = provider.currentEmployeeTasks;
      expect(myTasks.isNotEmpty, isTrue);
      final firstTask = myTasks.first;

      provider.completeTask(
        firstTask.id,
        proofText: 'Completed per official standard operating procedure',
      );
      final updatedTasks = provider.currentEmployeeTasks;
      final completed = updatedTasks.firstWhere((t) => t.id == firstTask.id);
      expect(completed.isCompleted, isTrue);

      // Step 4: Revert completed task within allowable window
      provider.revertTask(firstTask.id);
      final reverted = provider.currentEmployeeTasks.firstWhere((t) => t.id == firstTask.id);
      expect(reverted.isCompleted, isFalse);

      // Step 5: Personal Notes CRUD
      provider.addPersonalNote(
        title: 'VIP Client Wedding Set Followup',
        content: 'Call Mrs. Ananya regarding diamond choker polishing confirmation.',
      );
      final notes = provider.myPersonalNotes;
      expect(notes.any((n) => n.title.contains('VIP Client Wedding Set')), isTrue);

      // Step 6: Emergency Permission Slip Submission
      provider.requestEmergencyPermission(
        empId: '6',
        hours: 1.0,
        reason: 'Bank visit for jewel loan settlement',
        requesterRole: 'Employee',
      );
      expect(provider.permissionRecords.any((p) => p.empId == '6'), isTrue);

      // Step 7: Cross-department blocker submission
      provider.raiseBlocker(
        raisedByDept: 'Sales',
        raisedByName: 'Gokulakrishnan K',
        blockingDept: 'Accounts',
        issue: 'Payment confirmation pending for order #MNJ-8842',
      );
      expect(
        provider.blockers.any((b) => b.issue.contains('MNJ-8842')),
        isTrue,
      );
    });

    // ==========================================
    // 5. KONAR BOOK 5 ARCHITECTURES UI AUDIT
    // ==========================================
    testWidgets('5. Konar Book 5 Architecture Screen Rendering Test', (WidgetTester tester) async {
      provider.setActiveEmpId('MN-TL1002');
      final book = provider.onlineDeptKonarBook;

      expect(book.sections.length, 5);
      expect(book.sections[0].title, '01 PURPOSE');
      expect(book.sections[1].title, '02 GOALS');
      expect(book.sections[2].title, '03 PROCESS');
      expect(book.sections[3].title, '04 STRUCTURE');
      expect(book.sections[4].title, '05 SYSTEM');

      // Test Detail Screen UI
      await tester.pumpWidget(
        ChangeNotifierProvider<EcosystemProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: KonarBookDetailScreen(department: 'Online Department'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Department Core Architecture'), findsOneWidget);
      expect(find.textContaining('5 Operational Pillars'), findsOneWidget);
      expect(find.text('5 Architectures'), findsOneWidget);
      expect(find.text('01 PURPOSE'), findsOneWidget);
      expect(find.text('02 GOALS'), findsOneWidget);
      expect(find.text('03 PROCESS'), findsOneWidget);
      expect(find.text('04 STRUCTURE'), findsOneWidget);
      expect(find.text('05 SYSTEM'), findsOneWidget);
    });
  });
}
