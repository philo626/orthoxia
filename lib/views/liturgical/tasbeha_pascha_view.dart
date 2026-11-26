import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/coptic_calendar_service.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/sacred_section_banner.dart';
import '../../providers/theme_provider.dart';

Map<String, dynamic> _decodeTasbehaJson(String raw) =>
    jsonDecode(raw) as Map<String, dynamic>;

/// Complete Coptic Orthodox Annual & Weekday Psalmody (الإبصلمودية السنوية وأيام الأسبوع),
/// Full Kiahk 7 & 4 Psalmody (الإبصلمودية الكيهكية), 82 Complete Doxologies (الذكصولوجيات),
/// Full 7-Day Holy Week Pascha (دلال البصخة المقدسة كاملاً بساعاته الليلية والنهارية),
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
  static Map<String, dynamic>? _cachedDataset;

  late TabController _tabController;
  int _selectedYear = DateTime.now().year;

  bool _loading = true;
  List<Map<String, dynamic>> _tasbehaSections = [];
  List<Map<String, dynamic>> _weekdaySections = [];
  List<Map<String, dynamic>> _kiahkSections = [];
  List<Map<String, dynamic>> _seasonalDoxologies = [];
  List<Map<String, dynamic>> _paschaDays = [];
  List<Map<String, dynamic>> _fixedFeasts = [];

  String _tasbehaMode = 'annual'; // 'annual' | 'weekdays' | 'kiahk' | 'doxologies'
  int _selectedTasbehaIdx = 0;
  int _selectedWeekdayIdx = 0;
  int _selectedKiahkIdx = 0;
  String _doxQuery = '';
  bool _showArabic = true;
  bool _showCoptic = true;
  bool _showArabized = true;

  int _selectedPaschaDayIdx = 0;
  int _selectedPaschaHourIdx = -1; // -1 = show overview + selected hour, >= 0 = specific hour
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
      Map<String, dynamic> map;
      if (_cachedDataset != null) {
        map = _cachedDataset!;
      } else {
        final raw = await rootBundle
            .loadString('assets/data/tasbeha_pascha_complete.json');
        map = await compute(_decodeTasbehaJson, raw);
        _cachedDataset = map;
      }
      _tasbehaSections = (map['tasbeha'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _weekdaySections = (map['weekday_tasbeha'] as List? ?? [])
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

  void _copyText(String text) {
    if (text.trim().isEmpty) return;
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: text.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1400),
        content: Text('تم نسخ النص', style: GoogleFonts.cairo(fontSize: 12.5)),
      ),
    );
  }

  static const List<String> _arDays = [
    'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
  ];
  static const List<String> _arMonths = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];

  String _formatArabicDate(DateTime dt) {
    final dayName = _arDays[(dt.weekday - 1).clamp(0, 6)];
    final monthName = _arMonths[(dt.month - 1).clamp(0, 11)];
    return '$dayName، ${dt.day} $monthName ${dt.year}';
  }

  void _openSectionsIndexSheet({
    required String title,
    required List<String> labels,
    required int selectedIndex,
    required ValueChanged<int> onPick,
  }) {
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.72,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: p.border)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$title (${labels.length})',
              style: GoogleFonts.amiri(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: labels.length,
                separatorBuilder: (_, _) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final sel = i == selectedIndex;
                  return Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: sel ? p.accent : p.border),
                      ),
                      tileColor: sel ? p.goldSoft : p.surfaceSubtle,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: sel ? p.accent : p.surface,
                        child: Text(
                          '${i + 1}',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: sel ? p.onAccent : p.ink,
                          ),
                        ),
                      ),
                      title: Text(
                        labels[i],
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                          color: sel ? p.accent : p.ink,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        onPick(i);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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

  // ==================== TAB 1: COMPLETE ANNUAL + WEEKDAYS + KIAHK + DOXOLOGIES ====================
  Widget _buildTasbehaTab(AppPalette p, double fontScale) {
    if (_tasbehaSections.isEmpty) {
      return Center(
        child: Text('جارٍ تحميل الإبصلمودية...',
            style: GoogleFonts.cairo(color: p.inkMuted)),
      );
    }

    // Clean Katameros-style Psalmody Type Dropdown + Language Toggles (ع | ق | م)
    final modeItems = <DropdownMenuItem<String>>[
      DropdownMenuItem(
        value: 'annual',
        child: Text('الإبصلمودية السنوية (${_tasbehaSections.length} قسماً)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: p.ink)),
      ),
      if (_weekdaySections.isNotEmpty)
        DropdownMenuItem(
          value: 'weekdays',
          child: Text('ثيؤطوكيات أيام الأسبوع (${_weekdaySections.length})',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: p.ink)),
        ),
      DropdownMenuItem(
        value: 'kiahk',
        child: Text('الإبصلمودية الكيهكية ٧ و ٤ (${_kiahkSections.length})',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: p.ink)),
      ),
      DropdownMenuItem(
        value: 'doxologies',
        child: Text('ذكصولوجيات المناسبات والأعياد (${_seasonalDoxologies.length})',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: p.ink)),
      ),
    ];

    final bannerImg = (_tasbehaMode == 'kiahk' || _tasbehaMode == 'doxologies')
        ? 'assets/images/banner_madayeh.jpg'
        : 'assets/images/banner_tasbeha.jpg';
    final bannerTitle = _tasbehaMode == 'kiahk'
        ? 'الإبصلمودية الكيهكية المقدسة'
        : (_tasbehaMode == 'doxologies'
            ? 'ذكصولوجيات المناسبات والأعياد'
            : (_tasbehaMode == 'weekdays'
                ? 'ثيؤطوكيات وإبصاليات الأسبوع'
                : 'الإبصلمودية السنوية (تسبحة نصف الليل)'));

    final modeSwitcher = Column(
      children: [
        SacredSectionBanner(
          imageAsset: bannerImg,
          title: bannerTitle,
          subtitle: 'اختر نوع الإبصلمودية والقسم مباشرة من القوائم أدناه',
          badge: 'التسبحة المقدسة',
          height: 98,
          margin: const EdgeInsets.fromLTRB(14, 8, 14, 6),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
          child: Row(
            children: [
              Expanded(
                child: LiturgicalDropdownBox<String>(
                  label: 'نوع الإبصلمودية',
                  dense: true,
                  value: _tasbehaMode,
                  items: modeItems,
                  onChanged: (v) {
                    if (v == null) return;
                    HapticFeedback.selectionClick();
                    SpeechPronunciationService().stop();
                    setState(() => _tasbehaMode = v);
                  },
                ),
              ),
              const SizedBox(width: 6),
              // Katameros-style Language Toggles (ع | ق | م)
              _langTogglePill(p, 'ع', _showArabic, () {
                if (_showArabic && !_showCoptic && !_showArabized) return;
                setState(() => _showArabic = !_showArabic);
              }),
              const SizedBox(width: 4),
              _langTogglePill(p, 'ق', _showCoptic, () {
                if (_showCoptic && !_showArabic && !_showArabized) return;
                setState(() => _showCoptic = !_showCoptic);
              }),
              const SizedBox(width: 4),
              _langTogglePill(p, 'م', _showArabized, () {
                if (_showArabized && !_showArabic && !_showCoptic) return;
                setState(() => _showArabized = !_showArabized);
              }),
            ],
          ),
        ),
      ],
    );

    if (_tasbehaMode == 'doxologies') {
      final q = _doxQuery.trim();
      final filteredDox = q.isEmpty
          ? _seasonalDoxologies
          : _seasonalDoxologies.where((d) {
              return '${d['season'] ?? ''}'.contains(q) ||
                  '${d['arabic'] ?? ''}'.contains(q);
            }).toList();

      final bodyStyle = GoogleFonts.amiri(
        fontSize: 18 * fontScale,
        height: 1.85,
        color: p.ink,
      );
      final copStyle = TextStyle(
        fontFamily: 'Coptic',
        fontSize: 14 * fontScale,
        color: p.inkSecondary,
        height: 1.55,
      );

      return Column(
        children: [
          modeSwitcher,
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: TextField(
              onChanged: (v) => setState(() => _doxQuery = v),
              style: GoogleFonts.cairo(fontSize: 13, color: p.ink),
              decoration: const InputDecoration(
                hintText: 'ابحث في ٨٢ ذكصولوجية (العذراء، ميخائيل، مارجرجس، أنطونيوس...)...',
                prefixIcon: Icon(Icons.search_rounded, size: 19),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              itemCount: filteredDox.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, idx) {
                final dox = filteredDox[idx];
                final ar = '${dox['arabic'] ?? ''}';
                final cop = '${dox['coptic'] ?? ''}';
                final ab = '${dox['arabized'] ?? ''}';
                return GestureDetector(
                  onLongPress: () => _copyText(ar),
                  child: Container(
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
                                  fontSize: 18.5 * fontScale.clamp(0.85, 1.3),
                                  fontWeight: FontWeight.bold,
                                  color: p.accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(ar, style: bodyStyle),
                        if (ab.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            ab,
                            style: GoogleFonts.cairo(
                              fontSize: 12.5 * fontScale,
                              color: p.gold,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (cop.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            cop,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            style: copStyle,
                          ),
                        ],
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

    final List<Map<String, dynamic>> activeList;
    final int activeIdx;
    if (_tasbehaMode == 'weekdays' && _weekdaySections.isNotEmpty) {
      activeList = _weekdaySections;
      activeIdx = _selectedWeekdayIdx;
    } else if (_tasbehaMode == 'kiahk' && _kiahkSections.isNotEmpty) {
      activeList = _kiahkSections;
      activeIdx = _selectedKiahkIdx;
    } else {
      activeList = _tasbehaSections;
      activeIdx = _selectedTasbehaIdx;
    }

    final safeIdx = activeIdx.clamp(0, activeList.length - 1);
    final sec = activeList[safeIdx];
    final title = '${sec['title'] ?? ''}';
    final subtitle = '${sec['subtitle'] ?? sec['tune'] ?? ''}';
    final coptic = '${sec['coptic'] ?? ''}';
    final arabized = '${sec['arabized'] ?? ''}';
    final arabic = '${sec['arabic'] ?? ''}';

    void setActiveIdx(int newIdx) {
      SpeechPronunciationService().stop();
      setState(() {
        if (_tasbehaMode == 'weekdays') {
          _selectedWeekdayIdx = newIdx;
        } else if (_tasbehaMode == 'kiahk') {
          _selectedKiahkIdx = newIdx;
        } else {
          _selectedTasbehaIdx = newIdx;
        }
      });
    }

    return Column(
      children: [
        modeSwitcher,
        // Katameros-style Instant Section Jump Dropdown + Full Index Button
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Row(
            children: [
              Expanded(
                child: LiturgicalDropdownBox<int>(
                  label: 'الانتقال السريع للقسم (${safeIdx + 1} من ${activeList.length})',
                  dense: true,
                  value: safeIdx,
                  items: List.generate(activeList.length, (i) {
                    return DropdownMenuItem<int>(
                      value: i,
                      child: Text(
                        '${i + 1}. ${activeList[i]['title'] ?? ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: p.accent,
                        ),
                      ),
                    );
                  }),
                  onChanged: (v) {
                    if (v != null) {
                      HapticFeedback.selectionClick();
                      setActiveIdx(v);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'فهرس الإبصلمودية الكامل',
                style: IconButton.styleFrom(
                  backgroundColor: p.goldSoft,
                  foregroundColor: p.accent,
                ),
                icon: const Icon(Icons.format_list_bulleted_rounded, size: 20),
                onPressed: () => _openSectionsIndexSheet(
                  title: 'فهرس الإبصلمودية',
                  labels: activeList.map((e) => '${e['title'] ?? ''}').toList(),
                  selectedIndex: safeIdx,
                  onPick: setActiveIdx,
                ),
              ),
            ],
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
                          'القسم ${safeIdx + 1} من ${activeList.length}',
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

              // Coptic & Arabized Stanza Box (respects ع | ق | م toggles)
              if ((_showCoptic && coptic.isNotEmpty) ||
                  (_showArabized && arabized.isNotEmpty)) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.accentSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.accent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_showCoptic && coptic.isNotEmpty) ...[
                        Text(
                          'النص القبطي:',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: p.accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          coptic,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontFamily: 'Coptic',
                            fontSize: 15 * fontScale,
                            color: p.ink,
                            height: 1.6,
                          ),
                        ),
                      ],
                      if (_showArabized && arabized.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'النطق القبطي المعرب:',
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: p.crimson,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          arabized,
                          style: GoogleFonts.cairo(
                            fontSize: 13 * fontScale,
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
              if (_showArabic)
                GestureDetector(
                  onLongPress: () => _copyText(arabic),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: p.surfaceElevated,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: p.border),
                    ),
                    child: Text(
                      arabic,
                      style: GoogleFonts.amiri(
                        fontSize: 20 * fontScale,
                        height: 1.9,
                        color: p.ink,
                      ),
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
                      onPressed: () => setActiveIdx(safeIdx - 1),
                      icon: Icon(Icons.arrow_back_rounded, size: 16, color: p.accent),
                      label: Text('القسم السابق', style: GoogleFonts.cairo(color: p.accent)),
                      style: OutlinedButton.styleFrom(side: BorderSide(color: p.border)),
                    )
                  else
                    const SizedBox.shrink(),
                  if (safeIdx < activeList.length - 1)
                    ElevatedButton.icon(
                      onPressed: () => setActiveIdx(safeIdx + 1),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: Text('القسم التالي',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
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

  Widget _langTogglePill(
    AppPalette p,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 32,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? p.accent : p.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: active ? p.accent : p.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? p.onAccent : p.inkMuted,
          ),
        ),
      ),
    );
  }

  // ==================== TAB 2: COMPLETE 7-DAY HOLY WEEK PASCHA (EVERY HOUR VERBATIM!) ====================
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

    final visibleSections = (_selectedPaschaHourIdx >= 0 &&
            _selectedPaschaHourIdx < sections.length)
        ? [sections[_selectedPaschaHourIdx]]
        : sections;

    final bodyStyle = GoogleFonts.amiri(
      fontSize: 19 * fontScale,
      height: 1.85,
      color: p.ink,
    );

    return Column(
      children: [
        // Sacred Holy Week Banner
        SacredSectionBanner(
          imageAsset: 'assets/images/banner_pascha.jpg',
          title: 'دلال أسبوع الآلام المقدس',
          subtitle: '${day['day_name']} • ${day['tone'] ?? 'اللحن الإدريبي الحزايني'}',
          badge: 'البصخة المقدسة',
          height: 98,
          margin: const EdgeInsets.fromLTRB(14, 8, 14, 6),
        ),

        // Katameros-style Dual Dropdown Selector (Day + Hour)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: LiturgicalDropdownBox<int>(
                  label: 'يوم البصخة',
                  dense: true,
                  value: safeDay,
                  items: List.generate(_paschaDays.length, (i) {
                    return DropdownMenuItem<int>(
                      value: i,
                      child: Text(
                        '${_paschaDays[i]['day_name']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: p.crimson,
                        ),
                      ),
                    );
                  }),
                  onChanged: (idx) {
                    if (idx == null) return;
                    HapticFeedback.selectionClick();
                    SpeechPronunciationService().stop();
                    setState(() {
                      _selectedPaschaDayIdx = idx;
                      _selectedPaschaHourIdx = -1;
                      _thokCount = 0;
                    });
                  },
                ),
              ),
              if (sections.isNotEmpty) ...[
                const SizedBox(width: 8),
                Expanded(
                  flex: 6,
                  child: LiturgicalDropdownBox<int>(
                    label: 'الساعة (${sections.length})',
                    dense: true,
                    value: _selectedPaschaHourIdx.clamp(-1, sections.length - 1),
                    items: [
                      DropdownMenuItem<int>(
                        value: -1,
                        child: Text(
                          'كل ساعات اليوم (${sections.length})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: p.ink,
                          ),
                        ),
                      ),
                      ...List.generate(sections.length, (sIdx) {
                        final hrLabel =
                            '${sections[sIdx]['hour'] ?? sections[sIdx]['title'] ?? 'ساعة ${sIdx + 1}'}';
                        return DropdownMenuItem<int>(
                          value: sIdx,
                          child: Text(
                            hrLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 11.8,
                              fontWeight: FontWeight.w700,
                              color: p.accent,
                            ),
                          ),
                        );
                      }),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      HapticFeedback.selectionClick();
                      setState(() => _selectedPaschaHourIdx = v);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),

        // Lazy ListView.builder for 60fps Smooth Reading of Full Holy Week Texts
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 95),
            itemCount: visibleSections.length + 2,
            itemBuilder: (ctx, idx) {
              if (idx == 0) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: p.surfaceElevated,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: p.crimson.withValues(alpha: 0.45)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: p.crimsonSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${sections.length} ساعة/قسم',
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
                );
              }
              if (idx == 1) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
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
                          icon: Icon(Icons.refresh_rounded, size: 18, color: p.inkMuted),
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                );
              }

              final sec = visibleSections[idx - 2];
              final secTitle = '${sec['hour'] ?? sec['title'] ?? ''}';
              final secRef = '${sec['ref'] ?? ''}';
              final secBody = '${sec['text'] ?? sec['arabic'] ?? ''}';
              final secCop = '${sec['coptic'] ?? ''}';
              final secAb = '${sec['arabized'] ?? ''}';

              return GestureDetector(
                onLongPress: () => _copyText('$secTitle\n$secBody'),
                child: Container(
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  secTitle,
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: p.crimson,
                                  ),
                                ),
                                if (secRef.isNotEmpty)
                                  Text(
                                    secRef,
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      color: p.accent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SpeechPlayStopButton(
                            textToSpeak: '$secTitle. ${secBody.length > 1800 ? secBody.substring(0, 1800) : secBody}',
                            label: secTitle,
                            playText: 'استماع',
                            stopText: 'إيقاف',
                            compact: true,
                          ),
                        ],
                      ),
                      if (secCop.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          secCop,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontFamily: 'Coptic',
                            fontSize: 14 * fontScale,
                            color: p.accent,
                            height: 1.5,
                          ),
                        ),
                      ],
                      if (secAb.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          secAb,
                          style: GoogleFonts.cairo(
                            fontSize: 12.5 * fontScale,
                            fontWeight: FontWeight.w600,
                            color: p.inkMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Text(secBody, style: bodyStyle),
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

  // ==================== TAB 3: ALL COPTIC FEASTS & MOVABLE CALCULATOR ====================
  Widget _buildFeastsTab(AppPalette p, List<Map<String, dynamic>> movable) {
    final filteredFixed =
        _fixedFeasts.where((f) => f['group'] == _feastFilter).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 95),
      children: [
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
                      : (isFast ? p.crimson.withValues(alpha: 0.45) : p.border),
                  width: isMajor ? 1.3 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isMajor
                        ? Icons.auto_awesome_rounded
                        : (isFast ? Icons.nights_stay_rounded : Icons.church_rounded),
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
                          style: GoogleFonts.cairo(fontSize: 12, color: p.inkMuted),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
