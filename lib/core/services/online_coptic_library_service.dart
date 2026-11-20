import 'dart:convert';
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

/// Multi-source Orthodox Digital Library & Complete 73-Book Tafsir Engine:
/// - Full 73-book chapter-by-chapter Patristic Commentaries (Fr. Tadros Malaty & Fr. Antonios Fekry)
/// - 420+ curated multi-source Orthodox books (ChristianLib.com, Archive.org / Bibliotheca Alexandrina,
///   Father Matta El Meskeen / St-Macarius classics, Pope Shenouda III, Patristic texts)
/// - Live real-time web search across 6,000+ books on ChristianLib.com AND Archive.org
/// - Transparent SharedPreferences offline caching for every chapter read.
class OnlineCopticLibraryService {
  static final OnlineCopticLibraryService _instance = OnlineCopticLibraryService._internal();
  factory OnlineCopticLibraryService() => _instance;
  OnlineCopticLibraryService._internal();

  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/126.0.0.0 Mobile Safari/537.36',
    'Accept-Language': 'ar,en;q=0.9',
  };

  List<TafsirBookEntry>? _tafsirCache;
  List<OnlineBookEntry>? _booksCache;

  Future<List<TafsirBookEntry>> loadTafsirCatalog() async {
    if (_tafsirCache != null) return _tafsirCache!;
    try {
      final raw = await rootBundle.loadString('assets/data/tafsir_catalog.json');
      final list = jsonDecode(raw) as List;
      _tafsirCache = list.map((e) => TafsirBookEntry.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      _tafsirCache = [];
    }
    return _tafsirCache!;
  }

  Future<List<OnlineBookEntry>> loadOnlineBooksCatalog() async {
    if (_booksCache != null) return _booksCache!;
    try {
      final raw = await rootBundle.loadString('assets/data/online_books_catalog.json');
      final list = jsonDecode(raw) as List;
      _booksCache = list.map((e) => OnlineBookEntry.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      _booksCache = [];
    }
    return _booksCache!;
  }

  String _cacheKey(String prefix, String url) =>
      'olib_${prefix}_${url.hashCode.abs()}';

  Future<String> _httpGetUtf8(String url, {int timeoutSec = 16}) async {
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
    return utf8.decode(res.bodyBytes, allowMalformed: true);
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
        return list.map((e) => OnlineChapterLink.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }

    final html = await _httpGetUtf8(indexUrl);
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
      if (rawHref.isEmpty || rawHref.startsWith('#') || rawHref.startsWith('javascript:')) {
        continue;
      }
      final resolved = baseUri.resolve(rawHref).toString().split('#').first;
      if (!resolved.startsWith(basePrefix) || resolved == indexUrl) continue;
      if (!resolved.toLowerCase().endsWith('.html') && !resolved.toLowerCase().endsWith('.htm')) {
        continue;
      }
      if (seen.contains(resolved)) continue;

      final label = _cleanInlineHtml(m.group(2) ?? '');
      if (label.length < 2) continue;
      // Skip obvious duplicate image-only / navigation controls
      if (label == 'الرئيسية' || label == 'السابق' || label == 'التالي' || label == 'فهرس') {
        continue;
      }

      seen.add(resolved);
      chapters.add(OnlineChapterLink(title: label, url: resolved));
    }

    if (chapters.isNotEmpty) {
      await prefs.setString(key, jsonEncode(chapters.map((c) => c.toJson()).toList()));
    }
    return chapters;
  }

  /// Fetches and cleans a full Arabic chapter (Tafsir or Book) into pure editorial paragraphs.
  /// Returns `(paragraphs, isFromCache)`.
  Future<(List<String>, bool)> fetchChapterParagraphs(String chapterUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cacheKey('ch', chapterUrl);
    final cached = prefs.getString(key);
    if (cached != null && cached.isNotEmpty) {
      try {
        final list = (jsonDecode(cached) as List).map((e) => e.toString()).toList();
        if (list.isNotEmpty) return (list, true);
      } catch (_) {}
    }

    String html = await _httpGetUtf8(chapterUrl);
    // Strip non-content tags cleanly
    html = html
        .replaceAll(RegExp(r'<script\b[^>]*>.*?</script>', caseSensitive: false, dotAll: true), ' ')
        .replaceAll(RegExp(r'<style\b[^>]*>.*?</style>', caseSensitive: false, dotAll: true), ' ')
        .replaceAll(RegExp(r'<nav\b[^>]*>.*?</nav>', caseSensitive: false, dotAll: true), ' ')
        .replaceAll(RegExp(r'<header\b[^>]*>.*?</header>', caseSensitive: false, dotAll: true), ' ')
        .replaceAll(RegExp(r'<footer\b[^>]*>.*?</footer>', caseSensitive: false, dotAll: true), ' ')
        .replaceAll(RegExp(r'<select\b[^>]*>.*?</select>', caseSensitive: false, dotAll: true), ' ')
        .replaceAll(RegExp(r'<form\b[^>]*>.*?</form>', caseSensitive: false, dotAll: true), ' ');

    final blockRe = RegExp(
      r'<(p|h1|h2|h3|h4|blockquote|li)\b[^>]*>(.*?)</\1>',
      caseSensitive: false,
      dotAll: true,
    );

    final List<String> paragraphs = [];
    final Set<String> seen = {};
    final arabicCharRe = RegExp(r'[\u0600-\u06FF]');

    for (final m in blockRe.allMatches(html)) {
      final text = _cleanInlineHtml(m.group(2) ?? '');
      if (text.length < 18) continue;
      if (!arabicCharRe.hasMatch(text)) continue;

      // Filter out site chrome, jump bars, copyright banners, & sidebar indices
      final lower = text.toLowerCase();
      if (lower.contains('st-takla.org') ||
          text.contains('موقع الأنبا تكلا') ||
          text.contains('كنيسة الأنبا تكلا') ||
          text.contains('اذهب مباشرةً لتفسير الآية') ||
          text.contains('تفاسير أسفار الكتاب المقدس 1-') ||
          text.contains('ابحث في موقع') ||
          text.contains('حقوق الطبع') ||
          text.contains('الصفحة الرئيسية') ||
          text.contains('مواقع مسيحية') ||
          text.contains('اتصل بنا') ||
          text.startsWith('←')) {
        continue;
      }

      if (seen.contains(text)) continue;
      seen.add(text);
      paragraphs.add(text);
    }

    if (paragraphs.isNotEmpty) {
      await prefs.setString(key, jsonEncode(paragraphs));
    }
    return (paragraphs, false);
  }

  /// Fetches full book introduction & direct PDF/Download links for a ChristianLib.com book.
  Future<OnlineBookDetail> fetchChristianLibDetail(OnlineBookEntry book) async {
    final numericId = book.id.replaceFirst('clib_', '');
    if (int.tryParse(numericId) != null) {
      try {
        final raw = await _httpGetUtf8(
          'https://www.christianlib.com/wp-json/wp/v2/posts/$numericId',
          timeoutSec: 14,
        );
        final Map<String, dynamic> post = jsonDecode(raw);
        final title = _cleanInlineHtml((post['title']?['rendered'] ?? book.title).toString());
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

        final pMatches = RegExp(r'<(p|li|h2|h3)\b[^>]*>(.*?)</\1>', caseSensitive: false, dotAll: true)
            .allMatches(contentHtml);
        final buf = StringBuffer();
        for (final pm in pMatches) {
          final t = _cleanInlineHtml(pm.group(2) ?? '');
          if (t.length >= 12 && !t.contains('اضغط هنا للتحميل')) {
            buf.writeln(t);
            buf.writeln();
          }
        }

        return OnlineBookDetail(
          title: title,
          bodyText: buf.toString().trim().isNotEmpty ? buf.toString().trim() : book.description,
          downloadLinks: downloads,
          webUrl: book.url,
        );
      } catch (_) {}
    }

    return OnlineBookDetail(
      title: book.title,
      bodyText: book.description.isNotEmpty
          ? book.description
          : 'افتح صفحة الكتاب مباشرة للاطلاع على النسخة الكاملة وتحميل ملف PDF.',
      downloadLinks: book.pdfUrl.isNotEmpty ? [book.pdfUrl] : [],
      webUrl: book.url,
    );
  }

  /// LIVE real-time multi-library internet search across BOTH:
  /// 1) ChristianLib.com (6,000+ Orthodox & Christian Arabic books via WordPress REST API)
  /// 2) Archive.org (Bibliotheca Alexandrina & Arabic Coptic Orthodox texts via Search API)
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
      final raw = await _httpGetUtf8(
        'https://www.christianlib.com/wp-json/wp/v2/posts?search=$encoded&per_page=20',
        timeoutSec: 12,
      );
      final list = jsonDecode(raw) as List;
      return list.map((item) {
        final m = Map<String, dynamic>.from(item);
        final title = _cleanInlineHtml((m['title']?['rendered'] ?? '').toString());
        final link = (m['link'] ?? '').toString();
        final excerpt = _cleanInlineHtml((m['excerpt']?['rendered'] ?? '').toString());
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
          source: 'مكتبة الكتب المسيحية (ChristianLib)',
          url: link,
          readerType: 'christianlib_post',
          description: excerpt.length > 180 ? '${excerpt.substring(0, 180)}…' : excerpt,
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
      final raw = await _httpGetUtf8(
        'https://archive.org/advancedsearch.php?q=$encoded&fl[]=identifier,title,creator&rows=12&output=json',
        timeoutSec: 12,
      );
      final Map<String, dynamic> data = jsonDecode(raw);
      final docs = (data['response']?['docs'] as List?) ?? [];
      return docs.map((d) {
        final m = Map<String, dynamic>.from(d);
        final id = (m['identifier'] ?? '').toString();
        final title = (m['title'] ?? '').toString().replaceFirst(RegExp(r'^\d+_'), '').replaceAll('_', ' ').trim();
        final rawCreator = m['creator'];
        final author = rawCreator is List
            ? rawCreator.take(2).join(' • ')
            : (rawCreator ?? 'أرشيف التراث العالمي').toString();
        return OnlineBookEntry(
          id: 'arch_$id',
          title: title.isNotEmpty ? title : id,
          author: author,
          category: 'نتائج أرشيف الإنترنت',
          source: 'أرشيف الإنترنت (Archive.org)',
          url: 'https://archive.org/details/$id',
          readerType: 'archive_org',
          description: 'نسخة رقمية متاحة للتصفح والقراءة والتحميل المباشر من أرشيف الإنترنت ومكتبة الإسكندرية.',
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
