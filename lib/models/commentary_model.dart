class CommentaryVerse {
  final int verseNumber;
  final String scriptureText;
  final String patristicCommentary;
  final String citation;

  CommentaryVerse({
    required this.verseNumber,
    required this.scriptureText,
    required this.patristicCommentary,
    required this.citation,
  });

  factory CommentaryVerse.fromJson(Map<String, dynamic> json) {
    return CommentaryVerse(
      verseNumber: json['verse_number'] ?? 1,
      scriptureText: json['scripture_text'] ?? '',
      patristicCommentary: json['patristic_commentary'] ?? '',
      citation: json['citation'] ?? '',
    );
  }
}

class CommentaryChapter {
  final int chapterNumber;
  final String title;
  final String introduction;
  final List<CommentaryVerse> verses;

  CommentaryChapter({
    required this.chapterNumber,
    required this.title,
    required this.introduction,
    required this.verses,
  });

  factory CommentaryChapter.fromJson(Map<String, dynamic> json) {
    final list = json['verses'] as List? ?? [];
    return CommentaryChapter(
      chapterNumber: json['chapter_number'] ?? 1,
      title: json['title'] ?? '',
      introduction: json['introduction'] ?? '',
      verses: list.map((v) => CommentaryVerse.fromJson(v)).toList(),
    );
  }
}

class BibleBookCommentary {
  final String id;
  final String bibleBookName;
  final String testament; // 'NEW_TESTAMENT', 'OLD_TESTAMENT'
  final String commentator;
  final String summary;
  final List<CommentaryChapter> chapters;

  BibleBookCommentary({
    required this.id,
    required this.bibleBookName,
    required this.testament,
    required this.commentator,
    required this.summary,
    required this.chapters,
  });

  factory BibleBookCommentary.fromJson(Map<String, dynamic> json) {
    final list = json['chapters'] as List? ?? [];
    return BibleBookCommentary(
      id: json['id'] ?? '',
      bibleBookName: json['bible_book_name'] ?? '',
      testament: json['testament'] ?? 'NEW_TESTAMENT',
      commentator: json['commentator'] ?? 'القمص تادرس يعقوب ملطي',
      summary: json['summary'] ?? '',
      chapters: list.map((c) => CommentaryChapter.fromJson(c)).toList(),
    );
  }
}
