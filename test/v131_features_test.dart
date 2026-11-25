import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mn_family_app/core/models/daily_scorecard_model.dart';
import 'package:mn_family_app/core/models/monthly_scorecard_model.dart';
import 'package:mn_family_app/core/services/daily_scorecard_service.dart';
import 'package:mn_family_app/core/widgets/employee_avatar.dart';
import 'package:mn_family_app/core/widgets/person_avatar.dart';
import 'package:mn_family_app/providers/ecosystem_provider.dart';
import 'package:mn_family_app/views/shell/roles_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('team lead announcement reaches only their own team', () async {
    final eco = EcosystemProvider();
    await eco.loginWithFirebase(email: 'praveenkumarotm@mnj.com', password: 'x');
    final team = eco.myTeamMembers.map((e) => e.id).where((id) => id != eco.activeEmpId).toSet();
    expect(team, isNotEmpty);
    expect(eco.announceToMyTeam('', 'body'), 0, reason: 'a title is required');
    final sent = eco.announceToMyTeam('Meeting at 5', 'Please join in the cabin.');
    expect(sent, team.length);
    final n = eco.companyNotifications.first;
    expect(n.title, contains('Meeting at 5'));
    expect(n.targetEmpIds.toSet(), team);
    expect(n.isTargetedFor('MN-CEO01'), isFalse);
    expect(n.isTargetedFor(eco.activeEmpId), isFalse);
  });

  test('assigned task can be today-only or a daily default', () async {
    final eco = EcosystemProvider();
    await eco.loginWithFirebase(email: 'praveenkumarotm@mnj.com', password: 'x');
    final member = eco.myTeamMembers.firstWhere((e) => e.id != eco.activeEmpId);
    eco.assignTask(
      empId: member.id,
      title: 'One-off check',
      category: 'Operations',
      priority: 'High',
      due: '03:15 PM',
      assignedByRole: 'Team Lead',
      assignedByName: 'Praveenkumar M',
    );
    eco.assignTask(
      empId: member.id,
      title: 'Daily stock count',
      category: 'Operations',
      priority: 'Medium',
      due: '06:40 PM',
      assignedByRole: 'Team Lead',
      assignedByName: 'Praveenkumar M',
      daily: true,
    );
    final once = eco.tasks.firstWhere((t) => t.title == 'One-off check');
    final daily = eco.tasks.firstWhere((t) => t.title == 'Daily stock count');
    expect(once.isDefaultSop, isFalse);
    expect(once.due, '03:15 PM');
    expect(daily.isDefaultSop, isTrue);
    expect(daily.due, '06:40 PM');
    expect(eco.companyNotifications.first.title, startsWith('New Daily Task'));
  });

  test('water, sleep and macros are kept per day', () {
    final eco = EcosystemProvider();
    final today = DateTime.now();
    eco.setWaterForDate(today, 5);
    eco.setSleepMinutesForDate(today, 7 * 60 + 30);
    expect(eco.getWaterForDate(today), 5);
    expect(eco.getSleepMinutesForDate(today), 450);
    expect(eco.getWaterForDate(today.subtract(const Duration(days: 1))), 0);
    eco.setWaterForDate(today, -3);
    expect(eco.getWaterForDate(today), 0);

    final before = eco.macrosForDate(today);
    eco.addFoodLog(foodName: 'Idli', mealType: 'Breakfast', grams: 120, calories: 300, logDate: today);
    final after = eco.macrosForDate(today);
    expect(after.protein, greaterThan(before.protein));
    expect(after.carbs, greaterThan(after.protein));
    expect(eco.macroGoals.protein, greaterThan(0));
  });

  test('daily scorecard scores and adds up into the month', () {
    final d1 = DailyScorecardModel.blank(DateTime(2026, 11, 24));
    final d2 = DailyScorecardModel.blank(DateTime(2026, 11, 25));
    expect(d1.totalScore, 0);
    expect(d1.channels.fold<int>(0, (s, c) => s + c.weight), 100);
    for (final c in d1.channels) {
      for (final i in c.items) {
        i.done = i.target;
      }
    }
    expect(d1.totalScore, 100);
    d2.item('instagram', 'stories')!.done = 2;

    final back = DailyScorecardModel.fromJson(d1.toJson());
    expect(back.totalScore, 100);

    final month = MonthlyScorecardModel(month: 11, year: 2026);
    DailyScorecardService.applyToMonthly(month, [d1, d2]);
    final storyTarget = d1.item('instagram', 'stories')!.target * 2;
    expect(month.instaStoriesTarget, storyTarget);
    expect(month.instaStoriesActual, d1.item('instagram', 'stories')!.target + 2);
  });

  testWidgets('a new profile photo shows up wherever PersonAvatar is used', (tester) async {
    final eco = EcosystemProvider();
    final emp = eco.allEmployees.first;
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: eco,
      child: MaterialApp(home: Scaffold(body: PersonAvatar(empId: emp.id, size: 40))),
    ));
    expect(find.byType(EmployeeAvatar), findsOneWidget);
    final av = tester.widget<EmployeeAvatar>(find.byType(EmployeeAvatar));
    expect(av.avatar, emp.avatar);
    // Unknown people fall back to their initials.
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: eco,
      child: const MaterialApp(home: Scaffold(body: PersonAvatar(name: 'Zed Unknown', size: 40))),
    ));
    expect(find.text('ZU'), findsOneWidget);
  });

  testWidgets('role guide lists duties for each role', (tester) async {
    final eco = EcosystemProvider();
    await eco.loginWithFirebase(email: 'praveenkumarotm@mnj.com', password: 'x');
    final member = eco.myTeamMembers.firstWhere((e) => e.id != eco.activeEmpId && !e.isCeo);
    final guide = RoleGuide.of(member, eco);
    expect(guide.duties, isNotEmpty);
    final lead = RoleGuide.of(eco.currentEmployee, eco);
    expect(lead.label, contains('Team Lead'));
  });
}
