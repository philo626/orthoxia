import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/bible_model.dart';

class BibleProvider extends ChangeNotifier {
  List<BibleBook> _allBooks = [];
  bool _isLoading = false;
  String _searchQuery = '';
  List<BibleSearchResult> _searchResults = [];
  String _selectedTestament = 'ALL'; // 'ALL', 'OLD', 'NEW'
  
  // Currently active book and chapter in reader
  BibleBook? _currentBook;
  int _currentChapter = 1; // 1-indexed

  List<BibleBook> get allBooks => _allBooks;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  List<BibleSearchResult> get searchResults => _searchResults;
  String get selectedTestament => _selectedTestament;
  BibleBook? get currentBook => _currentBook;
  int get currentChapter => _currentChapter;

  List<BibleBook> get oldTestamentBooks =>
      _allBooks.where((b) => b.testament == 'OLD').toList();

  List<BibleBook> get newTestamentBooks =>
      _allBooks.where((b) => b.testament == 'NEW').toList();

  List<BibleBook> get filteredBooks {
    List<BibleBook> list;
    if (_selectedTestament == 'OLD') {
      list = oldTestamentBooks;
    } else if (_selectedTestament == 'NEW') {
      list = newTestamentBooks;
    } else {
      list = _allBooks;
    }

    if (_searchQuery.trim().isEmpty) {
      return list;
    }
    final q = _searchQuery.trim().toLowerCase();
    return list.where((b) => b.name.toLowerCase().contains(q)).toList();
  }

  Future<void> loadBible() async {
    if (_allBooks.isNotEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      final jsonString = await rootBundle.loadString('assets/data/bible.json');
      final List<dynamic> data = json.decode(jsonString);
      
      _allBooks = [];
      for (int i = 0; i < data.length; i++) {
        _allBooks.add(BibleBook.fromJson(data[i], i));
      }

      if (_allBooks.isNotEmpty && _currentBook == null) {
        // Default to Gospel of Matthew (New Testament) or Genesis
        _currentBook = _allBooks.firstWhere(
          (b) => b.abbrev == 'mt' || b.name.contains('متى'),
          orElse: () => _allBooks.first,
        );
        _currentChapter = 1;
      }
    } catch (e) {
      debugPrint('Error loading Bible: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setTestament(String testament) {
    _selectedTestament = testament;
    notifyListeners();
  }

  void setCurrentBookAndChapter(BibleBook book, int chapter) {
    _currentBook = book;
    _currentChapter = chapter.clamp(1, book.chaptersCount);
    notifyListeners();
  }

  void nextChapter() {
    if (_currentBook == null) return;
    if (_currentChapter < _currentBook!.chaptersCount) {
      _currentChapter++;
      notifyListeners();
    } else {
      // Go to next book
      final nextIndex = _currentBook!.index + 1;
      if (nextIndex < _allBooks.length) {
        _currentBook = _allBooks[nextIndex];
        _currentChapter = 1;
        notifyListeners();
      }
    }
  }

  void previousChapter() {
    if (_currentBook == null) return;
    if (_currentChapter > 1) {
      _currentChapter--;
      notifyListeners();
    } else {
      // Go to previous book last chapter
      final prevIndex = _currentBook!.index - 1;
      if (prevIndex >= 0) {
        _currentBook = _allBooks[prevIndex];
        _currentChapter = _currentBook!.chaptersCount;
        notifyListeners();
      }
    }
  }

  void searchVerses(String query) {
    _searchQuery = query;
    if (query.trim().length < 2) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    final q = query.trim().toLowerCase();
    final results = <BibleSearchResult>[];

    // Search through all books
    for (final book in _allBooks) {
      for (int chIdx = 0; chIdx < book.chapters.length; chIdx++) {
        final chapter = book.chapters[chIdx];
        for (int vIdx = 0; vIdx < chapter.length; vIdx++) {
          final verse = chapter[vIdx];
          if (verse.toLowerCase().contains(q)) {
            results.add(
              BibleSearchResult(
                book: book,
                chapterNumber: chIdx + 1,
                verseNumber: vIdx + 1,
                verseText: verse,
              ),
            );
            // Limit search results to 150 for ultra fast UI rendering
            if (results.length >= 150) break;
          }
        }
        if (results.length >= 150) break;
      }
      if (results.length >= 150) break;
    }

    _searchResults = results;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    notifyListeners();
  }
}
