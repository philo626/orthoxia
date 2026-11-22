import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/coptic_calendar_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../models/katameros_model.dart';
import '../../providers/theme_provider.dart';
import '../synaxarium/synaxarium_daily_view.dart';

class KatamerosView extends StatefulWidget {
  final KatamerosDay katameros;
  final int initialTabIndex;

  const KatamerosView({
    super.key,
    required this.katameros,
    this.initialTabIndex = 0,
  });

  @override
  State<KatamerosView> createState() => _KatamerosViewState();
}

class _KatamerosViewState extends State<KatamerosView> {
  late int _activeEngine;
  List<dynamic> _sundaysMonths = [];
  List<dynamic> _greatLentWeeks = [];
  bool _isLoading = true;

  int _selectedSundayMonthIdx = 0;
  int _selectedSundayIdx = 0;

  int _selectedLentWeekIdx = 0;
  int _selectedLentDayIdx = 0;

  late int _selectedMonth;
  late int _selectedDay;
  String _selectedSynCategory = 'today';

  @override
  void initState() {
    super.initState();
    _activeEngine = widget.initialTabIndex.clamp(0, 2);
    final today = CopticCalendarService.todayLiturgical();
    _selectedMonth = today.month.clamp(1, 13);
    _selectedDay = today.day.clamp(1, 30);
    _selectedSundayMonthIdx = (_selectedMonth - 1).clamp(0, 12);
    _loadKatamerosComplete();
  }

