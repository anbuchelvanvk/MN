import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// One number in the pillar summary banner.
class PillarHeroStat {
  final String value;
  final String label;
  const PillarHeroStat(this.value, this.label);
}

/// Summary banner shown at the top of every pillar page (Health, Family Time,
/// Work, Social Cause): a progress ring for the month, a headline, and three
/// quick numbers. Same look as the home page hero.
class PillarHeroCard extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String headline;
  final String caption;
  final double progress; // 0..1, shown in the ring
  final String ringLabel;
  final List<PillarHeroStat> stats;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PillarHeroCard({
    super.key,
    required this.icon,
    required this.eyebrow,
    required this.headline,
    required this.caption,
    required this.progress,
    required this.ringLabel,
    required this.stats,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final pct = progress.clamp(0.0, 1.0);
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [BoxShadow(color: Color(0x33881337), blurRadius: 22, offset: Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 170,
                height: 170,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 78,
                        height: 78,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox.expand(
                              child: CircularProgressIndicator(
                                value: pct,
                                strokeWidth: 7,
                                strokeCap: StrokeCap.round,
                                backgroundColor: const Color(0x33FFFFFF),
                                valueColor: const AlwaysStoppedAnimation(Colors.white),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icon, size: 18, color: AppColors.heroAccent),
                                Text(
                                  ringLabel,
                                  style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eyebrow.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                                color: AppColors.heroAccent,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              headline,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(fontSize: 13, color: const Color(0xFFFFE4EF), height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0x1FFFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x26FFFFFF)),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          for (int i = 0; i < stats.length; i++) ...[
                            if (i > 0) const VerticalDivider(color: Color(0x33FFFFFF), width: 1, thickness: 1),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      stats[i].value,
                                      style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                                    ),
                                  ),
                                  Text(
                                    stats[i].label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.outfit(fontSize: 11.5, color: const Color(0xFFFFE4EF)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                      ),
                      onPressed: onAction,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
