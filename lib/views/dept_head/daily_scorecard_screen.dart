import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/daily_scorecard_model.dart';
import '../../core/services/daily_scorecard_pdf_service.dart';
import '../../core/services/daily_scorecard_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/mn_app_bar.dart';
import '../../core/widgets/pillar_kit.dart';
import '../../providers/ecosystem_provider.dart';
import 'monthly_scorecard_screen.dart';

const _red = Color(0xFFE8232F);
const _green = Color(0xFF16794A);
const _blue = Color(0xFF27358C);

/// Scorecard entry: pick Daily or Monthly.
class ScorecardHubScreen extends StatelessWidget {
  const ScorecardHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eco = context.read<EcosystemProvider>();
    void open(Widget w) => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChangeNotifierProvider.value(value: eco, child: w)),
        );
    Widget option(Key key, IconData icon, Color color, String title, String sub, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: KitCard(
            key: key,
            onTap: onTap,
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                KitIcon(icon, color, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: kitTitle(17)),
                      const SizedBox(height: 2),
                      Text(sub, style: kitBody(13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        );
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: const MnAppBar(title: 'Scorecard', subtitle: 'Online team'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          option(const Key('open_daily_scorecard'), Icons.today_rounded, _red, 'Daily Scorecard',
              'Fill in today, save as often as needed, publish to share', () => open(const DailyScorecardScreen())),
          option(const Key('open_monthly_scorecard'), Icons.calendar_month_rounded, _green, 'Monthly Scorecard',
              'Totals of every published day (view and share)', () => open(const MonthlyScorecardScreen())),
        ],
      ),
    );
  }
}

class DailyScorecardScreen extends StatefulWidget {
  final DateTime? date;
  const DailyScorecardScreen({super.key, this.date});

  @override
  State<DailyScorecardScreen> createState() => _DailyScorecardScreenState();
}

