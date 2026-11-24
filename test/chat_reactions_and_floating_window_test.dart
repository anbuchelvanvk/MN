import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/models/chat_message_model.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/chat/chat_hub_screen.dart';
import 'package:mn_family_app/views/chat/floating_chat_window.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Chat emoji reactions', () {
    test('reactions are stored per person per emoji and counted', () {
      final msg = ChatMessage(
        id: 'm1',
        senderId: '65',
        senderName: 'Kaaviya',
        senderRole: 'OS1',
        receiverId: 'ALL_HANDS',
        text: 'hello',
        timestamp: DateTime(2026, 11, 24),
        reactions: const ['65|👍', '67|👍', '67|❤️'],
      );
      expect(msg.reactionCounts, {'👍': 2, '❤️': 1});
      expect(msg.hasReacted('67', '❤️'), isTrue);
      expect(msg.hasReacted('65', '❤️'), isFalse);

      final roundTrip = ChatMessage.fromJson(msg.toJson());
      expect(roundTrip.reactions, msg.reactions);
    });

    test('toggleChatReaction adds then removes the current user reaction', () async {
      final eco = EcosystemProvider();
      await eco.loginWithFirebase(email: 'kaaviyaos1@mnj.com', password: 'x');
      await eco.sendChatMessage(receiverId: 'ALL_HANDS', text: 'Good morning team');
      final msg = eco.chatMessages.last;

      eco.toggleChatReaction(msg.id, '🙏');
      expect(eco.chatMessages.last.hasReacted(eco.activeEmpId, '🙏'), isTrue);

      eco.toggleChatReaction(msg.id, '🙏');
      expect(eco.chatMessages.last.hasReacted(eco.activeEmpId, '🙏'), isFalse);
    });
  });

  testWidgets('Team chat opens as a floating window and closes', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final eco = EcosystemProvider();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: eco,
      child: MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => FloatingChatWindow.show(ctx),
                child: const Text('open chat'),
              ),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ChatHubScreen), findsOneWidget);
    // The page underneath is still there (floating, not a new full page)
    expect(find.text('open chat'), findsOneWidget);

    await tester.tap(find.byTooltip('Close chat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ChatHubScreen), findsNothing);
  });
}
