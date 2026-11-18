import '../core/services/coptic_youtube_registry.dart';

class HymnVerse {
  final String coptic;
  final String arabized;
  final String arabic;
  final int startMs;
  final int endMs;

  HymnVerse({
    required this.coptic,
    required this.arabized,
    required this.arabic,
    this.startMs = 0,
    this.endMs = 0,
  });

  factory HymnVerse.fromJson(Map<String, dynamic> json) {
    return HymnVerse(
      coptic: json['coptic'] ?? '',
      arabized: json['arabized'] ?? '',
      arabic: json['arabic'] ?? '',
      startMs: json['start_ms'] ?? 0,
      endMs: json['end_ms'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'coptic': coptic,
        'arabized': arabized,
        'arabic': arabic,
        'start_ms': startMs,
        'end_ms': endMs,
      };
}

class HymnRecording {
  final String url;
  final String cantor;
  final String info;
  final String youtubeId;

  HymnRecording({
    required this.url,
    required this.cantor,
    this.info = '',
    this.youtubeId = '',
  });

  factory HymnRecording.fromJson(Map<String, dynamic> json) {
    return HymnRecording(
      url: json['url'] ?? '',
      cantor: json['cantor'] ?? 'المرتل إبراهيم عياد',
      info: json['info'] ?? '',
      youtubeId: json['youtube_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'cantor': cantor,
        'info': info,
        'youtube_id': youtubeId,
      };
}

class CopticWordAnalysis {
  final String coptic;
  final String origin;
  final String meaning;

  CopticWordAnalysis({
    required this.coptic,
    this.origin = '',
    required this.meaning,
  });

  factory CopticWordAnalysis.fromJson(Map<String, dynamic> json) {
    return CopticWordAnalysis(
      coptic: json['coptic'] ?? '',
      origin: json['origin'] ?? '',
      meaning: json['meaning'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'coptic': coptic,
        'origin': origin,
        'meaning': meaning,
      };
}

class Hymn {
  final String id;
  final String title;
  final String categoryId;
  final String categoryName;
  final String cantor;
  final String audioUrl;
  final String localAsset;
  final String youtubeId;
  final String youtubeTitle;
  final bool exactYoutube;
  final String youtubeUrl;
  final List<HymnRecording> recordings;
  final int versesCount;
  final List<HymnVerse> verses;
  final List<CopticWordAnalysis> analysis;

  Hymn({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.categoryName,
    required this.cantor,
    required this.audioUrl,
    this.localAsset = '',
    this.youtubeId = '',
    this.youtubeTitle = '',
    this.exactYoutube = true,
    this.youtubeUrl = '',
    this.recordings = const [],
    required this.versesCount,
    required this.verses,
    this.analysis = const [],
  });

  /// Resolved authentic YouTube video ID for online playback
  String get resolvedYoutubeId {
    return CopticYouTubeRegistry.resolveVideoId(
      hymnId: id,
      title: title,
      categoryName: categoryName,
      explicitYoutubeId: youtubeId,
    );
  }

  /// Direct YouTube watch URL
  String get youtubeWatchUrl => CopticYouTubeRegistry.buildWatchUrl(resolvedYoutubeId);

  /// High precision YouTube search query URL for this hymn
  String get youtubeSearchUrl => CopticYouTubeRegistry.buildSearchUrl(title, cantor);

  factory Hymn.fromJson(Map<String, dynamic> json) {
    final list = json['verses'] as List? ?? [];
    final recList = json['recordings'] as List? ?? [];
    final anaList = json['analysis'] as List? ?? [];
    return Hymn(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      categoryId: json['category_id'] ?? '',
      categoryName: json['category_name'] ?? '',
      cantor: json['cantor'] ?? 'المرتل إبراهيم عياد',
      audioUrl: json['audio_url'] ?? '',
      localAsset: json['local_asset'] ?? '',
      youtubeId: json['youtube_id'] ?? '',
      youtubeTitle: json['youtube_title'] ?? '',
      exactYoutube: json['exact_youtube'] ?? true,
      youtubeUrl: json['youtube_url'] ?? '',
      recordings: recList.map((r) => HymnRecording.fromJson(Map<String, dynamic>.from(r))).toList(),
      versesCount: json['verses_count'] ?? list.length,
      verses: list.map((v) => HymnVerse.fromJson(Map<String, dynamic>.from(v))).toList(),
      analysis: anaList.map((a) => CopticWordAnalysis.fromJson(Map<String, dynamic>.from(a))).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category_id': categoryId,
        'category_name': categoryName,
        'cantor': cantor,
        'audio_url': audioUrl,
        'local_asset': localAsset,
        'youtube_id': youtubeId,
        'youtube_title': youtubeTitle,
        'exact_youtube': exactYoutube,
        'youtube_url': youtubeUrl,
        'recordings': recordings.map((r) => r.toJson()).toList(),
        'verses_count': versesCount,
        'verses': verses.map((v) => v.toJson()).toList(),
        'analysis': analysis.map((a) => a.toJson()).toList(),
      };
}
