import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double blur;
  final LinearGradient? borderGradient;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.borderRadius = 20,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.blur = 16,
    this.borderGradient,
  });

  @override
  Widget build(BuildContext context) {
    final isTapable = onTap != null;

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.pureWhite,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.sandBorder,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A), // subtle neutral ambient shadow
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
          BoxShadow(
            color: Color(0x030F172A),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );

    if (margin != EdgeInsets.zero) {
      content = Padding(padding: margin, child: content);
    }

    if (isTapable) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          splashColor: AppColors.magentaPrimary.withOpacity(0.12),
          highlightColor: AppColors.magentaSubtle.withOpacity(0.5),
          child: content,
        ),
      );
    }

    return content;
  }
}

class LiquidGlassPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;

  const LiquidGlassPill({
    super.key,
    required this.label,
    this.icon,
    this.color = AppColors.magentaPrimary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: color.withOpacity(0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 4),
            ] else ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LiquidGlassButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isPrimary;
  final Color? color;
  final double height;

  const LiquidGlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = true,
    this.color,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
    final bgGradient = isPrimary
        ? (color != null
            ? LinearGradient(colors: [color!, color!.withOpacity(0.85)])
            : AppColors.magentaGradient)
        : null;

    final textColor = isPrimary ? Colors.white : AppColors.magentaPrimary;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: bgGradient,
        color: isPrimary ? null : AppColors.pureWhite,
        border: Border.all(
          color: isPrimary ? Colors.transparent : AppColors.magentaPrimary.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? AppColors.magentaPrimary.withOpacity(0.28)
                : Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 15,
                    color: textColor,
                  ),
                  const SizedBox(width: 5),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                      letterSpacing: 0.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LiquidMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const LiquidMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.subtitle,
    this.color = AppColors.magentaPrimary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LiquidGlassCard(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        margin: EdgeInsets.zero,
        borderRadius: 16,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 13, color: color),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 1),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 9.5,
                  color: AppColors.textMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
