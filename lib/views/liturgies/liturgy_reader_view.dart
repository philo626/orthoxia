import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/coptic_calendar_service.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../models/liturgy_model.dart';
import '../../providers/church_mode_provider.dart';
import '../../providers/liturgy_provider.dart';
import '../../providers/theme_provider.dart';
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
  double _fontSize = 17.0;
  int _selectedSectionIndex = 0; // 0 = first section
  String _activeRoleFilter = 'all'; // 'all', 'priest', 'deacon', 'people'
  String _activeDisplayMode = 'all'; // 'all' (trilingual), 'arabic', 'arabized', 'coptic'
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedSectionIndex = widget.initialSectionIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LiturgyProvider>().loadLiturgies();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(int secIdx) {
    setState(() => _selectedSectionIndex = secIdx);
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _showLiturgicalIndexSheet(Liturgy liturgy) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Color(0xFF13151D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppColors.primaryGold, width: 1.5),
            ),
          ),
          child: Column(
            children: [
              // Header
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
                            'فهرس صلوات ومحطات القداس',
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

              // Sections list
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
                          width: 32,
                          height: 32,
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
                          '${sec.verses.length} ربعاً وطقساً صلواتياً',
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
              Text(
                'اختر القداس الإلهي (الخولاجي المقدس):',
                style: GoogleFonts.cairo(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGoldLight,
                ),
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
                      color: isSel ? AppColors.primaryGold : Colors.transparent,
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
                          fontSize: 14.5,
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
      return Scaffold(
        backgroundColor: AppColors.deepNavy,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryGold),
        ),
      );
    }

    final sections = currentLiturgy.sections;
    final safeSecIdx = _selectedSectionIndex.clamp(0, sections.length - 1);
    final activeSection = sections[safeSecIdx];

    // Filter verses by selected role
    final filteredVerses = activeSection.verses.where((v) {
      if (_activeRoleFilter == 'all') return true;
      return v.role == _activeRoleFilter || v.role == 'all';
    }).toList();

    return Scaffold(
      backgroundColor: churchMode.isChurchMode ? Colors.black : AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: churchMode.isChurchMode ? Colors.black : const Color(0xFF10121A),
        elevation: 0,
        title: InkWell(
          onTap: () => _showLiturgyPicker(liturgyProvider),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    currentLiturgy.title,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primaryGoldLight,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primaryGold),
              ],
            ),
          ),
        ),
        actions: [
          // Index button
          IconButton(
            tooltip: 'فهرس القداس',
            icon: const Icon(Icons.format_list_bulleted_rounded, color: AppColors.primaryGold),
            onPressed: () => _showLiturgicalIndexSheet(currentLiturgy),
          ),
          // Font size controls
          IconButton(
            icon: const Icon(Icons.text_fields_rounded, color: AppColors.primaryGold, size: 20),
            onPressed: () {
              setState(() {
                _fontSize = _fontSize >= 22.0 ? 15.0 : _fontSize + 2.0;
              });
            },
          ),
          // Smart Church Mode toggle
          IconButton(
            tooltip: 'وضع الكنيسة الذكي',
            icon: Icon(
              churchMode.isChurchMode ? Icons.church_rounded : Icons.church_outlined,
              color: churchMode.isChurchMode ? AppColors.primaryGold : AppColors.textLight,
            ),
            onPressed: () => churchMode.toggleChurchMode(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Horizontal Chapters Bar (مراحل القداس)
            Container(
              height: 44,
              color: const Color(0xFF13151E),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: sections.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final isSel = idx == safeSecIdx;
                  final secTitle = sections[idx].title;
                  // Short title for chip
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
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      _scrollToSection(idx);
                    },
                  );
                },
              ),
            ),

            // 2. Control Bar: Role Filter & Language Mode
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF0F1118),
                border: Border(bottom: BorderSide(color: Color(0xFF1E212D))),
              ),
              child: Row(
                children: [
                  // Role Filter Buttons
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
                          _buildRoleChip('people', '⚪ الشعب', const Color(0xFF423719)),
                        ],
                      ),
                    ),
                  ),

                  // Language Mode Dropdown
                  PopupMenuButton<String>(
                    initialValue: _activeDisplayMode,
                    tooltip: 'لغة العرض',
                    onSelected: (mode) => setState(() => _activeDisplayMode = mode),
                    icon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getDisplayModeLabel(_activeDisplayMode),
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGoldLight,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: AppColors.primaryGold, size: 16),
                        ],
                      ),
                    ),
                    itemBuilder: (context) => [
                      _buildMenuItem('all', 'عرض ثلاثي (عربي • معرب • قبطي)'),
                      _buildMenuItem('arabic', 'عربي فقط'),
                      _buildMenuItem('arabized', 'قبطي معرب فقط'),
                      _buildMenuItem('coptic', 'قبطي فقط'),
                    ],
                  ),
                ],
              ),
            ),

            // 3. Liturgical Verses Flow (Lazy ListView.builder for 60fps smoothness on all devices)
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

                  // Items: 0 = Section Banner, [optional Synaxarium if no Praxis marker], verses..., Footer
                  final totalItems = filteredVerses.length + 2;
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 84),
                    itemCount: totalItems,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF281E12), Color(0xFF151412)],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: AppColors.primaryGold, width: 1.2),
                              ),
                              child: Row(
                                children: [
                                  const CopticCross(size: 24),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          activeSection.title,
                                          style: GoogleFonts.cairo(
                                            fontSize: 16 * fontScale,
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
                                              color: AppColors.textMuted,
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
                                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E212D),
                                    foregroundColor: AppColors.primaryGoldLight,
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
                                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGold,
                                    foregroundColor: Colors.black,
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
      // Floating Index Quick Access
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
          color: isSel ? Colors.white : AppColors.textLight,
        ),
      ),
      selected: isSel,
      selectedColor: bgColor ?? AppColors.primaryGold,
      backgroundColor: const Color(0xFF1A1C27),
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
        return 'قبطي معرب';
      case 'coptic':
        return 'قبطي';
      default:
        return 'عرض ثلاثي';
    }
  }

  /// Interactive canonical card embedded into the Liturgy of the Word
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
    final isRubric = verse.role == 'all' &&
        (verse.arabic.contains('يقف') ||
            verse.arabic.contains('يقول الكاهن') ||
            verse.arabic.contains('يرشم') ||
            verse.arabic.contains('بعد رفع') ||
            verse.arabic.contains('يرتل') ||
            verse.arabic.contains('ينشف') ||
            verse.arabic.contains('سر') ||
            verse.coptic.isEmpty);

    // 1. Ritual Rubric Direction
    if (isRubric) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF141722),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primaryGold.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.primaryGold, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                verse.arabic,
                style: GoogleFonts.cairo(
                  fontSize: 12.5 * fontScale,
                  fontStyle: FontStyle.italic,
                  color: AppColors.primaryGoldLight,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Role Colors & Badges
    Color roleBadgeBg;
    Color roleBorder;
    String roleLabel = verse.roleArabic.isNotEmpty ? verse.roleArabic : 'الشعب';

    if (verse.role == 'priest' || roleLabel.contains('الكاهن')) {
      roleBadgeBg = const Color(0xFF6E1818);
      roleBorder = const Color(0xFFB71C1C);
    } else if (verse.role == 'deacon' || roleLabel.contains('الشماس')) {
      roleBadgeBg = const Color(0xFF123B68);
      roleBorder = const Color(0xFF1976D2);
    } else {
      roleBadgeBg = const Color(0xFF382E17);
      roleBorder = AppColors.primaryGold;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF171923),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGold.withValues(alpha: 0.2),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Role Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: roleBadgeBg.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: roleBorder.withValues(alpha: 0.5))),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: roleBorder,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  roleLabel,
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Arabic Liturgical Text
                if (_activeDisplayMode == 'all' || _activeDisplayMode == 'arabic')
                  SelectableText(
                    verse.arabic,
                    style: GoogleFonts.cairo(
                      fontSize: _fontSize * fontScale,
                      fontWeight: FontWeight.w600,
                      height: 1.65,
                      color: const Color(0xFFF5F5F5),
                    ),
                  ),

                // Coptic Arabized (المعرب)
                if ((_activeDisplayMode == 'all' || _activeDisplayMode == 'arabized') &&
                    verse.arabized.isNotEmpty) ...[
                  if (_activeDisplayMode == 'all') const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F222F),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primaryGold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'قبطي معرب:',
                          style: GoogleFonts.cairo(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          verse.arabized,
                          style: GoogleFonts.cairo(
                            fontSize: (_fontSize - 1.5) * fontScale,
                            height: 1.6,
                            color: AppColors.primaryGoldLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Coptic Script
                if ((_activeDisplayMode == 'all' || _activeDisplayMode == 'coptic') &&
                    verse.coptic.isNotEmpty) ...[
                  if (_activeDisplayMode == 'all') const SizedBox(height: 8),
                  SelectableText(
                    verse.coptic,
                    style: TextStyle(
                      fontFamily: 'Coptic',
                      fontSize: (_fontSize - 1.0) * fontScale,
                      height: 1.5,
                      color: const Color(0xFFB0BEC5),
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
