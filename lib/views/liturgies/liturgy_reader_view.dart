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
import '../liturgical/raising_of_incense_view.dart';

/// Cached TextStyle bundle computed once per build so ListView.builder items
/// never re-allocate GoogleFonts styles during scrolling.
class _LiturgyStyles {
  final TextStyle arabic;
  final TextStyle arabicBold;
  final TextStyle arabized;
  final TextStyle coptic;
  final TextStyle rubric;
  final TextStyle roleBadge;
  final TextStyle sectionTitle;
  final TextStyle sectionSubtitle;
  final TextStyle hymnChip;

  const _LiturgyStyles({
    required this.arabic,
    required this.arabicBold,
    required this.arabized,
    required this.coptic,
    required this.rubric,
    required this.roleBadge,
    required this.sectionTitle,
    required this.sectionSubtitle,
    required this.hymnChip,
  });

  factory _LiturgyStyles.build(AppPalette p, double fontSize, double fontScale) {
    final s = fontScale.clamp(0.85, 1.35);
    return _LiturgyStyles(
      arabic: GoogleFonts.amiri(
        fontSize: (fontSize + 1.5) * s,
        height: 1.85,
        color: p.ink,
        fontWeight: FontWeight.normal,
      ),
      arabicBold: GoogleFonts.amiri(
        fontSize: (fontSize + 1.5) * s,
        height: 1.85,
        color: p.ink,
        fontWeight: FontWeight.bold,
      ),
      arabized: GoogleFonts.cairo(
        fontSize: (fontSize - 3.2).clamp(12.5, 20.0) * s,
        height: 1.65,
        color: p.gold,
        fontWeight: FontWeight.w500,
      ),
      coptic: TextStyle(
        fontFamily: 'Coptic',
        fontSize: (fontSize - 2.5).clamp(12.5, 20.0) * s,
        height: 1.55,
        color: p.inkSecondary,
      ),
      rubric: GoogleFonts.cairo(
        fontSize: (fontSize - 5.5).clamp(11.5, 16.0) * s,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w500,
        color: p.crimson,
        height: 1.55,
      ),
      roleBadge: GoogleFonts.cairo(
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
      sectionTitle: GoogleFonts.amiri(
        fontSize: 21 * s,
        fontWeight: FontWeight.bold,
        color: p.isDark ? p.gold : p.crimson,
        height: 1.3,
      ),
      sectionSubtitle: GoogleFonts.cairo(
        fontSize: 11.5,
        color: p.inkSecondary,
      ),
      hymnChip: GoogleFonts.cairo(
        fontSize: 10.5,
        color: p.ink,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

sealed class _LiturgyRow {}

class _SectionHeaderRow extends _LiturgyRow {
  final LiturgySection section;
  final int sectionIndex;
  _SectionHeaderRow(this.section, this.sectionIndex);
}

class _VerseRow extends _LiturgyRow {
  final LiturgyVerse verse;
  _VerseRow(this.verse);
}

class _SlotRow extends _LiturgyRow {
  final String slotKey;
  _SlotRow(this.slotKey);
}

class _SectionNavFooterRow extends _LiturgyRow {
  final int sectionIndex;
  final int totalSections;
  final String? prevTitle;
  final String? nextTitle;
  _SectionNavFooterRow({
    required this.sectionIndex,
    required this.totalSections,
    this.prevTitle,
    this.nextTitle,
  });
}

/// High-Performance Illuminated Coptic Kholagy Reader:
/// - Zero-lag lazy ListView.builder (section-by-section fast mode + optional continuous scroll mode)
/// - Zero IntrinsicHeight, zero 4MB eager hymns.json parse on open, cached GoogleFonts TextStyles
/// - 4 Instant Liturgical Styles (Kholagy Book, 2-Column Coptic Reader, Tri-lingual, Pure Arabic)
/// - Instant `ع | م | ق | ص.ك` toggle ribbon + Milestone Stepper + `فهرس القداس` quick-jump sheet
/// - Live Embedded Daily Readings (Pauline, Catholic, Acts, Psalm & Gospel) & Today's Synaxarium
/// - 39 Seasonal Fractions Picker + On-demand Liturgical Hymn Audio Jump
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
  // Static shared caches so re-opening LiturgyReaderView NEVER re-parses large JSON assets.
  static List<Map<String, dynamic>>? _sharedFractionsCache;
  static List<Hymn>? _sharedHymnsCache;

  double _fontSize = 18.5;
  String _activeRoleFilter = 'all'; // 'all' | 'people' | 'priest' | 'deacon'
  String _layoutMode = 'kholagy_book'; // 'kholagy_book' | 'coptic_reader' | 'tri' | 'arabic'
  bool _sectionBySection = true; // Default fast section mode (zero-lag instant milestone jumps)
  bool _showArabic = true;
  bool _showArabized = true;
  bool _showCoptic = true;
  bool _showSilentPrayers = false;
  bool _showRubrics = true;
  bool _synaxariumExpanded = true;
  int _activeMilestoneIdx = 0;

  // Orsozoxi-style Liturgical Season Selector (auto-detected from Coptic calendar, 1-tap override)
  String _activeSeasonKey = 'annual'; // 'annual' | 'lent' | 'joyful' | 'kiahk' | 'palm'

  static const List<({String key, String label, String tune, String fracHint})> _liturgicalSeasons = [
    (key: 'annual', label: 'سنوي', tune: 'الطقس السنوي (آدام / واطس)', fracHint: 'سنوية'),
    (key: 'lent', label: 'صيامي', tune: 'طقس الصوم الكبير ويونان', fracHint: 'الصوم'),
    (key: 'joyful', label: 'فرايحي', tune: 'الطقس الفرايحي (الأعياد والخماسين)', fracHint: 'القيامة'),
    (key: 'kiahk', label: 'كيهكي', tune: 'طقس شهر كيهك والميلاد', fracHint: 'الميلاد'),
    (key: 'palm', label: 'شعانيني', tune: 'الطقس الشعانيني (الشعانين والصليب)', fracHint: 'الشعانين'),
  ];

  static String _detectSeasonKey(String seasonName) {
    if (seasonName.contains('كيهك') || seasonName.contains('الميلاد')) return 'kiahk';
    if (seasonName.contains('القيامة') || seasonName.contains('الخماسين') || seasonName.contains('عيد')) {
      return 'joyful';
    }
    if (seasonName.contains('الكبير') || seasonName.contains('نينوى') || seasonName.contains('صوم')) {
      return 'lent';
    }
    if (seasonName.contains('الشعانين') || seasonName.contains('الصليب')) return 'palm';
    return 'annual';
  }

  static int _phaseForSectionIndex(int idx, int total) {
    if (idx <= 1) return 0; // ١. تقديم الحمل ورفع البخور
    if (idx <= 4) return 1; // ٢. قداس الكلمة (الموعوظين)
    if (idx <= total - 3) return 2; // ٣. قداس المؤمنين (الأنافورا والقسمة)
    return 3; // ٤. التوزيع والختام
  }

  void _selectLiturgicalSeason(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      _activeSeasonKey = key;
      if (_seasonalFractions.isNotEmpty) {
        final meta = _liturgicalSeasons.firstWhere((s) => s.key == key);
        if (key == 'annual') {
          _selectedSeasonalFraction = null;
        } else {
          final found = _seasonalFractions.where(
            (f) => '${f['title']}'.contains(meta.fracHint),
          );
          if (found.isNotEmpty) _selectedSeasonalFraction = found.first;
        }
      }
    });
  }

  // Auto-scroll
  bool _isAutoScrolling = false;
  final double _autoScrollSpeed = 1.0;
  Timer? _autoScrollTimer;
  Timer? _clockWatcher;

  // Live liturgical date (5:00 PM Vespers rollover), readings, seasonal fractions
  late CopticDate _copticToday;
  bool _isAfterVespers = false;
  Map<String, Map<String, String>> _dailyReadings = {};
  List<Map<String, dynamic>> _seasonalFractions = [];
  Map<String, dynamic>? _selectedSeasonalFraction;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _activeMilestoneIdx = widget.initialSectionIndex.clamp(0, 99);
    _copticToday = CopticCalendarService.todayLiturgical();
    _activeSeasonKey = _detectSeasonKey(_copticToday.seasonName);
    _isAfterVespers = CopticCalendarService.isAfterVespers();
    if (_sharedFractionsCache != null) {
      _seasonalFractions = _sharedFractionsCache!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEssentialLiturgicalData();
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

  Future<void> _loadEssentialLiturgicalData() async {
    final prov = context.read<LiturgyProvider>();
    // 1. Load liturgy first so text renders instantaneously
    await prov.loadLiturgies();
    if (!mounted) return;
    final maxIdx = (prov.selectedLiturgy?.sections.length ?? 1) - 1;
    if (_activeMilestoneIdx > maxIdx) {
      setState(() => _activeMilestoneIdx = 0);
    }
    // 2. Load daily readings & fractions asynchronously in background without blocking frame 1
    unawaited(_reloadDailyReadings());
    unawaited(_loadSeasonalFractions());
  }

  Future<void> _reloadDailyReadings() async {
    final readings = await CopticCalendarService.getResolvedLiturgyReadings();
    if (mounted) {
      setState(() => _dailyReadings = readings);
    }
  }

  Future<void> _loadSeasonalFractions() async {
    if (_sharedFractionsCache != null) {
      if (mounted && _seasonalFractions.isEmpty) {
        setState(() => _seasonalFractions = _sharedFractionsCache!);
      }
      return;
    }
    try {
      final raw = await rootBundle.loadString('assets/data/seasonal_fractions.json');
      final list = (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)).toList();
      _sharedFractionsCache = list;
      if (mounted) setState(() => _seasonalFractions = list);
    } catch (_) {}
  }

  /// Lazily loads hymns.json (4 MB) ONLY when the user explicitly taps "سماع اللحن".
  Future<void> _openMatchedHymn(String keyword) async {
    HapticFeedback.selectionClick();
    if (_sharedHymnsCache == null) {
      try {
        final raw = await rootBundle.loadString('assets/data/hymns.json');
        final list = jsonDecode(raw) as List;
        _sharedHymnsCache = list.map((e) => Hymn.fromJson(e)).toList();
      } catch (_) {
        _sharedHymnsCache = [];
      }
    }
    if (!mounted || _sharedHymnsCache == null) return;
    Hymn? match;
    for (final h in _sharedHymnsCache!) {
      if (h.title.contains(keyword)) {
        match = h;
        break;
      }
    }
    if (match != null) {
      Navigator.push(
        context,
        luxeRoute(HymnDetailView(hymn: match, playlist: _sharedHymnsCache!)),
      );
    }
  }

  String? _matchLiturgicalHymnKeyword(LiturgyVerse verse) {
    if (verse.role != 'people') return null;
    final ar = verse.arabic;
    final ab = verse.arabized;
    if (ar.contains('قدوس الله قدوس القوي') || ab.contains('أجيوس')) return 'أجيوس';
    if (ar.contains('بشفاعات والدة الإله') || ab.contains('هيتين')) return 'هيتني';
    if (ar.contains('الشاروبيم يسجدون')) return 'الشاروبيم';
    if (ar.contains('بموتك يا رب نبشر')) return 'بموتك';
    if (ar.contains('سبحوا الله في جميع قديسيه')) return '150';
    if (ar.contains('نسجد لآب النور')) return 'تين أوأوشت';
    return null;
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

  void _jumpToSection(int idx, int totalSections) {
    final safeIdx = idx.clamp(0, (totalSections - 1).clamp(0, 999));
    setState(() {
      _activeMilestoneIdx = safeIdx;
      // Instant jump switches cleanly to focused section view for 0ms precision
      if (!_sectionBySection) {
        _sectionBySection = true;
      }
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _copyVerseText(String text) {
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

  List<_LiturgyRow> _buildVisibleRows(Liturgy liturgy) {
    final rows = <_LiturgyRow>[];
    if (liturgy.sections.isEmpty) return rows;

    if (_sectionBySection) {
      final safeIdx = _activeMilestoneIdx.clamp(0, liturgy.sections.length - 1);
      final sec = liturgy.sections[safeIdx];
      rows.add(_SectionHeaderRow(sec, safeIdx));
      for (final v in sec.verses) {
        if (v.role == 'reading_slot') {
          rows.add(_SlotRow(v.arabic));
        } else if (_shouldShowVerse(v)) {
          rows.add(_VerseRow(v));
        }
      }
      rows.add(
        _SectionNavFooterRow(
          sectionIndex: safeIdx,
          totalSections: liturgy.sections.length,
          prevTitle: safeIdx > 0 ? _compactMilestoneLabel(liturgy.sections[safeIdx - 1].title) : null,
          nextTitle: safeIdx < liturgy.sections.length - 1
              ? _compactMilestoneLabel(liturgy.sections[safeIdx + 1].title)
              : null,
        ),
      );
    } else {
      for (int sIdx = 0; sIdx < liturgy.sections.length; sIdx++) {
        final sec = liturgy.sections[sIdx];
        rows.add(_SectionHeaderRow(sec, sIdx));
        for (final v in sec.verses) {
          if (v.role == 'reading_slot') {
            rows.add(_SlotRow(v.arabic));
          } else if (_shouldShowVerse(v)) {
            rows.add(_VerseRow(v));
          }
        }
      }
    }
    return rows;
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      // Orsozoxi-style Matins Incense Opening Shortcut right before Offering of the Lamb!
                      Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(color: p.goldBorder),
                          ),
                          tileColor: p.goldSoft,
                          leading: Icon(Icons.local_fire_department_rounded, color: p.gold, size: 22),
                          title: Text(
                            '٠. رفع بخور عشية وباكر (ما قبل القداس)',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: p.ink,
                            ),
                          ),
                          subtitle: Text(
                            'صلاة الشكر • الأواشي • أرباع الناقوس • إنجيل باكر',
                            style: GoogleFonts.cairo(fontSize: 11, color: p.inkSecondary),
                          ),
                          trailing: Icon(Icons.chevron_left_rounded, color: p.gold, size: 19),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.push(context, luxeRoute(const RaisingOfIncenseView()));
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(liturgy.sections.length, (idx) {
                        final sec = liturgy.sections[idx];
                        final isSynax = sec.title.contains('السنكسار');
                        final isActive = idx == _activeMilestoneIdx;
                        final phase = _phaseForSectionIndex(idx, liturgy.sections.length);
                        final prevPhase = idx > 0
                            ? _phaseForSectionIndex(idx - 1, liturgy.sections.length)
                            : -1;
                        const phaseTitles = [
                          'المرحلة الأولى • تقديم الحمل والاستعداد',
                          'المرحلة الثانية • قداس الكلمة (الموعوظين)',
                          'المرحلة الثالثة • قداس المؤمنين (الأنافورا والقسمة)',
                          'المرحلة الرابعة • الاعتراف والتوزيع والختام',
                        ];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (phase != prevPhase)
                              Padding(
                                padding: EdgeInsets.only(top: idx == 0 ? 2 : 12, bottom: 6, right: 4),
                                child: Text(
                                  phaseTitles[phase],
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: p.gold,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 7),
                              child: Material(
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
                                    _jumpToSection(idx, liturgy.sections.length);
                                  },
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
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
              Material(
                type: MaterialType.transparency,
                child: ListTile(
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
              Text('نمط التصفح:', style: GoogleFonts.cairo(fontSize: 12, color: p.inkMuted)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _settingChip(p, 'محطة بمحطة (سريع جداً)', _sectionBySection, () {
                    setState(() => _sectionBySection = true);
                    setSheet(() {});
                    if (_scrollController.hasClients) _scrollController.jumpTo(0);
                  }),
                  _settingChip(p, 'عرض القداس كاملاً متصلاً', !_sectionBySection, () {
                    setState(() => _sectionBySection = false);
                    setSheet(() {});
                    if (_scrollController.hasClients) _scrollController.jumpTo(0);
                  }),
                ],
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
                      style: GoogleFonts.cairo(
                          fontSize: 12.5, fontWeight: FontWeight.bold, color: p.accent)),
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
                      child: Text('الأصلية',
                          style: GoogleFonts.cairo(fontSize: 12, color: p.accent)),
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
                  return Material(
                    type: MaterialType.transparency,
                    child: ListTile(
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

    // Compute cached TextStyles ONCE per build (massive FPS & memory boost!)
    final styles = _LiturgyStyles.build(p, _fontSize, fontScale);
    final rows = _buildVisibleRows(liturgy);

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
          // 1. Orsozoxi-style 4 Canonical Liturgy Phases + Season Switcher Ribbon
          Container(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            decoration: BoxDecoration(
              color: p.surface,
              border: Border(top: BorderSide(color: p.border, width: 0.8)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Season pill (tap to switch: سنوي / صيامي / فرايحي / كيهكي / شعانيني)
                  PopupMenuButton<String>(
                    initialValue: _activeSeasonKey,
                    onSelected: _selectLiturgicalSeason,
                    itemBuilder: (_) => _liturgicalSeasons
                        .map((s) => PopupMenuItem(
                              value: s.key,
                              child: Text(
                                '${s.label} • ${s.tune}',
                                style: GoogleFonts.cairo(fontSize: 12),
                              ),
                            ))
                        .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: p.goldSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: p.goldBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome_rounded, size: 13, color: p.gold),
                          const SizedBox(width: 4),
                          Text(
                            'طقس ${_liturgicalSeasons.firstWhere((s) => s.key == _activeSeasonKey).label}',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: p.ink,
                            ),
                          ),
                          Icon(Icons.arrow_drop_down_rounded, size: 16, color: p.gold),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _phaseJumpPill(
                    p,
                    'رفع البخور',
                    false,
                    () => Navigator.push(context, luxeRoute(const RaisingOfIncenseView())),
                  ),
                  const SizedBox(width: 6),
                  _phaseJumpPill(
                    p,
                    'تقديم الحمل',
                    _phaseForSectionIndex(_activeMilestoneIdx, liturgy.sections.length) == 0,
                    () => _jumpToSection(0, liturgy.sections.length),
                  ),
                  const SizedBox(width: 6),
                  _phaseJumpPill(
                    p,
                    'قداس الكلمة',
                    _phaseForSectionIndex(_activeMilestoneIdx, liturgy.sections.length) == 1,
                    () => _jumpToSection(2, liturgy.sections.length),
                  ),
                  const SizedBox(width: 6),
                  _phaseJumpPill(
                    p,
                    'قداس المؤمنين',
                    _phaseForSectionIndex(_activeMilestoneIdx, liturgy.sections.length) == 2,
                    () => _jumpToSection(5, liturgy.sections.length),
                  ),
                  const SizedBox(width: 6),
                  _phaseJumpPill(
                    p,
                    'التوزيع والختام',
                    _phaseForSectionIndex(_activeMilestoneIdx, liturgy.sections.length) == 3,
                    () => _jumpToSection(
                      (liturgy.sections.length - 2).clamp(0, liturgy.sections.length - 1),
                      liturgy.sections.length,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Interactive Liturgical Milestone Stepper Ribbon
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: p.surface,
              border: Border(
                top: BorderSide(color: p.border, width: 0.6),
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
                final active = idx == _activeMilestoneIdx && _sectionBySection;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _jumpToSection(idx, liturgy.sections.length);
                  },
                  child: Container(
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

          // Instant Language & Silent Priest Prayers Toggle Bar (ع | م | ق | ص.ك | كامل/محطات)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: p.surfaceSubtle,
              border: Border(bottom: BorderSide(color: p.border, width: 0.7)),
            ),
            child: Row(
              children: [
                _langTogglePill(p, 'ع', _showArabic, () {
                  if (_showArabic && !_showArabized && !_showCoptic) return;
                  setState(() => _showArabic = !_showArabic);
                }),
                const SizedBox(width: 5),
                _langTogglePill(p, 'م', _showArabized, () {
                  setState(() => _showArabized = !_showArabized);
                }),
                const SizedBox(width: 5),
                _langTogglePill(p, 'ق', _showCoptic, () {
                  setState(() => _showCoptic = !_showCoptic);
                }),
                const SizedBox(width: 5),
                _langTogglePill(p, 'ص.ك', _showSilentPrayers, () {
                  setState(() => _showSilentPrayers = !_showSilentPrayers);
                }),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _sectionBySection = !_sectionBySection);
                    if (_scrollController.hasClients) _scrollController.jumpTo(0);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.border),
                    ),
                    child: Text(
                      _sectionBySection ? 'عرض كامل' : 'محطة بمحطة',
                      style: GoogleFonts.cairo(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: p.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Zero-Lag Virtualized Lazy ListView.builder
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 740),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                  addAutomaticKeepAlives: false,
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final item = rows[index];
                    return switch (item) {
                      _SectionHeaderRow(:final section, :final sectionIndex) =>
                        _buildSectionHeader(p, section, sectionIndex, styles),
                      _VerseRow(:final verse) =>
                        _buildFlowingLiturgicalLine(p, verse, styles),
                      _SlotRow(:final slotKey) =>
                        _buildDynamicLiturgicalSlot(p, slotKey, fontScale),
                      _SectionNavFooterRow(
                        :final sectionIndex,
                        :final totalSections,
                        :final prevTitle,
                        :final nextTitle,
                      ) =>
                        _buildSectionNavFooter(
                          p,
                          sectionIndex,
                          totalSections,
                          prevTitle,
                          nextTitle,
                        ),
                    };
                  },
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

  Widget _phaseJumpPill(AppPalette p, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? p.accent : p.surfaceSubtle,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? p.accent : p.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: active ? p.onAccent : p.inkSecondary,
          ),
        ),
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

  Widget _buildSectionHeader(
    AppPalette p,
    LiturgySection sec,
    int sIdx,
    _LiturgyStyles styles,
  ) {
    return Padding(
      padding: EdgeInsets.only(top: sIdx == 0 || _sectionBySection ? 4 : 22, bottom: 12),
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
                    style: styles.sectionTitle,
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
                style: styles.sectionSubtitle,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionNavFooter(
    AppPalette p,
    int sectionIndex,
    int totalSections,
    String? prevTitle,
    String? nextTitle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 12),
      child: Row(
        children: [
          if (sectionIndex > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _jumpToSection(sectionIndex - 1, totalSections);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  side: BorderSide(color: p.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: Icon(Icons.chevron_right_rounded, size: 18, color: p.accent),
                label: Text(
                  prevTitle ?? 'المحطة السابقة',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: p.ink,
                  ),
                ),
              ),
            )
          else
            const Spacer(),
          const SizedBox(width: 10),
          if (sectionIndex < totalSections - 1)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _jumpToSection(sectionIndex + 1, totalSections);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: p.accent,
                  foregroundColor: p.onAccent,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.chevron_left_rounded, size: 18),
                label: Text(
                  'التالي: ${nextTitle ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            const Spacer(),
        ],
      ),
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
          closing:
              'لاَ تُحِبُّوا الْعَالَمَ وَلاَ الأَشْيَاءَ الَّتِي فِي الْعَالَمِ، لأَنَّ الْعَالَمَ يَمْضِي وَشَهْوَتَهُ، وَأَمَّا الَّذِي يَصْنَعُ مَشِيئَةَ اللهِ فَيَثْبُتُ إِلَى الأَبَدِ. آمِينَ.',
          fontScale: fontScale,
        );
      case 'LITURGY_ACTS_SLOT':
        return _buildEmbeddedScriptureBlock(
          p: p,
          title: 'قراءة الإبركسيس (أعمال آبائنا الرسل)',
          reading: _dailyReadings['acts'],
          opening:
              'فَصْلٌ مِنْ أَعْمَالِ آبَائِنَا الرُّسُلِ الأَطْهَارِ الْمَشْمُولِينَ بِنِعْمَةِ الرُّوحِ الْقُدُسِ، بَرَكَتُهُمْ تَكُونُ مَعَنَا آمِينَ:',
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
                      style: GoogleFonts.cairo(
                          fontSize: 11.5, color: p.accent, fontWeight: FontWeight.w600),
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
            GestureDetector(
              onLongPress: () => _copyVerseText('$ref\n$body'),
              child: Text(
                body,
                style: GoogleFonts.amiri(
                  fontSize: (_fontSize + 1) * fontScale,
                  height: 1.9,
                  color: p.ink,
                ),
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
              Text(
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
            Text(
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

  Widget _buildFlowingLiturgicalLine(
    AppPalette p,
    LiturgyVerse verse,
    _LiturgyStyles styles,
  ) {
    if (verse.role == 'rubric') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Text(verse.arabic, style: styles.rubric),
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

    final matchedHymnKw = _matchLiturgicalHymnKeyword(verse);
    final hasArabized = verse.arabized.isNotEmpty;
    final hasCoptic = verse.coptic.isNotEmpty && verse.coptic != verse.arabized;

    final Color? blockBg = isSilent
        ? p.surfaceSubtle
        : (isPeople && _layoutMode == 'kholagy_book'
            ? p.goldSoft.withValues(alpha: p.isDark ? 0.55 : 0.65)
            : null);

    return GestureDetector(
      onLongPress: () => _copyVerseText(verse.arabic),
      child: Container(
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
                    style: styles.roleBadge.copyWith(color: roleColor),
                  ),
                ),
                const Spacer(),
                if (matchedHymnKw != null)
                  GestureDetector(
                    onTap: () => _openMatchedHymn(matchedHymnKw),
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
                          Text('سماع اللحن', style: styles.hymnChip),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 7),

            // Mode A: Parallel 2-Column Coptic Reader Style (NO IntrinsicHeight — zero double-layout lag!)
            if (_layoutMode == 'coptic_reader' &&
                ((_showArabized && hasArabized) || (_showCoptic && hasCoptic)))
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_showArabic)
                    Expanded(
                      flex: 11,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          verse.arabic,
                          style: isPeople ? styles.arabicBold : styles.arabic,
                        ),
                      ),
                    ),
                  Expanded(
                    flex: 9,
                    child: Container(
                      padding: _showArabic ? const EdgeInsets.only(right: 10) : EdgeInsets.zero,
                      decoration: _showArabic
                          ? BoxDecoration(
                              border: Border(
                                right: BorderSide(color: p.border, width: 1),
                              ),
                            )
                          : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_showArabized && hasArabized)
                            Text(verse.arabized, style: styles.arabized),
                          if (_showCoptic && hasCoptic) ...[
                            if (_showArabized && hasArabized) const SizedBox(height: 6),
                            Text(
                              verse.coptic,
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.left,
                              style: styles.coptic,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else ...[
              if (_showArabic)
                Text(
                  verse.arabic,
                  style: isPeople ? styles.arabicBold : styles.arabic,
                ),
              if (_showArabized && _layoutMode != 'arabic' && hasArabized) ...[
                const SizedBox(height: 5),
                Text(verse.arabized, style: styles.arabized),
              ],
              if (_showCoptic &&
                  (_layoutMode == 'tri' || _layoutMode == 'kholagy_book') &&
                  hasCoptic) ...[
                const SizedBox(height: 5),
                Text(
                  verse.coptic,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  style: styles.coptic,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _langTogglePill(
    AppPalette p,
    String code,
    bool active,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? p.accent : p.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? p.accent : p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              size: 13,
              color: active ? p.onAccent : p.inkMuted,
            ),
            const SizedBox(width: 4),
            Text(
              code,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: active ? p.onAccent : p.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
