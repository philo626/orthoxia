import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/services/coptic_calendar_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/patron_saint_service.dart';
import 'core/services/speech_pronunciation_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/app_palette.dart';
import 'core/theme/app_theme.dart';
import 'providers/ai_companion_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/bible_provider.dart';
import 'providers/books_provider.dart';
import 'providers/church_mode_provider.dart';
import 'providers/liturgy_provider.dart';
import 'providers/prayer_wall_provider.dart';
import 'providers/spiritual_tracker_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/trivia_provider.dart';
import 'views/onboarding/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init();
  await Future.wait([
    FirebaseService().initSafely(),
    NotificationService().init(),
    CopticCalendarService.ensureLectionaryLoaded(),
    PatronSaintService.ensureLoaded(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
        ChangeNotifierProvider(create: (_) => SpiritualTrackerProvider()),
        ChangeNotifierProvider(create: (_) => PrayerWallProvider()),
        ChangeNotifierProvider(create: (_) => AiCompanionProvider()),
        ChangeNotifierProvider(create: (_) => TriviaProvider()),
        ChangeNotifierProvider(create: (_) => BooksProvider()),
        ChangeNotifierProvider(create: (_) => BibleProvider()),
        ChangeNotifierProvider(create: (_) => LiturgyProvider()),
        ChangeNotifierProvider(create: (_) => ChurchModeProvider()),
      ],
      child: const OrthodoxApp(),
    ),
  );
}

class OrthodoxApp extends StatelessWidget {
  const OrthodoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final churchMode = Provider.of<ChurchModeProvider>(context);

    final activeTheme = churchMode.isChurchMode
        ? AppTheme.getTheme(AppThemeMode.amoledChurch)
        : themeProv.currentTheme;
    final isDark = activeTheme.brightness == Brightness.dark;
    final palette = activeTheme.extension<AppPalette>() ??
        (isDark ? AppPalette.darkCharcoal : AppPalette.lightParchment);

    SystemChrome.setSystemUIOverlayStyle(
      isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: palette.canvas,
              systemNavigationBarIconBrightness: Brightness.light,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: palette.surface,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
    );

    return MaterialApp(
      title: 'أرثوذكسيا',
      debugShowCheckedModeBanner: false,
      theme: activeTheme,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [
        Locale('ar', 'EG'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final speech = SpeechPronunciationService();
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            // Adaptive Floating Stop Audio Pill whenever voice reading is active
            ValueListenableBuilder<bool>(
              valueListenable: speech.isSpeakingNotifier,
              builder: (context, speaking, _) {
                if (!speaking) return const SizedBox.shrink();
                return Positioned(
                  left: 16,
                  right: 16,
                  bottom: 84,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: palette.goldBorder, width: 1.1),
                        boxShadow: [
                          BoxShadow(
                            color: palette.shadow.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.volume_up_rounded, color: palette.accent, size: 19),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ValueListenableBuilder<String>(
                              valueListenable: speech.activeLabelNotifier,
                              builder: (_, lbl, _) => Text(
                                lbl.isNotEmpty ? 'جاري القراءة: $lbl' : 'جاري القراءة الصوتية',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: palette.ink,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => speech.stop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: palette.crimson,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(0, 34),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.stop_rounded, size: 15),
                            label: Text(
                              'إيقاف',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            if (churchMode.isChurchMode)
              IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  color: Colors.black.withValues(alpha: churchMode.dimFactor),
                ),
              ),
          ],
        );
      },
      home: const SplashView(),
    );
  }
}
