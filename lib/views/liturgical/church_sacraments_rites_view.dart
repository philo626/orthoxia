import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/widgets/coptic_cross.dart';

class SacramentRiteSection {
  final String role;
  final String title;
  final String copticOrArabized;
  final String arabicText;

  const SacramentRiteSection({
    required this.role,
    required this.title,
    this.copticOrArabized = '',
    required this.arabicText,
  });
}

class SacramentRite {
  final String id;
  final String title;
  final String emoji;
  final String occasion;
  final String overview;
  final List<SacramentRiteSection> sections;

  const SacramentRite({
    required this.id,
    required this.title,
    required this.emoji,
    required this.occasion,
    required this.overview,
    required this.sections,
  });
}

class ChurchSacramentsRitesView extends StatefulWidget {
  const ChurchSacramentsRitesView({super.key});

  static const List<SacramentRite> rites = [
    SacramentRite(
      id: 'lakan',
      title: 'طقس وصلاة اللقان المقدس',
      emoji: '💧',
      occasion: 'يُصلى ٣ مرات في السنة: عيد الغطاس • خميس العهد • عيد الآباء الرسل',
      overview: 'صلاة تقديس الماء في اللقان تذكاراً لمعمودية الرب يسوع في نهر الأردن (الغطاس)، ولغسله أرجل التلاميذ باتضاع (خميس العهد)، ولإرسالية التلاميذ لتعميد الأمم (عيد الرسل).',
      sections: [
        SacramentRiteSection(
          role: 'الكاهن',
          title: 'صلاة الشكر والنبوات والمزامير',
          copticOrArabized: 'مارين شيب إهموت إنطوطف إم إفنوتي • إسمو إيروف',
          arabicText: 'تُفتتح صلاة اللقان بصلاة الشكر ورفع البخور، ثم تُقرأ نبوات من العهد القديم تشير إلى قوة الماء المطهر، ويتلو الشعب الهيتينيات وأوشية الإنجيل.',
        ),
        SacramentRiteSection(
          role: 'الكاهن',
          title: 'الطلبات الكبرى على ماء اللقان',
          copticOrArabized: 'كيريي إليسون (يا رب ارحم)',
          arabicText: 'أيها السيد الرب الإله ضابط الكل، خالق المياه وينبوع الحياة، قدس هذا الماء بروحك القدوس، ليكون ماء بركة وطهارة وشفاءً للنفوس والأجساد، واغسل قلوبنا من كل دنس الخطية كما غسلت أرجل تلاميذك القديسين.',
        ),
        SacramentRiteSection(
          role: 'الشعب',
          title: 'مرد الشعب أثناء رشومات اللقان',
          copticOrArabized: 'كيرياليسون • كيرياليسون • كيرياليسون',
          arabicText: 'يا رب ارحم (يرددها الشعب مع كل طلبة، ثم يرشم الكاهن الماء بالصليب ثلاث مرات باسم الآب والابن والروح القدس، ويبارك الشعب بالماء المقدس).',
        ),
      ],
    ),
    SacramentRite(
      id: 'pentecost_sagda',
      title: 'صلوات السجدة المقدسة (عيد العنصرة)',
      emoji: '🔥',
      occasion: 'تُصلى عصر يوم أحد عيد العنصرة (حلول الروح القدس)',
      overview: 'ثلاث سجدات خاشعة للثالوث القدوس (السجدة الأولى للآب، والثانية للابن، والثالثة للروح القدس)، حيث نركع لأول مرة بعد خمسين يوماً من القيامة شكراً على حلول الروح القدس المعزي.',
      sections: [
        SacramentRiteSection(
          role: 'الشماس',
          title: 'نداء السجدة في عيد البنطيقسطي',
          copticOrArabized: 'إكلينومين طاغوناطا • أنيستومي',
          arabicText: 'نحني ركبنا أمام الرب! نقوم ثم نحني ركبنا أيضاً! فلنسجد للآب والابن والروح القدس الثالوث المساوي في الجوهر.',
        ),
        SacramentRiteSection(
          role: 'الكاهن',
          title: 'السجدة الأولى (موجهة لله الآب)',
          copticOrArabized: 'إفنوتي بي نيشتي بي شا إينيه',
          arabicText: 'أيها الرب الإله الآب الأزلي غير المدرك، الذي أرسل ابنه الوحيد لخلاص العالم، تقبل سجودنا وتضرعاتنا، وأرح نفوس آبائنا وإخوتنا الذين رقدوا على رجاء القيامة في فردوس النعيم.',
        ),
        SacramentRiteSection(
          role: 'الكاهن',
          title: 'السجدة الثانية (موجهة لله الابن الكلمة)',
          copticOrArabized: 'بي إخريستوس بين نوتي',
          arabicText: 'أيها السيد الرب يسوع المسيح كلمة الآب، الذي صعد إلى السماوات وجلس عن يمين العظمة وأرسل لنا الروح المعزي، هب لنا روح الحكمة والفهم ومخافتك المقدسة.',
        ),
        SacramentRiteSection(
          role: 'الكاهن',
          title: 'السجدة الثالثة (استدعاء مواهب الروح القدس)',
          copticOrArabized: 'بي إبنيفما إمباراكليطون',
          arabicText: 'أيها الملك السمائي المعزي، روح الحق الحاضر في كل مكان والمالئ الكل، هلم اسكن فينا وطهرنا من كل دنس، وخلص أيها الصالح نفوسنا، وجدد وجه الأرض بسلامك.',
        ),
      ],
    ),
    SacramentRite(
      id: 'matrimony',
      title: 'طقس سر الإكليل المقدس (الزيجة)',
      emoji: '👑',
      occasion: 'سر اتحاد العروسين في الرب على مثال اتحاد المسيح بالكنيسة',
      overview: 'سر مقدس يصير به العروسان جسداً واحداً بالروح القدس، ويشمل تبريك الخواتم (العربون)، القراءات، دهن الزيت، إلباس البرنس والأكاليل، والوصايا المقدسة.',
      sections: [
        SacramentRiteSection(
          role: 'الكاهن',
          title: 'صلاة تبريك الأكاليل والاتحاد المقدس',
          copticOrArabized: 'إفنوتي بي أجيوس • بارك إكليلهما',
          arabicText: 'اللهم القدوس الذي جبل الإنسان على صورته ومثاله، وقال ليس حسناً أن يكون آدم وحده، بارك عبديك هذين، واجمعهما في وحدانية المحبة والطهارة، وكللهما بإكليل المجد والكرامة.',
        ),
        SacramentRiteSection(
          role: 'الشماس',
          title: 'وصايا الكنيسة للعروسين',
          copticOrArabized: 'الوصية الرسولية للبيت المسيحي',
          arabicText: 'يجب عليك أيها العريس المبارك أن تتسلم زوجتك في هذه الساعة بنية خالصة وقلب طاهر، وتكرمها كجسدك كما أحب المسيح الكنيسة. وأنتِ أيتها العروس المباركة أكرمي رجلَكِ وكوني معه في سلام ووداعة، وليبارك الرب بيتكما بالنسل الصالح والسلام.',
        ),
      ],
    ),
    SacramentRite(
      id: 'unction_sick',
      title: 'طقس سر مسحة المرضى (القنديل)',
      emoji: '⚕️',
      occasion: 'سبع صلوات لشفاء النفس والجسد (ويُصلى القنديل العام في جمعة ختام الصوم)',
      overview: 'تأسيساً على وصية معلمنا يعقوب الرسول: «أمريض أحد بينكم؟ فليدعُ قسوس الكنيسة فيصلوا عليه ويدهنوه بزيت باسم الرب، وصلاة الإيمان تشفي المريض».',
      sections: [
        SacramentRiteSection(
          role: 'الكاهن',
          title: 'صلاة شفاء المرضى وتقديس الزيت',
          copticOrArabized: 'طبيب النفوس والأجساد الحقيقي',
          arabicText: 'أيها السيد الرب يسوع المسيح طبيب نفوسنا وأجسادنا الحقيقي، الذي حمل أمراضنا وأوجاعنا، قدس هذا الزيت ليكون شفاءً وعافيةً لكل من يُدهن به بإيمان، وانزع كل مرض وكل وجع، وأقم عبيدك بمعونتك الإلهية.',
        ),
      ],
    ),
    SacramentRite(
      id: 'baptism_myron',
      title: 'طقس سر المعمودية والميرون المقدس',
      emoji: '🕊️',
      occasion: 'سر الميلاد الثاني من الماء والروح وختم الروح القدس (٣٦ رشماً)',
      overview: 'بالمعمودية ندفن مع المسيح ونقوم معه خليقة جديدة، وبالميرون المقدس ننال سكنى وختم الروح القدس في كل حواسنا وأعضائنا.',
      sections: [
        SacramentRiteSection(
          role: 'الكاهن',
          title: 'جحد الشيطان والإقرار بالإيمان بالمسيح',
          copticOrArabized: 'أجحدك أيها الشيطان • وأعترف بك أيها المسيح إلهي',
          arabicText: 'ينظر المعمد (أو إشبينه) نحو الغرب ويجحد الشيطان وكل أعماله الشريرة، ثم يلتفت نحو الشرق ويرفع يديه معلناً: أعترف بك أيها المسيح إلهي وبكل نواميسك المخلصة، ويتلو قانون الإيمان الأرثوذكسي.',
        ),
        SacramentRiteSection(
          role: 'الكاهن',
          title: 'التغطيس الثلاثي ورشومات الميرون الـ ٣٦',
          copticOrArabized: 'أعمدك باسم الآب والابن والروح القدس',
          arabicText: 'يُغطس المعمد ثلاث دفعات باسم الآب والابن والروح القدس، ثم يُرشم بزيت الميرون المقدس ٣٦ رشماً على جميع الحواس والمفاصل قائلاً: مسحة نعمة الروح القدس، مسحة عربون ملكوت السماوات. آمين.',
        ),
      ],
    ),
  ];

