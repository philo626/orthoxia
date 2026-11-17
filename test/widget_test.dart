import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orthodox_app/core/services/storage_service.dart';
import 'package:orthodox_app/providers/theme_provider.dart';
import 'package:orthodox_app/providers/audio_provider.dart';
import 'package:orthodox_app/providers/spiritual_tracker_provider.dart';
import 'package:orthodox_app/providers/prayer_wall_provider.dart';
import 'package:orthodox_app/providers/ai_companion_provider.dart';
import 'package:orthodox_app/providers/trivia_provider.dart';
import 'package:orthodox_app/providers/books_provider.dart';
import 'package:orthodox_app/providers/bible_provider.dart';
import 'package:orthodox_app/providers/liturgy_provider.dart';
import 'package:orthodox_app/providers/church_mode_provider.dart';
import 'package:orthodox_app/views/main_navigation_shell.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('Orthodox App Main Navigation smoke test', (WidgetTester tester) async {
    await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({'notif_prompt_shown': true});
      await StorageService().init();
    });
    await tester.pumpWidget(
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
        child: const MaterialApp(
          home: MainNavigationShell(),
        ),
      ),
    );

    expect(find.byType(MainNavigationShell), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });
}
