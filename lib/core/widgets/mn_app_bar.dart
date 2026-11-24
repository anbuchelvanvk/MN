import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// The app's standard page header: back chevron, clear Title-Case title, an
/// optional one-line subtitle and compact actions. Used by every pillar and
/// sub-page so headers look the same across the app.
class MnAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool showBack;
  final Color background;

  const MnAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.onBack,
    this.showBack = true,
    this.background = AppColors.pureWhite,
  });

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 60 : 66);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.6,
      shadowColor: const Color(0x1F881337),
      automaticallyImplyLeading: false,
      toolbarHeight: preferredSize.height,
      titleSpacing: (showBack && (canPop || onBack != null)) ? 0 : 16,
      leading: (showBack && (canPop || onBack != null))
          ? IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textDark),
              onPressed: onBack ?? () => Navigator.maybePop(context),
            )
          : null,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.2,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
      actions: [
        if (actions != null) ...actions!,
        const SizedBox(width: 8),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, thickness: 1, color: Color(0xFFF3E8EE)),
      ),
    );
  }
}

/// A compact pill used for small header actions/badges (e.g. "Recalibrate").
class MnHeaderPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const MnHeaderPill({super.key, required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: AppColors.magentaSubtle,
        shape: const StadiumBorder(side: BorderSide(color: Color(0xFFF3C6D6))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: AppColors.magentaPrimary),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.magentaPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
