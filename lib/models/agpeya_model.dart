class AgpeyaPsalm {
  final int number;
  final String title;
  final String text;

  AgpeyaPsalm({
    required this.number,
    required this.title,
    required this.text,
  });

  factory AgpeyaPsalm.fromJson(Map<String, dynamic> json) {
    return AgpeyaPsalm(
      number: json['number'] ?? 0,
      title: json['title'] ?? '',
      text: json['text'] ?? '',
    );
  }
}

class AgpeyaSection {
  final String type;
  final String title;
  final String? content;
  final List<AgpeyaPsalm>? psalms;

  AgpeyaSection({
    this.type = '',
    required this.title,
    this.content,
    this.psalms,
  });

  factory AgpeyaSection.fromJson(Map<String, dynamic> json) {
    return AgpeyaSection(
      type: (json['type'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      content: json['content']?.toString(),
      psalms: json['psalms'] != null
          ? (json['psalms'] as List).map((p) => AgpeyaPsalm.fromJson(p)).toList()
          : null,
    );
  }
}

class AgpeyaHour {
  final String id;
  final String nameAr;
  final String nameCoptic;
  final String hourSymbol;
  final String theme;
  final String timeRange;
  final List<AgpeyaSection> sections;

  AgpeyaHour({
    required this.id,
    required this.nameAr,
    required this.nameCoptic,
    required this.hourSymbol,
    required this.theme,
    required this.timeRange,
    required this.sections,
  });

  factory AgpeyaHour.fromJson(Map<String, dynamic> json) {
    return AgpeyaHour(
      id: (json['id'] ?? '').toString(),
      nameAr: (json['name_ar'] ?? '').toString(),
      nameCoptic: (json['name_coptic'] ?? '').toString(),
      hourSymbol: (json['hour_symbol'] ?? '').toString(),
      theme: (json['theme'] ?? '').toString(),
      timeRange: (json['time_range'] ?? '').toString(),
      sections: (json['sections'] as List? ?? [])
          .map((s) => AgpeyaSection.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
    );
  }
}
