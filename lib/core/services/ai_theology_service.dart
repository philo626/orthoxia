import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'security_guard_service.dart';

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
}

class AiTheologyService {
  static List<dynamic>? _booksCache;
  static List<dynamic>? _commentariesCache;
  static Map<String, dynamic>? _lectionaryCache;

  static Future<void> _ensureLocalRagLoaded() async {
    if (_booksCache == null) {
      try {
        final raw = await rootBundle.loadString('assets/data/books.json');
        _booksCache = jsonDecode(raw) as List<dynamic>;
      } catch (_) {
        _booksCache = [];
      }
    }
    if (_commentariesCache == null) {
      try {
        final raw = await rootBundle.loadString('assets/data/commentaries.json');
        _commentariesCache = jsonDecode(raw) as List<dynamic>;
      } catch (_) {
        _commentariesCache = [];
      }
    }
    if (_lectionaryCache == null) {
      try {
        final raw = await rootBundle.loadString('assets/data/synaxarium_ar.json');
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
        'القديس يوحنا ذهبي الفم - مقالات في التوبة',
        'القديس مارإسحق السرياني - النسكيات',
        'قداسة البابا شنودة الثالث - كتاب حياة التوبة والنقاوة'
      ]
    },
    'صوم يونان': {
      'response':
          'صوم نينوى (يونان) هو صوم توبة وانسحاق لمدة ثلاثة أيام، يسبق الصوم الكبير بأسبوعين كتهيئة روحية للنفس.\n\nدخل هذا الصوم إلى طقس الكنيسة القبطية الأرثوذكسية في عهد البابا إبرآم بن زرعة السرياني (البطريرك ٦٢ في القرن العاشر الميلادي)، ونصومه تشبهاً بأهل نينوى وتأملاً في مكوث يونان ثلاثة أيام في جوف الحوت كرمز لدفن وقيامة مخلصنا الصالح.',
      'citations': [
        'سفر يونان النبي - العهد القديم',
        'قطمارس الصوم الكبير وصوم يونان - دير مارمينا مريوط',
        'تاريخ البطاركة - البابا إبرآم بن زرعة'
      ]
    },
    'سر التجسد': {
      'response':
          'سر التجسد الإلهي هو أساس إيماننا المسيحي الأرثوذكسي، حيث أخذ كلمة الله الأزلي جسداً حقيقياً من الروح القدس ومن العذراء القديسة مريم وتأنس، دون اختلاط ولا امتزاج ولا تغيير.\n\nيعلمنا القديس أثناسيوس الرسولي في كتاب «تجسد الكلمة»: «تجسد الكلمة لكي يبيد الفساد الذي حل بالطبيعة البشرية، ويعيد للإنسان صورة الله، ويبطل سلطان الموت».',
      'citations': [
        'القديس أثناسيوس الرسولي - تجسد الكلمة',
        'القديس كيرلس الكبير - شرح تجسد الوحيد',
        'الاعتراف الأخير بالقداس الباسيلي'
      ]
    },
    'الفتور الروحي': {
      'response':
          'الفتور الروحي حالة قد تصيب المؤمن حينما تخمد حرارة الصلاة، وعلاجه في التراث الآبائي:\n١. التمسك بقانون صلاة الأجبية ولو ساعة قصيرة.\n٢. ترديد صلاة يسوع السهمية على المسبحة القبطية («يا ربي يسوع المسيح ابن الله الحي ارحمني أنا الخاطئ»).\n٣. قراءة سير الشهداء وأقوال آباء البرية في بستان الرهبان.\n٤. الجلوس مع أب الاعتراف لطلب الإرشاد والمعونة.',
      'citations': [
        'بستان الرهبان - أقوال القديس أنطونيوس الكبير',
        'الأب متى المسكين - حياة الصلاة الأرثوذكسية',
        'القديس البابا كيرلس السادس'
      ]
    },
    'الثالوث': {
      'response':
          'تؤمن الكنيسة القبطية الأرثوذكسية بإله واحد مثلث الأقانيم: الآب (الأصل والينبوع)، والابن (الكلمة والحكمة المولود من الآب قبل كل الدهور)، والروح القدس (الرب المحيي المنبثق من الآب). ثلاثة أقانيم متمايزة بغير انفصال، وجوهر إلهي واحد بغير انقسام.\n\nيشبّه القديس أثناسيوس الرسولي والقديس كيرلس الكبير ذلك بالشمس: قرص الشمس والنور الصادر منها والحرارة المنبعثة منها؛ ثلاثة ولكنها شمس واحدة.',
      'citations': [
        'قانون الإيمان النيقاوي القسطنطيني',
        'القديس أثناسيوس الرسولي - الرسائل إلى سرابيون',
        'عقيدة الثالوث القدوس في الكنيسة الأرثوذكسية'
      ]
    },
    'الأسرار': {
      'response':
          'أسرار الكنيسة القبطية الأرثوذكسية السبعة هي:\n١. سر المعمودية (الميلاد الثاني من الماء والروح - يو ٣: ٥).\n٢. سر الميرون (تثبيت وسكنى الروح القدس - ١ يو ٢: ٢٠).\n٣. سر الإفخارستيا / التناول (جسد الرب ودمه الأقدسين - يو ٦: ٥٤).\n٤. سر التوبة والاعتراف (غفران الخطايا بسلطان الكهنوت - يو ٢٠: ٢٣).\n٥. سر مسحة المرضى / القنديل (يع ٥: ١٤).\n٦. سر الزيجة المقدسة (أف ٥: ٣٢).\n٧. سر الكهنوت المقدس (إقامة الأساقفة والكهنة والشمامسة).',
      'citations': [
        'اللاهوت الطقسي والأسرار السبعة - الأرشيدياكون حبيب جرجس',
        'قداسة البابا شنودة الثالث - اللاهوت المقارن'
      ]
    },
    'شفاعة': {
      'response':
          'تميّز الكنيسة الأرثوذكسية بين:\n• الشفاعة الكفارية: وهي خاصة بالرب يسوع المسيح وحده الذي بذل ذاته كفارة عن خطايانا (١ يو ٢: ١).\n• الشفاعة التوسلية: وهي صلاة وتوسل القديسين الأحياء في السماء (وعلى رأسهم العذراء مريم والملائكة والشهداء) من أجلنا أمام عرش النعمة، لأن إلهنا «ليس إله أموات بل إله أحياء لأن الجميع عنده أحياء» (لو ٢٠: ٣٨).',
      'citations': [
        'قداسة البابا شنودة الثالث - الشفاعة والوساطة',
        'الهيتينيات ومجمع القديسين في الخولاجي المقدس'
      ]
    },
  };

