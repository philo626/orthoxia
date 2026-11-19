import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/coptic_calendar_service.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../models/hymn_model.dart';
import '../../models/liturgy_model.dart';
import '../../providers/church_mode_provider.dart';
import '../../providers/liturgy_provider.dart';
import '../../providers/theme_provider.dart';
import '../hymns/hymn_detail_view.dart';

/// Authentic Continuous Coptic Orthodox Divine Liturgy Reader modeled directly on
/// Coptic Reader & Orsozoxi (أرثوذكسي):
/// - Continuous uninterrupted flow from Offering of the Lamb to Final Blessing
/// - Instant Quick-Jump Index Drawer for all 11 canonical liturgical milestones
/// - Authentic side-by-side Coptic Reader 2-column mode OR clean Orsozoxi stacked mode
/// - Live embedded TODAY'S Readings (Pauline, Catholic, Acts, Psalm & Gospel) from Smith & Van Dyck Bible
/// - Live embedded FULL TODAY'S SYNAXARIUM right in its canonical place (after Acts, before Agios),
///   automatically advancing at 5:00 PM (Vespers / عشية)
/// - 1-tap Seasonal Fractions Picker (39 fractions) right at the Fraction milestone.
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
  String _layoutMode = 'orsozoxi'; // 'orsozoxi' (Ar+Arabized) | 'coptic_reader' (2-col) | 'arabic' | 'tri'
  bool _showSilentPrayers = false;
  bool _showRubrics = true;
  bool _synaxariumExpanded = true;

  // Auto-scroll
  bool _isAutoScrolling = false;
  double _autoScrollSpeed = 1.0;
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: Container(
            height: MediaQuery.of(ctx).size.height * 0.78,
            decoration: const BoxDecoration(
              color: AppColors.deepNavy,
              border: Border(top: BorderSide(color: AppColors.hairline)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                  child: Row(
                    children: [
                      const CopticCross(size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'خريطة ومحطات القداس الإلهي',
                              style: GoogleFonts.amiri(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGoldLight,
                              ),
                            ),
                            Text(
                              '${liturgy.title} • ${_copticToday.formatted}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.hairline, height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: liturgy.sections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 7),
                    itemBuilder: (_, idx) {
                      final sec = liturgy.sections[idx];
                      final isSynax = sec.title.contains('السنكسار');
                      return Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSynax
                                  ? AppColors.primaryGold.withValues(alpha: 0.45)
                                  : AppColors.hairline,
                            ),
                          ),
                          tileColor: AppColors.cardNavy,
                          leading: Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surfaceNavy,
                              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                            ),
                            child: Text(
                              '${idx + 1}',
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGoldLight,
                              ),
                            ),
                          ),
                          title: Text(
                            sec.title,
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                          ),
                          subtitle: sec.tafseer.isNotEmpty
                              ? Text(
                                  sec.tafseer,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.textMuted),
                                )
                              : null,
                          trailing: const Icon(Icons.chevron_left_rounded,
                              color: AppColors.primaryGold, size: 18),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.deepNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: AppColors.hairline),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 3.5,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'اختر القداس الإلهي (الخولاجي المقدس)',
              style: GoogleFonts.amiri(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGoldLight,
              ),
            ),
            const SizedBox(height: 12),
            for (final lit in prov.liturgies) ...[
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: prov.selectedLiturgy?.id == lit.id
                        ? AppColors.primaryGold
                        : AppColors.hairline,
                  ),
                ),
                tileColor: prov.selectedLiturgy?.id == lit.id
                    ? AppColors.primaryGold.withValues(alpha: 0.12)
                    : AppColors.cardNavy,
                leading: const CopticCross(size: 18),
                title: Text(
                  lit.title,
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                trailing: prov.selectedLiturgy?.id == lit.id
                    ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGold)
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  prov.selectLiturgy(lit);
                  setState(() => _selectedSeasonalFraction = null);
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.deepNavy,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: AppColors.hairline),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGold.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'إعدادات العرض واللغة (Coptic Reader / أرثوذكسي)',
                style: GoogleFonts.amiri(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGoldLight,
                ),
              ),
              const SizedBox(height: 12),
              Text('نمط العرض واللغة:', style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _settingChip('أرثوذكسي (عربي + معرب)', _layoutMode == 'orsozoxi', () {
                    setState(() => _layoutMode = 'orsozoxi');
                    setSheet(() {});
                  }),
                  _settingChip('Coptic Reader (عمودان)', _layoutMode == 'coptic_reader', () {
                    setState(() => _layoutMode = 'coptic_reader');
                    setSheet(() {});
                  }),
                  _settingChip('عربي فقط', _layoutMode == 'arabic', () {
                    setState(() => _layoutMode = 'arabic');
                    setSheet(() {});
                  }),
                  _settingChip('ثلاثي (عربي + معرب + قبطي)', _layoutMode == 'tri', () {
                    setState(() => _layoutMode = 'tri');
                    setSheet(() {});
                  }),
                ],
              ),
              const SizedBox(height: 14),
              Text('تصفية المتكلم:', style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _settingChip('الكل', _activeRoleFilter == 'all', () {
                    setState(() => _activeRoleFilter = 'all');
                    setSheet(() {});
                  }),
                  _settingChip('الشعب فقط', _activeRoleFilter == 'people', () {
                    setState(() => _activeRoleFilter = 'people');
                    setSheet(() {});
                  }),
                  _settingChip('الكاهن', _activeRoleFilter == 'priest', () {
                    setState(() => _activeRoleFilter = 'priest');
                    setSheet(() {});
                  }),
                  _settingChip('الشماس', _activeRoleFilter == 'deacon', () {
                    setState(() => _activeRoleFilter = 'deacon');
                    setSheet(() {});
                  }),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primaryGold,
                title: Text('إظهار الصلوات السرية للكاهن',
                    style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textLight)),
                value: _showSilentPrayers,
                onChanged: (v) {
                  setState(() => _showSilentPrayers = v);
                  setSheet(() {});
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primaryGold,
                title: Text('إظهار الإرشادات الطقسية (الخولاجي)',
                    style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textLight)),
                value: _showRubrics,
                onChanged: (v) {
                  setState(() => _showRubrics = v);
                  setSheet(() {});
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primaryGold,
                title: Text('وضع الكنيسة المعتم (خفوت الشاشة)',
                    style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textLight)),
                value: churchMode.isChurchMode,
                onChanged: (_) {
                  churchMode.toggleChurchMode();
                  setSheet(() {});
                },
              ),
              Row(
                children: [
                  Text('حجم الخط:', style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.textMuted)),
                  Expanded(
                    child: Slider(
                      value: _fontSize,
                      min: 14.0,
                      max: 26.0,
                      activeColor: AppColors.primaryGold,
                      onChanged: (v) {
                        setState(() => _fontSize = v);
                        setSheet(() {});
                      },
                    ),
                  ),
                  Text('${_fontSize.round()}',
                      style: GoogleFonts.cairo(fontSize: 12, color: AppColors.primaryGoldLight)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingChip(String label, bool active, VoidCallback onTap) {
    return ChoiceChip(
      showCheckmark: false,
      label: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 11.5,
          fontWeight: active ? FontWeight.bold : FontWeight.w500,
          color: active ? Colors.black : AppColors.textLight,
        ),
      ),
      selected: active,
      selectedColor: AppColors.primaryGold,
      backgroundColor: AppColors.cardNavy,
      side: BorderSide(color: active ? AppColors.primaryGold : AppColors.hairline),
      onSelected: (_) => onTap(),
    );
  }

  void _showSeasonalFractionPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.deepNavy,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        side: BorderSide(color: AppColors.hairline),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.76,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
              child: Row(
                children: [
                  const CopticCross(size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'صلوات القسمة السنوية والموسمية (${_seasonalFractions.length})',
                      style: GoogleFonts.amiri(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGoldLight,
                      ),
                    ),
                  ),
                  if (_selectedSeasonalFraction != null)
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedSeasonalFraction = null);
                        Navigator.pop(ctx);
                      },
                      child: Text('القسمة الأصلية',
                          style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.primaryGold)),
                    ),
                ],
              ),
            ),
            const Divider(color: AppColors.hairline, height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _seasonalFractions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, idx) {
                  final frac = _seasonalFractions[idx];
                  final isSel = _selectedSeasonalFraction?['title'] == frac['title'];
                  return ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: isSel ? AppColors.primaryGold : AppColors.hairline),
                    ),
                    tileColor: isSel
                        ? AppColors.primaryGold.withValues(alpha: 0.14)
                        : AppColors.cardNavy,
                    title: Text(
                      '${frac['title']}',
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSel ? AppColors.primaryGoldLight : AppColors.textLight,
                      ),
                    ),
                    subtitle: Text(
                      '${frac['text']}'.replaceAll('\n', ' '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
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
    final prov = context.watch<LiturgyProvider>();
    final fontScale = context.watch<ThemeProvider>().fontScale;

    if (prov.isLoading || prov.selectedLiturgy == null) {
      return const Scaffold(
        backgroundColor: AppColors.deepNavy,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGold, strokeWidth: 2)),
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
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
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
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGoldLight,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primaryGold, size: 19),
                ],
              ),
              Text(
                '${_copticToday.formatted}${_isAfterVespers ? ' • توقيت عشية' : ''}',
                style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: _isAutoScrolling ? 'إيقاف التمرير التلقائي' : 'تمرير تلقائي أثناء القداس',
            icon: Icon(
              _isAutoScrolling ? Icons.pause_circle_filled_rounded : Icons.play_circle_outline_rounded,
              color: _isAutoScrolling ? AppColors.primaryGold : AppColors.textMuted,
              size: 22,
            ),
            onPressed: _toggleAutoScroll,
          ),
          IconButton(
            tooltip: 'إعدادات العرض واللغة',
            icon: const Icon(Icons.tune_rounded, color: AppColors.primaryGoldLight, size: 21),
            onPressed: _showDisplaySettingsSheet,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Slim Quick-Jump Milestone Ribbon (like Orsozoxi / Coptic Reader top tabs)
          Container(
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.surfaceNavy,
              border: Border(
                top: BorderSide(color: AppColors.hairline, width: 0.7),
                bottom: BorderSide(color: AppColors.hairline, width: 0.7),
              ),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              itemCount: liturgy.sections.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, idx) {
                final raw = liturgy.sections[idx].title;
                final compact = _compactMilestoneLabel(raw);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _jumpToSection(idx);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.cardNavy,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: compact.contains('السنكسار')
                            ? AppColors.primaryGold.withValues(alpha: 0.45)
                            : AppColors.hairline,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        compact,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: compact.contains('السنكسار')
                              ? AppColors.primaryGoldLight
                              : AppColors.textLight,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Continuous Flowing Kholagy Book (Coptic Reader + Orsozoxi Experience!)
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int sIdx = 0; sIdx < liturgy.sections.length; sIdx++) ...[
                    _buildSectionBlock(liturgy.sections[sIdx], sIdx, fontScale),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.cardNavy,
        foregroundColor: AppColors.primaryGoldLight,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.55)),
        ),
        icon: const Icon(Icons.format_list_numbered_rtl_rounded,
            size: 19, color: AppColors.primaryGold),
        label: Text(
          'فهرس القداس',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.5),
        ),
        onPressed: () => _showLiturgicalIndexSheet(liturgy),
      ),
    );
  }

  String _compactMilestoneLabel(String fullTitle) {
    if (fullTitle.contains('تقدمة الحمل')) return 'تقدمة الحمل';
    if (fullTitle.contains('تحليل الخدام')) return 'تحليل الخدام';
    if (fullTitle.contains('البولس')) return 'القراءات';
    if (fullTitle.contains('السنكسار')) return 'السنكسار';
    if (fullTitle.contains('أجيوس')) return 'الإنجيل والإيمان';
    if (fullTitle.contains('الصلح')) return 'الصلح';
    if (fullTitle.contains('الأنافورا') || fullTitle.contains('التسبحة الشاروبيمية')) {
      return fullTitle.contains('التسبحة') ? 'التقديس' : 'الأنافورا';
    }
    if (fullTitle.contains('أواشي') || fullTitle.contains('المجمع')) return 'الأواشي والمجمع';
    if (fullTitle.contains('القسمة')) return 'القسمة';
    if (fullTitle.contains('الخضوع') || fullTitle.contains('الاعتراف')) return 'الاعتراف';
    if (fullTitle.contains('التناول')) return 'التناول والبركة';
    return fullTitle.length > 18 ? fullTitle.substring(0, 18) : fullTitle;
  }

  Widget _buildSectionBlock(LiturgySection sec, int sIdx, double fontScale) {
    return Column(
      key: _sectionKeys[sIdx],
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Editorial Liturgical Section Divider Banner (Coptic Reader Style)
        Padding(
          padding: EdgeInsets.only(top: sIdx == 0 ? 4 : 24, bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: const BoxDecoration(
                color: AppColors.cardNavy,
                border: Border(
                  right: BorderSide(color: AppColors.primaryGold, width: 3),
                  top: BorderSide(color: AppColors.hairline),
                  left: BorderSide(color: AppColors.hairline),
                  bottom: BorderSide(color: AppColors.hairline),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sec.title,
                    style: GoogleFonts.amiri(
                      fontSize: 20 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGoldLight,
                      height: 1.3,
                    ),
                  ),
                  if (sec.tafseer.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      sec.tafseer,
                      style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Verses & Live Embedded Readings / Synaxarium
        for (final v in sec.verses) ...[
          if (v.role == 'reading_slot')
            _buildDynamicLiturgicalSlot(v.arabic, fontScale)
          else if (_shouldShowVerse(v))
            _buildFlowingLiturgicalLine(v, fontScale),
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

  // ===========================================================================
  // LIVE EMBEDDED DAILY READINGS + LIVE FULL SYNAXARIUM + SEASONAL FRACTIONS
  // ===========================================================================
  Widget _buildDynamicLiturgicalSlot(String slotKey, double fontScale) {
    switch (slotKey) {
      case 'LITURGY_PAULINE_SLOT':
        return _buildEmbeddedScriptureBlock(
          title: 'قراءة البولس (رسالة معلمنا بولس الرسول)',
          reading: _dailyReadings['pauline'],
          opening: 'بُولُسُ عَبْدُ يَسُوعَ الْمَسِيحِ، الْمَدْعُوُّ رَسُولاً، الْمُفْرَزُ لإِنْجِيلِ اللهِ:',
          closing: 'نِعْمَةُ اللهِ الآبِ تَحِلُّ عَلَى أَرْوَاحِنَا يَا آبَائِي وَإِخْوَتِي. آمِينَ.',
          fontScale: fontScale,
        );
      case 'LITURGY_CATHOLIC_SLOT':
        return _buildEmbeddedScriptureBlock(
          title: 'قراءة الكاثوليكون (رسالة الجامعة)',
          reading: _dailyReadings['catholic'],
          opening: 'الكاثوليكون، فَصْلٌ مِنْ رِسَالَةِ مُعَلِّمِنَا الرَّسُولِ بَرَكَتُهُ عَلَيْنَا آمِينَ:',
          closing: 'لاَ تُحِبُّوا الْعَالَمَ وَلاَ الأَشْيَاءَ الَّتِي فِي الْعَالَمِ، لأَنَّ الْعَالَمَ يَمْضِي وَشَهْوَتَهُ، وَأَمَّا الَّذِي يَصْنَعُ مَشِيئَةَ اللهِ فَيَثْبُتُ إِلَى الأَبَدِ. آمِينَ.',
          fontScale: fontScale,
        );
      case 'LITURGY_ACTS_SLOT':
        return _buildEmbeddedScriptureBlock(
          title: 'قراءة الإبركسيس (أعمال آبائنا الرسل)',
          reading: _dailyReadings['acts'],
          opening: 'فَصْلٌ مِنْ أَعْمَالِ آبَائِنَا الرُّسُلِ الأَطْهَارِ الْمَشْمُولِينَ بِنِعْمَةِ الرُّوحِ الْقُدُسِ، بَرَكَتُهُمْ تَكُونُ مَعَنَا آمِينَ:',
          closing: 'لَمْ تَزَلْ كَلِمَةُ الرَّبِّ تَنْمُو وَتَزْدَادُ وَتَعْتَزُّ وَتَثْبُتُ فِي هذِهِ الْكَنِيسَةِ وَكُلِّ كَنِيسَةٍ. آمِينَ.',
          fontScale: fontScale,
        );
      case 'LITURGY_SYNAXARIUM_SLOT':
        return _buildInlineFullSynaxariumBlock(fontScale);
      case 'LITURGY_GOSPEL_SLOT':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEmbeddedScriptureBlock(
              title: 'مزمور القداس الإلهي لليوم',
              reading: _dailyReadings['psalm'],
              opening: 'مِنْ مَزَامِيرِ وَتَرَاتِيلِ أَبِينَا دَاوُدَ النَّبِيِّ، بَرَكَتُهُ عَلَيْنَا آمِينَ:',
              closing: 'هَلِّلُويَا.',
              fontScale: fontScale,
            ),
            _buildEmbeddedScriptureBlock(
              title: 'الإنجيل المقدس لليوم',
              reading: _dailyReadings['gospel'],
              opening: 'مُبَارَكٌ الآتِي بِاسْمِ الرَّبِّ. فَصْلٌ شَرِيفٌ مِنْ بِشَارَةِ الإِنْجِيلِ الْمُقَدَّسِ:',
              closing: 'وَالْمَجْدُ للهِ دَائِماً أَبَدِيّاً. آمِينَ.',
              fontScale: fontScale,
              isGospel: true,
            ),
          ],
        );
      case 'LITURGY_FRACTION_PICKER_SLOT':
        return _buildFractionPickerInline(fontScale);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmbeddedScriptureBlock({
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.surfaceNavy,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isGospel
              ? AppColors.primaryGold.withValues(alpha: 0.45)
              : AppColors.hairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isGospel ? Icons.auto_stories_rounded : Icons.menu_book_outlined,
                color: AppColors.primaryGold,
                size: 17,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGoldLight,
                      ),
                    ),
                    Text(
                      ref,
                      style: GoogleFonts.cairo(fontSize: 11, color: AppColors.primaryGold),
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
              fontSize: (_fontSize - 1.5) * fontScale,
              color: AppColors.rubricRed,
              height: 1.55,
            ),
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              body,
              style: GoogleFonts.amiri(
                fontSize: (_fontSize + 1) * fontScale,
                height: 1.85,
                color: AppColors.textLight,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            closing,
            style: GoogleFonts.amiri(
              fontSize: (_fontSize - 1) * fontScale,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGoldLight,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Renders TODAY'S FULL SYNAXARIUM inline inside the Divine Liturgy (exact Orsozoxi / Coptic Reader placement!)
  Widget _buildInlineFullSynaxariumBlock(double fontScale) {
    final events = CopticCalendarService.getSynaxariumEventsForDate(
      _copticToday.month,
      _copticToday.day,
    );
    final fullText = CopticCalendarService.getSynaxariumForDate(
      _copticToday.month,
      _copticToday.day,
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardNavy,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CopticCross(size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سنكسار اليوم: ${_copticToday.day} ${_copticToday.monthName} ${_copticToday.year} ش',
                      style: GoogleFonts.amiri(
                        fontSize: 19 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGoldLight,
                      ),
                    ),
                    Text(
                      _isAfterVespers
                          ? 'تذكار اليوم التالي تلقائياً (توقيت عشية بعد ٥ مساءً)'
                          : 'يُقرأ عقب الإبركسيس وقبل أجيوس والإنجيل',
                      style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: _synaxariumExpanded ? 'طي السنكسار' : 'عرض السنكسار كاملاً',
                icon: Icon(
                  _synaxariumExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: AppColors.primaryGold,
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
                  stopText: 'إيقاف الصوت',
                  compact: true,
                ),
                const Spacer(),
                Text(
                  '${events.length} تذكار اليوم',
                  style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'باسم الآب والابن والروح القدس الإله الواحد آمين. اليوم ${_copticToday.day} من شهر ${_copticToday.monthName} المبارك:',
              style: GoogleFonts.amiri(
                fontSize: (_fontSize - 1) * fontScale,
                fontWeight: FontWeight.bold,
                color: AppColors.rubricRed,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 10),
            for (int i = 0; i < events.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: AppColors.hairline, height: 1),
                ),
              Text(
                '${i + 1}. ${events[i]['title']}',
                style: GoogleFonts.amiri(
                  fontSize: (_fontSize + 1) * fontScale,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGoldLight,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                '${events[i]['text']}'.trim(),
                style: GoogleFonts.amiri(
                  fontSize: _fontSize * fontScale,
                  height: 1.85,
                  color: AppColors.textLight,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'بركة صلواتهم وشفاعتهم فلتكن معنا جميعاً، ولربنا المجد دائماً أبدياً. آمين.',
              style: GoogleFonts.amiri(
                fontSize: (_fontSize - 0.5) * fontScale,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGoldLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFractionPickerInline(double fontScale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories_outlined, color: AppColors.primaryGold, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedSeasonalFraction != null
                      ? 'القسمة المختارة: ${_selectedSeasonalFraction!['title']}'
                      : 'يمكنك اختيار قسمة الموسم أو العيد حسب طقس اليوم',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryGoldLight,
                  ),
                ),
              ),
              OutlinedButton(
                onPressed: _seasonalFractions.isEmpty ? null : _showSeasonalFractionPicker,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.45)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'تبديل القسمة',
                  style: GoogleFonts.cairo(fontSize: 11, color: AppColors.primaryGoldLight),
                ),
              ),
            ],
          ),
          if (_selectedSeasonalFraction != null) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.hairline, height: 1),
            const SizedBox(height: 10),
            Text(
              'الكاهن • ${_selectedSeasonalFraction!['title']}',
              style: GoogleFonts.cairo(
                fontSize: 11.5,
                fontWeight: FontWeight.bold,
                color: AppColors.rubricRed,
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              '${_selectedSeasonalFraction!['text']}',
              style: GoogleFonts.amiri(
                fontSize: _fontSize * fontScale,
                height: 1.85,
                color: AppColors.textLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // CONTINUOUS FLOWING LITURGICAL LINE (NO BLOATED CARDS PER VERSE!)
  // ===========================================================================
  Widget _buildFlowingLiturgicalLine(LiturgyVerse verse, double fontScale) {
    // 1. Rubric line (subtle italic vermilion — traditional Kholagy style)
    if (verse.role == 'rubric') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Text(
          verse.arabic,
          style: GoogleFonts.cairo(
            fontSize: (_fontSize - 5.5).clamp(11.5, 16.0) * fontScale,
            fontStyle: FontStyle.italic,
            color: AppColors.rubricRed,
            height: 1.55,
          ),
        ),
      );
    }

    // 2. Role colors (restrained, reverent, high legibility in church)
    final bool isSilent = verse.role == 'priest_silent';
    final bool isPriest = verse.role == 'priest' || isSilent;
    final bool isDeacon = verse.role == 'deacon';
    final bool isPeople = verse.role == 'people';

    final Color roleColor = isSilent
        ? const Color(0xFFA78BC7)
        : (isPriest
            ? const Color(0xFFD9786C)
            : (isDeacon ? const Color(0xFF7DA8CF) : AppColors.primaryGold));

    final String roleLabel = verse.roleArabic.isNotEmpty
        ? verse.roleArabic
        : (isPriest ? 'الكاهن' : (isDeacon ? 'الشماس' : 'الشعب'));

    final matchedHymn = _matchLiturgicalHymn(verse);
    final hasArabized = verse.arabized.isNotEmpty;
    final hasCoptic = verse.coptic.isNotEmpty && verse.coptic != verse.arabized;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isSilent ? 12 : 4,
        10,
        isPeople ? 10 : (isSilent ? 12 : 4),
        12,
      ),
      margin: EdgeInsets.symmetric(vertical: isSilent ? 5 : 1),
      decoration: BoxDecoration(
        color: isSilent ? const Color(0xFF1A1622) : Colors.transparent,
        borderRadius: isSilent ? BorderRadius.circular(10) : null,
        border: isSilent
            ? Border.all(color: const Color(0xFF3E3052), width: 0.8)
            : Border(
                right: isPeople
                    ? BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.6), width: 2.2)
                    : BorderSide.none,
                bottom: BorderSide(color: AppColors.hairline.withValues(alpha: 0.65), width: 0.6),
              ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Minimalist Speaker Tag Row (like Coptic Reader & Orsozoxi)
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: roleColor),
              ),
              const SizedBox(width: 6),
              Text(
                roleLabel,
                style: GoogleFonts.cairo(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: roleColor,
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceNavy,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.music_note_rounded, size: 12, color: AppColors.primaryGold),
                        const SizedBox(width: 3),
                        Text(
                          'اللحن',
                          style: GoogleFonts.cairo(
                            fontSize: 10.5,
                            color: AppColors.primaryGoldLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 5),

          // Layout Mode A: COPTIC READER 2-COLUMN SIDE-BY-SIDE (Arabic Right | Coptic/Arabized Left)
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
                        height: 1.75,
                        color: isPeople ? const Color(0xFFFAF5EA) : AppColors.textLight,
                        fontWeight: isPeople ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  Container(
                    width: 0.8,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    color: AppColors.hairline,
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
                              color: AppColors.textArabized,
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
                              color: AppColors.textMuted,
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
            // Layout Mode B: ORSOZOXI CLEAN FLOWING ARABIC (+ OPTIONAL ARABIZED / COPTIC)
            SelectableText(
              verse.arabic,
              style: GoogleFonts.amiri(
                fontSize: (_fontSize + 1.5) * fontScale,
                height: 1.8,
                color: isPeople ? const Color(0xFFFAF5EA) : AppColors.textLight,
                fontWeight: isPeople ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if ((_layoutMode == 'orsozoxi' || _layoutMode == 'tri') && hasArabized) ...[
              const SizedBox(height: 5),
              SelectableText(
                verse.arabized,
                style: GoogleFonts.cairo(
                  fontSize: (_fontSize - 3.0).clamp(12.5, 20.0) * fontScale,
                  height: 1.65,
                  color: AppColors.textArabized,
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
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
