import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
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

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'name': 'جميع الألحان'},
    {'id': 'liturgical', 'name': 'القداس ورفع البخور'},
    {'id': 'resurrection', 'name': 'القيامة والخماسين'},
    {'id': 'holy_week', 'name': 'أسبوع الآلام'},
    {'id': 'kiahk_nativity', 'name': 'كيهك والميلاد والغطاس'},
    {'id': 'great_lent', 'name': 'الصوم الكبير ويونان'},
    {'id': 'praise', 'name': 'التسبحة والأبصلمودية'},
    {'id': 'feasts', 'name': 'الأعياد والمناسبات'},
    {'id': 'agpeya_coptic', 'name': 'الأجبية بالقبطي'},
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

  List<Hymn> get _filteredHymns {
    return _allHymns.where((h) {
      final matchCat = _selectedCategory == 'all' || h.categoryId == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty ||
          h.title.contains(_searchQuery) ||
          h.cantor.contains(_searchQuery) ||
          h.categoryName.contains(_searchQuery);
      return matchCat && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.deepNavy,
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
      );
    }

    final featured = context.watch<AudioProvider>().currentHymn ??
        (_allHymns.isNotEmpty ? _allHymns.first : null);

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header (matches Video Frames 08 & 09)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  LuxeCircleButton(
                    icon: Icons.search_rounded,
                    onTap: () => Navigator.push(context, luxeRoute(const GlobalSearchView())),
                  ),
                  Text(
                    'الألحان والطقوس',
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                  if (featured != null)
                    LuxeCircleButton(
                      icon: Icons.fullscreen_rounded,
                      onTap: () => Navigator.push(
                        context,
                        luxeRoute(HymnDetailView(hymn: featured, playlist: _filteredHymns)),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),

            // Featured Hymn Player Card (tapping opens the full Frame 08-09 player)
            if (featured != null)
              Consumer<AudioProvider>(
                builder: (context, audioProv, _) {
                  final isPlaying =
                      audioProv.currentHymn?.id == featured.id && audioProv.isPlaying;
                  return PressScale(
                    scale: 0.98,
                    onTap: () => Navigator.push(
                      context,
                      luxeRoute(HymnDetailView(hymn: featured, playlist: _filteredHymns)),
                    ),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: AppColors.obsidianCard,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppColors.primaryGold.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: const SizedBox(
                              width: 78,
                              height: 78,
                              child: SafeAssetImage('assets/images/hymn_album_art.jpg'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGold.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.play_circle_fill_rounded, size: 12, color: Colors.redAccent),
                                      const SizedBox(width: 4),
                                      Text(
                                        'بث مباشر يوتيوب أونلاين • اضغط للعرض والترتيل',
                                        style: GoogleFonts.cairo(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryGoldLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  featured.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textLight,
                                  ),
                                ),
                                Text(
                                  featured.cantor,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              if (isPlaying) {
                                audioProv.pause();
                              } else {
                                audioProv.play(featured);
                              }
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.champagne,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryGold.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 28,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            // Search Field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13.5),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryGold),
                  hintText: 'ابحث في ${_allHymns.length} لحناً قبطياً باسم اللحن أو المرتل...',
                  hintStyle: GoogleFonts.cairo(
                    color: AppColors.textMuted.withValues(alpha: 0.75),
                    fontSize: 12.5,
                  ),
                  filled: true,
                  fillColor: AppColors.cardNavy,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
                  ),
                ),
              ),
            ),

            // Categories Chips
            SizedBox(
              height: 42,
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
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.black : AppColors.textLight,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primaryGold,
                    backgroundColor: AppColors.cardNavy,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primaryGold
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                    onSelected: (_) => setState(() => _selectedCategory = cat['id']!),
                  );
                },
              ),
            ),

            const SizedBox(height: 6),

            // Hymns List (Obsidian cards with square thumbnail)
            Expanded(
              child: _filteredHymns.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد ألحان مطابقة للبحث',
                        style: GoogleFonts.cairo(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 95),
                      itemCount: _filteredHymns.length,
                      itemBuilder: (context, index) {
                        final hymn = _filteredHymns[index];
                        return Consumer<AudioProvider>(
                          builder: (context, audioProv, _) {
                            final isCurrentPlaying =
                                audioProv.currentHymn?.id == hymn.id && audioProv.isPlaying;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                gradient: AppColors.obsidianCard,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isCurrentPlaying
                                      ? AppColors.primaryGold
                                      : Colors.white.withValues(alpha: 0.06),
                                  width: isCurrentPlaying ? 1.5 : 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                leading: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    if (isCurrentPlaying) {
                                      audioProv.pause();
                                    } else {
                                      audioProv.play(hymn);
                                    }
                                  },
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: const SizedBox(
                                          width: 52,
                                          height: 52,
                                          child: SafeAssetImage(
                                            'assets/images/thumb_hymns.jpg',
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isCurrentPlaying
                                              ? AppColors.primaryGold
                                              : Colors.black.withValues(alpha: 0.65),
                                          border: Border.all(
                                            color: AppColors.primaryGold,
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Icon(
                                          isCurrentPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: isCurrentPlaying
                                              ? Colors.black
                                              : AppColors.primaryGoldLight,
                                          size: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                title: Text(
                                  hymn.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textLight,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.35)),
                                      ),
                                      child: Text(
                                        'يوتيوب 🎥',
                                        style: GoogleFonts.cairo(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.redAccent,
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
                                          fontSize: 11.5,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(
                                  Icons.chevron_left_rounded,
                                  size: 22,
                                  color: AppColors.primaryGoldLight,
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
                            );
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
}
