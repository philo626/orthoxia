import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../search/global_search_view.dart';
import 'bible_explorer_view.dart';

class ScripturePassage {
  final String id;
  final String title;
  final String reference;
  final String vocalizedText;
  final List<Map<String, String>> patristicCommentaries;

  const ScripturePassage({
    required this.id,
    required this.title,
    required this.reference,
    required this.vocalizedText,
    required this.patristicCommentaries,
  });
}

class ScriptureTafseerReadingView extends StatefulWidget {
  final int initialIndex;

  const ScriptureTafseerReadingView({super.key, this.initialIndex = 0});

  static const List<ScripturePassage> passages = [
    ScripturePassage(
      id: '1john_4',
      title: 'الله محبة',
      reference: 'رسالة يوحنا الرسول الأولى ٤ : ٧ - ١٦',
      vocalizedText:
          'أَيُّهَا الأَحِبَّاءُ، لِنُحِبَّ بَعْضُنَا بَعْضاً، لأَنَّ الْمَحَبَّةَ هِيَ مِنَ اللهِ، وَكُلُّ مَنْ يُحِبُّ فَقَدْ وُلِدَ مِنَ اللهِ وَيَعْرِفُ اللهَ ① وَمَنْ لاَ يُحِبُّ لَمْ يَعْرِفِ اللهَ، لأَنَّ اللهَ مَحَبَّةٌ ② بِهذَا أُظْهِرَتْ مَحَبَّةُ اللهِ فِينَا: أَنَّ اللهَ قَدْ أَرْسَلَ ابْنَهُ الْوَحِيدَ إِلَى الْعَالَمِ لِكَيْ نَحْيَا بِهِ ③ فِي هذَا هِيَ الْمَحَبَّةُ: لَيْسَ أَنَّنَا نَحْنُ أَحْبَبْنَا اللهَ، بَلْ أَنَّهُ هُوَ أَحَبَّنَا، وَأَرْسَلَ ابْنَهُ كَفَّارَةً لِخَطَايَانَا ④ وَنَحْنُ قَدْ عَرَفْنَا وَصَدَّقْنَا الْمَحَبَّةَ الَّتِي للهِ فِينَا. اللهُ مَحَبَّةٌ، وَمَنْ يَثْبُتْ فِي الْمَحَبَّةِ يَثْبُتْ فِي اللهِ وَاللهُ فِيهِ ⑤.',
      patristicCommentaries: [
        {
          'father': 'الجيل السمائي • القمص تادرس يعقوب ملطي',
          'body':
              'المحبة ليست مجرد فضيلة يقتنيها المؤمن، بل هي طبيعة الله ذاته؛ فحين نحب إخوتنا بقلب نقي، نثبت في الله ونتشكل على صورة المسيح الذي بذل ذاته لأجل خلاص العالم.',
        },
        {
          'father': 'الحياة الأرثوذكسية • قداسة البابا شنودة الثالث',
          'body':
              'القلب المملوء بمحبة الله لا يعرف الكراهية أو الإدانة، لأن المحبة الإلهية تفيض فيه سلاماً وبذلاً واحتمالاً للآخرين كما احتملنا الرب في محبتنا.',
        },
        {
          'father': 'القديس أوغسطينوس والآباء الأولون',
          'body':
              'إن أردت أن تعرف إن كنت قد ولدت من الروح القدس، فافحص قلبك: هل تحب إخوتك؟ لأن المحبة وحدها هي العلامة الحقيقية لأبناء الملكوت.',
        },
      ],
    ),
    ScripturePassage(
      id: 'john_1',
      title: 'في البدء كان الكلمة',
      reference: 'إنجيل معلمنا يوحنا البشير ١ : ١ - ١٤',
      vocalizedText:
          'فِي الْبَدْءِ كَانَ الْكَلِمَةُ، وَالْكَلِمَةُ كَانَ عِنْدَ اللهِ، وَكَانَ الْكَلِمَةُ اللهَ ① هذَا كَانَ فِي الْبَدْءِ عِنْدَ اللهِ. كُلُّ شَيْءٍ بِهِ كَانَ، وَبِغَيْرِهِ لَمْ يَكُنْ شَيْءٌ مِمَّا كَانَ ② فِيهِ كَانَتِ الْحَيَاةُ، وَالْحَيَاةُ كَانَتْ نُورَ النَّاسِ، وَالنُّورُ يُضِيءُ فِي الظُّلْمَةِ، وَالظُّلْمَةُ لَمْ تُدْرِكْهُ ③ وَالْكَلِمَةُ صَارَ جَسَداً وَحَلَّ بَيْنَنَا، وَرَأَيْنَا مَجْدَهُ، مَجْداً كَمَا لِوَحِيدٍ مِنَ الآبِ، مَمْلُوءاً نِعْمَةً وَحَقّاً ④.',
      patristicCommentaries: [
        {
          'father': 'القديس كيرلس الكبير (عمود الدين)',
          'body':
              'الكلمة الأزلي غير المحدود اتحد بناسوتنا الكامل دون اختلاط ولا امتزاج ولا تغيير، لكي يعيد إلينا الحياة النورانية التي فقدناها، ويجعلنا شركاء الطبيعة الإلهية بالروح القدس.',
        },
        {
          'father': 'القديس أثناسيوس الرسولي (حامي الإيمان)',
          'body':
              'صار ابن الله إنساناً لكي يرفع الإنسان إلى البنوة، وأشرق بنوره الإلهي في ظلمة العالم فلم تقوَ الظلمة على إطفاء نور القيامة والخلاص.',
        },
      ],
    ),
    ScripturePassage(
      id: 'matthew_5',
      title: 'التطويبات والموعظة على الجبل',
      reference: 'إنجيل معلمنا متى البشير ٥ : ١ - ١٢',
      vocalizedText:
          'وَلَمَّا رَأَى الْجُمُوعَ صَعِدَ إِلَى الْجَبَلِ، فَلَمَّا جَلَسَ تَقَدَّمَ إِلَيْهِ تَلاَمِيذُهُ ① فَضَرَبَ فَمَهُ وَعَلَّمَهُمْ قَائِلاً: طُوبَى لِلْمَسَاكِينِ بِالرُّوحِ، لأَنَّ لَهُمْ مَلَكُوتَ السَّمَاوَاتِ ② طُوبَى لِلْحَزَانَى، لأَنَّهُمْ يَتَعَزَّوْنَ. طُوبَى لِلْوُدَعَاءِ، لأَنَّهُمْ يَرِثُونَ الأَرْضَ ③ طُوبَى لِلْجِيَاعِ وَالْعِطَاشِ إِلَى الْبِرِّ، لأَنَّهُمْ يُشْبَعُونَ. طُوبَى لِلرُّحَمَاءِ، لأَنَّهُمْ يُرْحَمُونَ ④ طُوبَى لِلأَنْقِيَاءِ الْقَلْبِ، لأَنَّهُمْ يُعَايِنُونَ اللهَ ⑤.',
      patristicCommentaries: [
        {
          'father': 'القديس يوحنا ذهبي الفم',
          'body':
              'يبدأ السيد المسيح دستور الملكوت بالتواضع («المساكين بالروح»)، لأن الاتضاع هو الأساس الذي تُبنى عليه كل الفضائل الروحية ومعاينة مجد الله.',
        },
        {
          'father': 'القمص تادرس يعقوب ملطي',
          'body':
              'صعود الرب إلى الجبل يشير إلى رفع النفس البشرية فوق الاهتمامات الأرضية لتسمع صوت العريس السماوي وتتنعم بنقاوة القلب التي تعاين الله.',
        },
      ],
    ),
  ];

