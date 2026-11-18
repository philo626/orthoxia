import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/coptic_calendar_service.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../models/hymn_model.dart';
import '../../models/liturgy_model.dart';
import '../../providers/church_mode_provider.dart';
import '../../providers/liturgy_provider.dart';
import '../../providers/theme_provider.dart';
import '../hymns/hymn_detail_view.dart';
import '../synaxarium/synaxarium_daily_view.dart';

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
  double _fontSize = 18.0;
  int _selectedSectionIndex = 0;
  String _activeRoleFilter = 'all'; // 'all', 'priest', 'priest_silent', 'deacon', 'people'
  String _activeDisplayMode = 'arabized'; // Default: Clear Arabic + Arabized (like Orsozoxi + Katamars)
  bool _showSilentPrayers = false;
  bool _showRubrics = false;
  String _searchQuery = '';
  bool _showSearchBar = false;

  // Auto-scroll (وضع المتابعة التلقائي أثناء القداس)
  bool _isAutoScrolling = false;
  double _autoScrollSpeed = 1.0; // 1.0, 1.5, 2.0
  Timer? _autoScrollTimer;

  // Cached hymns for 1-tap liturgical chant playback inside the liturgy
  List<Hymn> _cachedHymns = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedSectionIndex = widget.initialSectionIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LiturgyProvider>().loadLiturgies();
      _loadLiturgicalHymns();
    });
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
          _scrollController.jumpTo((current + (1.2 * _autoScrollSpeed)).clamp(0.0, maxExtent));
        }
      });
    }
  }

  void _cycleAutoScrollSpeed() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_autoScrollSpeed == 1.0) {
        _autoScrollSpeed = 1.5;
      } else if (_autoScrollSpeed == 1.5) {
        _autoScrollSpeed = 2.2;
      } else {
        _autoScrollSpeed = 1.0;
      }
    });
  }

  void _scrollToSection(int secIdx) {
    setState(() => _selectedSectionIndex = secIdx);
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  IconData _stationIconForTitle(String title) {
    if (title.contains('الحمل') || title.contains('تقدمة')) return Icons.bakery_dining_rounded;
    if (title.contains('الكلمة') || title.contains('الإنجيل') || title.contains('تحليل')) return Icons.menu_book_rounded;
    if (title.contains('الصلح')) return Icons.handshake_rounded;
    if (title.contains('الأنافورا') || title.contains('التقديس') || title.contains('الشاروبيم')) return Icons.local_fire_department_rounded;
    if (title.contains('أواشي') || title.contains('المجمع')) return Icons.people_alt_rounded;
    if (title.contains('القسمة')) return Icons.wine_bar_rounded;
    if (title.contains('الخضوع') || title.contains('الاعتراف')) return Icons.self_improvement_rounded;
    if (title.contains('التناول') || title.contains('١٥٠')) return Icons.auto_awesome_rounded;
    return Icons.church_rounded;
  }

  /// Matches a liturgical people response to a runnable Hymn from our library
  Hymn? _matchLiturgicalHymn(LiturgyVerse verse) {
    if (_cachedHymns.isEmpty || verse.role != 'people') return null;
    final ar = verse.arabic;
    final arabized = verse.arabized;

    String? targetKeyword;
    if (ar.contains('قدوس الله') || arabized.contains('أجيوس')) {
      targetKeyword = 'أجيوس';
    } else if (ar.contains('بشفاعات والدة الإله') || arabized.contains('هيتين')) {
      targetKeyword = 'هيتني';
    } else if (ar.contains('الشاروبيم يسجدون') || ar.contains('بي شيروبيم')) {
      targetKeyword = 'الشاروبيم';
    } else if (ar.contains('بموتك يا رب نبشر') || arabized.contains('آمين آمين')) {
      targetKeyword = 'بموتك';
    } else if (ar.contains('سبحوا الله في جميع قديسيه') || ar.contains('المزمور المئة والخمسون')) {
      targetKeyword = '150';
    } else if (ar.contains('نعظمك يا أم النور') || ar.contains('نؤمن بإله واحد')) {
      targetKeyword = 'قانون الايمان';
    } else if (ar.contains('نسجد لآب النور') || arabized.contains('تين أو أوشت')) {
      targetKeyword = 'تين أوأوشت';
    }

    if (targetKeyword == null) return null;
    for (final h in _cachedHymns) {
      if (h.title.contains(targetKeyword)) return h;
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
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.78,
          decoration: const BoxDecoration(
            color: Color(0xFF13151D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppColors.primaryGold, width: 1.5),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFF232532))),
                ),
                child: Row(
                  children: [
                    const CopticCross(size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'خريطة ومحطات القداس الإلهي',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGoldLight,
                            ),
                          ),
                          Text(
                            liturgy.title,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textLight),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: liturgy.sections.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final sec = liturgy.sections[idx];
                    final isCurrent = idx == _selectedSectionIndex;
                    return Material(
                      type: MaterialType.transparency,
                      child: ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isCurrent
                                ? AppColors.primaryGold
                                : AppColors.primaryGold.withValues(alpha: 0.15),
                            width: isCurrent ? 1.5 : 0.8,
                          ),
                        ),
                        tileColor: isCurrent
                            ? AppColors.primaryGold.withValues(alpha: 0.12)
                            : const Color(0xFF1A1C27),
                        leading: Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isCurrent ? AppColors.primaryGold : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primaryGold, width: 1),
                          ),
                          child: Text(
                            '${idx + 1}',
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? Colors.black : AppColors.primaryGoldLight,
                            ),
                          ),
                        ),
                        title: Text(
                          sec.title,
                          style: GoogleFonts.cairo(
                            fontSize: 13.5,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                            color: isCurrent ? AppColors.primaryGoldLight : Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          '${sec.verses.length} صلاة ومرداً وطقساً',
                          style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
                        ),
                        trailing: isCurrent
                            ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGold, size: 20)
                            : const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 14),
                        onTap: () {
                          Navigator.pop(ctx);
                          _scrollToSection(idx);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLiturgyPicker(LiturgyProvider prov) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFF13151D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.primaryGold, width: 1.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const CopticCross(size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'اختر القداس الإلهي (الخولاجي المقدس):',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGoldLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...prov.liturgies.map((lit) {
                final isSel = prov.selectedLiturgy?.id == lit.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isSel
                        ? AppColors.primaryGold.withValues(alpha: 0.15)
                        : const Color(0xFF1A1C27),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSel ? AppColors.primaryGold : Colors.white10,
                      width: 1.2,
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      leading: const CopticCross(size: 22),
                      title: Text(
                        lit.title,
                        style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSel ? AppColors.primaryGoldLight : Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        lit.description,
                        style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                      trailing: isSel
                          ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryGold)
                          : null,
                      onTap: () {
                        prov.selectLiturgy(lit);
                        Navigator.pop(ctx);
                        setState(() => _selectedSectionIndex = 0);
                      },
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final liturgyProvider = context.watch<LiturgyProvider>();
    final churchMode = context.watch<ChurchModeProvider>();
    final fontScale = context.watch<ThemeProvider>().fontScale;
    final currentLiturgy = liturgyProvider.selectedLiturgy;

    if (liturgyProvider.isLoading || currentLiturgy == null) {
      return const Scaffold(
        backgroundColor: AppColors.deepNavy,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryGold),
        ),
      );
    }

    final sections = currentLiturgy.sections;
    final safeSecIdx = _selectedSectionIndex.clamp(0, sections.length - 1);
    final activeSection = sections[safeSecIdx];
    final progressValue = sections.isEmpty ? 0.0 : (safeSecIdx + 1) / sections.length;

    // Filter verses by selected role, silent toggle, rubrics toggle, and search query
    final filteredVerses = activeSection.verses.where((v) {
      if (!_showSilentPrayers && v.role == 'priest_silent') return false;
      if (!_showRubrics && v.role == 'rubric') return false;
      if (_activeRoleFilter != 'all') {
        if (_activeRoleFilter == 'priest' && v.role != 'priest' && v.role != 'priest_silent') {
          return false;
        } else if (_activeRoleFilter != 'priest' && v.role != _activeRoleFilter) {
          return false;
        }
      }
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim();
        return v.arabic.contains(q) || v.arabized.contains(q) || v.roleArabic.contains(q);
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: churchMode.isChurchMode ? Colors.black : AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: churchMode.isChurchMode ? Colors.black : const Color(0xFF10121A),
        elevation: 0,
        title: InkWell(
          onTap: () => _showLiturgyPicker(liturgyProvider),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CopticCross(size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    currentLiturgy.title.split('(').first.trim(),
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: AppColors.primaryGoldLight,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primaryGold, size: 20),
              ],
            ),
          ),
        ),
        actions: [
          // Search toggle
          IconButton(
            tooltip: 'بحث في القداس',
            icon: Icon(
              _showSearchBar ? Icons.search_off_rounded : Icons.search_rounded,
              color: _showSearchBar ? AppColors.primaryGold : AppColors.textLight,
              size: 21,
            ),
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) _searchQuery = '';
              });
            },
          ),
          // Auto-scroll toggle
          IconButton(
            tooltip: _isAutoScrolling ? 'إيقاف التمرير التلقائي' : 'تمرير تلقائي مع القداس',
            icon: Icon(
              _isAutoScrolling ? Icons.pause_circle_filled_rounded : Icons.play_circle_outline_rounded,
              color: _isAutoScrolling ? Colors.greenAccent : AppColors.primaryGold,
              size: 22,
            ),
            onPressed: _toggleAutoScroll,
          ),
          if (_isAutoScrolling)
            GestureDetector(
              onTap: _cycleAutoScrollSpeed,
              child: Container(
                alignment: Alignment.center,
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryGold,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_autoScrollSpeed}x',
                  style: GoogleFonts.roboto(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          // Font size controls
          IconButton(
            tooltip: 'حجم الخط',
            icon: const Icon(Icons.text_fields_rounded, color: AppColors.primaryGold, size: 20),
            onPressed: () {
              setState(() {
                _fontSize = _fontSize >= 24.0 ? 16.0 : _fontSize + 2.0;
              });
            },
          ),
          // Smart Church Mode toggle
          IconButton(
            tooltip: 'وضع الكنيسة الذكي',
            icon: Icon(
              churchMode.isChurchMode ? Icons.church_rounded : Icons.church_outlined,
              color: churchMode.isChurchMode ? AppColors.primaryGold : AppColors.textLight,
              size: 20,
            ),
            onPressed: () => churchMode.toggleChurchMode(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Optional Live Search Bar
            if (_showSearchBar)
              Container(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
                color: const Color(0xFF13151E),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن صلاة أو أوشية أو مرد في هذه المحطة...',
                    hintStyle: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryGold, size: 18),
                    filled: true,
                    fillColor: const Color(0xFF1C1F2B),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

            // 1. Visual Liturgical Timeline & Station Stepper
            Container(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              decoration: const BoxDecoration(
                color: Color(0xFF13151E),
                border: Border(bottom: BorderSide(color: Color(0xFF222533))),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'المحطة ${safeSecIdx + 1} من ${sections.length}',
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progressValue,
                            minHeight: 5,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () => _showLiturgicalIndexSheet(currentLiturgy),
                        child: Row(
                          children: [
                            const Icon(Icons.map_rounded, size: 14, color: AppColors.primaryGoldLight),
                            const SizedBox(width: 4),
                            Text(
                              'خريطة القداس',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGoldLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: sections.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final isSel = idx == safeSecIdx;
                        final secTitle = sections[idx].title;
                        final shortTitle = secTitle.split('(').first.trim();
                        return ChoiceChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            shortTitle,
                            style: GoogleFonts.cairo(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isSel ? Colors.black : AppColors.textLight,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: AppColors.primaryGold,
                          backgroundColor: const Color(0xFF1E212D),
                          showCheckmark: false,
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            _scrollToSection(idx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 2. Control Bar: Role Filter, Silent Prayers Toggle & Language Mode
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF0F1118),
                border: Border(bottom: BorderSide(color: Color(0xFF1E212D))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildRoleChip('all', 'الكل', null),
                          const SizedBox(width: 6),
                          _buildRoleChip('priest', '🔴 الكاهن', const Color(0xFF7A1C1C)),
                          const SizedBox(width: 6),
                          _buildRoleChip('deacon', '🔵 الشماس', const Color(0xFF163E6C)),
                          const SizedBox(width: 6),
                          _buildRoleChip('people', '🟡 الشعب', const Color(0xFF5A4618)),
                          const SizedBox(width: 6),
                          FilterChip(
                            visualDensity: VisualDensity.compact,
                            selected: _showSilentPrayers,
                            selectedColor: const Color(0xFF4A1E6D),
                            backgroundColor: const Color(0xFF1A1C27),
                            checkmarkColor: Colors.white,
                            label: Text(
                              '🤫 الصلوات السرية',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            onSelected: (val) {
                              HapticFeedback.selectionClick();
                              setState(() => _showSilentPrayers = val);
                            },
                          ),
                          const SizedBox(width: 6),
                          FilterChip(
                            visualDensity: VisualDensity.compact,
                            selected: _showRubrics,
                            selectedColor: const Color(0xFF3E3216),
                            backgroundColor: const Color(0xFF1A1C27),
                            checkmarkColor: AppColors.primaryGoldLight,
                            label: Text(
                              '📜 شرح الطقس',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            onSelected: (val) {
                              HapticFeedback.selectionClick();
                              setState(() => _showRubrics = val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  PopupMenuButton<String>(
                    initialValue: _activeDisplayMode,
                    tooltip: 'لغة العرض',
                    onSelected: (mode) => setState(() => _activeDisplayMode = mode),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.translate_rounded, color: AppColors.primaryGold, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            _getDisplayModeLabel(_activeDisplayMode),
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGoldLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      _buildMenuItem('all', 'عرض ثلاثي (عربي • معرب • قبطي)'),
                      _buildMenuItem('arabic', 'عربي فقط (قراءة سريعة)'),
                      _buildMenuItem('arabized', 'عربي + قبطي معرب'),
                      _buildMenuItem('coptic', 'قبطي أصلي فقط (Ⲧⲉⲛⲟⲩⲱϣⲧ)'),
                    ],
                  ),
                ],
              ),
            ),

            // 3. Liturgical Verses Flow
            Expanded(
              child: Builder(
                builder: (context) {
                  final showSynaxarium = activeSection.id.contains('2_word') ||
                      activeSection.title.contains('الكلمة');
                  int synaxInsertAfterIdx = -1;
                  if (showSynaxarium) {
                    for (int i = 0; i < filteredVerses.length; i++) {
                      final ar = filteredVerses[i].arabic;
                      if (ar.contains('الإبركسيس') || ar.contains('أعمال آبائنا الرسل') || ar.contains('السنكسار')) {
                        synaxInsertAfterIdx = i;
                        break;
                      }
                    }
                  }

                  final totalItems = filteredVerses.length + 2;
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    itemCount: totalItems,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Creative Station Hero Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2B2113), Color(0xFF14151D)],
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.primaryGold, width: 1.3),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryGold.withValues(alpha: 0.14),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryGold.withValues(alpha: 0.18),
                                      border: Border.all(color: AppColors.primaryGold),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _stationIconForTitle(activeSection.title),
                                        color: AppColors.primaryGoldLight,
                                        size: 22,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          activeSection.title,
                                          style: GoogleFonts.cairo(
                                            fontSize: 15.5 * fontScale,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryGoldLight,
                                          ),
                                        ),
                                        if (activeSection.tafseer.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            activeSection.tafseer,
                                            style: GoogleFonts.cairo(
                                              fontSize: 12 * fontScale,
                                              color: Colors.white70,
                                              height: 1.45,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (showSynaxarium && synaxInsertAfterIdx == -1)
                              _buildEmbeddedSynaxariumCard(fontScale),
                          ],
                        );
                      }

                      if (index == totalItems - 1) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (safeSecIdx > 0)
                                ElevatedButton.icon(
                                  onPressed: () => _scrollToSection(safeSecIdx - 1),
                                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                                  label: Text(
                                    'المحطة السابقة',
                                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.5),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E212D),
                                    foregroundColor: AppColors.primaryGoldLight,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                              if (safeSecIdx < sections.length - 1)
                                ElevatedButton.icon(
                                  onPressed: () => _scrollToSection(safeSecIdx + 1),
                                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                                  label: Text(
                                    'المحطة التالية',
                                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.5),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGold,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                )
                              else
                                const SizedBox.shrink(),
                            ],
                          ),
                        );
                      }

                      final verseIdx = index - 1;
                      final verseWidget = _buildVerseItem(filteredVerses[verseIdx], fontScale);
                      if (showSynaxarium && verseIdx == synaxInsertAfterIdx) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            verseWidget,
                            _buildEmbeddedSynaxariumCard(fontScale),
                          ],
                        );
                      }
                      return verseWidget;
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: Colors.black,
        elevation: 6,
        icon: const Icon(Icons.menu_book_rounded, size: 20),
        label: Text(
          'فهرس القداس',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        onPressed: () => _showLiturgicalIndexSheet(currentLiturgy),
      ),
    );
  }

  Widget _buildRoleChip(String roleId, String label, Color? bgColor) {
    final isSel = _activeRoleFilter == roleId;
    return ChoiceChip(
      visualDensity: VisualDensity.compact,
      label: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          color: isSel ? (bgColor == null ? Colors.black : Colors.white) : AppColors.textLight,
        ),
      ),
      selected: isSel,
      selectedColor: bgColor ?? AppColors.primaryGold,
      backgroundColor: const Color(0xFF1A1C27),
      showCheckmark: false,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() => _activeRoleFilter = roleId);
      },
    );
  }

  PopupMenuItem<String> _buildMenuItem(String val, String text) {
    return PopupMenuItem<String>(
      value: val,
      child: Text(
        text,
        style: GoogleFonts.cairo(
          fontSize: 12.5,
          fontWeight: _activeDisplayMode == val ? FontWeight.bold : FontWeight.normal,
          color: _activeDisplayMode == val ? AppColors.primaryGold : Colors.white,
        ),
      ),
    );
  }

  String _getDisplayModeLabel(String mode) {
    switch (mode) {
      case 'arabic':
        return 'عربي فقط';
      case 'arabized':
        return 'عربي + معرب';
      case 'coptic':
        return 'قبطي';
      default:
        return 'ثلاثي';
    }
  }

  Widget _buildEmbeddedSynaxariumCard(double fontScale) {
    final today = CopticCalendarService.fromGregorian(DateTime.now());
    final synEvents = CopticCalendarService.getSynaxariumEventsForDate(today.month, today.day);
    final topEvent = synEvents.isNotEmpty ? synEvents.first : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1712),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryGold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withValues(alpha: 0.15),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CopticCross(size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'السنكسار القبطي المقدس (تذكار اليوم)',
                      style: GoogleFonts.cairo(
                        fontSize: 14.5 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGoldLight,
                      ),
                    ),
                    Text(
                      'يُقرأ بعد الإبركسيس وقبل الثلاث تقديسات والإنجيل',
                      style: GoogleFonts.cairo(
                        fontSize: 11 * fontScale,
                        color: AppColors.primaryGold,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    luxeRoute(SynaxariumDailyView(
                      initialMonth: today.month,
                      initialDay: today.day,
                    )),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'فتح السنكسار',
                  style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (topEvent != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✝ ${topEvent['title']}',
                    style: GoogleFonts.cairo(
                      fontSize: 13 * fontScale,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${topEvent['text']}'.replaceAll('\n', ' ').trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 11.5 * fontScale,
                      color: AppColors.textMuted,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerseItem(LiturgyVerse verse, double fontScale) {
    final isRubric = verse.role == 'rubric';

    // 1. Ritual Rubric Ribbon Card (الطقس والحركة الليتورجية)
    if (isRubric) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 7),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1D1A14), Color(0xFF14161F)],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryGold.withValues(alpha: 0.38),
            width: 0.9,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.auto_awesome_rounded, color: AppColors.primaryGold, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                verse.arabic,
                style: GoogleFonts.cairo(
                  fontSize: 13 * fontScale,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryGoldLight,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 2. Role Colors, Icons & Badges for Spoken Prayers
    Color roleBadgeBg;
    Color roleBorder;
    IconData roleIcon;
    String roleLabel = verse.roleArabic.isNotEmpty ? verse.roleArabic : 'الشعب / الخورس';

    if (verse.role == 'priest_silent') {
      roleBadgeBg = const Color(0xFF421C5E);
      roleBorder = const Color(0xFFAB47BC);
      roleIcon = Icons.lock_clock_rounded;
    } else if (verse.role == 'priest' || roleLabel.contains('الكاهن')) {
      roleBadgeBg = const Color(0xFF6E1818);
      roleBorder = const Color(0xFFEF5350);
      roleIcon = Icons.auto_awesome_rounded;
    } else if (verse.role == 'deacon' || roleLabel.contains('الشماس')) {
      roleBadgeBg = const Color(0xFF123B68);
      roleBorder = const Color(0xFF42A5F5);
      roleIcon = Icons.campaign_rounded;
    } else {
      roleBadgeBg = const Color(0xFF3E3115);
      roleBorder = AppColors.primaryGold;
      roleIcon = Icons.groups_rounded;
    }

    final matchedHymn = _matchLiturgicalHymn(verse);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: verse.role == 'priest_silent' ? const Color(0xFF191524) : const Color(0xFF171923),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: roleBorder.withValues(alpha: 0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: roleBadgeBg.withValues(alpha: 0.88),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              border: Border(bottom: BorderSide(color: roleBorder.withValues(alpha: 0.45))),
            ),
            child: Row(
              children: [
                Icon(roleIcon, color: Colors.white, size: 15),
                const SizedBox(width: 8),
                Text(
                  roleLabel,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                if (matchedHymn != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          luxeRoute(HymnDetailView(hymn: matchedHymn, playlist: _cachedHymns)),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryGold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.music_note_rounded, size: 13, color: Colors.black),
                            const SizedBox(width: 4),
                            Text(
                              'استمع للحن',
                              style: GoogleFonts.cairo(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: verse.arabic));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم نسخ النص', style: GoogleFonts.cairo(fontSize: 12)),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Icon(Icons.copy_rounded, size: 14, color: Colors.white70),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Modern Clear Arabic Liturgical Text
                if (_activeDisplayMode != 'coptic')
                  SelectableText(
                    verse.arabic,
                    style: GoogleFonts.amiri(
                      fontSize: (_fontSize + 2.0) * fontScale,
                      fontWeight: FontWeight.w600,
                      height: 1.75,
                      color: const Color(0xFFF9F6F0),
                    ),
                  ),

                // 2. Coptic Arabized (القبطي المعرب لمنطق اللحن)
                if ((_activeDisplayMode == 'all' || _activeDisplayMode == 'arabized') &&
                    verse.arabized.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F222F),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryGold.withValues(alpha: 0.32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.record_voice_over_rounded, size: 13, color: AppColors.primaryGold),
                            const SizedBox(width: 5),
                            Text(
                              'النطق القبطي المعرب:',
                              style: GoogleFonts.cairo(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        SelectableText(
                          verse.arabized,
                          style: GoogleFonts.cairo(
                            fontSize: (_fontSize - 2.0) * fontScale,
                            height: 1.65,
                            color: AppColors.primaryGoldLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // 3. Authentic Bohairic Coptic Unicode Script
                if ((_activeDisplayMode == 'all' || _activeDisplayMode == 'coptic') &&
                    verse.coptic.isNotEmpty &&
                    verse.coptic != verse.arabized) ...[
                  if (_activeDisplayMode == 'all') const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SelectableText(
                      verse.coptic,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontFamily: 'Coptic',
                        fontSize: (_fontSize - 1.5) * fontScale,
                        height: 1.55,
                        color: const Color(0xFFCFD8DC),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