class _DailyScorecardScreenState extends State<DailyScorecardScreen> {
  late DateTime _date;
  DailyScorecardModel? _m;
  bool _dirty = false;
  bool _busy = false;

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  String _label(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  @override
  void initState() {
    super.initState();
    final n = widget.date ?? DateTime.now();
    _date = DateTime(n.year, n.month, n.day);
    _load();
  }

  Future<void> _load() async {
    setState(() => _m = null);
    final m = await DailyScorecardService.load(_date);
    if (!mounted) return;
    setState(() {
      _m = m;
      _dirty = false;
    });
  }

  Future<void> _go(int days) async {
    if (_dirty && !await _confirmLeave()) return;
    final next = _date.add(Duration(days: days));
    final today = DateTime.now();
    if (next.isAfter(DateTime(today.year, today.month, today.day))) return;
    _date = next;
    await _load();
  }

  Future<bool> _confirmLeave() async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Unsaved changes'),
          content: const Text('Leave without saving this day?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Stay')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Leave')),
          ],
        ),
      ) ==
      true;

  bool get _canEdit => context.read<EcosystemProvider>().canEditDailyScorecard && !(_m?.isPublished ?? true);

  Future<void> _save({bool publish = false}) async {
    final m = _m;
    if (m == null) return;
    final eco = context.read<EcosystemProvider>();
    if (publish) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.campaign_rounded, color: AppColors.primary),
          title: Text('Publish ${_label(m.date)}?'),
          content: Text(
            'Total score ${m.totalScore}/100. It will be shared with the online team and the CEO and added to '
            'the monthly scorecard. After publishing it can no longer be edited.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Not yet')),
            FilledButton(key: const Key('confirm_publish'), onPressed: () => Navigator.pop(c, true), child: const Text('Publish')),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _busy = true);
    m.updatedBy = eco.currentEmployee.name;
    m.updatedAt = DateTime.now();
    if (publish) {
      m.status = 'published';
      m.publishedBy = eco.currentEmployee.name;
      m.publishedAt = DateTime.now();
    }
    final online = await DailyScorecardService.save(m);
    if (publish) eco.notifyDailyScorecardPublished(_label(m.date), m.totalScore);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _dirty = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(publish
          ? 'Published and shared with the team and the CEO.'
          : (online ? 'Draft saved.' : 'Draft saved on this phone (offline).')),
    ));
  }

  Future<void> _share({required bool image}) async {
    final m = _m;
    if (m == null) return;
    setState(() => _busy = true);
    try {
      final pdf = await DailyScorecardPdfService.generatePdf(m);
      final name = 'Daily_Scorecard_${m.id}';
      if (image) {
        final png = await DailyScorecardPdfService.toPng(pdf);
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$name.png');
        await file.writeAsBytes(png);
        await Share.shareXFiles([XFile(file.path)], text: 'Daily Scorecard ${_label(m.date)}');
      } else {
        await Printing.sharePdf(bytes: pdf, filename: '$name.pdf');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not share: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editItem(ScoreChannel c, ScoreItem i) async {
    if (!_canEdit) return;
    var done = i.done;
    var target = i.target;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) {
          Widget stepper(String label, int v, ValueChanged<int> on, Key key) => Row(
                children: [
                  Expanded(child: Text(label, style: kitTitle(15))),
                  IconButton.filledTonal(onPressed: v > 0 ? () => set(() => on(v - 1)) : null, icon: const Icon(Icons.remove_rounded)),
                  SizedBox(
                    width: 56,
                    child: Text('$v', key: key, textAlign: TextAlign.center, style: kitValue(24)),
                  ),
                  IconButton.filledTonal(onPressed: () => set(() => on(v + 1)), icon: const Icon(Icons.add_rounded)),
                ],
              );
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${c.name} · ${i.label}', style: kitTitle(18)),
                const SizedBox(height: 16),
                stepper('Done today', done, (v) => done = v, const Key('item_done')),
                const SizedBox(height: 8),
                stepper('Target', target, (v) => target = v, const Key('item_target')),
                const SizedBox(height: 18),
                FilledButton(
                  key: const Key('item_ok'),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        },
      ),
    );
    if (ok == true) {
      setState(() {
        i.done = done;
        i.target = target;
        _dirty = true;
      });
    }
  }

  Future<void> _editChannelScore(ScoreChannel c) async {
    if (!_canEdit) return;
    var v = c.score;
    final res = await showDialog<int?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: Text('${c.name} score'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Worked out from the circles: ${c.autoScore}% of ${c.weight}%', style: kitBody(13)),
              Slider(
                value: v.toDouble(),
                min: 0,
                max: c.weight.toDouble(),
                divisions: c.weight,
                label: '$v%',
                onChanged: (x) => set(() => v = x.round()),
              ),
              Text('$v% out of ${c.weight}%', style: kitTitle(16)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, -1), child: const Text('Use auto')),
            FilledButton(onPressed: () => Navigator.pop(ctx, v), child: const Text('Set')),
          ],
        ),
      ),
    );
    if (res == null) return;
    setState(() {
      c.scoreOverride = res < 0 ? null : res;
      _dirty = true;
    });
  }

  Future<void> _editFeedback() async {
    final m = _m!;
    if (!_canEdit) return;
    final rating = TextEditingController(text: '${m.feedbackRating}');
    final responses = TextEditingController(text: '${m.feedbackResponses}');
    final remark = TextEditingController(text: m.remark ?? '');
    var onTime = m.onTime, quality = m.qualityDesign, perfection = m.designPerfection;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Design feedback & remark', style: kitTitle(18)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: rating,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Feedback rating %'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: responses,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Responses'),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Wrap(spacing: 8, children: [
                FilterChip(label: const Text('On Time'), selected: onTime, onSelected: (x) => set(() => onTime = x)),
                FilterChip(label: const Text('Quality Design'), selected: quality, onSelected: (x) => set(() => quality = x)),
                FilterChip(label: const Text('Design Perfection'), selected: perfection, onSelected: (x) => set(() => perfection = x)),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: remark,
                decoration: InputDecoration(labelText: 'Remark (optional)', hintText: m.effectiveRemark),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Done')),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    setState(() {
      m.feedbackRating = (int.tryParse(rating.text.trim()) ?? m.feedbackRating).clamp(0, 100);
      m.feedbackResponses = (int.tryParse(responses.text.trim()) ?? m.feedbackResponses).clamp(0, 999);
      m.onTime = onTime;
      m.qualityDesign = quality;
      m.designPerfection = perfection;
      m.remark = remark.text.trim().isEmpty ? null : remark.text.trim();
      _dirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final m = _m;
    final canEditRole = eco.canEditDailyScorecard;
    final today = DateTime.now();
    final isToday = _date.year == today.year && _date.month == today.month && _date.day == today.day;
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: MnAppBar(
          title: 'Daily Scorecard',
          subtitle: m == null ? _label(_date) : '${_label(_date)} · ${m.isPublished ? 'Published' : 'Draft'}',
        ),
        body: m == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                children: [
                  Row(
                    children: [
                      IconButton(onPressed: () => _go(-1), icon: const Icon(Icons.chevron_left_rounded)),
                      Expanded(
                        child: Center(
                          child: KitPill(
                            m.isPublished ? 'Published${m.publishedBy != null ? ' by ${m.publishedBy}' : ''}' : 'Draft',
                            m.isPublished ? _green : const Color(0xFFD97706),
                            icon: m.isPublished ? Icons.verified_rounded : Icons.edit_note_rounded,
                          ),
                        ),
                      ),
                      IconButton(onPressed: isToday ? null : () => _go(1), icon: const Icon(Icons.chevron_right_rounded)),
                    ],
                  ),
                  if (_canEdit)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('Tap a circle to change its numbers, a score pill to set the channel score.',
                          textAlign: TextAlign.center, style: kitBody(12)),
                    ),
                  if (!canEditRole && !m.isPublished)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: KitEmptyState(
                        icon: Icons.hourglass_top_rounded,
                        title: 'Not published yet',
                        message: 'The online team lead has not published this day yet.',
                      ),
                    ),
                  if (canEditRole || m.isPublished) ...[
                    _Gauge(score: m.totalScore, grade: m.grade, remark: m.effectiveRemark, date: m.date),
                    const SizedBox(height: 6),
                    for (final c in m.channels)
                      _ChannelBlock(
                        channel: c,
                        onItem: (i) => _editItem(c, i),
                        onScore: () => _editChannelScore(c),
                      ),
                    _FeedbackBanner(model: m, onTap: _editFeedback),
                  ],
                ],
              ),
        bottomNavigationBar: m == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                  child: _busy
                      ? const LinearProgressIndicator()
                      : Row(
                          children: [
                            if (_canEdit) ...[
                              Expanded(
                                child: OutlinedButton(
                                  key: const Key('save_draft'),
                                  onPressed: () => _save(),
                                  child: const Text('Save draft'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton(
                                  key: const Key('publish_scorecard'),
                                  onPressed: () => _save(publish: true),
                                  child: const Text('Publish'),
                                ),
                              ),
                            ] else if (canEditRole || m.isPublished) ...[
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _share(image: false),
                                  icon: const Icon(Icons.picture_as_pdf_rounded),
                                  label: const Text('PDF'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _share(image: true),
                                  icon: const Icon(Icons.image_rounded),
                                  label: const Text('Image'),
                                ),
                              ),
                            ],
                            if (_canEdit) ...[
                              const SizedBox(width: 4),
                              PopupMenuButton<String>(
                                tooltip: 'Share',
                                icon: const Icon(Icons.ios_share_rounded),
                                onSelected: (v) => _share(image: v == 'image'),
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'pdf', child: Text('Share as PDF')),
                                  PopupMenuItem(value: 'image', child: Text('Share as image')),
                                ],
                              ),
                            ],
                          ],
                        ),
                ),
              ),
      ),
    );
  }
}

