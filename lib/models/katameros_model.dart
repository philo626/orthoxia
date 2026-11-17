class KatamerosDay {
  final String dateGregorian;
  final String dateCoptic;
  final FastingInfo fastingInfo;
  final VerseOfTheDay verseOfTheDay;
  final ReadingPair vespers;
  final ReadingPair matins;
  final LiturgyReadings liturgy;

  KatamerosDay({
    required this.dateGregorian,
    required this.dateCoptic,
    required this.fastingInfo,
    required this.verseOfTheDay,
    required this.vespers,
    required this.matins,
    required this.liturgy,
  });

  factory KatamerosDay.fromJson(Map<String, dynamic> json) {
    return KatamerosDay(
      dateGregorian: json['date_gregorian'] ?? '',
      dateCoptic: json['date_coptic'] ?? '',
      fastingInfo: FastingInfo.fromJson(json['fasting_info'] ?? {}),
      verseOfTheDay: VerseOfTheDay.fromJson(json['verse_of_the_day'] ?? {}),
      vespers: ReadingPair.fromJson(json['vespers'] ?? {}),
      matins: ReadingPair.fromJson(json['matins'] ?? {}),
      liturgy: LiturgyReadings.fromJson(json['liturgy'] ?? {}),
    );
  }
}

class FastingInfo {
  final bool isFasting;
  final String seasonName;
  final String riteTone;

  FastingInfo({
    required this.isFasting,
    required this.seasonName,
    required this.riteTone,
  });

  factory FastingInfo.fromJson(Map<String, dynamic> json) {
    return FastingInfo(
      isFasting: json['is_fasting'] ?? false,
      seasonName: json['season_name'] ?? 'الأيام السنوية',
      riteTone: json['rite_tone'] ?? 'سنوي',
    );
  }
}

class VerseOfTheDay {
  final String text;
  final String reference;
  final String copticText;

  VerseOfTheDay({
    required this.text,
    required this.reference,
    required this.copticText,
  });

  factory VerseOfTheDay.fromJson(Map<String, dynamic> json) {
    return VerseOfTheDay(
      text: json['text'] ?? '',
      reference: json['reference'] ?? '',
      copticText: json['coptic_text'] ?? '',
    );
  }
}

class ReadingPair {
  final String psalm;
  final String gospel;

  ReadingPair({required this.psalm, required this.gospel});

  factory ReadingPair.fromJson(Map<String, dynamic> json) {
    return ReadingPair(
      psalm: json['psalm'] ?? '',
      gospel: json['gospel'] ?? '',
    );
  }
}

class LiturgyReadings {
  final String pauline;
  final String catholic;
  final String acts;
  final String synaxarium;
  final String gospelPsalm;
  final String gospel;

  LiturgyReadings({
    required this.pauline,
    required this.catholic,
    required this.acts,
    required this.synaxarium,
    required this.gospelPsalm,
    required this.gospel,
  });

  factory LiturgyReadings.fromJson(Map<String, dynamic> json) {
    return LiturgyReadings(
      pauline: json['pauline'] ?? '',
      catholic: json['catholic'] ?? '',
      acts: json['acts'] ?? '',
      synaxarium: json['synaxarium'] ?? '',
      gospelPsalm: json['gospel_psalm'] ?? '',
      gospel: json['gospel'] ?? '',
    );
  }
}
