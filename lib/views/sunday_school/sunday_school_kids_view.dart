import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/widgets/coptic_cross.dart';

class KidsSaintStory {
  final String id;
  final String title;
  final String emoji;
  final String heroBadge;
  final String storyText;
  final String moralLesson;
  final String memoryVerse;

  const KidsSaintStory({
    required this.id,
    required this.title,
    required this.emoji,
    required this.heroBadge,
    required this.storyText,
    required this.moralLesson,
    required this.memoryVerse,
  });
}

class SundaySchoolKidsView extends StatefulWidget {
  const SundaySchoolKidsView({super.key});

  static const List<KidsSaintStory> stories = [
    KidsSaintStory(
      id: 'abanoub',
      title: 'الطفل البطل القديس أبانوب النهيسي',
      emoji: '🌟',
      heroBadge: 'بطل الشجاعة والإيمان (١٢ سنة)',
      storyText:
          'كان القديس أبانوب طفلاً صغيراً عمره ١٢ سنة من بلدة نهيسا بمصر. دخل الكنيسة وسمع أبونا الكاهن يشجع الشعب على الثبات في محبة الرب يسوع، فذهب أبانوب وصلى أمام المذبح، ووزع كل ما يملكه على الفقراء، وشهد بشجاعة أمام الوالي أنه يحب المسيح، وكان الملاك ميخائيل يحفظه ويشفيه ويقويه.',
      moralLesson: 'حتى لو كنت صغيراً في السن، إيمانك وصلاتك ومحبتك للرب يسوع تجعلك بطلاً عظيماً تفرح به السماء!',
      memoryVerse: '«لاَ يَسْتَهِنْ أَحَدٌ بِحَدَاثَتِكَ، بَلْ كُنْ قُدْوَةً لِلْمُؤْمِنِينَ» (١ تيموثاوس ٤: ١٢)',
    ),
    KidsSaintStory(
      id: 'david_goliath',
      title: 'داود الصغير والعملاق جليات',
      emoji: '🪨',
      heroBadge: 'بطل التسبيح والثقة بالله',
      storyText:
          'كان داود راعياً صغيراً يرعى الغنم ويرنم المزامير لله. عندما خاف الجيش كله من العملاق جليات، تقدم داود بخمس حصيات صغيرة من النهر وقال لجليات: أنت تأتي إليّ بسيف ورمح، وأنا آتي إليك باسم رب الجنود! وبقوة الله انتصر داود الصغير.',
      moralLesson: 'لا تخف من أي مشكلة كبيرة؛ عندما تقول «باسم الرب يسوع» يعطيك الله قوة ونصرة.',
      memoryVerse: '«الرَّبُّ رَاعِيَّ فَلاَ يُعْوِزُنِي شَيْءٌ» (مزمور ٢٣: ١)',
    ),
    KidsSaintStory(
      id: 'daniel_lions',
      title: 'دانيال النبي في جب الأسود',
      emoji: '🦁',
      heroBadge: 'بطل الأمانة والصلاة اليومية',
      storyText:
          'كان دانيال النبي يحب الصلاة ثلاث مرات كل يوم ويفتح نافذته نحو أورشليم ليشكر الله. ولما ألقوه في جب الأسود الجائعة لأنه رفض ترك الصلاة، أرسل الله ملاكه وسد أفواه الأسود، فجلس دانيال بينها بسلام ولم تؤذه أبداً!',
      moralLesson: 'حافظ على صلاتك في الصباح وقبل النوم كل يوم، والله يرسل ملائكته لتحفظك في كل مكان.',
      memoryVerse: '«إِلهِي أَرْسَلَ مَلاَكَهُ وَسَدَّ أَفْوَاهَ الأُسُودِ» (دانيال ٦: ٢٢)',
    ),
    KidsSaintStory(
      id: 'paul_raven',
      title: 'الأنبا بولا والغراب العجيب',
      emoji: '🦅',
      heroBadge: 'أول السواح وصديق السماء',
      storyText:
          'عاش القديس الأنبا بولا في البرية يصلي ويسبح الله بفرح. وكان الله يرسل له كل يوم غراباً يحمل في منقاره نصف خبزة طازجة! وفي اليوم الذي زاره فيه القديس الأنبا أنطونيوس، أرسل الله الغراب بخبزة كاملة لهما معاً فشكرت قلوبهما الرب.',
      moralLesson: 'الله أبونا السماوي يهتم بنا ويرعانا في كل احتياجاتنا ولا ينسانا أبداً.',
      memoryVerse: '«مُلْقِينَ كُلَّ هَمِّكُمْ عَلَيْهِ، لأَنَّهُ هُوَ يَعْتَنِي بِكُمْ» (١ بطرس ٥: ٧)',
    ),
    KidsSaintStory(
      id: 'mina_camels',
      title: 'الشهيد مارمينا والجملين',
      emoji: '🐪',
      heroBadge: 'شفيع مريوط وصانع العجائب',
      storyText:
          'لما أرادوا نقل جسد الشهيد العظيم مارمينا، وضعوه على جملين وساروا في صحراء مريوط. وفي مكان معين برك الجملان على الأرض ورفضا التحرك تماماً! فعرف الجميع أن هذه هي إرادة الله، وبنوا هناك كنيسة ودير مارمينا العظيم بمريوط.',
      moralLesson: 'القديسون أصدقاؤنا السماويون الذين يشفعون فينا ويقودوننا لطريق البركة.',
      memoryVerse: '«عَجِيبٌ هُوَ اللهُ فِي قِدِّيسِيهِ» (مزمور ٦٨: ٣٥)',
    ),
    KidsSaintStory(
      id: 'demiana',
      title: 'الأميرة القديسة دميانة والأربعين عذراء',
      emoji: '🕊️',
      heroBadge: 'بطلة النقاوة وحب الكنيسة',
      storyText:
          'كانت القديسة دميانة ابنة والي البرلس، وبدلاً من حياة القصور والرفاهية طلبت من والدها أن يبني لها بيتاً هادئاً لتصلي وتقرأ الإنجيل مع أربعين عذراء، وثبتت على إيمانها بمحبة المسيح حتى نالت إكليل السماء.',
      moralLesson: 'أجمل شيء في حياتنا هو محبة ربنا يسوع وقراءة الإنجيل والاجتماع مع أصدقائنا في الكنيسة.',
      memoryVerse: '«طُوبَى لِلأَنْقِيَاءِ الْقَلْبِ، لأَنَّهُمْ يُعَايِنُونَ اللهَ» (متى ٥: ٨)',
    ),
  ];

