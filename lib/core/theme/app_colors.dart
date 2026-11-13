import 'package:flutter/material.dart';

class AppColors {
  // --- Signature Luxury Imperial Burgundy & Champagne Sandel Canvas ---
  static const Color whiteBg = Color(0xFFFAF5F0);          // Warm Champagne Sandel canvas
  static const Color pureWhite = Color(0xFFFFFFFF);        // Crisp pure white card surface
  static const Color cardWhite = Color(0xFFFFFFFF);        // Pure white card
  static const Color backgroundWhite = Color(0xFFFAF5F0);  // Sandel background canvas
  static const Color surfaceWhite = Color(0xFFFFFFFF);     // Card surface
  static const Color glassWhite = Color(0xF8FFFFFF);       // Translucent frosted glass
  static const Color glassCard = Color(0xF2FFFFFF);        // Translucent card glass

  // --- Signature Imperial Burgundy Palette ---
  static const Color burgundyPrimary = Color(0xFF620013);  // Deep Royal Wine / Imperial Burgundy (#620013)
  static const Color burgundyDark = Color(0xFF450510);     // Dark Burgundy (#450510)
  static const Color burgundyDeep = Color(0xFF3A030C);     // Deepest Velvet Burgundy
  static const Color burgundyLight = Color(0xFF871429);    // Wine Burgundy
  static const Color burgundyAccent = Color(0xFF620013);   // Signature Burgundy Accent
  static const Color burgundySubtle = Color(0xFFF8F1EA);   // Warm Sandel Wash
  static const Color burgundyBorder = Color(0x33620013);   // Burgundy border wash
  static const Color burgundyHighlight = Color(0x1A620013);// Item selection wash

  // Aliases for backward compatibility
  static const Color magentaPrimary = burgundyPrimary;
  static const Color magentaDark = burgundyDark;
  static const Color magentaDeep = burgundyDeep;
  static const Color magentaLight = burgundyLight;
  static const Color magentaAccent = Color(0xFF871429);
  static const Color magentaSubtle = burgundySubtle;
  static const Color magentaBorder = burgundyBorder;
  static const Color magentaHighlight = burgundyHighlight;

  static const Color burgundyBg = Color(0xFFFAF5F0);       // Warm Champagne Sandel canvas
  static const Color burgundySurface = Color(0xFFFFFFFF);  // Pure white surface
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color burgundyGlass = Color(0xF8FFFFFF);
  static const Color burgundyCard = Color(0xFFFFFFFF);

  // --- Signature Champagne Sandel & Gold Palette ---
  static const Color sandPrimary = Color(0xFF620013);      // Signature Imperial Burgundy
  static const Color sandLight = Color(0xFF2A050C);        // Deep Espresso Burgundy for headers
  static const Color sandGold = Color(0xFFCBB094);         // Warm Champagne Sandel Accent (#CBB094)
  static const Color sandDark = Color(0xFF8B6B52);         // Rich Sandel
  static const Color sandBorder = Color(0xFFE6D3C2);       // Elegant Sandel border (#E6D3C2)
  static const Color sandHighlight = Color(0xFFF8F1EA);    // Soft Sandel highlight wash

  // Backward-compatible Gold Aliases
  static const Color goldPrimary = Color(0xFF620013);
  static const Color goldLight = Color(0xFF2A050C);
  static const Color goldBright = Color(0xFFCBB094);
  static const Color goldDark = Color(0xFF8B6B52);
  static const Color goldSand = Color(0xFFCBB094);

  // --- High-Contrast Typography ---
  static const Color textDark = Color(0xFF2A050C);         // Deep Espresso Burgundy
  static const Color textPrimary = Color(0xFF2A050C);      // Primary body text
  static const Color textSecondary = Color(0xFF745B54);    // Warm muted sandel charcoal
  static const Color textLight = Color(0xFF2A050C);
  static const Color textWhite = Color(0xFFFFFFFF);        // White text on burgundy buttons/badges
  static const Color textSand = Color(0xFF8B6B52);         // Rich sandel accent text
  static const Color textBurgundy = Color(0xFF620013);     // Imperial Burgundy text
  static const Color textMuted = Color(0xFF745B54);        // Crisp muted warm sandel for hints/dates
  static const Color textMagenta = Color(0xFF620013);

  // --- Status & Traffic RAG (Refined with pastel backgrounds) ---
  static const Color ragGreen = Color(0xFF10B981);
  static const Color ragGreenBg = Color(0xFFECFDF5);
  static const Color ragYellow = Color(0xFFF59E0B);
  static const Color ragYellowBg = Color(0xFFFFFBEB);
  static const Color ragRed = Color(0xFFD32F2F);
  static const Color ragRedBg = Color(0xFFFCE8E6);
  static const Color statusBlue = Color(0xFF2563EB);
  static const Color statusPurple = Color(0xFF8B5CF6);

  // --- Luxury Gradients ---
  static const LinearGradient magentaGradient = LinearGradient(
    colors: [Color(0xFF871429), Color(0xFF620013)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient burgundyGradient = LinearGradient(
    colors: [Color(0xFF871429), Color(0xFF620013), Color(0xFF450510)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sandGradient = LinearGradient(
    colors: [Color(0xFFFAF5F0), Color(0xFFF8F1EA), Color(0xFFE6D3C2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFDECEBE), Color(0xFFCBB094)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFAF7F2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient liquidShine = LinearGradient(
    colors: [
      Color(0x26620013),
      Color(0x0A620013),
      Color(0x00FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomCenter,
  );
}
