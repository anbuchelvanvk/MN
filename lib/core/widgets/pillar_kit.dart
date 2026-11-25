import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// Shared building blocks for the pillar pages (Health, Family, Work) so
/// every card, tile and chip looks like one family: white cards, soft
/// shadow, magenta accents, sentence-case headings, no truncated labels.

const _ink = AppColors.midnight;
const _muted = Color(0xFF7A6A74);

TextStyle kitTitle([double size = 16]) => GoogleFonts.outfit(
  fontSize: size,
  fontWeight: FontWeight.w800,
  color: _ink,
  height: 1.2,
);
TextStyle kitBody([double size = 13]) => GoogleFonts.outfit(
  fontSize: size,
  fontWeight: FontWeight.w500,
  color: _muted,
  height: 1.35,
);
TextStyle kitValue([double size = 26]) => GoogleFonts.outfit(
  fontSize: size,
  fontWeight: FontWeight.w800,
  color: _ink,
  height: 1.05,
  letterSpacing: -0.5,
);

/// 1,324 style thousands separators.
String kitNumber(num n) {
  final s = n.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// Section heading: magenta bar, title, optional subtitle and action.
class KitSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const KitSectionHeader(this.title, {super.key, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: subtitle == null ? 18 : 34,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: kitTitle(17)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(subtitle!, style: kitBody(12.5)),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// White card with hairline border and soft shadow.
class KitCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  const KitCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final box = Ink(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor ?? AppColors.line),
        boxShadow: AppColors.softShadow,
      ),
      child: child,
    );
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: onTap == null
          ? box
          : InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: onTap,
              child: box,
            ),
    );
  }
}

/// Rounded square icon on a soft tint.
class KitIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool onDark;
  const KitIcon(
    this.icon,
    this.color, {
    super.key,
    this.size = 40,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withOpacity(0.18)
            : color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, size: size * 0.5, color: onDark ? Colors.white : color),
    );
  }
}

/// Small rounded label, e.g. "From phone", "Overweight".
class KitPill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final bool solid;
  const KitPill(
    this.text,
    this.color, {
    super.key,
    this.icon,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: solid ? color : color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: solid ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: solid ? Colors.white : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small action button used in card headers ("Log", "Edit").
class KitChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Key? buttonKey;
  const KitChipButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      key: buttonKey,
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tappable summary tile. Selected tiles use the magenta gradient.
class KitStatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? unit;
  final String caption;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? badge;
  const KitStatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.unit,
    required this.caption,
    this.selected = false,
    this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : _ink;
    final sub = selected ? Colors.white.withOpacity(0.85) : _muted;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
          decoration: BoxDecoration(
            color: selected ? null : Colors.white,
            gradient: selected ? AppColors.heroGradient : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.line,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.28),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x0D881337),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  KitIcon(icon, color, size: 34, onDark: selected),
                  const Spacer(),
                  if (badge != null)
                    badge!
                  else if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: sub,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: kitValue(22).copyWith(color: fg),
                      ),
                      if (unit != null)
                        TextSpan(
                          text: ' $unit',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: sub,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: sub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-column grid of tiles with equal heights.
class KitTileGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  const KitTileGrid({super.key, required this.children, this.spacing = 12});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: children[i]),
              SizedBox(width: spacing),
              Expanded(
                child: i + 1 < children.length
                    ? children[i + 1]
                    : const SizedBox(),
              ),
            ],
          ),
        ),
      );
      if (i + 2 < children.length) rows.add(SizedBox(height: spacing));
    }
    return Column(children: rows);
  }
}

/// Circular progress with a label in the middle.
class KitRing extends StatelessWidget {
  final double progress; // 0..1 (can exceed 1)
  final Color color;
  final double size;
  final Widget center;
  final double stroke;
  const KitRing({
    super.key,
    required this.progress,
    required this.color,
    required this.center,
    this.size = 92,
    this.stroke = 9,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => CustomPaint(
          painter: _RingPainter(v, color, stroke),
          child: Center(child: center),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double v;
  final Color color;
  final double stroke;
  _RingPainter(this.v, this.color, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = rect.deflate(stroke / 2);
    final track = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(r, 0, math.pi * 2, false, track);
    if (v <= 0) return;
    final arc = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + math.pi * 2,
        colors: [color.withOpacity(0.65), color],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke;
    canvas.drawArc(r, -math.pi / 2, math.pi * 2 * v, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.v != v || old.color != color;
}

/// Rounded progress bar.
class KitBar extends StatelessWidget {
  final double progress;
  final Color color;
  final double height;
  const KitBar({
    super.key,
    required this.progress,
    required this.color,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(height: height, color: color.withOpacity(0.12)),
          FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.7), color],
                ),
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small number with a label under it; never truncates the label.
class KitMiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData? icon;
  const KitMiniStat({
    super.key,
    required this.value,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 6),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: kitValue(19).copyWith(color: color)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: _muted,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// A row of equal [KitMiniStat]s.
class KitMiniStatRow extends StatelessWidget {
  final List<KitMiniStat> stats;
  const KitMiniStatRow(this.stats, {super.key});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < stats.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: stats[i]),
          ],
        ],
      ),
    );
  }
}

/// Horizontally scrolling choice chips.
class KitChoiceChips extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;
  final List<int?>? counts;
  const KitChoiceChips({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
    this.counts,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final on = i == selected;
          final count = counts != null && i < counts!.length
              ? counts![i]
              : null;
          return Material(
            color: on ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(30),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => onSelected(i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: on ? AppColors.primary : AppColors.line,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      labels[i],
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: on ? Colors.white : _ink,
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: on
                              ? Colors.white.withOpacity(0.25)
                              : AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: on ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Segmented control (2-3 options) on a soft track.
class KitSegmented extends StatelessWidget {
  final List<(IconData, String)> options;
  final int selected;
  final ValueChanged<int> onSelected;
  const KitSegmented({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var i = 0; i < options.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    color: i == selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: i == selected ? AppColors.softShadow : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        options[i].$1,
                        size: 16,
                        color: i == selected ? AppColors.primary : _muted,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            options[i].$2,
                            maxLines: 1,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: i == selected ? AppColors.primary : _muted,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Friendly empty state.
class KitEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const KitEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 26, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: kitTitle(15)),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: kitBody(12.5)),
        ],
      ),
    );
  }
}

/// List row with an icon, title, subtitle and trailing widget.
class KitListRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const KitListRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            children: [
              KitIcon(icon, color, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: _muted,
                          height: 1.3,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
