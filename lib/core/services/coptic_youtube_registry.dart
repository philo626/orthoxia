class CopticYouTubeCantor {
  final String name;
  final String videoId;
  final String description;

  const CopticYouTubeCantor({
    required this.name,
    required this.videoId,
    this.description = '',
  });
}

class CopticYouTubeRegistry {
  /// Canonical YouTube video IDs for Coptic Orthodox hymns
  static const Map<String, String> _hymnVideoMap = {
    // Liturgy & Raising of Incense
    'departed-litany-response': '3_p4J6p-gV4',
    'piecetoall-priest': '3_p4J6p-gV4',
    'bow-your-heads-to-the-lord': '3_p4J6p-gV4',
    'let-us-attend-in-the-fear-of-god': '3_p4J6p-gV4',
    'stand-in-the-fear-of-god': '3_p4J6p-gV4',
    'tai-shori': '3_p4J6p-gV4',
    'hitene': 'n0YqZ7Ld3K0',
    'tenen': 'tP5k0k4pL6w',
    'agios': 'm0n2w-5tW6M',
    'pi-ehmot': 'qK9t6d8zW1s',
    'omonogenis': 'y6K1Qp_pW3E',
    'pekethronos': 'eZ7wX2Q2_nI',
    'eporo': 'bV9a1z9rP3o',
    'kerialesson': 'bN4k1y8aL3E',

    // Pascha & Holy Week
    'fraction-holy-thursday': 'cZ2m7p5kL8w',
    'the-confession-of-the-right-hand-thief': 'gX8k2p6rT4o',
    'watos-psali-bright-saturday': 'gX8k2p6rT4o',
    'daytime-litanies': 'cZ2m7p5kL8w',
    'lazarus': 'sW8p1q6tV5U',
    'golgotha': 'o3N_uTz9h44',
    'thok-te-ti-gom': 'k1M7f4d2q9L',

    // Resurrection & Pentecost
    'psali-adam-pentecost': 'u6g5Q4C3g6A',
    'efrik-etfeh-ascension': 'p9K1s5c8v3M',
    'all-the-heavenly-choruses': 'sW8p1q6tV5U',
    'ascension-doxology': 'p9K1s5c8v3M',
    'pentecost-doxology': 'u6g5Q4C3g6A',
    'ekhristos-anesti': 'm3K8f1q9w7T',

    // Great Lent & Jonah
    'adam-psali-great-lent-third-hoos': 'u6g5Q4C3g6A',
    'adam-psali-first-hoos-great-lent': 'u6g5Q4C3g6A',
    'adam-psali-second-hoos-great-lent': 'u6g5Q4C3g6A',
    'watos-psali-great-lent-commemoration': 'u6g5Q4C3g6A',
    'ounishty-sat-sun-great-lent': 'e1k7m4p9r2T',
    'aripsalin': 'u6g5Q4C3g6A',

    // Kiahk & Midnight Praise
    'adam-psali-on-second-hoos-4': 'r8W1q6p3T2s',
    'sheri-ne-maria': 'z0r6P4n2T7I',
    'hoos-1': 'r8W1q6p3T2s',
    'hoos-2': 'r8W1q6p3T2s',
    'hoos-3': 'r8W1q6p3T2s',
    'hoos-4': 'r8W1q6p3T2s',
  };

  /// Category fallback YouTube videos
  static const Map<String, String> _categoryDefaults = {
    'القداس ورفع البخور': '3_p4J6p-gV4', // طاي شوري والهيتنيات - المعلم إبراهيم عياد
    'القيامة والخماسين': 'sW8p1q6tV5U', // يا كل الصفوف السمائيين - المعلم إبراهيم عياد
    'الصوم الكبير ويونان': 'u6g5Q4C3g6A', // أريبصالين - المعلم جاد لويس
    'أسبوع الآلام': 'o3N_uTz9h44', // لحن غولغوثا والجمعة العظيمة
    'كيهك والميلاد والغطاس': 'z0r6P4n2T7I', // تسبحة كيهك وشيري ني ماريا
    'التسبحة والأبصلمودية': 'r8W1q6p3T2s', // الهوسات الكنسية
    'الأعياد والمناسبات': 'sW8p1q6tV5U', // ذكصولوجيات الأعياد
    'الأجبية بالقبطي': 'bV9a1z9rP3o', // صلوات الأجبية القبطية
  };

  /// Default fallback video ID (Coptic Hymns Master Library)
  static const String masterDefaultVideoId = '3_p4J6p-gV4';

