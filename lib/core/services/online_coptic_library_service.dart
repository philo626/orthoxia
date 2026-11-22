import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'security_guard_service.dart';

class TafsirBookEntry {
  final String id;
  final String name;
  final String testament;
  final int chaptersCount;
  final String tadrosUrl;
  final String antoniosUrl;
  final String mattaQuery;

  const TafsirBookEntry({
    required this.id,
    required this.name,
    required this.testament,
    required this.chaptersCount,
    required this.tadrosUrl,
    required this.antoniosUrl,
    required this.mattaQuery,
  });

  factory TafsirBookEntry.fromJson(Map<String, dynamic> j) => TafsirBookEntry(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        testament: (j['testament'] ?? 'old').toString(),
        chaptersCount: (j['chaptersCount'] as num?)?.toInt() ?? 0,
        tadrosUrl: (j['tadrosUrl'] ?? '').toString(),
        antoniosUrl: (j['antoniosUrl'] ?? '').toString(),
        mattaQuery: (j['mattaQuery'] ?? '').toString(),
      );
}

class OnlineBookEntry {
  final String id;
  final String title;
  final String author;
  final String category;
  final String source;
  final String url;
  final String readerType; // 'in_app_chapters' | 'christianlib_post' | 'archive_org'
  final String description;
  final String pdfUrl;

  const OnlineBookEntry({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.source,
    required this.url,
    required this.readerType,
    this.description = '',
    this.pdfUrl = '',
  });

  factory OnlineBookEntry.fromJson(Map<String, dynamic> j) => OnlineBookEntry(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        author: (j['author'] ?? '').toString(),
        category: (j['category'] ?? '').toString(),
        source: (j['source'] ?? '').toString(),
        url: (j['url'] ?? '').toString(),
        readerType: (j['readerType'] ?? 'in_app_chapters').toString(),
        description: (j['description'] ?? '').toString(),
        pdfUrl: (j['pdfUrl'] ?? '').toString(),
      );
}

class OnlineChapterLink {
  final String title;
  final String url;

  const OnlineChapterLink({required this.title, required this.url});

  Map<String, String> toJson() => {'title': title, 'url': url};
  factory OnlineChapterLink.fromJson(Map<String, dynamic> j) =>
      OnlineChapterLink(title: j['title'] ?? '', url: j['url'] ?? '');
}

class OnlineBookDetail {
  final String title;
  final String bodyText;
  final List<String> downloadLinks;
  final String webUrl;

  const OnlineBookDetail({
    required this.title,
    required this.bodyText,
    required this.downloadLinks,
    required this.webUrl,
  });
}

/// Multi-source Orthodox Digital Library & Complete 73-Book Patristic Tafsir Engine.
/// Includes full IANA Windows-1256 (CP1256) Arabic HTML decoder so Arabic Patristic
/// commentaries (Fr. Tadros Yacoub Malaty & Fr. Antonios Fekry) and 98 full-chapter
/// books render cleanly with zero mojibake or `***` artifacts.
class OnlineCopticLibraryService {
  static final OnlineCopticLibraryService _instance =
      OnlineCopticLibraryService._internal();
  factory OnlineCopticLibraryService() => _instance;
  OnlineCopticLibraryService._internal();

  static const Map<String, String> _headers = {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/126.0.0.0 Mobile Safari/537.36',
    'Accept-Language': 'ar,en;q=0.9',
  };

