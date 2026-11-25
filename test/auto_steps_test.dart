import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/core/services/auto_steps_service.dart';
import 'package:mn_family_app/core/theme/app_theme.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/pillars/auto_steps_panel.dart';

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

Future<EcosystemProvider> signedIn() async {
  final eco = EcosystemProvider();
  await eco.loginWithFirebase(email: 'kaaviyaos1@mnj.com', password: 'x');
  return eco;
}

Widget host(EcosystemProvider eco) => ChangeNotifierProvider.value(
      value: eco,
      child: MaterialApp(
        theme: AppThemes.whiteMagentaTheme,
        home: const Scaffold(body: Padding(padding: EdgeInsets.all(16), child: AutoStepsPanel())),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final today = dayOnly(DateTime.now());
  final yesterday = today.subtract(const Duration(days: 1));

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    AutoStepsService.debugStatus = null;
    AutoStepsService.debugStepsForDay = null;
    AutoStepsService.debugIsIOS = null;
  });

  test('turning on fills steps from the phone and keeps higher typed numbers', () async {
    AutoStepsService.debugStatus = AutoStepsStatus.on;
    AutoStepsService.debugStepsForDay = (d) {
      if (dayOnly(d) == today) return 4321;
      if (dayOnly(d) == yesterday) return 100;
      return 0;
    };
    final eco = await signedIn();
    eco.recordDailySteps(date: yesterday, steps: 500);

    expect(await eco.enableAutoSteps(), AutoStepsStatus.on);
    expect(eco.autoStepsEnabled, isTrue);
    expect(eco.getStepsForDate(today), 4321);
    expect(eco.getStepsForDate(yesterday), 500, reason: 'typed-in 500 beats the phone\'s 100');
    expect(eco.isAutoStepsDay(today), isTrue);
    expect(eco.autoStepsLastSync, isNotNull);
    expect(eco.autoStepsNoData, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('auto_steps_${eco.currentEmployee.id}'), isTrue);

    await eco.disableAutoSteps();
    expect(eco.autoStepsEnabled, isFalse);
    expect(eco.autoStepsStatus, AutoStepsStatus.off);
    expect(eco.getStepsForDate(today), 4321, reason: 'saved steps stay after turning off');
  });

  test('refused access leaves it off', () async {
    AutoStepsService.debugStatus = AutoStepsStatus.needsPermission;
    final eco = await signedIn();
    expect(await eco.enableAutoSteps(), AutoStepsStatus.needsPermission);
    expect(eco.autoStepsEnabled, isFalse);
  });

  test('no steps at all this week is flagged', () async {
    AutoStepsService.debugStatus = AutoStepsStatus.on;
    AutoStepsService.debugStepsForDay = (_) => 0;
    final eco = await signedIn();
    await eco.enableAutoSteps();
    expect(eco.autoStepsNoData, isTrue);
  });

  testWidgets('panel on a desktop/test host says it works on phones', (tester) async {
    final eco = EcosystemProvider();
    await tester.pumpWidget(host(eco));
    expect(find.textContaining('Works in the phone app'), findsOneWidget);
    expect(find.byKey(const Key('auto_steps_switch')), findsNothing);
  });

  testWidgets('iPhone: switch on, Apple Health wording, settings hint when empty', (tester) async {
    AutoStepsService.debugStatus = AutoStepsStatus.on;
    AutoStepsService.debugIsIOS = true;
    AutoStepsService.debugStepsForDay = (_) => 0;
    final eco = await tester.runAsync(signedIn);
    await tester.pumpWidget(host(eco!));
    expect(find.text('Auto-count steps'), findsOneWidget);
    expect(find.textContaining('Apple Health'), findsOneWidget);

    await tester.tap(find.byKey(const Key('auto_steps_switch')));
    await tester.pumpAndSettle();
    expect(find.text('Count steps automatically?'), findsOneWidget); // explainer first
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    expect(eco.autoStepsEnabled, isTrue);
    expect(find.textContaining('Data Access & Devices'), findsOneWidget);
    expect(find.byKey(const Key('auto_steps_refresh')), findsOneWidget);
  });

  testWidgets('Android: Health Connect missing shows a fix button', (tester) async {
    AutoStepsService.debugStatus = AutoStepsStatus.needsHealthConnect;
    AutoStepsService.debugIsIOS = false;
    final eco = EcosystemProvider();
    await tester.pumpWidget(host(eco));
    await tester.tap(find.byKey(const Key('auto_steps_switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Health Connect needed'), findsOneWidget);
    expect(find.text('Get Health Connect'), findsOneWidget);
    expect(eco.autoStepsEnabled, isFalse);
  });
}
