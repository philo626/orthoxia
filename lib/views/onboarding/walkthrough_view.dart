import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import 'auth_view.dart';

class WalkthroughView extends StatefulWidget {
  const WalkthroughView({super.key});

  @override
  State<WalkthroughView> createState() => _WalkthroughViewState();
}

class _WalkthroughViewState extends State<WalkthroughView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'صلاتك معك في كل حين',
      'subtitle': 'الأجبية الذكية والقطمارس اليومي',
      'description': 'تطبيق تلقائي يفتح لك صلاة الساعة المناسبة لوقت يومك، مع قراءات القداس كاملة والسنكسار بدون إنترنت.',
      'icon': Icons.menu_book_rounded,
      'color': AppColors.primaryGold,
    },
    {
      'title': 'كنوز التراث والألحان',
      'subtitle': 'مكتبة كنسية كبرى بصوت المعلمين',
      'description': 'استمع لكبار المرتلين مع تزامن الكلمات باللغات الثلاث: القبطي الأصيل، المعرب، والترجمة العربية.',
      'icon': Icons.music_note_rounded,
      'color': AppColors.prayerBlue,
    },
    {
      'title': 'المساعد الآبائي الذكي',
      'subtitle': 'إجابات موثوقة بروح آباء الكنيسة',
      'description': 'رفيقك لدراسة الكتاب المقدس وأقوال الآباء القديسين المقيدة بتفاسير الكنيسة الأرثوذكسية النقية.',
      'icon': Icons.auto_awesome_rounded,
      'color': AppColors.sacredBurgundy,
    },
  ];

  void _finishWalkthrough() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'أرثوذكسيا',
                    style: GoogleFonts.cairo(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  TextButton(
                    onPressed: _finishWalkthrough,
                    child: Text(
                      'تخطي',
                      style: GoogleFonts.cairo(
                        color: AppColors.textMuted,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (page['color'] as Color).withOpacity(0.12),
                            border: Border.all(
                              color: (page['color'] as Color).withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            page['icon'] as IconData,
                            size: 64,
                            color: page['color'] as Color,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          page['title'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          page['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            color: AppColors.textLight.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page['description'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            color: AppColors.textMuted,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Indicators & Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot Indicators
                  Row(
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primaryGold
                              : AppColors.cardNavy,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // Continue / Start Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishWalkthrough();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _pages.length - 1 ? 'ابدأ الآن' : 'استمرار',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
