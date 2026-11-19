import 'dart:convert';
import 'package:flutter/services.dart';

class CopticDate {
  final int day;
  final int month; // 1..13
  final int year; // Anno Martyrum (AM)
  final String monthName;
  final String seasonName;
  final String fastingNote;

  CopticDate({
    required this.day,
    required this.month,
    required this.year,
    required this.monthName,
    required this.seasonName,
    required this.fastingNote,
  });

  String get formatted => '$day $monthName $year ش';
}

class CopticCalendarService {
  static const List<String> copticMonths = [
    'توت',      // 1
    'بابه',     // 2
    'هاتور',    // 3
    'كيهك',     // 4
    'طوبة',     // 5
    'أمشير',    // 6
    'برمهات',   // 7
    'برمودة',   // 8
    'بشنس',     // 9
    'بؤونة',    // 10
    'أبيب',     // 11
    'مسرى',     // 12
    'النسيء',   // 13
  ];

  static Map<String, dynamic>? _lectionaryData;
  static Map<String, dynamic>? _synaxariumArabicData;
  static List<dynamic>? _bibleRawCache;

  /// In the Coptic Orthodox Church, the new liturgical day begins at Vespers (5:00 PM / 17:00).
  /// When the current local time reaches 5:00 PM, both the Synaxarium and Liturgy readings
  /// automatically advance to the next liturgical day.
  static bool isAfterVespers([DateTime? now]) => (now ?? DateTime.now()).hour >= 17;

  static DateTime effectiveLiturgicalDate([DateTime? now]) {
    final dt = now ?? DateTime.now();
    final base = DateTime(dt.year, dt.month, dt.day);
    return dt.hour >= 17 ? base.add(const Duration(days: 1)) : base;
  }

  /// Returns today's active Coptic liturgical date (automatically advances at 5:00 PM Vespers).
  static CopticDate todayLiturgical([DateTime? now]) =>
      fromGregorian(effectiveLiturgicalDate(now));

