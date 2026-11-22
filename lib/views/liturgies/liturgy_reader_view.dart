import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/coptic_calendar_service.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../models/hymn_model.dart';
import '../../models/liturgy_model.dart';
import '../../providers/church_mode_provider.dart';
import '../../providers/liturgy_provider.dart';
import '../../providers/theme_provider.dart';
import '../hymns/hymn_detail_view.dart';

/// Museum-Grade Illuminated Coptic Kholagy Reader:
/// - 4 Instant Liturgical Styles:
///   1) `kholagy_book` (Illuminated printed Kholagy manuscript: crimson rubrics, gilded people responses)
///   2) `coptic_reader` (Side-by-side 2-column Arabic | Arabized + Bohairic Coptic Unicode)
///   3) `tri` (Stacked Arabic + Arabized + Coptic Unicode)
///   4) `arabic` (Pure calm Arabic reading)
/// - Live Liturgical Milestone Stepper + Quick-Jump Index Sheet
/// - Live Embedded Daily Readings (Pauline, Catholic, Acts, Psalm & Gospel)
/// - Live Embedded Full Today's Synaxarium with automatic 5:00 PM Vespers rollover
/// - 39 Seasonal Fractions Picker + Direct Liturgical Hymn Audio Jump
/// - Full Adaptive Warm Parchment Daylight, Charcoal Night & AMOLED Sanctuary Mode
class LiturgyReaderView extends StatefulWidget {
  final int initialSectionIndex;

  const LiturgyReaderView({
    super.key,
    this.initialSectionIndex = 0,
  });

  @override
  State<LiturgyReaderView> createState() => _LiturgyReaderViewState();
}

class _LiturgyReaderViewState extends State<LiturgyReaderView> {
  double _fontSize = 18.5;
  String _activeRoleFilter = 'all'; // 'all' | 'people' | 'priest' | 'deacon'
  String _layoutMode = 'kholagy_book'; // 'kholagy_book' | 'coptic_reader' | 'tri' | 'arabic'
  bool _showSilentPrayers = false;
  bool _showRubrics = true;
  bool _synaxariumExpanded = true;
  int _activeMilestoneIdx = 0;

  // Auto-scroll
  bool _isAutoScrolling = false;
  final double _autoScrollSpeed = 1.0;
  Timer? _autoScrollTimer;
  Timer? _clockWatcher;

  // Live liturgical date (5:00 PM Vespers rollover), readings, synaxarium, hymns, seasonal fractions
  late CopticDate _copticToday;
  bool _isAfterVespers = false;
  Map<String, Map<String, String>> _dailyReadings = {};
  List<Map<String, dynamic>> _seasonalFractions = [];
  Map<String, dynamic>? _selectedSeasonalFraction;
  List<Hymn> _cachedHymns = [];

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _sectionKeys = {};
  bool _didInitialJump = false;

