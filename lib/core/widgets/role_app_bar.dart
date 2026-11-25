import 'mn_brand_logo.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import 'company_notification_sheet.dart';
import 'logout_confirm_dialog.dart';
import '../../views/auth/pillars_popup_dialog.dart';
import '../../views/auth/login_screen.dart';
import '../../providers/ecosystem_provider.dart';
import '../../views/pillars/profile_pillar_screen.dart';
import '../../views/chat/chat_hub_screen.dart';
import '../../views/ceo/admin_role_access_management_screen.dart';
import '../../views/media/creative_media_review_board_screen.dart';

class RoleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String roleName;
  final String userName;
  final Color roleColor;
  final IconData roleIcon;
  final VoidCallback? onRoleSwitch;
  final VoidCallback? onBellPressed;
  final VoidCallback? onExportPressed;
  final VoidCallback? onPillarsPressed;
  final VoidCallback? onRefreshPressed;
  final bool? showBackButton;

  const RoleAppBar({
    super.key,
    required this.roleName,
    required this.userName,
    required this.roleColor,
    required this.roleIcon,
    this.onRoleSwitch,
    this.onBellPressed,
    this.onExportPressed,
    this.onPillarsPressed,
    this.onRefreshPressed,
    this.showBackButton,
  });

  void _handleSwitchRole(BuildContext context) {
    if (onRoleSwitch != null) {
      onRoleSwitch!();
    } else {
      EcosystemProvider? eco;
      try {
        eco = Provider.of<EcosystemProvider>(context, listen: false);
      } catch (_) {}
      Widget target = const LoginScreen(isSwitchAccount: true);
      if (eco != null) {
        target = ChangeNotifierProvider<EcosystemProvider>.value(
          value: eco,
          child: target,
        );
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => target),
      );
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(96);

  Widget _glassButton({
    required Key key,
    required IconData icon,
    required VoidCallback onTap,
    int badge = 0,
    bool dotOnly = false,
  }) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Material(
            color: const Color(0x1FFFFFFF),
            shape: const CircleBorder(side: BorderSide(color: Color(0x26FFFFFF))),
            child: InkWell(
              key: key,
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(icon, size: 20, color: Colors.white),
              ),
            ),
          ),
          if (badge > 0)
            Positioned(
              top: -2,
              right: -2,
              child: dotOnly
                  ? Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.heroAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.indigoDeep, width: 1.5),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                      decoration: BoxDecoration(
                        color: AppColors.heroAccent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.indigoDeep, width: 1.5),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.midnight,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = showBackButton ?? Navigator.canPop(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        boxShadow: [
          BoxShadow(color: Color(0x292A0F22), blurRadius: 18, offset: Offset(0, 6)),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Signed-in user + switch role
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: roleName == 'Profile'
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ProfilePillarScreen()),
                              );
                            },
                      child: Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.heroAccent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFFD6E5),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _handleSwitchRole(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0x1FFFFFFF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x40FFD6E5), width: 0.8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_horiz_rounded, size: 12, color: AppColors.heroAccent),
                          SizedBox(width: 4),
                          Text(
                            'Switch Role',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Brand + actions
              Row(
                children: [
                  if (canGoBack) ...[
                    _glassButton(
                      key: const ValueKey('role_app_bar_back_button'),
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.maybePop(context),
                    ),
                    const SizedBox(width: 10),
                  ],
                  const MnBrandLogo(size: 44),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'MN JEWEL PARK',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          roleName.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 10.5,
                            letterSpacing: 1.2,
                            color: AppColors.heroAccent,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  Consumer<EcosystemProvider>(
                    builder: (context, eco, _) => _glassButton(
                      key: const ValueKey('role_app_bar_notification_button'),
                      icon: Icons.notifications_none_rounded,
                      badge: eco.unreadNotificationCount,
                      onTap: () {
                        if (onBellPressed != null) {
                          onBellPressed!();
                        } else {
                          CompanyNotificationSheet.show(context);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Consumer<EcosystemProvider>(
                    builder: (context, eco, _) => _glassButton(
                      key: const ValueKey('role_app_bar_hamburger'),
                      icon: Icons.menu_rounded,
                      badge: eco.unreadNotificationCount,
                      dotOnly: true,
                      onTap: () => _openMenuSheet(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openMenuSheet(BuildContext context) {
    EcosystemProvider? eco;
    try {
      eco = Provider.of<EcosystemProvider>(context, listen: false);
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final content = Container(
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AppColors.sandBorder,
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A991B45),
                blurRadius: 24,
                offset: Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // Top drag handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.sandBorder.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // User Identity Header with Close Button
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ProfilePillarScreen()),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: roleColor.withOpacity(0.18),
                                border: Border.all(color: roleColor.withOpacity(0.5), width: 1),
                              ),
                              child: Icon(roleIcon, size: 18, color: roleColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.sandLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    roleName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.sandGold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.sandPrimary, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.sandBorder, height: 1),
                const SizedBox(height: 10),

                // Creative & Media Review Board (DAM Pipeline)
                Consumer<EcosystemProvider>(
                  builder: (context, eco, _) {
                    final pendingMedia = eco.pendingMediaApprovalsCount;
                    return _menuItemTile(
                      icon: Icons.video_collection_outlined,
                      iconColor: const Color(0xFFD97706),
                      title: 'Media Review Board',
                      subtitle: 'Reels, photoshoots & social sign-off',
                      badgeText: pendingMedia > 0 ? '$pendingMedia' : 'DAM',
                      badgeColor: pendingMedia > 0
                          ? const Color(0xFFD97706)
                          : const Color(0xFF475569),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const CreativeMediaReviewBoardScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),

                // Team Chat Hub
                Consumer<EcosystemProvider>(
                  builder: (context, eco, _) {
                    final unreadChats = eco.unreadTotalChatCount;
                    return _menuItemTile(
                      icon: Icons.chat_bubble_outline_rounded,
                      iconColor: const Color(0xFFF43F5E),
                      title: 'MN Team Chat',
                      subtitle: unreadChats > 0
                          ? '$unreadChats unread messages'
                          : 'Direct & All-Hands team messaging',
                      badgeText: unreadChats > 0 ? '$unreadChats' : null,
                      badgeColor: const Color(0xFFF43F5E),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChatHubScreen()),
                        );
                      },
                    );
                  },
                ),

                // 1. Notification Hub
                Consumer<EcosystemProvider>(
                  builder: (context, eco, _) {
                    final unread = eco.unreadNotificationCount;
                    return _menuItemTile(
                      icon: Icons.notifications_none_rounded,
                      iconColor: AppColors.sandGold,
                      title: 'Notifications',
                      subtitle: unread > 0 ? '$unread unread alerts' : 'Company announcements & directives',
                      badgeText: unread > 0 ? '$unread' : null,
                      badgeColor: const Color(0xFFEF4444),
                      onTap: () {
                        Navigator.pop(ctx);
                        if (onBellPressed != null) {
                          onBellPressed!();
                        } else {
                          CompanyNotificationSheet.show(context);
                        }
                      },
                    );
                  },
                ),

                // 2. Refresh App
                _menuItemTile(
                  icon: Icons.sync_rounded,
                  iconColor: const Color(0xFF38BDF8),
                  title: 'Refresh App',
                  subtitle: 'Sync live punches, orders & data',
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (onRefreshPressed != null) {
                      onRefreshPressed!();
                    } else {
                      final eco = Provider.of<EcosystemProvider>(context, listen: false);
                      await eco.refreshAllData();
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 2),
                          backgroundColor: const Color(0xFF1E293B),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 16),
                              SizedBox(width: 8),
                              Text('App refreshed successfully', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),

                // 3. MN Family Pillars
                _menuItemTile(
                  icon: Icons.inventory_2_outlined,
                  iconColor: const Color(0xFFFA8BB0),
                  title: 'MN Family Pillars',
                  subtitle: 'Health, Family, Profile, Attendance & Social',
                  onTap: () {
                    Navigator.pop(ctx);
                    if (onPillarsPressed != null) {
                      onPillarsPressed!();
                    } else {
                      PillarsPopupDialog.show(context);
                    }
                  },
                ),

                // 4. Export Audit Report (if available for role)
                if (onExportPressed != null)
                  _menuItemTile(
                    icon: Icons.download_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'Export Audit Report',
                    subtitle: 'Download complete CSV ledger',
                    tooltip: 'Export CSV Audit',
                    onTap: () {
                      Navigator.pop(ctx);
                      onExportPressed!();
                    },
                  ),

                // Role & Access Management (RBAC Admin)
                Consumer<EcosystemProvider>(
                  builder: (context, eco, _) {
                    if (!eco.currentEmployee.canManageRoles && !eco.isCeo) {
                      return const SizedBox.shrink();
                    }
                    return _menuItemTile(
                      icon: Icons.admin_panel_settings_outlined,
                      iconColor: AppColors.sandGold,
                      title: 'Role & Access Control',
                      subtitle: 'Manage RBAC permissions & role assignments',
                      badgeText: 'RBAC',
                      badgeColor: AppColors.sandGold,
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminRoleAccessManagementScreen(),
                          ),
                        );
                      },
                    );
                  },
                ),

                // 5. Switch Role
                _menuItemTile(
                  icon: Icons.swap_horiz_rounded,
                  iconColor: AppColors.sandPrimary,
                  title: 'Switch Role',
                  subtitle: 'Change to another executive or staff profile',
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleSwitchRole(context);
                  },
                ),

                const SizedBox(height: 8),
                const Divider(color: AppColors.sandBorder, height: 1),
                const SizedBox(height: 8),

                // 6. Logout Button
                _menuItemTile(
                  icon: Icons.logout_rounded,
                  iconColor: const Color(0xFFEF4444),
                  title: 'Logout',
                  subtitle: 'End session and exit application',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    LogoutConfirmDialog.show(context);
                  },
                ),
              ],
            ),
          ),
        ),
      );

      if (eco != null) {
        return ChangeNotifierProvider<EcosystemProvider>.value(
          value: eco,
          child: content,
        );
      }
      return content;
    },
  );
  }

  Widget _menuItemTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badgeText,
    Color? badgeColor,
    String? tooltip,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Tooltip(
        message: tooltip ?? title,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDestructive
                          ? const Color(0xFFEF4444).withOpacity(0.12)
                          : AppColors.magentaSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDestructive
                            ? const Color(0xFFEF4444).withOpacity(0.35)
                            : AppColors.sandBorder,
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 16,
                        color: isDestructive ? const Color(0xFFEF4444) : iconColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: GoogleFonts.outfit(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDestructive ? const Color(0xFFEF4444) : AppColors.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (badgeText != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: badgeColor ?? const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  badgeText,
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
                        Text(
                          subtitle,
                          style: GoogleFonts.outfit(
                            fontSize: 11.5,
                            color: isDestructive ? AppColors.ragRed : AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: isDestructive
                        ? const Color(0xFFEF4444).withOpacity(0.6)
                        : AppColors.textMuted.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
