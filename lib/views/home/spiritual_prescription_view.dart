import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/blessing_poster_studio_sheet.dart';
import '../../core/widgets/coptic_cross.dart';

class SpiritualMoodPrescription {
  final String id;
  final String label;
  final IconData icon;
  final String verse;
  final String verseRef;
  final String psalmExcerpt;
  final String psalmRef;
  final String patristicSaying;
  final String patristicAuthor;
  final String personalPrayer;

  const SpiritualMoodPrescription({
    required this.id,
    required this.label,
    required this.icon,
    required this.verse,
    required this.verseRef,
    required this.psalmExcerpt,
    required this.psalmRef,
    required this.patristicSaying,
    required this.patristicAuthor,
    required this.personalPrayer,
  });
}

class SpiritualPrescriptionView extends StatefulWidget {
  final int initialMoodIndex;

  const SpiritualPrescriptionView({super.key, this.initialMoodIndex = 0});

  static const List<SpiritualMoodPrescription> prescriptions = [
    SpiritualMoodPrescription(
      id: 'anxiety',
      label: 'قلق وخوف',
      icon: Icons.shield_outlined,
      verse:
          'لاَ تَخَفْ لأَنِّي مَعَكَ. لاَ تَتَلَفَّتْ لأَنِّي إِلهُكَ. قَدْ أَيَّدْتُكَ وَأَعَنْتُكَ وَعَضَدْتُكَ بِيَمِينِ بِرِّي.',
      verseRef: 'إشعياء ٤١ : ١٠',
      psalmExcerpt:
          'الرَّبُّ نُورِي وَخَلاَصِي، مِمَّنْ أَخَافُ؟ الرَّبُّ حِصْنُ حَيَاتِي، مِمَّنْ أَرْتَعِبُ؟',
      psalmRef: 'مزمور ٢٧ : ١',
      patristicSaying:
          'كن مطمئناً جداً جداً، ولا تفكر في الأمر كثيراً، بل دع الأمر لمن بيده الأمر.',
      patristicAuthor: 'القديس البابا كيرلس السادس',
      personalPrayer:
          'يا ربي يسوع المسيح ملك السلام، أضع بين يديك كل قلقي وخوفي من الغد. أنت قلت تعالوا إليّ يا جميع المتعبين وأنا أريحكم؛ املأ قلبي بسلامك الفائق لكل عقل. آمين.',
    ),
    SpiritualMoodPrescription(
      id: 'sadness',
      label: 'حزن وضيق',
      icon: Icons.water_drop_outlined,
      verse:
          'قَرِيبٌ هُوَ الرَّبُّ مِنَ الْمُنْكَسِرِي الْقُلُوبِ، وَيُخَلِّصُ الْمُنْسَحِقِي الرُّوحِ.',
      verseRef: 'مزمور ٣٤ : ١٨',
      psalmExcerpt:
          'عِنْدَ كَثْرَةِ هُمُومِي فِي دَاخِلِي، تَعْزِيَاتُكَ تُلَذِّذُ نَفْسِي.',
      psalmRef: 'مزمور ٩٤ : ١٩',
      patristicSaying:
          'مسيرها تنتهي... لا توجد ضيقة دائمة تستمر مدى الحياة، وثق أن الله يحول كل ضيق إلى بركة.',
      patristicAuthor: 'قداسة البابا شنودة الثالث',
      personalPrayer:
          'أيها الرب الحنون معزي الحزانى، انظر إلى تعب قلبي وامسح بيدك المثقوبة كل دمعة وحزن، وهبني رجاءً حياً وفرحاً سماوياً لا ينزعه أحد مني. آمين.',
    ),
    SpiritualMoodPrescription(
      id: 'lukewarm',
      label: 'فتور روحي',
      icon: Icons.local_fire_department_outlined,
      verse: 'اِقْتَرِبُوا إِلَى اللهِ فَيَقْتَرِبَ إِلَيْكُمْ.',
      verseRef: 'يعقوب ٤ : ٨',
      psalmExcerpt:
          'قَلْباً نَقِيّاً اخْلُقْ فِيَّ يَا اللهُ، وَرُوحاً مُسْتَقِيماً جَدِّدْ فِي دَاخِلِي.',
      psalmRef: 'مزمور ٥١ : ١٠',
      patristicSaying:
          'كما أن السمك إذا خرج من الماء يموت، هكذا النفس إن ابتعدت عن الصلاة تفتر؛ ارفع يديك الآن وقل: يا رب أعنّي.',
      patristicAuthor: 'القديس الأنبا أنطونيوس الكبير',
      personalPrayer:
          'يا روح الله القدوس الناري، أشعل قلبي الفاتر بمحبتك من جديد، وانزع عني الكسل والتأجيل لأذوق حلاوة الوقوف أمامك كل يوم. آمين.',
    ),
    SpiritualMoodPrescription(
      id: 'confusion',
      label: 'حيرة وقرار',
      icon: Icons.explore_outlined,
      verse:
          'تَوَكَّلْ عَلَى الرَّبِّ بِكُلِّ قَلْبِكَ، وَعَلَى فَهْمِكَ لاَ تَعْتَمِدْ. فِي كُلِّ طُرُقِكَ اعْرِفْهُ، وَهُوَ يُقَوِّمُ سُبُلَكَ.',
      verseRef: 'أمثال ٣ : ٥ - ٦',
      psalmExcerpt:
          'عَرِّفْنِي يَا رَبُّ طُرُقَكَ، وَسُبُلَكَ عَلِّمْنِي. دَرِّبْنِي فِي حَقِّكَ وَعَلِّمْنِي.',
      psalmRef: 'مزمور ٢٥ : ٤ - ٥',
      patristicSaying:
          'حين تسلّم دفة السفينة لله بهدوء، يقودك بروحه القدوس إلى الميناء الأمين دون أن تضل.',
      patristicAuthor: 'القديس يوحنا ذهبي الفم',
      personalPrayer:
          'يا رب الحكمة والنور، أرشدني في قراري هذا؛ إن كان هذا الطريق منك فباركه وافتح أبوابه بسلام، وإن لم يكن حسب مشيئتك فأغلق بابه وعوضني خيراً. آمين.',
    ),
    SpiritualMoodPrescription(
      id: 'repentance',
      label: 'توبة ورجوع',
      icon: Icons.favorite_border_rounded,
      verse:
          'إِنِ اعْتَرَفْنَا بِخَطَايَانَا فَهُوَ أَمِينٌ وَعَادِلٌ، حَتَّى يَغْفِرَ لَنَا خَطَايَانَا وَيُطَهِّرَنَا مِنْ كُلِّ إِثْمٍ.',
      verseRef: '١ يوحنا ١ : ٩',
      psalmExcerpt:
          'ارْحَمْنِي يَا اللهُ كَعَظِيمِ رَحْمَتِكَ، وَمِثْلَ كَثْرَةِ رَأْفَتِكَ امْحُ مَآثِمِي.',
      psalmRef: 'مزمور ٥١ : ١',
      patristicSaying:
          'لا توجد خطية بلا مغفرة إلا التي بلا توبة؛ وكما أن كمشة رمل لا تقف أمام البحر، هكذا خطايانا أمام رحمة الله.',
      patristicAuthor: 'القديس الأنبا موسى القوي ومارإسحق السرياني',
      personalPrayer:
          'يا مخلصي الصالح الذي فتح ذراعيه على الصليب لكي يقبل الخطاة، اقبلني اليوم كالابن الضال، واغسلني بدمك الثمين وهبني بداية جديدة طاهرة. آمين.',
    ),
    SpiritualMoodPrescription(
      id: 'gratitude',
      label: 'فرح وشكر',
      icon: Icons.wb_sunny_outlined,
      verse: 'بَارِكِي يَا نَفْسِي الرَّبَّ، وَلاَ تَنْسَيْ كُلَّ حَسَنَاتِهِ.',
      verseRef: 'مزمور ١٠٣ : ٢',
      psalmExcerpt:
          'هذَا هُوَ الْيَوْمُ الَّذِي صَنَعَهُ الرَّبُّ، نَبْتَهِجُ وَنَفْرَحُ فِيهِ.',
      psalmRef: 'مزمور ١١٨ : ٢٤',
      patristicSaying:
          'المجد لله على كل حال! القلب الشاكر يجذب نعم الله ويزيد البركة أضعافاً.',
      patristicAuthor: 'القديس يوحنا ذهبي الفم',
      personalPrayer:
          'فلنشكر صانع الخيرات الرحوم الله، لأنك سترتنا وأعنتنا وحفظتنا وقبلتنا إليك وأشفقت علينا وعضدتنا وأتيت بنا إلى هذه الساعة. لك المجد إلى الأبد. آمين.',
    ),
  ];

