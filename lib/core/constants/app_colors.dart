import 'package:flutter/material.dart';

/// Warm Basalt & Antique Leaf-Gold liturgical palette.
class AppColors {
  // Antique Liturgical Gold (dignified, restrained — never flashy neon)
  static const Color primaryGold = Color(0xFFC8A253);
  static const Color primaryGoldLight = Color(0xFFE7D3A7);
  static const Color primaryGoldDark = Color(0xFF8F6E32);

  // Warm deep monastic crimson accents
  static const Color sacredBurgundy = Color(0xFF75212A);
  static const Color sacredBurgundyDark = Color(0xFF241614);

  // Warm Basalt & Dark Ink Surfaces
  static const Color deepNavy = Color(0xFF0E0D0C); // App canvas
  static const Color cardNavy = Color(0xFF171513); // Elevated surface
  static const Color surfaceNavy = Color(0xFF121110); // Inset surface
  static const Color tileSurface = Color(0xFF1E1B18); // Interactive tile
  static const Color hairline = Color(0xFF2A2621); // Whisper-thin editorial border

  // AMOLED Church Mode (True Black)
  static const Color amoledBlack = Color(0xFF000000);
  static const Color amoledCard = Color(0xFF0C0B0A);

  // Light Parchment Theme
  static const Color parchmentBg = Color(0xFFF7F3EB);
  static const Color parchmentCard = Color(0xFFFFFFFF);
  static const Color parchmentText = Color(0xFF282016);

  // Restrained Semantic Accents
  static const Color accentCross = Color(0xFFC8A253);
  static const Color successGreen = Color(0xFF4F8261); // Muted monastic sage
  static const Color fastingPurple = Color(0xFF7B669E); // Muted Lenten violet
  static const Color prayerBlue = Color(0xFF5B86A8); // Soft cathedral slate blue
  static const Color rubricRed = Color(0xFFC26D5E); // Traditional Kholagy rubric vermilion

  // Text Colors (Warm Alabaster & Stone)
  static const Color textLight = Color(0xFFF3ECE0);
  static const Color textMuted = Color(0xFF9C9386);
  static const Color textGold = Color(0xFFE5CD9B);
  static const Color textCoptic = Color(0xFFEBD4A6);
  static const Color textArabized = Color(0xFFC4A064);
  static const Color textArabic = Color(0xFFF3ECE0);

  // Aliases for convenience
  static const Color gold = primaryGold;
  static const Color goldLight = primaryGoldLight;
  static const Color burgundy = sacredBurgundy;
  static const Color cream = Color(0xFFF7F1E6);

  // Refined subtle gradients
  static const LinearGradient champagne = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE7D3A7), Color(0xFFC8A253), Color(0xFF9B7938)],
  );

  static const LinearGradient obsidianCard = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1B1916), Color(0xFF141210)],
  );
}
