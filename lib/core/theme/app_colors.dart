import 'package:flutter/material.dart';

class AppColors {
  // --- Modern Luxury White & Magenta Canvas & Backgrounds ---
  static const Color whiteBg = Color(0xFFFBF8FA);          // Luminous soft white canvas
  static const Color pureWhite = Color(0xFFFFFFFF);        // Crisp pure white
  static const Color cardWhite = Color(0xFFFFFFFF);        // Pure white card
  static const Color backgroundWhite = Color(0xFFFBF8FA);  // Canvas background
  static const Color surfaceWhite = Color(0xFFFFFFFF);     // Card & dialog surface
  static const Color glassWhite = Color(0xF5FFFFFF);       // Translucent white frosted glass
  static const Color glassCard = Color(0xF2FFFFFF);        // Translucent card glass

  // --- Signature Luxury Magenta Accents ---
  static const Color magentaPrimary = Color(0xFFE11D48);   // Vibrant executive Rose-Magenta (#E11D48)
  static const Color magentaDark = Color(0xFF9F1239);      // Deep executive magenta (#9F1239)
  static const Color magentaDeep = Color(0xFF881337);      // Deepest magenta (#881337)
  static const Color magentaLight = Color(0xFFFB7185);     // Soft rose pink (#FB7185)
  static const Color magentaAccent = Color(0xFFD946EF);    // Radiant electric orchid (#D946EF)
  static const Color magentaSubtle = Color(0xFFFFF1F4);    // Soft pastel blush wash
  static const Color magentaBorder = Color(0x33E11D48);    // Faint magenta border
  static const Color magentaHighlight = Color(0x1FE11D48); // Item selection wash

  // --- Backward Compatibility Aliases (Burgundy -> Modern White & Magenta) ---
  static const Color burgundyBg = Color(0xFFFBF8FA);       // Soft luminous white canvas
  static const Color burgundySurface = Color(0xFFFFFFFF);  // Crisp pure white surface
  static const Color cardSurface = Color(0xFFFFFFFF);      // Crisp pure white card surface
  static const Color burgundyGlass = Color(0xF8FFFFFF);    // Frosted white glass
  static const Color burgundyCard = Color(0xFFFFFFFF);     // Crisp pure white card
  static const Color burgundyAccent = Color(0xFFE11D48);   // Vibrant signature magenta
  static const Color burgundySubtle = Color(0xFFFFF1F4);   // Soft blush wash
  static const Color burgundyPrimary = Color(0xFFE11D48);  // Vibrant signature magenta
  static const Color burgundyLight = Color(0xFFFB7185);    // Soft rose
  static const Color burgundyDark = Color(0xFF9F1239);     // Deep magenta

  // --- Signature Sand & Gold Mapped to Magenta & Slate Palette ---
  static const Color sandPrimary = Color(0xFFE11D48);      // Signature vibrant magenta accent
  static const Color sandLight = Color(0xFF1F1530);        // Deep slate charcoal for headers on white canvas
  static const Color sandGold = Color(0xFFBE185D);         // Rich magenta-rose
  static const Color sandDark = Color(0xFF9F1239);         // Deep magenta
  static const Color sandBorder = Color(0xFFF1E4EB);       // Clean neutral hairline border
  static const Color sandHighlight = Color(0xFFFFF1F4);    // Soft blush wash

  // --- Backward-compatible Gold Aliases ---
  static const Color goldPrimary = Color(0xFFE11D48);
  static const Color goldLight = Color(0xFF1F1530);
  static const Color goldBright = Color(0xFFBE185D);
  static const Color goldDark = Color(0xFF9F1239);
  static const Color goldSand = Color(0xFFE11D48);

  // --- High-Contrast Crisp Typography on White/Light Canvas ---
  static const Color textDark = Color(0xFF1F1530);         // Deep slate charcoal (headers, prominent text)
  static const Color textPrimary = Color(0xFF2E2440);      // Primary body slate
  static const Color textSecondary = Color(0xFF5B5068);    // Secondary subtext slate
  static const Color textLight = Color(0xFF1F1530);        // Mapped to dark slate on light cards
  static const Color textWhite = Color(0xFFFFFFFF);        // White text on magenta buttons/badges
  static const Color textSand = Color(0xFFBE185D);         // Rich magenta accent text
  static const Color textBurgundy = Color(0xFFE11D48);     // Vibrant magenta text
  static const Color textMuted = Color(0xFF756A80);        // Crisp muted slate for hints and timestamps
  static const Color textMagenta = Color(0xFFBE123C);      // Bold magenta text

  // --- Status & Traffic RAG (Refined with pastel backgrounds) ---
  static const Color ragGreen = Color(0xFF059669);
  static const Color ragGreenBg = Color(0xFFECFDF5);
  static const Color ragYellow = Color(0xFFD97706);
  static const Color ragYellowBg = Color(0xFFFFFBEB);
  static const Color ragRed = Color(0xFFE11D48);           // High-contrast vivid magenta-red
  static const Color ragRedBg = Color(0xFFFFF1F2);
  static const Color statusBlue = Color(0xFF2563EB);
  static const Color statusPurple = Color(0xFF9333EA);

  // --- Modern White & Magenta Luxury Gradients ---
  static const LinearGradient magentaGradient = LinearGradient(
    colors: [Color(0xFFE11D48), Color(0xFFBE185D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient burgundyGradient = LinearGradient(
    colors: [Color(0xFFE11D48), Color(0xFFBE185D), Color(0xFFA21CAF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sandGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFFF1F4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFBE185D), Color(0xFF881337)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFFF7FA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient liquidShine = LinearGradient(
    colors: [
      Color(0x1FE11D48),
      Color(0x0AE11D48),
      Color(0x00FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomCenter,
  );
}
