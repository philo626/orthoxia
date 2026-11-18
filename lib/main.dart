import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/services/coptic_calendar_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/patron_saint_service.dart';
import 'core/services/speech_pronunciation_service.dart';
import 'core/services/storage_service.dart';
import 'providers/theme_provider.dart';
import 'providers/audio_provider.dart';
import 'providers/spiritual_tracker_provider.dart';
import 'providers/prayer_wall_provider.dart';
import 'providers/ai_companion_provider.dart';
import 'providers/trivia_provider.dart';
import 'providers/books_provider.dart';
import 'providers/bible_provider.dart';
import 'providers/liturgy_provider.dart';
import 'providers/church_mode_provider.dart';
import 'views/onboarding/splash_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init();
  await FirebaseService().initSafely();
  await NotificationService().init();
  await CopticCalendarService.ensureLectionaryLoaded();
  await PatronSaintService.ensureLoaded();

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

    final baseTheme = themeProv.currentTheme;
    final activeTheme = churchMode.isChurchMode
        ? baseTheme.copyWith(
            scaffoldBackgroundColor: Colors.black,
            cardColor: const Color(0xFF090909),
            appBarTheme: baseTheme.appBarTheme.copyWith(backgroundColor: Colors.black),
          )
        : baseTheme;

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
            // Global Floating Stop Audio Pill whenever SpeechPronunciationService is active
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1416),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.redAccent, width: 1.4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.7),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.volume_up_rounded, color: AppColors.primaryGold, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ValueListenableBuilder<String>(
                              valueListenable: speech.activeLabelNotifier,
                              builder: (_, lbl, __) => Text(
                                lbl.isNotEmpty ? 'جاري القراءة: $lbl' : 'جاري القراءة الصوتية...',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => speech.stop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.stop_circle_rounded, size: 16),
                            label: Text(
                              'إيقاف الصوت',
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
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
