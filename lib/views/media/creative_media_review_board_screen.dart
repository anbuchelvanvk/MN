import '../../core/widgets/mn_app_bar.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/google_drive_upload_service.dart';
import '../../core/theme/app_colors.dart';
import '../../models/creative_media_asset_model.dart';
import '../../providers/ecosystem_provider.dart';

class CreativeMediaReviewBoardScreen extends StatefulWidget {
  const CreativeMediaReviewBoardScreen({super.key});

  @override
  State<CreativeMediaReviewBoardScreen> createState() =>
      _CreativeMediaReviewBoardScreenState();
}

class _CreativeMediaReviewBoardScreenState
    extends State<CreativeMediaReviewBoardScreen> {
  String _selectedStatusFilter = 'all'; // 'all', 'pending_review', 'revisions_requested', 'approved_by_ceo', 'published'
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Reel',
    'Photoshoot',
    'Catalog Banner',
    'YouTube Short',
    'Story',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: MnAppBar(
        title: 'Media Review',
        subtitle: 'Photoshoots and reels for sign-off',
        actions: [
          MnGlassIconButton(
            icon: Icons.add_photo_alternate_outlined,
            tooltip: 'Upload media',
            onTap: () => _openSubmitAssetSheet(context),
          ),
        ],
      ),
      body: Consumer<EcosystemProvider>(
        builder: (context, eco, _) {
          final allAssets = eco.mediaAssets;

          // Stats
          final totalCount = allAssets.length;
          final pendingCount =
              allAssets.where((a) => a.isPendingReview).length;
          final revisionCount =
              allAssets.where((a) => a.isRevisionsRequested).length;
          final approvedCount =
              allAssets.where((a) => a.isApprovedByCeo || a.isPublished).length;

          // Filtering
          final filtered = allAssets.where((asset) {
            final matchesStatus = _selectedStatusFilter == 'all' ||
                asset.status == _selectedStatusFilter;
            final matchesCat = _selectedCategory == 'All' ||
                asset.category.toLowerCase() == _selectedCategory.toLowerCase();
            final matchesSearch = _searchQuery.isEmpty ||
                asset.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                asset.description
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                asset.creatorName
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                asset.collectionTag
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());
            return matchesStatus && matchesCat && matchesSearch;
          }).toList();

          return Column(
            children: [
              // Header Summary Metrics
              Container(
                color: AppColors.pureWhite,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _metricTile(
                          label: 'Total Drafts',
                          value: '$totalCount',
                          color: const Color(0xFF334155),
                          bgColor: const Color(0xFFF1F5F9),
                        ),
                        const SizedBox(width: 8),
                        _metricTile(
                          label: 'Pending Review',
                          value: '$pendingCount',
                          color: const Color(0xFFD97706),
                          bgColor: const Color(0xFFFEF3C7),
                        ),
                        const SizedBox(width: 8),
                        _metricTile(
                          label: 'Revisions',
                          value: '$revisionCount',
                          color: const Color(0xFFE11D48),
                          bgColor: const Color(0xFFFFE4E6),
                        ),
                        const SizedBox(width: 8),
                        _metricTile(
                          label: 'Approved / Live',
                          value: '$approvedCount',
                          color: const Color(0xFF059669),
                          bgColor: const Color(0xFFD1FAE5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Search Input
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim()),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: AppColors.textDark),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search,
                              size: 18, color: Color(0xFF64748B)),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          hintText: 'Search by title, creator, or collection...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5, color: const Color(0xFF94A3B8)),
                          border: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Status Filter Tabs
              Container(
                color: AppColors.pureWhite,
                padding: const EdgeInsets.only(bottom: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _statusFilterChip('All Statuses', 'all', totalCount),
                      _statusFilterChip(
                          'Pending CEO Review', 'pending_review', pendingCount),
                      _statusFilterChip('Revisions Requested',
                          'revisions_requested', revisionCount),
                      _statusFilterChip('Approved for Posting',
                          'approved_by_ceo', approvedCount),
                      _statusFilterChip('Live Published', 'published',
                          allAssets.where((a) => a.isPublished).length),
                    ],
                  ),
                ),
              ),

              // Category Selector
              Container(
                color: const Color(0xFFF8FAFC),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            cat,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF475569),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.magentaPrimary,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.magentaPrimary
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          onSelected: (_) =>
                              setState(() => _selectedCategory = cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Asset Cards List
              Expanded(
                child: filtered.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _buildMediaCard(
                              context, filtered[index], eco);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.magentaPrimary,
        elevation: 3,
        icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
        label: Text(
          'Submit Media Draft',
          style: GoogleFonts.plusJakartaSans(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
        onPressed: () => _openSubmitAssetSheet(context),
      ),
    );
  }

  Widget _metricTile({
    required String label,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2), width: 0.8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.9),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusFilterChip(String label, String value, int count) {
    final isSelected = _selectedStatusFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedStatusFilter = value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.magentaPrimary.withOpacity(0.1)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.magentaPrimary
                  : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? AppColors.magentaPrimary
                      : const Color(0xFF475569),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.magentaPrimary
                      : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_collection_outlined,
              size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No Media Assets Found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Upload a new photoshoot or reel draft to initiate CEO review.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaCard(
      BuildContext context, CreativeMediaAsset asset, EcosystemProvider eco) {
    final isCeo = eco.isCeo;

    Color statusColor = const Color(0xFFD97706);
    Color statusBg = const Color(0xFFFEF3C7);
    IconData statusIcon = Icons.hourglass_top_rounded;

    if (asset.isApprovedByCeo) {
      statusColor = const Color(0xFF059669);
      statusBg = const Color(0xFFD1FAE5);
      statusIcon = Icons.check_circle_outline_rounded;
    } else if (asset.isRevisionsRequested) {
      statusColor = const Color(0xFFE11D48);
      statusBg = const Color(0xFFFFE4E6);
      statusIcon = Icons.edit_note_rounded;
    } else if (asset.isPublished) {
      statusColor = const Color(0xFF2563EB);
      statusBg = const Color(0xFFDBEAFE);
      statusIcon = Icons.public_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Badges Strip
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Row(
              children: [
                // Category Tag
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF660022),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        asset.category == 'Reel'
                            ? Icons.play_circle_fill_rounded
                            : Icons.camera_alt_rounded,
                        size: 11,
                        color: AppColors.sandGold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        asset.category.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Collection Tag (if specified)
                if (asset.collectionTag.trim().isNotEmpty) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: const Color(0xFFFDE68A), width: 0.8),
                    ),
                    child: Text(
                      asset.collectionTag,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
                const Spacer(),

                // Status Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 11, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        asset.displayStatus,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Title & Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  asset.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF475569),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),

          // Caption Draft (if available)
          if (asset.captionDraft.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tag, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        asset.captionDraft,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF334155),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 13),
                      tooltip: 'Copy Caption',
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: asset.captionDraft));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Caption copied to clipboard!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Target Channels & Creator Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFFE2E8F0),
                  child: Text(
                    asset.creatorName.isNotEmpty
                        ? asset.creatorName.substring(0, 1)
                        : 'M',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${asset.creatorName} (${asset.creatorRole})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
                const Spacer(),

                // Target channel badges
                ...asset.targetChannels.map((ch) {
                  return Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ch,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Google Drive Action Link
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: asset.driveUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF0F172A),
                    content: Row(
                      children: [
                        const Icon(Icons.cloud_done,
                            color: Colors.greenAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Google Drive preview URL copied: ${asset.driveUrl}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: const Color(0xFFBFDBFE), width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_to_drive,
                        size: 15, color: Color(0xFF2563EB)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Google Drive: ${asset.driveUrl}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1D4ED8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.copy_rounded,
                        size: 13, color: Color(0xFF2563EB)),
                  ],
                ),
              ),
            ),
          ),

          // Review Comments Thread (Expandable)
          if (asset.comments.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REVIEW LOG (${asset.comments.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...asset.comments.map((comment) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: comment.isExecutiveNote
                            ? const Color(0xFFFFFBEB)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: comment.isExecutiveNote
                              ? const Color(0xFFFDE68A)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            comment.isExecutiveNote
                                ? Icons.verified_rounded
                                : Icons.chat_bubble_outline_rounded,
                            size: 13,
                            color: comment.isExecutiveNote
                                ? const Color(0xFFD97706)
                                : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text:
                                        '${comment.authorName} (${comment.authorRole}): ',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: comment.isExecutiveNote
                                          ? const Color(0xFFB45309)
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  TextSpan(
                                    text: comment.comment,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      color: const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          const Divider(height: 14, color: Color(0xFFE2E8F0)),

          // Bottom Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                // Collaborative comment button
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_comment_outlined, size: 14),
                  label: const Text('Feedback'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    textStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _openFeedbackDialog(context, asset, eco),
                ),
                const Spacer(),

                // Executive CEO Actions
                if (isCeo) ...[
                  if (!asset.isApprovedByCeo && !asset.isPublished) ...[
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE11D48),
                        side: const BorderSide(color: Color(0xFFFDA4AF)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        textStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _openRequestRevisionsDialog(
                          context, asset, eco),
                      child: const Text('Request Changes'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        textStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        eco.reviewCreativeMediaAsset(
                          assetId: asset.id,
                          newStatus: 'approved_by_ceo',
                          feedbackNote:
                              'Approved by CEO M N Naveenraaj for social media publishing.',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF059669),
                            content: Text(
                                'Asset "${asset.title}" cleared for social media!'),
                          ),
                        );
                      },
                    ),
                  ] else if (asset.isApprovedByCeo && !asset.isPublished) ...[
                    ElevatedButton.icon(
                      icon: const Icon(Icons.public, size: 14),
                      label: const Text('Mark Published'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        textStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () =>
                          _openMarkPublishedDialog(context, asset, eco),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openFeedbackDialog(
      BuildContext context, CreativeMediaAsset asset, EcosystemProvider eco) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Add Creative Feedback',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: GoogleFonts.plusJakartaSans(fontSize: 12),
          decoration: const InputDecoration(
            hintText: 'Enter feedback note, lighting tweak, or edit request...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.magentaPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                eco.addMediaAssetComment(
                  assetId: asset.id,
                  comment: controller.text.trim(),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Post Note'),
          ),
        ],
      ),
    );
  }

  void _openRequestRevisionsDialog(
      BuildContext context, CreativeMediaAsset asset, EcosystemProvider eco) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Request Creative Revisions',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE11D48)),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: GoogleFonts.plusJakartaSans(fontSize: 12),
          decoration: const InputDecoration(
            hintText:
                'Specify required changes (e.g. angle out of focus, adjust color grading)...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                eco.reviewCreativeMediaAsset(
                  assetId: asset.id,
                  newStatus: 'revisions_requested',
                  feedbackNote: controller.text.trim(),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('Send Revision Request'),
          ),
        ],
      ),
    );
  }

  void _openMarkPublishedDialog(
      BuildContext context, CreativeMediaAsset asset, EcosystemProvider eco) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Mark Post as Live & Published',
          style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          style: GoogleFonts.plusJakartaSans(fontSize: 12),
          decoration: const InputDecoration(
            hintText: 'Paste live Instagram Reel URL or post link...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              eco.markMediaAssetPublished(
                assetId: asset.id,
                publishedUrl: controller.text.trim(),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Confirm Live Post'),
          ),
        ],
      ),
    );
  }

  void _openSubmitAssetSheet(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final driveController = TextEditingController();
    final captionController = TextEditingController();
    String category = 'Reel';
    String collectionTag = '';
    List<String> targetChannels = ['Instagram'];
    bool isUploadingToDrive = false;
    String? uploadedDriveFileName;
    String? uploadErrorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.88,
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE4E6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.cloud_upload_outlined,
                            color: AppColors.magentaPrimary, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Submit Media Draft for Review',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Uploaded to Google Drive for CEO sign-off',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Title
                  Text('ASSET TITLE *',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF475569))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: titleController,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 22K Antique Lakshmi Choker 4K Reel',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category
                  Text('CATEGORY',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF475569))),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: category,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, color: AppColors.textDark),
                    decoration: const InputDecoration(
                        border: OutlineInputBorder()),
                    items: ['Reel', 'Photoshoot', 'Catalog Banner', 'Story']
                        .map((c) => DropdownMenuItem(
                            value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSheetState(() => category = v);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Media Asset File Upload Header
                  Text(
                    'UPLOAD MEDIA FILE *',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Option A: Direct File Upload to Google Drive via Apps Script Webhook
                  InkWell(
                    onTap: isUploadingToDrive
                        ? null
                        : () async {
                            try {
                              final result = await FilePicker.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: [
                                  'mp4', 'mov', 'avi', 'mkv', 'jpg', 'jpeg', 'png', 'pdf'
                                ],
                                withData: true,
                              );
                              if (result == null || result.files.isEmpty) return;
                              final file = result.files.single;
                              final bytes = file.bytes ??
                                  (file.path != null
                                      ? await File(file.path!).readAsBytes()
                                      : null);
                              if (bytes == null) return;

                              setSheetState(() {
                                isUploadingToDrive = true;
                                uploadErrorMessage = null;
                              });

                              final res = await GoogleDriveUploadService.uploadMediaToDrive(
                                fileBytes: bytes,
                                fileName: file.name,
                                folderId: GoogleDriveUploadService.mediaFolderId,
                              );

                              final driveUrl = res['driveUrl'] as String? ??
                                  res['previewUrl'] as String? ??
                                  res['downloadUrl'] as String?;

                              if (driveUrl != null && driveUrl.isNotEmpty) {
                                setSheetState(() {
                                  driveController.text = driveUrl;
                                  uploadedDriveFileName = file.name;
                                  isUploadingToDrive = false;
                                  if (titleController.text.trim().isEmpty) {
                                    titleController.text = file.name.replaceAll(
                                        RegExp(r'\.[a-zA-Z0-9]+$'), '');
                                  }
                                });
                              } else {
                                throw Exception('No Drive URL returned from webhook');
                              }
                            } catch (e) {
                              setSheetState(() {
                                isUploadingToDrive = false;
                                uploadErrorMessage = 'Upload note: $e';
                              });
                            }
                          },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: isUploadingToDrive
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF16A34A)),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Uploading Media File...',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.cloud_upload_outlined,
                                    size: 18, color: Color(0xFF16A34A)),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    uploadedDriveFileName != null
                                        ? 'Uploaded: $uploadedDriveFileName (Tap to replace)'
                                        : 'Upload Media File',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF15803D),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  if (uploadErrorMessage != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      uploadErrorMessage!,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFFDC2626)),
                    ),
                  ],
                  const SizedBox(height: 8),

                  // Option B: Or paste Google Drive Link manually
                  Text(
                    'OR PASTE MEDIA LINK / SHARING URL',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: driveController,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.link, size: 16),
                      hintText: 'https://drive.google.com/file/d/...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text('PRODUCTION NOTES / SCOPE',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF475569))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Describe shoot angles, models, or lighting...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Caption Draft
                  Text('SOCIAL MEDIA CAPTION & HASHTAGS DRAFT',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF475569))),
                  const SizedBox(height: 4),
                  TextField(
                    controller: captionController,
                    maxLines: 2,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 916 Hallmark Gold. DM for custom bridal orders. #MNJewelPark',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: const Text('Submit for CEO Sign-Off'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.magentaPrimary,
                        foregroundColor: Colors.white,
                        textStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        if (titleController.text.trim().isEmpty ||
                            driveController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter Title and select or paste a Media File!'),
                            ),
                          );
                          return;
                        }

                        Provider.of<EcosystemProvider>(context, listen: false)
                            .submitCreativeMediaAsset(
                          title: titleController.text.trim(),
                          description: descController.text.trim(),
                          category: category,
                          collectionTag: collectionTag,
                          driveUrl: driveController.text.trim(),
                          captionDraft: captionController.text.trim(),
                          targetChannels: targetChannels,
                        );

                        Navigator.pop(sheetCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Color(0xFF059669),
                            content: Text(
                                'Media asset draft submitted for CEO review!'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
