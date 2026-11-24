import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'security_guard_service.dart';

enum AiProviderType { gemini, groq, customProxy }

class AiApiConfig {
  final AiProviderType provider;
  final String apiKey;
  final String customEndpoint;
  final String customModel;

  const AiApiConfig({
    this.provider = AiProviderType.gemini,
    this.apiKey = '',
    this.customEndpoint = '',
    this.customModel = '',
  });

  bool get isConfigured =>
      provider == AiProviderType.customProxy
          ? customEndpoint.trim().startsWith('https://')
          : apiKey.trim().length >= 12;

  String get providerDisplayName {
    switch (provider) {
      case AiProviderType.gemini:
        return 'Google Gemini';
      case AiProviderType.groq:
        return 'Groq (Llama 3.3)';
      case AiProviderType.customProxy:
        return customModel == 'orthoxia-cloud'
            ? 'سحابة أرثوذكسيا'
            : 'خادم مخصص';
    }
  }
}

class AiMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? citations;

  AiMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.citations,
  });

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    return AiMessage(
      text: json['text']?.toString() ?? '',
      isUser: json['isUser'] == true,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      citations: json['citations'] is List
          ? (json['citations'] as List).map((e) => e.toString()).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        if (citations != null) 'citations': citations,
      };
}

class AiTheologyService {
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
      keyCipherAlgorithm:
          KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
  );
  static const _cfgProviderKey = 'ai_provider_type_v1';
  static const _cfgApiKeyKey = 'ai_provider_apikey_v1';
  static const _cfgEndpointKey = 'ai_provider_endpoint_v1';
  static const _cfgModelKey = 'ai_provider_model_v1';

  /// Built-in Serverless AI Proxy URL (keeps Gemini/Groq API keys 100% hidden server-side).
  /// Hosted on Vercel (100% free & unblocked across Egypt ISPs) so ALL app users get
  /// live Coptic Orthodox AI out-of-the-box with zero API key setup.
  static const String builtInCloudflareWorkerUrl =
      'https://orthoxia-vercel-api.vercel.app/v1/chat/completions';
  static const String builtInClientHeaderToken = '';

  static AiApiConfig _builtInDefaultConfig() {
    if (builtInCloudflareWorkerUrl.startsWith('https://')) {
      return const AiApiConfig(
        provider: AiProviderType.customProxy,
        customEndpoint: builtInCloudflareWorkerUrl,
        apiKey: builtInClientHeaderToken,
        customModel: 'orthoxia-cloud',
      );
    }
    return const AiApiConfig();
  }

  static List<dynamic>? _booksCache;
  static List<dynamic>? _bibleCache;
  static Map<String, dynamic>? _lectionaryCache;
  static AiApiConfig? _cachedConfig;

  static Future<AiApiConfig> loadConfig() async {
    if (_cachedConfig != null) return _cachedConfig!;
    try {
      final pStr = await _secureStorage.read(key: _cfgProviderKey) ?? '';
      final apiKey = (await _secureStorage.read(key: _cfgApiKeyKey) ?? '').trim();
      final endpoint = (await _secureStorage.read(key: _cfgEndpointKey) ?? '').trim();
      final model = (await _secureStorage.read(key: _cfgModelKey) ?? '').trim();

      if (pStr.isEmpty && apiKey.isEmpty && endpoint.isEmpty) {
        _cachedConfig = _builtInDefaultConfig();
        return _cachedConfig!;
      }

      final provider = AiProviderType.values.firstWhere(
        (e) => e.name == pStr,
        orElse: () => AiProviderType.gemini,
      );
      final userCfg = AiApiConfig(
        provider: provider,
        apiKey: apiKey,
        customEndpoint: endpoint,
        customModel: model,
      );
      _cachedConfig = userCfg.isConfigured ? userCfg : _builtInDefaultConfig();
      return _cachedConfig!;
    } catch (_) {
      return _builtInDefaultConfig();
    }
  }

  static Future<void> saveConfig(AiApiConfig config) async {
    _cachedConfig = config;
    try {
      await _secureStorage.write(
          key: _cfgProviderKey, value: config.provider.name);
      await _secureStorage.write(
          key: _cfgApiKeyKey, value: config.apiKey.trim());
      await _secureStorage.write(
          key: _cfgEndpointKey, value: config.customEndpoint.trim());
      await _secureStorage.write(
          key: _cfgModelKey, value: config.customModel.trim());
    } catch (_) {}
  }

  static Future<void> clearConfig() async {
    _cachedConfig = _builtInDefaultConfig();
    try {
      await _secureStorage.delete(key: _cfgProviderKey);
      await _secureStorage.delete(key: _cfgApiKeyKey);
      await _secureStorage.delete(key: _cfgEndpointKey);
      await _secureStorage.delete(key: _cfgModelKey);
    } catch (_) {}
  }

  static Future<void> _ensureLocalRagLoaded() async {
    if (_booksCache == null) {
      try {
        final raw = await rootBundle.loadString('assets/data/books.json');
        _booksCache = jsonDecode(raw) as List<dynamic>;
      } catch (_) {
        _booksCache = [];
      }
    }
    if (_bibleCache == null) {
      try {
        final raw = await rootBundle.loadString('assets/data/bible.json');
        _bibleCache = jsonDecode(raw) as List<dynamic>;
      } catch (_) {
        _bibleCache = [];
      }
    }
    if (_lectionaryCache == null) {
      try {
        final raw =
            await rootBundle.loadString('assets/data/synaxarium_ar.json');
        _lectionaryCache = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        _lectionaryCache = {};
      }
    }
  }

  static final Map<String, Map<String, dynamic>> _patristicKnowledgeBase = {
    'مفهوم التوبة': {
      'response':
          'التوبة في المفهوم الأرثوذكسي ليست مجرد ندم نفسي، بل هي «ميتانويا» (Μετάνοια) أي تجديد الذهن وتغيير اتجاه القلب بالكامل نحو محبة الله.\n\nيقول القديس يوحنا ذهبي الفم: «التوبة هي الدواء الذي يمحو الخطية، وهي عطية سماوية تغلب عدالة الدينونة بالرحمة».\n\nوتتوج التوبة في الكنيسة القبطية بممارسة سر الاعتراف على يد الكاهن ونيل الحل والتناول من الجسد والدم الأقدسين.',
      'citations': [
        'القديس يوحنا ذهبي الفم — مقالات في التوبة',
        'القديس مارإسحق السرياني — النسكيات',
        'قداسة البابا شنودة الثالث — حياة التوبة والنقاوة'
      ]
    },
    'صوم يونان': {
      'response':
          'صوم نينوى (صوم يونان) هو صوم توبة وانسحاق لمدة ثلاثة أيام (الاثنين والثلاثاء والأربعاء)، يسبق الصوم الكبير بأسبوعين كتهيئة روحية للنفس.\n\nدخل هذا الصوم إلى طقس الكنيسة القبطية الأرثوذكسية في عهد البابا إبرآم بن زرعة السرياني (البطريرك ٦٢ في القرن العاشر الميلادي)، ونصومه تشبهاً بتوبة أهل نينوى وتأملاً في مكوث يونان ثلاثة أيام وثلاث ليالٍ في جوف الحوت كرمز لدفن وقيامة مخلصنا الصالح.',
      'citations': [
        'سفر يونان النبي — العهد القديم',
        'قطمارس الصوم الكبير وصوم يونان',
        'تاريخ البطاركة — البابا إبرآم بن زرعة'
      ]
    },
    'سر التجسد': {
      'response':
          'سر التجسد الإلهي هو أساس إيماننا المسيحي الأرثوذكسي، حيث أخذ كلمة الله الأزلي جسداً حقيقياً من الروح القدس ومن العذراء القديسة مريم وتأنس، بغير اختلاط ولا امتزاج ولا تغيير.\n\nيعلمنا القديس أثناسيوس الرسولي في كتاب «تجسد الكلمة»: «تجسد الكلمة لكي يبيد الفساد الذي حل بالطبيعة البشرية، ويعيد للإنسان صورة الله، ويبطل سلطان الموت».',
      'citations': [
        'القديس أثناسيوس الرسولي — تجسد الكلمة',
        'القديس كيرلس الكبير — شرح تجسد الوحيد',
        'الاعتراف الأخير بالقداس الباسيلي'
      ]
    },
    'الفتور الروحي': {
      'response':
          'الفتور الروحي حالة قد تصيب المؤمن حينما تخمد حرارة الصلاة، وعلاجه في التراث الآبائي:\n١. التمسك بقانون صلاة الأجبية بانتظام ولو صلاة قصيرة بخشوع.\n٢. ترديد صلاة يسوع السهمية («يا ربي يسوع المسيح ابن الله الحي ارحمني أنا الخاطئ»).\n٣. قراءة سير الشهداء وأقوال آباء البرية في بستان الرهبان.\n٤. الجلوس مع أب الاعتراف لطلب الإرشاد والتناول من الأسرار المقدسة.',
      'citations': [
        'بستان الرهبان — القديس أنطونيوس الكبير',
        'الأب متى المسكين — حياة الصلاة الأرثوذكسية',
        'القديس البابا كيرلس السادس'
      ]
    },
    'الثالوث': {
      'response':
          'تؤمن الكنيسة القبطية الأرثوذكسية بإله واحد مثلث الأقانيم: الآب (الأصل والينبوع)، والابن (الكلمة والحكمة المولود من الآب قبل كل الدهور)، والروح القدس (الرب المحيي المنبثق من الآب). ثلاثة أقانيم متمايزة بغير انفصال، وجوهر إلهي واحد بغير انقسام.\n\nيشبّه القديس أثناسيوس والقديس كيرلس ذلك بالشمس: قرص الشمس والنور الصادر منها والحرارة المنبعثة منها؛ ثلاثة ولكنها شمس واحدة.',
      'citations': [
        'قانون الإيمان النيقاوي القسطنطيني',
        'القديس أثناسيوس الرسولي — الرسائل إلى سرابيون'
      ]
    },
    'الأسرار': {
      'response':
          'أسرار الكنيسة القبطية الأرثوذكسية السبعة هي:\n١. سر المعمودية (الميلاد الثاني من الماء والروح — يو ٣: ٥).\n٢. سر الميرون (تثبيت وسكنى الروح القدس — ١ يو ٢: ٢٠).\n٣. سر الإفخارستيا / التناول (جسد الرب ودمه الأقدسين — يو ٦: ٥٤).\n٤. سر التوبة والاعتراف (غفران الخطايا بسلطان الكهنوت — يو ٢٠: ٢٣).\n٥. سر مسحة المرضى / القنديل (يع ٥: ١٤).\n٦. سر الزيجة المقدسة (أف ٥: ٣٢).\n٧. سر الكهنوت المقدس (إقامة الأساقفة والكهنة والشمامسة).',
      'citations': [
        'الأرشيدياكون حبيب جرجس — الأسرار السبعة',
        'قداسة البابا شنودة الثالث — اللاهوت المقارن'
      ]
    },
    'شفاعة': {
      'response':
          'تميّز الكنيسة الأرثوذكسية بين:\n• الشفاعة الكفارية: وهي خاصة بالرب يسوع المسيح وحده الذي بذل ذاته كفارة عن خطايانا (١ يو ٢: ١).\n• الشفاعة التوسلية: وهي صلاة وتوسل القديسين الأحياء في السماء (وعلى رأسهم العذراء مريم والملائكة والشهداء) من أجلنا أمام عرش النعمة، لأن إلهنا «ليس إله أموات بل إله أحياء لأن الجميع عنده أحياء» (لو ٢٠: ٣٨).',
      'citations': [
        'قداسة البابا شنودة الثالث — الشفاعة والوساطة',
        'الهيتينيات ومجمع القديسين في الخولاجي المقدس'
      ]
    },
    'الصوم الكبير': {
      'response':
          'الصوم الكبير في الكنيسة القبطية الأرثوذكسية مدته ٥٥ يوماً مقسمة إلى:\n١. أسبوع الاستعداد (الرفاع) — ٧ أيام.\n٢. الأربعين المقدسة التي صامها السيد المسيح — ٤٠ يوماً.\n٣. أسبوع الآلام المقدس (البصخة) — ٨ أيام تنتهي بعيد القيامة المجيد.\n\nوآحاده السبعة تمثل رحلة النفس من التوبة حتى الملكوت: أحد الكنوز، التجربة، الابن الضال، السامرية، المخلع، المولود أعمى، وأحد الشعانين.',
      'citations': [
        'قطمارس الصوم الكبير — دير مارمينا مريوط',
        'الترتيب الطقسي للكنيسة القبطية الأرثوذكسية'
      ]
    },
    'القداس': {
      'response':
          'القداس الإلهي هو سر الشكر (الإفخارستيا) وذبيحة العهد الجديد غير الدموية، وتصلي الكنيسة القبطية بثلاثة قداسات قانونية:\n١. القداس الباسيلي (للقديس باسيليوس الكبير — يُصلى أغلب أيام السنة).\n٢. القداس الغريغوري (للقديس غريغوريوس النزينزي — للأعياد السيدية ومناسبات الفرح).\n٣. القداس الكيرلسي (للقديس مارمرقس وهذّبه القديس كيرلس عمود الدين — يغلب عليه طابع التخشع والصوم).',
      'citations': [
        'الخولاجي المقدس — الكنيسة القبطية الأرثوذكسية',
        'الأنبا متاؤس — روحانية القداس الإلهي'
      ]
    },
    'البصخة': {
      'response':
          'كلمة «بصخة» (Pascha) معناها «العبور»، وهو أسبوع الآلام المقدس الذي تعيش فيه الكنيسة خطوة بخطوة مع السيد المسيح من أحد الشعانين حتى ليلة سبت النور وعيد القيامة.\n\nتُصلى كل يوم ٥ سواعي نهارية و٥ سواعي ليلية، وتُرَتَّل فيها تسبحة «ثوك تي تي جوم» (لك القوة والمجد) ١٢ مرة في كل ساعة، وتُختم بالساعة الثانية عشرة من الجمعة العظيمة (الدفن ولحن غولغوثا).',
      'citations': [
        'دلال أسبوع الآلام المقدس',
        'قطمارس البصخة المقدسة'
      ]
    },
    'التسبحة': {
      'response':
          'تسبحة نصف الليل (الإبصلمودية المقدسة) هي شركة مع صفوف الملائكة في التسبيح، وتتكون من:\n١. تين ثينو (قوموا يا بني النور).\n٢. الهوس الأول (تسبحة موسى النبي — خروج ١٥) ولبشه.\n٣. الهوس الثاني (مزمور ١٣٦ — اشكروا الرب) ولبشه.\n٤. الهوس الثالث (تسبحة الثلاثة فتية القديسين) ولحن تينين والمجمع.\n٥. الهوس الرابع (المزامير ١٤٨ و١٤٩ و١٥٠).\n٦. الإبصالية والثيؤطوكية (مديح والدة الإله) والذكصولوجيات وختام التسبحة.',
      'citations': [
        'الإبصلمودية السنوية والكيهكية المقدسة',
        'الكنيسة القبطية الأرثوذكسية'
      ]
    },
    'المعمودية': {
      'response':
          'سر المعمودية هو باب الأسرار والميلاد الثاني من الماء والروح كما قال الرب لنيقوديموس: «إن كان أحد لا يولد من الماء والروح لا يقدر أن يدخل ملكوت الله» (يو ٣: ٥).\n\nتتم في الكنيسة الأرثوذكسية بالتغطيس الكامل ثلاث دفعات باسم الآب والابن والروح القدس، ويتبعها مباشرة سر الميرون المقدس (٣٦ رشمة) لنوال سكنى الروح القدس.',
      'citations': [
        'إنجيل يوحنا ٣: ٥ • رومية ٦: ٣-٤',
        'ترتيب طقس المعمودية والميرون بالكنيسة القبطية'
      ]
    },
    'العذراء': {
      'response':
          'تلقب الكنيسة القبطية السيدة العذراء مريم بلقب «ثيؤطوكوس» (Θεοτόκος) أي والدة الإله، وقد أقرّه مجمع أفسس المسكوني (٤٣١م) بقيادة القديس كيرلس الكبير.\n\nوهي شفيعتنا المؤتمنة أمام عرش النعمة، نكرمها بالتطويب كما تنبأت: «هوذا منذ الآن جميع الأجيال تطوبني» (لو ١: ٤٨)، لكن العبادة والسجود الكامل لله وحده.',
      'citations': [
        'مجمع أفسس المسكوني ٤٣١م — القديس كيرلس الكبير',
        'ثيؤطوكية يوم الأحد — الإبصلمودية المقدسة'
      ]
    },
  };

  /// Searches local Orthodox library (Knowledge base + Books + Bible + Synaxarium)
  Future<Map<String, dynamic>> _searchLocalRag(String query) async {
    await _ensureLocalRagLoaded();
    final tokens = query
        .replaceAll(RegExp(r'[^\u0600-\u06FF\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) =>
            w.length >= 3 &&
            ![
              'ماذا',
              'لماذا',
              'كيف',
              'متى',
              'اين',
              'أين',
              'اشرح',
              'تفسير',
              'معنى',
              'عن',
              'في',
              'من',
              'على',
              'الى',
              'إلى',
              'هذا',
              'هذه',
              'هل',
              'ماهو',
              'ماهي',
              'اريد',
              'أريد',
              'عايز'
            ].contains(w))
        .toList();

    final matchedSnippets = <String>[];
    final matchedCitations = <String>[];

    // 1. Check Patristic Encyclopedia
    String? directHitText;
    List<String>? directHitCitations;
    for (final entry in _patristicKnowledgeBase.entries) {
      if (query.contains(entry.key) ||
          tokens.any((t) => entry.key.contains(t) && t.length >= 4)) {
        directHitText = entry.value['response'] as String;
        directHitCitations = List<String>.from(entry.value['citations']);
        matchedSnippets.add(directHitText);
        matchedCitations.addAll(directHitCitations);
        break;
      }
    }

    // 2. Search Orthodox Books (books.json)
    if (_booksCache != null && tokens.isNotEmpty) {
      for (final bk in _booksCache!) {
        final bMap = bk as Map<String, dynamic>;
        final title = '${bMap['title'] ?? ''}';
        final author = '${bMap['author'] ?? ''}';
        final chapters = bMap['chapters'] as List<dynamic>? ?? [];
        for (final ch in chapters) {
          final cMap = ch as Map<String, dynamic>;
          final cTitle = '${cMap['title'] ?? ''}';
          final cContent = '${cMap['content'] ?? ''}';
          final combined = '$title $cTitle $cContent';
          int score = 0;
          for (final t in tokens) {
            if (combined.contains(t)) score++;
          }
          if (score > 0 && matchedSnippets.length < 3) {
            final excerpt = cContent.length > 480
                ? '${cContent.substring(0, 480)}...'
                : cContent;
            matchedSnippets
                .add('• من كتاب «$title» ($author — $cTitle):\n$excerpt');
            final cit = '$title — $author';
            if (!matchedCitations.contains(cit)) matchedCitations.add(cit);
          }
        }
      }
    }

    // 3. Search 366-Day Authentic Arabic Synaxarium
    if (_lectionaryCache != null &&
        tokens.isNotEmpty &&
        matchedSnippets.length < 3) {
      for (final entry in _lectionaryCache!.entries) {
        final evs = entry.value as List<dynamic>? ?? [];
        for (final ev in evs) {
          final eMap = ev as Map<String, dynamic>;
          final title = '${eMap['title'] ?? ''}';
          final text = '${eMap['text'] ?? ''}';
          if (tokens.any((t) => title.contains(t))) {
            final excerpt =
                text.length > 420 ? '${text.substring(0, 420)}...' : text;
            matchedSnippets.add('• من السنكسار القبطي ($title):\n$excerpt');
            matchedCitations.add('السنكسار القبطي — $title');
            if (matchedSnippets.length >= 3) break;
          }
        }
        if (matchedSnippets.length >= 3) break;
      }
    }

    // 4. Search Holy Bible verses (bible.json) if still room
    if (_bibleCache != null && tokens.isNotEmpty && matchedSnippets.length < 3) {
      for (final bk in _bibleCache!) {
        final bMap = bk as Map<String, dynamic>;
        final bName = '${bMap['name'] ?? ''}';
        final chs = bMap['chapters'] as List<dynamic>? ?? [];
        bool foundInBook = false;
        for (int ci = 0; ci < chs.length && !foundInBook; ci++) {
          final vs = chs[ci] as List<dynamic>;
          for (int vi = 0; vi < vs.length; vi++) {
            final vText = vs[vi].toString();
            if (tokens.every((t) => vText.contains(t))) {
              matchedSnippets
                  .add('• من الكتاب المقدس ($bName ${ci + 1}:${vi + 1}): «$vText»');
              matchedCitations.add('$bName ${ci + 1}:${vi + 1}');
              foundInBook = true;
              break;
            }
          }
        }
        if (matchedSnippets.length >= 3) break;
      }
    }

    return {
      'direct_hit': directHitText != null,
      'direct_text': directHitText,
      'direct_citations': directHitCitations,
      'snippets': matchedSnippets,
      'citations': matchedCitations,
    };
  }

  static const String _orthodoxSystemPrompt =
      'أنت «المرشد الآبائي القبطي الأرثوذكسي» في تطبيق أرثوذكسيا. '
      'أجب عن سؤال المستخدم بدقة لاهوتية وكتابية وطقسية وفق إيمان الكنيسة القبطية الأرثوذكسية فقط '
      'وتفاسير الآباء (القديس أثناسيوس الرسولي، القديس كيرلس الكبير، القديس يوحنا ذهبي الفم، قداسة البابا شنودة الثالث، '
      'القمص تادرس يعقوب ملطي، القمص أنطونيوس فكري، والأب متى المسكين). '
      'قواعد صارمة: ١) التزم تماماً بالحقائق الكنسية القبطية (مثلاً: صوم يونان ٣ أيام قبل الصوم الكبير بأسبوعين، '
      'الصوم الكبير ٥٥ يوماً، الأسرار السبعة، الشفاعة التوسلية للقديسين). '
      '٢) اكتب بلغة عربية واضحة ومرتبة في نقاط مرقمة (١. ٢. ٣.) أو نقاط (•) مع وضع الآيات وأقوال الآباء بين «...». '
      '٣) ممنوع تماماً استخدام الإيموجي أو علامات النجوم (*** أو ** أو *) أو رموز الماركداون (#).';

  /// Live test of an API configuration before saving. Returns `(ok, message)`.
  Future<(bool, String)> testConnection(AiApiConfig cfg) async {
    if (!cfg.isConfigured) {
      return (false, 'يرجى إدخال مفتاح API صحيح أولاً.');
    }
    try {
      final reply = await _callConfiguredProvider(
        cfg: cfg,
        userPrompt: 'أجب بجملة واحدة قصيرة: ما معنى كلمة أرثوذكسية؟',
        history: const [],
      );
      if (reply != null && reply.isNotEmpty) {
        return (true, 'تم الاتصال بنجاح بـ ${cfg.providerDisplayName}!');
      }
      return (false, 'لم يستجب الخادم — تحقق من صحة المفتاح أو اتصالك بالإنترنت.');
    } catch (e) {
      return (false, 'فشل الاتصال: ${e.toString().replaceFirst("Exception: ", "")}');
    }
  }

  Future<String?> _callConfiguredProvider({
    required AiApiConfig cfg,
    required String userPrompt,
    required List<AiMessage> history,
  }) async {
    final recentTurns =
        history.length > 6 ? history.sublist(history.length - 6) : history;

    if (cfg.provider == AiProviderType.gemini) {
      // Try latest official Google Gemini Flash models (supports both AIza... and AQ.... keys)
      for (final model in const [
        'gemini-3.5-flash-lite',
        'gemini-3.8-flash',
        'gemini-2.5-flash',
        'gemini-2.0-flash',
      ]) {
        final uri = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent',
        );
        final contents = <Map<String, dynamic>>[];
        for (final turn in recentTurns) {
          if (turn.text.trim().isEmpty) continue;
          contents.add({
            'role': turn.isUser ? 'user' : 'model',
            'parts': [
              {
                'text': turn.text.length > 600
                    ? turn.text.substring(0, 600)
                    : turn.text
              }
            ],
          });
        }
        contents.add({
          'role': 'user',
          'parts': [
            {'text': userPrompt}
          ],
        });

        final res = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': cfg.apiKey,
              },
              body: jsonEncode({
                'systemInstruction': {
                  'parts': [
                    {'text': _orthodoxSystemPrompt}
                  ]
                },
                'contents': contents,
                'generationConfig': {
                  'temperature': 0.25,
                  'maxOutputTokens': 1024,
                },
              }),
            )
            .timeout(const Duration(seconds: 22));

        if (res.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(res.bodyBytes));
          final parts =
              decoded['candidates']?[0]?['content']?['parts'] as List?;
          final raw = parts
                  ?.map((p) => (p as Map)['text']?.toString() ?? '')
                  .join('\n')
                  .trim() ??
              '';
          if (raw.isNotEmpty) return cleanMarkdownFormatting(raw);
        } else if (res.statusCode == 400 ||
            res.statusCode == 401 ||
            res.statusCode == 403) {
          throw Exception('مفتاح Gemini غير صالح أو غير مفعّل (HTTP ${res.statusCode})');
        }
      }
      return null;
    }

    // Groq OR Custom OpenAI-Compatible Endpoint
    final String endpointUrl = cfg.provider == AiProviderType.groq
        ? 'https://api.groq.com/openai/v1/chat/completions'
        : SecurityGuardService.upgradeToHttps(cfg.customEndpoint);
    if (!SecurityGuardService.isSafeExternalUrl(endpointUrl)) {
      throw Exception('رابط الخادم يجب أن يبدأ بـ https:// وآمن');
    }

    final modelName = cfg.provider == AiProviderType.groq
        ? 'llama-3.3-70b-versatile'
        : (cfg.customModel.isNotEmpty ? cfg.customModel : 'gpt-4o-mini');

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': _orthodoxSystemPrompt},
    ];
    for (final turn in recentTurns) {
      if (turn.text.trim().isEmpty) continue;
      messages.add({
        'role': turn.isUser ? 'user' : 'assistant',
        'content': turn.text.length > 600
            ? turn.text.substring(0, 600)
            : turn.text,
      });
    }
    messages.add({'role': 'user', 'content': userPrompt});

    final headers = <String, String>{'Content-Type': 'application/json'};
    if (cfg.apiKey.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${cfg.apiKey}';
      if (cfg.provider == AiProviderType.customProxy) {
        headers['X-Orthoxia-Client'] = cfg.apiKey;
      }
    }

    final res = await http
        .post(
          Uri.parse(endpointUrl),
          headers: headers,
          body: jsonEncode({
            'model': modelName,
            'messages': messages,
            'temperature': 0.25,
          }),
        )
        .timeout(const Duration(seconds: 22));

    if (res.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      final raw = decoded['choices']?[0]?['message']?['content']
              ?.toString()
              .trim() ??
          '';
      if (raw.isNotEmpty) return cleanMarkdownFormatting(raw);
    } else if (res.statusCode == 401 || res.statusCode == 403) {
      throw Exception('مفتاح API غير صالح (HTTP ${res.statusCode})');
    }
    return null;
  }

  Future<AiMessage> askQuestion(
    String query, {
    String? apiKey,
    List<AiMessage> history = const [],
  }) async {
    final cleanQuery = SecurityGuardService.sanitizeText(
      query,
      maxLength: 600,
      allowNewlines: false,
    );
    if (cleanQuery.isEmpty) {
      return AiMessage(
        text: 'من فضلك اكتب سؤالك الروحي أو الطقسي بوضوح.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
    if (!SecurityGuardService().allowAction(
      'ai_theology',
      cooldown: const Duration(seconds: 2),
      maxPerWindow: 15,
      window: const Duration(minutes: 3),
    )) {
      return AiMessage(
        text:
            'تمهل قليلاً بين الأسئلة المتتالية لكي نتمكن من خدمتك بأفضل إجابة آبائية دقيقة.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
    final lower = cleanQuery.toLowerCase();

    // 1. Pastoral guardrail for personal canonical/marital disputes
    if (lower.contains('طلاق') ||
        lower.contains('خلع') ||
        lower.contains('زواج مدني')) {
      return AiMessage(
        text:
            'سلام ونعمة. المسائل المتعلقة بالأحوال الشخصية والقوانين الكنسية الخاصة تستلزم حواراً ورعاية أبوية مباشرة مع أب اعترافك أو المجلس الإكليريكي المختص بالإيبارشية لتقديم المشورة المناسبة بمحبة ورعاية.',
        isUser: false,
        timestamp: DateTime.now(),
        citations: ['إرشاد آبائي ورعوي — الكنيسة القبطية الأرثوذكسية'],
      );
    }

    // 2. Always ground with Local Orthodox RAG first
    final rag = await _searchLocalRag(cleanQuery);
    final ragSnippets = (rag['snippets'] as List<String>? ?? []);
    final ragCitations = (rag['citations'] as List<String>? ?? []);
    final ragContext = ragSnippets.isNotEmpty
        ? '\n\nمراجع موثقة من مكتبة التطبيق الأرثوذكسية:\n${ragSnippets.join("\n\n")}'
        : '';

    // 3. Call user's configured REAL AI API (Gemini / Groq / Custom Proxy) if set
    var cfg = await loadConfig();
    if (!cfg.isConfigured && apiKey != null && apiKey.trim().length >= 12) {
      cfg = AiApiConfig(provider: AiProviderType.gemini, apiKey: apiKey.trim());
    }

    if (cfg.isConfigured) {
      try {
        final aiText = await _callConfiguredProvider(
          cfg: cfg,
          userPrompt: '$cleanQuery$ragContext',
          history: history,
        );
        if (aiText != null && aiText.isNotEmpty) {
          return AiMessage(
            text: aiText,
            isUser: false,
            timestamp: DateTime.now(),
            citations: ragCitations.isNotEmpty
                ? ragCitations
                : const ['تراث الكنيسة القبطية الأرثوذكسية'],
          );
        }
      } catch (_) {
        // Fall through cleanly to zero-hallucination local Orthodox RAG!
      }
    }

    // 4. Zero-hallucination Offline Patristic Knowledge Base + Local RAG Synthesis
    if (rag['direct_hit'] == true && rag['direct_text'] != null) {
      return AiMessage(
        text: rag['direct_text'] as String,
        isUser: false,
        timestamp: DateTime.now(),
        citations: rag['direct_citations'] as List<String>?,
      );
    }

    if (ragSnippets.isNotEmpty) {
      return AiMessage(
        text:
            'بخصوص سؤالك: «$cleanQuery»\n\nإليك ما ورد في مكتبة التطبيق الأرثوذكسية (الكتاب المقدس، الكتب الآبائية، والسنكسار):\n\n${ragSnippets.join("\n\n─────────────────\n\n")}',
        isUser: false,
        timestamp: DateTime.now(),
        citations: ragCitations,
      );
    }

    return AiMessage(
      text:
          'بخصوص سؤالك: «$cleanQuery»\n\n'
          'يبدو أن الاتصال بالإنترنت غير متاح حالياً. يمكنك إعادة المحاولة عند عودة الاتصال، أو سؤالي مباشرة بدون إنترنت عن: التوبة، الثالوث، التجسد، الأسرار السبعة، الشفاعة، الصوم الكبير، صوم يونان، القداس، البصخة، التسبحة، المعمودية، أو أي آية أو قديس في السنكسار.',
      isUser: false,
      timestamp: DateTime.now(),
      citations: const ['الموسوعة الآبائية — أرثوذكسيا'],
    );
  }

  /// Strips raw Markdown asterisks (***, **, *), hashes (###), and horizontal rules (---)
  static String cleanMarkdownFormatting(String raw) {
    if (raw.isEmpty) return '';
    String text = raw;
    text = text.replaceAll(
        RegExp(r'^\s*(\*{3,}|-{3,}|_{3,})\s*$', multiLine: true), '');
    text = text.replaceAllMapped(
      RegExp(r'^\s*#{1,6}\s*(.+)$', multiLine: true),
      (m) => '☦ ${m.group(1)!.replaceAll('*', '').trim()}',
    );
    text = text.replaceAllMapped(
      RegExp(r'^\s*[\*\-]\s+(.+)$', multiLine: true),
      (m) => '• ${m.group(1)!.trim()}',
    );
    text = text.replaceAll(RegExp(r'\*{1,3}'), '');
    text = text.replaceAll(RegExp(r'_{2,}'), '');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }
}
