import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/core/theme/app_theme.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/home/modern_home_screen.dart';
import 'package:mn_family_app/views/home/pillar_today_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('today targets follow the person\'s own data and goals', (tester) async {
    final eco = EcosystemProvider();
    await tester.runAsync(() => eco.loginWithFirebase(email: 'gokulakrishnanosh@mnj.com', password: 'x'));
    final now = DateTime.now();
    eco.recordDailySteps(date: now, steps: 3000);
    eco.setWaterForDate(now, 4);
    eco.setWaterGoalGlasses(10);

    final h = todayTargetsFor(eco, PillarKind.health);
    final steps = h.rows.firstWhere((r) => r.label == 'Steps');
    expect(steps.done, 3000);
    expect(steps.target, eco.dailyStepGoal.toDouble());
    final water = h.rows.firstWhere((r) => r.label == 'Water');
    expect(water.done, 4);
    expect(water.target, 10);
    expect(water.ratio, closeTo(0.4, 0.001));
    expect(water.met, isFalse);
    expect(h.rows.firstWhere((r) => r.label == 'Calories eaten').target, eco.dailyCalorieTarget);

    final w = todayTargetsFor(eco, PillarKind.work);
    final tasks = eco.currentEmployeeTasks;
    expect(w.rows.first.target, tasks.length.toDouble());
    expect(w.rows.first.done, tasks.where((t) => t.isCompleted).length.toDouble());

    final s = todayTargetsFor(eco, PillarKind.social);
    expect(s.title, 'Social Service');
    expect(s.rows[1].target, eco.socialAmountGoalForMonth(now));
  });

  testWidgets('holding a commitment card on Home opens today\'s targets', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    final eco = EcosystemProvider();
    await tester.runAsync(() => eco.loginWithFirebase(email: 'gokulakrishnanosh@mnj.com', password: 'x'));

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: eco,
      child: MaterialApp(theme: AppThemes.burgundySandTheme, home: const ModernHomeScreen()),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Your commitments'), findsOneWidget);
    expect(find.text('Social Service'), findsOneWidget);

    for (final (title, kind) in [
      ('Health', PillarKind.health),
      ('Family Time', PillarKind.family),
      ('Work', PillarKind.work),
      ('Social Service', PillarKind.social),
    ]) {
      await tester.longPress(find.byKey(Key('pillar_card_$title')));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('pillar_today_${kind.name}')), findsOneWidget, reason: title);
      expect(find.text('$title • Today'), findsOneWidget);
      // Close the sheet
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('pillar_today_${kind.name}')), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });
}
