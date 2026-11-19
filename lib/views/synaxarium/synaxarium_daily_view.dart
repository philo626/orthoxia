import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/coptic_calendar_service.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../providers/theme_provider.dart';

/// Pure Day-by-Day Coptic Orthodox Synaxarium ("اليوم بيومه").
/// Automatically displays today's exact liturgical commemorations with NO manual date picking,
/// and rolls over automatically at 5:00 PM (Vespers / عشية) to the next Coptic liturgical day.
class SynaxariumDailyView extends StatefulWidget {
  final int? initialMonth;
  final int? initialDay;

  const SynaxariumDailyView({
    super.key,
    this.initialMonth,
    this.initialDay,
  });

  @override
  State<SynaxariumDailyView> createState() => _SynaxariumDailyViewState();
}

class _SynaxariumDailyViewState extends State<SynaxariumDailyView> {
  bool _isLoading = true;
  late CopticDate _activeDate;
  bool _isVespersNextDay = false;
  Timer? _clockWatcher;

  @override
  void initState() {
    super.initState();
    _syncLiturgicalClock();
    _loadData();
    // Auto-check every 30s so if 5:00 PM arrives while open, it transitions live to next day!
    _clockWatcher = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || widget.initialMonth != null) return;
      final latest = CopticCalendarService.todayLiturgical();
      if (latest.month != _activeDate.month || latest.day != _activeDate.day) {
        setState(() {
          _activeDate = latest;
          _isVespersNextDay = CopticCalendarService.isAfterVespers();
        });
      }
    });
  }

  void _syncLiturgicalClock() {
    final now = DateTime.now();
    final live = CopticCalendarService.todayLiturgical(now);
    _isVespersNextDay = widget.initialMonth == null && CopticCalendarService.isAfterVespers(now);
    if (widget.initialMonth != null && widget.initialDay != null) {
      final m = widget.initialMonth!.clamp(1, 13);
      final d = widget.initialDay!.clamp(1, m == 13 ? 6 : 30);
      _activeDate = CopticDate(
        day: d,
        month: m,
        year: live.year,
        monthName: CopticCalendarService.copticMonths[m - 1],
        seasonName: CopticCalendarService.getSeasonName(m, d),
        fastingNote: CopticCalendarService.getFastingNote(m, d, now.weekday),
      );
    } else {
      _activeDate = live;
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await CopticCalendarService.ensureLectionaryLoaded();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _clockWatcher?.cancel();
    SpeechPronunciationService().stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fontScale = context.watch<ThemeProvider>().fontScale;
    final events = CopticCalendarService.getSynaxariumEventsForDate(
      _activeDate.month,
      _activeDate.day,
    );
    final fullText = CopticCalendarService.getSynaxariumForDate(
      _activeDate.month,
      _activeDate.day,
    );

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'السنكسار القبطي اليومي',
          style: GoogleFonts.amiri(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppColors.primaryGoldLight,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'مشاركة سنكسار اليوم',
            icon: const Icon(Icons.share_outlined, color: AppColors.primaryGoldLight, size: 20),
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(
                  text: 'السنكسار القبطي (${_activeDate.formatted})\n\n$fullText\n\nمن تطبيق أرثوذكسيا',
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold, strokeWidth: 2),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 44),
              children: [
                // 1. Dignified Liturgical Date Header (No manual date pickers — Day-by-Day!)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.cardNavy,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primaryGold.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const CopticCross(size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'اليوم ${_activeDate.day} من شهر ${_activeDate.monthName} ${_activeDate.year} ش',
                                  style: GoogleFonts.amiri(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGoldLight,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_activeDate.seasonName} • ${_activeDate.fastingNote}',
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
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceNavy,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.hairline),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isVespersNextDay ? Icons.nights_stay_outlined : Icons.schedule_outlined,
                              size: 15,
                              color: AppColors.primaryGold,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isVespersNextDay
                                    ? 'تذكار اليوم التالي تلقائياً حسب توقيت عشية (بعد الخامسة مساءً)'
                                    : 'يُعرض سنكسار اليوم تلقائياً وينتقل لليوم التالي عند الساعة ٥:٠٠ مساءً (عشية)',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          SpeechPlayStopButton(
                            textToSpeak: fullText,
                            label: 'سنكسار ${_activeDate.day} ${_activeDate.monthName}',
                            playText: 'استماع لسنكسار اليوم كاملاً',
                            stopText: 'إيقاف الصوت',
                            compact: true,
                          ),
                          const Spacer(),
                          Text(
                            '${events.length} تذكار اليوم',
                            style: GoogleFonts.cairo(
                              fontSize: 11.5,
                              color: AppColors.primaryGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Traditional Liturgical Opening Formula
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    'بِاسْمِ الآبِ وَالابْنِ وَالرُّوحِ الْقُدُسِ الإِلَهِ الْوَاحِدِ آمِينَ. '
                    'اليَوْمُ ${_activeDate.day} مِنْ شَهْرِ ${_activeDate.monthName} الْمُبَارَكِ، '
                    'أَحْسَنَ اللهُ انْقِضَاءَهُ وَأَعَادَهُ عَلَيْنَا وَعَلَيْكُمْ وَنَحْنُ فِي هُدُوءٍ وَاطْمِئْنَانٍ مَغْفُورِي الْخَطَايَا وَالآثَامِ:',
                    style: GoogleFonts.amiri(
                      fontSize: 17.5 * fontScale,
                      height: 1.75,
                      color: AppColors.primaryGoldLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 3. Full Editorial Cards for Each Commemoration of Today
                for (int i = 0; i < events.length; i++) ...[
                  _buildEventBlock(events[i], i + 1, fontScale),
                  const SizedBox(height: 14),
                ],

                // 4. Concluding Liturgical Blessing
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceNavy,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    'بَرَكَةُ صَلَوَاتِهِمْ وَشَفَاعَتِهِمْ فَلْتَكُنْ مَعَنَا جَمِيعاً، وَلِرَبِّنَا الْمَجْدُ دَائِماً أَبَدِيّاً آمِينَ.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(
                      fontSize: 18 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGoldLight,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEventBlock(Map<String, dynamic> ev, int number, double fontScale) {
    final title = '${ev['title'] ?? ''}'.trim();
    final body = '${ev['text'] ?? ''}'.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceNavy,
                  border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.45)),
                ),
                child: Text(
                  '$number',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGoldLight,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.amiri(
                    fontSize: 20 * fontScale,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGoldLight,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.hairline, height: 1),
          const SizedBox(height: 12),
          SelectableText(
            body,
            style: GoogleFonts.amiri(
              fontSize: 18.5 * fontScale,
              height: 1.9,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SpeechPlayStopButton(
                textToSpeak: '$title. $body',
                label: title,
                playText: 'استماع',
                stopText: 'إيقاف الصوت',
                compact: true,
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'نسخ السيرة',
                icon: const Icon(Icons.copy_rounded, size: 17, color: AppColors.textMuted),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: '$title\n\n$body'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تم نسخ السيرة', style: GoogleFonts.cairo(fontSize: 12))),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
