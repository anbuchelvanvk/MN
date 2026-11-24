import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/core/services/google_drive_upload_service.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/media/creative_media_review_board_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Feature 4: Creative Production & Media Review Board (DAM Pipeline) Tests', () {
    test('GoogleDriveUploadService points to user-specified Media Review Board folder', () {
      expect(GoogleDriveUploadService.mediaFolderId, equals('1zfY6b6xuI8GOT1cfUOw3DpXa2u81-BX2'));
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
      expect(find.text('Media Review'), findsOneWidget);
      expect(find.textContaining('Photoshoots and reels'), findsOneWidget);

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
}
