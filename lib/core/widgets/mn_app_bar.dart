import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// The app's standard page header: a magenta gradient bar with a
/// round back button, a clear title, an optional one-line subtitle and compact
/// actions. Used by every pillar and sub-page so headers look the same.
class MnAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool showBack;
  final PreferredSizeWidget? bottom;

  /// Kept for backwards compatibility; the header always uses the hero gradient.
  final Color background;

  const MnAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.onBack,
    this.showBack = true,
    this.bottom,
    this.background = AppColors.pureWhite,
  });

  double get _barHeight => subtitle == null ? 64 : 72;

  @override
  Size get preferredSize => Size.fromHeight(_barHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final hasBack = showBack && (canPop || onBack != null);
    return AppBar(
      backgroundColor: AppColors.indigoDeep,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      automaticallyImplyLeading: false,
      toolbarHeight: _barHeight,
      bottom: bottom,
      titleSpacing: hasBack ? 4 : 18,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: const DecoratedBox(
        decoration: BoxDecoration(gradient: AppColors.heroGradient),
        child: _HeaderGlow(),
      ),
      leading: hasBack
          ? Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Center(
                child: MnGlassIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  tooltip: 'Back',
                  onTap: onBack ?? () => Navigator.maybePop(context),
                ),
              ),
            )
          : null,
      leadingWidth: hasBack ? 58 : null,
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
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFFFD6E5),
                ),
              ),
            ),
        ],
      ),
      actions: [
        if (actions != null)
          ...actions!.map((a) => IconTheme.merge(
                data: const IconThemeData(color: Colors.white),
                child: a,
              )),
        const SizedBox(width: 10),
      ],
    );
  }
}

/// Soft white glow in the corner of the header for depth.
class _HeaderGlow extends StatelessWidget {
  const _HeaderGlow();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned(
          right: -40,
          top: -60,
          child: SizedBox(
            width: 180,
            height: 180,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x33FFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Round translucent icon button for use on the dark header.
class MnGlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? tooltip;
  final bool dot;
  final double size;
  const MnGlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.onLongPress,
    this.tooltip,
    this.dot = false,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: const Color(0x1FFFFFFF),
      shape: const CircleBorder(side: BorderSide(color: Color(0x26FFFFFF))),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, size: size * 0.48, color: Colors.white),
              if (dot)
                Positioned(
                  top: size * 0.22,
                  right: size * 0.24,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.heroAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.indigoDeep, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip!, child: btn);
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
        color: const Color(0x1FFFFFFF),
        shape: const StadiumBorder(side: BorderSide(color: Color(0x40FFD6E5))),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: AppColors.heroAccent),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
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

/// Section title used inside pages: bold label with an optional trailing action.
class MnSectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const MnSectionTitle(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.midnight,
            ),
          ),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}
