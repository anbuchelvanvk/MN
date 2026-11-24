import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../../providers/ecosystem_provider.dart';
import '../../models/company_notification_models.dart';
import '../../views/orders/online_orders_handler_screen.dart';
import '../../views/pillars/attendance_pillar_screen.dart';
import 'social_cause_detail_dialog.dart';
import 'notification_comments_sheet.dart';

class CompanyNotificationSheet extends StatefulWidget {
  const CompanyNotificationSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const CompanyNotificationSheet(),
    );
  }

  @override
  State<CompanyNotificationSheet> createState() => _CompanyNotificationSheetState();
}

class _CompanyNotificationSheetState extends State<CompanyNotificationSheet> {
  String _selectedFilter = 'all'; // 'all', 'birthday', 'socialCause', 'broadcastNotice', 'todoReminder'

  @override
  Widget build(BuildContext context) {
    final eco = context.watch<EcosystemProvider>();
    final notifications = eco.activeCompanyNotifications;
    final unreadCount = eco.unreadNotificationCount;

    final validNotifs = notifications.where((n) => n.isValid).toList();

    final filtered = validNotifs.where((n) {
      if (_selectedFilter == 'all') return true;
      if (_selectedFilter == 'teamAlerts') {
        final title = n.title.toLowerCase();
        final content = n.content.toLowerCase();
        return title.contains('order') ||
            title.contains('overdue') ||
            title.contains('absent') ||
            title.contains('reassignment') ||
            title.contains('nudge') ||
            title.contains('sla') ||
            content.contains('order') ||
            content.contains('reassign') ||
            content.contains('nudge') ||
            n.type == CompanyNotificationType.todoReminder;
      }
      if (_selectedFilter == 'birthday') {
        return n.type == CompanyNotificationType.birthday || n.type == CompanyNotificationType.anniversary;
      }
      if (_selectedFilter == 'socialCause') {
        return n.type == CompanyNotificationType.socialCause;
      }
      if (_selectedFilter == 'broadcastNotice') {
        return n.type == CompanyNotificationType.broadcastNotice;
      }
      if (_selectedFilter == 'todoReminder') {
        return n.type == CompanyNotificationType.todoReminder;
      }
      return true;
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag indicator
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F4),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      child: const Icon(Icons.notifications_active, color: AppColors.magentaPrimary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'Notifications & Nudges',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (unreadCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$unreadCount New',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Birthdays, Special Days & Management Notices',
                            style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action Buttons Row: "Mark as Read" & "Clear all read alerts"
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          eco.markAllNotificationsAsRead();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All notifications marked as read'),
                              duration: Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.done_all_rounded, size: 15, color: AppColors.magentaPrimary),
                        label: const Text(
                          'Mark as Read',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.magentaPrimary),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          side: BorderSide(color: AppColors.magentaPrimary.withOpacity(0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: const Color(0xFFFFF1F4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          eco.clearAllReadNotifications();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All read alerts cleared for your account'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: Color(0xFF64748B)),
                        label: const Text(
                          'Clear all read alerts',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          backgroundColor: const Color(0xFFF8FAFC),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFFF1F5F9), height: 1),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _filterChip('all', 'All (${validNotifs.length})', Icons.layers_outlined),
                const SizedBox(width: 6),
                _filterChip('teamAlerts', 'Team & Orders', Icons.notifications_none_rounded),
                const SizedBox(width: 6),
                _filterChip('broadcastNotice', 'Notices', Icons.campaign_outlined),
                const SizedBox(width: 6),
                _filterChip('todoReminder', 'To-Do Reminders', Icons.history_rounded),
                const SizedBox(width: 6),
                _filterChip('birthday', 'Celebrations', Icons.cake_outlined),
                const SizedBox(width: 6),
                _filterChip('socialCause', 'Social Causes', Icons.volunteer_activism_outlined),
              ],
            ),
          ),
          const Divider(color: AppColors.sandBorder, height: 1),

          // Overdue Orders Alert Banner
          if (eco.overdueOnlineOrders.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OnlineOrdersHandlerScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.ragRed.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.ragRed, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.ragRed, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${eco.overdueOnlineOrders.length} Online Order(s) overdue SLA. Tap to resolve.',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // Notification List
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.notifications_off_outlined, size: 40, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'No notifications in this category',
                          style: TextStyle(color: AppColors.sandLight, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'You are all caught up on MN Jewel Park announcements!',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notif = filtered[index];
                      return _buildNotificationCard(context, eco, notif);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String key, String label, IconData icon) {
    final isSelected = _selectedFilter == key;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = key),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.magentaPrimary : AppColors.pureWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.magentaPrimary : AppColors.sandBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : AppColors.sandLight,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.sandLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, EcosystemProvider eco, CompanyNotification notif) {
    final timeStr = _formatTimeAgo(notif.timestamp);
    final isRead = notif.isReadBy(eco.activeEmpId);

    return InkWell(
      onTap: () {
        if (!isRead) eco.markNotificationAsRead(notif.id);
        final title = notif.title.toLowerCase();
        final content = notif.content.toLowerCase();
        if (notif.type == CompanyNotificationType.socialCause ||
            notif.actionTag?.startsWith('CAUSE-') == true ||
            notif.id.contains('SC-') ||
            title.contains('social') ||
            content.contains('social')) {
          SocialCauseDetailDialog.show(
            context,
            notification: notif,
            causeId: notif.actionTag,
          );
          return;
        }
        _showNotificationDetailDialog(context, eco, notif);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.pureWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead ? const Color(0xFFE2E8F0) : notif.color.withOpacity(0.55),
            width: isRead ? 1.0 : 1.3,
          ),
          boxShadow: isRead
              ? [
                  const BoxShadow(
                    color: Color(0x060F172A),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: notif.color.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: notif.color.withOpacity(0.14),
                shape: BoxShape.circle,
                border: Border.all(color: notif.color.withOpacity(0.4)),
              ),
              child: Icon(notif.icon, color: notif.color, size: 20),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: notif.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          notif.categoryLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: notif.color,
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeStr,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(width: 8),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: notif.color,
                              ),
                            )
                          else
                            const Icon(
                              Icons.done_all_rounded,
                              size: 15,
                              color: Color(0xFF94A3B8),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notif.title
                        .replaceAll('Dr. K. Senthil Nathan', 'M N Naveenraaj')
                        .replaceAll('Senthil Nathan', 'M N Naveenraaj')
                        .replaceAll('Senthil', 'M N Naveenraaj'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (notif.content.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notif.content
                          .replaceAll('Dr. K. Senthil Nathan', 'M N Naveenraaj')
                          .replaceAll('Senthil Nathan', 'M N Naveenraaj')
                          .replaceAll('Senthil', 'M N Naveenraaj')
                          .replaceAll('CEO & Founder', 'Managing Director & CEO'),
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), height: 1.35),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_pin, size: 12, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'From: ${notif.senderName.toLowerCase().contains("senthil") || notif.senderName.toLowerCase().contains("executive ceo") ? "M N Naveenraaj" : notif.senderName} (${notif.senderRole.toLowerCase().contains("founder") || notif.senderName.toLowerCase().contains("senthil") ? "Managing Director & CEO" : notif.senderRole})',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Like Button
                        InkWell(
                          onTap: () {
                            final targetId = notif.actionTag ?? notif.id;
                            eco.toggleSocialCauseReaction(targetId, reactingEmpId: eco.activeEmpId);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: notif.isLikedBy(eco.activeEmpId)
                                  ? const Color(0xFFEF4444).withOpacity(0.18)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: notif.isLikedBy(eco.activeEmpId)
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFFE2E8F0),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  notif.isLikedBy(eco.activeEmpId) ? Icons.favorite : Icons.favorite_border,
                                  size: 13,
                                  color: notif.isLikedBy(eco.activeEmpId) ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${notif.likesCount}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: notif.isLikedBy(eco.activeEmpId) ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Comments Button
                        InkWell(
                          onTap: () {
                            NotificationCommentsSheet.show(context, notif);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: notif.commentsCount > 0
                                  ? const Color(0xFFF43F5E).withOpacity(0.12)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: notif.commentsCount > 0
                                    ? const Color(0xFFF43F5E).withOpacity(0.4)
                                    : const Color(0xFFE2E8F0),
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.mode_comment_outlined,
                                  size: 12.5,
                                  color: notif.commentsCount > 0 ? const Color(0xFFBE185D) : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  notif.commentsCount > 0 ? '${notif.commentsCount}' : 'Comment',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: notif.commentsCount > 0 ? const Color(0xFFBE185D) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (notif.isCeoReacted) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.stars_rounded, size: 12, color: Color(0xFFD97706)),
                                SizedBox(width: 3),
                                Text(
                                  'CEO Reacted!',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (notif.type == CompanyNotificationType.socialCause || notif.actionTag?.startsWith('CAUSE-') == true)
                          const Text(
                            'Tap to view deed',
                            style: TextStyle(fontSize: 11.5, color: AppColors.sandGold, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  if (notif.actionTag == 'ATTENDANCE' || notif.actionTag == 'ATTENDANCE_UPDATE' || notif.title.toLowerCase().contains('attendance')) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AttendancePillarScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD97706).withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.fingerprint_rounded, size: 13, color: Color(0xFFD97706)),
                                SizedBox(width: 4),
                                Text(
                                  'Open Attendance',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  void _showNotificationDetailDialog(BuildContext context, EcosystemProvider eco, CompanyNotification notif) {
    final title = notif.title
        .replaceAll('Dr. K. Senthil Nathan', 'M N Naveenraaj')
        .replaceAll('Senthil Nathan', 'M N Naveenraaj')
        .replaceAll('Senthil', 'M N Naveenraaj');
    final content = notif.content
        .replaceAll('Dr. K. Senthil Nathan', 'M N Naveenraaj')
        .replaceAll('Senthil Nathan', 'M N Naveenraaj')
        .replaceAll('Senthil', 'M N Naveenraaj')
        .replaceAll('CEO & Founder', 'Managing Director & CEO');
    final formattedDate = DateFormat('dd MMMM yyyy, hh:mm a').format(notif.timestamp);

    final isOrderRelated = title.toLowerCase().contains('order') || content.toLowerCase().contains('order');
    final isAttendanceRelated = notif.actionTag == 'ATTENDANCE' ||
        notif.actionTag == 'ATTENDANCE_UPDATE' ||
        title.toLowerCase().contains('attendance') ||
        content.toLowerCase().contains('attendance');

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Category & Close
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: notif.color.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: notif.color.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(notif.icon, size: 13, color: notif.color),
                          const SizedBox(width: 5),
                          Text(
                            notif.categoryLabel,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: notif.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),

                // Timestamp
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 12),

                // Content body
                Flexible(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Text(
                        content.isNotEmpty ? content : 'No additional details provided.',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF334155),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Sender attribution
                Row(
                  children: [
                    const Icon(Icons.person_pin, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'From: ${notif.senderName.toLowerCase().contains("senthil") || notif.senderName.toLowerCase().contains("executive ceo") ? "M N Naveenraaj" : notif.senderName} (${notif.senderRole.toLowerCase().contains("founder") || notif.senderName.toLowerCase().contains("senthil") ? "Managing Director & CEO" : notif.senderRole})',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 12),

                // Dialog Buttons
                // Wrap (not Row) so buttons move to a second line on narrow
                // screens instead of pushing "Close" off the edge.
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (isAttendanceRelated) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pop(context); // close sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AttendancePillarScreen()),
                          );
                        },
                        icon: const Icon(Icons.fingerprint_rounded, size: 15, color: Colors.white),
                        label: const Text('Attendance', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.magentaPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                    ],
                    if (isOrderRelated) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.pop(context); // close sheet
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const OnlineOrdersHandlerScreen()),
                          );
                        },
                        icon: const Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.white),
                        label: const Text('View Orders', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE11D48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        NotificationCommentsSheet.show(context, notif);
                      },
                      icon: const Icon(Icons.mode_comment_outlined, size: 14, color: Color(0xFFBE185D)),
                      label: Text(
                        notif.commentsCount > 0
                            ? 'Comments (${notif.commentsCount})'
                            : 'Comments',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFFBE185D), fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: const BorderSide(color: Color(0xFFFECDD3)),
                        backgroundColor: const Color(0xFFFFF1F4),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Close', style: TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.bold)),
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
  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
