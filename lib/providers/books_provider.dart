import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/book_model.dart';
import '../models/commentary_model.dart';

class BooksProvider with ChangeNotifier {
  List<Book> _books = [];
  List<BibleBookCommentary> _commentaries = [];
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isLoading = true;

  final Set<String> _bookmarkedChapterIds = {};

  List<Book> get books => _books;
  List<BibleBookCommentary> get commentaries => _commentaries;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  Set<String> get bookmarkedChapterIds => _bookmarkedChapterIds;

  final List<Map<String, String>> categories = [
    {'id': 'all', 'name': 'الكل'},
    {'id': 'commentaries', 'name': 'تفاسير الكتاب المقدس'},
    {'id': 'patrology', 'name': 'كتابات الآباء الأولين'},
    {'id': 'pope_shenouda', 'name': 'كتب البابا شنوده الثالث'},
    {'id': 'spirituality', 'name': 'بستان الرهبان والقداسة'},
    {'id': 'rites', 'name': 'الطقوس الكنسية والألحان'},
  ];

  BooksProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Load Books
      final booksRaw = await rootBundle.loadString('assets/data/books.json');
      final booksList = jsonDecode(booksRaw) as List;
      _books = booksList.map((b) => Book.fromJson(b)).toList();

      // 2. Load Commentaries
      final commRaw = await rootBundle.loadString('assets/data/commentaries.json');
      final commList = jsonDecode(commRaw) as List;
      _commentaries = commList.map((c) => BibleBookCommentary.fromJson(c)).toList();
    } catch (e) {
      // Graceful error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(String catId) {
    _selectedCategory = catId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  List<Book> get filteredBooks {
    if (_selectedCategory == 'commentaries') {
      return [];
    }

    return _books.where((b) {
      final matchCat = _selectedCategory == 'all' || b.categoryId == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty ||
          b.title.contains(_searchQuery) ||
          b.author.contains(_searchQuery) ||
          b.description.contains(_searchQuery);
      return matchCat && matchSearch;
    }).toList();
  }

  List<BibleBookCommentary> get filteredCommentaries {
    if (_selectedCategory != 'all' && _selectedCategory != 'commentaries') {
      return [];
    }

    return _commentaries.where((c) {
      final matchSearch = _searchQuery.isEmpty ||
          c.bibleBookName.contains(_searchQuery) ||
          c.commentator.contains(_searchQuery) ||
          c.summary.contains(_searchQuery);
      return matchSearch;
    }).toList();
  }

  void toggleBookmark(String chapterId) {
    if (_bookmarkedChapterIds.contains(chapterId)) {
      _bookmarkedChapterIds.remove(chapterId);
    } else {
      _bookmarkedChapterIds.add(chapterId);
    }
    notifyListeners();
  }

  bool isBookmarked(String chapterId) {
    return _bookmarkedChapterIds.contains(chapterId);
  }
}
