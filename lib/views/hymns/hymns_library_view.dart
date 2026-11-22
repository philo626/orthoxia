import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/coptic_calendar_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../models/hymn_model.dart';
import '../../providers/audio_provider.dart';
import '../search/global_search_view.dart';
import 'hymn_detail_view.dart';

class HymnsLibraryView extends StatefulWidget {
  const HymnsLibraryView({super.key});

  @override
  State<HymnsLibraryView> createState() => _HymnsLibraryViewState();
}

class _HymnsLibraryViewState extends State<HymnsLibraryView> {
  List<Hymn> _allHymns = [];
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool _isLoading = true;

  // Only real populated categories (removed empty dead `agpeya_coptic` chip!)
  static const List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'جميع الألحان'},
    {'id': 'liturgical', 'name': 'القداس ورفع البخور'},
    {'id': 'resurrection', 'name': 'القيامة والخماسين'},
    {'id': 'holy_week', 'name': 'أسبوع الآلام'},
    {'id': 'kiahk_nativity', 'name': 'كيهك والميلاد والغطاس'},
    {'id': 'great_lent', 'name': 'الصوم الكبير ويونان'},
    {'id': 'praise', 'name': 'التسبحة والأبصلمودية'},
    {'id': 'feasts', 'name': 'الأعياد والمناسبات'},
  ];

  @override
  void initState() {
    super.initState();
    _loadHymns();
  }

  Future<void> _loadHymns() async {
    try {
      final raw = await rootBundle.loadString('assets/data/hymns.json');
      final list = jsonDecode(raw) as List;
      _allHymns = list.map((item) => Hymn.fromJson(item)).toList();
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Auto-matches today's Coptic liturgical season to curated hymns!
  String _seasonalCategoryId(String seasonName) {
    if (seasonName.contains('كيهك') ||
        seasonName.contains('الميلاد') ||
        seasonName.contains('الغطاس')) {
      return 'kiahk_nativity';
    }
    if (seasonName.contains('الآلام') || seasonName.contains('البصخة')) {
      return 'holy_week';
    }
    if (seasonName.contains('القيامة') ||
        seasonName.contains('الخماسين') ||
        seasonName.contains('العنصرة')) {
      return 'resurrection';
    }
    if (seasonName.contains('الكبير') || seasonName.contains('نينوى')) {
      return 'great_lent';
    }
    if (seasonName.contains('الرسل') ||
        seasonName.contains('النيروز') ||
        seasonName.contains('الصليب') ||
        seasonName.contains('عيد')) {
      return 'feasts';
    }
    return 'liturgical';
  }

  List<Hymn> get _filteredHymns {
    final q = _searchQuery.toLowerCase();
    return _allHymns.where((h) {
      final matchCat =
          _selectedCategory == 'all' || h.categoryId == _selectedCategory;
      final matchSearch = q.isEmpty ||
          h.title.toLowerCase().contains(q) ||
          h.cantor.toLowerCase().contains(q) ||
          h.categoryName.toLowerCase().contains(q);
      return matchCat && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: p.background,
        body: Center(child: CircularProgressIndicator(color: p.accent)),
      );
    }

    final todayLiturgical = CopticCalendarService.todayLiturgical();
    final seasonCatId = _seasonalCategoryId(todayLiturgical.seasonName);
    final seasonalHymns = _allHymns
        .where((h) => h.categoryId == seasonCatId)
        .take(8)
        .toList();

    final audioProv = context.watch<AudioProvider>();
    final nowPlaying = audioProv.currentHymn;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Editorial Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الألحان والطقوس',
                          style: GoogleFonts.amiri(
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            color: p.ink,
                            height: 1.15,
                          ),
                        ),
                        Text(
                          '${_allHymns.length} لحناً قبطياً بالنص الثلاثي والتسجيل الصوتي',
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            color: p.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  LuxeCircleButton(
                    icon: Icons.search_rounded,
                    onTap: () => Navigator.push(
                        context, luxeRoute(const GlobalSearchView())),
                  ),
                ],
              ),
            ),

            // Active Now Playing Strip (when a hymn is loaded)
            if (nowPlaying != null)
              PressScale(
                scale: 0.985,
                onTap: () => Navigator.push(
                  context,
                  luxeRoute(HymnDetailView(
                      hymn: nowPlaying, playlist: _filteredHymns)),
                ),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.surfaceElevated,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: p.accent.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: const SizedBox(
                          width: 52,
                          height: 52,
                          child: SafeAssetImage(
                              'assets/images/hymn_album_art.jpg'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              audioProv.isLoading
                                  ? 'جارٍ تحميل الصوت...'
                                  : (audioProv.isPlaying
                                      ? 'قيد التشغيل الآن'
                                      : 'متوقف مؤقتاً'),
                              style: GoogleFonts.cairo(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: p.accent,
                              ),
                            ),
                            Text(
                              nowPlaying.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: p.ink,
                              ),
                            ),
                            Text(
                              audioProv.activeCantor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: p.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          if (audioProv.isPlaying) {
                            audioProv.pause();
                          } else {
                            audioProv.resume();
                          }
                        },
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.accent,
                          ),
                          child: audioProv.isLoading
                              ? Padding(
                                  padding: const EdgeInsets.all(11),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: p.onAccent,
                                  ),
                                )
                              : Icon(
                                  audioProv.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: p.onAccent,
                                  size: 24,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Search Field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded, color: p.accent),
                  hintText:
                      'ابحث في ${_allHymns.length} لحناً باسم اللحن أو المرتل...',
                  hintStyle: GoogleFonts.cairo(color: p.inkSubtle, fontSize: 12.5),
                  filled: true,
                  fillColor: p.surfaceElevated,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: p.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: p.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: p.accent, width: 1.2),
                  ),
                ),
              ),
            ),

            // Categories Chips
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat['id'];
                  return ChoiceChip(
                    label: Text(
                      cat['name']!,
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? p.onAccent : p.ink,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: p.accent,
                    backgroundColor: p.surfaceElevated,
                    side: BorderSide(
                      color: isSelected ? p.accent : p.border,
                    ),
                    showCheckmark: false,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = cat['id']!),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Main scrollable body (Seasonal Strip + Filtered Hymns List)
            Expanded(
              child: _filteredHymns.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.music_off_rounded,
                              size: 40, color: p.inkSubtle),
                          const SizedBox(height: 8),
                          Text(
                            'لا توجد ألحان مطابقة للبحث',
                            style: GoogleFonts.cairo(color: p.inkMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 100),
                      itemCount: _filteredHymns.length +
                          (_selectedCategory == 'all' &&
                                  _searchQuery.isEmpty &&
                                  seasonalHymns.isNotEmpty
                              ? 1
                              : 0),
                      itemBuilder: (context, rawIdx) {
                        final hasSeasonHeader = _selectedCategory == 'all' &&
                            _searchQuery.isEmpty &&
                            seasonalHymns.isNotEmpty;
                        if (hasSeasonHeader && rawIdx == 0) {
                          return _buildSeasonalRibbon(
                            p,
                            todayLiturgical.seasonName,
                            seasonCatId,
                            seasonalHymns,
                          );
                        }
                        final index = hasSeasonHeader ? rawIdx - 1 : rawIdx;
                        final hymn = _filteredHymns[index];
                        return _buildHymnRow(p, hymn, audioProv);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonalRibbon(
    AppPalette p,
    String seasonName,
    String seasonCatId,
    List<Hymn> seasonalHymns,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded, color: p.accent, size: 17),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'ألحان موسم اليوم — $seasonName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _selectedCategory = seasonCatId),
                child: Text(
                  'عرض الكل',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: p.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: seasonalHymns.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, idx) {
                final h = seasonalHymns[idx];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    luxeRoute(HymnDetailView(hymn: h, playlist: seasonalHymns)),
                  ),
                  child: Container(
                    width: 178,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: p.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: p.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          h.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: p.ink,
                            height: 1.25,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              h.exactYoutube
                                  ? Icons.play_circle_filled_rounded
                                  : Icons.audiotrack_rounded,
                              size: 13,
                              color: h.exactYoutube ? p.crimson : p.accent,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                h.cantor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  color: p.inkMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHymnRow(AppPalette p, Hymn hymn, AudioProvider audioProv) {
    final isCurrent = audioProv.currentHymn?.id == hymn.id;
    final isCurrentPlaying = isCurrent && audioProv.isPlaying;
    final isCurrentLoading = isCurrent && audioProv.isLoading;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? p.accent : p.border,
          width: isCurrent ? 1.3 : 1,
        ),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: GestureDetector(
          onTap: () async {
            HapticFeedback.lightImpact();
            if (isCurrentPlaying) {
              audioProv.pause();
            } else {
              final ok = await audioProv.play(hymn);
              if (!ok && mounted) {
                // Open the full detail screen where YouTube playback is 1 tap away
                Navigator.push(
                  context,
                  luxeRoute(
                      HymnDetailView(hymn: hymn, playlist: _filteredHymns)),
                );
              }
            }
          },
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isCurrent ? p.accent : p.accentSoft,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: p.accent.withValues(alpha: 0.35),
              ),
            ),
            child: isCurrentLoading
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isCurrent ? p.onAccent : p.accent,
                    ),
                  )
                : Icon(
                    isCurrentPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: isCurrent ? p.onAccent : p.accent,
                    size: 24,
                  ),
          ),
        ),
        title: Text(
          hymn.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: p.ink,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: hymn.exactYoutube ? p.crimsonSoft : p.accentSoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  hymn.exactYoutube ? 'فيديو + صوت' : 'نص + صوت',
                  style: GoogleFonts.cairo(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: hymn.exactYoutube ? p.crimson : p.accent,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${hymn.cantor} • ${hymn.categoryName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    color: p.inkMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: Icon(
          Icons.chevron_left_rounded,
          size: 22,
          color: p.inkSubtle,
        ),
        onTap: () {
          Navigator.push(
            context,
            luxeRoute(
              HymnDetailView(
                hymn: hymn,
                playlist: _filteredHymns,
              ),
            ),
          );
        },
        ),
      ),
    );
  }
}
