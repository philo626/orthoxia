class PrayerRequest {
  final String id;
  final String authorName;
  final bool isAnonymous;
  final String title;
  final String content;
  final DateTime createdAt;
  int prayedCount;
  bool hasPrayed;

  PrayerRequest({
    required this.id,
    required this.authorName,
    required this.isAnonymous,
    required this.title,
    required this.content,
    required this.createdAt,
    this.prayedCount = 0,
    this.hasPrayed = false,
  });

  factory PrayerRequest.fromJson(Map<String, dynamic> json) {
    return PrayerRequest(
      id: json['id'] ?? '',
      authorName: json['isAnonymous'] == true ? 'ابن للكنيسة (فاعل خير)' : (json['authorName'] ?? 'فاعل خير'),
      isAnonymous: json['isAnonymous'] ?? true,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      prayedCount: json['prayedCount'] ?? 0,
      hasPrayed: json['hasPrayed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'authorName': authorName,
    'isAnonymous': isAnonymous,
    'title': title,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
    'prayedCount': prayedCount,
    'hasPrayed': hasPrayed,
  };
}
