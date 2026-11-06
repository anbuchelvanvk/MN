import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/ecosystem_provider.dart';
import '../../models/social_cause_models.dart';
import '../../services/image_optimization_service.dart';

class SocialCausePillarScreen extends StatefulWidget {
  final bool isStandalone;
  const SocialCausePillarScreen({super.key, this.isStandalone = true});

  @override
  State<SocialCausePillarScreen> createState() => _SocialCausePillarScreenState();
}

class _SocialCausePillarScreenState extends State<SocialCausePillarScreen> {
  String _filter = 'all'; // 'all', 'mine', 'pending'

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
        title: Text(
          'SOCIAL CAUSE',
          style: GoogleFonts.cinzel(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.sandLight,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sandGold.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                  color: const Color(0xFFEF4444).withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)),
                ),
                child: const Icon(Icons.volunteer_activism, color: Color(0xFFEF4444), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MN Social Cause Initiative',
                      style: GoogleFonts.cinzel(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sandLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Kindness, Community Service & Good Deeds',
                      style: TextStyle(fontSize: 11, color: AppColors.sandGold),
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
              color: AppColors.sandLight.withOpacity(0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.burgundySurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.sandBorder),
            ),
            child: Row(
              children: [
                Expanded(child: _metricColumn('Total Value', '₹${totalApprovedSpent.toStringAsFixed(0)}', AppColors.sandGold)),
                Container(width: 1, height: 26, color: AppColors.sandBorder),
                Expanded(child: _metricColumn('Approved', '$approvedCount', const Color(0xFF10B981))),
                Container(width: 1, height: 26, color: AppColors.sandBorder),
                Expanded(child: _metricColumn('Total Posted', '$totalCount', AppColors.sandLight)),
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
          style: GoogleFonts.cinzel(
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
          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
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
            color: isSelected ? AppColors.sandGold : AppColors.burgundyCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.sandGold : AppColors.sandBorder,
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
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.burgundyBg : AppColors.sandLight,
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

    return Container(
      decoration: BoxDecoration(
        color: AppColors.burgundyCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cause.isApproved ? AppColors.sandBorder : const Color(0xFFF59E0B).withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Employee & Cause Type
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: typeColor.withOpacity(0.4)),
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              cause.employeeName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.sandLight,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(cause),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              cause.employeeRole,
                              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(width: 3, height: 3, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.textMuted)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              cause.causeType,
                              style: TextStyle(fontSize: 10, color: typeColor, fontWeight: FontWeight.w600),
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
          ),

          // Deed Title & Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cause.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.sandLight,
                  ),
                ),
                if (cause.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    cause.description,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.sandLight, height: 1.35),
                  ),
                ],
              ],
            ),
          ),

          // Optional Image attachment
          if (cause.imageUrl != null && cause.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  cause.imageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 80,
                    color: AppColors.burgundySurface,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image, color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),
          const Divider(color: AppColors.sandBorder, height: 1),

          // Footer: Amount Spent, Approval & Heart Reaction
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.sandGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.sandGold.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.currency_rupee, size: 12, color: AppColors.sandGold),
                      Text(
                        '${cause.amountSpent.toStringAsFixed(0)} Sponsored',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sandGold,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cause.isApproved) ...[
                        const Icon(Icons.verified, size: 13, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        const Text(
                          'Approved',
                          style: TextStyle(fontSize: 9.5, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                      ],
                      InkWell(
                      onTap: () => eco.toggleSocialCauseHeart(cause.id),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              cause.isHeartedByCurrentUser ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: cause.isHeartedByCurrentUser ? const Color(0xFFEF4444) : AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${cause.heartsCount}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: cause.isHeartedByCurrentUser ? const Color(0xFFEF4444) : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(SocialCauseItem cause) {
    if (cause.isApproved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF10B981)),
        ),
        child: const Text(
          'Approved',
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
        ),
      );
    }
    if (cause.isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withOpacity(0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFF59E0B)),
        ),
        child: const Text(
          'Pending HR/CEO Approval',
          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Rejected',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
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
                style: GoogleFonts.cinzel(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.sandLight),
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
                  decoration: InputDecoration(
                    hintText: 'e.g. Bought food for elderly person, blood donation...',
                    hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.burgundySurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                  ),
                ),
                const SizedBox(height: 12),

                const Text('Cost / Amount Spent (₹)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.sandGold)),
                const SizedBox(height: 6),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12, color: AppColors.sandLight),
                  decoration: InputDecoration(
                    prefixText: '₹ ',
                    prefixStyle: const TextStyle(color: AppColors.sandGold, fontWeight: FontWeight.bold),
                    hintText: 'e.g. 500, 1500 (enter 0 if voluntary)',
                    hintStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.burgundySurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
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
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                          ),
                        ),
                        InkWell(
                          onTap: () => setDialogState(() {
                            compressedPhotoDataUrl = null;
                            compressedPhotoSizeKb = null;
                          }),
                          child: const Icon(Icons.close, size: 14, color: Colors.white70),
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
                    hintStyle: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.burgundySurface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.sandBorder)),
                  ),
                ),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter what deed was performed.')),
                  );
                  return;
                }
                final amount = double.tryParse(amountCtrl.text.trim());
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid contribution amount greater than ₹0.')),
                  );
                  return;
                }

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

