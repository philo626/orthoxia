class BookChapter {
  final String id;
  final int chapterNumber;
  final String title;
  final String content;

  BookChapter({
    required this.id,
    required this.chapterNumber,
    required this.title,
    required this.content,
  });

  factory BookChapter.fromJson(Map<String, dynamic> json) {
    return BookChapter(
      id: json['id'] ?? '',
      chapterNumber: json['chapter_number'] ?? 1,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'chapter_number': chapterNumber,
    'title': title,
    'content': content,
  };
}

class Book {
  final String id;
  final String title;
  final String author;
  final String categoryId;
  final String categoryName;
  final String description;
  final int chaptersCount;
  final String coverIcon;
  final bool isFeatured;
  final List<BookChapter> chapters;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.chaptersCount,
    this.coverIcon = '📖',
    this.isFeatured = false,
    required this.chapters,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    final list = json['chapters'] as List? ?? [];
    return Book(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? 'آباء الكنيسة القبطية',
      categoryId: json['category_id'] ?? 'general',
      categoryName: json['category_name'] ?? 'كتب روحية',
      description: json['description'] ?? '',
      chaptersCount: json['chapters_count'] ?? list.length,
      coverIcon: json['cover_icon'] ?? '📖',
      isFeatured: json['is_featured'] ?? false,
      chapters: list.map((c) => BookChapter.fromJson(c)).toList(),
    );
  }
}
