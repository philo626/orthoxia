import 'package:flutter/material.dart';

/// Obsidian & Champagne-Gold palette (matches the reference video design).
class AppColors {
  // Champagne Gold
  static const Color primaryGold = Color(0xFFD9B77E);
  static const Color primaryGoldLight = Color(0xFFF3E0B8);
  static const Color primaryGoldDark = Color(0xFFA9834B);

  // Warm deep accents (kept names for backwards compatibility)
  static const Color sacredBurgundy = Color(0xFF5C2A22);
  static const Color sacredBurgundyDark = Color(0xFF221A12);

  // Obsidian surfaces (old "navy" names now map to obsidian tones)
  static const Color deepNavy = Color(0xFF0B0B0D); // App background
  static const Color cardNavy = Color(0xFF1A1A1D); // Elevated card
  static const Color surfaceNavy = Color(0xFF131315); // Secondary surface
  static const Color tileSurface = Color(0xFF232326);

  // AMOLED Church Mode (True Black)
  static const Color amoledBlack = Color(0xFF000000);
  static const Color amoledCard = Color(0xFF0E0E0F);

  // Light Parchment Theme
  static const Color parchmentBg = Color(0xFFF9F6F0);
  static const Color parchmentCard = Color(0xFFFFFFFF);
  static const Color parchmentText = Color(0xFF2C2416);

  // Accents
  static const Color accentCross = Color(0xFFC9A25F);
  static const Color successGreen = Color(0xFF10B981);
  static const Color fastingPurple = Color(0xFF8B5CF6);
  static const Color prayerBlue = Color(0xFF38BDF8);
  static const Color rubricRed = Color(0xFFD08770); // Kholagy rubric colour

  // Text Colors
  static const Color textLight = Color(0xFFF4EFE6);
  static const Color textMuted = Color(0xFF9A948A);
  static const Color textGold = Color(0xFFE6CB98);
  static const Color textCoptic = Color(0xFFEBD3A3);
  static const Color textArabized = Color(0xFFC9A46A);
  static const Color textArabic = Color(0xFFF4EFE6);

  // Aliases for convenience
  static const Color gold = primaryGold;
  static const Color goldLight = primaryGoldLight;
  static const Color burgundy = sacredBurgundy;
  static const Color cream = Color(0xFFF7F1E6);

  // Reusable gradients
  static const LinearGradient champagne = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF6E3BC), Color(0xFFD9B77E), Color(0xFFA9834B)],
  );

  static const LinearGradient obsidianCard = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF222225), Color(0xFF161618)],
  );
}
