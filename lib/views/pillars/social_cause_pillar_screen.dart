import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/ecosystem_provider.dart';
import '../../models/social_cause_models.dart';
import '../../services/image_optimization_service.dart';
import '../../core/widgets/social_cause_detail_dialog.dart';
import '../ceo/ceo_subpages.dart';

class SocialCausePillarScreen extends StatefulWidget {
  final bool isStandalone;
  const SocialCausePillarScreen({super.key, this.isStandalone = true});

  @override
  State<SocialCausePillarScreen> createState() => _SocialCausePillarScreenState();
}

class _SocialCausePillarScreenState extends State<SocialCausePillarScreen> {
  String _filter = 'all'; // 'all', 'mine', 'pending'

  String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minStr = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour12:$minStr $period';
  }

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final allCauses = eco.socialCauses;
    final currentEmpId = eco.activeEmpId;

    final filtered = allCauses.where((c) {
      if (_filter == 'mine') return c.empId == currentEmpId;
      if (_filter == 'pending') return c.isPending;
      return true;
    }).toList();

    final totalSpent = allCauses.fold(0.0, (sum, c) => sum + (c.isApproved ? c.amountSpent : 0.0));
    final approvedCount = allCauses.where((c) => c.isApproved).length;

    final content = SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Hero Impact Banner
          _buildHeroBanner(totalSpent, approvedCount, allCauses.length),
          const SizedBox(height: 16),

          // 2. Action Button to Post
          ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.burgundyBg),
            label: Text(
              'Post Social Cause',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.burgundyBg,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.sandGold,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
            ),
            onPressed: () => _showPostSocialCauseDialog(context, eco),
          ),
          if (eco.isCeo || eco.activeRole == 'ceo' || eco.activeRole == 'hr') ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.verified_user_outlined, size: 18, color: AppColors.sandGold),
                  if (eco.pendingSocialCauses.isNotEmpty)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Color(0xFFE11D48), shape: BoxShape.circle),
                        child: Text(
                          '${eco.pendingSocialCauses.length}',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              label: Text(
                'Approve Pending Social Causes (${eco.pendingSocialCauses.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sandGold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.sandGold, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CeoSocialCausesScreen()),
                );
              },
            ),
          ],
          const SizedBox(height: 16),

          // 3. Filter tabs
          Row(
            children: [
              _filterTab('all', 'All (${allCauses.length})'),
              const SizedBox(width: 8),
              _filterTab('mine', 'My Deeds'),
              const SizedBox(width: 8),
              _filterTab('pending', 'Pending (${eco.pendingSocialCauses.length})'),
            ],
          ),
          const SizedBox(height: 14),

          // 4. Feed
          if (filtered.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, idx) => _buildCauseCard(ctx, eco, filtered[idx]),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );

    if (!widget.isStandalone) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppColors.burgundyBg,
      appBar: AppBar(
        backgroundColor: AppColors.burgundyCard,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Social Cause',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.sandGold,
              ),
            ),
            const Text(
              'Pillar 5 • Occasional Cadence',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: AppColors.sandGold),
            tooltip: 'Post Good Deed',
            onPressed: () => _showPostSocialCauseDialog(context, eco),
          ),
        ],
      ),
      body: content,
    );
  }

  Widget _buildHeroBanner(double totalApprovedSpent, int approvedCount, int totalCount) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F4),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: const Icon(Icons.volunteer_activism, color: Color(0xFFE11D48), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MN Social Cause Initiative',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Kindness, Community Service & Good Deeds • Occasional Cadence',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFFE11D48), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Whether providing food for an elderly person, blood donation, eye pledging, or medical help — record your good deeds here. Once verified by HR or CEO, your deed is celebrated across the company!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFF475569),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(child: _metricColumn('Total Value', '₹${totalApprovedSpent.toStringAsFixed(0)}', const Color(0xFFE11D48))),
                Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                Expanded(child: _metricColumn('Approved', '$approvedCount', const Color(0xFF10B981))),
                Container(width: 1, height: 26, color: const Color(0xFFE2E8F0)),
                Expanded(child: _metricColumn('Total Posted', '$totalCount', const Color(0xFF0F172A))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _filterTab(String key, String label) {
    final isSelected = _filter == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filter = key),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE11D48) : AppColors.pureWhite,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFFE11D48) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCauseCard(BuildContext context, EcosystemProvider eco, SocialCauseItem cause) {
    final typeColor = SocialCauseType.getColor(cause.causeType);
    final typeIcon = SocialCauseType.getIcon(cause.causeType);
    final isLiked = cause.isHeartedBy(eco.activeEmpId);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cause.isPending ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => SocialCauseDetailDialog.show(context, cause: cause),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Avatar, Name, Role, Date & Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar with category icon
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: typeColor.withOpacity(0.25)),
                      ),
                      child: Center(
                        child: Icon(typeIcon, color: typeColor, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Contributor Name, Role & Timestamp
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cause.employeeName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cause.employeeRole,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 11, color: Color(0xFF94A3B8)),
                              const SizedBox(width: 4),
                              Text(
                                _formatDateTime(cause.date),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status Badge & Delete action at top-right
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildStatusBadge(cause),
                        if (cause.empId == eco.activeEmpId || eco.isCeo || eco.activeRole == 'ceo' || eco.activeRole == 'hr') ...[
                          const SizedBox(height: 6),
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  backgroundColor: AppColors.burgundyCard,
                                  title: const Text('Delete Social Cause?', style: TextStyle(color: AppColors.sandLight, fontSize: 14, fontWeight: FontWeight.bold)),
                                  content: const Text('Are you sure you want to delete this social cause? It will be removed permanently.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(c, false),
                                      child: const Text('Cancel', style: TextStyle(color: AppColors.sandGold)),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                                      onPressed: () => Navigator.pop(c, true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await eco.deleteSocialCause(cause.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Social cause deleted successfully')),
                                  );
                                }
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFEF4444)),
                                  SizedBox(width: 2),
                                  Text('Delete', style: TextStyle(fontSize: 11.5, color: Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Deed Content Card Container (Soft slate/grey container)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cause Category Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          cause.causeType,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: typeColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Deed Title
                      Text(
                        cause.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      // Deed Description
                      if (cause.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          cause.description,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF475569),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Optional Attached Photo
                if (cause.imageUrl != null && cause.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      cause.imageUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 80,
                        color: const Color(0xFFF1F5F9),
                        alignment: Alignment.center,
                        child: const Icon(Icons.image, color: Color(0xFF94A3B8)),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 10),

                // Footer Row: Sponsored Amount & CEO Reacted on Left, Heart Reaction on Right
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Chips: Sponsored & CEO Reaction (No duplicate "Approved" text!)
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (cause.amountSpent > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F4),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFECDD3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.currency_rupee, size: 12, color: Color(0xFFE11D48)),
                                  Text(
                                    '${cause.amountSpent.toStringAsFixed(0)} Sponsored',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFE11D48),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFA7F3D0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.volunteer_activism, size: 12, color: Color(0xFF059669)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Voluntary Service',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (cause.isCeoReacted)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.star_rounded, size: 13, color: Color(0xFFD97706)),
                                  SizedBox(width: 4),
                                  Text(
                                    'CEO Reacted!',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Right side: Interactive Like / Heart button
                    InkWell(
                      onTap: () => eco.toggleSocialCauseReaction(cause.id, reactingEmpId: eco.activeEmpId),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isLiked ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isLiked ? const Color(0xFFFDA4AF) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 15,
                              color: isLiked ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${cause.totalLikesCount}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isLiked ? const Color(0xFFE11D48) : const Color(0xFF64748B),
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
        ),
      ),
    );
  }

  Widget _buildStatusBadge(SocialCauseItem cause) {
    if (cause.isApproved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF059669)),
            SizedBox(width: 4),
            Text(
              'Approved',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
            ),
          ],
        ),
      );
    }
    if (cause.isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.schedule_rounded, size: 12, color: Color(0xFFD97706)),
            SizedBox(width: 4),
            Text(
              'Pending Approval',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFD97706)),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.cancel_rounded, size: 12, color: Color(0xFFDC2626)),
          SizedBox(width: 4),
          Text(
            'Rejected',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: const [
          Icon(Icons.volunteer_activism_outlined, size: 40, color: AppColors.textMuted),
          SizedBox(height: 10),
          Text(
            'No social causes found in this category',
            style: TextStyle(color: AppColors.sandLight, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 4),
          Text(
            'Be the first to record a good deed and inspire the MN Jewel Park family!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  void _showPostSocialCauseDialog(BuildContext context, EcosystemProvider eco) {
    String selectedType = SocialCauseType.foodDonation;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final imageCtrl = TextEditingController();
    String? compressedPhotoDataUrl;
    double? compressedPhotoSizeKb;
    bool isVolunteering = false;
    String? inlineErrorMessage;

    final currentEmp = eco.employees.firstWhere(
      (e) => e.id == eco.activeEmpId,
      orElse: () => eco.employees.first,
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.burgundyCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.sandGold)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.sandGold.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite, color: AppColors.sandGold, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'Post a Social Cause',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.sandLight),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cause Category',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.burgundySurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.sandBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedType,
                      dropdownColor: AppColors.burgundyCard,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.sandGold),
                      style: const TextStyle(fontSize: 12, color: AppColors.sandLight),
                      items: SocialCauseType.all.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Icon(SocialCauseType.getIcon(t), size: 16, color: SocialCauseType.getColor(t)),
                              const SizedBox(width: 8),
                              Text(t),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selectedType = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('What good deed did you do?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                const SizedBox(height: 6),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(fontSize: 12, color: AppColors.sandLight),
                  onChanged: (_) {
                    if (inlineErrorMessage != null) {
                      setDialogState(() => inlineErrorMessage = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'e.g. Bought food for elderly person, blood donation...',
                    hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.burgundySurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'Amount Spent (₹)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Volunteering Toggle Button
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setDialogState(() {
                          isVolunteering = !isVolunteering;
                          inlineErrorMessage = null;
                          if (isVolunteering) {
                            amountCtrl.text = '0';
                          } else {
                            amountCtrl.clear();
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: isVolunteering ? const Color(0xFF10B981) : AppColors.burgundySurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isVolunteering ? const Color(0xFF10B981) : AppColors.sandGold.withOpacity(0.6),
                            width: isVolunteering ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVolunteering ? Icons.check_circle : Icons.volunteer_activism,
                              size: 13,
                              color: isVolunteering ? Colors.white : AppColors.sandGold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isVolunteering ? 'Volunteering (₹0)' : 'Volunteering',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isVolunteering ? Colors.white : AppColors.sandGold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: amountCtrl,
                  readOnly: isVolunteering,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 12,
                    color: isVolunteering ? const Color(0xFF34D399) : AppColors.sandLight,
                    fontWeight: isVolunteering ? FontWeight.bold : FontWeight.normal,
                  ),
                  onChanged: (_) {
                    if (inlineErrorMessage != null) {
                      setDialogState(() => inlineErrorMessage = null);
                    }
                  },
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: TextStyle(
                      color: isVolunteering ? const Color(0xFF34D399) : AppColors.sandGold,
                      fontWeight: FontWeight.bold,
                    ),
                    suffixText: isVolunteering ? 'Voluntary Service' : null,
                    suffixStyle: const TextStyle(fontSize: 11.5, color: Color(0xFF34D399), fontWeight: FontWeight.bold),
                    hintText: isVolunteering ? '0 (Voluntary Service)' : 'e.g. 500, 1500 (or tap Volunteering)',
                    hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    filled: true,
                    fillColor: isVolunteering ? const Color(0xFF10B981).withOpacity(0.12) : AppColors.burgundySurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isVolunteering ? const Color(0xFF10B981) : AppColors.sandBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isVolunteering ? const Color(0xFF10B981) : AppColors.sandBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.sandGold, width: 1.2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('Story / Description (Optional)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 12, color: AppColors.sandLight),
                  decoration: InputDecoration(
                    hintText: 'Share a few words on what you did and where...',
                    hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.burgundySurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('Attach Photo / Receipt Proof (Max 150 KB)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
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
                          if (res != null) {
                            setDialogState(() {
                              compressedPhotoDataUrl = res.dataUrl;
                              compressedPhotoSizeKb = res.sizeInKb;
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
                          if (res != null) {
                            setDialogState(() {
                              compressedPhotoDataUrl = res.dataUrl;
                              compressedPhotoSizeKb = res.sizeInKb;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                if (compressedPhotoDataUrl != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Optimized: ${compressedPhotoSizeKb?.toStringAsFixed(1)} KB (Safe <= 150 KB)',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                          ),
                        ),
                        InkWell(
                          onTap: () => setDialogState(() {
                            compressedPhotoDataUrl = null;
                            compressedPhotoSizeKb = null;
                          }),
                          child: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: imageCtrl,
                  style: const TextStyle(fontSize: 12, color: AppColors.sandLight),
                  decoration: InputDecoration(
                    hintText: 'Or paste external image URL...',
                    hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.burgundySurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                  ),
                ),

                // Inline Error Display in the dialog
                if (inlineErrorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7F1D1D),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEF4444)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, size: 16, color: Color(0xFFFCA5A5)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            inlineErrorMessage!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFFEE2E2),
                              fontWeight: FontWeight.w600,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.sandGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final title = titleCtrl.text.trim();
                if (title.isEmpty) {
                  setDialogState(() {
                    inlineErrorMessage = 'Please enter what deed was performed.';
                  });
                  return;
                }

                double amount = 0.0;
                if (!isVolunteering) {
                  final parsed = double.tryParse(amountCtrl.text.trim());
                  if (parsed == null || parsed <= 0) {
                    setDialogState(() {
                      inlineErrorMessage = 'Please enter an amount > ₹0 or tap "Volunteering" for free service.';
                    });
                    return;
                  }
                  amount = parsed;
                } else {
                  amount = 0.0;
                }

                setDialogState(() {
                  inlineErrorMessage = null;
                });

                final finalImage = compressedPhotoDataUrl ?? (imageCtrl.text.trim().isNotEmpty ? imageCtrl.text.trim() : null);

                eco.submitSocialCause(
                  empId: currentEmp.id,
                  employeeName: currentEmp.name,
                  employeeRole: currentEmp.role,
                  causeType: selectedType,
                  title: title,
                  description: descCtrl.text.trim(),
                  amountSpent: amount,
                  imageUrl: finalImage,
                );

                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Color(0xFF10B981),
                    content: Text('Social deed submitted. Pending review by HR / CEO.'),
                  ),
                );
              },
              child: const Text(
                'Submit for Approval',
                style: TextStyle(color: AppColors.burgundyBg, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