  @override
  State<ChurchSacramentsRitesView> createState() => _ChurchSacramentsRitesViewState();
}

class _ChurchSacramentsRitesViewState extends State<ChurchSacramentsRitesView> {
  int _selectedRiteIdx = 0;

  @override
  void dispose() {
    SpeechPronunciationService().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rite = ChurchSacramentsRitesView.rites[_selectedRiteIdx];

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        centerTitle: true,
        title: Text(
          'الطقوس الكنسية والأسرار واللقان',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          // Horizontal Rites Selector
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              itemCount: ChurchSacramentsRitesView.rites.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final r = ChurchSacramentsRitesView.rites[idx];
                final sel = idx == _selectedRiteIdx;
                return ChoiceChip(
                  showCheckmark: false,
                  label: Text(
                    '${r.emoji} ${r.title}',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: sel ? Colors.black : Colors.white,
                    ),
                  ),
                  selected: sel,
                  selectedColor: AppColors.primaryGold,
                  backgroundColor: AppColors.cardNavy,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    SpeechPronunciationService().stop();
                    setState(() => _selectedRiteIdx = idx);
                  },
                );
              },
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 36),
              children: [
                // Overview Hero Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2B2012), Color(0xFF14151D)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.primaryGold, width: 1.3),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(rite.emoji, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rite.title,
                                  style: GoogleFonts.cairo(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGoldLight,
                                  ),
                                ),
                                Text(
                                  rite.occasion,
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    color: AppColors.primaryGold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        rite.overview,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          height: 1.6,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SpeechPlayStopButton(
                          textToSpeak:
                              '${rite.title}. ${rite.overview}. ${rite.sections.map((s) => "${s.title}: ${s.arabicText}").join(". ")}',
                          label: rite.title,
                          playText: 'استماع للطقس كاملاً 🔊',
                          stopText: 'إيقاف الصوت ⏹️',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Sections
                ...rite.sections.map((sec) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardNavy,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const CopticCross(size: 16),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                sec.role,
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGoldLight,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                sec.title,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGoldLight,
                                ),
                              ),
                            ),
                            SpeechPlayStopButton(
                              textToSpeak: '${sec.title}. ${sec.arabicText}',
                              label: sec.title,
                              playText: 'استماع 🔊',
                              stopText: 'إيقاف ⏹️',
                              compact: true,
                            ),
                          ],
                        ),
                        if (sec.copticOrArabized.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '☦ ${sec.copticOrArabized}',
                            style: GoogleFonts.cairo(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGold,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        SelectableText(
                          sec.arabicText,
                          style: GoogleFonts.amiri(
                            fontSize: 19,
                            height: 1.75,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