  @override
  State<ScriptureTafseerReadingView> createState() => _ScriptureTafseerReadingViewState();
}

class _ScriptureTafseerReadingViewState extends State<ScriptureTafseerReadingView> {
  late int _passageIndex;
  bool _drawerExpanded = false;

  @override
  void initState() {
    super.initState();
    _passageIndex = widget.initialIndex.clamp(0, ScriptureTafseerReadingView.passages.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final passage = ScriptureTafseerReadingView.passages[_passageIndex];
    final userName = StorageService().getUserName();
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: Stack(
          children: [
            // Top Header + Vocalized Scripture Area
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Bar (matches Frame 06)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      LuxeCircleButton(
                        icon: Icons.search_rounded,
                        onTap: () => Navigator.push(context, luxeRoute(const GlobalSearchView())),
                      ),
                      Text(
                        'الرئيسية',
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF231D14),
                            border: Border.all(
                              color: AppColors.primaryGold.withValues(alpha: 0.55),
                            ),
                          ),
                          child: const Center(
                            child: CopticCross(size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Passage Selector Chips + Open Full 66-Book Bible button
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      ...List.generate(ScriptureTafseerReadingView.passages.length, (i) {
                        final p = ScriptureTafseerReadingView.passages[i];
                        final sel = i == _passageIndex;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            label: Text(
                              p.title,
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: sel ? Colors.black : AppColors.textLight,
                              ),
                            ),
                            selected: sel,
                            selectedColor: AppColors.primaryGold,
                            backgroundColor: AppColors.cardNavy,
                            side: BorderSide(
                              color: sel
                                  ? AppColors.primaryGold
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                            onSelected: (_) {
                              HapticFeedback.selectionClick();
                              setState(() => _passageIndex = i);
                            },
                          ),
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(Icons.menu_book_rounded,
                            size: 15, color: AppColors.primaryGold),
                        backgroundColor: AppColors.cardNavy,
                        side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                        label: Text(
                          'كل أسفار الكتاب المقدس (٦٦ سفراً)',
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGoldLight,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(context, luxeRoute(const BibleExplorerView()));
                        },
                      ),
                    ],
                  ),
                ),

                // Main Vocalized Scripture Area (matches Frame 06 typography)
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      22,
                      14,
                      22,
                      _drawerExpanded ? screenH * 0.68 : screenH * 0.44,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'أهلاً بك يا $userName',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGold,
                              ),
                            ),
                            Text(
                              passage.reference,
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          passage.vocalizedText,
                          textAlign: TextAlign.justify,
                          style: GoogleFonts.amiri(
                            fontSize: 22.5,
                            height: 1.95,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textLight,
                          ),
                        ).animate(key: ValueKey(passage.id)).fadeIn(duration: 350.ms),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Expandable Bottom Patristic Commentary Drawer ("التفسير الآبائي" - matches Frame 06)
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOutCubic,
                height: _drawerExpanded ? screenH * 0.66 : screenH * 0.41,
                decoration: BoxDecoration(
                  color: const Color(0xFF141417),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.primaryGold.withValues(alpha: 0.45),
                      width: 1.4,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 28,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drawer Handle + Header ("التفسير الآبائي" + Chevron ^)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _drawerExpanded = !_drawerExpanded);
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                        child: Column(
                          children: [
                            Container(
                              width: 44,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  _drawerExpanded
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.keyboard_arrow_up_rounded,
                                  color: AppColors.primaryGoldLight,
                                  size: 24,
                                ),
                                Text(
                                  'التفسير الآبائي',
                                  style: GoogleFonts.cairo(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textLight,
                                  ),
                                ),
                                const SizedBox(width: 24),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    // Patristic Commentary Cards with Circular Gold Cross Badges (as in Frame 06)
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        itemCount: passage.patristicCommentaries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, idx) {
                          final item = passage.patristicCommentaries[idx];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1F1F23),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Circular Gold Cross Badge on the right (in RTL)
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.champagne,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryGold.withValues(alpha: 0.25),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: CopticCross(
                                      size: 20,
                                      color: Color(0xFF23180B),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['father'] ?? '',
                                        style: GoogleFonts.cairo(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textLight,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item['body'] ?? '',
                                        style: GoogleFonts.cairo(
                                          fontSize: 12.5,
                                          height: 1.55,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 280.ms, delay: (idx * 60).ms);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
