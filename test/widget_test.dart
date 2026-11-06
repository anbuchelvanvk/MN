import 'package:flutter_test/flutter_test.dart';
import 'package:mn_family_app/main.dart';
import 'package:provider/provider.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => EcosystemProvider(),
        child: const MnFamilyApp(),
      ),
    );

    expect(find.text('MN JEWEL PARK'), findsOneWidget);
  });
}
