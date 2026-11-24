import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The official MN Jewel Park logo (assets/images/mnjlogo.jpg) in a clean
/// rounded frame: a white ring, a soft outer halo and a gentle shadow.
///
/// Use [onDark] = true on magenta headers (white halo) and false on white
/// surfaces (blush halo).
class MnBrandLogo extends StatelessWidget {
  final double size;
  final bool onDark;
  final bool circle;

  const MnBrandLogo({
    super.key,
    this.size = 44,
    this.onDark = true,
    this.circle = false,
  });

  static const asset = 'assets/images/mnjlogo.jpg';

  @override
  Widget build(BuildContext context) {
    final ring = (size * 0.06).clamp(1.5, 4.0);
    final halo = (size * 0.07).clamp(2.0, 6.0);
    final outerRadius = circle ? size : size * 0.30;
    final innerRadius = circle ? size : (outerRadius - halo - ring).clamp(4.0, size);

    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(halo),
      decoration: BoxDecoration(
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(outerRadius),
        color: onDark ? const Color(0x26FFFFFF) : AppColors.primarySoft,
        border: Border.all(
          color: onDark ? const Color(0x40FFFFFF) : const Color(0xFFF5D0E0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: onDark ? const Color(0x33000000) : const Color(0x22881337),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(ring),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(innerRadius + ring),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(innerRadius),
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.medium,
            cacheWidth: (size * 3).round(),
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.indigoDeep,
              alignment: Alignment.center,
              child: Icon(Icons.diamond_outlined, color: Colors.white, size: size * 0.45),
            ),
          ),
        ),
      ),
    );
  }
}
