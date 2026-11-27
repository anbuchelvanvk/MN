import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/chat/floating_chat_window.dart';

/// Regression: with the keyboard open, the group chat in the floating window
/// shrank twice for the keyboard. The message list got no height, so older
/// messages and newly sent ones could not be seen.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('group chat shows messages and a sent message with the keyboard open', (tester) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final eco = EcosystemProvider();
    await eco.loginWithFirebase(email: 'kaaviyaos1@mnj.com', password: 'x');
    await eco.sendChatMessage(receiverId: 'ALL_HANDS', text: 'Earlier message in the group');

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: eco,
      child: MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => FloatingChatWindow.show(ctx, start: FloatingChatStart.allHands),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Keyboard comes up (about 40% of the screen, like a phone keyboard).
    tester.view.viewInsets = const FakeViewPadding(bottom: 340);
    await tester.pumpAndSettle();

    // The earlier message is still visible with real height.
    final earlier = find.text('Earlier message in the group');
    expect(earlier, findsOneWidget);
    expect(tester.getSize(earlier).height, greaterThan(0));
    final list = find.byType(ListView).first;
    expect(tester.getSize(list).height, greaterThan(80));

    // Type and send: the new message shows up in the list.
    await tester.enterText(find.byType(TextField).last, 'Hello from the floating chat');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pumpAndSettle();
    expect(find.text('Hello from the floating chat'), findsOneWidget);
    expect(
      eco.getConversation('ALL_HANDS').any((m) => m.text == 'Hello from the floating chat'),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
