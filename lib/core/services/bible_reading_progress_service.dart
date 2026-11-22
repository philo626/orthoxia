import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/bible_model.dart';
import 'firebase_service.dart';

/// Tracks completed chapters across all books of the Holy Bible ("ختم الكتاب المقدس"),
/// with automatic cloud merge when signed in.
class BibleReadingProgressService {
  static final BibleReadingProgressService _instance =
      BibleReadingProgressService._internal();
  factory BibleReadingProgressService() => _instance;

  static const String _prefsKey = 'bible_completed_chapters_v1';
  Set<String> _completedKeys = {};
  bool _loaded = false;

  final ValueNotifier<int> completedCountNotifier = ValueNotifier<int>(0);

  BibleReadingProgressService._internal();

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? [];
    _completedKeys = list.toSet();
    completedCountNotifier.value = _completedKeys.length;
    _loaded = true;
  }

  Future<void> mergeCloudChapters(List<String> cloudKeys) async {
    await ensureLoaded();
    bool changed = false;
    for (final k in cloudKeys) {
      if (k.isNotEmpty && _completedKeys.add(k)) {
        changed = true;
      }
    }
    if (changed) {
      completedCountNotifier.value = _completedKeys.length;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, _completedKeys.toList());
    }
  }

  String _key(String abbrev, int chapter) => '$abbrev:$chapter';

  bool isChapterCompleted(String abbrev, int chapter) {
    return _completedKeys.contains(_key(abbrev, chapter));
  }

  Future<bool> toggleChapterCompleted(String abbrev, int chapter) async {
    await ensureLoaded();
    final k = _key(abbrev, chapter);
    bool nowCompleted;
    if (_completedKeys.contains(k)) {
      _completedKeys.remove(k);
      nowCompleted = false;
    } else {
      _completedKeys.add(k);
      nowCompleted = true;
    }
    completedCountNotifier.value = _completedKeys.length;
    final prefs = await SharedPreferences.getInstance();
    final list = _completedKeys.toList();
    await prefs.setStringList(_prefsKey, list);
    // Non-blocking cloud sync for signed-in users
    FirebaseService().syncBibleCompletedChapters(list);
    return nowCompleted;
  }

  int getBookCompletedChaptersCount(BibleBook book) {
    int cnt = 0;
    for (int c = 1; c <= book.chaptersCount; c++) {
      if (isChapterCompleted(book.abbrev, c)) cnt++;
    }
    return cnt;
  }

  int getTotalChaptersCount(List<BibleBook> books) {
    int total = 0;
    for (final b in books) {
      total += b.chaptersCount;
    }
    return total;
  }
}
