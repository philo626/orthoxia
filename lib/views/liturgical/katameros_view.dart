import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/coptic_calendar_service.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../models/katameros_model.dart';
import '../../providers/theme_provider.dart';
import '../synaxarium/synaxarium_daily_view.dart';

class KatamerosView extends StatefulWidget {
  final KatamerosDay katameros;
  final int initialTabIndex; // 0: Sundays, 1: Great Lent, 2: Annual & Categorized Synaxarium

  const KatamerosView({
    super.key,
    required this.katameros,
    this.initialTabIndex = 0,
  });

  @override
  State<KatamerosView> createState() => _KatamerosViewState();
}

class _KatamerosViewState extends State<KatamerosView> {
  late int _activeEngine; // 0 = قطمارس الآحاد, 1 = قطمارس الصوم الكبير, 2 = السنوي والسنكسار المقسم
  List<dynamic> _sundaysMonths = [];
  List<dynamic> _greatLentWeeks = [];
  bool _isLoading = true;

  // Sundays state
  int _selectedSundayMonthIdx = 0;
  int _selectedSundayIdx = 0;

  // Great Lent state
  int _selectedLentWeekIdx = 0;
  int _selectedLentDayIdx = 0;

  // Annual & Categorized Synaxarium state
  late int _selectedMonth;
  late int _selectedDay;
  String _selectedSynCategory = 'today';

  @override
  void initState() {
    super.initState();
    _activeEngine = widget.initialTabIndex.clamp(0, 2);
    final today = CopticCalendarService.fromGregorian(DateTime.now());
    _selectedMonth = today.month.clamp(1, 13);
    _selectedDay = today.day.clamp(1, 30);
    _selectedSundayMonthIdx = (_selectedMonth - 1).clamp(0, 12);
    _loadKatamerosComplete();
  }

