import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/core/theme/app_theme.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/ceo/ceo_teams_screen.dart';
import 'package:mn_family_app/views/home/home_highlights_card.dart';

Widget host(EcosystemProvider eco, Widget child) => ChangeNotifierProvider.value(
      value: eco,
      child: MaterialApp(theme: AppThemes.whiteMagentaTheme, home: Scaffold(body: child)),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('special days: a birthday shows today and a week ahead, not later', (tester) async {
    final eco = EcosystemProvider();
    await tester.runAsync(() => eco.loginWithFirebase(email: 'ceoofmn@mnjpark.com', password: 'x'));
    final withDob = eco.employees.where((e) => EcosystemProvider.parseDob(e.dob) != null).toList();
    expect(withDob, isNotEmpty, reason: 'the staff list should have dates of birth');
    final person = withDob.first;
    final dob = EcosystemProvider.parseDob(person.dob)!;
    final first = person.name.split(' ').first;

    // On the day itself.
    final onDay = buildHomeHighlights(eco, now: DateTime(2027, dob.month, dob.day, 9));
    final today = onDay.where((h) => h.kind == 'birthday' && h.person?.id == person.id).toList();
    expect(today, hasLength(1));
    expect(today.single.isToday, isTrue);
    expect(today.single.meta, 'Today');
    // Special days come before notices.
    expect(onDay.first.kind, anyOf('birthday', 'work', 'wedding'));

    // Three days before: "In 3 days".
    final before = DateTime(2027, dob.month, dob.day).subtract(const Duration(days: 3));
    final soon = buildHomeHighlights(eco, now: before)
        .where((h) => h.kind == 'birthday' && h.person?.id == person.id)
        .toList();
    expect(soon, hasLength(1));
    expect(soon.single.meta, 'In 3 days');
    expect(soon.single.title, contains(first));

    // Twenty days before: not shown.
    final far = DateTime(2027, dob.month, dob.day).subtract(const Duration(days: 20));
    expect(
      buildHomeHighlights(eco, now: far).where((h) => h.kind == 'birthday' && h.person?.id == person.id),
      isEmpty,
    );
  });

  testWidgets('highlights card moves to the next item every 10 seconds and on swipe', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final eco = EcosystemProvider();
    await tester.runAsync(() => eco.loginWithFirebase(email: 'ceoofmn@mnjpark.com', password: 'x'));
    final items = buildHomeHighlights(eco);

    await tester.pumpWidget(host(eco, const Padding(padding: EdgeInsets.all(16), child: HomeHighlightsCard())));
    await tester.pumpAndSettle();

    if (items.isEmpty) {
      expect(find.byKey(const Key('home_highlights_empty')), findsOneWidget);
      return;
    }
    expect(find.text(items[0].title), findsOneWidget);
    if (items.length < 2) return;

    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();
    expect(find.text(items[1].title), findsOneWidget);

    // Swipe back to the first one.
    await tester.fling(find.byKey(const Key('home_highlights')), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text(items[0].title), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CEO Teams lists every department and opens one with live numbers', (tester) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final eco = EcosystemProvider();
    await tester.runAsync(() => eco.loginWithFirebase(email: 'ceoofmn@mnjpark.com', password: 'x'));

    await tester.pumpWidget(host(eco, const CeoTeamsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('MN Family today'), findsOneWidget);
    for (final d in eco.availableDepartments) {
      expect(find.byKey(Key('dept_card_$d')), findsOneWidget, reason: d);
    }

    // Online Department: its people are listed with their own task progress.
    final online = eco.availableDepartments.firstWhere(EcosystemProvider.isOnlineDept);
    final snap = DeptSnapshot.of(eco, online);
    await tester.tap(find.byKey(Key('dept_card_$online')));
    await tester.pumpAndSettle();
    expect(find.byType(DepartmentDashboardScreen), findsOneWidget);
    expect(find.text('Overall performance'), findsOneWidget);
    expect(find.text('Attendance today'), findsOneWidget);
    expect(find.text('People (${snap.members.length})'), findsOneWidget);
    expect(snap.tasks.length, eco.tasks.where((t) => snap.members.any((m) => m.id == t.empId)).length);
    expect(tester.takeException(), isNull);
  });
}
