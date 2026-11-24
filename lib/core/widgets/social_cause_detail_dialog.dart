import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../../models/company_notification_models.dart';
import '../../models/social_cause_models.dart';
import '../../providers/ecosystem_provider.dart';
import 'notification_comments_sheet.dart';

class SocialCauseDetailDialog extends StatelessWidget {
  final SocialCauseItem? initialCause;
  final CompanyNotification? initialNotification;
  final String? causeId;

  const SocialCauseDetailDialog({
    super.key,
    this.initialCause,
    this.initialNotification,
    this.causeId,
  });

  static Future<void> show(
    BuildContext context, {
    SocialCauseItem? cause,
    CompanyNotification? notification,
    String? causeId,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => SocialCauseDetailDialog(
        initialCause: cause,
        initialNotification: notification,
        causeId: causeId ?? cause?.id ?? notification?.actionTag,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EcosystemProvider>(
      builder: (context, eco, _) {
        final effectiveId = causeId ?? initialCause?.id ?? initialNotification?.actionTag;

        // Resolve latest cause from EcosystemProvider state
        SocialCauseItem? cause;
        if (effectiveId != null && effectiveId.isNotEmpty) {
          final idx = eco.socialCauses.indexWhere((c) => c.id == effectiveId);
          if (idx != -1) {
            cause = eco.socialCauses[idx];
          }
        }
        cause ??= initialCause;

        // Resolve latest notification from EcosystemProvider state
        CompanyNotification? notif;
        if (effectiveId != null && effectiveId.isNotEmpty) {
          final nIdx = eco.companyNotifications.indexWhere(
            (n) => n.actionTag == effectiveId || n.id == effectiveId || n.id == 'NOTIF-SC-$effectiveId',
          );
          if (nIdx != -1) {
            notif = eco.companyNotifications[nIdx];
          }
        }
        notif ??= initialNotification;

        final employeeName = cause?.employeeName ?? notif?.senderName ?? 'Staff Member';
        final employeeRole = cause?.employeeRole ?? notif?.senderRole ?? 'MN Jewel Park Staff';
        final causeType = cause?.causeType ?? 'Social Cause Deed';
        final title = cause?.title.isNotEmpty == true
            ? cause!.title
            : (notif?.title ?? 'Act of Kindness');
        final description = cause?.description.isNotEmpty == true
            ? cause!.description
            : (notif?.content ?? '');
        final amountSpent = cause?.amountSpent ?? 0.0;
        final imageUrl = cause?.imageUrl;

        final currentUserId = eco.activeEmpId;
        final likedStaff = <String>{
          if (cause != null) ...cause.likedEmpIds,
          if (notif != null) ...notif.likedStaffIds,
        };

        final isLikedByMe = likedStaff.contains(currentUserId) ||
            (cause != null && cause.isHeartedByCurrentUser);

        final isCeoReacted = likedStaff.any(
          (id) => id == 'MN-CEO01' || id.toLowerCase().contains('ceo'),
        );

        final totalLikes = likedStaff.isNotEmpty
            ? likedStaff.length
            : (cause?.totalLikesCount ?? 0);

        final categoryColor = SocialCauseType.getColor(causeType);
        final categoryIcon = SocialCauseType.getIcon(causeType);

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Banner with Close Button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.12),
                        border: Border(
                          bottom: BorderSide(color: categoryColor.withOpacity(0.25), width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: categoryColor.withOpacity(0.6), width: 1.2),
                            ),
                            child: Icon(categoryIcon, color: categoryColor, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  causeType,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: categoryColor,
                                  ),
                                ),
                                Text(
                                  'Act of kindness',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.textDark, size: 20),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Contributor Profile Row
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppColors.magentaGradient,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.magentaPrimary.withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    employeeName.trim().isNotEmpty
                                        ? employeeName.trim().split(RegExp(r'\s+')).map((e) => e[0]).take(2).join('').toUpperCase()
                                        : 'MN',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      employeeName,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    Text(
                                      employeeRole,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (amountSpent > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFA7F3D0)),
                                  ),
                                  child: Text(
                                    '₹${amountSpent.toStringAsFixed(0)}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF047857),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Deed Title
                          Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Deed Description
                          if (description.isNotEmpty) ...[
                            Text(
                              description,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: const Color(0xFF334155),
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Attached Photo Preview
                          if (imageUrl != null && imageUrl.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                constraints: const BoxConstraints(maxHeight: 240),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: _buildImageWidget(imageUrl),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          const Divider(color: Color(0xFFE2E8F0), height: 1),
                          const SizedBox(height: 14),

                          // Heart Reaction & Interactions Bar
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Like / Heart Reaction Button
                                  InkWell(
                                    onTap: () {
                                      if (effectiveId != null && effectiveId.isNotEmpty) {
                                        eco.toggleSocialCauseReaction(effectiveId, reactingEmpId: currentUserId);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: isLikedByMe
                                            ? const Color(0xFFFEE2E2)
                                            : const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isLikedByMe
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFFCBD5E1),
                                          width: 1.1,
                                        ),
                                        boxShadow: isLikedByMe
                                            ? [
                                                BoxShadow(
                                                  color: const Color(0xFFEF4444).withOpacity(0.2),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isLikedByMe ? Icons.favorite : Icons.favorite_border,
                                            size: 16,
                                            color: isLikedByMe ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                                          ),
                                          const SizedBox(width: 5),
                                          Text(
                                            totalLikes > 0
                                                ? '$totalLikes ${totalLikes == 1 ? 'Reaction' : 'Reactions'}'
                                                : 'Like',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isLikedByMe ? const Color(0xFFDC2626) : const Color(0xFF475569),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Comments button
                                  InkWell(
                                    onTap: () {
                                      final n = notif ??
                                          CompanyNotification(
                                            id: effectiveId ?? 'CAUSE-TEMP',
                                            title: title,
                                            content: description,
                                            type: CompanyNotificationType.socialCause,
                                            timestamp: cause?.date ?? DateTime.now(),
                                            senderName: employeeName,
                                            senderRole: employeeRole,
                                          );
                                      NotificationCommentsSheet.show(context, n);
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF1F4),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: const Color(0xFFFECDD3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.mode_comment_outlined, size: 15, color: Color(0xFFBE185D)),
                                          const SizedBox(width: 5),
                                          Text(
                                            notif != null && notif.commentsCount > 0
                                                ? 'Comments (${notif.commentsCount})'
                                                : 'Comments',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFFBE185D),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Close',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // CEO Reacted Luxury Banner (shown when CEO liked)
                          if (isCeoReacted) ...[
                            Container(
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B).withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'CEO Reacted!',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF92400E),
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                        Text(
                                          'M N Naveenraaj (Managing Director & CEO) acknowledged this deed.',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFFB45309),
                                          ),
                                        ),
                                      ],
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
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      try {
        final commaIdx = imageUrl.indexOf(',');
        final base64Str = commaIdx != -1 ? imageUrl.substring(commaIdx + 1) : imageUrl;
        return Image.memory(
          base64Decode(base64Str),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
      } catch (_) {
        return const Center(child: Icon(Icons.broken_image, color: Colors.grey));
      }
    } else if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

