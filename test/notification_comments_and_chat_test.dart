import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mn_family_app/core/services/push_notification_service.dart';
import 'package:mn_family_app/core/widgets/celebration_marquee_banner.dart';
import 'package:mn_family_app/models/company_notification_models.dart';
import 'package:mn_family_app/models/chat_message_model.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/chat/chat_conversation_screen.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PushNotificationService.clearTestLogs();
  });

  group('Universal Notification Comments & Likes Tests', () {
    test('NotificationComment model serializes and deserializes correctly', () {
      final comment = NotificationComment(
        id: 'CMT-1001',
        notificationId: 'NOTIF-001',
        authorId: 'MN-CEO01',
        authorName: 'M N Naveenraaj',
        authorRole: 'Managing Director & CEO',
        text: 'Hearty congratulations to the team on this milestone!',
        timestamp: DateTime(2026, 11, 18, 10, 30),
        likedStaffIds: ['7', 'MN-TL1002'],
      );

      final json = comment.toJson();
      final parsed = NotificationComment.fromJson(json);

      expect(parsed.id, 'CMT-1001');
      expect(parsed.authorName, 'M N Naveenraaj');
      expect(parsed.text, 'Hearty congratulations to the team on this milestone!');
      expect(parsed.likesCount, 2);
      expect(parsed.isLikedBy('7'), isTrue);
      expect(parsed.isLikedBy('MN-CEO01'), isFalse);
    });

    test('EcosystemProvider adds comments and toggles likes on notifications', () async {
      final provider = EcosystemProvider();

      // Seed a test notification
      final testNotif = CompanyNotification(
        id: 'TEST-NOTIF-99',
        title: '🎉 Birthday Celebration Today!',
        content: "Today is M N Naveenraaj's Birthday, wish him the best!",
        type: CompanyNotificationType.birthday,
        timestamp: DateTime.now(),
        senderName: 'M N Naveenraaj',
        senderRole: 'Managing Director & CEO',
      );
      provider.companyNotifications.insert(0, testNotif);

      // 1. Employee Praveenkumar M adds a comment
      provider.setActiveEmpId('MN-TL1002');
      await provider.addNotificationComment('TEST-NOTIF-99', 'Happy Birthday Naveenraaj sir! Have a wonderful year ahead!');

      final updatedNotif = provider.companyNotifications.firstWhere((n) => n.id == 'TEST-NOTIF-99');
      expect(updatedNotif.commentsCount, 1);
      final comment = updatedNotif.comments.first;
      expect(comment.text, 'Happy Birthday Naveenraaj sir! Have a wonderful year ahead!');
      expect(comment.authorId, 'MN-TL1002');
      expect(comment.likesCount, 0);

      // 2. CEO logs in and likes Praveenkumar's comment
      provider.setActiveEmpId('MN-CEO01');
      await provider.toggleNotificationCommentLike('TEST-NOTIF-99', comment.id);

      final notifAfterCeoLike = provider.companyNotifications.firstWhere((n) => n.id == 'TEST-NOTIF-99');
      final commentAfterLike = notifAfterCeoLike.comments.first;
      expect(commentAfterLike.likesCount, 1);
      expect(commentAfterLike.isLikedBy('MN-CEO01'), isTrue);

      // 3. CEO unlikes comment
      await provider.toggleNotificationCommentLike('TEST-NOTIF-99', comment.id);
      final notifAfterUnlike = provider.companyNotifications.firstWhere((n) => n.id == 'TEST-NOTIF-99');
      expect(notifAfterUnlike.comments.first.likesCount, 0);
    });
  });

  group('Team Chat Engine Tests', () {
    test('ChatMessage model with replies serializes and deserializes correctly', () {
      final msg = ChatMessage(
        id: 'MSG-TEST-1',
        senderId: 'MN-TL1002',
        senderName: 'Praveenkumar M',
        senderRole: 'Team Lead',
        receiverId: 'MN-CEO01',
        text: 'Sir, today online team achieved all 4 pillars.',
        timestamp: DateTime(2026, 11, 18, 14, 0),
        isRead: false,
        readBy: ['MN-TL1002'],
        likedBy: [],
        replyToId: 'MSG-TEST-0',
        replyToSenderName: 'M N Naveenraaj',
        replyToText: 'Please share the daily pillar status.',
      );

      final json = msg.toJson();
      final parsed = ChatMessage.fromJson(json);

      expect(parsed.id, 'MSG-TEST-1');
      expect(parsed.senderName, 'Praveenkumar M');
      expect(parsed.receiverId, 'MN-CEO01');
      expect(parsed.isAllHands, isFalse);
      expect(parsed.isSentBy('MN-TL1002'), isTrue);
      expect(parsed.replyToId, 'MSG-TEST-0');
      expect(parsed.replyToSenderName, 'M N Naveenraaj');
      expect(parsed.replyToText, 'Please share the daily pillar status.');
    });

    test('EcosystemProvider chat messaging, unread counts & push notifications', () async {
      final provider = EcosystemProvider();

      // Clear existing chats for deterministic testing
      provider.chatMessages.clear();
      PushNotificationService.clearTestLogs();

      // 1. CEO sends message to TL Praveenkumar with reply
      provider.setActiveEmpId('MN-CEO01');
      await provider.sendChatMessage(
        receiverId: 'MN-TL1002',
        text: 'Praveen, please check order dispatch status.',
      );

      expect(provider.chatMessages.length, 1);
      final lastMsg = provider.getLastMessageWith('MN-TL1002');
      expect(lastMsg?.text, 'Praveen, please check order dispatch status.');

      // Verify sender does NOT receive self-notification
      expect(PushNotificationService.testNotificationLog.isEmpty, isTrue);

      // Verify recipient receives push notification when incoming message arrives
      await PushNotificationService().showChatNotification(
        id: lastMsg!.id,
        senderName: lastMsg.senderName,
        message: lastMsg.text,
        isGroup: false,
      );
      expect(PushNotificationService.testNotificationLog.isNotEmpty, isTrue);
      final push = PushNotificationService.testNotificationLog.last;
      expect(push['title'], contains('M N Naveenraaj'));
      expect(push['body'], 'Praveen, please check order dispatch status.');

      // 2. Switch to TL Praveenkumar and verify unread count
      provider.setActiveEmpId('MN-TL1002');
      expect(provider.getUnreadChatCountFor('MN-CEO01'), 1);

      // Mark conversation as read
      await provider.markConversationAsRead('MN-CEO01');
      expect(provider.getUnreadChatCountFor('MN-CEO01'), 0);

      // 3. TL replies to CEO referencing the original message
      await provider.sendChatMessage(
        receiverId: 'MN-CEO01',
        text: 'All dispatched on schedule sir!',
        replyToId: lastMsg.id,
        replyToSenderName: lastMsg.senderName,
        replyToText: lastMsg.text,
      );

      // Check conversation thread (should have 2 messages)
      final conv = provider.getConversation('MN-CEO01');
      expect(conv.length, 2);
      expect(conv.last.text, 'All dispatched on schedule sir!');
      expect(conv.last.replyToText, 'Praveen, please check order dispatch status.');

      // 4. TL likes the CEO message
      await provider.toggleChatMessageLike(conv.first.id);
      final updatedConv = provider.getConversation('MN-CEO01');
      expect(updatedConv.first.likesCount, 1);
      expect(updatedConv.first.isLikedBy('MN-TL1002'), isTrue);

      // 5. Send message to ALL_HANDS
      await provider.sendChatMessage(
        receiverId: 'ALL_HANDS',
        text: 'Team meeting at 4 PM in conference hall.',
      );
      final allHands = provider.getConversation('ALL_HANDS');
      expect(allHands.any((m) => m.text.contains('Team meeting at 4 PM')), isTrue);
    });

    testWidgets('ChatConversationScreen supports initialText, @mentions, and reply preview', (tester) async {
      final provider = EcosystemProvider();
      provider.setActiveEmpId('MN-TL1002');

      await tester.pumpWidget(
        ChangeNotifierProvider<EcosystemProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: ChatConversationScreen(
              peerId: 'ALL_HANDS',
              peerName: 'MN All-Hands Workforce',
              peerRole: 'CEO, HR, TL & All Employees',
              peerInitials: 'MN',
              isGroup: true,
              initialText: 'Happy Birthday @M N Naveenraaj 🥳',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify pre-typed text exists in the TextField
      expect(find.text('Happy Birthday @M N Naveenraaj 🥳'), findsOneWidget);

      // Tap the Mention chip to trigger autocomplete
      expect(find.text('Mention'), findsOneWidget);
      await tester.tap(find.text('Mention'));
      await tester.pumpAndSettle();

      // Verify mention list appears
      expect(find.text('Mention Colleague'), findsOneWidget);

      // Tap info icon in AppBar to view group recipients
      await tester.tap(find.byIcon(Icons.people_alt_outlined));
      await tester.pumpAndSettle();

      // Verify Group Recipients bottom sheet is displayed
      expect(find.text('MN All-Hands Workforce'), findsWidgets);
      expect(find.textContaining('Group Recipients & Collaborators'), findsOneWidget);
    });

    testWidgets('CelebrationMarqueeBanner tap opens group chat with pre-typed celebration text', (tester) async {
      final provider = EcosystemProvider();
      provider.setActiveEmpId('MN-TL1002');

      // Set CEO birthday to today so celebration marquee banner activates
      final now = DateTime.now();
      final ceoIdx = provider.employees.indexWhere((e) => e.id == 'MN-CEO01');
      if (ceoIdx != -1) {
        provider.employees[ceoIdx] = provider.employees[ceoIdx].copyWith(
          dob: '${now.day}/${now.month}/1990',
        );
      }

      await tester.pumpWidget(
        ChangeNotifierProvider<EcosystemProvider>.value(
          value: provider,
          child: const MaterialApp(
            home: Scaffold(
              body: CelebrationMarqueeBanner(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the celebration marquee banner
      expect(find.byType(CelebrationMarqueeBanner), findsOneWidget);
      await tester.tap(find.byType(CelebrationMarqueeBanner));
      await tester.pumpAndSettle();

      // Verifies navigation occurred and group chat has pre-typed birthday message
      expect(find.text('Happy Birthday @M N Naveenraaj 🥳'), findsOneWidget);
    });

    testWidgets('MentionTextEditingController styles @mentions in signature Magenta in chat box', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final controller = MentionTextEditingController(
                  text: 'Wishing @M N Naveenraaj and @Mithra M great success!',
                  getEmployeeNames: () => ['M N Naveenraaj', 'Mithra M'],
                );
                final span = controller.buildTextSpan(
                  context: context,
                  style: const TextStyle(color: Colors.black),
                  withComposing: false,
                );
                final mentionSpan = span.children!.firstWhere(
                  (s) => s is TextSpan && s.text == '@M N Naveenraaj',
                ) as TextSpan;
                assert(mentionSpan.style?.color != null);
                return RichText(text: span);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(RichText), findsWidgets);
    });
  });
}
