import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppThemes {
  static ThemeData get burgundySandTheme {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.dark().textTheme,
    ).copyWith(
      displayLarge: GoogleFonts.cinzel(
        color: AppColors.sandLight,
        fontSize: 26,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      displayMedium: GoogleFonts.cinzel(
        color: AppColors.sandPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        color: AppColors.textLight,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        color: AppColors.sandPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        color: AppColors.textLight,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        color: AppColors.textMuted,
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
      ),
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.burgundyBg,
      primaryColor: AppColors.burgundyPrimary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.sandPrimary,
        secondary: AppColors.burgundyPrimary,
        surface: AppColors.burgundySurface,
        error: AppColors.ragRed,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AppColors.burgundyGlass,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.sandBorder, width: 1.2),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.sandPrimary),
        titleTextStyle: GoogleFonts.cinzel(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.sandLight,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
