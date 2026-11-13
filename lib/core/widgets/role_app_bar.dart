import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_colors.dart';
import 'company_notification_sheet.dart';
import 'logout_confirm_dialog.dart';
import '../../views/auth/pillars_popup_dialog.dart';
import '../../views/auth/login_screen.dart';
import '../../providers/ecosystem_provider.dart';
import '../../views/employee/employee_profile_screen.dart';

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
  @override
  Size get preferredSize => const Size.fromHeight(84);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFF1F5F9),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Executive Identity & Switch Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3.5),
              color: AppColors.pureWhite,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: roleName == 'Profile'
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
                              );
                            },
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: roleColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              userName,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
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
                    onTap: () => _handleSwitchRole(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.magentaSubtle,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.magentaBorder, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          FaIcon(FontAwesomeIcons.rightLeft, size: 8.5, color: AppColors.magentaPrimary),
                          SizedBox(width: 4),
                          Text(
                            'Switch Role',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.magentaPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Brand and Actions Hub
            Padding(
              padding: const EdgeInsets.only(
                left: 12,
                right: 12,
                top: 2,
                bottom: 6,
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.magentaPrimary.withOpacity(0.5),
                        width: 1.2,
                      ),
                      color: Colors.black,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.magentaPrimary.withOpacity(0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.diamond_outlined,
                          color: AppColors.magentaPrimary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'MN JEWEL PARK',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            letterSpacing: 0.8,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'EXECUTIVE SUITE',
                          style: TextStyle(
                            fontSize: 8.5,
                            letterSpacing: 1.1,
                            color: AppColors.magentaPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),

                  // Hamburger Toggle Button
                  Consumer<EcosystemProvider>(
                    builder: (context, eco, _) {
                      final unread = eco.unreadNotificationCount;
                      return SizedBox(
                        width: 36,
                        height: 36,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                key: const ValueKey('role_app_bar_hamburger'),
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => _openMenuSheet(context),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppColors.pureWhite,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: unread > 0
                                          ? AppColors.ragRed
                                          : AppColors.magentaPrimary.withOpacity(0.35),
                                      width: 1.1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.magentaPrimary.withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.menu_rounded,
                                      size: 20,
                                      color: AppColors.magentaPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (unread > 0)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppColors.ragRed,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.pureWhite, width: 1.2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
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
                color: Color(0x1A991B52),
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
                            MaterialPageRoute(builder: (_) => const EmployeeProfileScreen()),
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
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.sandLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    roleName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
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

                // 1. Notification Hub
                Consumer<EcosystemProvider>(
                  builder: (context, eco, _) {
                    final unread = eco.unreadNotificationCount;
                    return _menuItemTile(
                      icon: FontAwesomeIcons.bell,
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
                  icon: FontAwesomeIcons.arrowsRotate,
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
                  icon: FontAwesomeIcons.cubesStacked,
                  iconColor: const Color(0xFFA78BFA),
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
                    icon: FontAwesomeIcons.fileArrowDown,
                    iconColor: const Color(0xFF10B981),
                    title: 'Export Audit Report',
                    subtitle: 'Download complete CSV ledger',
                    tooltip: 'Export CSV Audit',
                    onTap: () {
                      Navigator.pop(ctx);
                      onExportPressed!();
                    },
                  ),

                // 5. Switch Role
                _menuItemTile(
                  icon: FontAwesomeIcons.rightLeft,
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
                      child: FaIcon(
                        icon,
                        size: 15,
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
                            Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: isDestructive ? const Color(0xFFEF4444) : AppColors.textDark,
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
                                    fontSize: 9.5,
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
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
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
