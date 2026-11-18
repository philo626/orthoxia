class BibleBook {
  final String abbrev;
  final String name;
  final List<List<String>> chapters;
  final String testament; // 'OLD' or 'NEW'
  final int index; // 0 to 65

  BibleBook({
    required this.abbrev,
    required this.name,
    required this.chapters,
    required this.testament,
    required this.index,
  });

  int get chaptersCount => chapters.length;

  factory BibleBook.fromJson(Map<String, dynamic> json, int index) {
    final rawChapters = json['chapters'] as List? ?? [];
    final parsedChapters = rawChapters.map((ch) {
      if (ch is List) {
        return ch.map((v) => v.toString()).toList();
      }
      return <String>[];
    }).toList();

    final testament = json['testament']?.toString() ?? (index < 39 ? 'OLD' : 'NEW');

    return BibleBook(
      abbrev: json['abbrev'] ?? '',
      name: json['name'] ?? '',
      chapters: parsedChapters,
      testament: testament,
      index: index,
    );
  }
}

class BibleSearchResult {
  final BibleBook book;
  final int chapterNumber; // 1-indexed
  final int verseNumber; // 1-indexed
  final String verseText;

  BibleSearchResult({
    required this.book,
    required this.chapterNumber,
    required this.verseNumber,
    required this.verseText,
  });
}