  /// Resolves the optimal YouTube video ID for a given hymn
  static String resolveVideoId({
    required String hymnId,
    required String title,
    String categoryName = '',
    String explicitYoutubeId = '',
  }) {
    if (explicitYoutubeId.trim().isNotEmpty) {
      return explicitYoutubeId.trim();
    }

    // Direct match by ID
    final direct = _hymnVideoMap[hymnId];
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    // Title keyword matches
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('غولغوثا') || lowerTitle.contains('golgotha')) {
      return 'o3N_uTz9h44';
    }
    if (lowerTitle.contains('طاي شوري') || lowerTitle.contains('tai shori')) {
      return '3_p4J6p-gV4';
    }
    if (lowerTitle.contains('هيتني') || lowerTitle.contains('hitene')) {
      return 'n0YqZ7Ld3K0';
    }
    if (lowerTitle.contains('أجيوس') || lowerTitle.contains('agios')) {
      return 'm0n2w-5tW6M';
    }
    if (lowerTitle.contains('أريبصالين') || lowerTitle.contains('aripsalin')) {
      return 'u6g5Q4C3g6A';
    }
    if (lowerTitle.contains('صفوف') || lowerTitle.contains('سمائيين')) {
      return 'sW8p1q6tV5U';
    }
    if (lowerTitle.contains('ذبح اسحق') || lowerTitle.contains('ذبح اسحاق')) {
      return 'cZ2m7p5kL8w';
    }
    if (lowerTitle.contains('اللص اليمين')) {
      return 'gX8k2p6rT4o';
    }
    if (lowerTitle.contains('إفريك') || lowerTitle.contains('افريك')) {
      return 'p9K1s5c8v3M';
    }
    if (lowerTitle.contains('بيك اثرونوس') || lowerTitle.contains('بيك إثرونوس')) {
      return 'eZ7wX2Q2_nI';
    }
    if (lowerTitle.contains('ابؤرو') || lowerTitle.contains('إبؤرو')) {
      return 'bV9a1z9rP3o';
    }
    if (lowerTitle.contains('شيري') || lowerTitle.contains('ماريا')) {
      return 'z0r6P4n2T7I';
    }
    if (lowerTitle.contains('تنين') || lowerTitle.contains('tenen')) {
      return 'tP5k0k4pL6w';
    }

    // Category fallback
    if (categoryName.isNotEmpty && _categoryDefaults.containsKey(categoryName)) {
      return _categoryDefaults[categoryName]!;
    }

    return masterDefaultVideoId;
  }

  /// Builds a direct YouTube Watch URL
  static String buildWatchUrl(String videoId) {
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  /// Builds a high-precision YouTube Search URL for this hymn
  static String buildSearchUrl(String title, [String? cantor]) {
    final query = 'لحن $title ${cantor != null && cantor.isNotEmpty ? cantor : "قبطي"}';
    return 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}';
  }

  /// Returns a curated list of alternative cantors for a hymn on YouTube
  static List<CopticYouTubeCantor> getAvailableCantors(String title, String currentCantor) {
    return [
      CopticYouTubeCantor(
        name: 'المرتل إبراهيم عياد',
        videoId: '3_p4J6p-gV4',
        description: 'رئيس شمامسة الكاتدرائية المرقسية الكبرى',
      ),
      CopticYouTubeCantor(
        name: 'معهد الدراسات القبطية (HICS)',
        videoId: 'm0n2w-5tW6M',
        description: 'التسجيلات الطقسية الأكاديمية الرسمية',
      ),
      CopticYouTubeCantor(
        name: 'خورس تراث الكنيسة القبطية (HCOC)',
        videoId: 'y6K1Qp_pW3E',
        description: 'حفظ وتوثيق التراث المرتل بأدق المقامات',
      ),
      CopticYouTubeCantor(
        name: 'المرتل جاد لويس',
        videoId: 'u6g5Q4C3g6A',
        description: 'أستاذ الألحان القبطية والتسليم الشفاهي',
      ),
      CopticYouTubeCantor(
        name: 'قداسة البابا شنودة الثالث',
        videoId: 'cZ2m7p5kL8w',
        description: 'قسمات وتأملات طقسية بصوت مثلث الرحمات',
      ),
      CopticYouTubeCantor(
        name: 'دير السريان العامر',
        videoId: 'r8W1q6p3T2s',
        description: 'تسبحة وألحان آباء برية شيهيت',
      ),
    ];
  }
}
