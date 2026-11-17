import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/services/coptic_calendar_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
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
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
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
