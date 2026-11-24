import 'package:flutter/material.dart';

/// "Midnight & Gold" — the MN Family design tokens.
///
/// Deep midnight-indigo for structure and headers, royal indigo for actions,
/// champagne gold for highlights, on a cool pearl canvas. Older token names
/// (magenta*, burgundy*, sand*, gold*) are kept as aliases so every screen
/// picks up the new palette automatically.
class AppColors {
  // --- Core palette ---
  static const Color midnight = Color(0xFF14123A);      // Deepest ink / hero base
  static const Color indigoDeep = Color(0xFF1E1B4B);    // Hero gradient start
  static const Color indigoDark = Color(0xFF312E81);    // Pressed / dark accents
  static const Color primary = Color(0xFF4338CA);       // Royal indigo — actions
  static const Color primaryBright = Color(0xFF6366F1); // Bright indigo
  static const Color violet = Color(0xFF7C3AED);        // Secondary accent
  static const Color gold = Color(0xFFC9A24B);          // Champagne gold highlight
  static const Color goldDeep = Color(0xFF9A7322);      // Gold text on light
  static const Color goldSoft = Color(0xFFFBF3DD);      // Gold wash
  static const Color canvas = Color(0xFFF4F5FA);        // App background
  static const Color surface = Color(0xFFFFFFFF);       // Cards, sheets
  static const Color surfaceAlt = Color(0xFFF8F9FD);    // Inset panels
  static const Color line = Color(0xFFE6E8F2);          // Hairlines
  static const Color primarySoft = Color(0xFFEEF0FF);   // Indigo wash

  // --- Canvas & surfaces (legacy names) ---
  static const Color whiteBg = canvas;
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color backgroundWhite = canvas;
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color glassWhite = Color(0xF5FFFFFF);
  static const Color glassCard = Color(0xF2FFFFFF);

  // --- Accent (legacy "magenta" names now map to indigo) ---
  static const Color magentaPrimary = primary;
  static const Color magentaDark = indigoDark;
  static const Color magentaDeep = indigoDeep;
  static const Color magentaLight = Color(0xFF818CF8);
  static const Color magentaAccent = violet;
  static const Color magentaSubtle = primarySoft;
  static const Color magentaBorder = Color(0x334338CA);
  static const Color magentaHighlight = Color(0x1F4338CA);

  static const Color burgundyBg = canvas;
  static const Color burgundySurface = Color(0xFFFFFFFF);
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color burgundyGlass = Color(0xF8FFFFFF);
  static const Color burgundyCard = Color(0xFFFFFFFF);
  static const Color burgundyAccent = primary;
  static const Color burgundySubtle = primarySoft;
  static const Color burgundyPrimary = primary;
  static const Color burgundyLight = Color(0xFF818CF8);
  static const Color burgundyDark = indigoDark;

  static const Color sandPrimary = primary;
  static const Color sandLight = midnight;
  static const Color sandGold = gold;
  static const Color sandDark = indigoDark;
  static const Color sandBorder = line;
  static const Color sandHighlight = goldSoft;

  static const Color goldPrimary = gold;
  static const Color goldLight = midnight;
  static const Color goldBright = Color(0xFFE2C26E);
  static const Color goldDark = goldDeep;
  static const Color goldSand = gold;

  // --- Typography ---
  static const Color textDark = midnight;
  static const Color textPrimary = Color(0xFF23233F);
  static const Color textSecondary = Color(0xFF4B4E66);
  static const Color textLight = midnight;
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textSand = goldDeep;
  static const Color textBurgundy = primary;
  static const Color textMuted = Color(0xFF6B6F86);
  static const Color textMagenta = primary;

  // --- Status ---
  static const Color ragGreen = Color(0xFF0E9F6E);
  static const Color ragGreenBg = Color(0xFFE8F8F1);
  static const Color ragYellow = Color(0xFFD97706);
  static const Color ragYellowBg = Color(0xFFFFF8E6);
  static const Color ragRed = Color(0xFFE5484D);
  static const Color ragRedBg = Color(0xFFFDEDEE);
  static const Color statusBlue = Color(0xFF2563EB);
  static const Color statusPurple = violet;

  // --- Gradients ---
  /// Signature hero gradient used by page headers, the home hero and the nav bar.
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF14123A), Color(0xFF1E1B4B), Color(0xFF3730A3)],
    stops: [0.0, 0.45, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4338CA), Color(0xFF6D28D9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradientBright = LinearGradient(
    colors: [Color(0xFFE9CF8A), Color(0xFFC9A24B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient magentaGradient = primaryGradient;
  static const LinearGradient burgundyGradient = heroGradient;

  static const LinearGradient sandGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF1F2FB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient liquidShine = LinearGradient(
    colors: [Color(0x1F4338CA), Color(0x0A4338CA), Color(0x00FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomCenter,
  );

  /// Soft elevation used by cards across the app.
  static const List<BoxShadow> softShadow = [
    BoxShadow(color: Color(0x0F14123A), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0814123A), blurRadius: 4, offset: Offset(0, 1)),
  ];
}