  /// Complete Unicode mapping table for Windows-1256 (Arabic CP1256) bytes 0x80..0xFF.
  static const List<int> _cp1256High = [
    0x20AC, 0x067E, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, // 80-87
    0x02C6, 0x2030, 0x0679, 0x2039, 0x0152, 0x0686, 0x0698, 0x0688, // 88-8F
    0x06AF, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014, // 90-97
    0x06A9, 0x2122, 0x0691, 0x203A, 0x0153, 0x200C, 0x200D, 0x06BA, // 98-9F
    0x00A0, 0x060C, 0x00A2, 0x00A3, 0x00A4, 0x00A5, 0x00A6, 0x00A7, // A0-A7
    0x00A8, 0x00A9, 0x06BE, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x00AF, // A8-AF
    0x00B0, 0x00B1, 0x00B2, 0x00B3, 0x00B4, 0x00B5, 0x00B6, 0x00B7, // B0-B7
    0x00B8, 0x00B9, 0x061B, 0x00BB, 0x00BC, 0x00BD, 0x00BE, 0x061F, // B8-BF
    0x06C1, 0x0621, 0x0622, 0x0623, 0x0624, 0x0625, 0x0626, 0x0627, // C0-C7
    0x0628, 0x0629, 0x062A, 0x062B, 0x062C, 0x062D, 0x062E, 0x062F, // C8-CF
    0x0630, 0x0631, 0x0632, 0x0633, 0x0634, 0x0635, 0x0636, 0x00D7, // D0-D7
    0x0637, 0x0638, 0x0639, 0x063A, 0x0640, 0x0641, 0x0642, 0x0643, // D8-DF
    0x00E0, 0x0644, 0x00E2, 0x0645, 0x0646, 0x0647, 0x0648, 0x00E7, // E0-E7
    0x00E8, 0x00E9, 0x00EA, 0x00EB, 0x0649, 0x064A, 0x00EE, 0x00EF, // E8-EF
    0x064B, 0x064C, 0x064D, 0x064E, 0x00F4, 0x064F, 0x0650, 0x00F7, // F0-F7
    0x0651, 0x00F9, 0x0652, 0x00FB, 0x00FC, 0x200E, 0x200F, 0x06D2, // F8-FF
  ];

  /// Decodes raw Windows-1256 Arabic bytes to clean Unicode String.
  static String decodeWindows1256(Uint8List bytes) {
    final codes = Uint16List(bytes.length);
    for (int i = 0; i < bytes.length; i++) {
      final b = bytes[i];
      codes[i] = b < 0x80 ? b : _cp1256High[b - 0x80];
    }
    return String.fromCharCodes(codes);
  }

