import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mn_family_app/core/legal/legal_content.dart';
import 'package:mn_family_app/core/widgets/legal_links.dart';
import 'package:mn_family_app/views/legal/legal_screen.dart';

void main() {
  Widget host() => MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                for (final p in LegalPage.values)
                  TextButton(key: Key('open_${p.slug}'), onPressed: () => p.open(context), child: Text(p.title)),
              ],
            ),
          ),
        ),
      );

  testWidgets('Privacy Policy opens in the app with every section', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(host());
    await tester.tap(find.byKey(const Key('open_privacy')));
    await tester.pumpAndSettle();

    expect(find.byType(LegalScreen), findsOneWidget);
    expect(find.text(privacyPolicy.lead), findsOneWidget);

    // Contents list jumps to a section
    await tester.tap(find.byKey(const Key('legal_contents_toggle')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deleting your account').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Delete my MN Family account'), findsOneWidget);

    // Every section heading is there
    for (final s in privacyPolicy.sections) {
      await tester.scrollUntilVisible(find.text(s.title).last, 300,
          scrollable: find.descendant(of: find.byKey(const Key('legal_scroll')), matching: find.byType(Scrollable)));
      expect(find.text(s.title), findsWidgets);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Terms open in the app and link to the Privacy Policy', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(host());
    await tester.tap(find.byKey(const Key('open_terms')));
    await tester.pumpAndSettle();
    expect(find.text(termsAndConditions.lead), findsOneWidget);

    await tester.scrollUntilVisible(find.byKey(const Key('legal_other_doc')), 600,
        scrollable: find.descendant(of: find.byKey(const Key('legal_scroll')), matching: find.byType(Scrollable)));
    await tester.tap(find.byKey(const Key('legal_other_doc')));
    await tester.pumpAndSettle();
    expect(find.text(privacyPolicy.lead), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
