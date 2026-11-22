import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/security_guard_service.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/spiritual_tracker_provider.dart';

class SpiritualTrackerView extends StatefulWidget {
  const SpiritualTrackerView({super.key});

  @override
  State<SpiritualTrackerView> createState() => _SpiritualTrackerViewState();
}

class _SpiritualTrackerViewState extends State<SpiritualTrackerView> {
  static const List<String> _arabicWeekdays = [
    'إثنين',
    'ثلاثاء',
    'أربعاء',
    'خميس',
    'جمعة',
    'سبت',
    'أحد',
  ];

  @override
  void initState() {
    super.initState();
    SecurityGuardService().setSecureScreen(true);
  }

  @override
  void dispose() {
    SecurityGuardService().setSecureScreen(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Consumer<SpiritualTrackerProvider>(
      builder: (context, trackerProv, _) {
        final today = trackerProv.todayLog;
        final weekLogs = trackerProv.last7DaysLogs;
        final streak = trackerProv.activeStreakDays;

        // Calculate realistic Y axis max from actual recorded values
        double maxActivity = 6.0;
        for (final l in weekLogs) {
          final score = (l.bibleChaptersRead + l.agpeyaHoursCompleted).toDouble();
          if (score > maxActivity) maxActivity = score + 1;
        }
        final hasAnyWeekData = weekLogs.any(
          (l) => l.bibleChaptersRead > 0 || l.agpeyaHoursCompleted > 0,
        );

        return Scaffold(
          backgroundColor: p.background,
          appBar: AppBar(
            backgroundColor: p.background,
            elevation: 0,
            title: Text(
              'مُتتبع الجهاد الروحي',
              style: GoogleFonts.amiri(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                color: p.ink,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Encouragement Verse Card (Non-judgmental, calm parchment aesthetic)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: p.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: p.accent.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.auto_stories_rounded,
                          color: p.accent, size: 24),
                      const SizedBox(height: 10),
                      Text(
                        trackerProv.encouragingVerse,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: p.ink,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        streak > 0
                            ? 'أيام المواظبة المتواصلة: $streak ${streak == 1 ? "يوم" : "أيام"} • مسيرة نعمة هادئة'
                            : 'الجهاد الروحي مسيرة نعمة ونمو هادئ في محبة الفادي',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          color: p.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                Text(
                  'أعمال اليوم الروحية',
                  style: GoogleFonts.cairo(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: p.accent,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: _buildCounterTile(
                        p: p,
                        title: 'أصحاحات الإنجيل',
                        count: '${today.bibleChaptersRead}',
                        unit: 'أصحاح',
                        icon: Icons.menu_book_rounded,
                        accentColor: p.accent,
                        onIncrement: () {
                          HapticFeedback.lightImpact();
                          trackerProv.incrementBibleChapters();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCounterTile(
                        p: p,
                        title: 'صلوات الأجبية',
                        count: '${today.agpeyaHoursCompleted} / 7',
                        unit: 'صلاة',
                        icon: Icons.access_time_filled_rounded,
                        accentColor: p.crimson,
                        onIncrement: () {
                          HapticFeedback.lightImpact();
                          trackerProv.incrementAgpeyaHours();
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildCounterTile(
                        p: p,
                        title: 'الصلاة السرية',
                        count: '${today.personalPrayerMinutes}',
                        unit: 'دقيقة',
                        icon: Icons.self_improvement_rounded,
                        accentColor: p.accent,
                        onIncrement: () {
                          HapticFeedback.lightImpact();
                          trackerProv.addPersonalPrayerMinutes(5);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: p.surfaceElevated,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: p.border),
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                trackerProv.toggleCommunion();
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      today.tookCommunion
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked_rounded,
                                      color: today.tookCommunion
                                          ? p.accent
                                          : p.inkSubtle,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'التناول المقدس',
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: p.ink,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Divider(color: p.border, height: 18),
                            InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                trackerProv.toggleCharity();
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      today.actsOfCharity
                                          ? Icons.check_circle_rounded
                                          : Icons.radio_button_unchecked_rounded,
                                      color: today.actsOfCharity
                                          ? p.success
                                          : p.inkSubtle,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'أعمال المحبة',
                                        style: GoogleFonts.cairo(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: p.ink,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),

                // REAL Weekly Growth Chart (100% bound to user's actual logs)
                Text(
                  'سجل آخر ٧ أيام الفعلي',
                  style: GoogleFonts.cairo(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: p.accent,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasAnyWeekData
                      ? 'مجموع الأصحاحات وصلوات الأجبية المسجلة يومياً'
                      : 'ابدأ بتسجيل أول أصحاح أو صلاة أجبية اليوم ليظهر تقدمك الحقيقي هنا',
                  style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkMuted),
                ),
                const SizedBox(height: 12),

                Container(
                  height: 195,
                  padding: const EdgeInsets.fromLTRB(14, 20, 14, 10),
                  decoration: BoxDecoration(
                    color: p.surfaceElevated,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: p.border),
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxActivity,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val, meta) {
                              final idx = val.toInt();
                              if (idx < 0 || idx >= weekLogs.length) {
                                return const SizedBox.shrink();
                              }
                              final parsed =
                                  DateTime.tryParse(weekLogs[idx].date) ??
                                      DateTime.now();
                              final label = idx == 6
                                  ? 'اليوم'
                                  : _arabicWeekdays[parsed.weekday - 1];
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  label,
                                  style: GoogleFonts.cairo(
                                    color: idx == 6 ? p.accent : p.inkMuted,
                                    fontWeight: idx == 6
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 2,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: p.border, strokeWidth: 0.7),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(weekLogs.length, (i) {
                        final log = weekLogs[i];
                        final realVal =
                            (log.bibleChaptersRead + log.agpeyaHoursCompleted)
                                .toDouble();
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: realVal,
                              color: i == 6
                                  ? p.accent
                                  : p.accent.withValues(alpha: 0.45),
                              width: 16,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxActivity,
                                color: p.surfaceMuted,
                              ),
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
    required AppPalette p,
    required String title,
    required String count,
    required String unit,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: accentColor, size: 22),
              IconButton(
                icon: const Icon(Icons.add_circle_rounded, size: 26),
                color: accentColor,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onIncrement,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.cairo(fontSize: 12, color: p.inkMuted),
          ),
          const SizedBox(height: 2),
          Text(
            '$count $unit',
            style: GoogleFonts.cairo(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: p.ink,
            ),
          ),
        ],
      ),
    );
  }
}
