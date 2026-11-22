import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/coptic_calendar_service.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../providers/theme_provider.dart';

/// Pure Day-by-Day Coptic Orthodox Synaxarium ("اليوم بيومه").
/// Automatically displays today's exact liturgical commemorations and rolls over
/// at 5:00 PM (Vespers / عشية) to the next Coptic liturgical day.
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
    _isVespersNextDay =
        widget.initialMonth == null && CopticCalendarService.isAfterVespers(now);
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
    final p = context.palette;
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
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'السنكسار القبطي اليومي',
          style: GoogleFonts.amiri(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: p.ink,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'مشاركة سنكسار اليوم',
            icon: Icon(Icons.share_outlined, color: p.accent, size: 20),
            onPressed: () {
              SharePlus.instance.share(
                ShareParams(
                  text:
                      'السنكسار القبطي (${_activeDate.formatted})\n\n$fullText\n\nمن تطبيق أرثوذكسيا',
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: p.accent, strokeWidth: 2),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 44),
              children: [
                // 1. Dignified Liturgical Date Header
                Container(
                  padding: const EdgeInsets.all(18),
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
                          CopticCross(size: 22, color: p.accent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'اليوم ${_activeDate.day} من شهر ${_activeDate.monthName} ${_activeDate.year} ش',
                                  style: GoogleFonts.amiri(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w700,
                                    color: p.ink,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_activeDate.seasonName} • ${_activeDate.fastingNote}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    color: p.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: p.surfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: p.border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isVespersNextDay
                                  ? Icons.nights_stay_outlined
                                  : Icons.schedule_outlined,
                              size: 15,
                              color: p.accent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _isVespersNextDay
                                    ? 'تذكار اليوم التالي تلقائياً حسب توقيت عشية (بعد الخامسة مساءً)'
                                    : 'يُعرض سنكسار اليوم تلقائياً وينتقل لليوم التالي عند الساعة ٥:٠٠ مساءً (عشية)',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: p.inkMuted,
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
                            label:
                                'سنكسار ${_activeDate.day} ${_activeDate.monthName}',
                            playText: 'استماع لسنكسار اليوم',
                            stopText: 'إيقاف الصوت',
                            compact: true,
                          ),
                          const Spacer(),
                          Text(
                            '${events.length} تذكار اليوم',
                            style: GoogleFonts.cairo(
                              fontSize: 11.5,
                              color: p.accent,
                              fontWeight: FontWeight.w700,
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    'بِاسْمِ الآبِ وَالابْنِ وَالرُّوحِ الْقُدُسِ الإِلَهِ الْوَاحِدِ آمِينَ. '
                    'اليَوْمُ ${_activeDate.day} مِنْ شَهْرِ ${_activeDate.monthName} الْمُبَارَكِ، '
                    'أَحْسَنَ اللهُ انْقِضَاءَهُ وَأَعَادَهُ عَلَيْنَا وَعَلَيْكُمْ وَنَحْنُ فِي هُدُوءٍ وَاطْمِئْنَانٍ مَغْفُورِي الْخَطَايَا وَالآثَامِ:',
                    style: GoogleFonts.amiri(
                      fontSize: 17.5 * fontScale,
                      height: 1.75,
                      color: p.crimson,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                for (int i = 0; i < events.length; i++) ...[
                  _buildEventBlock(p, events[i], i + 1, fontScale),
                  const SizedBox(height: 14),
                ],

                // 4. Concluding Liturgical Blessing
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: p.accentSoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.accent.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'بَرَكَةُ صَلَوَاتِهِمْ وَشَفَاعَتِهِمْ فَلْتَكُنْ مَعَنَا جَمِيعاً، وَلِرَبِّنَا الْمَجْدُ دَائِماً أَبَدِيّاً آمِينَ.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(
                      fontSize: 18 * fontScale,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildEventBlock(
    AppPalette p,
    Map<String, dynamic> ev,
    int number,
    double fontScale,
  ) {
    final title = '${ev['title'] ?? ''}'.trim();
    final body = '${ev['text'] ?? ''}'.trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
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
                  color: p.accentSoft,
                  border: Border.all(color: p.accent.withValues(alpha: 0.45)),
                ),
                child: Text(
                  '$number',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: p.accent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.amiri(
                    fontSize: 20 * fontScale,
                    fontWeight: FontWeight.w700,
                    color: p.accent,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: p.border, height: 1),
          const SizedBox(height: 12),
          SelectableText(
            body,
            style: GoogleFonts.amiri(
              fontSize: 18.5 * fontScale,
              height: 1.9,
              color: p.ink,
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
                icon: Icon(Icons.copy_rounded, size: 17, color: p.inkMuted),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: '$title\n\n$body'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم نسخ السيرة',
                          style: GoogleFonts.cairo(fontSize: 12)),
                    ),
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
