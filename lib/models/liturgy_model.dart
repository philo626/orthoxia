class LiturgyVerse {
  final String role; // 'priest', 'deacon', 'people', 'all'
  final String roleArabic;
  final String coptic;
  final String arabized;
  final String arabic;

  LiturgyVerse({
    required this.role,
    required this.roleArabic,
    required this.coptic,
    required this.arabized,
    required this.arabic,
  });

  factory LiturgyVerse.fromJson(Map<String, dynamic> json) {
    return LiturgyVerse(
      role: json['role'] ?? 'all',
      roleArabic: json['roleArabic'] ?? '',
      coptic: json['coptic'] ?? '',
      arabized: json['arabized'] ?? '',
      arabic: json['arabic'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'role': role,
    'roleArabic': roleArabic,
    'coptic': coptic,
    'arabized': arabized,
    'arabic': arabic,
  };
}

class LiturgySection {
  final String id;
  final String title;
  final String tafseer;
  final List<LiturgyVerse> verses;

  LiturgySection({
    required this.id,
    required this.title,
    this.tafseer = '',
    required this.verses,
  });

  factory LiturgySection.fromJson(Map<String, dynamic> json) {
    final list = json['verses'] as List? ?? [];
    return LiturgySection(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      tafseer: json['tafseer'] ?? '',
      verses: list.map((v) => LiturgyVerse.fromJson(v)).toList(),
    );
  }
}

class Liturgy {
  final String id;
  final String title;
  final String type; // 'basil', 'gregory', 'cyril'
  final String description;
  final List<LiturgySection> sections;

  Liturgy({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.sections,
  });

  factory Liturgy.fromJson(Map<String, dynamic> json) {
    final list = json['sections'] as List? ?? [];
    return Liturgy(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      type: json['type'] ?? 'basil',
      description: json['description'] ?? '',
      sections: list.map((s) => LiturgySection.fromJson(s)).toList(),
    );
  }
}