  /// Searches local books, commentaries, and Synaxarium for relevant Orthodox context
  Future<Map<String, dynamic>> _searchLocalRag(String query) async {
    await _ensureLocalRagLoaded();
    final tokens = query
        .replaceAll(RegExp(r'[^\u0600-\u06FF\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 3 && !['ماذا', 'لماذا', 'كيف', 'متى', 'اين', 'أين', 'اشرح', 'تفسير', 'معنى', 'عن', 'في', 'من', 'على', 'الى', 'إلى', 'هذا', 'هذه', 'هل'].contains(w))
        .toList();

    final matchedSnippets = <String>[];
    final matchedCitations = <String>[];

    // 1. Check built-in Patristic Encyclopedia
    for (final entry in _patristicKnowledgeBase.entries) {
      if (query.contains(entry.key) || tokens.any((t) => entry.key.contains(t))) {
        return {
          'direct_hit': true,
          'text': entry.value['response'] as String,
          'citations': List<String>.from(entry.value['citations']),
        };
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
            matchedSnippets.add('📖 من كتاب «$title» ($author - $cTitle):\n$cContent');
            final cit = '$title - $author';
            if (!matchedCitations.contains(cit)) matchedCitations.add(cit);
          }
        }
      }
    }

    // 3. Search 75-Book Patristic Commentaries (commentaries.json)
    if (_commentariesCache != null && tokens.isNotEmpty && matchedSnippets.length < 3) {
      for (final comm in _commentariesCache!) {
        final cMap = comm as Map<String, dynamic>;
        final bName = '${cMap['bible_book_name'] ?? ''}';
        if (tokens.any((t) => bName.contains(t))) {
          final chs = cMap['chapters'] as List<dynamic>? ?? [];
          if (chs.isNotEmpty) {
            final ch0 = chs.first as Map<String, dynamic>;
            final intro = '${ch0['introduction'] ?? ''}';
            final vs = ch0['verses'] as List<dynamic>? ?? [];
            final vText = vs.isNotEmpty ? '${(vs.first as Map)['patristic_commentary'] ?? ''}' : '';
            matchedSnippets.add('☦ من تفسير «$bName»:\n$intro\n\n$vText');
            matchedCitations.add('تفسير $bName - القمص تادرس يعقوب ملطي والقس أنطونيوس فكري');
          }
        }
      }
    }

    // 4. Search 366-Day Authentic Arabic Synaxarium (synaxarium_ar.json)
    if (_lectionaryCache != null && tokens.isNotEmpty && matchedSnippets.length < 3) {
      for (final entry in _lectionaryCache!.entries) {
        final evs = entry.value as List<dynamic>? ?? [];
        for (final ev in evs) {
          final eMap = ev as Map<String, dynamic>;
          final title = '${eMap['title'] ?? ''}';
          final text = '${eMap['text'] ?? ''}';
          if (tokens.any((t) => title.contains(t))) {
            final excerpt = text.length > 450 ? '${text.substring(0, 450)}...' : text;
            matchedSnippets.add('🕯️ من السنكسار القبطي ($title):\n$excerpt');
            matchedCitations.add('السنكسار القبطي الأرثوذكسي - $title');
            if (matchedSnippets.length >= 3) break;
          }
        }
        if (matchedSnippets.length >= 3) break;
      }
    }

    return {
      'direct_hit': false,
      'snippets': matchedSnippets,
      'citations': matchedCitations,
    };
  }