  /// Preload both the authentic Coptic lectionary & the complete 366-day Arabic Synaxarium
  static Future<void> ensureLectionaryLoaded() async {
    if (_lectionaryData != null && _synaxariumArabicData != null) return;
    try {
      if (_lectionaryData == null) {
        final raw = await rootBundle.loadString('assets/data/coptic_lectionary.json');
        _lectionaryData = jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (_) {}

    try {
      if (_synaxariumArabicData == null) {
        final rawSyn = await rootBundle.loadString('assets/data/synaxarium_ar.json');
        _synaxariumArabicData = jsonDecode(rawSyn) as Map<String, dynamic>;
      }
    } catch (_) {}
  }

  /// Resolves the FULL vocalized Smith & Van Dyck Arabic text for today's Liturgy of the Word
  /// readings (Pauline, Catholic, Acts, Psalm, Gospel) using the 5:00 PM Vespers liturgical clock.
  static Future<Map<String, Map<String, String>>> getResolvedLiturgyReadings([DateTime? now]) async {
    await ensureLectionaryLoaded();
    if (_bibleRawCache == null) {
      try {
        final rawBible = await rootBundle.loadString('assets/data/bible.json');
        _bibleRawCache = jsonDecode(rawBible) as List<dynamic>;
      } catch (_) {
        _bibleRawCache = [];
      }
    }

    final cDate = todayLiturgical(now);
    final blueprint = getDailyReadingsBlueprint(cDate.month, cDate.day);
    final result = <String, Map<String, String>>{};

    for (final item in blueprint) {
      final type = item['type'] ?? '';
      final bookName = item['book'] ?? '';
      final chNum = int.tryParse(item['chapter'] ?? '1') ?? 1;
      final verseSpec = item['verses'] ?? '1-10';
      final refLabel = (item['full_ref'] != null && item['full_ref']!.isNotEmpty)
          ? item['full_ref']!
          : '$bookName ($chNum: $verseSpec)';

      final versesText = _extractBiblePassage(bookName, chNum, verseSpec);
      final key = switch (type) {
        'البولس' => 'pauline',
        'الكاثوليكون' => 'catholic',
        'الإبركسيس' => 'acts',
        'المزمور' => 'psalm',
        'الإنجيل' => 'gospel',
        _ => '',
      };
      if (key.isNotEmpty) {
        result[key] = {
          'type': type,
          'book': bookName,
          'ref': refLabel,
          'text': versesText,
        };
      }
    }
    return result;
  }

  static String _extractBiblePassage(String bookName, int chapterNum, String verseSpec) {
    final books = _bibleRawCache;
    if (books == null || books.isEmpty) return '';

    Map<String, dynamic>? matchedBook;
    for (final raw in books) {
      final b = raw as Map<String, dynamic>;
      final name = (b['name'] ?? '').toString();
      if (name == bookName || name.contains(bookName) || bookName.contains(name)) {
        matchedBook = b;
        break;
      }
    }
    if (matchedBook == null) return '';

    final chapters = matchedBook['chapters'] as List<dynamic>? ?? [];
    if (chapters.isEmpty) return '';
    final chIdx = (chapterNum - 1).clamp(0, chapters.length - 1);
    final verses = chapters[chIdx] as List<dynamic>? ?? [];
    if (verses.isEmpty) return '';

    final rangeMatch = RegExp(r'(\d+)\s*-\s*(\d+)').firstMatch(verseSpec);
    int startV = 1;
    int endV = verses.length;
    if (rangeMatch != null) {
      startV = int.tryParse(rangeMatch.group(1)!) ?? 1;
      endV = int.tryParse(rangeMatch.group(2)!) ?? verses.length;
    } else {
      final single = int.tryParse(verseSpec.replaceAll(RegExp(r'[^0-9]'), ''));
      if (single != null && single > 0) {
        startV = single;
        endV = single;
      }
    }

    final safeStart = (startV - 1).clamp(0, verses.length - 1);
    final safeEnd = (endV - 1).clamp(safeStart, verses.length - 1);
    final buf = StringBuffer();
    for (int i = safeStart; i <= safeEnd; i++) {
      final vText = verses[i].toString().trim();
      if (vText.isEmpty) continue;
      buf.write('$vText (${i + 1}) ');
    }
    return buf.toString().trim();
  }

  static CopticDate fromGregorian(DateTime date) {
    final gYear = date.year;
    final isNextGregorianLeap = ((gYear + 1) % 4 == 0 && (gYear + 1) % 100 != 0) || ((gYear + 1) % 400 == 0);
    final newYearDay = isNextGregorianLeap ? 12 : 11;
    final copticNewYear = DateTime(gYear, 9, newYearDay);

    int copticYear;
    DateTime startOfCopticYear;

    if (!date.isBefore(copticNewYear)) {
      copticYear = gYear - 283;
      startOfCopticYear = copticNewYear;
    } else {
      copticYear = gYear - 284;
      final isCurrentGregorianLeap = (gYear % 4 == 0 && gYear % 100 != 0) || (gYear % 400 == 0);
      startOfCopticYear = DateTime(gYear - 1, 9, isCurrentGregorianLeap ? 12 : 11);
    }

    final diffDays = date.difference(startOfCopticYear).inDays;
    final cMonth = (diffDays ~/ 30) + 1;
    final cDay = (diffDays % 30) + 1;

    final safeMonth = cMonth.clamp(1, 13);
    final monthName = copticMonths[safeMonth - 1];

    return CopticDate(
      day: cDay,
      month: safeMonth,
      year: copticYear,
      monthName: monthName,
      seasonName: getSeasonName(safeMonth, cDay),
      fastingNote: getFastingNote(safeMonth, cDay, date.weekday),
    );
  }

  static String getSeasonName(int month, int day) {
    if (month == 1 && day <= 16) return 'فترة النيروز وعيد الشهداء';
    if (month == 1 && day >= 17 && day <= 19) return 'عيد الصليب المجيد';
    if (month == 3 && day >= 16) return 'صوم الميلاد المجيد';
    if (month == 4) return 'الشهر المريمي (تسبحة كيهك "٧ و٤")';
    if (month == 5 && day <= 13) return 'فترة أعياد الميلاد والغطاس وعرس قانا الجليل';
    if (month == 7 || month == 8) return 'رحلة الصوم الكبير والقيامة';
    if (month == 9) return 'فترة الخماسين المقدسة';
    if (month == 10 || (month == 11 && day <= 5)) return 'فترة صوم الآباء الرسل';
    if (month == 12 && day <= 16) return 'صوم وإعلان صعود جسد السيدة العذراء';
    return 'الطقس السنوي المعتاد';
  }

  static String getFastingNote(int month, int day, int weekday) {
    if ((month == 3 && day >= 16) || (month == 4 && day <= 28)) {
      return 'صوم الميلاد المجيد';
    }
    if (month == 12 && day >= 1 && day <= 15) {
      return 'صوم السيدة العذراء';
    }
    if (weekday == DateTime.wednesday || weekday == DateTime.friday) {
      return 'صوم الأربعاء والجمعة الانقطاعي';
    }
    return 'فترة فرح روحي (طقس سنوي)';
  }

  static List<Map<String, String>> getDailyReadingsBlueprint(int month, int day) {
    if (_lectionaryData != null) {
      try {
        final monthsReadings = _lectionaryData!['months_readings'] as Map<String, dynamic>?;
        final templates = _lectionaryData!['templates'] as Map<String, dynamic>?;
        if (monthsReadings != null && templates != null) {
          final monthList = monthsReadings['$month'] as List<dynamic>?;
          if (monthList != null && monthList.isNotEmpty) {
            final idx = (day - 1).clamp(0, monthList.length - 1);
            final templateId = '${monthList[idx]}';
            final tpl = templates[templateId] as Map<String, dynamic>?;
            if (tpl != null) {
              Map<String, String> extract(String key, String typeLabel) {
                final item = tpl[key] as Map<String, dynamic>? ?? {};
                return {
                  'type': typeLabel,
                  'book': '${item['book'] ?? 'المزامير'}',
                  'chapter': '${item['chapter'] ?? '1'}',
                  'verses': '${item['verses'] ?? '1-10'}',
                  'full_ref': '${item['full_ref'] ?? ''}',
                };
              }

              return [
                extract('pauline', 'البولس'),
                extract('catholic', 'الكاثوليكون'),
                extract('acts', 'الإبركسيس'),
                extract('liturgy_psalm', 'المزمور'),
                extract('liturgy_gospel', 'الإنجيل'),
                extract('vespers_psalm', 'مزمور عشية'),
                extract('vespers_gospel', 'إنجيل عشية'),
                extract('matins_psalm', 'مزمور باكر'),
                extract('matins_gospel', 'إنجيل باكر'),
              ];
            }
          }
        }
      } catch (_) {}
    }

    return [
      {'type': 'البولس', 'book': 'الرسالة إلى مؤمني روما', 'chapter': '8', 'verses': '1-11', 'full_ref': 'الرسالة إلى مؤمني روما (8: 1-11)'},
      {'type': 'الكاثوليكون', 'book': 'رسالة بطرس الأولى', 'chapter': '1', 'verses': '3-12', 'full_ref': 'رسالة بطرس الأولى (1: 3-12)'},
      {'type': 'الإبركسيس', 'book': 'أعمال الرسل', 'chapter': '2', 'verses': '1-21', 'full_ref': 'أعمال الرسل (2: 1-21)'},
      {'type': 'المزمور', 'book': 'المزامير', 'chapter': '65', 'verses': '1-2', 'full_ref': 'المزامير (65: 1-2)'},
      {'type': 'الإنجيل', 'book': 'الإنجيل كما دونه يوحنا', 'chapter': '8', 'verses': '12-20', 'full_ref': 'الإنجيل كما دونه يوحنا (8: 12-20)'},
    ];
  }

  /// Returns full Arabic Synaxarium reading formatted for church liturgy
  static String getSynaxariumForDate(int month, int day) {
    final monthName = copticMonths[(month - 1).clamp(0, 12)];
    final key = '$month-$day';

    // 1. Prefer authentic Arabic Synaxarium data
    if (_synaxariumArabicData != null) {
      final events = _synaxariumArabicData![key] as List<dynamic>?;
      if (events != null && events.isNotEmpty) {
        final buffer = StringBuffer();
        buffer.writeln('اليوم $day من شهر $monthName المبارك:');
        buffer.writeln();
        for (final ev in events) {
          final m = ev as Map<String, dynamic>;
          final title = m['title'] ?? '';
          final text = m['text'] ?? '';
          buffer.writeln('✝ $title');
          if (text.toString().isNotEmpty) {
            buffer.writeln(text);
          }
          buffer.writeln();
        }
        buffer.write('بركة صلواتهم وشفاعتهم فلتكن معنا جميعاً. ولربنا المجد دائماً أبدياً آمين.');
        return buffer.toString();
      }
    }

    return 'في اليوم $day من شهر $monthName المبارك: تُعيّد الكنيسة القبطية الأرثوذكسية بتذكار الآباء الشهداء والمعترفين والقديسين، شفاعتهم المقدسة تكون معنا. آمين.';
  }

  /// Returns structured list of events for a specific Coptic date
  static List<Map<String, dynamic>> getSynaxariumEventsForDate(int month, int day) {
    final safeMonth = month.clamp(1, 13);
    final key = '$safeMonth-$day';
    final monthName = copticMonths[safeMonth - 1];

    if (_synaxariumArabicData != null) {
      final list = _synaxariumArabicData![key] as List<dynamic>?;
      if (list != null && list.isNotEmpty) {
        return list.map((item) {
          final m = item as Map<String, dynamic>;
          return {
            'title': '${m['title'] ?? ''}',
            'text': '${m['text'] ?? ''}',
            'summary': '${m['text'] ?? ''}',
            'category_id': '${m['category_id'] ?? 'monks'}',
            'category_name': '${m['category_name'] ?? 'آباء البرية والرهبان'}',
            'date': '$day $monthName',
            'order': m['order'] ?? 0,
          };
        }).toList();
      }
    }

    return [
      {
        'title': 'تذكار يوم $day من شهر $monthName المبارك',
        'text': getSynaxariumForDate(safeMonth, day),
        'summary': getSynaxariumForDate(safeMonth, day),
        'category_id': 'monks',
        'category_name': 'آباء البرية والرهبان',
        'date': '$day $monthName',
        'order': 0,
      }
    ];
  }

  static const List<Map<String, String>> synaxariumCategories = [
    {'id': 'today', 'name': 'تذكارات اليوم القبطي'},
    {'id': 'all', 'name': 'جميع تذكارات الشهر'},
    {'id': 'martyrs', 'name': 'الشهداء والمعترفون'},
    {'id': 'popes_apostles', 'name': 'الآباء الرسل والبطاركة'},
    {'id': 'monks', 'name': 'آباء البرية والرهبان'},
    {'id': 'feasts_angels', 'name': 'الأعياد والعذراء والملائكة'},
  ];

  static List<Map<String, String>> getCategorizedSynaxariumItems({
    required int month,
    required int day,
    String category = 'today',
  }) {
    final safeMonth = month.clamp(1, 13);
    final monthName = copticMonths[safeMonth - 1];
    final results = <Map<String, String>>[];

    if (_synaxariumArabicData != null) {
      if (category == 'today') {
        final key = '$safeMonth-$day';
        final events = _synaxariumArabicData![key] as List<dynamic>? ?? [];
        for (final ev in events) {
          final m = ev as Map<String, dynamic>;
          results.add({
            'title': '${m['title'] ?? ''}',
            'summary': '${m['text'] ?? ''}',
            'text': '${m['text'] ?? ''}',
            'date': '$day $monthName',
            'category_id': '${m['category_id'] ?? 'monks'}',
            'category_name': '${m['category_name'] ?? 'آباء البرية والرهبان'}',
          });
        }
      } else if (category == 'all') {
        for (int d = 1; d <= (safeMonth == 13 ? 6 : 30); d++) {
          final key = '$safeMonth-$d';
          final events = _synaxariumArabicData![key] as List<dynamic>? ?? [];
          for (final ev in events) {
            final m = ev as Map<String, dynamic>;
            results.add({
              'title': '${m['title'] ?? ''}',
              'summary': '${m['text'] ?? ''}',
              'text': '${m['text'] ?? ''}',
              'date': '$d $monthName',
              'category_id': '${m['category_id'] ?? 'monks'}',
              'category_name': '${m['category_name'] ?? 'آباء البرية والرهبان'}',
            });
          }
        }
      } else {
        // Filter by category across the month
        for (int d = 1; d <= (safeMonth == 13 ? 6 : 30); d++) {
          final key = '$safeMonth-$d';
          final events = _synaxariumArabicData![key] as List<dynamic>? ?? [];
          for (final ev in events) {
            final m = ev as Map<String, dynamic>;
            if (m['category_id'] == category) {
              results.add({
                'title': '${m['title'] ?? ''}',
                'summary': '${m['text'] ?? ''}',
                'text': '${m['text'] ?? ''}',
                'date': '$d $monthName',
                'category_id': '${m['category_id'] ?? 'monks'}',
                'category_name': '${m['category_name'] ?? 'آباء البرية والرهبان'}',
              });
            }
          }
        }
      }
    }

    if (results.isEmpty) {
      results.add({
        'title': 'تذكار يوم $day $monthName المبارك',
        'summary': getSynaxariumForDate(safeMonth, day),
        'text': getSynaxariumForDate(safeMonth, day),
        'date': '$day $monthName',
        'category_id': 'monks',
        'category_name': 'آباء البرية والرهبان',
      });
    }

    return results;
  }

  /// Exact Orthodox Alexandrian Computus for Coptic Resurrection Sunday (عيد القيامة المجيد)
  static DateTime computeOrthodoxEaster(int gregorianYear) {
    final a = gregorianYear % 4;
    final b = gregorianYear % 7;
    final c = gregorianYear % 19;
    final d = (19 * c + 15) % 30;
    final e = (2 * a + 4 * b - d + 34) % 7;
    final month = ((d + e + 114) ~/ 31); // Julian month (3=March, 4=April)
    final day = ((d + e + 114) % 31) + 1; // Julian day
    // Convert Julian to Gregorian (+13 days for 1900-2099)
    return DateTime(gregorianYear, month, day).add(const Duration(days: 13));
  }

  /// Calculates all major Coptic Orthodox Movable Feasts & Fasts automatically for any year!
  static List<Map<String, dynamic>> getMovableFeastsForYear(int year) {
    final easter = computeOrthodoxEaster(year);
    return [
      {
        'name': 'بداية صوم يونان (نينوى)',
        'date': easter.subtract(const Duration(days: 69)),
        'type': 'fast',
      },
      {
        'name': 'بداية الصوم الكبير المقدس (٥٥ يوماً)',
        'date': easter.subtract(const Duration(days: 55)),
        'type': 'fast',
      },
      {
        'name': 'أحد الشعانين (دخول السيد المسيح أورشليم)',
        'date': easter.subtract(const Duration(days: 7)),
        'type': 'feast',
      },
      {
        'name': 'الجمعة العظيمة المقدسة',
        'date': easter.subtract(const Duration(days: 2)),
        'type': 'fast',
      },
      {
        'name': 'عيد القيامة المجيد (إخرستوس أنستي)',
        'date': easter,
        'type': 'major_feast',
      },
      {
        'name': 'عيد الصعود المجيد',
        'date': easter.add(const Duration(days: 39)),
        'type': 'feast',
      },
      {
        'name': 'عيد العنصرة (حلول الروح القدس)',
        'date': easter.add(const Duration(days: 49)),
        'type': 'major_feast',
      },
      {
        'name': 'بداية صوم الآباء الرسل',
        'date': easter.add(const Duration(days: 50)),
        'type': 'fast',
      },
    ];
  }

  /// Searches all saints across the entire year
  static List<Map<String, String>> searchSynaxarium(String query) {
    final cleanQ = query.trim().toLowerCase();
    if (cleanQ.isEmpty || _synaxariumArabicData == null) return [];

    final results = <Map<String, String>>[];
    for (int m = 1; m <= 13; m++) {
      final monthName = copticMonths[m - 1];
      final maxDays = m == 13 ? 6 : 30;
      for (int d = 1; d <= maxDays; d++) {
        final key = '$m-$d';
        final events = _synaxariumArabicData![key] as List<dynamic>? ?? [];
        for (final ev in events) {
          final item = ev as Map<String, dynamic>;
          final title = '${item['title'] ?? ''}';
          final text = '${item['text'] ?? ''}';
          if (title.toLowerCase().contains(cleanQ) || text.toLowerCase().contains(cleanQ)) {
            results.add({
              'title': title,
              'summary': text,
              'text': text,
              'date': '$d $monthName',
              'category_id': '${item['category_id'] ?? 'monks'}',
              'category_name': '${item['category_name'] ?? 'آباء البرية والرهبان'}',
            });
            if (results.length >= 50) return results; // Cap results for performance
          }
        }
      }
    }
    return results;
  }
}
