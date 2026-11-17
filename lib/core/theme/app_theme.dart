import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

enum AppThemeMode {
  darkGold,
  amoledChurch,
  lightParchment,
}

class AppTheme {
  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.darkGold:
        return _darkGoldTheme;
      case AppThemeMode.amoledChurch:
        return _amoledChurchTheme;
      case AppThemeMode.lightParchment:
        return _lightParchmentTheme;
    }
  }

  // 1. Dark Gold Theme (Default)
  static final ThemeData _darkGoldTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.cairo().fontFamily,
    scaffoldBackgroundColor: AppColors.deepNavy,
    primaryColor: AppColors.primaryGold,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryGold,
      secondary: AppColors.sacredBurgundy,
      surface: AppColors.cardNavy,
      onPrimary: Colors.black,
      onSurface: AppColors.textLight,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.deepNavy,
      foregroundColor: AppColors.primaryGold,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.cairo(
        color: AppColors.primaryGold,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardNavy,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.15)),
      ),
    ),
  );

  // 2. AMOLED Church Mode (Pure Black for dim sanctuaries)
  static final ThemeData _amoledChurchTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: GoogleFonts.cairo().fontFamily,
    scaffoldBackgroundColor: AppColors.amoledBlack,
    primaryColor: AppColors.primaryGold,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryGold,
      secondary: AppColors.sacredBurgundy,
      surface: AppColors.amoledCard,
      onPrimary: Colors.black,
      onSurface: AppColors.textLight,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.amoledBlack,
      foregroundColor: AppColors.primaryGold,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.cairo(
        color: AppColors.primaryGold,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.amoledCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
    ),
  );

  // 3. Light Parchment Theme
  static final ThemeData _lightParchmentTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: GoogleFonts.cairo().fontFamily,
    scaffoldBackgroundColor: AppColors.parchmentBg,
    primaryColor: AppColors.sacredBurgundy,
    colorScheme: const ColorScheme.light(
      primary: AppColors.sacredBurgundy,
      secondary: AppColors.primaryGoldDark,
      surface: AppColors.parchmentCard,
      onPrimary: Colors.white,
      onSurface: AppColors.parchmentText,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.parchmentBg,
      foregroundColor: AppColors.sacredBurgundy,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.cairo(
        color: AppColors.sacredBurgundy,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.parchmentCard,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.sacredBurgundy.withValues(alpha: 0.1)),
      ),
    ),
  );
}
