import 'package:flutter/material.dart';

/// MN Family design tokens: white and magenta.
///
/// Crisp white surfaces on a soft blush-white canvas, signature magenta for
/// headers and actions, deep plum ink for text. Older token names (indigo*,
/// midnight, gold*, burgundy*, sand*) are kept as aliases so every screen
/// picks up the palette from here.
class AppColors {
  // --- Core palette ---
  static const Color midnight = Color(0xFF2A0F22);      // Deep plum ink (text, dark accents)
  static const Color indigoDeep = Color(0xFF881337);    // Deep magenta (header gradient start)
  static const Color indigoDark = Color(0xFF9F1239);    // Pressed / dark magenta
  static const Color primary = Color(0xFFE11D48);       // Signature magenta: actions
  static const Color primaryBright = Color(0xFFF43F5E); // Bright magenta
  static const Color violet = Color(0xFFBE185D);        // Secondary magenta-rose
  static const Color gold = Color(0xFFBE185D);          // Accent on white
  static const Color goldDeep = Color(0xFF9D174D);      // Accent text on white
  static const Color goldSoft = Color(0xFFFFF1F4);      // Blush wash
  static const Color heroAccent = Color(0xFFFFD6E5);    // Accent on magenta headers
  static const Color canvas = Color(0xFFFBF8FA);        // App background (soft white)
  static const Color surface = Color(0xFFFFFFFF);       // Cards, sheets
  static const Color surfaceAlt = Color(0xFFFFF7FA);    // Inset panels
  static const Color line = Color(0xFFF1E4EB);          // Hairlines
  static const Color primarySoft = Color(0xFFFFF1F4);   // Magenta wash

  // --- Canvas & surfaces (legacy names) ---
  static const Color whiteBg = canvas;
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color backgroundWhite = canvas;
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color glassWhite = Color(0xF5FFFFFF);
  static const Color glassCard = Color(0xF2FFFFFF);

  // --- Magenta accents ---
  static const Color magentaPrimary = primary;
  static const Color magentaDark = indigoDark;
  static const Color magentaDeep = indigoDeep;
  static const Color magentaLight = Color(0xFFFB7185);
  static const Color magentaAccent = Color(0xFFD946EF);
  static const Color magentaSubtle = primarySoft;
  static const Color magentaBorder = Color(0x33E11D48);
  static const Color magentaHighlight = Color(0x1FE11D48);

  static const Color burgundyBg = canvas;
  static const Color burgundySurface = Color(0xFFFFFFFF);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color burgundyGlass = Color(0xF8FFFFFF);
  static const Color burgundyCard = Color(0xFFFFFFFF);
  static const Color burgundyAccent = primary;
  static const Color burgundySubtle = primarySoft;
  static const Color burgundyPrimary = primary;
  static const Color burgundyLight = Color(0xFFFB7185);
  static const Color burgundyDark = indigoDark;

  static const Color sandPrimary = primary;
  static const Color sandLight = midnight;
  static const Color sandGold = gold;
  static const Color sandDark = indigoDark;
  static const Color sandBorder = line;
  static const Color sandHighlight = goldSoft;

  static const Color goldPrimary = primary;
  static const Color goldLight = midnight;
  static const Color goldBright = Color(0xFFBE185D);
  static const Color goldDark = goldDeep;
  static const Color goldSand = primary;

  // --- Typography ---
  static const Color textDark = Color(0xFF1F1530);
  static const Color textPrimary = Color(0xFF2E2440);
  static const Color textSecondary = Color(0xFF5B5068);
  static const Color textLight = Color(0xFF1F1530);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textSand = goldDeep;
  static const Color textBurgundy = primary;
  static const Color textMuted = Color(0xFF756A80);
  static const Color textMagenta = Color(0xFFBE123C);

  // --- Status ---
  static const Color ragGreen = Color(0xFF059669);
  static const Color ragGreenBg = Color(0xFFECFDF5);
  static const Color ragYellow = Color(0xFFD97706);
  static const Color ragYellowBg = Color(0xFFFFFBEB);
  static const Color ragRed = Color(0xFFDC2626);
  static const Color ragRedBg = Color(0xFFFEF2F2);
  static const Color statusBlue = Color(0xFF2563EB);
  static const Color statusPurple = Color(0xFF9333EA);

  // --- Gradients ---
  /// Signature magenta gradient used by page headers, the home hero and the nav bar.
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF881337), Color(0xFFBE185D), Color(0xFFE11D48)],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE11D48), Color(0xFFBE185D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// White pill / ring used on magenta headers (role chip, selected tab, avatar ring).
  static const LinearGradient goldGradientBright = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFFE4EF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient magentaGradient = primaryGradient;
  static const LinearGradient burgundyGradient = heroGradient;

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
    colors: [Color(0x1FE11D48), Color(0x0AE11D48), Color(0x00FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomCenter,
  );

  /// Soft elevation used by cards across the app.
  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x12881337), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x08881337), blurRadius: 4, offset: Offset(0, 1)),
  ];
}
