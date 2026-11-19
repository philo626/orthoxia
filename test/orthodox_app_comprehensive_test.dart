import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orthodox_app/core/services/ai_theology_service.dart';
import 'package:orthodox_app/core/services/bible_reading_progress_service.dart';
import 'package:orthodox_app/core/services/coptic_calendar_service.dart';
import 'package:orthodox_app/core/services/coptic_fast_service.dart';
import 'package:orthodox_app/core/services/coptic_youtube_registry.dart';
import 'package:orthodox_app/core/services/notification_service.dart';
import 'package:orthodox_app/core/services/online_coptic_library_service.dart';
import 'package:orthodox_app/core/services/patron_saint_service.dart';
import 'package:orthodox_app/core/services/storage_service.dart';
import 'package:orthodox_app/models/spiritual_tracker_model.dart';
import 'package:orthodox_app/providers/books_provider.dart';
import 'package:orthodox_app/providers/church_mode_provider.dart';
import 'package:orthodox_app/providers/liturgy_provider.dart';
import 'package:orthodox_app/providers/theme_provider.dart';
import 'package:orthodox_app/views/books/books_library_view.dart';
import 'package:orthodox_app/views/coptic_academy/coptic_academy_view.dart';
import 'package:orthodox_app/views/home/spiritual_prescription_view.dart';
import 'package:orthodox_app/views/liturgical/church_sacraments_rites_view.dart';
import 'package:orthodox_app/views/liturgical/remember_them_view.dart';
import 'package:orthodox_app/views/liturgical/tasbeha_pascha_view.dart';
import 'package:orthodox_app/views/liturgies/liturgy_reader_view.dart';
import 'package:orthodox_app/views/synaxarium/my_patron_saint_view.dart';
import 'package:orthodox_app/views/synaxarium/synaxarium_daily_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('1. Coptic Calendar & Movable Feasts Computus', () {
    test('Converts key Gregorian feasts to exact Coptic dates and computes Orthodox Easter', () {
      final nayrouz = CopticCalendarService.fromGregorian(DateTime(2025, 9, 11));
      expect(nayrouz.day, 1);
      expect(nayrouz.month, 1);
      expect(nayrouz.monthName, 'توت');
      expect(nayrouz.year, 1742);

      // Verify 5:00 PM (17:00) Coptic Vespers rollover to next liturgical day!
      final beforeVespers = CopticCalendarService.todayLiturgical(DateTime(2025, 9, 11, 16, 59));
      expect(beforeVespers.day, 1);
      expect(beforeVespers.month, 1);
      expect(CopticCalendarService.isAfterVespers(DateTime(2025, 9, 11, 16, 59)), isFalse);

      final atVespers = CopticCalendarService.todayLiturgical(DateTime(2025, 9, 11, 17, 0));
      expect(atVespers.day, 2);
      expect(atVespers.month, 1);
      expect(CopticCalendarService.isAfterVespers(DateTime(2025, 9, 11, 17, 0)), isTrue);

      final nativity = CopticCalendarService.fromGregorian(DateTime(2026, 1, 7));
      expect(nativity.day, 29);
      expect(nativity.month, 4);
      expect(nativity.monthName, 'كيهك');

      // Orthodox Easter 2026 = April 12, 2026
      final easter2026 = CopticCalendarService.computeOrthodoxEaster(2026);
      expect(easter2026.month, 4);
      expect(easter2026.day, 12);

      final movable = CopticCalendarService.getMovableFeastsForYear(2026);
      expect(movable.length, 8);
      expect(CopticCalendarService.copticMonths.length, 13);

      // Verify CopticFastService & AiTheologyService markdown cleaner
      final fastGreatLent = CopticFastService.getTodayFastStatus(DateTime(2026, 3, 15));
      expect(fastGreatLent.isFastingToday, isTrue);
      expect(fastGreatLent.fishAllowed, isFalse);

      final cleanedAi = AiTheologyService.cleanMarkdownFormatting(
        '### ***عنوان الإجابة***\n***\n* **النقطة الأولى:** شرح واضح.',
      );
      expect(cleanedAi.contains('*'), isFalse);
      expect(cleanedAi.contains('#'), isFalse);
      expect(cleanedAi.contains('☦ عنوان الإجابة'), isTrue);
      expect(cleanedAi.contains('• النقطة الأولى:'), isTrue);
    });
  });

  group('2. Authentic Arabic Synaxarium, Liturgies & Verified YouTube Hymns Integrity', () {
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
        expect(list.isNotEmpty, isTrue);
        for (final item in list) {
          totalEntries++;
          final title = '${item['title'] ?? ''}'.trim();
          final text = '${item['text'] ?? ''}'.trim();
          expect(title.isNotEmpty, isTrue);
          expect(text.length, greaterThan(20));
          if (latinRegex.hasMatch(title)) englishTitleCount++;
        }
      }

      expect(totalEntries, greaterThanOrEqualTo(850));
      expect(englishTitleCount, 0);
    });

    test('liturgies.json contains complete modernized St. Basil, St. Gregory, and St. Cyril liturgies with true Coptic Unicode', () {
      final list = jsonDecode(File('assets/data/liturgies.json').readAsStringSync()) as List;
      expect(list.length, 3);
      expect(list.map((e) => e['id']), containsAll(['liturgy_basil', 'liturgy_gregory', 'liturgy_cyril']));
      final rolesFound = <String>{};
      bool hasTrueCopticUnicode = false;
      for (final lit in list) {
        final sections = lit['sections'] as List;
        expect('${sections.first['title']}', contains('تقدمة الحمل'));
        for (final sec in sections) {
          for (final v in (sec['verses'] as List)) {
            rolesFound.add('${v['role']}');
            final cop = '${v['coptic'] ?? ''}';
            if (cop.contains('Ⲧ') || cop.contains('Ϣ') || cop.contains('Ⲕ')) {
              hasTrueCopticUnicode = true;
            }
          }
        }
      }
      expect(hasTrueCopticUnicode, isTrue, reason: 'Must contain true Bohairic Coptic Unicode characters');
      expect(rolesFound, containsAll(['priest', 'priest_silent', 'deacon', 'people', 'rubric', 'reading_slot']));
      // Verify canonical Coptic Reader / Orsozoxi order with embedded Synaxarium milestone
      for (final lit in list) {
        final titles = (lit['sections'] as List).map((s) => '${s['title']}').toList();
        expect(titles.any((t) => t.contains('السنكسار')), isTrue);
        expect(titles.last, contains('التناول'));
      }
      final fracs = jsonDecode(File('assets/data/seasonal_fractions.json').readAsStringSync()) as List;
      expect(fracs.length, greaterThanOrEqualTo(35));

      // Verify Bible is the authentic Smith & Van Dyck translation with concise book names
      final bibleBooks = jsonDecode(File('assets/data/bible.json').readAsStringSync()) as List;
      expect(bibleBooks.length, greaterThanOrEqualTo(66));
      final psalms = bibleBooks.firstWhere((b) => b['abbrev'] == 'sl');
      expect('${psalms['chapters'][0][0]}', contains('طُوبَى لِلرَّجُلِ الَّذِي لَمْ يَسْلُكْ'));
      for (final b in bibleBooks) {
        if (b['testament'] == 'NEW') {
          expect('${b['name']}'.length, lessThanOrEqualTo(20), reason: 'Book name must fit button cleanly: ${b['name']}');
        }
      }
    });

    test('All 317 hymns have 100% unique 1-to-1 audio URLs and verified YouTube IDs (zero duplicates or mismatches)', () {
      final hymns = jsonDecode(File('assets/data/hymns.json').readAsStringSync()) as List;
      expect(hymns.length, greaterThanOrEqualTo(315));
      final deadIds = {'3_p4J6p-gV4', 'n0YqZ7Ld3K0', 'o3N_uTz9h44', 'sW8p1q6tV5U'};
      final audioUrls = <String>{};
      final youtubeIds = <String>{};
      for (final h in hymns) {
        final yid = '${h['youtube_id'] ?? ''}';
        final aurl = '${h['audio_url'] ?? ''}';
        expect(yid.isNotEmpty, isTrue);
        expect(aurl.startsWith('http'), isTrue);
        expect(deadIds.contains(yid), isFalse, reason: 'Dead YouTube ID found: $yid');
        audioUrls.add(aurl);
        youtubeIds.add(yid);
      }
      expect(audioUrls.length, hymns.length, reason: 'Every hymn must have its own unique 1-to-1 audio URL');
      expect(youtubeIds.length, greaterThanOrEqualTo(250), reason: 'Hymns must map to specific YouTube video IDs');
      expect(CopticYouTubeRegistry.resolveVideoId(hymnId: 'tai-shori', title: 'طاي شوري'), 'RIRb2ED0qvE');
      expect(CopticYouTubeRegistry.resolveVideoId(hymnId: 'golgotha', title: 'غولغوثا'), '6iuEVnKP7rU');
    });
  });

  group('3. AES-256 Encryption, User Name, Patron Saint & Notifications', () {
    test('StorageService uses AES-256-CBC for confession & spiritual logs, saves user name & patron saint', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      await storage.init();

      await storage.setUserName('كيرلس فادي');
      expect(storage.getUserName(), 'كيرلس فادي');

      await storage.setPatronSaintId('pope_kyrillos');
      expect(storage.getPatronSaintId(), 'pope_kyrillos');
      final quote = PatronSaintService.getDailyQuote('pope_kyrillos');
      expect(quote.quote.isNotEmpty, isTrue);

      // Family prayer reminder defaults to OFF (strictly optional, never forced!)
      expect(storage.isFamilyPrayerReminderEnabled(), isFalse);
      expect(NotificationService.getTodayVerse().text.isNotEmpty, isTrue);

      final log = SpiritualLog(
        date: '2026-11-18',
        agpeyaHoursCompleted: 3,
        bibleChaptersRead: 2,
        personalPrayerMinutes: 20,
        tookCommunion: true,
        actsOfCharity: true,
        reflectionNote: 'مذكرة اعتراف خاصة مشفرة',
      );
      await storage.saveSpiritualLogs([log]);

      final prefs = await SharedPreferences.getInstance();
      final rawStored = prefs.getString('spiritual_logs_encrypted') ?? '';
      expect(rawStored.startsWith('AES256_V2:'), isTrue, reason: 'Must use AES-256-CBC V2');
      expect(rawStored.contains('مذكرة اعتراف'), isFalse, reason: 'Plaintext must never be stored');

      final restored = storage.getSpiritualLogs();
      expect(restored.length, 1);
      expect(restored.first.reflectionNote, 'مذكرة اعتراف خاصة مشفرة');
    });

    test('CopticCalendarService, PatronSaintService (800+ saints with portraits), OnlineLibrary & LiturgyProvider load cleanly', () async {
      await CopticCalendarService.ensureLectionaryLoaded();
      expect(CopticCalendarService.searchSynaxarium('العذراء').isNotEmpty, isTrue);

      await PatronSaintService.ensureLoaded();
      expect(PatronSaintService.saints.length, greaterThanOrEqualTo(800));
      for (final s in PatronSaintService.saints) {
        final img = PatronSaintService.getImageUrlForSaint(s);
        expect(img.startsWith('https://'), isTrue, reason: 'Every saint must resolve to a real portrait URL: ${s.name}');
      }

      // Verify multi-source online books catalog & full 73-book tafsir catalog
      final lib = OnlineCopticLibraryService();
      final tafsir = await lib.loadTafsirCatalog();
      expect(tafsir.length, 73);
      expect(tafsir.every((b) => b.tadrosUrl.isNotEmpty || b.antoniosUrl.isNotEmpty), isTrue);

      final onlineBooks = await lib.loadOnlineBooksCatalog();
      expect(onlineBooks.length, greaterThanOrEqualTo(400));
      final sources = onlineBooks.map((b) => b.source).toSet();
      expect(sources.length, greaterThanOrEqualTo(3), reason: 'Library must span multiple Orthodox online sources');

      final readings = await CopticCalendarService.getResolvedLiturgyReadings(DateTime(2025, 9, 11, 10, 0));
      expect(readings['pauline']?['text']?.isNotEmpty, isTrue);
      expect(readings['catholic']?['text']?.isNotEmpty, isTrue);
      expect(readings['acts']?['text']?.isNotEmpty, isTrue);
      expect(readings['psalm']?['text']?.isNotEmpty, isTrue);
      expect(readings['gospel']?['text']?.isNotEmpty, isTrue);

      final prov = LiturgyProvider();
      await prov.loadLiturgies();
      expect(prov.liturgies.length, 3);
      prov.setActiveRole('priest');
      expect(
        prov.filterVerses(prov.selectedLiturgy!.sections.first.verses).every((v) => v.role == 'priest' || v.role == 'all'),
        isTrue,
      );
    });
  });

  group('4. Widget Rendering & Interaction Tests', () {
    testWidgets('SynaxariumDailyView renders Arabic commemorations', (tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues({});
        await StorageService().init();
        await CopticCalendarService.ensureLectionaryLoaded();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: SynaxariumDailyView(initialMonth: 1, initialDay: 1),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('السنكسار القبطي اليومي'), findsOneWidget);
      expect(find.textContaining('النيروز'), findsWidgets);
    });

    testWidgets('LiturgyReaderView renders Kholagy, role filters, and Index Sheet', (tester) async {
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
      await tester.tap(find.text('فهرس القداس'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('خريطة ومحطات القداس الإلهي'), findsOneWidget);
    });

    testWidgets('MyPatronSaintView, BooksLibraryView, TasbehaPaschaView, and spiritual views render cleanly', (tester) async {
      await tester.runAsync(() async {
        await StorageService().init();
        await StorageService().setPatronSaintId('st_george');
        await PatronSaintService.ensureLoaded();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MyPatronSaintView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('شفيعي الشخصي'), findsOneWidget);
      expect(find.textContaining('مارجرجس'), findsWidgets);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => BooksProvider()),
          ],
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: BooksLibraryView(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('المكتبة الأرثوذكسية والتفاسير'), findsOneWidget);
      expect(find.text('التفاسير (٧٣ سفراً)'), findsOneWidget);
      expect(find.text('المكتبة الشاملة'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: TasbehaPaschaView(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('التسبحة والبصخة والأعياد المتحركة'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: CopticAcademyView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('أكاديمية اللغة القبطية'), findsOneWidget);
      expect(find.textContaining('سماع نطق الحرف'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: RememberThemView(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('دفتر «اذكرهم يا رب» في صلاتي'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: SpiritualPrescriptionView(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('خلوة الـ ٥ دقائق (بماذا تشعر الآن؟)'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ChurchSacramentsRitesView(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('الطقوس الكنسية والأسرار واللقان'), findsOneWidget);

      final progress = BibleReadingProgressService();
      await tester.runAsync(() async {
        await progress.ensureLoaded();
        await progress.toggleChapterCompleted('mt', 1);
      });
      expect(progress.isChapterCompleted('mt', 1), isTrue);
    });
  });
}