  /// Smart charset-aware HTML/text byte decoder (handles Windows-1256 & UTF-8 cleanly).
  static String decodeResponseBytes(Uint8List bytes, {String? contentType}) {
    final ct = (contentType ?? '').toLowerCase();
    if (ct.contains('windows-1256') || ct.contains('cp1256')) {
      return decodeWindows1256(bytes);
    }
    // Sniff <meta charset="windows-1256"> in the ASCII head of the document
    final headLen = bytes.length < 2400 ? bytes.length : 2400;
    final headAscii = latin1.decode(bytes.sublist(0, headLen)).toLowerCase();
    if (headAscii.contains('windows-1256') || headAscii.contains('cp1256')) {
      return decodeWindows1256(bytes);
    }
    // Try strict UTF-8 first; if invalid UTF-8 bytes exist, fall back to Windows-1256!
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } catch (_) {
      return decodeWindows1256(bytes);
    }
  }

  List<TafsirBookEntry>? _tafsirCache;
  List<OnlineBookEntry>? _booksCache;

  Future<List<TafsirBookEntry>> loadTafsirCatalog() async {
    if (_tafsirCache != null) return _tafsirCache!;
    try {
      final raw = await rootBundle.loadString('assets/data/tafsir_catalog.json');
      final list = jsonDecode(raw) as List;
      _tafsirCache = list
          .map((e) => TafsirBookEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      _tafsirCache = [];
    }
    return _tafsirCache!;
  }

  Future<List<OnlineBookEntry>> loadOnlineBooksCatalog() async {
    if (_booksCache != null) return _booksCache!;
    try {
      final raw =
          await rootBundle.loadString('assets/data/online_books_catalog.json');
      final list = jsonDecode(raw) as List;
      _booksCache = list
          .map((e) => OnlineBookEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      _booksCache = [];
    }
    return _booksCache!;
  }

  // Bumped to v2 so any previously cached broken mojibake chapters are auto-invalidated!
  String _cacheKey(String prefix, String url) =>
      'olib_v2_${prefix}_${url.hashCode.abs()}';

  Future<String> _httpGetDecoded(String url, {int timeoutSec = 16}) async {
    final safeUrl = SecurityGuardService.upgradeToHttps(url);
    if (!SecurityGuardService.isTrustedLibraryUrl(safeUrl)) {
      throw const FormatException('Blocked untrusted or non-HTTPS library URL');
    }
    final res = await http
        .get(Uri.parse(safeUrl), headers: _headers)
        .timeout(Duration(seconds: timeoutSec));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}');
    }
    return decodeResponseBytes(
      res.bodyBytes,
      contentType: res.headers['content-type'],
    );
  }

  /// Fetches the full chapter list from an online Tafsir or Book index page (cached locally).
  Future<List<OnlineChapterLink>> fetchChapters(String indexUrl) async {
    if (indexUrl.isEmpty) return [];
    final prefs = await SharedPreferences.getInstance();
    final key = _cacheKey('idx', indexUrl);
    final cached = prefs.getString(key);
    if (cached != null && cached.isNotEmpty) {
      try {
        final list = jsonDecode(cached) as List;
        final restored = list
            .map((e) => OnlineChapterLink.fromJson(Map<String, dynamic>.from(e)))
            .where((c) => !c.title.contains('\uFFFD'))
            .toList();
        if (restored.isNotEmpty) return restored;
      } catch (_) {}
    }

    final html = await _httpGetDecoded(indexUrl);
    final baseUri = Uri.parse(indexUrl);
    final dirPath = baseUri.path.contains('/')
        ? baseUri.path.substring(0, baseUri.path.lastIndexOf('/') + 1)
        : '/';
    final basePrefix = '${baseUri.scheme}://${baseUri.host}$dirPath';

    final linkRegex = RegExp(
      r'''<a\b[^>]*href=["']([^"']+)["'][^>]*>(.*?)</a>''',
      caseSensitive: false,
      dotAll: true,
    );

    final List<OnlineChapterLink> chapters = [];
    final Set<String> seen = {};

    for (final m in linkRegex.allMatches(html)) {
      final rawHref = (m.group(1) ?? '').trim();
      if (rawHref.isEmpty ||
          rawHref.startsWith('#') ||
          rawHref.startsWith('javascript:')) {
        continue;
      }
      final resolved = baseUri.resolve(rawHref).toString().split('#').first;
      if (!resolved.startsWith(basePrefix) || resolved == indexUrl) continue;
      if (!resolved.toLowerCase().endsWith('.html') &&
          !resolved.toLowerCase().endsWith('.htm')) {
        continue;
      }
      if (seen.contains(resolved)) continue;

      final label = _cleanInlineHtml(m.group(2) ?? '');
      if (label.length < 2) continue;
      if (label == 'الرئيسية' ||
          label == 'السابق' ||
          label == 'التالي' ||
          label == 'فهرس' ||
          label.contains('تصفح')) {
        continue;
      }

      seen.add(resolved);
      chapters.add(OnlineChapterLink(title: label, url: resolved));
    }

    if (chapters.isNotEmpty) {
      await prefs.setString(
        key,
        jsonEncode(chapters.map((c) => c.toJson()).toList()),
      );
    }
    return chapters;
  }

  /// Fetches and cleans a full Arabic chapter (Tafsir or Book) into pure editorial paragraphs.
  /// Strips ALL `***` dividers, navigation breadcrumbs, and site boilerplate.
  Future<(List<String>, bool)> fetchChapterParagraphs(String chapterUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cacheKey('ch', chapterUrl);
    final cached = prefs.getString(key);
    if (cached != null && cached.isNotEmpty) {
      try {
        final list = (jsonDecode(cached) as List)
            .map((e) => e.toString())
            .where((t) => !t.contains('\uFFFD') && !_isGarbageLine(t))
            .toList();
        if (list.isNotEmpty) return (list, true);
      } catch (_) {}
    }

    String html = await _httpGetDecoded(chapterUrl);
    html = html
        .replaceAll(
            RegExp(r'<script\b[^>]*>.*?</script>',
                caseSensitive: false, dotAll: true),
            ' ')
        .replaceAll(
            RegExp(r'<style\b[^>]*>.*?</style>',
                caseSensitive: false, dotAll: true),
            ' ')
        .replaceAll(
            RegExp(r'<nav\b[^>]*>.*?</nav>', caseSensitive: false, dotAll: true),
            ' ')
        .replaceAll(
            RegExp(r'<header\b[^>]*>.*?</header>',
                caseSensitive: false, dotAll: true),
            ' ')
        .replaceAll(
            RegExp(r'<footer\b[^>]*>.*?</footer>',
                caseSensitive: false, dotAll: true),
            ' ')
        .replaceAll(
            RegExp(r'<select\b[^>]*>.*?</select>',
                caseSensitive: false, dotAll: true),
            ' ')
        .replaceAll(
            RegExp(r'<form\b[^>]*>.*?</form>',
                caseSensitive: false, dotAll: true),
            ' ');

    final blockRe = RegExp(
      r'<(p|h1|h2|h3|h4|blockquote|li)\b[^>]*>(.*?)</\1>',
      caseSensitive: false,
      dotAll: true,
    );

    final List<String> paragraphs = [];
    final Set<String> seen = {};
    final arabicCharRe = RegExp(r'[\u0600-\u06FF]');

    for (final m in blockRe.allMatches(html)) {
      var text = _cleanInlineHtml(m.group(2) ?? '');
      // Strip decorative runs of asterisks or underscores inside text
      text = text.replaceAll(RegExp(r'\*{2,}'), '').replaceAll(RegExp(r'_{3,}'), '').trim();
      if (text.length < 18) continue;
      if (!arabicCharRe.hasMatch(text)) continue;
      if (_isGarbageLine(text)) continue;

      if (seen.contains(text)) continue;
      seen.add(text);
      paragraphs.add(text);
    }

    if (paragraphs.isNotEmpty) {
      await prefs.setString(key, jsonEncode(paragraphs));
    }
    return (paragraphs, false);
  }

  static bool _isGarbageLine(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return true;
    if (RegExp(r'^[\*\-\s_•·\.\|=]+$').hasMatch(trimmed)) return true;
    final lower = trimmed.toLowerCase();
    if (lower.contains('st-takla.org') ||
        trimmed.contains('موقع الأنبا تكلا') ||
        trimmed.contains('كنيسة الأنبا تكلا') ||
        trimmed.contains('اضغط هنا لإظهار الفهرس') ||
        trimmed.contains('اذهب مباشرةً لتفسير الآية') ||
        trimmed.contains('تفاسير أسفار الكتاب المقدس 1-') ||
        trimmed.contains('ابحث في موقع') ||
        trimmed.contains('حقوق الطبع') ||
        trimmed.contains('الصفحة الرئيسية') ||
        trimmed.contains('مواقع مسيحية') ||
        trimmed.contains('اتصل بنا') ||
        trimmed.startsWith('←')) {
      return true;
    }
    // Drop dense chapter-jump horizontal index bars ("الأصحاح 1 | الأصحاح 2 | الأصحاح 3 ...")
    if ('|'.allMatches(trimmed).length >= 4) return true;
    return false;
  }

  /// Fetches full book introduction & direct PDF/Download links for a ChristianLib.com book.
  Future<OnlineBookDetail> fetchChristianLibDetail(OnlineBookEntry book) async {
    final numericId = book.id.replaceFirst('clib_', '');
    if (int.tryParse(numericId) != null) {
      try {
        final raw = await _httpGetDecoded(
          'https://www.christianlib.com/wp-json/wp/v2/posts/$numericId',
          timeoutSec: 14,
        );
        final Map<String, dynamic> post = jsonDecode(raw);
        final title =
            _cleanInlineHtml((post['title']?['rendered'] ?? book.title).toString());
        final contentHtml = (post['content']?['rendered'] ?? '').toString();
        final linkMatches = RegExp(
          r'''href=["']([^"']+(?:\.pdf|drive\.google\.com|mediafire\.com|archive\.org|dropbox\.com|4shared\.com|mega\.nz|christianlib\.com/download)[^"']*)["']''',
          caseSensitive: false,
        ).allMatches(contentHtml);

        final downloads = <String>[];
        for (final lm in linkMatches) {
          final u = lm.group(1) ?? '';
          if (u.isNotEmpty && !downloads.contains(u)) downloads.add(u);
        }
        if (book.pdfUrl.isNotEmpty && !downloads.contains(book.pdfUrl)) {
          downloads.insert(0, book.pdfUrl);
        }

        final pMatches = RegExp(
          r'<(p|li|h2|h3)\b[^>]*>(.*?)</\1>',
          caseSensitive: false,
          dotAll: true,
        ).allMatches(contentHtml);
        final buf = StringBuffer();
        for (final pm in pMatches) {
          final t = _cleanInlineHtml(pm.group(2) ?? '');
          if (t.length >= 12 &&
              !t.contains('اضغط هنا للتحميل') &&
              !_isGarbageLine(t)) {
            buf.writeln(t);
            buf.writeln();
          }
        }

        return OnlineBookDetail(
          title: title,
          bodyText: buf.toString().trim().isNotEmpty
              ? buf.toString().trim()
              : book.description,
          downloadLinks: downloads,
          webUrl: book.url,
        );
      } catch (_) {}
    }

    return OnlineBookDetail(
      title: book.title,
      bodyText: book.description.isNotEmpty
          ? book.description
          : 'تصفّح الكتاب الكامل مباشرة داخل قارئ التطبيق أو قم بتحميل نسخة PDF.',
      downloadLinks: book.pdfUrl.isNotEmpty ? [book.pdfUrl] : [],
      webUrl: book.url,
    );
  }

  /// LIVE real-time multi-library internet search across ChristianLib.com & Archive.org
  Future<List<OnlineBookEntry>> searchInternetLibraries(String query) async {
    final q = query.trim();
    if (q.length < 2) return [];

    final results = <OnlineBookEntry>[];
    final seenUrls = <String>{};

    final futures = await Future.wait([
      _searchChristianLib(q),
      _searchArchiveOrg(q),
    ]);

    for (final list in futures) {
      for (final item in list) {
        if (seenUrls.add(item.url)) {
          results.add(item);
        }
      }
    }
    return results;
  }

  Future<List<OnlineBookEntry>> _searchChristianLib(String query) async {
    try {
      final encoded = Uri.encodeQueryComponent(query);
      final raw = await _httpGetDecoded(
        'https://www.christianlib.com/wp-json/wp/v2/posts?search=$encoded&per_page=20',
        timeoutSec: 12,
      );
      final list = jsonDecode(raw) as List;
      return list.map((item) {
        final m = Map<String, dynamic>.from(item);
        final title =
            _cleanInlineHtml((m['title']?['rendered'] ?? '').toString());
        final link = (m['link'] ?? '').toString();
        final excerpt =
            _cleanInlineHtml((m['excerpt']?['rendered'] ?? '').toString());
        final content = (m['content']?['rendered'] ?? '').toString();
        final pdfM = RegExp(
          r'''href=["']([^"']+(?:\.pdf|drive\.google\.com|mediafire\.com|archive\.org)[^"']*)["']''',
          caseSensitive: false,
        ).firstMatch(content);

        String author = 'مكتبة الكتب المسيحية';
        final parts = title.split(RegExp(r'\s*[–\-]\s*'));
        if (parts.length >= 2 && parts.last.length <= 45) {
          author = parts.last.trim();
        }

        return OnlineBookEntry(
          id: 'clib_${m['id']}',
          title: title,
          author: author,
          category: 'نتائج البحث الحية',
          source: 'مكتبة الكتب المسيحية',
          url: link,
          readerType: 'christianlib_post',
          description:
              excerpt.length > 180 ? '${excerpt.substring(0, 180)}…' : excerpt,
          pdfUrl: pdfM?.group(1) ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<OnlineBookEntry>> _searchArchiveOrg(String query) async {
    try {
      final encoded = Uri.encodeQueryComponent('($query) AND mediatype:texts');
      final raw = await _httpGetDecoded(
        'https://archive.org/advancedsearch.php?q=$encoded&fl[]=identifier,title,creator&rows=12&output=json',
        timeoutSec: 12,
      );
      final Map<String, dynamic> data = jsonDecode(raw);
      final docs = (data['response']?['docs'] as List?) ?? [];
      return docs.map((d) {
        final m = Map<String, dynamic>.from(d);
        final id = (m['identifier'] ?? '').toString();
        final title = (m['title'] ?? '')
            .toString()
            .replaceFirst(RegExp(r'^\d+_'), '')
            .replaceAll('_', ' ')
            .trim();
        final rawCreator = m['creator'];
        final author = rawCreator is List
            ? rawCreator.take(2).join(' • ')
            : (rawCreator ?? 'أرشيف التراث القبطي').toString();
        return OnlineBookEntry(
          id: 'arch_$id',
          title: title.isNotEmpty ? title : id,
          author: author,
          category: 'أرشيف التراث القبطي',
          source: 'أرشيف الكتب الكاملة (Archive.org)',
          url: 'https://archive.org/details/$id',
          readerType: 'archive_org',
          description:
              'نسخة مصوّرة كاملة متاحة للتصفح بالصفحات مباشرة داخل التطبيق.',
          pdfUrl: 'https://archive.org/details/$id',
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static String _cleanInlineHtml(String input) {
    var s = input
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#8211;', '–')
        .replaceAll('&#8212;', '—')
        .replaceAll('&#8220;', '«')
        .replaceAll('&#8221;', '»')
        .replaceAll('&laquo;', '«')
        .replaceAll('&raquo;', '»')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    s = s.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
      final code = int.tryParse(m.group(1) ?? '');
      return code != null ? String.fromCharCode(code) : '';
    });
    return s.replaceAll(RegExp(r'[ \t\r\n]+'), ' ').trim();
  }
}