  Future<void> _loadKatamerosComplete() async {
    try {
      await CopticCalendarService.ensureLectionaryLoaded();
      final raw = await rootBundle.loadString('assets/data/katameros_complete.json');
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
    final fontScale = context.watch<ThemeProvider>().fontScale;

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGold))
            : Column(
                children: [
                  // Top Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const CopticCross(size: 26),
                        Text(
                          'موسوعة القطمارس والسنكسار القبطي',
                          style: GoogleFonts.cairo(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGoldLight,
                          ),
                        ),
                        LuxeCircleButton(
                          icon: Icons.chevron_right_rounded,
                          onTap: () {
                            if (Navigator.canPop(context)) Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),

                  // 3-Engine Segmented Selector (قطمارس الآحاد • قطمارس الصوم الكبير • السنوي والسنكسار المقسم)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.cardNavy,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.primaryGold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildEngineTab(0, 'قطمارس الآحاد'),
                        _buildEngineTab(1, 'قطمارس الصوم الكبير'),
                        _buildEngineTab(2, 'السنوي والسنكسار'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Engine Body
                  Expanded(
                    child: _activeEngine == 0
                        ? _buildSundaysKatamerosView(fontScale)
                        : (_activeEngine == 1
                            ? _buildGreatLentKatamerosView(fontScale)
                            : _buildAnnualAndCategorizedSynaxariumView(fontScale)),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEngineTab(int idx, String title) {
    final sel = _activeEngine == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activeEngine = idx);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: sel ? AppColors.champagne : null,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: sel ? Colors.black : AppColors.textLight,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ENGINE 1: قطمارس قراءات الآحاد - القس أنطونيوس فكري
  // ===========================================================================
  Widget _buildSundaysKatamerosView(double fontScale) {
    if (_sundaysMonths.isEmpty) {
      return const Center(child: Text('جاري تحميل قراءات الآحاد...'));
    }
    final safeMIdx = _selectedSundayMonthIdx.clamp(0, _sundaysMonths.length - 1);
    final monthData = _sundaysMonths[safeMIdx] as Map<String, dynamic>;
    final sundays = monthData['sundays'] as List<dynamic>? ?? [];
    final safeSIdx = _selectedSundayIdx.clamp(0, sundays.length - 1);
    final sundayData = sundays[safeSIdx] as Map<String, dynamic>;
    final readings = sundayData['readings'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
      children: [
        // 13 Coptic Months Selector
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
                    fontWeight: FontWeight.bold,
                    color: sel ? Colors.black : AppColors.textLight,
                  ),
                ),
                selected: sel,
                selectedColor: AppColors.primaryGold,
                backgroundColor: AppColors.cardNavy,
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

        // 4 Sundays Selector (الأحد الأول .. الرابع)
        Row(
          children: List.generate(sundays.length, (sIdx) {
            final sel = sIdx == safeSIdx;
            final labels = ['الأحد الأول', 'الأحد الثاني', 'الأحد الثالث', 'الأحد الرابع'];
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
                      color: sel ? AppColors.primaryGold : AppColors.cardNavy,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel
                            ? AppColors.primaryGoldLight
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      labels[sIdx % labels.length],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: sel ? Colors.black : AppColors.textLight,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 12),

        // Fr. Antonios Fekry Contemplative Theme Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2B2215), Color(0xFF161513)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryGold, width: 1.3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const CopticCross(size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${sundayData['title']} • القس أنطونيوس فكري',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGoldLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'محور الأحد: ${sundayData['theme']}',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${sundayData['father_commentary']}',
                style: GoogleFonts.cairo(
                  fontSize: 12.5 * fontScale,
                  height: 1.6,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Readings Accordion/Cards
        ...readings.map((r) {
          final item = r as Map<String, dynamic>;
          return _buildReadingCard(
            section: '${item['section']}',
            reference: '${item['ref']}',
            text: '${item['text']}',
            fontScale: fontScale,
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // ENGINE 2: قطمارس الصوم الكبير وصوم يونان - دير الشهيد مارمينا مريوط (53 يوماً)
  // ===========================================================================
  Widget _buildGreatLentKatamerosView(double fontScale) {
    if (_greatLentWeeks.isEmpty) {
      return const Center(child: Text('جاري تحميل قطمارس الصوم الكبير...'));
    }
    final safeWIdx = _selectedLentWeekIdx.clamp(0, _greatLentWeeks.length - 1);
    final weekData = _greatLentWeeks[safeWIdx] as Map<String, dynamic>;
    final days = weekData['days'] as List<dynamic>? ?? [];
    final safeDIdx = _selectedLentDayIdx.clamp(0, days.length - 1);
    final dayData = days[safeDIdx] as Map<String, dynamic>;
    final readings = dayData['readings'] as List<dynamic>? ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
      children: [
        // Weeks Selector (صوم يونان + الـ ٧ أسابيع للصوم الكبير)
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
                    fontWeight: FontWeight.bold,
                    color: sel ? Colors.black : AppColors.textLight,
                  ),
                ),
                selected: sel,
                selectedColor: AppColors.primaryGold,
                backgroundColor: AppColors.cardNavy,
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

        // Days of the Selected Lent Week Selector
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
                    fontWeight: FontWeight.bold,
                    color: sel ? Colors.black : AppColors.primaryGoldLight,
                  ),
                ),
                selected: sel,
                selectedColor: AppColors.primaryGold,
                backgroundColor: AppColors.cardNavy,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedLentDayIdx = dIdx);
                },
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // St. Mina Monastery Great Lent Day Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF281D16), Color(0xFF151412)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryGold, width: 1.3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const CopticCross(size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${dayData['day_title']}',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGoldLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'قطمارس الصوم الكبير • دير الشهيد العظيم مارمينا العجائبي بمريوط',
                style: GoogleFonts.cairo(
                  fontSize: 11.5,
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${dayData['contemplation']}',
                style: GoogleFonts.cairo(
                  fontSize: 12.5 * fontScale,
                  height: 1.55,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Prophecies, Matins, Pauline, Catholic, Acts, Liturgy Gospel
        ...readings.map((r) {
          final item = r as Map<String, dynamic>;
          return _buildReadingCard(
            section: '${item['section']}',
            reference: '${item['ref']}',
            text: '${item['text']}',
            fontScale: fontScale,
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // ENGINE 3: القطمارس والسنكسار اليومي التلقائي المُقسّم فئات (Categories)
  // ===========================================================================
  Widget _buildAnnualAndCategorizedSynaxariumView(double fontScale) {
    final copticToday = CopticCalendarService.fromGregorian(DateTime.now());
    final monthName = CopticCalendarService.copticMonths[(_selectedMonth - 1).clamp(0, 12)];
    final seasonName = copticToday.seasonName;
    final readingsBlueprint =
        CopticCalendarService.getDailyReadingsBlueprint(_selectedMonth, _selectedDay);
    final synItems = CopticCalendarService.getCategorizedSynaxariumItems(
      month: _selectedMonth,
      day: _selectedDay,
      category: _selectedSynCategory,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
      children: [
        // Live Automatic Daily Coptic Date & Occasion Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF281F13), Color(0xFF151412)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryGold, width: 1.3),
          ),
          child: Row(
            children: [
              const CopticCross(size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'تاريخ اليوم القبطي: ${copticToday.formatted}',
                          style: GoogleFonts.cairo(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGoldLight,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'يتحدث يومياً تلقائياً',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGoldLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'المناسبة الكنسية: ${copticToday.seasonName} • ${copticToday.fastingNote}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.primaryGold,
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

        // Synaxarium Categories Filter Chips (متقسم Categories)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'أقسام وفئات السنكسار اليومي (Categories):',
              style: GoogleFonts.cairo(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGoldLight,
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
              icon: const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.primaryGold),
              label: Text(
                'السنكسار الكامل',
                style: GoogleFonts.cairo(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: CopticCalendarService.synaxariumCategories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, cIdx) {
              final cat = CopticCalendarService.synaxariumCategories[cIdx];
              final sel = _selectedSynCategory == cat['id'];
              return ChoiceChip(
                label: Text(
                  cat['name']!,
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: sel ? Colors.black : AppColors.textLight,
                  ),
                ),
                selected: sel,
                selectedColor: AppColors.primaryGold,
                backgroundColor: AppColors.cardNavy,
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedSynCategory = cat['id']!);
                },
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Categorized Synaxarium Cards
        ...synItems.take(12).map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: AppColors.obsidianCard,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primaryGold.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item['category_name'] ?? 'السنكسار',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGoldLight,
                        ),
                      ),
                    ),
                    Text(
                      item['date'] ?? '$_selectedDay $monthName',
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const CopticCross(size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['title'] ?? '',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGoldLight,
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
                      fontSize: 19 * fontScale,
                      height: 1.85,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),

        const SizedBox(height: 8),

        // Daily Readings Blueprint for Selected Coptic Day
        Text(
          'جدول قراءات القطمارس ليوم $_selectedDay $monthName ($seasonName):',
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryGoldLight,
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
              color: AppColors.cardNavy,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  r['type'] ?? '',
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGold,
                  ),
                ),
                Flexible(
                  child: Text(
                    fullRef,
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      color: AppColors.textLight,
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
    required String section,
    required String reference,
    required String text,
    required double fontScale,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.obsidianCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primaryGold.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  section,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGoldLight,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  reference,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.justify,
            style: GoogleFonts.amiri(
              fontSize: 19.5 * fontScale,
              height: 1.85,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 240.ms);
  }
}
