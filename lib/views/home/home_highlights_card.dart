import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/company_notification_sheet.dart';
import '../../core/widgets/employee_avatar.dart';
import '../../models/company_notification_models.dart';
import '../../models/employee_model.dart';
import '../../providers/ecosystem_provider.dart';

/// One slide in the Home highlights card.
class HomeHighlight {
  final String kind; // 'birthday' | 'work' | 'wedding' | notification type name
  final String title;
  final String body;
  final String meta;
  final IconData icon;
  final List<Color> colors;
  final Employee? person;
  final bool isToday;
  const HomeHighlight({
    required this.kind,
    required this.title,
    required this.body,
    required this.meta,
    required this.icon,
    required this.colors,
    this.person,
    this.isToday = false,
  });
}

/// Special days (today and the next 7 days) first, then current notices.
List<HomeHighlight> buildHomeHighlights(EcosystemProvider eco, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final specials = <(int, HomeHighlight)>[];

  /// Days until the next yearly repeat of [d] (0 = today), or null if more than a week.
  int? daysUntil(DateTime d) {
    var next = DateTime(today.year, d.month, d.day == 29 && d.month == 2 ? 28 : d.day);
    if (next.isBefore(today)) next = DateTime(today.year + 1, d.month, d.day);
    final diff = next.difference(today).inDays;
    return diff <= 7 ? diff : null;
  }

  String when(int days) => days == 0 ? 'Today' : (days == 1 ? 'Tomorrow' : 'In $days days');

  for (final e in eco.employees) {
    if (e.name.trim().isEmpty) continue;
    final first = e.name.split(' ').first;
    final isMe = e.id == eco.activeEmpId;

    final dob = EcosystemProvider.parseDob(e.dob);
    final dBirth = dob == null ? null : daysUntil(dob);
    if (dBirth != null) {
      specials.add((
        dBirth,
        HomeHighlight(
          kind: 'birthday',
          title: dBirth == 0 ? (isMe ? 'Happy birthday to you! 🎂' : 'Happy birthday, $first! 🎂') : '$first\'s birthday',
          body: dBirth == 0
              ? (isMe ? 'The whole MN Family is celebrating you today.' : 'Send ${e.name} your wishes today.')
              : '${e.name} • ${e.straightCutDesignation}',
          meta: when(dBirth),
          icon: Icons.cake_rounded,
          colors: const [Color(0xFFF59E0B), Color(0xFFDB2777)],
          person: e,
          isToday: dBirth == 0,
        ),
      ));
    }

    final joined = EcosystemProvider.parseDob(e.doj) ?? e.joinedAt;
    if (joined != null && joined.year < today.year) {
      final dWork = daysUntil(joined);
      if (dWork != null) {
        final next = DateTime(today.year + (DateTime(today.year, joined.month, joined.day).isBefore(today) ? 1 : 0),
            joined.month, joined.day);
        final years = next.year - joined.year;
        if (years > 0) {
          specials.add((
            dWork,
            HomeHighlight(
              kind: 'work',
              title: dWork == 0
                  ? '$years year${years == 1 ? '' : 's'} with MN Jewel Park! 🎉'
                  : '$first\'s work anniversary',
              body: dWork == 0
                  ? '${isMe ? 'You complete' : '${e.name} completes'} $years year${years == 1 ? '' : 's'} with us today.'
                  : '${e.name} • $years year${years == 1 ? '' : 's'}',
              meta: when(dWork),
              icon: Icons.workspace_premium_rounded,
              colors: const [Color(0xFF7C3AED), Color(0xFF2563EB)],
              person: e,
              isToday: dWork == 0,
            ),
          ));
        }
      }
    }

    final wed = EcosystemProvider.parseDob(e.anniversaryDate);
    final dWed = wed == null ? null : daysUntil(wed);
    if (dWed != null) {
      specials.add((
        dWed,
        HomeHighlight(
          kind: 'wedding',
          title: dWed == 0 ? 'Happy anniversary, $first! 💐' : '$first\'s wedding anniversary',
          body: dWed == 0 ? 'Wishing ${isMe ? 'you' : e.name} and family a lovely day.' : e.name,
          meta: when(dWed),
          icon: Icons.favorite_rounded,
          colors: const [Color(0xFFE11D48), Color(0xFF9D174D)],
          person: e,
          isToday: dWed == 0,
        ),
      ));
    }
  }
  specials.sort((a, b) => a.$1.compareTo(b.$1));

  String ago(DateTime t) {
    final d = n.difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    return '${d.inDays} d ago';
  }

  final notices = eco.activeCompanyNotifications
      // Birthdays and anniversaries are already shown from the staff list.
      .where((x) => x.type != CompanyNotificationType.birthday && x.type != CompanyNotificationType.anniversary)
      .take(10)
      .map((x) {
    final (IconData icon, List<Color> colors) = switch (x.type) {
      CompanyNotificationType.socialCause => (Icons.volunteer_activism_rounded, const [Color(0xFF0F766E), Color(0xFF059669)]),
      CompanyNotificationType.todoReminder => (Icons.task_alt_rounded, const [Color(0xFFD97706), Color(0xFFEA580C)]),
      _ => (Icons.campaign_rounded, const [Color(0xFF881337), Color(0xFFE11D48)]),
    };
    return HomeHighlight(
      kind: x.type.name,
      title: x.title,
      body: x.content,
      meta: '${x.senderName.isNotEmpty ? '${x.senderName} • ' : ''}${ago(x.timestamp)}',
      icon: icon,
      colors: colors,
    );
  });

  return [for (final s in specials) s.$2, ...notices];
}

