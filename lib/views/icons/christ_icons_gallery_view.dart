import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class ChristIconItem {
  final String id;
  final String title;
  final String copticTitle;
  final String imagePath;
  final String verse;
  final String verseReference;
  final String contemplation;
  final String prayer;

  const ChristIconItem({
    required this.id,
    required this.title,
    required this.copticTitle,
    required this.imagePath,
    required this.verse,
    required this.verseReference,
    required this.contemplation,
    required this.prayer,
  });
}

class ChristIconsGalleryView extends StatefulWidget {
  final int initialIndex;

  const ChristIconsGalleryView({super.key, this.initialIndex = 0});

  static const List<ChristIconItem> icons = [
    ChristIconItem(
      id: 'pantocrator',
      title: 'أيقونة المسيح ضابط الكل',
      copticTitle: 'Ⲡⲓπαντοκράτωρ • Pantocrator',
      imagePath: 'assets/images/christ_pantocrator.jpg',
      verse: '«أَنَا هُوَ نُورُ الْعَالَمِ. مَنْ يَتْبَعْنِي فَلاَ يَمْشِي فِي الظُّلْمَةِ بَلْ يَكُونُ لَهُ نُورُ الْحَيَاةِ»',
      verseReference: 'يوحنا ٨: ١٢',
      contemplation:
          'في الفن القبطي الأصيل، يتجلى الرب يسوع المسيح ضابط الكل يبارك بيمينه حاملاً إنجيل الحياة الأبدية بيساره. الهالة الذهبية المصلبة تشير إلى لاهوته الأزلي وذبيحته الخلاصية، والنظرة الهادئة المملوءة مراحم تدعو النفس للتوبة والسلام الداخلي.',
      prayer:
          'أيها الرب يسوع المسيح ضابط الكل، نور العالم الحقيقي، أشرق في قلبي بنور معرفتك الإلهية، وبارك حياتي بيمينك المقدسة، واحفظني في وصايا إنجيلك المحيي كل أيام حياتي. آمين.',
    ),
    ChristIconItem(
      id: 'good_shepherd',
      title: 'أيقونة المسيح الراعي الصالح',
      copticTitle: 'Ⲡⲓⲙⲁⲛⲉⲥⲱⲟⲩ Ⲛ̀ⲁⲅⲁⲑⲟⲥ • The Good Shepherd',
      imagePath: 'assets/images/christ_good_shepherd.jpg',
      verse: '«أَنَا هُوَ الرَّاعِي الصَّالِحُ، وَالرَّاعِي الصَّالِحُ يَبْذِلُ نَفْسَهُ عَنِ الْخِرَافِ»',
      verseReference: 'يوحنا ١٠: ١١',
      contemplation:
          'أيقونة الراعي الصالح تجسد محبة المسيح الفائقة التي سعت وراء الخروف الضال وحملته على منكبيه بفرح. مهما ثقلت خطايانا أو ابتعدنا، فإن ذراعي الفادي مفتوحتان دائماً ليرد نفوسنا إلى فردوس الفرح والسلام.',
      prayer:
          'يا راعي نفسي الصالح، يا من خرجت تبحث عني وحملتني على منكبيك المقدسين، لا تتركني أضل عن رعيتك، بل قدني إلى مراعٍ خضراء ومياه الراحة، واشفِ جراحات نفسي بنعمتك. آمين.',
    ),
    ChristIconItem(
      id: 'resurrection',
      title: 'أيقونة القيامة المجيدة',
      copticTitle: 'Ϯⲁⲛⲁⲥⲧⲁⲥⲓⲥ • The Holy Resurrection',
      imagePath: 'assets/images/christ_resurrection.jpg',
      verse: '«أَنَا هُوَ الْقِيَامَةُ وَالْحَيَاةُ. مَنْ آمَنَ بِي وَلَوْ مَاتَ فَسَيَحْيَا»',
      verseReference: 'يوحنا ١١: ٢٥',
      contemplation:
          'تُظهر أيقونة القيامة القبطية السيد المسيح القائم من بين الأموات بثوب النور الإلهي الساطع، حاملاً راية الصليب، محطماً أبواب الجحيم ومُقيماً آدم وحواء وكل البشرية معه من الظلمة إلى نور الملكوت.',
      prayer:
          'المسيح قام من بين الأموات، بالموت داس الموت، والذين في القبور أنعم لهم بالحياة الأبدية. أقم يا رب نفسي من فتورها واملأ قلبي بقوة قيامتك المحيية. آمين.',
    ),
  ];

  @override
  State<ChristIconsGalleryView> createState() => _ChristIconsGalleryViewState();
}

