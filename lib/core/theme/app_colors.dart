import 'package:flutter/material.dart';

class AppColors {
  // Rich Velvet Burgundy Canvas & Backgrounds
  static const Color burgundyBg = Color(0xFF140206);
  static const Color burgundySurface = Color(0xFF22030A);
  static const Color burgundyGlass = Color(0xCC28040C);
  static const Color burgundyCard = Color(0xFF28040C);
  static const Color burgundyAccent = Color(0xFF8B152B);
  static const Color burgundySubtle = Color(0x334A0713);

  // Backward compatibility aliases (all mapped strictly to velvet burgundy canvas)
  static const Color pureWhite = Color(0xFF140206);
  static const Color backgroundWhite = Color(0xFF140206);
  static const Color surfaceWhite = Color(0xFF22030A);
  static const Color glassWhite = Color(0xCC28040C);
  static const Color glassCard = Color(0xCC28040C);

  static const Color burgundyPrimary = Color(0xFF8B152B);
  static const Color burgundyLight = Color(0xFFA81D37);
  static const Color burgundyDark = Color(0xFF140206);

  // Signature Champagne Sand & Gold Palette
  static const Color sandPrimary = Color(0xFFDFC8AF);
  static const Color sandLight = Color(0xFFFBF4EB);
  static const Color sandGold = Color(0xFFE8CF8B);
  static const Color sandDark = Color(0xFFB89877);
  static const Color sandBorder = Color(0x40DFC8AF);
  static const Color sandHighlight = Color(0x26DFC8AF);

  // Backward-compatible color aliases
  static const Color goldPrimary = Color(0xFFDFC8AF);
  static const Color goldLight = Color(0xFFFBF4EB);
  static const Color goldBright = Color(0xFFE8CF8B);
  static const Color goldDark = Color(0xFFB89877);
  static const Color goldSand = Color(0xFFDFC8AF);

  // High-Contrast Crisp Typography on Dark Burgundy
  static const Color textLight = Color(0xFFFBF4EB);
  static const Color textDark = Color(0xFFFBF4EB); // Mapped to champagne light on burgundy
  static const Color textSand = Color(0xFFDFC8AF);
  static const Color textBurgundy = Color(0xFFFBF4EB);
  static const Color textMuted = Color(0xFFBCA69D);

  // Status & Traffic RAG
  static const Color ragGreen = Color(0xFF10B981);
  static const Color ragYellow = Color(0xFFF59E0B);
  static const Color ragRed = Color(0xFFFF5252); // High-contrast Vivid Coral Red
  static const Color statusBlue = Color(0xFF3B82F6);
  static const Color statusPurple = Color(0xFFA855F7);

  // Luxury Gradients
  static const LinearGradient burgundyGradient = LinearGradient(
    colors: [Color(0xFF8B152B), Color(0xFF500814), Color(0xFF22030A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sandGradient = LinearGradient(
    colors: [Color(0xFFFBF4EB), Color(0xFFDFC8AF), Color(0xFFB89877)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFF2A3), Color(0xFFE8CF8B), Color(0xFFB89877)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient liquidShine = LinearGradient(
    colors: [
      Color(0x26FFFFFF),
      Color(0x0AFFFFFF),
      Color(0x00FFFFFF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomCenter,
  );
}
