import 'dart:math' as math;

import 'package:flutter/material.dart';

/// True when [dob] (YYYY-MM-DD or DD-MM-YYYY) falls on today's day and month.
bool isBirthdayToday(String dob, {DateTime? now, DateTime? Function(String)? parse}) {
  final n = now ?? DateTime.now();
  final d = (parse ?? _parseDob)(dob);
  if (d == null) return false;
  // 29 Feb birthdays are celebrated on 28 Feb in non-leap years.
  if (d.month == 2 && d.day == 29 && !_isLeap(n.year)) return n.month == 2 && n.day == 28;
  return d.month == n.month && d.day == n.day;
}

bool _isLeap(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;

DateTime? _parseDob(String raw) {
  final t = raw.trim().replaceAll('/', '-');
  final a = RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(t);
  final b = RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$').firstMatch(t);
  if (a != null) return DateTime(int.parse(a.group(1)!), int.parse(a.group(2)!), int.parse(a.group(3)!));
  if (b != null) return DateTime(int.parse(b.group(3)!), int.parse(b.group(2)!), int.parse(b.group(1)!));
  return null;
}

/// Wraps a round profile photo and, when [show] is true, sets a gold crown
/// on top of it with a gentle bob and a sparkle.
class BirthdayCrown extends StatefulWidget {
  final Widget child;
  final bool show;

  /// Diameter of the photo the crown sits on.
  final double size;
  const BirthdayCrown({super.key, required this.child, required this.show, required this.size});

  @override
  State<BirthdayCrown> createState() => _BirthdayCrownState();
}

class _BirthdayCrownState extends State<BirthdayCrown> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    if (widget.show) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant BirthdayCrown old) {
    super.didUpdateWidget(old);
    if (widget.show && !_c.isAnimating) _c.repeat(reverse: true);
    if (!widget.show && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return widget.child;
    final crownW = widget.size * 0.62;
    final crownH = crownW * 0.72;
    return Semantics(
      label: 'Birthday crown',
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          widget.child,
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = Curves.easeInOut.transform(_c.value);
              return Positioned(
                key: const Key('birthday_crown'),
                top: -crownH * 0.62 - 3 * t,
                left: 0,
                right: 0,
                child: Center(
                  child: Transform.rotate(
                    angle: -0.18 + 0.04 * t,
                    child: SizedBox(
                      width: crownW,
                      height: crownH,
                      child: CustomPaint(painter: _CrownPainter(sparkle: t)),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CrownPainter extends CustomPainter {
  final double sparkle;
  _CrownPainter({required this.sparkle});

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final baseTop = h * 0.66;

    // Crown body: three points with a curved band.
    final body = Path()
      ..moveTo(w * 0.06, baseTop)
      ..lineTo(w * 0.02, h * 0.22)
      ..lineTo(w * 0.30, h * 0.46)
      ..lineTo(w * 0.50, h * 0.06)
      ..lineTo(w * 0.70, h * 0.46)
      ..lineTo(w * 0.98, h * 0.22)
      ..lineTo(w * 0.94, baseTop)
      ..close();
    final band = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.04, baseTop - h * 0.02, w * 0.92, h * 0.26),
      Radius.circular(h * 0.08),
    );

    // Soft shadow for depth on the magenta header
    canvas.drawPath(
      body.shift(const Offset(0, 2)),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    const gold = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFF1B8), Color(0xFFFFD54F), Color(0xFFF59E0B), Color(0xFFB45309)],
      stops: [0.0, 0.35, 0.7, 1.0],
    );
    final goldPaint = Paint()..shader = gold.createShader(Offset.zero & s);
    canvas.drawPath(body, goldPaint);
    canvas.drawRRect(band, goldPaint);

    // Fine outline
    final edge = Paint()
      ..color = const Color(0xFF92400E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, w * 0.025)
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(body, edge);
    canvas.drawRRect(band, edge);

    // Balls on the three tips
    final tipPaint = Paint()..color = const Color(0xFFFFF7D6);
    for (final p in [Offset(w * 0.02, h * 0.22), Offset(w * 0.50, h * 0.06), Offset(w * 0.98, h * 0.22)]) {
      canvas.drawCircle(p, w * 0.055, tipPaint);
      canvas.drawCircle(p, w * 0.055, edge);
    }

    // Jewels on the band: magenta (brand), white, magenta
    final jewelY = baseTop + h * 0.11;
    void jewel(double x, Color c) {
      canvas.drawCircle(Offset(x, jewelY), w * 0.055, Paint()..color = c);
      canvas.drawCircle(Offset(x - w * 0.018, jewelY - w * 0.018), w * 0.016, Paint()..color = Colors.white70);
    }

    jewel(w * 0.26, const Color(0xFFE11D48));
    jewel(w * 0.50, const Color(0xFFFFFFFF));
    jewel(w * 0.74, const Color(0xFFE11D48));

    // Twinkle near the top point
    final sp = Paint()..color = Colors.white.withOpacity(0.55 + 0.45 * sparkle);
    final c = Offset(w * 0.82, h * 0.04);
    final r = w * (0.05 + 0.03 * sparkle);
    final star = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.25, c.dy - r * 0.25)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx + r * 0.25, c.dy + r * 0.25)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r * 0.25, c.dy + r * 0.25)
      ..lineTo(c.dx - r, c.dy)
      ..lineTo(c.dx - r * 0.25, c.dy - r * 0.25)
      ..close();
    canvas.drawPath(star, sp);
  }

  @override
  bool shouldRepaint(_CrownPainter old) => old.sparkle != sparkle;
}
