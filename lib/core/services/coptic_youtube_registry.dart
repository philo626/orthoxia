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
  static final RegExp _ytIdRegex = RegExp(r'^[a-zA-Z0-9_-]{11}$');

  /// Direct verified map by hymn slug if explicitYoutubeId is empty
  static const Map<String, String> _hymnVideoMap = {
    'psali-adam-pentecost': 'wMY14z83qNg',
    'aripsalin': '1fhw8IYL02I',
    'fraction-holy-thursday': 'XLqpt5HJras',
    'the-confession-of-the-right-hand-thief': 'VvAVF8zcWaA',
    'adam-psali-on-second-hoos-4': 'Cvrdybv_9-M',
    'watos-psali-bright-saturday': 'V7ubgDjRHy0',
    'hoos_kiahk': 'zi_-GOPrldY',
    'daytime-litanies': 'Xu5gc7LrrSI',
    'saturday-lobsh': 'RUDXPS5wV_4',
    'saturday-theotokia': 'fMPU-_l6Dng',
    'sunday-theotokia15': 'mchPkLcE50I',
    'efrik-etfeh-ascension': 'HroG5veVO5A',
    'wednesday-psali': 'HaznXuIXqqA',
    'lazarus': 'D0zkpzhEM8o',
    'the-orthodox-creed': 'p6dXu-zJ9d8',
    'tai-shori': 'RIRb2ED0qvE',
    'hitene': 'SEFJNb_-JgE',
    'tenen': 'QJ4uwZdy_7U',
    'agios': '_R03VturUEg',
    'pi-ehmot': 'XF2UvZA953k',
    'omonogenis': 'TP6xIUxhOgA',
    'pekethronos': 'svoEcl7t5dE',
    'eporo': 'zld51r43YyU',
    'kerialesson': 'GmkNsXdFpJU',
    'golgotha': '6iuEVnKP7rU',
    'thok-te-ti-gom': '676sEDTHsns',
    'thok-te-tigom': '676sEDTHsns',
    'all-the-heavenly-choruses': 'zoMLL5Abtew',
    'ascension-doxology': '-6ijA2bN1Ew',
    'pentecost-doxology': 'zoMLL5Abtew',
    'ekhristos-anesti': 'ioi4KmLau6o',
    'sheri-ne-maria': '8p43TAdEd40',
    'hoos-1': 'o5CIYH07ur0',
    'hoos-2': 'AceZHsiBlvQ',
    'hoos-3': 'mtAXMS_MSik',
    'hoos-4': 'j8oEiqEnDhM',
  };

  /// Category fallback verified YouTube videos
  static const Map<String, String> _categoryDefaults = {
    'القداس ورفع البخور': 'RIRb2ED0qvE',
    'القيامة والخماسين': 'zoMLL5Abtew',
    'الصوم الكبير ويونان': 'DcR5CZdSEhk',
    'أسبوع الآلام': '6iuEVnKP7rU',
    'كيهك والميلاد والغطاس': 'Dlu3GI_oIC8',
    'التسبحة والأبصلمودية': 'o5CIYH07ur0',
    'الأعياد والمناسبات': 'zld51r43YyU',
  };

  static const String masterDefaultVideoId = 'RIRb2ED0qvE';

  /// Resolves the best YouTube video ID for a given hymn.
  static String resolveVideoId({
    required String hymnId,
    required String title,
    String categoryName = '',
    String explicitYoutubeId = '',
  }) {
    final trimmed = explicitYoutubeId.trim();
    if (_ytIdRegex.hasMatch(trimmed)) {
      return trimmed;
    }

    final direct = _hymnVideoMap[hymnId];
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }

    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('غولغوثا') || lowerTitle.contains('golgotha')) {
      return '6iuEVnKP7rU';
    }
    if (lowerTitle.contains('طاي شوري') ||
        lowerTitle.contains('طاى شورى') ||
        lowerTitle.contains('tai shori')) {
      return 'RIRb2ED0qvE';
    }
    if (lowerTitle.contains('هيتني') || lowerTitle.contains('hitene')) {
      return 'SEFJNb_-JgE';
    }
    if (lowerTitle.contains('أجيوس') ||
        lowerTitle.contains('اجيوس') ||
        lowerTitle.contains('agios')) {
      return '_R03VturUEg';
    }
    if (lowerTitle.contains('أريبصالين') ||
        lowerTitle.contains('اريبصالين') ||
        lowerTitle.contains('aripsalin')) {
      return '1fhw8IYL02I';
    }
    if (lowerTitle.contains('صفوف') || lowerTitle.contains('سمائيين')) {
      return 'zoMLL5Abtew';
    }
    if (lowerTitle.contains('اللص اليمين') || lowerTitle.contains('امانة اللص')) {
      return 'VvAVF8zcWaA';
    }
    if (lowerTitle.contains('إفريك') ||
        lowerTitle.contains('افريك') ||
        lowerTitle.contains('صعود')) {
      return 'HroG5veVO5A';
    }
    if (lowerTitle.contains('بيك اثرونوس') ||
        lowerTitle.contains('بيك إثرونوس')) {
      return 'svoEcl7t5dE';
    }
    if (lowerTitle.contains('ابؤرو') || lowerTitle.contains('إبؤرو')) {
      return 'zld51r43YyU';
    }
    if (lowerTitle.contains('شيري') || lowerTitle.contains('ماريا')) {
      return '8p43TAdEd40';
    }
    if (lowerTitle.contains('تنين') || lowerTitle.contains('tenen')) {
      return 'QJ4uwZdy_7U';
    }
    if (lowerTitle.contains('ثوك') || lowerTitle.contains('تسبحة البصخة')) {
      return '676sEDTHsns';
    }
    if (lowerTitle.contains('اخرستوس') || lowerTitle.contains('قيامة')) {
      return 'ioi4KmLau6o';
    }
    if (lowerTitle.contains('اومونوجينيس') ||
        lowerTitle.contains('أومونوجينيس')) {
      return 'TP6xIUxhOgA';
    }
    if (lowerTitle.contains('اهموت') || lowerTitle.contains('أهموت')) {
      return 'XF2UvZA953k';
    }
    if (lowerTitle.contains('لعازر')) return 'D0zkpzhEM8o';
    if (lowerTitle.contains('كيرياليسون')) return 'GmkNsXdFpJU';
    if (lowerTitle.contains('الهوس الأول') ||
        lowerTitle.contains('الهوس الاول')) {
      return 'o5CIYH07ur0';
    }
    if (lowerTitle.contains('الهوس الثاني') ||
        lowerTitle.contains('الهوس الثانى')) {
      return 'AceZHsiBlvQ';
    }
    if (lowerTitle.contains('الهوس الثالث')) return 'mtAXMS_MSik';
    if (lowerTitle.contains('الهوس الرابع')) return 'j8oEiqEnDhM';

    if (categoryName.isNotEmpty && _categoryDefaults.containsKey(categoryName)) {
      return _categoryDefaults[categoryName]!;
    }

    return masterDefaultVideoId;
  }

  static String buildWatchUrl(String videoId) {
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  static String buildSearchUrl(String hymnTitle, [String cantor = '']) {
    final query = Uri.encodeComponent('لحن $hymnTitle قبطي $cantor'.trim());
    return 'https://www.youtube.com/results?search_query=$query';
  }

  /// Returns ONLY verified recordings matching this specific hymn (never mixes
  /// unrelated hymns into the cantor list).
  static List<CopticYouTubeCantor> getAvailableCantors({
    required String hymnTitle,
    required String defaultCantor,
    required String primaryVideoId,
    String primaryVideoTitle = '',
    bool isExactMatch = true,
  }) {
    if (!isExactMatch) {
      return const [];
    }
    return [
      CopticYouTubeCantor(
        name: primaryVideoTitle.isNotEmpty
            ? primaryVideoTitle
            : '$hymnTitle — $defaultCantor',
        videoId: primaryVideoId,
        description: 'التسجيل الموثّق المطابق للحن «$hymnTitle»',
      ),
    ];
  }
}
