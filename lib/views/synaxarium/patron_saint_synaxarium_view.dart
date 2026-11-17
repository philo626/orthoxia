import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/coptic_calendar_service.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';

class PatronSaintItem {
  final String name;
  final String title;
  final String copticHiten;
  final String arabizedHiten;
  final String arabicHiten;
  final String virtue;
  final String promiseVerse;

  const PatronSaintItem({
    required this.name,
    required this.title,
    required this.copticHiten,
    required this.arabizedHiten,
    required this.arabicHiten,
    required this.virtue,
    required this.promiseVerse,
  });
}

class PatronSaintSynaxariumView extends StatefulWidget {
  const PatronSaintSynaxariumView({super.key});

  static const List<PatronSaintItem> saints = [
    PatronSaintItem(
      name: 'القديسة العذراء مريم (ثيؤطوكوس)',
      title: 'أم النور وفخر جنسنا والشفيعة الأمينة',
      copticHiten: 'Ϩⲓⲧⲉⲛ ⲛⲓⲡ̀ⲣⲉⲥⲃⲓⲁ ⲛ̀ⲧⲉ ϯⲑⲉⲟ̀ⲧⲟⲕⲟⲥ ⲉⲑⲟⲩⲁⲃ Ⲙⲁⲣⲓⲁ: Ⲡ̀ϭⲟⲓⲥ ⲁ̀ⲣⲓϩ̀ⲙⲟⲧ ⲛⲁⲛ ⲙ̀ⲡⲓⲭⲱ ⲉ̀ⲃⲟⲗ ⲛ̀ⲧⲉ ⲛⲉⲛⲛⲟⲃⲓ.',
      arabizedHiten: 'هيتين ني إبريسفيا إنتي تي ثيؤطوكوس إثؤواب ماريا: إبشويس آري إهموت نان إمبي كو إيفول إنتي نين نوفي.',
      arabicHiten: 'بشفاعات والدة الإله القديسة مريم، يا رب أنعم لنا بمغفرة خطايانا.',
      virtue: 'فضيلة اليوم: الاتضاع الهادئ والتسليم الكامل لمشيئة الله («هوذا أنا أمة الرب»).',
      promiseVerse: '«طُوبَى لِلَّتِي آمَنَتْ أَنْ يَتِمَّ مَا قِيلَ لَهَا مِنْ قِبَلِ الرَّبِّ» (لو ١: ٤٥)',
    ),
    PatronSaintItem(
      name: 'الشهيد العظيم مارجرجس الروماني',
      title: 'أمير الشهداء وكوكب الصبح المنير',
      copticHiten: 'Ϩⲓⲧⲉⲛ ⲛⲓⲉⲩⲭⲏ ⲛ̀ⲧⲉ ⲡⲓⲁⲑⲗⲟⲫⲟⲣⲟⲥ ⲙ̀ⲙⲁⲣⲧⲩⲣⲟⲥ ⲡⲁϭⲟⲓⲥ ⲡ̀ⲟⲩⲣⲟ ⲅⲉⲱⲣⲅⲓⲟⲥ.',
      arabizedHiten: 'هيتين ني إفشي إنتي بي أثلُوفوروس إممارتيروس باشويس إبؤرو جيؤرجيوس.',
      arabicHiten: 'بصلوات المجاهد الشهيد سيدي الملك جاورجيوس، يا رب أنعم لنا بمغفرة خطايانا.',
      virtue: 'فضيلة اليوم: الشجاعة في الحق وعدم الخوف من الضيقات لأن الرب يسندك.',
      promiseVerse: '«تَشَدَّدْ وَتَشَجَّعْ! لاَ تَرْهَبْ وَلاَ تَرْتَعِبْ لأَنَّ الرَّبَّ إِلهَكَ مَعَكَ حَيْثُمَا تَذْهَبُ» (يش ١: ٩)',
    ),
    PatronSaintItem(
      name: 'الشهيد مارمينا العجائبي',
      title: 'الأمين في البرية وصانع العجائب',
      copticHiten: 'Ϩⲓⲧⲉⲛ ⲛⲓⲉⲩⲭⲏ ⲛ̀ⲧⲉ ⲡⲓⲙⲁⲣⲧⲩⲣⲟⲥ ⲁⲃⲃⲁ Ⲙⲏⲛⲁ ⲡⲓⲫⲁⲓϣⲉⲛⲛⲟⲩϥⲓ.',
      arabizedHiten: 'هيتين ني إفشي إنتي بي مارتيروس آفا مينا بي فاي شينوفي.',
      arabicHiten: 'بصلوات الشهيد القديس أبينا مينا الصفي، يا رب أنعم لنا بمغفرة خطايانا.',
      virtue: 'فضيلة اليوم: حب الخلوة الهادئة مع الله والثقة في استجابة الصلاة.',
      promiseVerse: '«ادْعُنِي فِي يَوْمِ الضِّيقِ أُنْقِذْكَ فَتُمَجِّدَنِي» (مز ٥٠: ١٥)',
    ),
    PatronSaintItem(
      name: 'القديس البابا كيرلس السادس',
      title: 'رجل الصلاة والقداسات اليومية',
      copticHiten: 'Ⲡⲉⲛⲓⲱⲧ ⲉⲑⲟⲩⲁⲃ ⲛ̀ⲇⲓⲕⲉⲟⲥ ⲁⲃⲃⲁ Ⲕⲩⲣⲓⲗⲗⲟⲥ ⲡⲓⲙⲁϩⲥⲟⲟⲩ.',
      arabizedHiten: 'بينيوت إثؤواب إنديكيؤس آفا كيرلس بي ماه سوؤو.',
      arabicHiten: 'أبونا القديس البار الأنبا كيرلس السادس، اطلب من الرب عنا.',
      virtue: 'فضيلة اليوم: «كن مطمئناً جداً جداً ولا تفكر في الأمر كثيراً، بل دع الأمر لمن بيده الأمر».',
      promiseVerse: '«أَلْقِ عَلَى الرَّبِّ هَمَّكَ فَهُوَ يَعُولُكَ» (مز ٥٥: ٢٢)',
    ),
    PatronSaintItem(
      name: 'القديس أثناسيوس الرسولي',
      title: 'الرسولي حامي الإيمان الأرثوذكسي (العشرين)',
      copticHiten: 'Ϩⲓⲧⲉⲛ ⲛⲓⲉⲩⲭⲏ ⲛ̀ⲧⲉ ⲡⲉⲛⲓⲱⲧ ⲉⲑⲟⲩⲁⲃ ⲁⲃⲃⲁ Ⲁⲑⲁⲛⲁⲥⲓⲟⲥ ⲡⲓⲁ̀ⲡⲟⲥⲧⲟⲗⲓⲕⲟⲥ.',
      arabizedHiten: 'هيتين ني إفشي إنتي بينيوت إثؤواب آفا أثناسيوس بي أبوستوليكوس.',
      arabicHiten: 'بصلوات أبينا القديس الأنبا أثناسيوس الرسولي، يا رب احفظ إيماننا.',
      virtue: 'فضيلة اليوم: الثبات في الإيمان المستقيم والتمسك بكلمة الحق مهما اشتدت العواصف.',
      promiseVerse: '«اسْهَرُوا، اثْبُتُوا فِي الإِيمَانِ، تَقَوَّوْا» (١ كو ١٦: ١٣)',
    ),
    PatronSaintItem(
      name: 'القوي الأنبا موسى الأسود',
      title: 'مثال التوبة الصادقة والوداعة والاتضاع',
      copticHiten: 'Ϩⲓⲧⲉⲛ ⲛⲓⲉⲩⲭⲏ ⲛ̀ⲧⲉ ⲡⲓϫⲱⲣⲓ ⲉⲑⲟⲩⲁⲃ ⲁⲃⲃⲁ Ⲙⲱⲩ̀ⲥⲏⲥ.',
      arabizedHiten: 'هيتين ني إفشي إنتي بي چوري إثؤواب آفا مويسيس.',
      arabicHiten: 'بصلوات القوي القديس الأنبا موسى، يا رب هبنا توبة صادقة.',
      virtue: 'فضيلة اليوم: عدم إدانة أحد مطلقاً وحمل خطاياي أمام عيني بالتوبة والرجاء.',
      promiseVerse: '«لاَ تَدِينُوا لِكَيْ لاَ تُدَانُوا» (مت ٧: ١)',
    ),
  ];

