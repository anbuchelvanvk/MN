import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/pillar_kit.dart';
import '../../providers/ecosystem_provider.dart';

/// The four commitment cards on Home.
enum PillarKind { health, family, work, social }

/// One row: what today's target is and how much is done.
class TodayTarget {
  final IconData icon;
  final String label;
  final double done;
  final double target; // 0 = no target, just a count
  final String Function(double) format;
  final String? note;
  const TodayTarget(this.icon, this.label, this.done, this.target, this.format, {this.note});

  double get ratio => target <= 0 ? (done > 0 ? 1 : 0) : (done / target).clamp(0.0, 1.0);
  bool get met => target > 0 && done >= target;
}

String _n(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
String _thousands(double v) =>
    v.round().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
String _rupees(double v) => '₹${_thousands(v)}';
String _hm(double mins) => '${mins ~/ 60}h ${(mins % 60).round()}m';
String _hours(double h) => '${_n(h)}h';

/// Today's targets for [kind], worked out from the signed-in person's own data.
({String title, Color color, IconData icon, List<TodayTarget> rows, List<String> extra}) todayTargetsFor(
  EcosystemProvider eco,
  PillarKind kind, {
  DateTime? now,
}) {
  final d = now ?? DateTime.now();
  final today = DateTime(d.year, d.month, d.day);
  switch (kind) {
    case PillarKind.health:
      final m = eco.macrosForDate(today);
      final g = eco.macroGoals;
      final kcalTarget = eco.dailyCalorieTarget > 0 ? eco.dailyCalorieTarget : 2000.0;
      return (
        title: 'Health',
        color: const Color(0xFF0E9F6E),
        icon: Icons.favorite_rounded,
        rows: [
          TodayTarget(Icons.local_fire_department_rounded, 'Calories eaten', eco.getCaloriesConsumedForDate(today),
              kcalTarget, (v) => '${_thousands(v)} kcal'),
          TodayTarget(Icons.directions_walk_rounded, 'Steps', eco.getStepsForDate(today).toDouble(),
              eco.dailyStepGoal.toDouble(), _thousands),
          TodayTarget(Icons.local_drink_rounded, 'Water', eco.getWaterForDate(today).toDouble(),
              eco.waterGoalGlasses.toDouble(), (v) => '${_n(v)} glasses'),
          TodayTarget(Icons.bedtime_rounded, 'Sleep', eco.getSleepMinutesForDate(today).toDouble(),
              eco.sleepGoalMinutes.toDouble(), _hm),
          TodayTarget(Icons.fitness_center_rounded, 'Workout', eco.getWorkoutMinutesForDate(today).toDouble(), 30,
              (v) => '${_n(v)} min', note: '30 min a day suggested'),
          TodayTarget(Icons.restaurant_rounded, 'Meals logged', eco.getFoodLogsForDate(today).length.toDouble(), 3,
              (v) => _n(v)),
          TodayTarget(Icons.egg_alt_rounded, 'Protein', m.protein, g.protein, (v) => '${_n(v.roundToDouble())} g'),
          TodayTarget(Icons.rice_bowl_rounded, 'Carbs', m.carbs, g.carbs, (v) => '${_n(v.roundToDouble())} g'),
          TodayTarget(Icons.opacity_rounded, 'Fat', m.fat, g.fat, (v) => '${_n(v.roundToDouble())} g'),
          TodayTarget(Icons.grass_rounded, 'Fibre', m.fibre, g.fibre, (v) => '${_n(v.roundToDouble())} g'),
        ],
        extra: ['Burned today: ${_thousands(eco.getCaloriesBurnedForDate(today))} kcal'],
      );
    case PillarKind.family:
      final logs = eco.getFamilyActivitiesForDate(today);
      final family = logs.where((a) => a.category == 'Family').fold(0.0, (s, a) => s + a.hoursSpent);
      final friends = logs.where((a) => a.category != 'Family').fold(0.0, (s, a) => s + a.hoursSpent);
      final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
      final monthFamily = eco.familyActivityLogs
          .where((a) => a.category == 'Family' && a.timestamp.year == today.year && a.timestamp.month == today.month)
          .fold(0.0, (s, a) => s + a.hoursSpent);
      final dailyShare = 30.0 / daysInMonth;
      return (
        title: 'Family Time',
        color: AppColors.violet,
        icon: Icons.family_restroom_rounded,
        rows: [
          TodayTarget(Icons.family_restroom_rounded, 'Family time', family, dailyShare, _hours,
              note: '30h a month ≈ ${_n((dailyShare * 10).roundToDouble() / 10)}h a day'),
          TodayTarget(Icons.groups_rounded, 'Friends & colleagues', friends, 0, _hours),
          TodayTarget(Icons.edit_note_rounded, 'Activities logged', logs.length.toDouble(), 1, (v) => _n(v)),
          TodayTarget(Icons.calendar_month_rounded, 'This month (family)', monthFamily, 30, _hours),
        ],
        extra: [for (final a in logs.take(4)) '${a.iconEmoji} ${a.activityName} • ${_hours(a.hoursSpent)}'],
      );
    case PillarKind.work:
      final tasks = eco.currentEmployeeTasks;
      final done = tasks.where((t) => t.isCompleted).length;
      final pending = tasks.where((t) => t.isPending).toList();
      final later = tasks.where((t) => t.isPostponed).length;
      return (
        title: 'Work',
        color: AppColors.primary,
        icon: Icons.work_rounded,
        rows: [
          TodayTarget(Icons.task_alt_rounded, 'Tasks done', done.toDouble(), tasks.length.toDouble(), (v) => _n(v)),
          TodayTarget(Icons.pending_actions_rounded, 'Still pending', pending.length.toDouble(), 0, (v) => _n(v)),
          TodayTarget(Icons.schedule_rounded, 'Moved to later', later.toDouble(), 0, (v) => _n(v)),
        ],
        extra: [
          for (final t in pending.take(5)) '${t.due.isNotEmpty ? '${t.due} • ' : ''}${t.title}',
          if (pending.length > 5) '+ ${pending.length - 5} more pending',
        ],
      );
    case PillarKind.social:
      final mine = eco.currentEmployeeSocialCauses;
      bool isToday(DateTime t) => t.year == today.year && t.month == today.month && t.day == today.day;
      final approvedToday = eco.myApprovedSocialCauses(today, dayOnly: true);
      final approvedMonth = eco.myApprovedSocialCauses(today);
      final waiting = mine.where((c) => c.isPending).toList();
      final amountDaily = eco.socialAmountPeriod == 'day';
      final countDaily = eco.socialCountPeriod == 'day';
      final todayAmt = approvedToday.fold(0.0, (s, c) => s + c.amountSpent);
      final monthAmt = approvedMonth.fold(0.0, (s, c) => s + c.amountSpent);
      return (
        title: 'Social Service',
        color: const Color(0xFFB7791F),
        icon: Icons.volunteer_activism_rounded,
        rows: [
          TodayTarget(Icons.currency_rupee_rounded, amountDaily ? 'Amount today' : 'Amount today (no daily goal)',
              todayAmt, amountDaily ? eco.socialAmountGoal : 0, _rupees),
          TodayTarget(Icons.calendar_month_rounded, 'Amount this month', monthAmt,
              eco.socialAmountGoalForMonth(today), _rupees),
          TodayTarget(Icons.volunteer_activism_rounded, countDaily ? 'Good deeds today' : 'Good deeds today (no daily goal)',
              approvedToday.length.toDouble(), countDaily ? eco.socialCountGoal.toDouble() : 0, (v) => _n(v)),
          TodayTarget(Icons.event_available_rounded, 'Good deeds this month', approvedMonth.length.toDouble(),
              eco.socialCountGoalForMonth(today).toDouble(), (v) => _n(v)),
        ],
        extra: [
          if (waiting.isNotEmpty)
            '${waiting.length} waiting for approval (not counted yet)',
          for (final c in mine.where((c) => isToday(c.date)).take(3)) '${c.title} • ${_rupees(c.amountSpent)}',
        ],
      );
  }
}

/// Opens the "Today" sheet for a commitment card (long-press on Home).
Future<void> showPillarTodaySheet(BuildContext context, PillarKind kind, {VoidCallback? onOpenFull}) {
  final eco = context.read<EcosystemProvider>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    builder: (ctx) => ChangeNotifierProvider<EcosystemProvider>.value(
      value: eco,
      child: _PillarTodaySheet(kind: kind, onOpenFull: onOpenFull),
    ),
  );
}

