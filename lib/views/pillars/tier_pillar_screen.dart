import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/liquid_glass.dart';
import '../../models/profile_document_models.dart';
import '../../providers/ecosystem_provider.dart';
import 'health_pillar_screen.dart';
import 'family_pillar_screen.dart';
import 'profile_pillar_screen.dart';
import 'attendance_pillar_screen.dart';

class TierPillarScreen extends StatefulWidget {
  const TierPillarScreen({super.key});

  @override
  State<TierPillarScreen> createState() => _TierPillarScreenState();
}

class _TierPillarScreenState extends State<TierPillarScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EcosystemProvider>();
    final tier = provider.holisticTierLevel;
    final tierName = provider.holisticTierName;
    final tierColor = provider.holisticTierColor;

    // Calculate real dynamic holistic equilibrium score
    final int equilibriumScore = provider.holisticEquilibriumScore;

    return Scaffold(
      backgroundColor: AppColors.burgundyBg,
      appBar: AppBar(
        backgroundColor: AppColors.burgundyBg,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.sandPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'YOUR STATUS',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.sandLight,
            letterSpacing: 0.8,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: LiquidGlassPill(
                label: 'STATUS',
                color: tierColor,
                icon: Icons.light_mode,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Philosophy Monogram
            _buildPhilosophyCard(),
            const SizedBox(height: 16),

            // 4-Pillars Equilibrium Scorecard Breakdown
            _buildFourPillarsScorecard(context, provider),
            const SizedBox(height: 18),

            // HERO GLOWING CIRCLE GAUGE (Tap to open audit)
            _buildHeroTierCircle(context, provider, tier, tierName, tierColor, equilibriumScore),
            const SizedBox(height: 22),

            // Tap hint prompt
            Center(
              child: InkWell(
                onTap: () => _showLagAuditBottomSheet(context, provider),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: tierColor.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: tierColor.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app, size: 16, color: tierColor),
                      const SizedBox(width: 8),
                      Text(
                        'View Suggestions',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: tierColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 11, color: tierColor),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),

            // 4 Pillar Diagnostics Cards
            _buildDiagnosticsSection(context, provider),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // --- 4-PILLAR EQUILIBRIUM SCORECARD BREAKDOWN ---

  Widget _buildFourPillarsScorecard(BuildContext context, EcosystemProvider provider) {
    final s1 = provider.pillar1HealthScore;
    final s2 = provider.pillar2FamilyScore;
    final s3 = provider.pillar3ProfileScore;
    final s4 = provider.pillar4AttendanceScore;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sandBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hub_rounded, size: 16, color: AppColors.sandGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '4-PILLAR EQUILIBRIUM SCORES',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.sandGold,
                    letterSpacing: 0.6,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: provider.holisticTierColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${provider.holisticEquilibriumScore}% OVERALL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: provider.holisticTierColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMiniScorePill('P1: Health', s1, Icons.health_and_safety_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniScorePill('P2: Family', s2, Icons.family_restroom_rounded)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildMiniScorePill('P3: Profile', s3, Icons.badge_rounded)),
              const SizedBox(width: 8),
              Expanded(child: _buildMiniScorePill('P4: Attendance', s4, Icons.assignment_turned_in_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniScorePill(String title, int score, IconData icon) {
    final color = score >= 80
        ? const Color(0xFF10B981)
        : (score >= 60 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (score / 100.0).clamp(0.0, 1.0),
                    minHeight: 3.5,
                    backgroundColor: Colors.black.withOpacity(0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$score%',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // --- HERO GLOWING TIER CIRCLE ---

  Widget _buildHeroTierCircle(
    BuildContext context,
    EcosystemProvider provider,
    PillarTierLevel tier,
    String tierName,
    Color tierColor,
    int score,
  ) {
    String tierTitle = 'GREEN';
    String tierBadgeDesc = 'All Good';
    IconData tierIcon = Icons.verified;

    if (tier == PillarTierLevel.yellow) {
      tierTitle = 'YELLOW';
      tierBadgeDesc = 'Needs Attention';
      tierIcon = Icons.warning_amber_rounded;
    } else if (tier == PillarTierLevel.red) {
      tierTitle = 'RED';
      tierBadgeDesc = 'Action Needed';
      tierIcon = Icons.error_outline;
    }

    return GestureDetector(
      onTap: () => _showLagAuditBottomSheet(context, provider),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (ctx, child) {
          return Center(
            child: Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: tierColor.withOpacity(0.35),
                      blurRadius: 36,
                      spreadRadius: 6,
                    ),
                    BoxShadow(
                      color: const Color(0x0A0F172A),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Circular Progress Track
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: CircularProgressIndicator(
                        value: score / 100.0,
                        strokeWidth: 8,
                        backgroundColor: AppColors.burgundyCard,
                        valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                      ),
                    ),

                    // Inner Core Dial
                    Container(
                      width: 216,
                      height: 216,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.2),
                          radius: 0.85,
                          colors: [
                            tierColor.withOpacity(0.32),
                            AppColors.burgundyCard,
                            AppColors.burgundyBg,
                          ],
                        ),
                        border: Border.all(
                          color: tierColor.withOpacity(0.7),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(tierIcon, size: 36, color: tierColor),
                          const SizedBox(height: 6),
                          Text(
                            tierTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: tierColor,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tierBadgeDesc,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.sandLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: tierColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: tierColor.withOpacity(0.5)),
                            ),
                            child: Text(
                              '$score% SCORE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: tierColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.touch_app, size: 11, color: AppColors.textMuted),
                              SizedBox(width: 3),
                              Text(
                                'Tap to inspect audit',
                                style: TextStyle(fontSize: 9.5, color: AppColors.textMuted),
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
        },
      ),
    );
  }

  // --- PHILOSOPHY TOP CARD ---

  Widget _buildPhilosophyCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.sandBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: const Icon(Icons.balance, color: AppColors.magentaPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your 4 Pillars Status',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Combines Pillar 1 (Health), Pillar 2 (Family), Pillar 3 (Profile), and Pillar 4 (Attendance) to show your current status.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- DIAGNOSTICS SECTION ---

  Widget _buildDiagnosticsSection(BuildContext context, EcosystemProvider provider) {
    final lags = provider.holisticLagAudit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'YOUR 4 PILLARS TODAY',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sandGold,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
              icon: const Icon(Icons.insights, size: 14, color: AppColors.sandGold),
              label: Text(
                'View Details',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.sandGold, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _showLagAuditBottomSheet(context, provider),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 3 Cards for the 3 pillars
        ...lags.map((item) => _buildAuditPillarCard(context, item)),
      ],
    );
  }

  Widget _buildAuditPillarCard(BuildContext context, PillarLagItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.indicatorColor.withOpacity(item.isCompromised ? 0.6 : 0.3),
          width: 1.1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.indicatorColor.withOpacity(0.16),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: item.indicatorColor.withOpacity(0.4)),
            ),
            child: Icon(item.icon, color: item.indicatorColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.pillarTitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.indicatorColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.status,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: item.indicatorColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: AppColors.textMuted,
                  ),
                ),
                if (item.isCompromised) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.indicatorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: item.indicatorColor.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.bolt, size: 12, color: item.indicatorColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Fix: ${item.improvementAction}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: item.indicatorColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- INTERACTIVE AUDIT MODAL BOTTOM SHEET ---

  void _showLagAuditBottomSheet(BuildContext context, EcosystemProvider provider) {
    final auditList = provider.holisticLagAudit;
    final tierColor = provider.holisticTierColor;
    final tierName = provider.holisticTierName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: BoxDecoration(
            color: AppColors.burgundyCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.sandGold, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0x140F172A),
                blurRadius: 30,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bottom sheet drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.sandGold.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Modal Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: tierColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: tierColor),
                      ),
                      child: Icon(Icons.analytics_outlined, color: tierColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR STATUS DETAILS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.sandLight,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tierName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: tierColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.sandLight, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.sandBorder, height: 1),

              // Scrollable Audit Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Pillar Status & Improvement Suggestions:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.sandPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // List of 4 Feeder Pillars with direct actionable buttons
                      ...auditList.map((item) => _buildDetailedAuditItem(context, item)),

                      const SizedBox(height: 16),

                      // Status Summary Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.burgundySurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.sandBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lightbulb_outline, color: AppColors.sandGold, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'How to Get Green Status',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.sandGold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '1. Health: Stay active and keep your BMI healthy.\n'
                              '2. Family: Spend quality time with family and friends.\n'
                              '3. Profile: Submit all required original documents to HR.\n'
                              '4. Attendance: Maintain clean attendance recorded and audited by HR in the Master Ledger.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                height: 1.45,
                                color: AppColors.sandLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Dismiss Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.sandGold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size.fromHeight(44),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Close',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.burgundyBg,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedAuditItem(BuildContext context, PillarLagItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.burgundySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.indicatorColor.withOpacity(0.5),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.indicatorColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.indicatorColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.pillarTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: item.indicatorColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Diagnostic description
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.burgundyBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.sandBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.isCompromised ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                  size: 15,
                  color: item.indicatorColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: AppColors.sandLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Improvement Action
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.arrow_right_alt, size: 16, color: AppColors.sandGold),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Suggestion: ${item.improvementAction}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.sandPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Direct Navigation CTA Button to that Pillar
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.launch, size: 13, color: AppColors.burgundyBg),
              label: Text(
                _getActionTextForPillar(item.pillarTitle),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.burgundyBg,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sandGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              ),
              onPressed: () {
                Navigator.pop(context); // Close bottom sheet
                _navigateToPillar(context, item.pillarTitle);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getActionTextForPillar(String title) {
    if (title.contains('Health')) return 'Go to Pillar 1 (Health)';
    if (title.contains('Family')) return 'Go to Pillar 2 (Family)';
    if (title.contains('Profile')) return 'Go to Pillar 3 (Profile)';
    return 'Go to Pillar 4 (Attendance)';
  }

  void _navigateToPillar(BuildContext context, String title) {
    if (title.contains('Health')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthPillarScreen()));
    } else if (title.contains('Family')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyPillarScreen()));
    } else if (title.contains('Profile')) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePillarScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AttendancePillarScreen()));
    }
  }
}
