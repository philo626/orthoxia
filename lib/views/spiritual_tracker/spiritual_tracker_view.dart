import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/spiritual_tracker_provider.dart';

class SpiritualTrackerView extends StatelessWidget {
  const SpiritualTrackerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SpiritualTrackerProvider>(
      builder: (context, trackerProv, _) {
        final today = trackerProv.todayLog;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'مُتتبع الجهاد الروحي الشخصي',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Encouragement Verse Card (Non-judgmental)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.sacredBurgundyDark, AppColors.cardNavy],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryGold.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.favorite_rounded, color: AppColors.primaryGold, size: 28),
                      const SizedBox(height: 10),
                      Text(
                        trackerProv.encouragingVerse,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'الجهاد الروحي مسيرة نعمة ونمو هادئ في محبة الفادي',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.primaryGoldLight,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  'أعمال اليوم الروحية',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGold,
                  ),
                ),
                const SizedBox(height: 12),

                // Grid of Daily Counters
                Row(
                  children: [
                    // Bible Chapters
                    Expanded(
                      child: _buildCounterTile(
                        title: 'أصحاحات الإنجيل',
                        count: '${today.bibleChaptersRead}',
                        unit: 'أصحاح',
                        icon: Icons.menu_book_rounded,
                        color: AppColors.prayerBlue,
                        onIncrement: () => trackerProv.incrementBibleChapters(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Agpeya Prayers
                    Expanded(
                      child: _buildCounterTile(
                        title: 'صلوات الأجبية',
                        count: '${today.agpeyaHoursCompleted} / 7',
                        unit: 'صلاة',
                        icon: Icons.access_time_filled_rounded,
                        color: AppColors.primaryGold,
                        onIncrement: () => trackerProv.incrementAgpeyaHours(),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    // Secret Prayer Minutes
                    Expanded(
                      child: _buildCounterTile(
                        title: 'الصلاة السرية',
                        count: '${today.personalPrayerMinutes}',
                        unit: 'دقيقة',
                        icon: Icons.self_improvement_rounded,
                        color: AppColors.fastingPurple,
                        onIncrement: () => trackerProv.addPersonalPrayerMinutes(5),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Communion & Charity toggles
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardNavy,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Column(
                          children: [
                            // Communion
                            InkWell(
                              onTap: () => trackerProv.toggleCommunion(),
                              child: Row(
                                children: [
                                  Icon(
                                    today.tookCommunion
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    color: today.tookCommunion
                                        ? AppColors.primaryGold
                                        : AppColors.textMuted,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'التناول المقدس',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 16),
                            // Charity
                            InkWell(
                              onTap: () => trackerProv.toggleCharity(),
                              child: Row(
                                children: [
                                  Icon(
                                    today.actsOfCharity
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked_rounded,
                                    color: today.actsOfCharity
                                        ? AppColors.successGreen
                                        : AppColors.textMuted,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'أعمال المحبة',
                                      style: GoogleFonts.cairo(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Weekly Growth Chart
                Text(
                  'مؤشر الثبات والاستمرار الأسبوعي',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'يهدف لمراقبة نموك الروحي بهدوء دون مقارنة أو إدانة',
                  style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),

                Container(
                  height: 180,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
                  decoration: BoxDecoration(
                    color: AppColors.cardNavy,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 6,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              const days = ['أحد', 'إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت'];
                              final dayIdx = val.toInt() % days.length;
                              return Text(
                                days[dayIdx],
                                style: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 10),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(7, (i) {
                        final val = (i == 6 ? (today.bibleChaptersRead + today.agpeyaHoursCompleted) : (i * 2 % 5 + 1)).toDouble();
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: val.clamp(0.5, 6.0),
                              color: i == 6 ? AppColors.primaryGold : AppColors.primaryGold.withOpacity(0.4),
                              width: 14,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCounterTile({
    required String title,
    required String count,
    required String unit,
    required IconData icon,
    required Color color,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              IconButton(
                icon: const Icon(Icons.add_circle_rounded, size: 26),
                color: color,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onIncrement,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            '$count $unit',
            style: GoogleFonts.cairo(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
