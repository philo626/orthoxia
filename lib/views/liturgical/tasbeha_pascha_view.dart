import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/coptic_calendar_service.dart';
import '../../core/widgets/coptic_cross.dart';

class TasbehaPaschaView extends StatefulWidget {
  final int initialTab;
  const TasbehaPaschaView({super.key, this.initialTab = 0});

  @override
  State<TasbehaPaschaView> createState() => _TasbehaPaschaViewState();
}

class _TasbehaPaschaViewState extends State<TasbehaPaschaView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static const List<Map<String, String>> _tasbehaParts = [
    {
      'title': '١. تين ثينو (قوموا يا بني النور)',
      'coptic': 'Ⲧⲉⲛⲑⲏⲛⲟⲩ ⲉ̀ⲡ̀ϣⲱⲓ ⲛⲓϣⲏⲣⲓ ⲛ̀ⲧⲉ ⲡⲓⲟⲩⲱⲓⲛⲓ',
      'arabized': 'تين ثينو إيبشوي ني شيري إنتيه بي أوؤيني، إنتين هوس إيبشويس إنتيه ني جوم.',
      'arabic': 'قوموا يا بني النور لنسبح رب القوات، لكي ينعم علينا بخلاص نفوسنا. عندما نقف أمامك جسدياً انزع من عقولنا نوم الغفلة.',
    },
    {
      'title': '٢. الهوس الأول (تسبحة موسى النبي - خروج ١٥)',
      'coptic': 'Ⲙⲁⲣⲉⲛϩⲱⲥ ⲉ̀Ⲡ̀ϭⲟⲓⲥ ϫⲉ ϧⲉⲛ ⲟⲩⲱ̀ⲟⲩ ⲅⲁⲣ ⲁϥϭⲓⲱ̀ⲟⲩ',
      'arabized': 'مارين هوس إيبشويس جيه خين أوؤؤ غار أف تشي أوؤ... تين هوس إيروك أوه تين إزمو إيروك.',
      'arabic': 'فلنسبح الرب لأنه بالمجد قد تمجد، الفرس وراكبه طرحهما في البحر. معيناً وساتراً صار لي للخلاص، هذا هو إلهي فأمجده إله أبي فأرفعه.',
    },
    {
      'title': '٣. الهوس الثاني (مزمور ١٣٦ - اشكروا الرب)',
      'coptic': 'Ⲟⲩⲱⲛϩ ⲉ̀ⲃⲟⲗ ⲙ̀Ⲡ̀ϭⲟⲓⲥ ϫⲉ ⲟⲩⲭ̀ⲣⲏⲥⲧⲟⲥ ⲡⲉ: Ⲁⲗⲗⲏⲗⲟⲩⲓⲁ',
      'arabized': 'أوؤنه إيفول إم إبشويس جيه أو إخريستوس بيه، ألليلويا، جيه بيف ناي شوب شا إينيه.',
      'arabic': 'اشكروا الرب لأنه صالح ألليلويا، لأن إلى الأبد رحمته. اشكروا إله الآلهة، اشكروا رب الأرباب، الصانع العجائب العظام وحده، لأن إلى الأبد رحمته.',
    },
    {
      'title': '٤. الهوس الثالث (تسبحة الثلاثة فتية القديسين)',
      'coptic': 'Ⲕ̀ⲥ̀ⲙⲁⲣⲱⲟⲩⲧ Ⲡ̀ϭⲟⲓⲥ Ⲫ̀ⲛⲟⲩϯ ⲛ̀ⲧⲉ ⲛⲉⲛⲓⲟϯ',
      'arabized': 'إك إزماروؤت إبشويس إفنوتي إنتيه نين يوتي، أوه إك إزمامات أوه إك إتشوسي شا ني إينيه.',
      'arabic': 'مبارك أنت أيها الرب إله آبائنا، ومتزايد بركة ومتزايد علواً إلى الأبد. باركي الرب يا جميع أعمال الرب، سبحيه وزيديه علواً إلى الآباد.',
    },
    {
      'title': '٥. مجمع القديسين بالتسبحة (شفاعة السمائيين)',
      'coptic': 'Ⲁⲣⲓⲡ̀ⲣⲉⲥⲃⲉⲩⲓⲛ ⲉ̀ϩ̀ⲣⲏⲓ ⲉ̀ϫⲱⲛ ⲱ̀ ⲧⲉⲛϭⲟⲓⲥ ⲛ̀ⲛⲏⲃ ⲧⲏⲣⲉⲛ Ϯⲑⲉⲟ̀ⲧⲟⲕⲟⲥ',
      'arabized': 'أريبريسفيفين إيه إهري إيجون أوتين شويس إن نيب تيرين تي ثيؤطوكوس، ماريا إثماف إمبين سوتير.',
      'arabic': 'اشفعي فينا يا سيدتنا كلنا السيدة والدة الإله مريم أم مخلصنا، ليغفر لنا خطايانا. اشفعوا فينا يا رؤساء الملائكة الأطهار والشهداء والأبرار.',
    },
    {
      'title': '٦. الهوس الرابع (المزامير ١٤٨ و ١٤٩ و ١٥٠)',
      'coptic': 'Ⲥ̀ⲙⲟⲩ ⲉ̀Ⲫ̀ⲛⲟⲩϯ ϧⲉⲛ ⲛⲏⲉⲑⲟⲩⲁⲃ ⲧⲏⲣⲟⲩ ⲛ̀ⲧⲁϥ',
      'arabized': 'إزمو إيه إفنوتي خين ني إثؤواب تيرو إنتاف: ألليلويا. كل نسمة فلتسبح اسم الرب إلهنا.',
      'arabic': 'سبحوا الله في جميع قديسيه، سبحوه في فلك قوته، سبحوه على مقدرته، سبحوه ككثرة عظمته. كل نسمة فلتسبح اسم الرب إلهنا.',
    },
  ];

  static const List<Map<String, String>> _paschaParts = [
    {
      'title': 'تسبحة البصخة المقدسة (ثوك تي تي جوم)',
      'coptic': 'Ⲑⲱⲕ ⲧⲉ ϯϫⲟⲙ ⲛⲉⲙ ⲡⲓⲱ̀ⲟⲩ ⲛⲉⲙ ⲡⲓⲥ̀ⲙⲟⲩ ⲛⲉⲙ ⲡⲓⲁ̀ⲙⲁϩⲓ ϣⲁ ⲉ̀ⲛⲉϩ Ⲁ̀ⲙⲏⲛ',
      'arabized': 'ثوك تي تي جوم، نيم بي أوؤ، نيم بي إزمو، نيم بي أماهي شا إينيه أمين. إممانوئيل بين نوتي بين أورو.',
      'arabic': 'لك القوة والمجد والبركة والعزة إلى الأبد آمين. عمانوئيل إلهنا وملكنا. يا ربي يسوع المسيح مخلصي الصالح، قوتي وتسبحتي هو الرب وقد صار لي خلاصاً مقدساً. (تُقال ١٢ مرة في كل ساعة من ساعات البصخة النهارية والليلية).',
    },
    {
      'title': 'لحن بيك إثرونوس (الجمعة العظيمة - الساعة السادسة)',
      'coptic': 'Ⲡⲉⲕⲑ̀ⲣⲟⲛⲟⲥ Ⲫ̀ⲛⲟⲩϯ ϣⲁ ⲉ̀ⲛⲉϩ ⲛ̀ⲧⲉ ⲡⲓⲉ̀ⲛⲉϩ',
      'arabized': 'بيك إثرونوس إفنوتي شا إينيه إنتيه بي إينيه، إبش فوت إمبي سوتين بيه إبش فوت إنتيه تيك ميت أورو.',
      'arabic': 'كرسيك يا الله إلى دهر الدهور، قضيب الاستقامة هو قضيب ملكك. لأنك أحببت البر وأبغضت الإثم، من أجل هذا مسحك الله إلهك بدهن البهجة أفضل من رفقائك.',
    },
    {
      'title': 'أمانة اللص اليمين (الجمعة العظيمة - الساعة التاسعة)',
      'coptic': 'Ⲁ̀ⲣⲓⲡⲁⲙⲉⲩⲓ ⲱ̀ Ⲡⲁϭⲟⲓⲥ ⲁⲕϣⲁⲛⲓ̀ ϧⲉⲛ ⲧⲉⲕⲙⲉⲧⲟⲩⲣⲟ',
      'arabized': 'أريباميفي أو باشويس أكشان إي خين تيك ميت أورو... أريباميفي أو با أورو، أريباميفي أو با سوتير.',
      'arabic': 'اذكرني يا رب متى جئت في ملكوتك. اذكرني يا قدوس متى جئت في ملكوتك. اذكرني يا سيد متى جئت في ملكوتك.',
    },
    {
      'title': 'لحن غولغوثا (الساعة الثانية عشرة - الدفن المقدس)',
      'coptic': 'Ⲅⲟⲗⲅⲟⲑⲁ ⲙ̀ⲙⲉⲧϩⲉⲃⲣⲉⲟⲥ ⲡⲓⲕ̀ⲣⲁⲛⲓⲟⲛ ⲙ̀ⲙⲉⲧⲟⲩⲉⲓⲛⲓⲛ',
      'arabized': 'غولغوثا إم ميت هيبريؤس، بي إكرانيون إم ميت أوينين، بي ما إيطاف إيشك إينخيتف باشويس إيسوس بي إخريستوس.',
      'arabic': 'الجلجثة بالعبرانية، الإكرانيون باليونانية، الموضع الذي صُلبت فيه يا ربي يسوع المسيح. بسطت يديك الطاهرتين فصُلب معك لصان عن يمينك وعن يسارك وأنت كائن في الوسط أيها المخلص الصالح.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final movableFeasts = CopticCalendarService.getMovableFeastsForYear(_selectedYear);

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: const Color(0xFF10121A),
        centerTitle: true,
        title: Text(
          'التسبحة والبصخة والأعياد المتحركة',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 15.5),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGold,
          labelColor: AppColors.primaryGoldLight,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: 'التسبحة (الإبصلمودية)'),
            Tab(text: 'البصخة المقدسة'),
            Tab(text: 'الأعياد المتحركة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPrayersList(_tasbehaParts, 'تسبحة نصف الليل والإبصلمودية المقدسة'),
          _buildPrayersList(_paschaParts, 'صلوات وألحان أسبوع الآلام والبصخة المقدسة'),
          _buildMovableFeastsTab(movableFeasts),
        ],
      ),
    );
  }

  Widget _buildPrayersList(List<Map<String, String>> list, String header) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
      itemCount: list.length + 1,
      itemBuilder: (context, idx) {
        if (idx == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF281E12), Color(0xFF151412)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryGold),
            ),
            child: Row(
              children: [
                const CopticCross(size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    header,
                    style: GoogleFonts.cairo(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGoldLight,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        final item = list[idx - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardNavy,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                item['title']!,
                style: GoogleFonts.cairo(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGoldLight,
                ),
              ),
              const SizedBox(height: 10),
              SelectableText(
                item['arabic']!,
                style: GoogleFonts.cairo(fontSize: 14.5, height: 1.7, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F222F),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'قبطي معرب:',
                      style: GoogleFonts.cairo(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primaryGold),
                    ),
                    SelectableText(
                      item['arabized']!,
                      style: GoogleFonts.cairo(fontSize: 13, height: 1.6, color: AppColors.primaryGoldLight),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                item['coptic']!,
                style: const TextStyle(
                  fontFamily: 'Coptic',
                  fontSize: 14,
                  height: 1.5,
                  color: Color(0xFFB0BEC5),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static const List<String> _arDays = [
    'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
  ];
  static const List<String> _arMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  String _formatArabicDate(DateTime dt) {
    final dayName = _arDays[(dt.weekday - 1).clamp(0, 6)];
    final monthName = _arMonths[(dt.month - 1).clamp(0, 11)];
    return '$dayName، ${dt.day} $monthName ${dt.year}';
  }

  Widget _buildMovableFeastsTab(List<Map<String, dynamic>> feasts) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardNavy,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.45)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(() => _selectedYear--),
                icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryGold),
              ),
              Column(
                children: [
                  Text(
                    'حاسبة الأعياد والأصوام القبطية',
                    style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted),
                  ),
                  Text(
                    'سنة $_selectedYear ميلادية',
                    style: GoogleFonts.cairo(
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGoldLight,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => setState(() => _selectedYear++),
                icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primaryGold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...feasts.map((f) {
          final dt = f['date'] as DateTime;
          final coptic = CopticCalendarService.fromGregorian(dt);
          final isMajor = f['type'] == 'major_feast';
          final isFast = f['type'] == 'fast';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isMajor ? const Color(0xFF281F12) : AppColors.cardNavy,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isMajor
                    ? AppColors.primaryGold
                    : (isFast ? Colors.deepPurpleAccent.withValues(alpha: 0.4) : Colors.white12),
                width: isMajor ? 1.4 : 0.9,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isMajor
                      ? Icons.auto_awesome_rounded
                      : (isFast ? Icons.nights_stay_rounded : Icons.church_rounded),
                  color: isMajor ? AppColors.primaryGold : AppColors.primaryGoldLight,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${f['name']}',
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isMajor ? AppColors.primaryGoldLight : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatArabicDate(dt),
                        style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textLight),
                      ),
                      Text(
                        'الموافق قبطياً: ${coptic.formatted}',
                        style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.primaryGold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
