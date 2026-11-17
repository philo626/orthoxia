import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orthodox_app/core/services/coptic_calendar_service.dart';
import 'package:orthodox_app/core/services/storage_service.dart';
import 'package:orthodox_app/models/spiritual_tracker_model.dart';
import 'package:orthodox_app/providers/church_mode_provider.dart';
import 'package:orthodox_app/providers/liturgy_provider.dart';
import 'package:orthodox_app/providers/theme_provider.dart';
import 'package:orthodox_app/views/liturgies/liturgy_reader_view.dart';
import 'package:orthodox_app/views/synaxarium/synaxarium_daily_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('1. Coptic Calendar Calculations', () {
    test('Converts key Gregorian feasts to exact Coptic dates', () {
      // Sept 11, 2025 -> 1 Tout 1742 AM
      final nayrouz = CopticCalendarService.fromGregorian(DateTime(2025, 9, 11));
      expect(nayrouz.day, 1);
      expect(nayrouz.month, 1);
      expect(nayrouz.monthName, 'توت');
      expect(nayrouz.year, 1742);

      // Jan 7, 2026 -> 29 Kiahk 1742 AM (Coptic Nativity)
      final nativity = CopticCalendarService.fromGregorian(DateTime(2026, 1, 7));
      expect(nativity.day, 29);
      expect(nativity.month, 4);
      expect(nativity.monthName, 'كيهك');

      // Jan 19, 2026 -> 11 Toba 1742 AM (Coptic Epiphany)
      final epiphany = CopticCalendarService.fromGregorian(DateTime(2026, 1, 19));
      expect(epiphany.day, 11);
      expect(epiphany.month, 5);
      expect(epiphany.monthName, 'طوبة');

      // All 13 Coptic months exist
      expect(CopticCalendarService.copticMonths.length, 13);
      expect(CopticCalendarService.copticMonths.last, 'النسيء');
    });
  });

  group('2. Authentic Arabic Synaxarium & Data Assets Integrity', () {
    test('synaxarium_ar.json has 366 days, pure Arabic titles, and non-empty biographies', () {
      final file = File('assets/data/synaxarium_ar.json');
      expect(file.existsSync(), isTrue);

      final Map<String, dynamic> data = jsonDecode(file.readAsStringSync());
      expect(data.length, 366);

      int totalEntries = 0;
      int englishTitleCount = 0;
      final latinRegex = RegExp(r'[A-Za-z]');

      for (final entry in data.entries) {
        final list = entry.value as List<dynamic>;
        expect(list.isNotEmpty, isTrue, reason: 'Day ${entry.key} should not be empty');
        for (final item in list) {
          totalEntries++;
          final title = '${item['title'] ?? ''}'.trim();
          final text = '${item['text'] ?? ''}'.trim();
          expect(title.isNotEmpty, isTrue);
          expect(text.length, greaterThan(20), reason: 'Biography too short for $title');
          if (latinRegex.hasMatch(title)) {
            englishTitleCount++;
          }
        }
      }

      expect(totalEntries, greaterThanOrEqualTo(850));
      expect(englishTitleCount, 0, reason: 'No English letters should appear in Arabic Synaxarium titles');
    });

    test('liturgies.json contains complete St. Basil, St. Gregory, and St. Cyril liturgies', () {
      final file = File('assets/data/liturgies.json');
      expect(file.existsSync(), isTrue);

      final List<dynamic> list = jsonDecode(file.readAsStringSync());
      expect(list.length, 3);

      final ids = list.map((e) => e['id']).toList();
      expect(ids, containsAll(['liturgy_basil', 'liturgy_gregory', 'liturgy_cyril']));

      for (final lit in list) {
        final sections = lit['sections'] as List<dynamic>;
        expect(sections.length, greaterThanOrEqualTo(6));
        expect('${sections.first['title']}', contains('تقدمة الحمل'));
      }
    });

    test('All core JSON assets parse cleanly (agpeya, bible, hymns, katameros, books, commentaries)', () {
      for (final path in [
        'assets/data/agpeya.json',
        'assets/data/bible.json',
        'assets/data/hymns.json',
        'assets/data/katameros_complete.json',
        'assets/data/books.json',
        'assets/data/commentaries.json',
      ]) {
        final f = File(path);
        expect(f.existsSync(), isTrue, reason: 'Missing $path');
        final decoded = jsonDecode(f.readAsStringSync());
        expect(decoded, isNotNull);
      }

      final hymns = jsonDecode(File('assets/data/hymns.json').readAsStringSync()) as List;
      expect(hymns.length, greaterThanOrEqualTo(400));
      final withYoutube = hymns.where((h) => '${h['youtube_id'] ?? ''}'.isNotEmpty).length;
      expect(withYoutube, greaterThan(350));
    });
  });

  group('3. Services & Local Encryption', () {
    test('CopticCalendarService loads Arabic Synaxarium and supports search & categories', () async {
      await CopticCalendarService.ensureLectionaryLoaded();

      final nayrouzEvents = CopticCalendarService.getSynaxariumEventsForDate(1, 1);
      expect(nayrouzEvents.isNotEmpty, isTrue);
      expect('${nayrouzEvents.first['title']}', contains('النيروز'));

      final searchResults = CopticCalendarService.searchSynaxarium('العذراء');
      expect(searchResults.isNotEmpty, isTrue);

      final martyrs = CopticCalendarService.getCategorizedSynaxariumItems(
        month: 1,
        day: 1,
        category: 'martyrs',
      );
      expect(martyrs.isNotEmpty, isTrue);
    });

    test('StorageService encrypts Spiritual Tracker & Conscience notes locally and persists church choice', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();

      await storage.setDiocese('إيبارشية الإسكندرية والوجه البحري');
      await storage.setChurchName('الكاتدرائية المرقسية بالإسكندرية');
      expect(storage.getDiocese(), 'إيبارشية الإسكندرية والوجه البحري');
      expect(storage.getChurchName(), 'الكاتدرائية المرقسية بالإسكندرية');

      final log = SpiritualLog(
        date: '2026-11-18',
        agpeyaHoursCompleted: 3,
        bibleChaptersRead: 2,
        personalPrayerMinutes: 20,
        tookCommunion: true,
        actsOfCharity: true,
        reflectionNote: 'شكر خاص لله على مراحمه',
      );
      await storage.saveSpiritualLogs([log]);

      final prefs = await SharedPreferences.getInstance();
      final rawStored = prefs.getString('spiritual_logs_encrypted') ?? '';
      expect(rawStored.startsWith('ENC_V1:'), isTrue, reason: 'Logs must be encrypted locally');
      expect(rawStored.contains('شكر خاص'), isFalse, reason: 'Plaintext must not appear in storage');

      final restored = storage.getSpiritualLogs();
      expect(restored.length, 1);
      expect(restored.first.reflectionNote, 'شكر خاص لله على مراحمه');
    });

    test('LiturgyProvider loads all 3 liturgies and filters roles accurately', () async {
      final prov = LiturgyProvider();
      await prov.loadLiturgies();
      expect(prov.liturgies.length, 3);
      expect(prov.selectedLiturgy?.id, 'liturgy_basil');

      final firstSecVerses = prov.selectedLiturgy!.sections.first.verses;
      prov.setActiveRole('priest');
      final priestOnly = prov.filterVerses(firstSecVerses);
      expect(priestOnly.every((v) => v.role == 'priest' || v.role == 'all'), isTrue);

      prov.selectLiturgyById('liturgy_gregory');
      expect(prov.selectedLiturgy?.id, 'liturgy_gregory');
    });
  });

  group('4. Widget Rendering & Interaction Tests', () {
    testWidgets('SynaxariumDailyView renders today Coptic date, months, and commemorations', (tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues({});
        await StorageService().init();
        await CopticCalendarService.ensureLectionaryLoaded();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ],
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: SynaxariumDailyView(initialMonth: 1, initialDay: 1),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('السنكسار القبطي اليومي والجامع'), findsOneWidget);
      expect(find.textContaining('النيروز'), findsWidgets);
    });

    testWidgets('LiturgyReaderView renders continuous Kholagy, role filters, and Index Sheet', (tester) async {
      late LiturgyProvider liturgyProvider;
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues({});
        await StorageService().init();
        await CopticCalendarService.ensureLectionaryLoaded();
        liturgyProvider = LiturgyProvider();
        await liturgyProvider.loadLiturgies();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => ChurchModeProvider()),
            ChangeNotifierProvider.value(value: liturgyProvider),
          ],
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: LiturgyReaderView(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('فهرس القداس'), findsOneWidget);
      expect(find.text('🔴 الكاهن'), findsOneWidget);
      expect(find.text('🔵 الشماس'), findsOneWidget);
      expect(find.text('⚪ الشعب'), findsOneWidget);

      // Tap Index Floating Action Button to open Liturgical Index Sheet
      await tester.tap(find.text('فهرس القداس'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('فهرس صلوات ومحطات القداس'), findsOneWidget);
    });
  });
}