  Future<void> _loadKatamerosComplete() async {
    try {
      await CopticCalendarService.ensureLectionaryLoaded();
      final raw =
          await rootBundle.loadString('assets/data/katameros_complete.json');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _sundaysMonths = data['sundays_katameros'] as List<dynamic>? ?? [];
      _greatLentWeeks = data['great_lent_katameros'] as List<dynamic>? ?? [];
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fontScale = context.watch<ThemeProvider>().fontScale;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: p.accent))
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: Row(
                      children: [
                        LuxeCircleButton(
                          icon: Icons.chevron_right_rounded,
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'القطمارس والسنكسار القبطي',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.amiri(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: p.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CopticCross(size: 22, color: p.accent),
                      ],
                    ),
                  ),

                  // 3-Engine Segmented Selector
                  Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: p.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: p.border),
                    ),
                    child: Row(
                      children: [
                        _buildEngineTab(p, 0, 'قطمارس الآحاد'),
                        _buildEngineTab(p, 1, 'قطمارس الصوم الكبير'),
                        _buildEngineTab(p, 2, 'السنوي والسنكسار'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  Expanded(
                    child: _activeEngine == 0
                        ? _buildSundaysKatamerosView(p, fontScale)
                        : (_activeEngine == 1
                            ? _buildGreatLentKatamerosView(p, fontScale)
                            : _buildAnnualAndCategorizedSynaxariumView(
                                p, fontScale)),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEngineTab(AppPalette p, int idx, String title) {
    final sel = _activeEngine == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activeEngine = idx);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: sel ? p.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: sel ? p.onAccent : p.ink,
            ),
          ),
        ),
      ),
    );
  }

  // ENGINE 1: قطمارس الآحاد
  Widget _buildSundaysKatamerosView(AppPalette p, double fontScale) {
    if (_sundaysMonths.isEmpty) {
      return Center(
        child: Text('جارٍ تحميل قراءات الآحاد...',
            style: GoogleFonts.cairo(color: p.inkMuted)),
      );
    }
    final safeMIdx =
        _selectedSundayMonthIdx.clamp(0, _sundaysMonths.length - 1);
    final monthData = _sundaysMonths[safeMIdx] as Map<String, dynamic>;
    final sundays = monthData['sundays'] as List<dynamic>? ?? [];
    final safeSIdx = _selectedSundayIdx.clamp(0, sundays.length - 1);
    final sundayData = sundays[safeSIdx] as Map<String, dynamic>;
    final readings = sundayData['readings'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
      children: [
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _sundaysMonths.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final m = _sundaysMonths[idx] as Map<String, dynamic>;
              final sel = idx == safeMIdx;
              return ChoiceChip(
                label: Text(
                  '${m['month_name']}',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: sel ? p.onAccent : p.ink,
                  ),
                ),
                selected: sel,
                selectedColor: p.accent,
                backgroundColor: p.surfaceElevated,
                showCheckmark: false,
                side: BorderSide(color: sel ? p.accent : p.border),
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedSundayMonthIdx = idx;
                    _selectedSundayIdx = 0;
                  });
                },
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(sundays.length, (sIdx) {
            final sel = sIdx == safeSIdx;
            const labels = [
              'الأحد الأول',
              'الأحد الثاني',
              'الأحد الثالث',
              'الأحد الرابع'
            ];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedSundayIdx = sIdx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? p.accent : p.surfaceElevated,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: sel ? p.accent : p.border),
                    ),
                    child: Text(
                      labels[sIdx % labels.length],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: sel ? p.onAccent : p.ink,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.accent.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CopticCross(size: 18, color: p.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${sundayData['title']} • القس أنطونيوس فكري',
                      style: GoogleFonts.cairo(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'محور الأحد: ${sundayData['theme']}',
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: p.accent,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${sundayData['father_commentary']}',
                style: GoogleFonts.cairo(
                  fontSize: 12.5 * fontScale,
                  height: 1.6,
                  color: p.inkMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...readings.map((r) {
          final item = r as Map<String, dynamic>;
          return _buildReadingCard(
            p: p,
            section: '${item['section']}',
            reference: '${item['ref']}',
            text: '${item['text']}',
            fontScale: fontScale,
          );
        }),
      ],
    );
  }

  // ENGINE 2: قطمارس الصوم الكبير وصوم يونان
  Widget _buildGreatLentKatamerosView(AppPalette p, double fontScale) {
    if (_greatLentWeeks.isEmpty) {
      return Center(
        child: Text('جارٍ تحميل قطمارس الصوم الكبير...',
            style: GoogleFonts.cairo(color: p.inkMuted)),
      );
    }
    final safeWIdx =
        _selectedLentWeekIdx.clamp(0, _greatLentWeeks.length - 1);
    final weekData = _greatLentWeeks[safeWIdx] as Map<String, dynamic>;
    final days = weekData['days'] as List<dynamic>? ?? [];
    final safeDIdx = _selectedLentDayIdx.clamp(0, days.length - 1);
    final dayData = days[safeDIdx] as Map<String, dynamic>;
    final readings = dayData['readings'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
      children: [
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _greatLentWeeks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final w = _greatLentWeeks[idx] as Map<String, dynamic>;
              final sel = idx == safeWIdx;
              return ChoiceChip(
                label: Text(
                  '${w['week_title']}',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: sel ? p.onAccent : p.ink,
                  ),
                ),
                selected: sel,
                selectedColor: p.accent,
                backgroundColor: p.surfaceElevated,
                showCheckmark: false,
                side: BorderSide(color: sel ? p.accent : p.border),
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _selectedLentWeekIdx = idx;
                    _selectedLentDayIdx = 0;
                  });
                },
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, dIdx) {
              final d = days[dIdx] as Map<String, dynamic>;
              final sel = dIdx == safeDIdx;
              return ChoiceChip(
                visualDensity: VisualDensity.compact,
                label: Text(
                  '${d['day_title']}',
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: sel ? p.onAccent : p.ink,
                  ),
                ),
                selected: sel,
                selectedColor: p.accent,
                backgroundColor: p.surfaceElevated,
                showCheckmark: false,
                side: BorderSide(color: sel ? p.accent : p.border),
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedLentDayIdx = dIdx);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.accent.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CopticCross(size: 18, color: p.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${dayData['day_title']}',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'قطمارس الصوم الكبير • دير الشهيد العظيم مارمينا بمريوط',
                style: GoogleFonts.cairo(
                  fontSize: 11.5,
                  color: p.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${dayData['contemplation']}',
                style: GoogleFonts.cairo(
                  fontSize: 12.5 * fontScale,
                  height: 1.55,
                  color: p.inkMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...readings.map((r) {
          final item = r as Map<String, dynamic>;
          return _buildReadingCard(
            p: p,
            section: '${item['section']}',
            reference: '${item['ref']}',
            text: '${item['text']}',
            fontScale: fontScale,
          );
        }),
      ],
    );
  }

  // ENGINE 3: السنوي والسنكسار اليومي
  Widget _buildAnnualAndCategorizedSynaxariumView(
      AppPalette p, double fontScale) {
    final copticToday = CopticCalendarService.todayLiturgical();
    final monthName =
        CopticCalendarService.copticMonths[(_selectedMonth - 1).clamp(0, 12)];
    final seasonName = copticToday.seasonName;
    final readingsBlueprint = CopticCalendarService.getDailyReadingsBlueprint(
        _selectedMonth, _selectedDay);
    final synItems = CopticCalendarService.getCategorizedSynaxariumItems(
      month: _selectedMonth,
      day: _selectedDay,
      category: _selectedSynCategory,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.accent.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              CopticCross(size: 22, color: p.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تاريخ اليوم القبطي: ${copticToday.formatted}',
                      style: GoogleFonts.amiri(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${copticToday.seasonName} • ${copticToday.fastingNote}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: p.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'أقسام السنكسار اليومي:',
              style: GoogleFonts.cairo(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: p.ink,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  luxeRoute(SynaxariumDailyView(
                    initialMonth: _selectedMonth,
                    initialDay: _selectedDay,
                  )),
                );
              },
              icon: Icon(Icons.open_in_new_rounded, size: 15, color: p.accent),
              label: Text(
                'السنكسار الكامل',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: p.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: CopticCalendarService.synaxariumCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, cIdx) {
              final cat = CopticCalendarService.synaxariumCategories[cIdx];
              final sel = _selectedSynCategory == cat['id'];
              return ChoiceChip(
                label: Text(
                  cat['name']!,
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: sel ? p.onAccent : p.ink,
                  ),
                ),
                selected: sel,
                selectedColor: p.accent,
                backgroundColor: p.surfaceElevated,
                showCheckmark: false,
                side: BorderSide(color: sel ? p.accent : p.border),
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedSynCategory = cat['id']!);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        ...synItems.take(12).map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: p.accentSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item['category_name'] ?? 'السنكسار',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: p.accent,
                        ),
                      ),
                    ),
                    Text(
                      item['date'] ?? '$_selectedDay $monthName',
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: p.inkMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CopticCross(size: 16, color: p.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['title'] ?? '',
                        style: GoogleFonts.amiri(
                          fontSize: 18.5,
                          fontWeight: FontWeight.w700,
                          color: p.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                if ((item['summary'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item['summary']!,
                    style: GoogleFonts.amiri(
                      fontSize: 18.5 * fontScale,
                      height: 1.85,
                      color: p.ink,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Text(
          'جدول قراءات القطمارس ليوم $_selectedDay $monthName ($seasonName):',
          style: GoogleFonts.cairo(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 8),
        ...readingsBlueprint.map((r) {
          final fullRef = (r['full_ref'] != null && r['full_ref']!.isNotEmpty)
              ? r['full_ref']!
              : '${r['book']} (${r['chapter']} : ${r['verses']})';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: p.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  r['type'] ?? '',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.accent,
                  ),
                ),
                Flexible(
                  child: Text(
                    fullRef,
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      color: p.ink,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildReadingCard({
    required AppPalette p,
    required String section,
    required String reference,
    required String text,
    required double fontScale,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: p.accentSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  section,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: p.accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  reference,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: p.crimson,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SelectableText(
            text,
            textAlign: TextAlign.justify,
            style: GoogleFonts.amiri(
              fontSize: 19.5 * fontScale,
              height: 1.85,
              color: p.ink,
            ),
          ),
        ],
      ),
    );
  }
}