class _PillarTodaySheet extends StatelessWidget {
  final PillarKind kind;
  final VoidCallback? onOpenFull;
  const _PillarTodaySheet({required this.kind, this.onOpenFull});

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final t = todayTargetsFor(eco, kind);
    final withTarget = t.rows.where((r) => r.target > 0).toList();
    final met = withTarget.where((r) => r.met).length;
    final overall = withTarget.isEmpty ? 0.0 : withTarget.fold(0.0, (s, r) => s + r.ratio) / withTarget.length;
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        key: Key('pillar_today_${kind.name}'),
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(color: const Color(0xFFEADCE4), borderRadius: BorderRadius.circular(3)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              KitRing(
                progress: overall,
                color: t.color,
                size: 72,
                stroke: 7,
                center: Text('${(overall * 100).round()}%', style: kitTitle(15)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${t.title} • Today', style: kitTitle(19)),
                    Text('${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}', style: kitBody(12.5)),
                    const SizedBox(height: 4),
                    Text(
                      withTarget.isEmpty ? 'No targets set' : '$met of ${withTarget.length} targets met',
                      style: kitTitle(13).copyWith(color: t.color),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final r in t.rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: r.met ? t.color.withOpacity(0.07) : const Color(0xFFFAF6F8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: r.met ? t.color.withOpacity(0.35) : AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(r.icon, size: 18, color: t.color),
                        const SizedBox(width: 8),
                        Expanded(child: Text(r.label, style: kitTitle(13.5))),
                        Text(
                          r.target > 0 ? '${r.format(r.done)} / ${r.format(r.target)}' : r.format(r.done),
                          style: kitTitle(13.5),
                        ),
                        if (r.met) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.check_circle_rounded, size: 16, color: t.color),
                        ],
                      ],
                    ),
                    if (r.target > 0) ...[
                      const SizedBox(height: 8),
                      KitBar(progress: r.ratio, color: t.color, height: 6),
                    ],
                    if (r.note != null) ...[
                      const SizedBox(height: 4),
                      Text(r.note!, style: kitBody(11)),
                    ],
                  ],
                ),
              ),
            ),
          if (t.extra.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(kind == PillarKind.work ? 'Next up' : 'Today', style: kitTitle(14)),
            const SizedBox(height: 6),
            for (final line in t.extra)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle, size: 6, color: t.color),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(line, style: kitBody(13))),
                  ],
                ),
              ),
          ],
          if (onOpenFull != null) ...[
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const Key('pillar_today_open'),
              onPressed: () {
                Navigator.pop(context);
                onOpenFull!();
              },
              icon: Icon(t.icon, size: 18),
              label: Text('Open ${t.title}'),
            ),
          ],
        ],
      ),
    );
  }
}
