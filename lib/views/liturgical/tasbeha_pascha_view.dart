import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/coptic_calendar_service.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../providers/theme_provider.dart';

/// Complete Coptic Orthodox Midnight Praise (الإبصلمودية السنوية الكاملة),
/// Full 7-Day Holy Week Pascha (البصخة المقدسة مع عداد ١٢ مرة ثوك تي تي جوم),
/// and All Major/Minor/Saints + Movable Feasts Calculator.
class TasbehaPaschaView extends StatefulWidget {
  final int initialTab;
  final bool embedded;

  const TasbehaPaschaView({
    super.key,
    this.initialTab = 0,
    this.embedded = false,
  });

  @override
  State<TasbehaPaschaView> createState() => _TasbehaPaschaViewState();
}

class _TasbehaPaschaViewState extends State<TasbehaPaschaView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedYear = DateTime.now().year;

  bool _loading = true;
  List<Map<String, dynamic>> _tasbehaSections = [];
  List<Map<String, dynamic>> _kiahkSections = [];
  List<Map<String, dynamic>> _seasonalDoxologies = [];
  List<Map<String, dynamic>> _paschaDays = [];
  List<Map<String, dynamic>> _fixedFeasts = [];

  String _tasbehaMode = 'annual'; // 'annual' | 'kiahk' | 'doxologies'
  int _selectedTasbehaIdx = 0;
  int _selectedKiahkIdx = 0;
  int _selectedPaschaDayIdx = 0;
  int _thokCount = 0; // Interactive 12x Thok Te Ti Gom counter
  String _feastFilter = 'movable'; // 'movable' | 'major' | 'minor' | 'saints'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 2),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final raw = await rootBundle
          .loadString('assets/data/tasbeha_pascha_complete.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _tasbehaSections = (map['tasbeha'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _kiahkSections = (map['kiahk_tasbeha'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _seasonalDoxologies = (map['seasonal_doxologies'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _paschaDays = (map['pascha_days'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _fixedFeasts = (map['fixed_feasts'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    SpeechPronunciationService().stop();
    _tabController.dispose();
    super.dispose();
  }

  static const List<String> _arDays = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];
  static const List<String> _arMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  String _formatArabicDate(DateTime dt) {
    final dayName = _arDays[(dt.weekday - 1).clamp(0, 6)];
    final monthName = _arMonths[(dt.month - 1).clamp(0, 11)];
    return '$dayName، ${dt.day} $monthName ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fontScale = context.watch<ThemeProvider>().fontScale;
    final movableFeasts =
        CopticCalendarService.getMovableFeastsForYear(_selectedYear);

    final tabBar = TabBar(
      controller: _tabController,
      indicatorColor: p.accent,
      labelColor: p.accent,
      unselectedLabelColor: p.inkMuted,
      labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 12),
      tabs: const [
        Tab(text: 'التسبحة (الإبصلمودية)'),
        Tab(text: 'البصخة المقدسة'),
        Tab(text: 'الأعياد والأصوام'),
      ],
    );

    final body = _loading
        ? Center(child: CircularProgressIndicator(color: p.accent))
        : TabBarView(
            controller: _tabController,
            children: [
              _buildTasbehaTab(p, fontScale),
              _buildPaschaTab(p, fontScale),
              _buildFeastsTab(p, movableFeasts),
            ],
          );

    if (widget.embedded) {
      return Column(
        children: [
          Material(color: p.background, child: tabBar),
          Divider(color: p.border, height: 1),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'التسبحة والبصخة والأعياد المتحركة',
          style: GoogleFonts.amiri(
            fontWeight: FontWeight.w700,
            fontSize: 21,
            color: p.ink,
          ),
        ),
        bottom: tabBar,
      ),
      body: body,
    );
  }

  // ==================== TAB 1: FULL MIDNIGHT TASBEHA (ANNUAL + KIAHK + DOXOLOGIES) ====================
  Widget _buildTasbehaTab(AppPalette p, double fontScale) {
    if (_tasbehaSections.isEmpty) {
      return Center(
        child: Text('جارٍ تحميل الإبصلمودية...',
            style: GoogleFonts.cairo(color: p.inkMuted)),
      );
    }

    final modeSwitcher = Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: p.surfaceSubtle,
        border: Border(bottom: BorderSide(color: p.border, width: 0.7)),
      ),
      child: Row(
        children: [
          _tasbehaModeBtn(p, 'annual', 'السنوية (${_tasbehaSections.length})'),
          const SizedBox(width: 6),
          _tasbehaModeBtn(p, 'kiahk', 'الكيهكية ٧ و ٤'),
          const SizedBox(width: 6),
          _tasbehaModeBtn(p, 'doxologies', 'الذكصولوجيات (${_seasonalDoxologies.length})'),
        ],
      ),
    );

    if (_tasbehaMode == 'doxologies') {
      return Column(
        children: [
          modeSwitcher,
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
              itemCount: _seasonalDoxologies.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, idx) {
                final dox = _seasonalDoxologies[idx];
                return Container(
                  padding: const EdgeInsets.all(15),
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
                          CopticCross(size: 14, color: p.accent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${dox['season'] ?? ''}',
                              style: GoogleFonts.amiri(
                                fontSize: 19 * fontScale.clamp(0.85, 1.3),
                                fontWeight: FontWeight.bold,
                                color: p.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        '${dox['arabic'] ?? ''}',
                        style: GoogleFonts.amiri(
                          fontSize: 18 * fontScale,
                          height: 1.8,
                          color: p.ink,
                        ),
                      ),
                      if ('${dox['arabized'] ?? ''}'.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        SelectableText(
                          '${dox['arabized']}',
                          style: GoogleFonts.cairo(
                            fontSize: 13 * fontScale,
                            color: p.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if ('${dox['coptic'] ?? ''}'.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        SelectableText(
                          '${dox['coptic']}',
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontFamily: 'Coptic',
                            fontSize: 14 * fontScale,
                            color: p.inkSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    final activeList = _tasbehaMode == 'kiahk' && _kiahkSections.isNotEmpty
        ? _kiahkSections
        : _tasbehaSections;
    final activeIdx = _tasbehaMode == 'kiahk' ? _selectedKiahkIdx : _selectedTasbehaIdx;
    final safeIdx = activeIdx.clamp(0, activeList.length - 1);
    final sec = activeList[safeIdx];
    final title = '${sec['title'] ?? ''}';
    final subtitle = '${sec['subtitle'] ?? sec['tune'] ?? ''}';
    final coptic = '${sec['coptic'] ?? ''}';
    final arabized = '${sec['arabized'] ?? ''}';
    final arabic = '${sec['arabic'] ?? ''}';

    return Column(
      children: [
        modeSwitcher,
        // Quick Part Selector Strip
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: activeList.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final sel = idx == safeIdx;
              final shortLbl = '${activeList[idx]['title'] ?? ''}'
                  .split('(')
                  .first
                  .trim();
              return ChoiceChip(
                showCheckmark: false,
                selected: sel,
                selectedColor: p.accent,
                backgroundColor: p.surfaceElevated,
                side: BorderSide(color: sel ? p.accent : p.border),
                label: Text(
                  shortLbl,
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: sel ? p.onAccent : p.ink,
                  ),
                ),
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  SpeechPronunciationService().stop();
                  setState(() {
                    if (_tasbehaMode == 'kiahk') {
                      _selectedKiahkIdx = idx;
                    } else {
                      _selectedTasbehaIdx = idx;
                    }
                  });
                },
              );
            },
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 95),
            children: [
              // Section Header Card
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
                            title,
                            style: GoogleFonts.amiri(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: p.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: p.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        SpeechPlayStopButton(
                          textToSpeak: '$title. $arabic',
                          label: title,
                          playText: 'استماع للقسم',
                          stopText: 'إيقاف الصوت',
                          compact: true,
                        ),
                        const Spacer(),
                        Text(
                          'القسم ${safeIdx + 1} من ${_tasbehaSections.length}',
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            color: p.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Coptic & Arabized Stanza Box
              if (coptic.isNotEmpty || arabized.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.accentSoft,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: p.accent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (coptic.isNotEmpty) ...[
                        Text(
                          'النص القبطي:',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: p.accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          coptic,
                          textDirection: TextDirection.ltr,
                          style: GoogleFonts.cairo(
                            fontSize: 14.5 * fontScale,
                            fontWeight: FontWeight.w700,
                            color: p.ink,
                            height: 1.55,
                          ),
                        ),
                      ],
                      if (arabized.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'القبطي المعرب:',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: p.crimson,
                          ),
                        ),
                        const SizedBox(height: 3),
                        SelectableText(
                          arabized,
                          style: GoogleFonts.cairo(
                            fontSize: 13.5 * fontScale,
                            fontWeight: FontWeight.w600,
                            color: p.crimson,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Full Verbatim Arabic Text
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: p.surfaceElevated,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: p.border),
                ),
                child: SelectableText(
                  arabic,
                  style: GoogleFonts.amiri(
                    fontSize: 20 * fontScale,
                    height: 1.9,
                    color: p.ink,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Prev / Next Tasbeha Section Navigation
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (safeIdx > 0)
                    OutlinedButton.icon(
                      onPressed: () => setState(() {
                        if (_tasbehaMode == 'kiahk') {
                          _selectedKiahkIdx = safeIdx - 1;
                        } else {
                          _selectedTasbehaIdx = safeIdx - 1;
                        }
                      }),
                      icon: Icon(Icons.arrow_back_rounded,
                          size: 16, color: p.accent),
                      label: Text('القسم السابق',
                          style: GoogleFonts.cairo(color: p.accent)),
                      style: OutlinedButton.styleFrom(
                          side: BorderSide(color: p.border)),
                    )
                  else
                    const SizedBox.shrink(),
                  if (safeIdx < activeList.length - 1)
                    ElevatedButton.icon(
                      onPressed: () => setState(() {
                        if (_tasbehaMode == 'kiahk') {
                          _selectedKiahkIdx = safeIdx + 1;
                        } else {
                          _selectedTasbehaIdx = safeIdx + 1;
                        }
                      }),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: Text('القسم التالي',
                          style:
                              GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.accent,
                        foregroundColor: p.onAccent,
                        elevation: 0,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tasbehaModeBtn(AppPalette p, String mode, String label) {
    final active = _tasbehaMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          SpeechPronunciationService().stop();
          setState(() => _tasbehaMode = mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? p.accent : p.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: active ? p.accent : p.border),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: active ? p.onAccent : p.ink,
            ),
          ),
        ),
      ),
    );
  }

  // ==================== TAB 2: COMPLETE 7-DAY HOLY WEEK PASCHA ====================
  Widget _buildPaschaTab(AppPalette p, double fontScale) {
    if (_paschaDays.isEmpty) {
      return Center(
        child: Text('جارٍ تحميل دلال البصخة المقدسة...',
            style: GoogleFonts.cairo(color: p.inkMuted)),
      );
    }
    final safeDay = _selectedPaschaDayIdx.clamp(0, _paschaDays.length - 1);
    final day = _paschaDays[safeDay];
    final sections = (day['sections'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return Column(
      children: [
        // 7-Day Holy Week Selector
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: p.border)),
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: _paschaDays.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final sel = idx == safeDay;
              return ChoiceChip(
                showCheckmark: false,
                selected: sel,
                selectedColor: p.crimson,
                backgroundColor: p.surfaceElevated,
                side: BorderSide(color: sel ? p.crimson : p.border),
                label: Text(
                  '${_paschaDays[idx]['day_name']}',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : p.ink,
                  ),
                ),
                onSelected: (_) {
                  HapticFeedback.selectionClick();
                  SpeechPronunciationService().stop();
                  setState(() {
                    _selectedPaschaDayIdx = idx;
                    _thokCount = 0;
                  });
                },
              );
            },
          ),
        ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 95),
            children: [
              // Day Liturgical Overview Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.surfaceElevated,
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: p.crimson.withValues(alpha: 0.45)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        CopticCross(size: 18, color: p.crimson),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${day['day_name']}',
                            style: GoogleFonts.amiri(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: p.ink,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: p.crimsonSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'أسبوع الآلام',
                            style: GoogleFonts.cairo(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: p.crimson,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${day['subtitle']} • ${day['tone']}',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: p.accent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${day['overview']}',
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        color: p.inkMuted,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Interactive 12x Thok Te Ti Gom Haptic Counter
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: p.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'عدّاد تسبحة البصخة «ثوك تي تي جوم»',
                            style: GoogleFonts.cairo(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: p.ink,
                            ),
                          ),
                          Text(
                            _thokCount >= 12
                                ? 'أتممت ١٢ مرة لهذه الساعة!'
                                : 'اضغط مع كل مرة (تُقال ١٢ مرة في كل ساعة)',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: _thokCount >= 12 ? p.success : p.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_thokCount > 0)
                      IconButton(
                        tooltip: 'تصفير',
                        icon: Icon(Icons.refresh_rounded,
                            size: 18, color: p.inkMuted),
                        onPressed: () => setState(() => _thokCount = 0),
                      ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _thokCount = _thokCount >= 12 ? 0 : _thokCount + 1;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _thokCount >= 12 ? p.success : p.accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_thokCount / 12',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: p.onAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Day Sections (Prophecies, Hymns, Gospels, Prayers)
              for (final sec in sections) ...[
                Container(
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
                        children: [
                          Expanded(
                            child: Text(
                              '${sec['title']}',
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: p.crimson,
                              ),
                            ),
                          ),
                          SpeechPlayStopButton(
                            textToSpeak: '${sec['title']}. ${sec['arabic']}',
                            label: '${sec['title']}',
                            playText: 'استماع',
                            stopText: 'إيقاف',
                            compact: true,
                          ),
                        ],
                      ),
                      if ('${sec['coptic'] ?? ''}'.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        SelectableText(
                          '${sec['coptic']}',
                          textDirection: TextDirection.ltr,
                          style: GoogleFonts.cairo(
                            fontSize: 13.5 * fontScale,
                            fontWeight: FontWeight.w700,
                            color: p.accent,
                            height: 1.5,
                          ),
                        ),
                      ],
                      if ('${sec['arabized'] ?? ''}'.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        SelectableText(
                          '${sec['arabized']}',
                          style: GoogleFonts.cairo(
                            fontSize: 12.5 * fontScale,
                            fontWeight: FontWeight.w600,
                            color: p.inkMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      SelectableText(
                        '${sec['arabic']}',
                        style: GoogleFonts.amiri(
                          fontSize: 19 * fontScale,
                          height: 1.85,
                          color: p.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ==================== TAB 3: ALL COPTIC FEASTS & MOVABLE CALCULATOR ====================
  Widget _buildFeastsTab(AppPalette p, List<Map<String, dynamic>> movable) {
    final filteredFixed =
        _fixedFeasts.where((f) => f['group'] == _feastFilter).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 95),
      children: [
        // Feast Category Filter Pills
        SizedBox(
          height: 38,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _feastPill(p, 'movable', 'حاسبة الأعياد والأصوام المتحركة'),
              const SizedBox(width: 8),
              _feastPill(p, 'major', 'السيدية الكبرى (٧)'),
              const SizedBox(width: 8),
              _feastPill(p, 'minor', 'السيدية الصغرى (٧)'),
              const SizedBox(width: 8),
              _feastPill(p, 'saints', 'أعياد العذراء والقديسين'),
            ],
          ),
        ),

        const SizedBox(height: 14),

        if (_feastFilter == 'movable') ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.accent.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() => _selectedYear--),
                  icon: Icon(Icons.chevron_right_rounded, color: p.accent),
                ),
                Column(
                  children: [
                    Text(
                      'حاسبة الأعياد والأصوام القبطية',
                      style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkMuted),
                    ),
                    Text(
                      'سنة $_selectedYear ميلادية',
                      style: GoogleFonts.amiri(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => setState(() => _selectedYear++),
                  icon: Icon(Icons.chevron_left_rounded, color: p.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...movable.map((f) {
            final dt = f['date'] as DateTime;
            final coptic = CopticCalendarService.fromGregorian(dt);
            final isMajor = f['type'] == 'major_feast';
            final isFast = f['type'] == 'fast';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isMajor ? p.accentSoft : p.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isMajor
                      ? p.accent
                      : (isFast
                          ? p.crimson.withValues(alpha: 0.45)
                          : p.border),
                  width: isMajor ? 1.3 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isMajor
                        ? Icons.auto_awesome_rounded
                        : (isFast
                            ? Icons.nights_stay_rounded
                            : Icons.church_rounded),
                    color: isFast ? p.crimson : p.accent,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${f['name']}',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: p.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatArabicDate(dt),
                          style: GoogleFonts.cairo(
                              fontSize: 12, color: p.inkMuted),
                        ),
                        Text(
                          'الموافق قبطياً: ${coptic.formatted}',
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: p.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ] else ...[
          for (final f in filteredFixed)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: p.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: p.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CopticCross(size: 16, color: p.accent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${f['name']}',
                          style: GoogleFonts.amiri(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: p.ink,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: p.accentSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${f['tone']}',
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: p.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'القبطي: ${f['coptic']} • الميلادي: ${f['gregorian']}',
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: p.crimson,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${f['meaning']}',
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      color: p.inkMuted,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _feastPill(AppPalette p, String id, String label) {
    final sel = _feastFilter == id;
    return ChoiceChip(
      showCheckmark: false,
      selected: sel,
      selectedColor: p.accent,
      backgroundColor: p.surfaceElevated,
      side: BorderSide(color: sel ? p.accent : p.border),
      label: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: sel ? p.onAccent : p.ink,
        ),
      ),
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() => _feastFilter = id);
      },
    );
  }
}
