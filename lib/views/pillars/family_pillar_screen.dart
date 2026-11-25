import '../../core/widgets/pillar_hero_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/image_preview_dialog.dart';
import '../../models/family_models.dart';
import '../../providers/ecosystem_provider.dart';
import '../../services/image_optimization_service.dart';
import '../../core/widgets/mn_app_bar.dart';
import '../../core/widgets/pillar_kit.dart';

/// User-friendly duration formatter:
/// - Under 1 hour (e.g. 0.8 hrs): represented as minutes (48 mins)
/// - Whole hours: 1 hr, 2 hrs
/// - Fractional hours: 1 hr 30 mins
String formatDuration(double hours, {bool showPlus = false, bool isCompact = false}) {
  if (hours <= 0) return isCompact ? '0m' : '0 mins';
  final totalMinutes = (hours * 60).round();
  final prefix = showPlus ? '+' : '';
  if (totalMinutes < 60) {
    return isCompact ? '$prefix${totalMinutes}m' : '$prefix$totalMinutes mins';
  }
  final wholeHours = totalMinutes ~/ 60;
  final remainingMinutes = totalMinutes % 60;
  if (remainingMinutes == 0) {
    if (isCompact) return '$prefix${wholeHours}h';
    return wholeHours == 1 ? '$prefix$wholeHours hr' : '$prefix$wholeHours hrs';
  }
  if (isCompact) return '$prefix${wholeHours}h ${remainingMinutes}m';
  return wholeHours == 1
      ? '$prefix$wholeHours hr $remainingMinutes mins'
      : '$prefix$wholeHours hrs $remainingMinutes mins';
}

class FamilyPillarScreen extends StatefulWidget {
  const FamilyPillarScreen({super.key});

  @override
  State<FamilyPillarScreen> createState() => _FamilyPillarScreenState();
}

class _FamilyPillarScreenState extends State<FamilyPillarScreen> {
  int _selectedSectionIndex = 0; // 0: Family Time, 1: Friends Time, 2: How You Spent Time (Logger), 3: Activity Diary
  String _diaryFilter = 'All'; // 'All', 'Family', 'Friends & Colleagues'
  DateTime _selectedDate = DateTime.now();
  bool _showAllHistory = false;

  static const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isPastDate(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    return target.isBefore(today) || target.isAfter(today);
  }

  String? _activityPhotoUrl;

  String _formatDayLabel(DateTime d) {
    if (_isToday(d)) return 'Today (${d.day} ${_months[d.month - 1].substring(0, 3)})';
    return '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1].substring(0, 3)}';
  }

  String _formatDayShort(DateTime d) {
    if (_isToday(d)) return 'Today';
    return '${d.day} ${_months[d.month - 1].substring(0, 3)}';
  }

  // Activity Logger Form Controllers & State
  String _logCategory = 'Family'; // 'Family' or 'Friends & Colleagues'
  String _selectedPresetName = '';
  String _selectedEmoji = '👨‍👩‍👧‍👦';
  String _selectedSubCategory = '';
  double _loggedHours = 1.0;
  final TextEditingController _customActivityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Family Welfare Settings
  final TextEditingController _emergencyContactController = TextEditingController();
  final TextEditingController _familyMembersController = TextEditingController();
  bool _dinnerTogetherToday = false;


  @override
  void dispose() {
    _customActivityController.dispose();
    _notesController.dispose();
    _emergencyContactController.dispose();
    _familyMembersController.dispose();
    super.dispose();
  }

  void _selectPreset(FamilyActivityPreset preset) {
    setState(() {
      _selectedPresetName = preset.name;
      _selectedEmoji = preset.iconEmoji;
      _selectedSubCategory = preset.subCategory;
      _loggedHours = preset.defaultHours;
      _customActivityController.text = preset.name;
    });
  }

  void _onCategorySwitched(String category) {
    setState(() {
      _logCategory = category;
      if (category == 'Family') {
        _selectPreset(FamilyActivityPreset.familyPresets.first);
      } else {
        _selectPreset(FamilyActivityPreset.friendsColleaguesPresets.first);
      }
    });
  }

  void _submitActivity(EcosystemProvider eco) {
    if (_isPastDate(_selectedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.ragRed,
          content: Text('Cannot log entries for past dates. Previous dates are view & delete only.'),
        ),
      );
      return;
    }

