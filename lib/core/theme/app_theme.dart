import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppThemes {
  static ThemeData get whiteMagentaTheme {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.light().textTheme,
    ).copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
        color: AppColors.textDark,
        fontSize: 26,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        color: AppColors.magentaPrimary,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        color: AppColors.textDark,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        color: AppColors.magentaPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        color: AppColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        color: AppColors.textSecondary,
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
      ),
    );

    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.whiteBg,
      primaryColor: AppColors.magentaPrimary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.magentaPrimary,
        secondary: AppColors.magentaAccent,
        surface: AppColors.pureWhite,
        error: AppColors.ragRed,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: AppColors.pureWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.sandBorder, width: 1.2),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.pureWhite,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.magentaPrimary),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // Alias for backward compatibility
  static ThemeData get burgundySandTheme => whiteMagentaTheme;
}