  @override
  State<PatronSaintSynaxariumView> createState() => _PatronSaintSynaxariumViewState();
}

class _PatronSaintSynaxariumViewState extends State<PatronSaintSynaxariumView>
    with SingleTickerProviderStateMixin {
  int _saintIdx = 0;
  bool _revealed = true;
  late int _selectedMonth;
  late int _selectedDay;

  static const List<String> _copticMonths = [
    'توت',
    'بابه',
    'هاتور',
    'كيهك',
    'طوبة',
    'أمشير',
    'برمهات',
    'برمودة',
    'بشنس',
    'بؤونة',
    'أبيب',
    'مسرى',
    'النسيء',
  ];

  @override
  void initState() {
    super.initState();
    final today = CopticCalendarService.fromGregorian(DateTime.now());
    _selectedMonth = today.month.clamp(1, 13);
    _selectedDay = today.day.clamp(1, 30);
    _saintIdx = DateTime.now().day % PatronSaintSynaxariumView.saints.length;
  }

  void _drawNewPatronSaint() {
    HapticFeedback.heavyImpact();
    setState(() {
      _revealed = false;
    });
    Future.delayed(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      setState(() {
        _saintIdx = (_saintIdx + 1 + math.Random().nextInt(PatronSaintSynaxariumView.saints.length - 1)) %
            PatronSaintSynaxariumView.saints.length;
        _revealed = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final saint = PatronSaintSynaxariumView.saints[_saintIdx];
    final synaxariumText = CopticCalendarService.getSynaxariumForDate(_selectedMonth, _selectedDay);
    final readings = CopticCalendarService.getDailyReadingsBlueprint(_selectedMonth, _selectedDay);

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LuxeCircleButton(
                    icon: Icons.share_rounded,
                    onTap: () {
                      Share.share(
                        '☦ شفيعي اليوم من تطبيق أرثوذكسيا:\n${saint.name} (${saint.title})\n\n${saint.arabicHiten}\n\n${saint.virtue}\n${saint.promiseVerse}',
                      );
                    },
                  ),
                  Text(
                    'شفيعك السماوي والسنكسار الحي',
                    style: GoogleFonts.cairo(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                  LuxeCircleButton(
                    icon: Icons.chevron_right_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 1. 3D Flipping Golden Patron Saint Card
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                transitionBuilder: (child, anim) {
                  final rotate = Tween(begin: math.pi / 2, end: 0.0).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
                  );
                  return AnimatedBuilder(
                    animation: rotate,
                    builder: (_, __) => Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(rotate.value),
                      child: child,
                    ),
                  );
                },
                child: _revealed
                    ? Container(
                        key: ValueKey(_saintIdx),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2B2215), Color(0xFF161513)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.primaryGold,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGold.withValues(alpha: 0.25),
                              blurRadius: 24,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: const SizedBox(
                                    width: 68,
                                    height: 68,
                                    child: SafeAssetImage(
                                      'assets/images/thumb_synaxarium.jpg',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGold.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'شفيعك السماوي ورسالة اليوم ☦',
                                          style: GoogleFonts.cairo(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryGoldLight,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        saint.name,
                                        style: GoogleFonts.amiri(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryGoldLight,
                                        ),
                                      ),
                                      Text(
                                        saint.title,
                                        style: GoogleFonts.cairo(
                                          fontSize: 11.5,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 22, color: Colors.white12),
                            Text(
                              saint.copticHiten,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.ltr,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGoldLight,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              saint.arabizedHiten,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: AppColors.textArabized,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              saint.arabicHiten,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.primaryGold.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    saint.virtue,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cairo(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGoldLight,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    saint.promiseVerse,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.amiri(
                                      fontSize: 16,
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            PressScale(
                              onTap: _drawNewPatronSaint,
                              child: Container(
                                height: 46,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: AppColors.champagne,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CopticCross(size: 18, color: Colors.black),
                                    const SizedBox(width: 8),
                                    Text(
                                      'اختَر شفيعاً آخر وبركة جديدة',
                                      style: GoogleFonts.cairo(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(height: 280),
              ),

              const SizedBox(height: 24),

              // 2. Automatic Daily Live Coptic Synaxarium (Updates automatically by Today's Date & Occasion)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'السنكسار اليومي التلقائي حسب تاريخ ومناسبة اليوم',
                    style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGoldLight,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'يتحدث تلقائياً يومياً',
                      style: GoogleFonts.cairo(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGoldLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Today's Live Synaxarium & Readings Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppColors.obsidianCard,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: AppColors.primaryGold.withValues(alpha: 0.35),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const CopticCross(size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'سنكسار اليوم: $_selectedDay ${_copticMonths[_selectedMonth - 1]}',
                                style: GoogleFonts.cairo(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGoldLight,
                                ),
                              ),
                              Text(
                                'المناسبة الكنسية الحالية: ${CopticCalendarService.getSeasonName(_selectedMonth, _selectedDay)}',
                                style: GoogleFonts.cairo(
                                  fontSize: 11.5,
                                  color: AppColors.primaryGold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: Colors.white12),
                    Text(
                      synaxariumText,
                      style: GoogleFonts.amiri(
                        fontSize: 19,
                        height: 1.85,
                        color: AppColors.textLight,
                      ),
                    ),
                    if (readings.isNotEmpty) ...[
                      const Divider(height: 24, color: Colors.white12),
                      Text(
                        'قراءات القطمارس لهذا اليوم القبطي:',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...readings.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ${r['title']}: ',
                                style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGoldLight,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  r['ref'] ?? '',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ).animate(key: ValueKey('$_selectedMonth-$_selectedDay')).fadeIn(duration: 260.ms),
            ],
          ),
        ),
      ),
    );
  }
}