  @override
  State<SundaySchoolKidsView> createState() => _SundaySchoolKidsViewState();
}

class _SundaySchoolKidsViewState extends State<SundaySchoolKidsView> {
  static const String _starsPrefsKey = 'sunday_school_kids_stars_v1';
  Set<String> _completedStoryIds = {};

  @override
  void initState() {
    super.initState();
    _loadStars();
  }

  @override
  void dispose() {
    SpeechPronunciationService().stop();
    super.dispose();
  }

  Future<void> _loadStars() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _completedStoryIds = (prefs.getStringList(_starsPrefsKey) ?? []).toSet();
    });
  }

  Future<void> _toggleStar(String storyId) async {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_completedStoryIds.contains(storyId)) {
        _completedStoryIds.remove(storyId);
      } else {
        _completedStoryIds.add(storyId);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_starsPrefsKey, _completedStoryIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    final totalStars = _completedStoryIds.length;

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        centerTitle: true,
        title: Text(
          'ركن مدارس الأحد والطفل القبطي',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryGold),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: AppColors.primaryGold, size: 18),
                const SizedBox(width: 4),
                Text(
                  '$totalStars / ${SundaySchoolKidsView.stories.length}',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGoldLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 36),
        itemCount: SundaySchoolKidsView.stories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (context, idx) {
          final story = SundaySchoolKidsView.stories[idx];
          final isStarred = _completedStoryIds.contains(story.id);

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF231D15), Color(0xFF151722)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isStarred
                    ? AppColors.primaryGold
                    : AppColors.primaryGold.withValues(alpha: 0.32),
                width: isStarred ? 1.6 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGold.withValues(alpha: 0.16),
                        border: Border.all(color: AppColors.primaryGold),
                      ),
                      child: Text(story.emoji, style: const TextStyle(fontSize: 24)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.title,
                            style: GoogleFonts.cairo(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGoldLight,
                            ),
                          ),
                          Text(
                            story.heroBadge,
                            style: GoogleFonts.cairo(
                              fontSize: 11.5,
                              color: AppColors.primaryGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'حفظت القصة والآية',
                      onPressed: () => _toggleStar(story.id),
                      icon: Icon(
                        isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                        color: AppColors.primaryGold,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  story.storyText,
                  style: GoogleFonts.cairo(
                    fontSize: 13.8,
                    height: 1.65,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 ماذا نتعلم من القصة؟\n${story.moralLesson}',
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          height: 1.55,
                          color: AppColors.primaryGoldLight,
                        ),
                      ),
                      const Divider(color: Colors.white12, height: 14),
                      Row(
                        children: [
                          const CopticCross(size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'آية الحفظ: ${story.memoryVerse}',
                              style: GoogleFonts.cairo(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SpeechPlayStopButton(
                        textToSpeak:
                            '${story.title}. ${story.storyText}. ماذا نتعلم من القصة: ${story.moralLesson}. آية الحفظ: ${story.memoryVerse}',
                        label: story.title,
                        playText: 'استمع للقصة والآية بصوت راوٍ 🔊',
                        stopText: 'إيقاف الصوت ⏹️',
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _toggleStar(story.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isStarred ? Colors.greenAccent : AppColors.primaryGoldLight,
                        side: BorderSide(
                          color: isStarred ? Colors.greenAccent : AppColors.primaryGold,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(
                        isStarred ? Icons.check_circle_rounded : Icons.star_outline_rounded,
                        size: 17,
                      ),
                      label: Text(
                        isStarred ? 'حفظتها ⭐' : 'حفظت الآية',
                        style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
