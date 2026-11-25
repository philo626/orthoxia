import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orthodox_app/core/services/ai_theology_service.dart';
import 'package:orthodox_app/core/services/bible_reading_progress_service.dart';
import 'package:orthodox_app/core/services/confession_service.dart';
import 'package:orthodox_app/core/services/coptic_calendar_service.dart';
import 'package:orthodox_app/core/services/coptic_fast_service.dart';
import 'package:orthodox_app/core/services/coptic_youtube_registry.dart';
import 'package:orthodox_app/core/services/encryption_service.dart';
import 'package:orthodox_app/core/services/multiplayer_trivia_service.dart';
import 'package:orthodox_app/core/services/notification_service.dart';
import 'package:orthodox_app/core/services/online_coptic_library_service.dart';
import 'package:orthodox_app/core/services/patron_saint_service.dart';
import 'package:orthodox_app/core/services/reading_state_service.dart';
import 'package:orthodox_app/core/services/security_guard_service.dart';
import 'package:orthodox_app/core/services/speech_pronunciation_service.dart';
import 'package:orthodox_app/core/services/storage_service.dart';
import 'package:orthodox_app/core/theme/app_palette.dart';
import 'package:orthodox_app/core/theme/app_theme.dart';
import 'package:orthodox_app/core/widgets/priest_qr_poster_sheet.dart';
import 'package:orthodox_app/models/confession_models.dart';
import 'package:orthodox_app/models/spiritual_tracker_model.dart';
import 'package:orthodox_app/providers/ai_companion_provider.dart';
import 'package:orthodox_app/providers/audio_provider.dart';
import 'package:orthodox_app/providers/bible_provider.dart';
import 'package:orthodox_app/providers/books_provider.dart';
import 'package:orthodox_app/providers/church_mode_provider.dart';
import 'package:orthodox_app/providers/liturgy_provider.dart';
import 'package:orthodox_app/providers/spiritual_tracker_provider.dart';
import 'package:orthodox_app/providers/theme_provider.dart';
import 'package:orthodox_app/views/ai_companion/ai_companion_view.dart';
import 'package:orthodox_app/views/books/books_library_view.dart';
import 'package:orthodox_app/views/community/online_trivia_arena_view.dart';
import 'package:orthodox_app/views/confession/admin_priest_review_view.dart';
import 'package:orthodox_app/views/confession/fathers_directory_view.dart';
import 'package:orthodox_app/views/confession/my_father_schedule_view.dart';
import 'package:orthodox_app/views/confession/priest_dashboard_view.dart';
import 'package:orthodox_app/views/coptic_academy/coptic_academy_view.dart';
import 'package:orthodox_app/views/home/spiritual_prescription_view.dart';
import 'package:orthodox_app/views/liturgical/church_sacraments_rites_view.dart';
import 'package:orthodox_app/views/liturgical/fractions_library_view.dart';
import 'package:orthodox_app/views/liturgical/raising_of_incense_view.dart';
import 'package:orthodox_app/views/liturgical/remember_them_view.dart';
import 'package:orthodox_app/views/liturgical/tasbeha_pascha_view.dart';
import 'package:orthodox_app/views/liturgies/liturgy_reader_view.dart';
import 'package:orthodox_app/views/onboarding/auth_view.dart';
import 'package:orthodox_app/views/priest/priest_altar_hub_view.dart';
import 'package:orthodox_app/views/priest/priest_navigation_shell.dart';
import 'package:orthodox_app/views/priest/priest_pastoral_care_view.dart';
import 'package:orthodox_app/views/spiritual_tracker/communion_readiness_view.dart';
import 'package:orthodox_app/views/synaxarium/my_patron_saint_view.dart';
import 'package:orthodox_app/views/treasures/sermons_library_view.dart';
import 'package:orthodox_app/views/synaxarium/synaxarium_daily_view.dart';
import 'package:orthodox_app/views/treasures/church_history_view.dart';
import 'package:orthodox_app/views/treasures/liturgical_encyclopedia_view.dart';
import 'package:orthodox_app/views/treasures/madayeh_library_view.dart';
import 'package:orthodox_app/views/treasures/patristic_sayings_view.dart';
import 'package:orthodox_app/views/treasures/service_notebook_view.dart';

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

    test('All 338+ hymns have 100% unique 1-to-1 audio URLs and verified YouTube IDs (zero duplicates or mismatches)', () {
      final hymns = jsonDecode(File('assets/data/hymns.json').readAsStringSync()) as List;
      expect(hymns.length, greaterThanOrEqualTo(338));
      final deadIds = {'3_p4J6p-gV4', 'n0YqZ7Ld3K0', 'o3N_uTz9h44', 'sW8p1q6tV5U'};
      final audioUrls = <String>{};
      final youtubeIds = <String>{};
      final titles = <String>{};
      for (final h in hymns) {
        final yid = '${h['youtube_id'] ?? ''}';
        final aurl = '${h['audio_url'] ?? ''}';
        final title = '${h['title'] ?? ''}';
        expect(yid.isNotEmpty, isTrue);
        expect(aurl.startsWith('http'), isTrue);
        expect(deadIds.contains(yid), isFalse, reason: 'Dead YouTube ID found: $yid');
        expect(titles.add(title), isTrue, reason: 'Duplicate hymn title found: $title');
        for (final v in (h['verses'] as List? ?? [])) {
          expect('${v['coptic'] ?? ''}'.contains('\xad'), isFalse, reason: 'Soft hyphen artifact in $title');
        }
        audioUrls.add(aurl);
        youtubeIds.add(yid);
      }
      expect(audioUrls.length, hymns.length, reason: 'Every hymn must have its own unique 1-to-1 audio URL');
      expect(youtubeIds.length, greaterThanOrEqualTo(250), reason: 'Hymns must map to specific YouTube video IDs');
      expect(CopticYouTubeRegistry.resolveVideoId(hymnId: 'tai-shori', title: 'طاي شوري'), 'RIRb2ED0qvE');
      expect(CopticYouTubeRegistry.resolveVideoId(hymnId: 'golgotha', title: 'غولغوثا'), '6iuEVnKP7rU');
    });

    test('Authentic Agpeya (all 8 hours, zero truncations, distinct Ps 114/115 & 146/147, 3 Midnight watches) & rich offline Books', () {
      final agpeya = jsonDecode(File('assets/data/agpeya.json').readAsStringSync()) as List;
      expect(agpeya.length, 8);
      String? ps114;
      String? ps115;
      String? ps146;
      String? ps147;
      for (final hour in agpeya) {
        final secs = hour['sections'] as List;
        expect(secs.length, greaterThanOrEqualTo(6));
        for (final sec in secs) {
          final title = '${sec['title'] ?? ''}';
          final content = '${sec['content'] ?? ''}';
          expect(
            content.trim().isNotEmpty,
            isTrue,
            reason: 'Empty section in ${hour['id']}: $title',
          );
          expect(content.contains('...'), isFalse, reason: 'Truncated prayer in ${hour['id']}: $title');
          if (title == 'المزمور 114') ps114 = content;
          if (title == 'المزمور 115') ps115 = content;
          if (title == 'المزمور 146') ps146 = content;
          if (title == 'المزمور 147') ps147 = content;
        }
      }
      expect(ps114, isNotNull);
      expect(ps115, isNotNull);
      expect(ps114, isNot(equals(ps115)));
      expect(ps146, isNotNull);
      expect(ps147, isNotNull);
      expect(ps146, isNot(equals(ps147)));

      final midnight = agpeya.firstWhere((h) => h['id'] == 'midnight');
      final midnightTitles = (midnight['sections'] as List).map((s) => '${s['title']}').join('\n');
      expect(midnightTitles.contains('الخدمة الأولى'), isTrue);
      expect(midnightTitles.contains('الخدمة الثانية'), isTrue);
      expect(midnightTitles.contains('الخدمة الثالثة'), isTrue);

      final books = jsonDecode(File('assets/data/books.json').readAsStringSync()) as List;
      expect(books.length, greaterThanOrEqualTo(12));
      for (final b in books) {
        final chapters = b['chapters'] as List;
        expect(chapters.isNotEmpty, isTrue);
        final totalLen = chapters.fold<int>(0, (sum, c) => sum + '${c['content'] ?? ''}'.length);
        expect(totalLen, greaterThanOrEqualTo(800), reason: 'Book too short/stub: ${b['title']}');
      }
    });
  });

  group('3. AES-256-GCM AEAD Security, Guards, User Name & Notifications', () {
    test('StorageService uses authenticated AES-256-GCM V3 with tamper detection & encrypted Diptych', () async {
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
      expect(rawStored.startsWith('AES256_GCM_V3:'), isTrue, reason: 'Must use authenticated AES-256-GCM V3');
      expect(rawStored.contains('مذكرة اعتراف'), isFalse, reason: 'Plaintext must never be stored');

      final restored = storage.getSpiritualLogs();
      expect(restored.length, 1);
      expect(restored.first.reflectionNote, 'مذكرة اعتراف خاصة مشفرة');

      // Verify AES-256-GCM cryptographic tamper detection (bit flip MUST throw!)
      final parts = rawStored.split(':');
      expect(parts.length, 3);
      final cipherBytes = base64Decode(parts[2]);
      cipherBytes[0] ^= 0xFF;
      final tampered = '${parts[0]}:${parts[1]}:${base64Encode(cipherBytes)}';
      expect(() => EncryptionService().decryptAes256(tampered), throwsA(anything));

      // Verify Diptych ("دفتر اذكرهم يا رب") is stored encrypted at rest
      await storage.saveEncryptedDiptychJson('{"family":["مارينا","كيرلس"]}');
      final rawDiptych = prefs.getString('remember_them_diptych_v1') ?? '';
      expect(rawDiptych.startsWith('AES256_GCM_V3:'), isTrue);
      expect(rawDiptych.contains('مارينا'), isFalse);
      expect(storage.getEncryptedDiptychJson(), '{"family":["مارينا","كيرلس"]}');
    });

    test('SecurityGuardService enforces HTTPS/Anti-SSRF, host allowlist, sanitization, strong passwords, and rate limiting', () {
      // 1. Safe external URL checks (HTTPS-only + Anti-SSRF)
      expect(SecurityGuardService.isSafeExternalUrl('https://archive.org/details/coptic'), isTrue);
      expect(SecurityGuardService.isSafeExternalUrl('http://archive.org/details/coptic'), isFalse);
      expect(SecurityGuardService.isSafeExternalUrl('javascript:alert(1)'), isFalse);
      expect(SecurityGuardService.isSafeExternalUrl('file:///etc/passwd'), isFalse);
      expect(SecurityGuardService.isSafeExternalUrl('https://127.0.0.1/admin'), isFalse);
      expect(SecurityGuardService.isSafeExternalUrl('https://localhost/secret'), isFalse);
      expect(SecurityGuardService.isSafeExternalUrl('https://192.168.1.1/router'), isFalse);
      expect(SecurityGuardService.isSafeExternalUrl('https://10.0.0.5/internal'), isFalse);

      // 2. Trusted Orthodox digital library allowlist
      expect(SecurityGuardService.isTrustedLibraryUrl('https://st-takla.org/books.html'), isTrue);
      expect(SecurityGuardService.isTrustedLibraryUrl('https://christianlib.com/book/1'), isTrue);
      expect(SecurityGuardService.isTrustedLibraryUrl('https://evil.example.com/phish'), isFalse);

      // 3. Text sanitization (anti-HTML/XSS & BiDi spoofing + max length)
      final clean = SecurityGuardService.sanitizeText(
        'صلاة \u202E<script>alert(1)</script>من أجل السلام',
        maxLength: 25,
        allowNewlines: false,
      );
      expect(clean.contains('<script>'), isFalse);
      expect(clean.contains('\u202E'), isFalse);
      expect(clean.length, lessThanOrEqualTo(25));

      // 4. Strong password validation
      expect(SecurityGuardService.validateNewPassword('123456'), isNotNull);
      expect(SecurityGuardService.validateNewPassword('abcdefgh'), isNotNull);
      expect(SecurityGuardService.validateNewPassword('12345678'), isNotNull);
      expect(SecurityGuardService.validateNewPassword('Orthodox2026'), isNull);

      // 5. Rate limiter blocks rapid spam
      final guard = SecurityGuardService();
      expect(guard.allowAction('test_bucket_sec', cooldown: const Duration(seconds: 5), maxPerWindow: 2), isTrue);
      expect(guard.allowAction('test_bucket_sec', cooldown: const Duration(seconds: 5), maxPerWindow: 2), isFalse);

      // 6. Verify Android & Firebase hardening config files exist and enforce invariants
      final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest.contains('android:allowBackup="false"'), isTrue);
      expect(manifest.contains('android:usesCleartextTraffic="false"'), isTrue);
      expect(manifest.contains('network_security_config'), isTrue);
      expect(File('android/app/src/main/res/xml/network_security_config.xml').existsSync(), isTrue);
      expect(File('android/app/proguard-rules.pro').existsSync(), isTrue);
      expect(File('firestore.rules').existsSync(), isTrue);
    });

    test('CopticCalendarService, PatronSaintService (800+ saints with portraits), OnlineLibrary & LiturgyProvider load cleanly', () async {
      await CopticCalendarService.ensureLectionaryLoaded();
      expect(CopticCalendarService.searchSynaxarium('العذراء').isNotEmpty, isTrue);

      await PatronSaintService.ensureLoaded();
      expect(PatronSaintService.saints.length, greaterThanOrEqualTo(800));
      for (final s in PatronSaintService.saints) {
        final img = PatronSaintService.getImageUrlForSaint(s);
        expect(
          img.startsWith('https://') || img.startsWith('assets/'),
          isTrue,
          reason: 'Every saint must resolve to a bundled Neo-Coptic icon or HTTPS portrait: ${s.name}',
        );
      }
      expect(
        PatronSaintService.getImageUrlForSaint(PatronSaintService.getSaintById('virgin_mary')),
        startsWith('assets/images/saints/'),
      );

      // Verify ReadingStateService (resume + favorite verses) and real SpiritualTrackerProvider 7-day logs
      SharedPreferences.setMockInitialValues({});
      await StorageService().init();
      final readingState = ReadingStateService();
      await readingState.saveLastBible(bookAbbrev: 'jn', bookName: 'إنجيل يوحنا', chapter: 3);
      expect(readingState.lastBible?['abbrev'], 'jn');
      expect(readingState.lastBible?['chapter'], 3);
      await readingState.toggleFavoriteVerse(
        FavoriteVerse(
          bookAbbrev: 'jn',
          bookName: 'إنجيل يوحنا',
          chapter: 3,
          verse: 16,
          text: 'لأَنَّهُ هكَذَا أَحَبَّ اللهُ الْعَالَمَ',
          savedAt: DateTime.now(),
        ),
      );
      expect(readingState.isVerseFavorited('jn', 3, 16), isTrue);

      await StorageService().saveSpiritualLogs([]);
      final tracker = SpiritualTrackerProvider();
      expect(tracker.last7DaysLogs.length, 7);
      // Zero fake data: before user logs anything, past 6 days are strictly 0
      expect(
        tracker.last7DaysLogs.take(6).every((l) => l.bibleChaptersRead == 0 && l.agpeyaHoursCompleted == 0),
        isTrue,
      );
      tracker.incrementBibleChapters();
      expect(tracker.last7DaysLogs.last.bibleChaptersRead, 1);

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
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: TasbehaPaschaView(),
            ),
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
      expect(find.text('خلوة هادئة لقلبك'), findsOneWidget);

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: ChurchSacramentsRitesView(),
            ),
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

    testWidgets('Redesigned AuthView & Adaptive Parchment/Dark Themes render cleanly without developer jargon', (tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues({});
        await StorageService().init();
        await PatronSaintService.ensureLoaded();
      });

      final lightTheme = AppTheme.getTheme(AppThemeMode.lightParchment);
      final darkTheme = AppTheme.getTheme(AppThemeMode.darkGold);
      expect(lightTheme.extension<AppPalette>()?.isDark, isFalse);
      expect(darkTheme.extension<AppPalette>()?.isDark, isTrue);

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
          child: MaterialApp(
            theme: lightTheme,
            home: const Directionality(
              textDirection: TextDirection.rtl,
              child: AuthView(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('المتابعة بحساب Google'), findsOneWidget);
      expect(find.text('نسيت كلمة المرور؟'), findsOneWidget);
      expect(find.text('برقم الهاتف'), findsNothing);
      expect(find.textContaining('Firebase'), findsNothing);
      expect(find.textContaining('AES-256'), findsNothing);

      // Step 2: Tap Guest to verify smooth personalization transition
      await tester.ensureVisible(find.text('كمّل كزائر من غير تسجيل'));
      await tester.tap(find.text('كمّل كزائر من غير تسجيل'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('اختر شفيعك الشخصي'), findsOneWidget);
    });

    test('Windows-1256 Tafsir decoder, Complete Tasbeha/Pascha/Rites JSON, and Multi-Provider AI API config', () {
      // 1. Verify Windows-1256 Arabic decoding (root fix for st-takla.org "***" bug!)
      // "تفسير" in CP1256 = [0xCA, 0xDD, 0xD3, 0xED, 0xD1]
      final decoded = OnlineCopticLibraryService.decodeWindows1256(
        Uint8List.fromList([0xCA, 0xDD, 0xD3, 0xED, 0xD1]),
      );
      expect(decoded, 'تفسير');
      expect(decoded.contains('\uFFFD'), isFalse);

      // 2. Verify Complete Tasbeha (12 parts), 7-Day Pascha, and 18 Fixed Feasts
      final tp = jsonDecode(File('assets/data/tasbeha_pascha_complete.json').readAsStringSync()) as Map<String, dynamic>;
      final tasbeha = tp['tasbeha'] as List;
      final pascha = tp['pascha_days'] as List;
      final feasts = tp['fixed_feasts'] as List;
      expect(tasbeha.length, 12);
      expect(pascha.length, 7);
      expect(feasts.length, 18);
      final stripDiacritics = RegExp(r'[\u064B-\u065F\u0670]');
      final hoos1 = tasbeha.firstWhere((s) => s['id'] == 'hoos_1');
      expect('${hoos1['arabic']}'.replaceAll(stripDiacritics, ''), contains('أرنم للرب'));
      final hoos2 = tasbeha.firstWhere((s) => s['id'] == 'hoos_2');
      expect('${hoos2['arabic']}'.replaceAll(stripDiacritics, ''), contains('لأن إلى الأبد رحمته'));

      // 3. Verify Complete 8 Church Sacraments & Rites
      final rites = jsonDecode(File('assets/data/sacraments_rites_complete.json').readAsStringSync()) as List;
      expect(rites.length, 8);
      final totalSections = rites.fold<int>(0, (sum, r) => sum + ((r['sections'] as List).length));
      expect(totalSections, greaterThanOrEqualTo(25));

      // 4. Verify Real Multi-Provider AI API Config (Gemini / Groq / Custom Proxy)
      const emptyCfg = AiApiConfig();
      expect(emptyCfg.isConfigured, isFalse);
      const geminiCfg = AiApiConfig(provider: AiProviderType.gemini, apiKey: 'AIzaTestKey1234567890');
      expect(geminiCfg.isConfigured, isTrue);
      expect(geminiCfg.providerDisplayName, contains('Gemini'));
      const groqCfg = AiApiConfig(provider: AiProviderType.groq, apiKey: 'gsk_TestKey1234567890');
      expect(groqCfg.isConfigured, isTrue);
      expect(groqCfg.providerDisplayName, contains('Groq'));

      // 5. Verify ALL new Orsozoxi-caliber Encyclopedic JSON Datasets
      final incense = jsonDecode(File('assets/data/raising_of_incense.json').readAsStringSync()) as Map<String, dynamic>;
      expect((incense['sections'] as List).length, greaterThanOrEqualTo(14));

      final otherPrayers = jsonDecode(File('assets/data/other_prayers.json').readAsStringSync()) as List;
      expect(otherPrayers.length, greaterThanOrEqualTo(10));

      expect((tp['kiahk_tasbeha'] as List).length, greaterThanOrEqualTo(8));
      expect((tp['seasonal_doxologies'] as List).length, greaterThanOrEqualTo(16));

      final encyc = jsonDecode(File('assets/data/liturgical_rites_encyclopedia.json').readAsStringSync()) as List;
      expect(encyc.length, 18);

      final madayeh = jsonDecode(File('assets/data/madayeh_tamagid.json').readAsStringSync()) as List;
      expect(madayeh.length, greaterThanOrEqualTo(22));

      final sayings = jsonDecode(File('assets/data/patristic_sayings.json').readAsStringSync()) as List;
      expect(sayings.length, greaterThanOrEqualTo(50));
    });

    testWidgets('Clean Patristic Chatbot (zero API/connected badges) & All New Church Treasures render cleanly', (tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues({});
        await StorageService().init();
      });

      // 1. Clean Chatbot View — MUST NOT expose API / متصل / سحابة jargon!
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => AiCompanionProvider()),
          ],
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: AiCompanionView(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('المرشد الآبائي'), findsOneWidget);
      expect(find.textContaining('API'), findsNothing);
      expect(find.text('متصل'), findsNothing);
      expect(find.textContaining('سحابة'), findsNothing);

      // 2. Render all 7 brand-new church treasure & liturgical screens cleanly
      final newScreens = <Widget>[
        const RaisingOfIncenseView(),
        const FractionsLibraryView(),
        const LiturgicalEncyclopediaView(),
        const MadayehLibraryView(),
        const PatristicSayingsView(),
        const ChurchHistoryView(),
        const ServiceNotebookView(),
      ];

      for (final screen in newScreens) {
        await tester.pumpWidget(
          MultiProvider(
            providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
            child: MaterialApp(
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: screen,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(Scaffold), findsOneWidget);
      }
    });

    test('Complete Verbatim Psalmody/Pascha/Sacraments, 200+ Visual Page Books & Audited 73-Book Tafsir', () {
      // 1. Complete Verbatim Tasbeha, Weekdays, Kiahk, Doxologies & 7-Day Pascha
      final tp = jsonDecode(File('assets/data/tasbeha_pascha_complete.json').readAsStringSync())
          as Map<String, dynamic>;
      expect((tp['weekday_tasbeha'] as List).length, greaterThanOrEqualTo(20));
      expect((tp['kiahk_tasbeha'] as List).length, greaterThanOrEqualTo(40));
      expect((tp['seasonal_doxologies'] as List).length, greaterThanOrEqualTo(70));
      final paschaDays = tp['pascha_days'] as List;
      expect(paschaDays.length, 7);
      int totalPaschaHours = 0;
      int totalPaschaChars = 0;
      for (final d in paschaDays) {
        final secs = d['sections'] as List;
        totalPaschaHours += secs.length;
        for (final s in secs) {
          totalPaschaChars += '${s['text'] ?? s['arabic'] ?? ''}'.length;
        }
      }
      expect(totalPaschaHours, greaterThanOrEqualTo(95));
      expect(totalPaschaChars, greaterThanOrEqualTo(250000));

      // 2. Complete Verbatim Sacraments & Rites (Qandil 7 prayers, Matrimony, Sagda, Lakkan, Baptism, Funeral)
      final rites = jsonDecode(File('assets/data/sacraments_rites_complete.json').readAsStringSync()) as List;
      expect(rites.length, 8);
      final totalRiteSections = rites.fold<int>(0, (s, r) => s + (r['sections'] as List).length);
      expect(totalRiteSections, greaterThanOrEqualTo(140));
      final qandil = rites.firstWhere((r) => r['id'] == 'unction_sick');
      expect((qandil['sections'] as List).length, greaterThanOrEqualTo(35));
      final matrimony = rites.firstWhere((r) => r['id'] == 'matrimony');
      expect((matrimony['sections'] as List).length, greaterThanOrEqualTo(30));

      // 3. Real Visual Page-by-Page Orthodox Books Catalog (200+ strictly vetted visual books, zero polemics)
      final books = jsonDecode(File('assets/data/online_books_catalog.json').readAsStringSync()) as List;
      final visualBooks = books.where((b) => b['readerType'] == 'visual_pages').toList();
      expect(visualBooks.length, greaterThanOrEqualTo(200));
      expect(visualBooks.every((b) => '${b['embedUrl'] ?? ''}'.startsWith('https://archive.org/embed/')), isTrue);
      expect(visualBooks.any((b) => '${b['title']}'.contains('أبو المنتصر')), isFalse);

      // 4. Audited 73-Book Tafsir Catalog with exact Deuterocanonical chapter counts
      final tafsir = jsonDecode(File('assets/data/tafsir_catalog.json').readAsStringSync()) as List;
      expect(tafsir.length, 73);
      final tobit = tafsir.firstWhere((t) => t['name'] == 'طوبيا');
      expect(tobit['chaptersCount'], 14);
      final sirach = tafsir.firstWhere((t) => t['name'] == 'يشوع بن سيراخ');
      expect(sirach['chaptersCount'], 51);
    });

    testWidgets('Animated Christ AuthView, Dual-Code Trust, Dedicated Priest Shell & Pastoral Care render cleanly', (tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues({});
        await StorageService().init();
        await PatronSaintService.ensureLoaded();
      });

      // 0. Dual-Code normalization + Bohairic Coptic phonetic transliteration + MediaService registration
      expect(ConfessionService.normalizeCode('ab4829', defaultPrefix: 'AB'), 'AB-4829');
      expect(ConfessionService.normalizeCode('٤٨٢٩', defaultPrefix: 'AB'), 'AB-4829');
      expect(ConfessionService.normalizeCode('kn 7391', defaultPrefix: 'KN'), 'KN-7391');

      final spokenCoptic = CopticPhoneticEngine.prepareForSpeech('Ⲡⲓⲭ̀ⲣⲓⲥⲧⲟⲥ Ⲑⲉⲟ̀ⲧⲟⲕⲟⲥ Ⲁ̀ⲙⲏⲛ');
      expect(spokenCoptic.contains('إِخْرِيسْتُوس'), isTrue);
      expect(spokenCoptic.contains('ثِيئُوطُوكُوس'), isTrue);
      expect(spokenCoptic.contains('آمِين'), isTrue);
      expect(RegExp(r'[\u2C80-\u2CFF\u03E2-\u03EF]').hasMatch(spokenCoptic), isFalse);

      final manifestXml = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifestXml.contains('HymnMediaService'), isTrue);
      expect(manifestXml.contains('FOREGROUND_SERVICE_MEDIA_PLAYBACK'), isTrue);

      // Verify end-time range formatting, multi-priest group invite, and playful 2-part name banter
      final sWithEnd = ConfessionSession.fromMap('s1', {
        'priestUid': 'p1',
        'priestName': 'القس بولس',
        'church': 'كنيسة العذراء',
        'diocese': 'القاهرة',
        'dateIso': '2026-11-27',
        'dayLabelAr': 'الجمعة ٢٧ نوفمبر',
        'startTimeAr': '4:00 مساءً',
        'endTimeAr': '6:00 مساءً',
        'isOpen': true,
        'confirmedCount': 0,
        'waitlistCount': 0,
      });
      expect(sWithEnd.timeRangeLabelAr, 'من 4:00 مساءً لغاية 6:00 مساءً');

      final groupInvite = PriestVouchInvite.fromMap('KN-4829', {
        'issuerUid': 'p1',
        'issuerName': 'القمص يوحنا',
        'issuerChurch': 'كنيسة مارجرجس',
        'used': false,
        'maxUses': 5,
        'usedCount': 2,
        'usedByUids': ['p2', 'p3'],
        'usedByNames': ['القس مينا', 'القس بطرس'],
      });
      expect(groupInvite.remainingUses, 3);
      expect(groupInvite.isFullyUsed, isFalse);

      final singleNameJoke = ConfessionNameValidator.validateTwoPartName('مينا');
      expect(singleNameJoke, isNotNull);
      expect(singleNameJoke!.contains('😂'), isTrue);
      expect(singleNameJoke.contains('مميز'), isTrue);
      expect(ConfessionNameValidator.validateTwoPartName('مينا جرجس'), isNull);

      // 1. Animated Christ AuthView role cards switch cleanly to Priest Mode
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => ChurchModeProvider()),
          ],
          child: const MaterialApp(
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: AuthView(),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('فرد من الشعب'), findsOneWidget);
      expect(find.text('أب كاهن'), findsOneWidget);
      await tester.tap(find.text('أب كاهن'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('سلام ونعمة يا قدس أبونا'), findsOneWidget);

      // 2. Render dedicated Priest Shell + Sanctuary Altar + Pastoral Care + Confession screens
      final priestAndConfessionScreens = <Widget>[
        const PriestNavigationShell(),
        const PriestAltarHubView(),
        const PriestPastoralCareView(),
        const FathersDirectoryView(),
        const MyFatherScheduleView(),
        const PriestDashboardView(),
        const AdminPriestReviewView(),
      ];

      for (final screen in priestAndConfessionScreens) {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider(create: (_) => ChurchModeProvider()),
              ChangeNotifierProvider(create: (_) => LiturgyProvider()),
              ChangeNotifierProvider(create: (_) => BibleProvider()),
              ChangeNotifierProvider(create: (_) => BooksProvider()),
            ],
            child: MaterialApp(
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: screen,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(Scaffold), findsWidgets);
      }

      // 3. Verify ISO PureQrMatrix, Audio Sermons Catalog (70+), Expanded Trivia (60+), Multiplayer Room & New Screens!
      final qr = PureQrMatrix.encode('https://github.com/philo626/orthoxia#code=AB-4829');
      expect(qr.size, greaterThanOrEqualTo(29));
      expect(qr.modules[0][0], isTrue); // Top-left finder corner
      expect(qr.modules[0][qr.size - 1], isTrue); // Top-right finder corner
      expect(qr.modules[qr.size - 1][0], isTrue); // Bottom-left finder corner

      final sermons = jsonDecode(File('assets/data/sermons_library.json').readAsStringSync()) as List;
      expect(sermons.length, greaterThanOrEqualTo(70));
      expect(sermons.every((s) => '${s['audio_url']}'.startsWith('https://')), isTrue);

      final triviaJson = jsonDecode(File('assets/data/trivia.json').readAsStringSync()) as Map<String, dynamic>;
      expect((triviaJson['questions'] as List).length, greaterThanOrEqualTo(60));

      expect(MultiplayerTriviaService.normalizeRoomCode('or4829'), 'OR-4829');
      expect(MultiplayerTriviaService.normalizeRoomCode('٤٨٢٩'), 'OR-4829');
      final dailyA = MultiplayerTriviaService.dailyQuestionIndices(60, count: 10, date: DateTime(2026, 11, 25));
      final dailyB = MultiplayerTriviaService.dailyQuestionIndices(60, count: 10, date: DateTime(2026, 11, 25));
      expect(dailyA, equals(dailyB));
      expect(dailyA.length, 10);

      for (final screen in const <Widget>[
        CommunionReadinessView(),
        SermonsLibraryView(),
        OnlineTriviaArenaView(),
      ]) {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ThemeProvider()),
              ChangeNotifierProvider(create: (_) => AudioProvider()),
            ],
            child: MaterialApp(
              home: Directionality(
                textDirection: TextDirection.rtl,
                child: screen,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.byType(Scaffold), findsWidgets);
      }
    });
  });
}
