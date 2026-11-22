import 'package:flutter/material.dart';

/// Unified adaptive design tokens for Orthodoxia across
/// Warm Parchment (daylight), Warm Charcoal & Antique Gold (night),
/// and Pure Black Sanctuary (AMOLED church mode).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color canvas;
  final Color surface;
  final Color surfaceSubtle;
  final Color surfaceMuted;
  final Color border;
  final Color ink;
  final Color inkSecondary;
  final Color inkMuted;
  final Color accent;
  final Color onAccent;
  final Color gold;
  final Color goldSoft;
  final Color goldBorder;
  final Color crimson;
  final Color sage;
  final Color danger;
  final Color shadow;
  final bool isDark;

  const AppPalette({
    required this.canvas,
    required this.surface,
    required this.surfaceSubtle,
    required this.surfaceMuted,
    required this.border,
    required this.ink,
    required this.inkSecondary,
    required this.inkMuted,
    required this.accent,
    required this.onAccent,
    required this.gold,
    required this.goldSoft,
    required this.goldBorder,
    required this.crimson,
    required this.sage,
    required this.danger,
    required this.shadow,
    required this.isDark,
  });

  /// 1. Warm Parchment (Daylight Editorial — Default)
  static const AppPalette lightParchment = AppPalette(
    canvas: Color(0xFFFAF6EE),
    surface: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF3ECE0),
    surfaceMuted: Color(0xFFEAE1D2),
    border: Color(0xFFE5DCCD),
    ink: Color(0xFF1F1A15),
    inkSecondary: Color(0xFF63574B),
    inkMuted: Color(0xFF938678),
    accent: Color(0xFF7E242D), // Dignified liturgical crimson
    onAccent: Color(0xFFFFFDF9),
    gold: Color(0xFFA47A2E), // High-contrast burnished antique gold
    goldSoft: Color(0xFFF6ECD7),
    goldBorder: Color(0xFFDCC79F),
    crimson: Color(0xFF7E242D),
    sage: Color(0xFF3A6B4F),
    danger: Color(0xFFB83232),
    shadow: Color(0x122B2012),
    isDark: false,
  );

  /// 2. Warm Charcoal & Antique Gold (Evening / Night)
  static const AppPalette darkCharcoal = AppPalette(
    canvas: Color(0xFF11100E),
    surface: Color(0xFF1A1815),
    surfaceSubtle: Color(0xFF23201C),
    surfaceMuted: Color(0xFF2D2924),
    border: Color(0xFF2E2A23),
    ink: Color(0xFFF4EEE3),
    inkSecondary: Color(0xFFB3A89A),
    inkMuted: Color(0xFF7E7469),
    accent: Color(0xFFC9A255), // Warm antique leaf gold
    onAccent: Color(0xFF19130A),
    gold: Color(0xFFD8B46C),
    goldSoft: Color(0xFF272116),
    goldBorder: Color(0xFF473A23),
    crimson: Color(0xFFA83C46),
    sage: Color(0xFF5D9674),
    danger: Color(0xFFE06666),
    shadow: Color(0x4A000000),
    isDark: true,
  );

  /// 3. Pure Black AMOLED Church Mode (Dim Sanctuary)
  static const AppPalette amoledChurch = AppPalette(
    canvas: Color(0xFF000000),
    surface: Color(0xFF0B0A09),
    surfaceSubtle: Color(0xFF141210),
    surfaceMuted: Color(0xFF1E1B17),
    border: Color(0xFF231F19),
    ink: Color(0xFFEAE2D4),
    inkSecondary: Color(0xFF9E9487),
    inkMuted: Color(0xFF6B6258),
    accent: Color(0xFFB89348),
    onAccent: Color(0xFF0D0A06),
    gold: Color(0xFFC4A056),
    goldSoft: Color(0xFF1C170E),
    goldBorder: Color(0xFF382E1B),
    crimson: Color(0xFF96353E),
    sage: Color(0xFF4D8062),
    danger: Color(0xFFD45E5E),
    shadow: Colors.transparent,
    isDark: true,
  );

  @override
  AppPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceSubtle,
    Color? surfaceMuted,
    Color? border,
    Color? ink,
    Color? inkSecondary,
    Color? inkMuted,
    Color? accent,
    Color? onAccent,
    Color? gold,
    Color? goldSoft,
    Color? goldBorder,
    Color? crimson,
    Color? sage,
    Color? danger,
    Color? shadow,
    bool? isDark,
  }) {
    return AppPalette(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      border: border ?? this.border,
      ink: ink ?? this.ink,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      inkMuted: inkMuted ?? this.inkMuted,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      gold: gold ?? this.gold,
      goldSoft: goldSoft ?? this.goldSoft,
      goldBorder: goldBorder ?? this.goldBorder,
      crimson: crimson ?? this.crimson,
      sage: sage ?? this.sage,
      danger: danger ?? this.danger,
      shadow: shadow ?? this.shadow,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceSubtle: Color.lerp(surfaceSubtle, other.surfaceSubtle, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSecondary: Color.lerp(inkSecondary, other.inkSecondary, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldSoft: Color.lerp(goldSoft, other.goldSoft, t)!,
      goldBorder: Color.lerp(goldBorder, other.goldBorder, t)!,
      crimson: Color.lerp(crimson, other.crimson, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette {
    final ext = Theme.of(this).extension<AppPalette>();
    if (ext != null) return ext;
    return Theme.of(this).brightness == Brightness.dark
        ? AppPalette.darkCharcoal
        : AppPalette.lightParchment;
  }
}