class _ChristIconsGalleryViewState extends State<ChristIconsGalleryView>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  final Set<String> _litCandles = {'pantocrator'};
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex, viewportFraction: 0.88);
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _toggleCandle(String id) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_litCandles.contains(id)) {
        _litCandles.remove(id);
      } else {
        _litCandles.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIcon = ChristIconsGalleryView.icons[_currentIndex];
    final isCandleLit = _litCandles.contains(currentIcon.id);

    return Scaffold(
      backgroundColor: const Color(0xFF070A12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('☦', style: TextStyle(color: AppColors.primaryGold, fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              'مقصورة أيقونات السيد المسيح',
              style: GoogleFonts.amiri(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGoldLight,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 36),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Ornate Icon Carousel
            SizedBox(
              height: 410,
              child: PageView.builder(
                controller: _pageController,
                itemCount: ChristIconsGalleryView.icons.length,
                onPageChanged: (idx) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentIndex = idx);
                },
                itemBuilder: (context, index) {
                  final item = ChristIconsGalleryView.icons[index];
                  final isSelected = index == _currentIndex;
                  final candleOn = _litCandles.contains(item.id);

                  return AnimatedScale(
                    scale: isSelected ? 1.0 : 0.92,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    child: AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, child) {
                        final glow = candleOn ? (0.25 + 0.25 * _glowController.value) : 0.08;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: AppColors.primaryGold.withValues(alpha: candleOn ? 0.9 : 0.45),
                              width: candleOn ? 2.5 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryGold.withValues(alpha: glow),
                                blurRadius: candleOn ? 32 : 12,
                                spreadRadius: candleOn ? 4 : 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  item.imagePath,
                                  fit: BoxFit.cover,
                                ),
                                // Subtle warm vignette overlay
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withValues(alpha: 0.85),
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.35),
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      stops: const [0.0, 0.55, 1.0],
                                    ),
                                  ),
                                ),
                                // Top Coptic Title Ribbon
                                Positioned(
                                  top: 14,
                                  right: 14,
                                  left: 14,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.65),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: AppColors.primaryGold.withValues(alpha: 0.5),
                                          ),
                                        ),
                                        child: Text(
                                          item.copticTitle,
                                          style: GoogleFonts.cairo(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryGoldLight,
                                          ),
                                        ),
                                      ),
                                      if (candleOn)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(color: Colors.amber),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.local_fire_department_rounded,
                                                  color: Colors.amber, size: 15),
                                              const SizedBox(width: 4),
                                              Text(
                                                'قنديل مضاء',
                                                style: GoogleFonts.cairo(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.amberAccent,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Bottom Title & Verse inside Icon Frame
                                Positioned(
                                  bottom: 18,
                                  right: 18,
                                  left: 18,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: GoogleFonts.amiri(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryGoldLight,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.verse,
                                        style: GoogleFonts.amiri(
                                          fontSize: 16,
                                          color: Colors.white,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '— ${item.verseReference}',
                                        style: GoogleFonts.cairo(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryGold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Interactive Candle Lighting & Copy Verse Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCandleLit
                            ? AppColors.primaryGold
                            : const Color(0xFF161F33),
                        foregroundColor: isCandleLit ? Colors.black : AppColors.primaryGoldLight,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.primaryGold, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _toggleCandle(currentIcon.id),
                      icon: Icon(
                        isCandleLit
                            ? Icons.local_fire_department_rounded
                            : Icons.lightbulb_outline_rounded,
                        size: 20,
                      ),
                      label: Text(
                        isCandleLit ? 'قنديل الصلاة مضاء أمام الأيقونة' : 'أضئ قنديلاً أمام الأيقونة',
                        style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF161F33),
                      side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.all(12),
                    ),
                    tooltip: 'نسخ الآية والصلاة',
                    icon: const Icon(Icons.copy_rounded, color: AppColors.primaryGold, size: 20),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              '${currentIcon.title}\n${currentIcon.verse} (${currentIcon.verseReference})\n\nصلاة: ${currentIcon.prayer}',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم نسخ الآية والصلاة لمشاركتها', style: GoogleFonts.cairo()),
                          backgroundColor: AppColors.cardNavy,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Contemplation & Prayer Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryGold, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'تأمل روحي في الأيقونة القبطية',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      currentIcon.contemplation,
                      style: GoogleFonts.cairo(
                        fontSize: 13.5,
                        color: AppColors.textLight.withValues(alpha: 0.92),
                        height: 1.7,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(color: Colors.white12),
                    ),
                    Row(
                      children: [
                        const Text('☦', style: TextStyle(color: AppColors.primaryGold, fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          'صلاة أمام الأيقونة',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGoldLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentIcon.prayer,
                      style: GoogleFonts.amiri(
                        fontSize: 18,
                        color: Colors.white,
                        height: 1.65,
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