/// Home: a card that shows special days and the latest notices one by one,
/// moving on every 10 seconds (swipe to move yourself).
class HomeHighlightsCard extends StatefulWidget {
  final Duration interval;
  const HomeHighlightsCard({super.key, this.interval = const Duration(seconds: 10)});

  @override
  State<HomeHighlightsCard> createState() => _HomeHighlightsCardState();
}

class _HomeHighlightsCardState extends State<HomeHighlightsCard> {
  int _index = 0;
  int _direction = 1;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (_) => _step(1));
  }

  void _step(int by) {
    if (!mounted) return;
    setState(() {
      _direction = by;
      _index += by;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final items = buildHomeHighlights(eco);
    if (items.isEmpty) return _emptyCard();
    final i = ((_index % items.length) + items.length) % items.length;
    final item = items[i];

    return GestureDetector(
      key: const Key('home_highlights'),
      onTap: () => CompanyNotificationSheet.show(context),
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v.abs() < 120) return;
        _step(v < 0 ? 1 : -1);
        _restartTimer();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        height: 132,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: item.colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: item.colors.last.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Soft glow rings
              Positioned(
                right: -30,
                top: -40,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [Color(0x40FFFFFF), Color(0x00FFFFFF)]),
                  ),
                ),
              ),
              Positioned(
                left: -40,
                bottom: -60,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x1AFFFFFF), width: 18),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) {
                          final incoming = child.key == ValueKey('hl_$i');
                          final dx = (incoming ? 0.25 : -0.25) * _direction;
                          return FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(begin: Offset(dx, 0), end: Offset.zero).animate(anim),
                              child: child,
                            ),
                          );
                        },
                        child: _slide(item, key: ValueKey('hl_$i')),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _livePill(items.length),
                        const Spacer(),
                        for (var d = 0; d < items.length && d < 8; d++)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(left: 4),
                            width: d == i % 8 ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: d == i % 8 ? Colors.white : Colors.white.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slide(HomeHighlight item, {required Key key}) {
    final lead = item.person != null
        ? Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: EmployeeAvatar(avatar: item.person!.avatar, initials: item.person!.initials, size: 50),
          )
        : Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.35)),
            ),
            child: Icon(item.icon, color: Colors.white, size: 26),
          );
    return Row(
      key: key,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            lead,
            if (item.person != null)
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: item.colors.first, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                  child: Icon(item.icon, size: 12, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
              ),
              const SizedBox(height: 3),
              Text(
                item.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w500, color: const Color(0xF2FFFFFF), height: 1.3),
              ),
              const SizedBox(height: 4),
              Text(
                item.meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xCCFFFFFF)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _livePill(int count) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF86EFAC), shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(
              count == 1 ? 'Live • 1 update' : 'Live • $count updates',
              style: GoogleFonts.outfit(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ],
        ),
      );

  Widget _emptyCard() => Container(
        key: const Key('home_highlights_empty'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.line),
          boxShadow: AppColors.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AppColors.primarySoft, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.done_all_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('All caught up',
                      style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  Text('New notices and special days will show here.',
                      style: GoogleFonts.outfit(fontSize: 12.5, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      );
}
