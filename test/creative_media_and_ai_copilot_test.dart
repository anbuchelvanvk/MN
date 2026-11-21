import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/core/services/google_drive_upload_service.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/services/mn_ai_copilot_service.dart';
import 'package:mn_family_app/views/media/creative_media_review_board_screen.dart';
import 'package:mn_family_app/views/copilot/mn_assistant_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Feature 4: Creative Production & Media Review Board (DAM Pipeline) Tests', () {
    test('GoogleDriveUploadService points to user-specified Media Review Board folder', () {
      expect(GoogleDriveUploadService.mediaFolderId, equals('1zfY6b6xuI8GOT1cfUOw3DpXa2u81-BX2'));
    });

    test('MnAiCopilotService welcome message provides clean operational summary without 5 Konar Books or personalized copilot banner', () {
      final eco = EcosystemProvider();
      final welcome = MnAiCopilotService.buildWelcomeMessage(eco);

      expect(welcome, contains('daily operational summary'));
      expect(welcome, contains(MnAiCopilotService.extractFirstName(eco.currentEmployee.name)));
      expect(welcome, contains("Today's Attendance:"));
      expect(welcome, contains('Active Tasks / To-Dos:'));
      expect(welcome, contains('Emergency Permissions:'));
      expect(welcome, isNot(contains('5 Konar Books')));
      expect(welcome, isNot(contains('5 Official KONAR Books')));
      expect(welcome, isNot(contains('Personalized Copilot for')));
      expect(welcome, isNot(contains('I have analyzed your live employee profile')));
    });

    test('EcosystemProvider initializes with zero mock data and clean empty state', () {
      final eco = EcosystemProvider();
      expect(eco.mediaAssets.isEmpty, isTrue);
      expect(eco.pendingMediaApprovalsCount, equals(0));
      expect(eco.approvedMediaCount, equals(0));
    });

    test('Creator submits new draft and transitions through CEO approval workflow', () async {
      final eco = EcosystemProvider();
      expect(eco.mediaAssets.isEmpty, isTrue);

      // 1. Submit a new media draft
      await eco.submitCreativeMediaAsset(
        title: 'New Diamond Bangle 4K Macro Reel',
        description: 'VVS Diamond clarity demonstration under showroom studio lighting.',
        category: 'Reel',
        collectionTag: 'Diamond & Polki',
        driveUrl: 'https://drive.google.com/file/d/test_123/preview',
        captionDraft: 'Dazzling brilliance. #MNJewelPark #Diamonds',
        targetChannels: ['Instagram', 'YouTube'],
      );

      expect(eco.mediaAssets.length, equals(1));
      final submitted = eco.mediaAssets.first;
      expect(submitted.title, 'New Diamond Bangle 4K Macro Reel');
      expect(submitted.isPendingReview, isTrue);
      expect(submitted.comments.length, equals(1));

      // 2. CEO requests changes
      await eco.reviewCreativeMediaAsset(
        assetId: submitted.id,
        newStatus: 'revisions_requested',
        feedbackNote: 'Add price range and certificate card in frame 3.',
      );

      final revised = eco.mediaAssets.firstWhere((a) => a.id == submitted.id);
      expect(revised.isRevisionsRequested, isTrue);
      expect(revised.comments.last.isExecutiveNote, isTrue);
      expect(revised.comments.last.comment, contains('Add price range'));

      // 3. Collaborative feedback comment added
      await eco.addMediaAssetComment(
        assetId: submitted.id,
        comment: 'Adjusted frame 3 with BIS 916 card. Re-uploaded to Drive.',
      );

      final updated = eco.mediaAssets.firstWhere((a) => a.id == submitted.id);
      expect(updated.comments.last.comment, contains('Adjusted frame 3'));

      // 4. CEO approves for social media
      await eco.reviewCreativeMediaAsset(
        assetId: submitted.id,
        newStatus: 'approved_by_ceo',
        feedbackNote: 'Approved for posting on Instagram.',
      );

      final approved = eco.mediaAssets.firstWhere((a) => a.id == submitted.id);
      expect(approved.isApprovedByCeo, isTrue);

      // 5. Mark as published
      await eco.markMediaAssetPublished(
        assetId: submitted.id,
        publishedUrl: 'https://instagram.com/reel/mn_test_reel',
      );

      final published = eco.mediaAssets.firstWhere((a) => a.id == submitted.id);
      expect(published.isPublished, isTrue);
      expect(published.publishedUrl, 'https://instagram.com/reel/mn_test_reel');
    });

    testWidgets('CreativeMediaReviewBoardScreen renders clean empty state and submission CTA', (tester) async {
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
            child: const CreativeMediaReviewBoardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Screen Title
      expect(find.text('Creative & Media Review Board'), findsOneWidget);
      expect(find.textContaining('DAM Pipeline'), findsOneWidget);

      // Verify Metrics starting at 0
      expect(find.text('Total Drafts'), findsOneWidget);
      expect(find.text('Pending Review'), findsOneWidget);
      expect(find.text('Revisions'), findsOneWidget);

      // Verify Empty State when zero mock data is present
      expect(find.text('No Media Assets Found'), findsOneWidget);

      // Verify Floating Action Button
      expect(find.text('Submit Media Draft'), findsOneWidget);
    });
  });

  group('Feature 6: Personalized AI Copilot ("MN Assistant") Tests', () {
    test('MnAiCopilotService personalizes responses with user name and handles typos', () {
      final eco = EcosystemProvider();
      final currentEmp = eco.currentEmployee;

      // Typo-tolerant query: "permisson" instead of "permission"
      final res = MnAiCopilotService.processQuery(
        query: 'How many emergency permisson do I have remaining this month?',
        eco: eco,
      );

      expect(res.text, contains('Emergency Permission Quota'));
      expect(res.text, contains(currentEmp.name));
      expect(res.actionType, equals(CopilotActionType.openEmergencyPermission));
      expect(res.actionLabel, isNotNull);
    });

    test('MnAiCopilotService resolves jewelry photography SOP checklist with typos', () {
      final eco = EcosystemProvider();
      // Typo-tolerant query: "photograpy" instead of "photography"
      final res = MnAiCopilotService.processQuery(
        query: 'What is the standard handover checklist for jewelry photograpy?',
        eco: eco,
      );

      expect(res.text, contains('Jewelry Photography & Handover SOP'));
      expect(res.text, contains('916 BIS Hallmark'));
      expect(res.text, contains('Dual Sign-off Workflow'));
      expect(res.actionType, equals(CopilotActionType.openMediaReviewBoard));
    });

    test('MnAiCopilotService provides identity breakdown on "who am i"', () {
      final eco = EcosystemProvider();
      final currentEmp = eco.currentEmployee;
      final res = MnAiCopilotService.processQuery(
        query: 'who am i in this app?',
        eco: eco,
      );

      expect(res.text, contains('Employee Profile Analysis'));
      expect(res.text, contains(currentEmp.name));
      expect(res.text, contains(currentEmp.dept));
    });

    test('MnAiCopilotService summarizes cross-department blockers with typos', () {
      final eco = EcosystemProvider();
      final res = MnAiCopilotService.processQuery(
        query: 'Summarize today open cross dept blokers for OTM.',
        eco: eco,
      );

      expect(res.text, contains('Blockers'));
    });

    test('MnAiCopilotService details 12-month Instagram reel and content goals', () {
      final eco = EcosystemProvider();
      final res = MnAiCopilotService.processQuery(
        query: 'What is our weekly instgram reel target and goals?',
        eco: eco,
      );

      expect(res.text, contains('7 Content Reels / week'));
      expect(res.text, contains('3 Daily Stories'));
      expect(res.text, contains('58K ➔ 100K Followers'));
    });

    test('MnAiCopilotService resolves corporate directory lookup', () {
      final eco = EcosystemProvider();
      final res = MnAiCopilotService.processQuery(
        query: 'Who is developer Eshwar and what is his email?',
        eco: eco,
      );

      expect(res.text, contains('Corporate Directory'));
      expect(res.text, contains('Eshwar'));
      expect(res.text, contains('DVP'));
    });

    test('MnAiCopilotService resolves broken grammar, chat shorthand & human typing errors', () {
      final eco = EcosystemProvider();

      // 1. Slang + broken grammar for permission: "i wnt go out 1hr permisson pls"
      final r1 = MnAiCopilotService.processQuery(
        query: 'i wnt go out 1hr permisson pls',
        eco: eco,
      );
      expect(r1.text, contains('Emergency Permission Quota'));

      // 2. Chat shorthand + bad grammar for tasks: "today my wrk pendng list tell"
      final r2 = MnAiCopilotService.processQuery(
        query: 'today my wrk pendng list tell',
        eco: eco,
      );
      expect(r2.text, contains('Active Work & Task Breakdown'));

      // 3. Typo + grammar slip for punch timings: "pnch time hw mch grace i hav"
      final r3 = MnAiCopilotService.processQuery(
        query: 'pnch time hw mch grace i hav',
        eco: eco,
      );
      expect(r3.text, contains('Attendance & Biometric Shift Policy'));

      // 4. Missing verbs + slang for camera shoot: "camra shoot items return when"
      final r4 = MnAiCopilotService.processQuery(
        query: 'camra shoot items return when',
        eco: eco,
      );
      expect(r4.text, contains('Jewelry Photography & Handover SOP'));

      // 5. Short informal prompt for blockers: "who is team blckr"
      final r5 = MnAiCopilotService.processQuery(
        query: 'who is team blckr',
        eco: eco,
      );
      expect(r5.text, contains('Blockers'));

      // 6. Tanglish shorthand for reels goal: "rel target weekly how mch"
      final r6 = MnAiCopilotService.processQuery(
        query: 'rel target weekly how mch',
        eco: eco,
      );
      expect(r6.text, contains('12-Month Omnichannel Goals'));
    });

    testWidgets('MnAssistantSheet renders personalized header, welcome message, and accepts natural typing', (tester) async {
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
            child: const Scaffold(
              body: MnAssistantSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header: Clean MN Assistant branding without PERSONALIZED badge or 5 Konar Books
      expect(find.text('MN Assistant'), findsOneWidget);
      expect(find.text('PERSONALIZED'), findsNothing);
      expect(find.textContaining('5 Konar Books'), findsNothing);
      expect(find.text('Live SOP & Policy Knowledge Engine'), findsOneWidget);

      // Verify Welcome message addressing user by first name cleanly without preamble
      final firstName = MnAiCopilotService.extractFirstName(eco.currentEmployee.name);
      expect(find.textContaining(firstName), findsWidgets);

      // Enter a hand-typed question with a minor typo
      final inputFinder = find.byType(TextField);
      expect(inputFinder, findsOneWidget);
      await tester.enterText(inputFinder, 'how many permisson do i have left?');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Verify that AI responded with permission quota
      expect(find.textContaining('Emergency Permission Quota'), findsOneWidget);
    });
  });
}