  @override
  void initState() {
    super.initState();
    _copticToday = CopticCalendarService.todayLiturgical();
    _isAfterVespers = CopticCalendarService.isAfterVespers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAllLiturgicalData();
    });
    _clockWatcher = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final latest = CopticCalendarService.todayLiturgical();
      if (latest.month != _copticToday.month || latest.day != _copticToday.day) {
        setState(() {
          _copticToday = latest;
          _isAfterVespers = CopticCalendarService.isAfterVespers();
        });
        _reloadDailyReadings();
      }
    });
  }

  Future<void> _loadAllLiturgicalData() async {
    final prov = context.read<LiturgyProvider>();
    await Future.wait([
      prov.loadLiturgies(),
      _reloadDailyReadings(),
      _loadSeasonalFractions(),
      _loadLiturgicalHymns(),
    ]);
    if (!mounted) return;
    if (widget.initialSectionIndex > 0 && !_didInitialJump) {
      _didInitialJump = true;
      Future.delayed(const Duration(milliseconds: 220), () {
        if (mounted) _jumpToSection(widget.initialSectionIndex);
      });
    }
  }

  Future<void> _reloadDailyReadings() async {
    final readings = await CopticCalendarService.getResolvedLiturgyReadings();
    if (mounted) {
      setState(() => _dailyReadings = readings);
    }
  }

  Future<void> _loadSeasonalFractions() async {
    try {
      final raw = await rootBundle.loadString('assets/data/seasonal_fractions.json');
      final list = (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)).toList();
      if (mounted) setState(() => _seasonalFractions = list);
    } catch (_) {}
  }

  Future<void> _loadLiturgicalHymns() async {
    try {
      final raw = await rootBundle.loadString('assets/data/hymns.json');
      final list = jsonDecode(raw) as List;
      _cachedHymns = list.map((e) => Hymn.fromJson(e)).toList();
    } catch (_) {}
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _clockWatcher?.cancel();
    SpeechPronunciationService().stop();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleAutoScroll() {
    HapticFeedback.selectionClick();
    setState(() => _isAutoScrolling = !_isAutoScrolling);
    _autoScrollTimer?.cancel();
    if (_isAutoScrolling) {
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (!_scrollController.hasClients) return;
        final maxExtent = _scrollController.position.maxScrollExtent;
        final current = _scrollController.offset;
        if (current >= maxExtent) {
          setState(() => _isAutoScrolling = false);
          _autoScrollTimer?.cancel();
        } else {
          _scrollController.jumpTo((current + (1.1 * _autoScrollSpeed)).clamp(0.0, maxExtent));
        }
      });
    }
  }

  void _jumpToSection(int idx) {
    setState(() => _activeMilestoneIdx = idx);
    final key = _sectionKeys[idx];
    final ctx = key?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.02,
      );
    }
  }

  Hymn? _matchLiturgicalHymn(LiturgyVerse verse) {
    if (_cachedHymns.isEmpty || verse.role != 'people') return null;
    final ar = verse.arabic;
    final ab = verse.arabized;
    String? kw;
    if (ar.contains('قدوس الله قدوس القوي') || ab.contains('أجيوس')) {
      kw = 'أجيوس';
    } else if (ar.contains('بشفاعات والدة الإله') || ab.contains('هيتين')) {
      kw = 'هيتني';
    } else if (ar.contains('الشاروبيم يسجدون')) {
      kw = 'الشاروبيم';
    } else if (ar.contains('بموتك يا رب نبشر')) {
      kw = 'بموتك';
    } else if (ar.contains('سبحوا الله في جميع قديسيه')) {
      kw = '150';
    } else if (ar.contains('نسجد لآب النور')) {
      kw = 'تين أوأوشت';
    }
    if (kw == null) return null;
    for (final h in _cachedHymns) {
      if (h.title.contains(kw)) return h;
    }
    return null;
  }

  void _showLiturgicalIndexSheet(Liturgy liturgy) {
    HapticFeedback.mediumImpact();
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.78,
            decoration: BoxDecoration(
              color: p.surface,
              border: Border(top: BorderSide(color: p.border)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                  child: Row(
                    children: [
                      CopticCross(size: 18, color: p.isDark ? p.gold : p.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'خريطة ومحطات القداس الإلهي',
                              style: GoogleFonts.amiri(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: p.ink,
                              ),
                            ),
                            Text(
                              '${liturgy.title} • ${_copticToday.formatted}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkMuted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: p.inkMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Divider(color: p.border, height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: liturgy.sections.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, idx) {
                      final sec = liturgy.sections[idx];
                      final isSynax = sec.title.contains('السنكسار');
                      final isActive = idx == _activeMilestoneIdx;
                      return Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isActive || isSynax ? p.goldBorder : p.border,
                              width: isActive ? 1.4 : 1,
                            ),
                          ),
                          tileColor: isActive || isSynax ? p.goldSoft : p.surfaceSubtle,
                          leading: Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? p.accent : p.surface,
                              border: Border.all(color: p.goldBorder),
                            ),
                            child: Text(
                              '${idx + 1}',
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isActive ? p.onAccent : p.ink,
                              ),
                            ),
                          ),
                          title: Text(
                            sec.title,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: p.ink,
                            ),
                          ),
                          subtitle: sec.tafseer.isNotEmpty
                              ? Text(
                                  sec.tafseer,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
                                )
                              : null,
                          trailing: Icon(Icons.chevron_left_rounded, color: p.accent, size: 18),
                          onTap: () {
                            Navigator.pop(ctx);
                            _jumpToSection(idx);
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
      },
    );
  }

  void _showLiturgySwitcher(LiturgyProvider prov) {
    HapticFeedback.selectionClick();
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'اختر القداس الإلهي (الخولاجي المقدس)',
              style: GoogleFonts.amiri(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 12),
            for (final lit in prov.liturgies) ...[
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: prov.selectedLiturgy?.id == lit.id ? p.accent : p.border,
                    width: prov.selectedLiturgy?.id == lit.id ? 1.5 : 1,
                  ),
                ),
                tileColor: prov.selectedLiturgy?.id == lit.id ? p.goldSoft : p.surfaceSubtle,
                leading: CopticCross(size: 18, color: p.isDark ? p.gold : p.accent),
                title: Text(
                  lit.title,
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: p.ink,
                  ),
                ),
                trailing: prov.selectedLiturgy?.id == lit.id
                    ? Icon(Icons.check_circle_rounded, color: p.accent)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  prov.selectLiturgy(lit);
                  setState(() {
                    _selectedSeasonalFraction = null;
                    _activeMilestoneIdx = 0;
                  });
                  if (_scrollController.hasClients) _scrollController.jumpTo(0);
                },
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  void _showDisplaySettingsSheet() {
    HapticFeedback.selectionClick();
    final churchMode = context.read<ChurchModeProvider>();
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ستايل الخولاجي وإعدادات القراءة',
                style: GoogleFonts.amiri(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text('نمط العرض واللغة:', style: GoogleFonts.cairo(fontSize: 12, color: p.inkMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _settingChip(p, 'الخولاجي المطبوع (عربي + معرب)', _layoutMode == 'kholagy_book', () {
                    setState(() => _layoutMode = 'kholagy_book');
                    setSheet(() {});
                  }),
                  _settingChip(p, 'أعمدة متوازية (Coptic Reader)', _layoutMode == 'coptic_reader', () {
                    setState(() => _layoutMode = 'coptic_reader');
                    setSheet(() {});
                  }),
                  _settingChip(p, 'ثلاثي (عربي + معرب + قبطي)', _layoutMode == 'tri', () {
                    setState(() => _layoutMode = 'tri');
                    setSheet(() {});
                  }),
                  _settingChip(p, 'عربي فقط', _layoutMode == 'arabic', () {
                    setState(() => _layoutMode = 'arabic');
                    setSheet(() {});
                  }),
                ],
              ),
              const SizedBox(height: 14),
              Text('تصفية المتكلم:', style: GoogleFonts.cairo(fontSize: 12, color: p.inkMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _settingChip(p, 'الكل', _activeRoleFilter == 'all', () {
                    setState(() => _activeRoleFilter = 'all');
                    setSheet(() {});
                  }),
                  _settingChip(p, 'مردات الشعب', _activeRoleFilter == 'people', () {
                    setState(() => _activeRoleFilter = 'people');
                    setSheet(() {});
                  }),
                  _settingChip(p, 'الكاهن', _activeRoleFilter == 'priest', () {
                    setState(() => _activeRoleFilter = 'priest');
                    setSheet(() {});
                  }),
                  _settingChip(p, 'الشماس', _activeRoleFilter == 'deacon', () {
                    setState(() => _activeRoleFilter = 'deacon');
                    setSheet(() {});
                  }),
                ],
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: p.accent,
                title: Text('إظهار الصلوات السرية للكاهن',
                    style: GoogleFonts.cairo(fontSize: 13.5, color: p.ink)),
                value: _showSilentPrayers,
                onChanged: (v) {
                  setState(() => _showSilentPrayers = v);
                  setSheet(() {});
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: p.accent,
                title: Text('إظهار الإرشادات الطقسية (الخولاجي)',
                    style: GoogleFonts.cairo(fontSize: 13.5, color: p.ink)),
                value: _showRubrics,
                onChanged: (v) {
                  setState(() => _showRubrics = v);
                  setSheet(() {});
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: p.accent,
                title: Text('وضع المذبح المعتم (AMOLED)',
                    style: GoogleFonts.cairo(fontSize: 13.5, color: p.ink)),
                value: churchMode.isChurchMode,
                onChanged: (_) {
                  churchMode.toggleChurchMode();
                  setSheet(() {});
                },
              ),
              Row(
                children: [
                  Text('حجم الخط:', style: GoogleFonts.cairo(fontSize: 12.5, color: p.inkMuted)),
                  Expanded(
                    child: Slider(
                      value: _fontSize,
                      min: 14.0,
                      max: 26.0,
                      activeColor: p.accent,
                      onChanged: (v) {
                        setState(() => _fontSize = v);
                        setSheet(() {});
                      },
                    ),
                  ),
                  Text('${_fontSize.round()}',
                      style: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold, color: p.accent)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingChip(AppPalette p, String label, bool active, VoidCallback onTap) {
    return ChoiceChip(
      showCheckmark: false,
      label: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 11.5,
          fontWeight: active ? FontWeight.bold : FontWeight.w500,
          color: active ? p.onAccent : p.ink,
        ),
      ),
      selected: active,
      selectedColor: p.accent,
      backgroundColor: p.surfaceSubtle,
      side: BorderSide(color: active ? p.accent : p.border),
      onSelected: (_) => onTap(),
    );
  }

  void _showSeasonalFractionPicker() {
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.76,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                children: [
                  CopticCross(size: 16, color: p.isDark ? p.gold : p.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'صلوات القسمة السنوية والموسمية (${_seasonalFractions.length})',
                      style: GoogleFonts.amiri(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                      ),
                    ),
                  ),
                  if (_selectedSeasonalFraction != null)
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedSeasonalFraction = null);
                        Navigator.pop(ctx);
                      },
                      child: Text('الأصلية', style: GoogleFonts.cairo(fontSize: 12, color: p.accent)),
                    ),
                ],
              ),
            ),
            Divider(color: p.border, height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _seasonalFractions.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, idx) {
                  final frac = _seasonalFractions[idx];
                  final isSel = _selectedSeasonalFraction?['title'] == frac['title'];
                  return ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: isSel ? p.accent : p.border),
                    ),
                    tileColor: isSel ? p.goldSoft : p.surfaceSubtle,
                    title: Text(
                      '${frac['title']}',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSel ? p.accent : p.ink,
                      ),
                    ),
                    subtitle: Text(
                      '${frac['text']}'.replaceAll('\n', ' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
                    ),
                    onTap: () {
                      setState(() => _selectedSeasonalFraction = frac);
                      Navigator.pop(ctx);
                    },
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
    final prov = context.watch<LiturgyProvider>();
    final fontScale = context.watch<ThemeProvider>().fontScale;

    if (prov.isLoading || prov.selectedLiturgy == null) {
      return Scaffold(
        backgroundColor: p.canvas,
        body: Center(child: CircularProgressIndicator(color: p.accent, strokeWidth: 2)),
      );
    }

    final liturgy = prov.selectedLiturgy!;
    final shortTitle = liturgy.id == 'liturgy_basil'
        ? 'القداس الباسيلي'
        : (liturgy.id == 'liturgy_gregory' ? 'القداس الغريغوري' : 'القداس الكيرلسي');

    for (int i = 0; i < liturgy.sections.length; i++) {
      _sectionKeys.putIfAbsent(i, () => GlobalKey());
    }

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        foregroundColor: p.ink,
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () => _showLiturgySwitcher(prov),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    shortTitle,
                    style: GoogleFonts.amiri(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, color: p.accent, size: 20),
                ],
              ),
              Text(
                '${_copticToday.formatted}${_isAfterVespers ? ' • توقيت عشية' : ''}',
                style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
              ),
            ],
          ),
        ),
        actions: [
          // 1-Tap Kholagy Style Switcher Pill
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              const order = ['kholagy_book', 'coptic_reader', 'tri', 'arabic'];
              final next = order[(order.indexOf(_layoutMode) + 1) % order.length];
              setState(() => _layoutMode = next);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: p.goldSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.goldBorder),
              ),
              alignment: Alignment.center,
              child: Text(
                _layoutMode == 'kholagy_book'
                    ? 'خولاجي'
                    : _layoutMode == 'coptic_reader'
                        ? 'عمودان'
                        : _layoutMode == 'tri'
                            ? 'ثلاثي'
                            : 'عربي',
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: p.isDark ? p.gold : p.accent,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: _isAutoScrolling ? 'إيقاف التمرير التلقائي' : 'تمرير تلقائي أثناء القداس',
            icon: Icon(
              _isAutoScrolling ? Icons.pause_circle_filled_rounded : Icons.play_circle_outline_rounded,
              color: _isAutoScrolling ? p.accent : p.inkMuted,
              size: 22,
            ),
            onPressed: _toggleAutoScroll,
          ),
          IconButton(
            tooltip: 'إعدادات العرض واللغة',
            icon: Icon(Icons.tune_rounded, color: p.ink, size: 21),
            onPressed: _showDisplaySettingsSheet,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Interactive Liturgical Milestone Stepper Ribbon
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: p.surface,
              border: Border(
                top: BorderSide(color: p.border, width: 0.8),
                bottom: BorderSide(color: p.border, width: 0.8),
              ),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              itemCount: liturgy.sections.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (_, idx) {
                final raw = liturgy.sections[idx].title;
                final compact = _compactMilestoneLabel(raw);
                final active = idx == _activeMilestoneIdx;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _jumpToSection(idx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 3),
                    decoration: BoxDecoration(
                      color: active ? p.accent : p.surfaceSubtle,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: active ? p.accent : p.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${idx + 1}. $compact',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: active ? FontWeight.bold : FontWeight.w600,
                          color: active ? p.onAccent : p.ink,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Continuous Flowing Illuminated Kholagy Book
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 740),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (int sIdx = 0; sIdx < liturgy.sections.length; sIdx++) ...[
                        _buildSectionBlock(p, liturgy.sections[sIdx], sIdx, fontScale),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: p.accent,
        foregroundColor: p.onAccent,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.format_list_numbered_rtl_rounded, size: 19),
        label: Text(
          'فهرس القداس',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.5),
        ),
        onPressed: () => _showLiturgicalIndexSheet(liturgy),
      ),
    );
  }

  String _compactMilestoneLabel(String fullTitle) {
    if (fullTitle.contains('تقدمة الحمل')) return 'الحمل';
    if (fullTitle.contains('تحليل الخدام')) return 'التحليل';
    if (fullTitle.contains('البولس')) return 'القراءات';
    if (fullTitle.contains('السنكسار')) return 'السنكسار';
    if (fullTitle.contains('أجيوس')) return 'الإنجيل';
    if (fullTitle.contains('الصلح')) return 'الصلح';
    if (fullTitle.contains('الأنافورا') || fullTitle.contains('التسبحة الشاروبيمية')) {
      return fullTitle.contains('التسبحة') ? 'التقديس' : 'الأنافورا';
    }
    if (fullTitle.contains('أواشي') || fullTitle.contains('المجمع')) return 'المجمع';
    if (fullTitle.contains('القسمة')) return 'القسمة';
    if (fullTitle.contains('الخضوع') || fullTitle.contains('الاعتراف')) return 'الاعتراف';
    if (fullTitle.contains('التناول')) return 'التناول';
    return fullTitle.length > 14 ? fullTitle.substring(0, 14) : fullTitle;
  }

  Widget _buildSectionBlock(AppPalette p, LiturgySection sec, int sIdx, double fontScale) {
    return Column(
      key: _sectionKeys[sIdx],
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Illuminated Printed Kholagy Section Banner
        Padding(
          padding: EdgeInsets.only(top: sIdx == 0 ? 6 : 26, bottom: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              color: p.goldSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.goldBorder, width: 1.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CopticCross(size: 14, color: p.isDark ? p.gold : p.accent),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        sec.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 21 * fontScale.clamp(0.85, 1.3),
                          fontWeight: FontWeight.bold,
                          color: p.isDark ? p.gold : p.crimson,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CopticCross(size: 14, color: p.isDark ? p.gold : p.accent),
                  ],
                ),
                if (sec.tafseer.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    sec.tafseer,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkSecondary),
                  ),
                ],
              ],
            ),
          ),
        ),

        for (final v in sec.verses) ...[
          if (v.role == 'reading_slot')
            _buildDynamicLiturgicalSlot(p, v.arabic, fontScale)
          else if (_shouldShowVerse(v))
            _buildFlowingLiturgicalLine(p, v, fontScale),
        ],
      ],
    );
  }

  bool _shouldShowVerse(LiturgyVerse v) {
    if (v.role == 'priest_silent' && !_showSilentPrayers) return false;
    if (v.role == 'rubric' && !_showRubrics) return false;
    if (_activeRoleFilter == 'all') return true;
    if (v.role == 'rubric') return _showRubrics;
    if (_activeRoleFilter == 'priest') {
      return v.role == 'priest' || v.role == 'priest_silent';
    }
    return v.role == _activeRoleFilter;
  }

  Widget _buildDynamicLiturgicalSlot(AppPalette p, String slotKey, double fontScale) {
    switch (slotKey) {
      case 'LITURGY_PAULINE_SLOT':
        return _buildEmbeddedScriptureBlock(
          p: p,
          title: 'قراءة البولس (رسالة معلمنا بولس الرسول)',
          reading: _dailyReadings['pauline'],
          opening: 'بُولُسُ عَبْدُ يَسُوعَ الْمَسِيحِ، الْمَدْعُوُّ رَسُولاً، الْمُفْرَزُ لإِنْجِيلِ اللهِ:',
          closing: 'نِعْمَةُ اللهِ الآبِ تَحِلُّ عَلَى أَرْوَاحِنَا يَا آبَائِي وَإِخْوَتِي. آمِينَ.',
          fontScale: fontScale,
        );
      case 'LITURGY_CATHOLIC_SLOT':
        return _buildEmbeddedScriptureBlock(
          p: p,
          title: 'قراءة الكاثوليكون (رسالة الجامعة)',
          reading: _dailyReadings['catholic'],
          opening: 'الكاثوليكون، فَصْلٌ مِنْ رِسَالَةِ مُعَلِّمِنَا الرَّسُولِ بَرَكَتُهُ عَلَيْنَا آمِينَ:',
          closing: 'لاَ تُحِبُّوا الْعَالَمَ وَلاَ الأَشْيَاءَ الَّتِي فِي الْعَالَمِ، لأَنَّ الْعَالَمَ يَمْضِي وَشَهْوَتَهُ، وَأَمَّا الَّذِي يَصْنَعُ مَشِيئَةَ اللهِ فَيَثْبُتُ إِلَى الأَبَدِ. آمِينَ.',
          fontScale: fontScale,
        );
      case 'LITURGY_ACTS_SLOT':
        return _buildEmbeddedScriptureBlock(
          p: p,
          title: 'قراءة الإبركسيس (أعمال آبائنا الرسل)',
          reading: _dailyReadings['acts'],
          opening: 'فَصْلٌ مِنْ أَعْمَالِ آبَائِنَا الرُّسُلِ الأَطْهَارِ الْمَشْمُولِينَ بِنِعْمَةِ الرُّوحِ الْقُدُسِ، بَرَكَتُهُمْ تَكُونُ مَعَنَا آمِينَ:',
          closing: 'لَمْ تَزَلْ كَلِمَةُ الرَّبِّ تَنْمُو وَتَزْدَادُ وَتَعْتَزُّ وَتَثْبُتُ فِي هذِهِ الْكَنِيسَةِ وَكُلِّ كَنِيسَةٍ. آمِينَ.',
          fontScale: fontScale,
        );
      case 'LITURGY_SYNAXARIUM_SLOT':
        return _buildInlineFullSynaxariumBlock(p, fontScale);
      case 'LITURGY_GOSPEL_SLOT':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEmbeddedScriptureBlock(
              p: p,
              title: 'مزمور القداس الإلهي لليوم',
              reading: _dailyReadings['psalm'],
              opening: 'مِنْ مَزَامِيرِ وَتَرَاتِيلِ أَبِينَا دَاوُدَ النَّبِيِّ، بَرَكَتُهُ عَلَيْنَا آمِينَ:',
              closing: 'هَلِّلُويَا.',
              fontScale: fontScale,
            ),
            _buildEmbeddedScriptureBlock(
              p: p,
              title: 'الإنجيل المقدس لليوم',
              reading: _dailyReadings['gospel'],
              opening: 'مُبَارَكٌ الآتِي بِاسْمِ الرَّبِّ. فَصْلٌ شَرِيفٌ مِنْ بِشَارَةِ الإِنْجِيلِ الْمُقَدَّسِ:',
              closing: 'وَالْمَجْدُ للهِ دَائِماً أَبَدِيّاً. آمِينَ.',
              fontScale: fontScale,
              isGospel: true,
            ),
          ],
        );
      case 'LITURGY_FRACTION_PICKER_SLOT':
        return _buildFractionPickerInline(p, fontScale);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmbeddedScriptureBlock({
    required AppPalette p,
    required String title,
    required Map<String, String>? reading,
    required String opening,
    required String closing,
    required double fontScale,
    bool isGospel = false,
  }) {
    final ref = reading?['ref'] ?? 'قراءة اليوم (${_copticToday.formatted})';
    final body = reading?['text'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isGospel ? p.goldBorder : p.border,
          width: isGospel ? 1.4 : 1,
        ),
        boxShadow: p.isDark
            ? null
            : [
                BoxShadow(
                  color: p.shadow,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isGospel ? Icons.auto_stories_rounded : Icons.menu_book_outlined,
                color: isGospel ? p.crimson : p.gold,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                      ),
                    ),
                    Text(
                      ref,
                      style: GoogleFonts.cairo(fontSize: 11.5, color: p.accent, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (body.isNotEmpty)
                SpeechPlayStopButton(
                  textToSpeak: '$opening $body $closing',
                  label: title,
                  playText: 'استماع',
                  stopText: 'إيقاف',
                  compact: true,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            opening,
            style: GoogleFonts.amiri(
              fontSize: (_fontSize - 1) * fontScale,
              color: p.crimson,
              fontWeight: FontWeight.w600,
              height: 1.55,
            ),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              body,
              style: GoogleFonts.amiri(
                fontSize: (_fontSize + 1) * fontScale,
                height: 1.9,
                color: p.ink,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            closing,
            style: GoogleFonts.amiri(
              fontSize: (_fontSize - 0.5) * fontScale,
              fontWeight: FontWeight.bold,
              color: p.accent,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineFullSynaxariumBlock(AppPalette p, double fontScale) {
    final events = CopticCalendarService.getSynaxariumEventsForDate(
      _copticToday.month,
      _copticToday.day,
    );
    final fullText = CopticCalendarService.getSynaxariumForDate(
      _copticToday.month,
      _copticToday.day,
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.goldBorder, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CopticCross(size: 18, color: p.isDark ? p.gold : p.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سنكسار اليوم: ${_copticToday.day} ${_copticToday.monthName} ${_copticToday.year} ش',
                      style: GoogleFonts.amiri(
                        fontSize: 19 * fontScale.clamp(0.85, 1.3),
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                      ),
                    ),
                    Text(
                      _isAfterVespers
                          ? 'تذكار اليوم التالي تلقائياً (توقيت عشية بعد ٥ مساءً)'
                          : 'يُقرأ عقب الإبركسيس وقبل أجيوس والإنجيل',
                      style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: _synaxariumExpanded ? 'طي السنكسار' : 'عرض السنكسار كاملاً',
                icon: Icon(
                  _synaxariumExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: p.accent,
                ),
                onPressed: () => setState(() => _synaxariumExpanded = !_synaxariumExpanded),
              ),
            ],
          ),
          if (_synaxariumExpanded) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                SpeechPlayStopButton(
                  textToSpeak: fullText,
                  label: 'سنكسار اليوم',
                  playText: 'استماع للسنكسار',
                  stopText: 'إيقاف',
                  compact: true,
                ),
                const Spacer(),
                Text(
                  '${events.length} تذكار اليوم',
                  style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'باسم الآب والابن والروح القدس الإله الواحد آمين. اليوم ${_copticToday.day} من شهر ${_copticToday.monthName} المبارك:',
              style: GoogleFonts.amiri(
                fontSize: (_fontSize - 1) * fontScale,
                fontWeight: FontWeight.bold,
                color: p.crimson,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 10),
            for (int i = 0; i < events.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: p.border, height: 1),
                ),
              Text(
                '${i + 1}. ${events[i]['title']}',
                style: GoogleFonts.amiri(
                  fontSize: (_fontSize + 1) * fontScale,
                  fontWeight: FontWeight.bold,
                  color: p.accent,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                '${events[i]['text']}'.trim(),
                style: GoogleFonts.amiri(
                  fontSize: _fontSize * fontScale,
                  height: 1.85,
                  color: p.ink,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'بركة صلواتهم وشفاعتهم فلتكن معنا جميعاً، ولربنا المجد دائماً أبدياً. آمين.',
              style: GoogleFonts.amiri(
                fontSize: (_fontSize - 0.5) * fontScale,
                fontWeight: FontWeight.bold,
                color: p.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFractionPickerInline(AppPalette p, double fontScale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_outlined, color: p.gold, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedSeasonalFraction != null
                      ? 'القسمة المختارة: ${_selectedSeasonalFraction!['title']}'
                      : 'اختر قسمة الموسم أو العيد حسب طقس اليوم',
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: p.ink,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: _seasonalFractions.isEmpty ? null : _showSeasonalFractionPicker,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  side: BorderSide(color: p.goldBorder),
                  backgroundColor: p.goldSoft,
                ),
                child: Text(
                  'تبديل القسمة',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: p.isDark ? p.gold : p.accent,
                  ),
                ),
              ),
            ],
          ),
          if (_selectedSeasonalFraction != null) ...[
            const SizedBox(height: 12),
            Divider(color: p.border, height: 1),
            const SizedBox(height: 10),
            Text(
              'الكاهن • ${_selectedSeasonalFraction!['title']}',
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: p.crimson,
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              '${_selectedSeasonalFraction!['text']}',
              style: GoogleFonts.amiri(
                fontSize: _fontSize * fontScale,
                height: 1.85,
                color: p.ink,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFlowingLiturgicalLine(AppPalette p, LiturgyVerse verse, double fontScale) {
    // 1. Authentic Rubric Line (traditional red ink of printed Kholagy)
    if (verse.role == 'rubric') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(
          verse.arabic,
          style: GoogleFonts.cairo(
            fontSize: (_fontSize - 5.5).clamp(11.5, 16.0) * fontScale,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            color: p.crimson,
            height: 1.55,
          ),
        ),
      );
    }

    final bool isSilent = verse.role == 'priest_silent';
    final bool isPriest = verse.role == 'priest' || isSilent;
    final bool isDeacon = verse.role == 'deacon';
    final bool isPeople = verse.role == 'people';

    final Color roleColor = isSilent
        ? const Color(0xFF7D61A8)
        : (isPriest
            ? p.crimson
            : (isDeacon ? const Color(0xFF3E6D96) : (p.isDark ? p.gold : p.accent)));

    final String roleLabel = verse.roleArabic.isNotEmpty
        ? verse.roleArabic
        : (isPriest ? 'الكاهن' : (isDeacon ? 'الشماس' : 'الشعب'));

    final matchedHymn = _matchLiturgicalHymn(verse);
    final hasArabized = verse.arabized.isNotEmpty;
    final hasCoptic = verse.coptic.isNotEmpty && verse.coptic != verse.arabized;

    final Color? blockBg = isSilent
        ? p.surfaceSubtle
        : (isPeople && _layoutMode == 'kholagy_book'
            ? p.goldSoft.withValues(alpha: p.isDark ? 0.55 : 0.65)
            : null);

    return Container(
      padding: EdgeInsets.fromLTRB(
        isPeople || isSilent ? 14 : 6,
        11,
        isPeople || isSilent ? 14 : 6,
        12,
      ),
      margin: EdgeInsets.symmetric(vertical: isPeople || isSilent ? 5 : 1),
      decoration: BoxDecoration(
        color: blockBg,
        borderRadius: isPeople || isSilent ? BorderRadius.circular(14) : null,
        border: isSilent
            ? Border.all(color: p.border)
            : isPeople && _layoutMode == 'kholagy_book'
                ? Border.all(color: p.goldBorder.withValues(alpha: 0.7))
                : Border(
                    bottom: BorderSide(color: p.border.withValues(alpha: 0.65), width: 0.7),
                  ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: p.isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  roleLabel,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: roleColor,
                  ),
                ),
              ),
              const Spacer(),
              if (matchedHymn != null)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.push(
                      context,
                      luxeRoute(HymnDetailView(hymn: matchedHymn, playlist: _cachedHymns)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.goldBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.music_note_rounded, size: 13, color: p.accent),
                        const SizedBox(width: 4),
                        Text(
                          'سماع اللحن',
                          style: GoogleFonts.cairo(
                            fontSize: 10.5,
                            color: p.ink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),

          // Mode A: Parallel 2-Column Coptic Reader Style
          if (_layoutMode == 'coptic_reader' && (hasArabized || hasCoptic))
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 11,
                    child: SelectableText(
                      verse.arabic,
                      style: GoogleFonts.amiri(
                        fontSize: (_fontSize + 0.5) * fontScale,
                        height: 1.8,
                        color: p.ink,
                        fontWeight: isPeople ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: p.border,
                  ),
                  Expanded(
                    flex: 9,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (hasArabized)
                          SelectableText(
                            verse.arabized,
                            style: GoogleFonts.cairo(
                              fontSize: (_fontSize - 3.5).clamp(12.0, 20.0) * fontScale,
                              height: 1.65,
                              color: p.gold,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        if (hasCoptic) ...[
                          if (hasArabized) const SizedBox(height: 6),
                          SelectableText(
                            verse.coptic,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontFamily: 'Coptic',
                              fontSize: (_fontSize - 3.0).clamp(12.0, 20.0) * fontScale,
                              height: 1.55,
                              color: p.inkSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Mode B: Printed Illuminated Kholagy Book / Tri / Pure Arabic
            SelectableText(
              verse.arabic,
              style: GoogleFonts.amiri(
                fontSize: (_fontSize + 1.5) * fontScale,
                height: 1.85,
                color: p.ink,
                fontWeight: isPeople ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if ((_layoutMode == 'kholagy_book' || _layoutMode == 'tri') && hasArabized) ...[
              const SizedBox(height: 5),
              SelectableText(
                verse.arabized,
                style: GoogleFonts.cairo(
                  fontSize: (_fontSize - 3.2).clamp(12.5, 20.0) * fontScale,
                  height: 1.65,
                  color: p.gold,
                ),
              ),
            ],
            if (_layoutMode == 'tri' && hasCoptic) ...[
              const SizedBox(height: 5),
              SelectableText(
                verse.coptic,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontFamily: 'Coptic',
                  fontSize: (_fontSize - 2.5).clamp(12.5, 20.0) * fontScale,
                  height: 1.55,
                  color: p.inkSecondary,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
