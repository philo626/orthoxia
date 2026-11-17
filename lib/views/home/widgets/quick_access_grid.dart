import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../bible/bible_explorer_view.dart';
import '../../liturgies/liturgies_hub_view.dart';
import '../../synaxarium/synaxarium_daily_view.dart';

class QuickAccessGrid extends StatelessWidget {
  final Function(int tabIndex) onNavigateTab;
  final VoidCallback onOpenConscience;
  final VoidCallback onOpenTracker;
  final VoidCallback onOpenBooks;

  const QuickAccessGrid({
    super.key,
    required this.onNavigateTab,
    required this.onOpenConscience,
    required this.onOpenTracker,
    required this.onOpenBooks,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'title': 'الكتاب المقدس',
        'icon': Icons.menu_book_rounded,
        'color': AppColors.primaryGold,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BibleExplorerView()),
          );
        },
      },
      {
        'title': 'القداسات',
        'icon': Icons.church_rounded,
        'color': const Color(0xFFE57373),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LiturgiesHubView()),
          );
        },
      },
      {
        'title': 'السنكسار',
        'icon': Icons.calendar_month_rounded,
        'color': AppColors.primaryGoldLight,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SynaxariumDailyView()),
          );
        },
      },
      {
        'title': 'الكتب والتفاسير',
        'icon': Icons.library_books_rounded,
        'color': AppColors.primaryGoldLight,
        'onTap': onOpenBooks,
      },
      {
        'title': 'الألحان',
        'icon': Icons.music_note_rounded,
        'color': AppColors.prayerBlue,
        'onTap': () => onNavigateTab(1), // Liturgical tab
      },
      {
        'title': 'فحص الضمير',
        'icon': Icons.shield_moon_rounded,
        'color': AppColors.sacredBurgundy,
        'onTap': onOpenConscience,
      },
      {
        'title': 'المساعد الآبائي',
        'icon': Icons.auto_awesome_rounded,
        'color': AppColors.primaryGold,
        'onTap': () => onNavigateTab(3), // AI Tab
      },
      {
        'title': 'حائط الصلوات',
        'icon': Icons.volunteer_activism_rounded,
        'color': AppColors.successGreen,
        'onTap': () => onNavigateTab(2), // Community Tab
      },
      {
        'title': 'الجهاد الروحي',
        'icon': Icons.insights_rounded,
        'color': AppColors.primaryGoldLight,
        'onTap': onOpenTracker,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الوصول السريع',
          style: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final item = items[index];
              final color = item['color'] as Color;
              return GestureDetector(
                onTap: item['onTap'] as VoidCallback,
                child: SizedBox(
                  width: 76,
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.14),
                          border: Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.15),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: color,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['title'] as String,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