  @override
  State<SpiritualPrescriptionView> createState() =>
      _SpiritualPrescriptionViewState();
}

class _SpiritualPrescriptionViewState extends State<SpiritualPrescriptionView> {
  final SpeechPronunciationService _speech = SpeechPronunciationService();
  late int _selectedIdx;

  @override
  void initState() {
    super.initState();
    _selectedIdx = widget.initialMoodIndex.clamp(
      0,
      SpiritualPrescriptionView.prescriptions.length - 1,
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final item = SpiritualPrescriptionView.prescriptions[_selectedIdx];

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'خلوة هادئة لقلبك',
          style: GoogleFonts.amiri(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: p.ink,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(
                SpiritualPrescriptionView.prescriptions.length, (i) {
              final mood = SpiritualPrescriptionView.prescriptions[i];
              final sel = i == _selectedIdx;
              return ChoiceChip(
                avatar: Icon(
                  mood.icon,
                  size: 15,
                  color: sel ? p.onAccent : p.accent,
                ),
                label: Text(
                  mood.label,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: sel ? p.onAccent : p.ink,
                  ),
                ),
                selected: sel,
                selectedColor: p.accent,
                backgroundColor: p.surfaceElevated,
                showCheckmark: false,
                side: BorderSide(color: sel ? p.accent : p.border),
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  _speech.stop();
                  setState(() => _selectedIdx = i);
                },
              );
            }),
          ),
          const SizedBox(height: 18),
          _buildSectionCard(
            p: p,
            icon: Icons.auto_stories_rounded,
            badge: '١. وعد الله لك الآن (${item.verseRef})',
            body: '«${item.verse}»',
            isScripture: true,
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            p: p,
            icon: Icons.music_note_rounded,
            badge: '٢. صرخة المزمور (${item.psalmRef})',
            body: '«${item.psalmExcerpt}»',
            isScripture: true,
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            p: p,
            icon: Icons.format_quote_rounded,
            badge: '٣. إرشاد الآباء (${item.patristicAuthor})',
            body: '«${item.patristicSaying}»',
            isScripture: false,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: p.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.accent.withValues(alpha: 0.45)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CopticCross(size: 18, color: p.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '٤. صلاتك الشخصية الآن',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: p.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.personalPrayer,
                  style: GoogleFonts.amiri(
                    fontSize: 19.5,
                    height: 1.75,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _speech.isSpeakingNotifier,
                        builder: (context, speaking, _) {
                          return ElevatedButton.icon(
                            onPressed: () {
                              if (speaking) {
                                _speech.stop();
                              } else {
                                final fullAudio =
                                    'وعد الله لك: ${item.verse}. من المزمور: ${item.psalmExcerpt}. يقول ${item.patristicAuthor}: ${item.patristicSaying}. صلاتك الآن: ${item.personalPrayer}';
                                _speech.speakText(fullAudio,
                                    label: 'خلوة ${item.label}');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: speaking ? p.crimson : p.accent,
                              foregroundColor:
                                  speaking ? Colors.white : p.onAccent,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: Icon(
                                speaking
                                    ? Icons.stop_rounded
                                    : Icons.volume_up_rounded,
                                size: 18),
                            label: Text(
                              speaking ? 'إيقاف الصوت' : 'استماع للخلوة',
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w700, fontSize: 12.5),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          BlessingPosterStudioSheet.show(
                            context,
                            title: 'رسالة تعزية ورجاء (${item.label})',
                            bodyText: item.verse,
                            reference: item.verseRef,
                            footerPrayer: item.personalPrayer,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: p.accent,
                          side: BorderSide(color: p.accent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(Icons.photo_camera_back_rounded,
                            size: 18, color: p.accent),
                        label: Text(
                          'مشاركة كبطاقة',
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.w700, fontSize: 12.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required AppPalette p,
    required IconData icon,
    required String badge,
    required String body,
    required bool isScripture,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: p.accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  badge,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: isScripture
                ? GoogleFonts.amiri(fontSize: 19, height: 1.75, color: p.ink)
                : GoogleFonts.cairo(fontSize: 14, height: 1.65, color: p.ink),
          ),
        ],
      ),
    );
  }
}
