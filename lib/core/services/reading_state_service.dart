import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteVerse {
  final String bookAbbrev;
  final String bookName;
  final int chapter;
  final int verse;
  final String text;
  final DateTime savedAt;

  const FavoriteVerse({
    required this.bookAbbrev,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.savedAt,
  });

  String get key => '${bookAbbrev}_${chapter}_$verse';

  Map<String, dynamic> toJson() => {
        'bookAbbrev': bookAbbrev,
        'bookName': bookName,
        'chapter': chapter,
        'verse': verse,
        'text': text,
        'savedAt': savedAt.toIso8601String(),
      };

  factory FavoriteVerse.fromJson(Map<String, dynamic> j) => FavoriteVerse(
        bookAbbrev: (j['bookAbbrev'] ?? '').toString(),
        bookName: (j['bookName'] ?? '').toString(),
        chapter: (j['chapter'] as num?)?.toInt() ?? 1,
        verse: (j['verse'] as num?)?.toInt() ?? 1,
        text: (j['text'] ?? '').toString(),
        savedAt: DateTime.tryParse('${j['savedAt'] ?? ''}') ?? DateTime.now(),
      );
}

/// Persists "Resume Where You Left Off" (Bible & Books) + Favorite Bible Verses.
class ReadingStateService {
  static final ReadingStateService _instance = ReadingStateService._internal();
  factory ReadingStateService() => _instance;
  ReadingStateService._internal();

  static const _lastBibleKey = 'resume_last_bible_v1';
  static const _lastBookKey = 'resume_last_book_v1';
  static const _favVersesKey = 'favorite_bible_verses_v1';

  bool _loaded = false;
  Map<String, dynamic>? _lastBible;
  Map<String, dynamic>? _lastBook;
  List<FavoriteVerse> _favorites = [];

  final ValueNotifier<int> favoritesCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> revisionNotifier = ValueNotifier<int>(0);

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final lb = prefs.getString(_lastBibleKey);
    if (lb != null && lb.isNotEmpty) {
      try {
        _lastBible = Map<String, dynamic>.from(jsonDecode(lb));
      } catch (_) {}
    }
    final lbk = prefs.getString(_lastBookKey);
    if (lbk != null && lbk.isNotEmpty) {
      try {
        _lastBook = Map<String, dynamic>.from(jsonDecode(lbk));
      } catch (_) {}
    }
    final fv = prefs.getString(_favVersesKey);
    if (fv != null && fv.isNotEmpty) {
      try {
        _favorites = (jsonDecode(fv) as List)
            .map((e) => FavoriteVerse.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {}
    }
    favoritesCountNotifier.value = _favorites.length;
    _loaded = true;
  }

  Map<String, dynamic>? get lastBible => _lastBible;
  Map<String, dynamic>? get lastBook => _lastBook;
  List<FavoriteVerse> get favoriteVerses => List.unmodifiable(_favorites);

  Future<void> saveLastBible({
    required String bookAbbrev,
    required String bookName,
    required int chapter,
  }) async {
    await ensureLoaded();
    _lastBible = {
      'abbrev': bookAbbrev,
      'name': bookName,
      'chapter': chapter,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBibleKey, jsonEncode(_lastBible));
    revisionNotifier.value++;
  }

  Future<void> saveLastBook({
    required String bookId,
    required String bookTitle,
    required int chapterIndex,
  }) async {
    await ensureLoaded();
    _lastBook = {
      'id': bookId,
      'title': bookTitle,
      'chapterIndex': chapterIndex,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBookKey, jsonEncode(_lastBook));
    revisionNotifier.value++;
  }

  bool isVerseFavorited(String bookAbbrev, int chapter, int verse) {
    final k = '${bookAbbrev}_${chapter}_$verse';
    return _favorites.any((f) => f.key == k);
  }

  Future<bool> toggleFavoriteVerse(FavoriteVerse verse) async {
    await ensureLoaded();
    final idx = _favorites.indexWhere((f) => f.key == verse.key);
    bool added;
    if (idx >= 0) {
      _favorites.removeAt(idx);
      added = false;
    } else {
      _favorites.insert(0, verse);
      added = true;
    }
    favoritesCountNotifier.value = _favorites.length;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _favVersesKey,
      jsonEncode(_favorites.map((e) => e.toJson()).toList()),
    );
    return added;
  }
}
