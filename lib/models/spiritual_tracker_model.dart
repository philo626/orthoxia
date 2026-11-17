class SpiritualLog {
  final String date; // YYYY-MM-DD
  int bibleChaptersRead;
  int agpeyaHoursCompleted;
  int personalPrayerMinutes;
  bool tookCommunion;
  bool actsOfCharity;
  String reflectionNote;

  SpiritualLog({
    required this.date,
    this.bibleChaptersRead = 0,
    this.agpeyaHoursCompleted = 0,
    this.personalPrayerMinutes = 0,
    this.tookCommunion = false,
    this.actsOfCharity = false,
    this.reflectionNote = '',
  });

  factory SpiritualLog.fromJson(Map<String, dynamic> json) {
    return SpiritualLog(
      date: json['date'] ?? '',
      bibleChaptersRead: json['bibleChaptersRead'] ?? 0,
      agpeyaHoursCompleted: json['agpeyaHoursCompleted'] ?? 0,
      personalPrayerMinutes: json['personalPrayerMinutes'] ?? 0,
      tookCommunion: json['tookCommunion'] ?? false,
      actsOfCharity: json['actsOfCharity'] ?? false,
      reflectionNote: json['reflectionNote'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'bibleChaptersRead': bibleChaptersRead,
    'agpeyaHoursCompleted': agpeyaHoursCompleted,
    'personalPrayerMinutes': personalPrayerMinutes,
    'tookCommunion': tookCommunion,
    'actsOfCharity': actsOfCharity,
    'reflectionNote': reflectionNote,
  };
}

class ConscienceQuestion {
  final String id;
  final String category; // 'WITH_GOD', 'WITH_OTHERS', 'WITH_SELF'
  final String title;
  final String explanation;
  bool isChecked;
  String personalNote;

  ConscienceQuestion({
    required this.id,
    required this.category,
    required this.title,
    required this.explanation,
    this.isChecked = false,
    this.personalNote = '',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'title': title,
    'explanation': explanation,
    'isChecked': isChecked,
    'personalNote': personalNote,
  };

  factory ConscienceQuestion.fromJson(Map<String, dynamic> json) {
    return ConscienceQuestion(
      id: json['id'],
      category: json['category'],
      title: json['title'],
      explanation: json['explanation'],
      isChecked: json['isChecked'] ?? false,
      personalNote: json['personalNote'] ?? '',
    );
  }
}
