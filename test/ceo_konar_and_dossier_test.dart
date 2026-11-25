import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/core/theme/app_theme.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/hr/hr_portal_subpages.dart';
import 'package:mn_family_app/views/konar/konar_books_directory_screen.dart';

Widget host(EcosystemProvider eco, Widget child) => ChangeNotifierProvider.value(
      value: eco,
      child: MaterialApp(theme: AppThemes.whiteMagentaTheme, home: child),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('CEO can add a Konar Book for a department without one', (tester) async {
    tester.view.physicalSize = const Size(420, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final eco = EcosystemProvider();
    await tester.runAsync(() => eco.loginWithFirebase(email: 'ceoofmn@mnjpark.com', password: 'x'));
    await tester.runAsync(() => eco.createNewDepartment('Showroom Floor'));
    final before = eco.konarBooks.length;

    await tester.pumpWidget(host(eco, const KonarBooksDirectoryScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add_konar_book')));
    await tester.pumpAndSettle();
    expect(find.text('New Konar Book'), findsOneWidget);

    await tester.tap(find.byKey(const Key('konar_new_dept')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Showroom Floor').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('konar_create')));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(eco.konarBooks.length, before + 1);
    expect(eco.konarBooks.any((b) => b.department == 'Showroom Floor'), isTrue);
  });

  testWidgets('Staff directory no longer shows passwords', (tester) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final eco = EcosystemProvider();
    await tester.runAsync(() => eco.loginWithFirebase(email: 'hr@mnj.com', password: 'x'));
    await tester.pumpWidget(host(eco, const HrStaffDirectoryScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Password:'), findsNothing);
    expect(find.text('Reset'), findsWidgets);
  });
}
