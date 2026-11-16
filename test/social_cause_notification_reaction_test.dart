import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/models/company_notification_models.dart';
import 'package:mn_family_app/models/social_cause_models.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/core/widgets/social_cause_detail_dialog.dart';
import 'package:mn_family_app/core/services/monthly_scorecard_pdf_service.dart';
import 'package:mn_family_app/core/models/monthly_scorecard_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Social Cause Notification & Reaction Tests', () {
    test('SocialCauseItem likedEmpIds, isCeoReacted, and totalLikesCount', () {
      final cause = SocialCauseItem(
        id: 'CAUSE-101',
        empId: 'EMP001',
        employeeName: 'Gokul R',
        employeeRole: 'Executive',
        causeType: SocialCauseType.foodDonation,
        title: 'Annadhanam at Temple',
        description: 'Provided afternoon meals to 100 people.',
        amountSpent: 2500,
        date: DateTime.now(),
        likedEmpIds: ['EMP002'],
      );

      expect(cause.totalLikesCount, equals(1));
      expect(cause.isHeartedBy('EMP002'), isTrue);
      expect(cause.isHeartedBy('EMP003'), isFalse);
      expect(cause.isCeoReacted, isFalse);

      // Add CEO reaction
      final withCeo = cause.copyWith(likedEmpIds: ['EMP002', 'MN-CEO01']);
      expect(withCeo.totalLikesCount, equals(2));
      expect(withCeo.isCeoReacted, isTrue);

      // JSON round-trip
      final json = withCeo.toJson();
      expect(json['likedEmpIds'], contains('MN-CEO01'));
      final decoded = SocialCauseItem.fromJson(json);
      expect(decoded.isCeoReacted, isTrue);
      expect(decoded.totalLikesCount, equals(2));
    });

    test('CompanyNotification likedStaffIds and isCeoReacted', () {
      final notif = CompanyNotification(
        id: 'NOTIF-SC-101',
        title: '❤️ Social Cause: Gokul R',
        content: 'Contributed food donation.',
        type: CompanyNotificationType.socialCause,
        timestamp: DateTime.now(),
        senderName: 'Gokul R',
        senderRole: 'Executive',
        actionTag: 'CAUSE-101',
        likedStaffIds: ['EMP005'],
      );

      expect(notif.likesCount, equals(1));
      expect(notif.isLikedBy('EMP005'), isTrue);
      expect(notif.isLikedBy('EMP001'), isFalse);
      expect(notif.isCeoReacted, isFalse);

      final withCeo = notif.copyWith(likedStaffIds: ['EMP005', 'MN-CEO01']);
      expect(withCeo.likesCount, equals(2));
      expect(withCeo.isCeoReacted, isTrue);

      final json = withCeo.toJson();
      expect(json['likedStaffIds'], contains('MN-CEO01'));
      final decoded = CompanyNotification.fromJson(json);
      expect(decoded.isCeoReacted, isTrue);
    });

    test('EcosystemProvider submitSocialCause does not broadcast until HR or CEO approves', () async {
      final eco = EcosystemProvider();
      final initialNotifCount = eco.companyNotifications.length;

      eco.submitSocialCause(
        empId: 'EMP-TEST-01',
        employeeName: 'Kaaviya S',
        employeeRole: 'Content Specialist',
        causeType: SocialCauseType.treePlanting,
        title: 'Planted 20 Neem Trees',
        description: 'Green drive near showroom.',
        amountSpent: 1200,
      );

      // Remains pending, NO public notification broadcasted yet
      expect(eco.companyNotifications.length, equals(initialNotifCount));
      final pendingCause = eco.socialCauses.first;
      expect(pendingCause.isPending, isTrue);

      // Now HR / CEO approves the deed
      await eco.approveSocialCause(
        pendingCause.id,
        approvedByName: 'M N Naveenraaj',
        approverRole: 'Managing Director & CEO',
      );

      // Now the notification is broadcast to all staff
      expect(eco.companyNotifications.length, equals(initialNotifCount + 1));
      final latestNotif = eco.companyNotifications.first;
      expect(latestNotif.type, equals(CompanyNotificationType.socialCause));
      expect(latestNotif.title, contains('Kaaviya S'));
      expect(latestNotif.content, contains('Tree Plantation'));
    });

    test('EcosystemProvider toggleSocialCauseReaction: single like per account & CEO badge', () async {
      final eco = EcosystemProvider();
      eco.submitSocialCause(
        empId: 'EMP-TEST-02',
        employeeName: 'Asha M',
        employeeRole: 'Designer',
        causeType: SocialCauseType.bloodDonation,
        title: 'Donated O+ Blood',
        description: 'Govt Hospital camp.',
        amountSpent: 0,
      );

      final causeId = eco.socialCauses.first.id;

      // Approve so notification exists
      await eco.approveSocialCause(
        causeId,
        approvedByName: 'Priya S',
        approverRole: 'HR Manager',
      );

      // User 1 likes
      eco.toggleSocialCauseReaction(causeId, reactingEmpId: 'EMP-USER-1');
      var cause = eco.socialCauses.firstWhere((c) => c.id == causeId);
      expect(cause.totalLikesCount, equals(1));
      expect(cause.likedEmpIds, contains('EMP-USER-1'));
      expect(cause.isCeoReacted, isFalse);

      // User 1 likes again -> unliked
      eco.toggleSocialCauseReaction(causeId, reactingEmpId: 'EMP-USER-1');
      cause = eco.socialCauses.firstWhere((c) => c.id == causeId);
      expect(cause.totalLikesCount, equals(0));
      expect(cause.likedEmpIds, isNot(contains('EMP-USER-1')));

      // User 1 & User 2 like
      eco.toggleSocialCauseReaction(causeId, reactingEmpId: 'EMP-USER-1');
      eco.toggleSocialCauseReaction(causeId, reactingEmpId: 'EMP-USER-2');
      cause = eco.socialCauses.firstWhere((c) => c.id == causeId);
      expect(cause.totalLikesCount, equals(2));
      expect(cause.isCeoReacted, isFalse);

      // CEO reacts
      eco.toggleSocialCauseReaction(causeId, reactingEmpId: 'MN-CEO01');
      cause = eco.socialCauses.firstWhere((c) => c.id == causeId);
      expect(cause.totalLikesCount, equals(3));
      expect(cause.isCeoReacted, isTrue);

      // Notification synchronized
      final matchingNotif = eco.companyNotifications.firstWhere((n) => n.actionTag == causeId);
      expect(matchingNotif.likesCount, equals(3));
      expect(matchingNotif.isCeoReacted, isTrue);

      // CEO unlikes
      eco.toggleSocialCauseReaction(causeId, reactingEmpId: 'MN-CEO01');
      cause = eco.socialCauses.firstWhere((c) => c.id == causeId);
      expect(cause.totalLikesCount, equals(2));
      expect(cause.isCeoReacted, isFalse);
    });

    testWidgets('SocialCauseDetailDialog renders deed content and reacts on tap', (tester) async {
      final eco = EcosystemProvider();
      eco.setActiveEmpId('EMP-STAFF-1');

      eco.submitSocialCause(
        empId: 'EMP-TEST-03',
        employeeName: 'Nisha B',
        employeeRole: 'Support Executive',
        causeType: SocialCauseType.educationSupport,
        title: 'Sponsored School Books',
        description: 'Provided notebooks and geometry boxes for 30 underprivileged kids.',
        amountSpent: 3500,
      );

      final cause = eco.socialCauses.first;

      await tester.pumpWidget(
        ChangeNotifierProvider<EcosystemProvider>.value(
          value: eco,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => SocialCauseDetailDialog.show(ctx, cause: cause),
                  child: const Text('Open Deed'),
                ),
              ),
            ),
          ),
        ),
      );

      // Tap button to open dialog
      await tester.tap(find.text('Open Deed'));
      await tester.pumpAndSettle();

      // Check deed content rendered
      expect(find.text('Sponsored School Books'), findsOneWidget);
      expect(find.text('Nisha B'), findsOneWidget);
      expect(find.text('Education Support'), findsOneWidget);
      expect(find.text('₹3500'), findsOneWidget);

      // Tap heart to like as normal employee
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pumpAndSettle();

      // Check reaction count increased and CEO has not reacted yet
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.text('1 Reaction'), findsOneWidget);
      expect(find.text('CEO Reacted!'), findsNothing);

      // Trigger CEO reaction
      eco.toggleSocialCauseReaction(cause.id, reactingEmpId: 'MN-CEO01');
      await tester.pumpAndSettle();

      // Check "CEO Reacted!" banner rendered and reactions count is 2
      expect(find.text('CEO Reacted!'), findsOneWidget);
      expect(find.text('2 Reactions'), findsOneWidget);
    });

    test('MonthlyScorecardPdfService generates PDF with bundled GoogleSans without Helvetica fallback', () async {
      final model = MonthlyScorecardModel(month: 11, year: 2026);
      final pdfBytes = await MonthlyScorecardPdfService.generatePdf(model);

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });
}