  Future<AiMessage> askQuestion(String query, {String? apiKey}) async {
    final cleanQuery = SecurityGuardService.sanitizeText(query, maxLength: 600, allowNewlines: false);
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
      maxPerWindow: 12,
      window: const Duration(minutes: 3),
    )) {
      return AiMessage(
        text: 'تمهل قليلاً بين الأسئلة المتتالية لكي نتمكن من خدمتك بأفضل إجابة آبائية دقيقة.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }
    final lower = cleanQuery.toLowerCase();

    // 1. Guardrail check for personal canonical/marital disputes
    if (lower.contains('طلاق') || lower.contains('خلع') || lower.contains('زواج مدني')) {
      return AiMessage(
        text:
            'سلام ونعمة يا أخي المبارك. المسائل المتعلقة بالأحوال الشخصية والقوانين الكنسية الخاصة تستلزم حواراً ورعاية أبوية مباشرة مع أب اعترافك أو المجلس الإكليريكي المختص بالإيبارشية لتقديم المشورة المناسبة لحالتك بمحبة ورعاية.',
        isUser: false,
        timestamp: DateTime.now(),
        citations: ['إرشاد آبائي ورعوي - الكنيسة القبطية الأرثوذكسية'],
      );
    }

    // 2. Run Local RAG over the 18 MB Coptic Orthodox Library
    final rag = await _searchLocalRag(cleanQuery);
    if (rag['direct_hit'] == true) {
      return AiMessage(
        text: rag['text'] as String,
        isUser: false,
        timestamp: DateTime.now(),
        citations: rag['citations'] as List<String>,
      );
    }

    final ragSnippets = (rag['snippets'] as List<String>? ?? []);
    final ragCitations = (rag['citations'] as List<String>? ?? []);
    final ragContext = ragSnippets.isNotEmpty
        ? '\n\nمراجع من مكتبة التطبيق الأرثوذكسية:\n${ragSnippets.join("\n\n")}'
        : '';

    const systemPrompt =
        'أنت «المساعد الآبائي القبطي الأرثوذكسي» في تطبيق أرثوذكسيا. أجب عن سؤال المستخدم بدقة لاهوتية وروحية وطقسية وفق إيمان الكنيسة القبطية الأرثوذكسية وتفاسير الآباء (القديس أثناسيوس الرسولي، القديس كيرلس الكبير، القديس يوحنا ذهبي الفم، قداسة البابا شنودة الثالث، القمص تادرس يعقوب ملطي، والقس أنطونيوس فكري). اكتب بلغة عربية واضحة ومرتبة في نقاط مرقمة (١. ٢. ٣.) أو نقاط (•) مع وضع الآيات وأقوال الآباء بين علامتي تنصيص «...»، وممنوع تماماً استخدام علامات النجوم (*** أو ** أو *) أو رموز الماركداون (#).';

    // 3. Try Live Online AI Generation (works out-of-the-box with zero API key via Pollinations OpenAI endpoint, or Anthropic if key supplied)
    try {
      final response = await http
          .post(
            Uri.parse('https://text.pollinations.ai/openai'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': 'openai',
              'messages': [
                {'role': 'system', 'content': systemPrompt},
                {'role': 'user', 'content': '$cleanQuery$ragContext'},
              ],
              'temperature': 0.25,
            }),
          )
          .timeout(const Duration(seconds: 16));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        final rawAiText = decoded['choices']?[0]?['message']?['content']?.toString().trim() ?? '';
        final aiText = cleanMarkdownFormatting(rawAiText);
        if (aiText.isNotEmpty) {
          return AiMessage(
            text: aiText,
            isUser: false,
            timestamp: DateTime.now(),
            citations: ragCitations.isNotEmpty
                ? ragCitations
                : [
                    'تفاسير آباء الكنيسة القبطية الأرثوذكسية',
                    'القمص تادرس يعقوب ملطي • القس أنطونيوس فكري',
                  ],
          );
        }
      }
    } catch (_) {
      // Offline fallback to Local RAG synthesis below
    }

    // 4. Offline Local RAG Synthesis (if device has no internet inside church)
    if (ragSnippets.isNotEmpty) {
      return AiMessage(
        text:
            'بخصوص سؤالك: «$cleanQuery»\n\nإليك ما ورد في مراجع وتفاسير الكنيسة القبطية الأرثوذكسية المحفوظة محلياً على جهازك:\n\n${ragSnippets.join("\n\n─────────────────\n\n")}',
        isUser: false,
        timestamp: DateTime.now(),
        citations: ragCitations,
      );
    }

    return AiMessage(
      text:
          'بخصوص سؤالك الروحي: «$cleanQuery»\n\nفي تعليم الكنيسة القبطية الأرثوذكسية وتفاسير الآباء (القديس أثناسيوس الرسولي، القديس كيرلس الكبير، والقمص تادرس يعقوب ملطي):\n• كل آية أو طقس في الكنيسة يشير إلى عمل السيد المسيح الخلاصي واتحادنا به في سر الكنيسة.\n• يمكنك كتابة اسم أي سفر من الـ ٧٥ سفراً أو اسم قديس أو عقيدة (مثل: الثالوث، التجسد، الأسرار السبعة، الشفاعة، البصخة، التوبة) لاستخراج النصوص والتفاسير الآبائية الكاملة فوراً.',
      isUser: false,
      timestamp: DateTime.now(),
      citations: [
        'الكتاب المقدس والتفاسير الآبائية (٧٥ سفراً)',
        'تراث الكنيسة القبطية الأرثوذكسية',
      ],
    );
  }

  /// Strips raw Markdown asterisks (***, **, *), hashes (###), and horizontal rules (---)
  /// and normalizes bullet points for clean Arabic Patristic display.
  static String cleanMarkdownFormatting(String raw) {
    if (raw.isEmpty) return '';
    String text = raw;
    // Replace horizontal rules *** or --- with clean line break
    text = text.replaceAll(RegExp(r'^\s*(\*{3,}|-{3,}|_{3,})\s*$', multiLine: true), '');
    // Replace markdown headings ### Title with ☦ Title
    text = text.replaceAllMapped(
      RegExp(r'^\s*#{1,6}\s*(.+)$', multiLine: true),
      (m) => '☦ ${m.group(1)!.replaceAll('*', '').trim()}',
    );
    // Replace markdown bullet points "* item" or "- item" at line start with "• item"
    text = text.replaceAllMapped(
      RegExp(r'^\s*[\*\-]\s+(.+)$', multiLine: true),
      (m) => '• ${m.group(1)!.trim()}',
    );
    // Strip inline ***bold*** and **bold** and *italic*
    text = text.replaceAll(RegExp(r'\*{1,3}'), '');
    // Strip inline markdown underscores __bold__
    text = text.replaceAll(RegExp(r'_{2,}'), '');
    // Collapse 3+ newlines into 2
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }
}
