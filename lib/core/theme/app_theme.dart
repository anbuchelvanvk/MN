import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App-wide look ("Midnight & Gold"): cool pearl canvas, midnight-indigo
/// structure, royal-indigo actions and champagne-gold highlights. Screens that use default Material widgets (buttons,
/// fields, dialogs, sheets, snack bars, chips, list tiles) pick this up
/// automatically.
class AppThemes {
  static ThemeData get whiteMagentaTheme {
    const primary = AppColors.magentaPrimary;
    const ink = AppColors.textDark;

    final base = GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme)
        .apply(bodyColor: AppColors.textPrimary, displayColor: ink);

    final textTheme = base.copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        color: ink, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      displayMedium: GoogleFonts.plusJakartaSans(
        color: primary, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
      headlineSmall: GoogleFonts.plusJakartaSans(
        color: ink, fontSize: 20, fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.plusJakartaSans(
        color: ink, fontSize: 18, fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.plusJakartaSans(
        color: ink, fontSize: 15.5, fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.plusJakartaSans(
        color: ink, fontSize: 13.5, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.plusJakartaSans(
        color: AppColors.textPrimary, fontSize: 15, height: 1.45),
      bodyMedium: GoogleFonts.plusJakartaSans(
        color: AppColors.textSecondary, fontSize: 13.5, height: 1.45),
      bodySmall: GoogleFonts.plusJakartaSans(
        color: AppColors.textMuted, fontSize: 12, height: 1.4),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.2),
    );

    final rounded14 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    const pill = StadiumBorder();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.whiteBg,
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: primary,
        onPrimary: Colors.white,
        secondary: AppColors.sandGold,
        onSecondary: Colors.white,
        tertiary: AppColors.magentaDeep,
        surface: AppColors.pureWhite,
        onSurface: ink,
        surfaceTint: Colors.transparent,
        outline: const Color(0xFFE2E5F0),
        outlineVariant: AppColors.sandBorder,
        error: AppColors.ragRed,
      ),
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,

      cardTheme: CardThemeData(
        color: AppColors.pureWhite,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x1414123A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.line, width: 1),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.pureWhite,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: const Color(0x1A1E1B4B),
        centerTitle: false,
        iconTheme: const IconThemeData(color: ink),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: ink,
          letterSpacing: 0.2,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: const Color(0x334338CA),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: pill,
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: pill,
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: Color(0xFFC7CBEA), width: 1.2),
          shape: pill,
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          shape: rounded14,
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: primary),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: StadiumBorder(),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.textMuted, fontSize: 14),
        labelStyle: GoogleFonts.plusJakartaSans(color: AppColors.textSecondary, fontSize: 14),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(color: primary, fontWeight: FontWeight.w600),
        prefixIconColor: primary,
        suffixIconColor: AppColors.textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE6E8F2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.ragRed),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.pureWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shadowColor: const Color(0x2914123A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: ink),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14, color: AppColors.textSecondary, height: 1.45),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.pureWhite,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.midnight,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13.5),
        actionTextColor: AppColors.goldBright,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: primary,
        checkmarkColor: Colors.white,
        side: const BorderSide(color: AppColors.line),
        shape: const StadiumBorder(),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: ink),
        secondaryLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primary,
        textColor: ink,
        shape: rounded14,
        titleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w600, color: ink),
        subtitleTextStyle: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.textMuted),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.sandBorder, thickness: 1, space: 1),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: AppColors.line,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w500),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : const Color(0xFFB9BCD3)),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : const Color(0xFFE6E8F2)),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : Colors.transparent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: Color(0xFFE6E8F2),
        circularTrackColor: Color(0xFFE6E8F2),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySoft,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: ink),
        ),
      ),
      badgeTheme: const BadgeThemeData(backgroundColor: AppColors.ragRed),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  // Alias for backward compatibility
  static ThemeData get burgundySandTheme => whiteMagentaTheme;
}
