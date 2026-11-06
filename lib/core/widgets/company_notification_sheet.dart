import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../../providers/ecosystem_provider.dart';
import '../../models/company_notification_models.dart';
import '../../views/orders/online_orders_handler_screen.dart';

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
    final notifications = eco.companyNotifications;
    final unreadCount = eco.unreadNotificationCount;

    final filtered = notifications.where((n) {
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
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppColors.burgundyBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: AppColors.sandGold.withOpacity(0.4),
          width: 1.2,
        ),
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
                color: AppColors.sandBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sandGold.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.sandGold.withOpacity(0.3), width: 1),
                  ),
                  child: const Icon(Icons.notifications_active, color: AppColors.sandGold, size: 20),
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
                              style: GoogleFonts.cinzel(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.sandLight,
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
                                  fontSize: 9,
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
                        style: TextStyle(fontSize: 10, color: AppColors.textMuted),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => eco.markAllNotificationsAsRead(),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.sandGold.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.sandGold.withOpacity(0.4), width: 0.8),
                      ),
                      child: const Text(
                        'Mark All Read',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.sandGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: AppColors.sandBorder, height: 1),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _filterChip('all', 'All (${notifications.length})', FontAwesomeIcons.layerGroup),
                const SizedBox(width: 6),
                _filterChip('teamAlerts', 'Team & Orders', FontAwesomeIcons.bell),
                const SizedBox(width: 6),
                _filterChip('broadcastNotice', 'Notices', FontAwesomeIcons.bullhorn),
                const SizedBox(width: 6),
                _filterChip('todoReminder', 'To-Do Reminders', FontAwesomeIcons.clockRotateLeft),
                const SizedBox(width: 6),
                _filterChip('birthday', 'Celebrations', FontAwesomeIcons.cakeCandles),
                const SizedBox(width: 6),
                _filterChip('socialCause', 'Social Causes', FontAwesomeIcons.handHoldingHeart),
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
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white70),
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
          color: isSelected ? AppColors.sandGold : AppColors.burgundyCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.sandGold : AppColors.sandBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppColors.burgundyBg : AppColors.sandLight,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.burgundyBg : AppColors.sandLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, EcosystemProvider eco, CompanyNotification notif) {
    final timeStr = _formatTimeAgo(notif.timestamp);

    return InkWell(
      onTap: () {
        if (!notif.isRead) eco.markNotificationAsRead(notif.id);
        final title = notif.title.toLowerCase();
        final content = notif.content.toLowerCase();
        if (title.contains('order') || content.contains('order') || title.contains('reassign') || content.contains('reassign')) {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OnlineOrdersHandlerScreen()),
          );
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notif.isRead ? AppColors.burgundyCard : AppColors.burgundyCard.withOpacity(0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead ? AppColors.sandBorder : notif.color.withOpacity(0.6),
            width: notif.isRead ? 1.0 : 1.4,
          ),
          boxShadow: notif.isRead
              ? null
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
                color: notif.color.withOpacity(0.18),
                shape: BoxShape.circle,
                border: Border.all(color: notif.color.withOpacity(0.5)),
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
                          color: notif.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          notif.categoryLabel,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: notif.color,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            timeStr,
                            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                          ),
                          if (!notif.isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: notif.color,
                              ),
                            ),
                          ],
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
                      fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                      color: AppColors.sandLight,
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
                      style: const TextStyle(fontSize: 11, color: AppColors.sandLight, height: 1.3),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person_pin, size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        'From: ${notif.senderName.toLowerCase().contains("senthil") || notif.senderName.toLowerCase().contains("executive ceo") ? "M N Naveenraaj" : notif.senderName} (${notif.senderRole.toLowerCase().contains("founder") || notif.senderName.toLowerCase().contains("senthil") ? "Managing Director & CEO" : notif.senderRole})',
                        style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