    final activityName = _customActivityController.text.trim();
    if (activityName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.ragRed,
          content: Text('Please enter or select an activity name.'),
        ),
      );
      return;
    }

    if (_loggedHours <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.ragRed,
          content: Text('Please specify hours greater than 0.'),
        ),
      );
      return;
    }

    eco.addFamilyActivity(
      activityName: activityName,
      category: _logCategory,
      subCategory: _selectedSubCategory,
      hoursSpent: _loggedHours,
      iconEmoji: _selectedEmoji,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      imageUrl: _activityPhotoUrl,
      date: _selectedDate,
    );

    _notesController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.burgundyPrimary,
        content: Text(
          'Logged "$activityName" ($_loggedHours hrs) for ${_formatDayLabel(_selectedDate)}!',
          style: GoogleFonts.outfit(color: AppColors.sandLight),
        ),
      ),
    );

    // Switch to diary section to view newly logged activity
    setState(() {
      _activityPhotoUrl = null;
      _selectedSectionIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();

    return Scaffold(
      backgroundColor: AppColors.burgundyBg,
      appBar: MnAppBar(
        title: 'Family Time',
        subtitle: '${_formatDayShort(_selectedDate)} • ${formatDuration(eco.getTotalSocialHoursForDate(_selectedDate))} logged',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFamilyHero(eco),
              const SizedBox(height: 16),

              // Horizontal Date Strip (Center Carousel with +/- 3 Days & Month Nav)
              _buildHorizontalDateStrip(eco),
              const SizedBox(height: 16),

              // 4 Interactive Navigation Section Cards
              _buildFourSectionSelector(eco),
              const SizedBox(height: 16),

              // Active Section Content
              _buildActiveSectionContent(context, eco),
              if (eco.isCeo || eco.activeRole.toLowerCase() == 'ceo' || eco.activeRole.toLowerCase() == 'hr') ...[
                const SizedBox(height: 20),
                _buildStaffFamilyActivitiesGateway(context, eco),
              ],
              const SizedBox(height: 85),
            ],
          ),
        ),
      ),
      floatingActionButton: _selectedSectionIndex != 2
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.magentaPrimary,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.add_rounded, size: 22),
              label: Text(
                'Log time',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
              onPressed: () {
                setState(() => _selectedSectionIndex = 2);
              },
            )
          : null,
    );
  }


  Widget _buildFamilyHero(EcosystemProvider eco) {
    final now = DateTime.now();
    final month = eco.familyActivityLogs.where((a) => a.timestamp.year == now.year && a.timestamp.month == now.month);
    final fam = month.where((a) => a.category == 'Family').fold(0.0, (s, a) => s + a.hoursSpent);
    final friends = month.where((a) => a.category != 'Family').fold(0.0, (s, a) => s + a.hoursSpent);
    String h(double v) => v == v.roundToDouble() ? '${v.toStringAsFixed(0)}h' : '${v.toStringAsFixed(1)}h';
    return PillarHeroCard(
      icon: Icons.family_restroom_rounded,
      eyebrow: 'This month',
      headline: '${h(fam)} with family',
      caption: fam >= 30 ? 'Monthly goal reached — lovely!' : '${h(30 - fam)} more to reach the 30h goal',
      progress: fam / 30,
      ringLabel: '${(fam / 30 * 100).clamp(0, 100).round()}%',
      stats: [
        PillarHeroStat(h(eco.totalFamilyHoursToday), 'Today'),
        PillarHeroStat(h(friends), 'Friends'),
        PillarHeroStat('${month.length}', month.length == 1 ? 'Activity' : 'Activities'),
      ],
    );
  }

  // =========================================================================
  // HORIZONTAL DATE STRIP: CENTER DATE CAROUSEL WITH +/- 3 DAYS & MONTH NAV
  // =========================================================================

  Widget _buildHorizontalDateStrip(EcosystemProvider eco) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September',
        'October', 'November', 'December'];
    final d = _selectedDate;
    final logged = eco.getFamilyActivitiesForDate(d).isNotEmpty;
    final isToday = _isToday(d);
    final color = logged ? const Color(0xFF10B981) : (isToday ? AppColors.primary : const Color(0xFFEF4444));
    return KitCard(
      key: const Key('family_date_button'),
      onTap: () => _openFamilyCalendar(eco),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 3)),
            child: Text('${d.day}', style: kitValue(18).copyWith(color: color)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${d.day} ${months[d.month - 1]} ${d.year}', style: kitTitle(16)),
                Text(
                  isToday ? 'Today · tap to pick another day' : (logged ? 'Time logged that day' : 'Nothing logged that day'),
                  style: kitBody(12.5),
                ),
              ],
            ),
          ),
          const Icon(Icons.calendar_month_rounded, color: AppColors.primary),
        ],
      ),
    );
  }

  /// Month calendar: green ring = family/friends time logged that day,
  /// red ring = a past day with nothing logged.
  Future<void> _openFamilyCalendar(EcosystemProvider eco) async {
    var month = DateTime(_selectedDate.year, _selectedDate.month);
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    const names = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September',
        'October', 'November', 'December'];
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          final first = DateTime(month.year, month.month, 1);
          final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
          final lead = first.weekday % 7; // Sunday first
          final canNext = DateTime(month.year, month.month + 1).isBefore(DateTime(today.year, today.month + 1));
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => set(() => month = DateTime(month.year, month.month - 1)),
                        icon: const Icon(Icons.chevron_left_rounded),
                      ),
                      Expanded(
                        child: Text('${names[month.month - 1]} ${month.year}',
                            textAlign: TextAlign.center, style: kitTitle(17)),
                      ),
                      IconButton(
                        onPressed: canNext ? () => set(() => month = DateTime(month.year, month.month + 1)) : null,
                        icon: const Icon(Icons.chevron_right_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      for (final w in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                        Expanded(child: Center(child: Text(w, style: kitBody(12)))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  GridView.count(
                    crossAxisCount: 7,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    children: [
                      for (var i = 0; i < lead; i++) const SizedBox(),
                      for (var day = 1; day <= daysInMonth; day++)
                        Builder(builder: (_) {
                          final date = DateTime(month.year, month.month, day);
                          final future = date.isAfter(todayOnly);
                          final has = eco.getFamilyActivitiesForDate(date).isNotEmpty;
                          final ring = future
                              ? const Color(0xFFE5D5DE)
                              : (has ? const Color(0xFF10B981) : (date == todayOnly ? AppColors.primary : const Color(0xFFEF4444)));
                          final selected = date == DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
                          return InkWell(
                            key: Key('cal_day_$day'),
                            customBorder: const CircleBorder(),
                            onTap: future ? null : () => Navigator.pop(ctx, date),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: selected ? ring.withOpacity(0.15) : null,
                                border: Border.all(color: ring, width: selected ? 3 : 2),
                              ),
                              child: Text('$day',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: future ? AppColors.textMuted : AppColors.textDark,
                                  )),
                            ),
                          );
                        }),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    children: [
                      _legendDot(const Color(0xFF10B981), 'Logged'),
                      _legendDot(const Color(0xFFEF4444), 'Not logged'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Widget _legendDot(Color c, String t) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c, width: 2.5)),
          ),
          const SizedBox(width: 5),
          Text(t, style: kitBody(12)),
        ],
      );

  // =========================================================================
  // 2. FOUR SECTIONS SELECTOR (Top 4 Interactive Modules)
  // =========================================================================

  Widget _buildFourSectionSelector(EcosystemProvider eco) {
    final familyHours = eco.getFamilyHoursForDate(_selectedDate);
    final friendsHours = eco.getFriendsHoursForDate(_selectedDate);

    Widget tile(int index, IconData icon, Color color, String label, String value, String? unit, String caption) =>
        KitStatTile(
          icon: icon,
          color: color,
          label: label,
          value: value,
          unit: unit,
          caption: caption,
          selected: _selectedSectionIndex == index,
          onTap: () => setState(() => _selectedSectionIndex = index),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitSectionHeader('Log by type', subtitle: 'Tap a card to see that day below'),
        const SizedBox(height: 12),
        KitTileGrid(children: [
          tile(0, Icons.family_restroom_rounded, const Color(0xFFE11D48), 'Family Time', formatDuration(familyHours), null,
              familyHours > 0 ? 'Cherished moments' : 'Nothing logged yet'),
          tile(1, Icons.diversity_3_rounded, const Color(0xFF8B5CF6), 'Friends & Peers', formatDuration(friendsHours), null,
              friendsHours > 0 ? 'Good company' : 'Nothing logged yet'),
        ]),
      ],
    );
  }


  // =========================================================================
  // 3. ACTIVE SECTION CONTENT ROUTER
  // =========================================================================

  Widget _buildActiveSectionContent(BuildContext context, EcosystemProvider eco) {
    switch (_selectedSectionIndex) {
      case 0:
        return _buildSection1TotalFamily(context, eco);
      case 1:
        return _buildSection2TotalFriends(context, eco);
      case 2:
        return _buildSection3HowYouSpentTime(context, eco);
      case 3:
      default:
        return _buildSection4ActivityDiary(context, eco);
    }
  }

  // =========================================================================
  // SECTION 1: TOTAL TIME SPENT WITH THE FAMILY
  // =========================================================================

  /// Big "time spent" card shared by Family and Friends.
  Widget _timeHeroCard({
    required BuildContext context,
    required EcosystemProvider eco,
    required double hours,
    required String title,
    required String emptyCaption,
    required String filledCaption,
    required IconData icon,
    required Color color,
    required String quote,
    required void Function(double h) onQuickAdd,
    VoidCallback? onReset,
  }) {
    final day = _isToday(_selectedDate) ? 'Today' : _formatDayShort(_selectedDate);
    return KitCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$day · $title', style: kitBody(13)),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(formatDuration(hours), style: kitValue(38)),
                    ),
                    const SizedBox(height: 4),
                    Text(hours > 0 ? filledCaption : emptyCaption,
                        style: GoogleFonts.outfit(fontSize: 12.5, fontWeight: FontWeight.w600, color: color)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: hours > 0 ? [color.withOpacity(0.85), color] : [color.withOpacity(0.12), color.withOpacity(0.2)],
                  ),
                  boxShadow: hours > 0
                      ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 6))]
                      : null,
                ),
                child: Icon(hours > 0 ? Icons.favorite_rounded : icon, size: 32, color: hours > 0 ? Colors.white : color),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                Icon(Icons.format_quote_rounded, size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(child: Text(quote, style: kitBody(12.5).copyWith(color: AppColors.textDark))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('Quick add', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const Spacer(),
              if (onReset != null && hours > 0)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.ragRed,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  label: const Text('Reset'),
                  onPressed: onReset,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final h in const [0.5, 1.0, 2.0]) ...[
                if (h != 0.5) const SizedBox(width: 8),
                Expanded(
                  child: Material(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        if (_isPastDate(_selectedDate)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.ragRed,
                              content: Text('Past dates are view and delete only.'),
                            ),
                          );
                          return;
                        }
                        onQuickAdd(h);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Text(h == 0.5 ? '+30' : '+${h.toInt()}',
                                style: kitValue(18).copyWith(color: color)),
                            Text(h == 0.5 ? 'minutes' : (h == 1 ? 'hour' : 'hours'), style: kitBody(11.5)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _loggedTodayCard(BuildContext context, EcosystemProvider eco, List<FamilyActivityItem> items,
      {VoidCallback? onResetAll}) {
    return KitCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Logged ${_isToday(_selectedDate) ? 'today' : _formatDayShort(_selectedDate)} (${items.length})', style: kitTitle(15))),
              if (onResetAll != null)
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: AppColors.ragRed),
                  onPressed: onResetAll,
                  child: const Text('Clear all'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (final a in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: Text(a.iconEmoji, style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.activityName,
                              style: GoogleFonts.outfit(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                          Text('${a.category} · ${formatDuration(a.hoursSpent)}', style: kitBody(12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.ragRed),
                      tooltip: 'Delete',
                      onPressed: () {
                        eco.deleteFamilyActivityItem(a);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Removed "${a.activityName}".')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection1TotalFamily(BuildContext context, EcosystemProvider eco) {
    final familyHours = eco.getFamilyHoursForDate(_selectedDate);
    final dateActivities = eco.getFamilyActivitiesForDate(_selectedDate).where((a) => a.category == 'Family').toList();
    void resetAll() {
      eco.resetFamilyHoursForDate(_selectedDate);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Family time cleared for this day.')));
    }

    void openLogger() {
      _onCategorySwitched('Family');
      setState(() => _selectedSectionIndex = 2);
    }

    final members = _familyMembersController.text.trim();
    final emergency = _emergencyContactController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitSectionHeader(
          'Family time',
          subtitle: '${_formatDayLabel(_selectedDate)} · quality time together',
          trailing: KitChipButton(label: 'Log', icon: Icons.add_rounded, onTap: openLogger),
        ),
        const SizedBox(height: 12),
        _timeHeroCard(
          context: context,
          eco: eco,
          hours: familyHours,
          title: 'with family',
          emptyCaption: 'No targets — go at your own pace',
          filledCaption: 'Lovely, cherished time',
          icon: Icons.family_restroom_rounded,
          color: AppColors.primary,
          quote: 'Genuine, stress-free presence with loved ones. Every moment counts.',
          onQuickAdd: (h) {
            eco.addFamilyActivity(
              activityName: 'Quality Family Time',
              category: 'Family',
              subCategory: 'General Bonding',
              hoursSpent: h,
              iconEmoji: '❤️',
              notes: 'Direct family time increment',
              date: _selectedDate,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Added ${formatDuration(h)} of family time for ${_formatDayShort(_selectedDate)}.')),
            );
          },
          onReset: resetAll,
        ),
        if (dateActivities.isNotEmpty) ...[
          const SizedBox(height: 14),
          _loggedTodayCard(context, eco, dateActivities, onResetAll: resetAll),
        ],
        const SizedBox(height: 14),
        KitCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Daily habit', style: kitTitle(15)),
              const SizedBox(height: 10),
              Material(
                color: _dinnerTogetherToday ? const Color(0xFF10B981).withOpacity(0.08) : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  key: const Key('family_dinner_habit'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    final v = !_dinnerTogetherToday;
                    setState(() => _dinnerTogetherToday = v);
                    if (v) {
                      eco.addFamilyActivity(
                        activityName: 'Family Dinner Together',
                        category: 'Family',
                        subCategory: 'Evening Meal',
                        hoursSpent: 1.0,
                        iconEmoji: '🍽️',
                        notes: 'Evening dinner together logged from checklist',
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                    child: Row(
                      children: [
                        const KitIcon(Icons.dinner_dining_rounded, Color(0xFFF97316), size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dinner together tonight',
                                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                              Text('A family meal with phones away', style: kitBody(12)),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _dinnerTogetherToday ? const Color(0xFF10B981) : Colors.white,
                            border: Border.all(
                                color: _dinnerTogetherToday ? const Color(0xFF10B981) : const Color(0xFFD9C7D1), width: 2),
                          ),
                          child: _dinnerTogetherToday
                              ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              KitListRow(
                icon: Icons.groups_rounded,
                color: const Color(0xFF6366F1),
                title: members.isNotEmpty ? members : 'Family members not added',
                subtitle: emergency.isNotEmpty ? 'Emergency: $emergency' : 'Add an emergency contact too',
                onTap: () => _openEditFamilyInfoDialog(context),
                trailing: KitChipButton(
                  label: 'Edit',
                  icon: Icons.edit_rounded,
                  onTap: () => _openEditFamilyInfoDialog(context),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Log an activity with family'),
          onPressed: openLogger,
        ),
      ],
    );
  }

  Widget _buildSection2TotalFriends(BuildContext context, EcosystemProvider eco) {
    final friendsHours = eco.getFriendsHoursForDate(_selectedDate);
    final dateActivities =
        eco.getFamilyActivitiesForDate(_selectedDate).where((a) => a.category != 'Family').toList();
    void openLogger() {
      _onCategorySwitched('Friends & Colleagues');
      setState(() => _selectedSectionIndex = 2);
    }

    const violet = Color(0xFF8B5CF6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitSectionHeader(
          'Friends & peers',
          subtitle: '${_formatDayLabel(_selectedDate)} · time with friends and colleagues',
          trailing: KitChipButton(label: 'Log', icon: Icons.add_rounded, onTap: openLogger),
        ),
        const SizedBox(height: 12),
        _timeHeroCard(
          context: context,
          eco: eco,
          hours: friendsHours,
          title: 'with friends',
          emptyCaption: 'Relaxed bonding, no quotas',
          filledCaption: 'Good company on record',
          icon: Icons.diversity_3_rounded,
          color: violet,
          quote: 'Shared chai, a laugh or a game with colleagues lowers stress and builds trust.',
          onQuickAdd: (h) {
            eco.addFamilyActivity(
              activityName: 'Chai / Coffee Catchup',
              category: 'Friends & Colleagues',
              subCategory: 'Casual Hangout',
              hoursSpent: h,
              iconEmoji: '☕',
              notes: 'Direct friends & colleagues time increment',
              date: _selectedDate,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Added ${formatDuration(h)} with friends for ${_formatDayShort(_selectedDate)}.')),
            );
          },
        ),
        if (dateActivities.isNotEmpty) ...[
          const SizedBox(height: 14),
          _loggedTodayCard(context, eco, dateActivities),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: violet,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Log an activity with friends'),
          onPressed: openLogger,
        ),
      ],
    );
  }

  // =========================================================================
  // SECTION 2: TOTAL TIME SPENT WITH FRIENDS / COLLEAGUES
  // =========================================================================


  // =========================================================================
  // SECTION 3: HOW DID YOU SPEND YOUR TIME WITH THEM? (ACTIVITY LOGGER)
  // =========================================================================

  Widget _buildSection3HowYouSpentTime(BuildContext context, EcosystemProvider eco) {
    final isFamily = _logCategory == 'Family';
    final presets = isFamily
        ? FamilyActivityPreset.familyPresets
        : FamilyActivityPreset.friendsColleaguesPresets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '3. LOG ACTIVITY',
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: AppColors.sandLight,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'Log Your Time',
              style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.sandPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Main Logger Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Entry Date Indicator Banner
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.burgundySurface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.sandGold.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 13, color: AppColors.sandGold),
                        const SizedBox(width: 7),
                        Text(
                          'Entry Date: ${_formatDayLabel(_selectedDate)}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandLight,
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020, 1, 1),
                          lastDate: DateTime.now().add(const Duration(days: 366)),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: AppColors.sandGold,
                                  onPrimary: AppColors.burgundyBg,
                                  surface: AppColors.burgundyCard,
                                  onSurface: AppColors.sandLight,
                                ),
                                dialogBackgroundColor: AppColors.burgundyCard,
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'Change',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sandGold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Step 1: Who was this with? (Segmented Choice)
              Text(
                'STEP 1: COMPANION',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceButton(
                      title: 'Family',
                      emoji: '👨‍👩‍👧‍👦',
                      isSelected: isFamily,
                      onTap: () => _onCategorySwitched('Family'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildChoiceButton(
                      title: 'Friends & Peers',
                      emoji: '🤝',
                      isSelected: !isFamily,
                      onTap: () => _onCategorySwitched('Friends & Colleagues'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Step 2: Choose Preset Template or Custom Name
              Text(
                'STEP 2: ACTIVITY',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold),
              ),
              const SizedBox(height: 8),

              // Presets Carousel Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: presets.map((p) {
                    final isChosen = _selectedPresetName == p.name;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        avatar: Text(p.iconEmoji, style: const TextStyle(fontSize: 15)),
                        label: Text(p.name),
                        backgroundColor: isChosen ? AppColors.magentaPrimary : AppColors.burgundySurface,
                        side: BorderSide(
                          color: isChosen ? AppColors.magentaPrimary : AppColors.sandBorder,
                          width: isChosen ? 1.4 : 0.8,
                        ),
                        labelStyle: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: isChosen ? FontWeight.bold : FontWeight.normal,
                          color: isChosen ? Colors.white : AppColors.textDark,
                        ),
                        onPressed: () => _selectPreset(p),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),

              // Custom Activity Input Field
              TextField(
                controller: _customActivityController,
                style: GoogleFonts.outfit(color: AppColors.sandLight, fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Activity Name',
                  labelStyle: GoogleFonts.outfit(color: AppColors.sandPrimary, fontSize: 11.5),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_selectedEmoji, style: const TextStyle(fontSize: 18)),
                  ),
                  hintText: 'e.g. Shopping for festival / Helping with science project',
                  hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11),
                  filled: true,
                  fillColor: AppColors.burgundySurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.sandBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.sandBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.sandGold)),
                ),
              ),
              const SizedBox(height: 14),

              // Upload Picture (Optional) - Family Memories
              Row(
                children: [
                  Text(
                    'UPLOAD PICTURE (OPTIONAL)',
                    style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.sandGold),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.photo_camera_back_outlined, size: 14, color: AppColors.sandGold),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt, size: 14, color: AppColors.sandGold),
                      label: const Text('Camera', style: TextStyle(fontSize: 11, color: AppColors.sandGold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.sandBorder),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () async {
                        final res = await ImageOptimizationService.pickAndCompressImage(source: ImageSource.camera);
                        if (!mounted) return;
                        if (res != null) {
                          setState(() {
                            _activityPhotoUrl = res.dataUrl;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library, size: 14, color: AppColors.sandGold),
                      label: const Text('Gallery', style: TextStyle(fontSize: 11, color: AppColors.sandGold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.sandBorder),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () async {
                        final res = await ImageOptimizationService.pickAndCompressImage(source: ImageSource.gallery);
                        if (!mounted) return;
                        if (res != null) {
                          setState(() {
                            _activityPhotoUrl = res.dataUrl;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (_activityPhotoUrl != null) ...[
                const SizedBox(height: 8),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ImageOptimizationService.buildImageWidget(
                        _activityPhotoUrl!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: InkWell(
                        onTap: () => setState(() => _activityPhotoUrl = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),

              // Step 3: Hours Spent
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'STEP 3: DURATION',
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.burgundySurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.sandGold.withOpacity(0.5)),
                    ),
                    child: Text(
                      formatDuration(_loggedHours),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandGold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Quick Hour Presets
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [0.5, 1.0, 1.5, 2.0, 3.0, 4.0].map((h) {
                    final isSelected = _loggedHours == h;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setState(() => _loggedHours = h),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.magentaPrimary : AppColors.burgundySurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? AppColors.magentaPrimary : AppColors.sandBorder),
                          ),
                          child: Text(
                            h == 0.5 ? '30m' : (h % 1 == 0 ? '${h.toInt()}h' : '${h}h'),
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Hours Fine-tuning Stepper
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.sandGold),
                    onPressed: () {
                      if (_loggedHours > 0.25) {
                        setState(() => _loggedHours -= 0.25);
                      }
                    },
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.sandGold,
                        inactiveTrackColor: AppColors.burgundySurface,
                        thumbColor: AppColors.sandGold,
                        overlayColor: AppColors.sandGold.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: _loggedHours.clamp(0.25, 8.0),
                        min: 0.25,
                        max: 8.0,
                        divisions: 31,
                        onChanged: (val) {
                          setState(() => _loggedHours = (val * 4).round() / 4);
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.sandGold),
                    onPressed: () {
                      if (_loggedHours < 8.0) {
                        setState(() => _loggedHours += 0.25);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Step 4: Notes (Optional)
              Text(
                'STEP 4: NOTES',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 2,
                style: GoogleFonts.outfit(color: AppColors.sandLight, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'e.g. Hearty laughter, kids solved maths fractions, mom felt joyful...',
                  hintStyle: GoogleFonts.outfit(color: AppColors.textMuted, fontSize: 11),
                  filled: true,
                  fillColor: AppColors.burgundySurface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.sandBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.sandBorder)),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button or Past Date Lock
              if (_isPastDate(_selectedDate))
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_clock_rounded, color: Color(0xFFDC2626), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Entries Locked for Past Dates (${_formatDayLabel(_selectedDate)}). Previous dates are view & delete only.',
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sandGold,
                    foregroundColor: AppColors.burgundyBg,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: Text(
                    'Record & Add to Activity Diary',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  onPressed: () => _submitActivity(eco),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceButton({
    required String title,
    required String emoji,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.magentaPrimary : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.magentaPrimary : const Color(0xFFE2E8F0),
            width: isSelected ? 1.6 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.magentaPrimary.withOpacity(0.22),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // SECTION 4: TODAY'S ACTIVITY DIARY & BALANCE BREAKDOWN
  // =========================================================================

  Widget _buildSection4ActivityDiary(BuildContext context, EcosystemProvider eco) {
    final dateLogs = eco.getFamilyActivitiesForDate(_selectedDate);
    final allLogs = eco.familyActivityLogs;
    final baseLogs = _showAllHistory ? allLogs : dateLogs;
    final filteredLogs = _diaryFilter == 'All'
        ? baseLogs
        : baseLogs.where((a) => a.category == _diaryFilter).toList();

    final familyHours = eco.getFamilyHoursForDate(_selectedDate);
    final friendsHours = eco.getFriendsHoursForDate(_selectedDate);
    final totalHours = eco.getTotalSocialHoursForDate(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '4. ACTIVITY DIARY',
                    style: GoogleFonts.outfit(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sandLight,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _showAllHistory
                        ? '${allLogs.length} total entries across all dates'
                        : '${dateLogs.length} entries on ${_formatDayLabel(_selectedDate)}',
                    style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.sandPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: AppColors.sandGold, size: 26),
              tooltip: 'Add New Activity',
              onPressed: () => setState(() => _selectedSectionIndex = 2),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Date Scope Mode Switcher
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.burgundySurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.sandBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _showAllHistory = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: !_showAllHistory ? AppColors.sandGold : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${_formatDayShort(_selectedDate)} (${dateLogs.length})',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: !_showAllHistory ? AppColors.burgundyBg : AppColors.sandLight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() => _showAllHistory = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: _showAllHistory ? AppColors.sandGold : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'All History (${allLogs.length})',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _showAllHistory ? AppColors.burgundyBg : AppColors.sandLight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Visual Balance Breakdown Bar
        if (totalHours > 0)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sandBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DAILY TIME RATIO',
                      style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.sandGold),
                    ),
                    Text(
                      'Total: ${formatDuration(totalHours)}',
                      style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandLight),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Multi-Segment Proportion Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    children: [
                      if (familyHours > 0)
                        Expanded(
                          flex: (familyHours * 100).toInt(),
                          child: Container(height: 10, color: const Color(0xFFA855F7)),
                        ),
                      if (friendsHours > 0)
                        Expanded(
                          flex: (friendsHours * 100).toInt(),
                          child: Container(height: 10, color: AppColors.sandGold),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Clean Structured Legend
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA855F7).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFA855F7))),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Family: ${formatDuration(familyHours)} (${totalHours > 0 ? ((familyHours / totalHours) * 100).toInt() : 0}%)',
                                style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.sandLight),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.sandGold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.sandGold.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.sandGold)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Friends: ${formatDuration(friendsHours)} (${totalHours > 0 ? ((friendsHours / totalHours) * 100).toInt() : 0}%)',
                                style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.sandLight),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        const SizedBox(height: 14),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: ['All', 'Family', 'Friends & Colleagues'].map((cat) {
              final isSelected = _diaryFilter == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: AppColors.magentaPrimary,
                  backgroundColor: AppColors.burgundySurface,
                  side: BorderSide(color: isSelected ? AppColors.magentaPrimary : AppColors.sandBorder),
                  labelStyle: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : AppColors.textDark,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _diaryFilter = cat);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Timeline List
        if (filteredLogs.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.burgundyCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.sandBorder),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sentiment_dissatisfied_outlined, size: 30, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text(
                    'No activities logged under "$_diaryFilter" yet today.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 12, color: AppColors.sandPrimary),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.sandGold,
                      foregroundColor: AppColors.burgundyBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Activity', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    onPressed: () => setState(() => _selectedSectionIndex = 2),
                  ),
                ],
              ),
            ),
          )
        else ...() {
          if (!_showAllHistory) {
            return [
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredLogs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) => _buildDiaryCard(filteredLogs[idx], eco),
              ),
            ];
          }

          final Map<DateTime, List<FamilyActivityItem>> groupedHistory = {};
          for (final log in filteredLogs) {
            final d = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
            groupedHistory.putIfAbsent(d, () => []).add(log);
          }
          final sortedDates = groupedHistory.keys.toList()..sort((a, b) => b.compareTo(a));

          return sortedDates.map((d) {
            final dayLogs = groupedHistory[d]!;
            final isToday = d.year == DateTime.now().year && d.month == DateTime.now().month && d.day == DateTime.now().day;
            final dateHeader = isToday ? 'Today (${DateFormat('dd MMM yyyy').format(d)})' : DateFormat('EEE, dd MMM yyyy').format(d);
            final dayHours = dayLogs.fold<double>(0.0, (sum, item) => sum + item.hoursSpent);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.sandGold.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.sandGold.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.sandGold),
                          const SizedBox(width: 6),
                          Text(
                            dateHeader,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sandLight,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${dayLogs.length} ${dayLogs.length == 1 ? "entry" : "entries"} • ${formatDuration(dayHours)}',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandGold,
                        ),
                      ),
                    ],
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: dayLogs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) => _buildDiaryCard(dayLogs[idx], eco),
                ),
              ],
            );
          }).toList();
        }(),
      ],
    );
  }

  Widget _buildDiaryCard(FamilyActivityItem log, EcosystemProvider eco) {
    final isFam = log.category == 'Family';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sandBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.burgundySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFam ? const Color(0xFFA855F7).withOpacity(0.5) : AppColors.sandGold.withOpacity(0.5),
              ),
            ),
            child: Center(
              child: Text(log.iconEmoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isFam
                            ? const Color(0xFFA855F7).withOpacity(0.18)
                            : AppColors.sandGold.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.category,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isFam ? const Color(0xFFA855F7) : AppColors.sandGold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      log.timeString,
                      style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  log.activityName,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.sandLight,
                  ),
                ),
                if (log.notes != null && log.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      log.notes!,
                      style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (log.imageUrl != null && log.imageUrl!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: GestureDetector(
                      onTap: () => ImagePreviewDialog.show(
                        context,
                        imageUrl: log.imageUrl!,
                        title: log.activityName,
                        subtitle: '${log.category} • ${log.timeString}',
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            ImageOptimizationService.buildImageWidget(
                              log.imageUrl!,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fullscreen, size: 11, color: AppColors.sandGold),
                                  SizedBox(width: 3),
                                  Text('Preview', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Hours Badge & Delete
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 10.5,
                      color: Color(0xFFBE185D),
                    ),
                    const SizedBox(width: 3.5),
                    Text(
                      formatDuration(log.hoursSpent),
                      style: GoogleFonts.outfit(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFBE185D),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.ragRed),
                onPressed: () {
                  eco.deleteFamilyActivityItem(log);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.burgundyPrimary,
                      content: Text('Activity removed.'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // EDIT FAMILY INFO DIALOG
  // =========================================================================

  void _openEditFamilyInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.burgundyCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.sandGold, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Family Welfare Settings',
                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.sandLight),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _familyMembersController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(color: AppColors.sandLight, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Total Family Members',
                    labelStyle: const TextStyle(color: AppColors.sandPrimary, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.burgundySurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emergencyContactController,
                  style: GoogleFonts.outfit(color: AppColors.sandLight, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Emergency Contact Number',
                    labelStyle: const TextStyle(color: AppColors.sandPrimary, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.burgundySurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Cancel', style: GoogleFonts.outfit(color: AppColors.sandPrimary)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.magentaPrimary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: AppColors.burgundyPrimary,
                            content: Text('Family info updated successfully!'),
                          ),
                        );
                      },
                      child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaffFamilyActivitiesGateway(BuildContext context, EcosystemProvider eco) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sandBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.sandGold.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.supervised_user_circle_rounded, color: AppColors.sandGold, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EMPLOYEE FAMILY ACTIVITIES',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sandLight,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'View team family time, quality moments & social logs',
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sandGold,
              foregroundColor: AppColors.burgundyBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmployeeFamilyActivitiesScreen()),
              );
            },
            child: Text(
              'Inspect',
              style: GoogleFonts.outfit(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dedicated Screen to inspect team family activities for CEO & HR
class EmployeeFamilyActivitiesScreen extends StatefulWidget {
  const EmployeeFamilyActivitiesScreen({super.key});

  @override
  State<EmployeeFamilyActivitiesScreen> createState() => _EmployeeFamilyActivitiesScreenState();
}

class _EmployeeFamilyActivitiesScreenState extends State<EmployeeFamilyActivitiesScreen> {
  String? _inspectedStaffId;
  Map<String, dynamic>? _inspectedFamilyData;
  bool _isLoadingInspectedFamily = false;

  Future<void> _fetchInspectedStaffFamily(String empId, EcosystemProvider eco) async {
    setState(() {
      _inspectedStaffId = empId;
      _isLoadingInspectedFamily = true;
    });
    final res = await eco.loadEmployeePillarsForInspection(empId);
    if (mounted) {
      setState(() {
        _inspectedFamilyData = res['family'] as Map<String, dynamic>?;
        _isLoadingInspectedFamily = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final teamMembers = eco.employees.where((e) => !e.isCeo).toList();

    if (_inspectedStaffId == null && teamMembers.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _inspectedStaffId == null) {
          _fetchInspectedStaffFamily(teamMembers.first.id, eco);
        }
      });
    }

    final selectedStaff = teamMembers.firstWhere(
      (e) => e.id == _inspectedStaffId,
      orElse: () => teamMembers.isNotEmpty ? teamMembers.first : eco.currentEmployee,
    );

    final family = _inspectedFamilyData ?? {};
    final activities = (family['activities'] as List?)?.cast<FamilyActivityItem>() ?? <FamilyActivityItem>[];
    final double familyHoursToday = (family['totalFamilyHoursToday'] as num?)?.toDouble() ?? 0.0;
    final double friendsHoursToday = (family['totalFriendsHoursToday'] as num?)?.toDouble() ?? 0.0;
    final double totalSocialHours = (family['totalSocialHoursToday'] as num?)?.toDouble() ?? 0.0;

    final double allFamilyHours = activities
        .where((a) => a.category == 'Family')
        .fold(0.0, (sum, a) => sum + a.hoursSpent);
    final double allFriendsHours = activities
        .where((a) => a.category != 'Family')
        .fold(0.0, (sum, a) => sum + a.hoursSpent);
    final double allTotalHours = allFamilyHours + allFriendsHours;

    final double displayFamilyHours = allFamilyHours > 0 ? allFamilyHours : familyHoursToday;
    final double displayFriendsHours = allFriendsHours > 0 ? allFriendsHours : friendsHoursToday;
    final double displayTotalHours = allTotalHours > 0 ? allTotalHours : totalSocialHours;

    return Scaffold(
      backgroundColor: AppColors.burgundyBg,
      appBar: const MnAppBar(
        title: 'Staff Family Time',
        subtitle: 'Family time logged by the team',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Employee Filter Chips
              Text(
                'SELECT EMPLOYEE',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.sandGold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: teamMembers.map((emp) {
                    final isSelected = emp.id == selectedStaff.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _fetchInspectedStaffFamily(emp.id, eco),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.sandGold : AppColors.burgundyCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.sandGold : AppColors.sandBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 10,
                                backgroundColor: isSelected ? AppColors.burgundyBg : AppColors.burgundySurface,
                                child: Text(
                                  emp.initials,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? AppColors.sandGold : AppColors.sandLight,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                emp.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? AppColors.burgundyBg : AppColors.sandLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Staff Header Card (EMP # removed to prevent clipping)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.burgundyCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sandBorder),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.burgundySurface,
                          child: Text(
                            selectedStaff.initials,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sandLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedStaff.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.sandLight,
                                ),
                              ),
                              Text(
                                selectedStaff.role.isNotEmpty ? selectedStaff.role : selectedStaff.dept,
                                style: GoogleFonts.outfit(fontSize: 11.5, color: AppColors.sandPrimary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.sandGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.sandGold.withOpacity(0.4)),
                          ),
                          child: Text(
                            '${formatDuration(displayTotalHours)} Total',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sandGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _staffFamilyMetricBox(
                            title: 'FAMILY TIME',
                            value: formatDuration(displayFamilyHours),
                            subText: 'Bonding & Care',
                            icon: Icons.family_restroom,
                            accentColor: const Color(0xFFA855F7),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _staffFamilyMetricBox(
                            title: 'FRIENDS TIME',
                            value: formatDuration(displayFriendsHours),
                            subText: 'Peer Camaraderie',
                            icon: Icons.people_outline,
                            accentColor: AppColors.sandGold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _staffFamilyMetricBox(
                            title: 'ACTIVITIES',
                            value: '${activities.length}',
                            subText: 'Logged Entries',
                            icon: Icons.checklist_rounded,
                            accentColor: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Datewise Activities Section
              Text(
                'LOGGED ACTIVITIES (DATEWISE)',
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sandGold,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),

              if (_isLoadingInspectedFamily) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.sandGold, strokeWidth: 2.5),
                  ),
                ),
              ] else if (activities.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.burgundyCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.sandBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.sentiment_satisfied_alt_rounded, size: 36, color: AppColors.sandGold),
                      const SizedBox(height: 8),
                      Text(
                        'No Activities Logged Yet',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${selectedStaff.name} has not recorded family time or activities yet.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                () {
                  final Map<DateTime, List<FamilyActivityItem>> grouped = {};
                  for (final a in activities) {
                    final d = DateTime(a.timestamp.year, a.timestamp.month, a.timestamp.day);
                    grouped.putIfAbsent(d, () => []).add(a);
                  }
                  final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

                  return Column(
                    children: sortedDates.map((d) {
                      final dayLogs = grouped[d]!;
                      final isToday = d.year == DateTime.now().year && d.month == DateTime.now().month && d.day == DateTime.now().day;
                      final dateHeader = isToday ? 'Today (${DateFormat('dd MMM yyyy').format(d)})' : DateFormat('EEE, dd MMM yyyy').format(d);
                      final double dayHours = dayLogs.fold(0.0, (sum, a) => sum + a.hoursSpent);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.burgundyCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.sandBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.sandGold),
                                    const SizedBox(width: 6),
                                    Text(
                                      dateHeader,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.sandLight,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.sandGold.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${dayLogs.length} ${dayLogs.length == 1 ? "entry" : "entries"} • ${formatDuration(dayHours)}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.sandGold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...dayLogs.map((a) {
                              final isFam = a.category == 'Family';
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.burgundySurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFF1F5F9)),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x06000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: isFam
                                                ? const Color(0xFFFAF5FF)
                                                : const Color(0xFFFFF1F4),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isFam
                                                  ? const Color(0xFFE9D5FF)
                                                  : const Color(0xFFFFE4E6),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(a.iconEmoji,
                                                style: const TextStyle(fontSize: 18)),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      a.activityName,
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 12.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: const Color(0xFF0F172A),
                                                        height: 1.25,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Refined, elegant duration pill
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 8, vertical: 3.5),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFFFF1F4),
                                                      borderRadius: BorderRadius.circular(16),
                                                      border: Border.all(
                                                          color: const Color(0xFFFECDD3)),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        const Icon(
                                                          Icons.access_time_rounded,
                                                          size: 10.5,
                                                          color: Color(0xFFBE185D),
                                                        ),
                                                        const SizedBox(width: 3.5),
                                                        Text(
                                                          formatDuration(a.hoursSpent),
                                                          style: GoogleFonts.outfit(
                                                            fontSize: 11.5,
                                                            fontWeight: FontWeight.w700,
                                                            color: const Color(0xFFBE185D),
                                                            letterSpacing: 0.2,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 5,
                                                    height: 5,
                                                    decoration: BoxDecoration(
                                                      color: isFam
                                                          ? const Color(0xFFA855F7)
                                                          : const Color(0xFFBE185D),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Expanded(
                                                    child: Text(
                                                      '${a.category} • ${a.subCategory}',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 11.5,
                                                        fontWeight: FontWeight.w600,
                                                        color: isFam
                                                            ? const Color(0xFFA855F7)
                                                            : const Color(0xFFBE185D),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (a.notes != null && a.notes!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                              color: const Color(0xFFF1F5F9)),
                                        ),
                                        child: Text(
                                          a.notes!,
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            color: const Color(0xFF475569),
                                            fontStyle: FontStyle.normal,
                                            height: 1.35,
                                          ),
                                        ),
                                      ),
                                    ],
                                    if (a.imageUrl != null && a.imageUrl!.isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      GestureDetector(
                                        onTap: () => ImagePreviewDialog.show(
                                          context,
                                          imageUrl: a.imageUrl!,
                                          title: a.activityName,
                                          subtitle: '${a.category} • ${a.timeString}',
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Stack(
                                            alignment: Alignment.bottomRight,
                                            children: [
                                              ImageOptimizationService.buildImageWidget(
                                                a.imageUrl!,
                                                height: 130,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                              ),
                                              Container(
                                                margin: const EdgeInsets.all(8),
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.72),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.fullscreen_rounded,
                                                        size: 13,
                                                        color: AppColors.sandGold),
                                                    SizedBox(width: 4),
                                                    Text('Preview Photo',
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 11.5,
                                                            fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }(),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _staffFamilyMetricBox({
    required String title,
    required String value,
    required String subText,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.burgundySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.sandBorder.withOpacity(0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.sandPrimary,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: AppColors.sandLight,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              subText,
              style: GoogleFonts.outfit(fontSize: 10, color: accentColor),
            ),
          ),
        ],
      ),
    );
  }
}