class _Gauge extends StatelessWidget {
  final int score;
  final String grade;
  final String remark;
  final DateTime date;
  const _Gauge({required this.score, required this.grade, required this.remark, required this.date});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Daily Scorecard', style: GoogleFonts.outfit(fontSize: 30, fontWeight: FontWeight.w900, color: _red)),
        SizedBox(
          height: 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: CustomPaint(painter: _GaugePainter(score))),
              Positioned(
                top: 40,
                child: Column(
                  children: [
                    const Text('★ ★ ★', style: TextStyle(color: _red, fontSize: 12)),
                    Text('$score', key: const Key('daily_total'),
                        style: GoogleFonts.outfit(fontSize: 64, fontWeight: FontWeight.w900, color: _red, height: 1)),
                    Text('/100 $grade', style: kitBody(12).copyWith(color: AppColors.textDark)),
                    Text(remark, style: kitBody(12).copyWith(color: AppColors.textDark)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final int score;
  _GaugePainter(this.score);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height - 10);
    final r = math.min(size.width / 2 - 24, size.height - 24);
    final rect = Rect.fromCircle(center: c, radius: r);
    Paint p(Color col) => Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi * 0.58, false, p(_red));
    canvas.drawArc(rect, math.pi + math.pi * 0.62, math.pi * 0.16, false, p(const Color(0xFFF29A2E)));
    canvas.drawArc(rect, math.pi + math.pi * 0.82, math.pi * 0.18, false, p(const Color(0xFF22A04B)));
    final a = math.pi + math.pi * score.clamp(0, 100) / 100;
    final m = c + Offset(r * math.cos(a), r * math.sin(a));
    canvas.drawCircle(m, 9, Paint()..color = Colors.white);
    canvas.drawCircle(m, 9, Paint()
      ..color = const Color(0xFF3B82C4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.score != score;
}

class _ChannelBlock extends StatelessWidget {
  final ScoreChannel channel;
  final ValueChanged<ScoreItem> onItem;
  final VoidCallback onScore;
  const _ChannelBlock({required this.channel, required this.onItem, required this.onScore});

  static const _icons = {
    'instagram': 'assets/scorecard/instagram.png',
    'listing': 'assets/scorecard/listing.png',
    'whatsapp': 'assets/scorecard/whatsapp.png',
    'mobileApp': 'assets/scorecard/mobile_app.png',
    'google': 'assets/scorecard/google.png',
    'otherSocial': 'assets/scorecard/other_social.png',
  };

  @override
  Widget build(BuildContext context) {
    final c = channel;
    final full = c.score >= c.weight;
    Widget pill(String t, Color col) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(4)),
          child: Text(t, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
            decoration: BoxDecoration(color: const Color(0xFFF2F3F2), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Image.asset(_icons[c.key] ?? '', errorBuilder: (_, __, ___) => const SizedBox()),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 5,
                        children: [
                          Text(c.name, style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                          InkWell(
                            key: Key('score_${c.key}'),
                            onTap: onScore,
                            child: pill('${c.score.toString().padLeft(2, '0')}%', full ? _green : _red),
                          ),
                          Text('Out of', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700)),
                          pill('${c.weight}%', _green),
                        ],
                      ),
                      Text('Target/day: ${c.targetText}', style: kitBody(11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final i in c.items)
                InkWell(
                  key: Key('item_${c.key}_${i.key}'),
                  customBorder: const CircleBorder(),
                  onTap: () => onItem(i),
                  child: _Circle(item: i),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  final ScoreItem item;
  const _Circle({required this.item});

  @override
  Widget build(BuildContext context) {
    final i = item;
    final col = i.done > i.target ? _blue : (i.met ? _green : _red);
    String two(int v) => v < 10 ? '0$v' : '$v';
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: col, width: 4.5)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(two(i.done), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: col, height: 1)),
          Container(width: 30, height: 1.2, color: col, margin: const EdgeInsets.symmetric(vertical: 1)),
          Text(two(i.target), style: GoogleFonts.outfit(fontSize: 8.5, fontWeight: FontWeight.w800, color: col, height: 1)),
          Text(i.label, maxLines: 1, overflow: TextOverflow.clip, style: GoogleFonts.outfit(fontSize: 5.5, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  final DailyScorecardModel model;
  final VoidCallback onTap;
  const _FeedbackBanner({required this.model, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = model;
    Widget chip(String t, bool on) => Container(
          margin: const EdgeInsets.only(right: 4, top: 4),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: on ? const Color(0xFFDDEFE2) : const Color(0xFF4D7F63),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(t, style: GoogleFonts.outfit(fontSize: 9, color: on ? _green : Colors.white)),
        );
    return InkWell(
      key: const Key('edit_feedback'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Text('${m.feedbackRating}%', style: GoogleFonts.outfit(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Feed Back Rating', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                  Wrap(children: [
                    chip('On Time', m.onTime),
                    chip('Quality Design', m.qualityDesign),
                    chip('Design Perfection', m.designPerfection),
                  ]),
                ],
              ),
            ),
            Container(
              width: 58,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFFFF7DD), borderRadius: BorderRadius.circular(8)),
              child: Column(children: [
                Text(m.feedbackResponses.toString().padLeft(2, '0'),
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: _green, height: 1)),
                Text('Response', style: GoogleFonts.outfit(fontSize: 8, color: _green)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
