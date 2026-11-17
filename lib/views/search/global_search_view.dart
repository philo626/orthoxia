import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/bible_provider.dart';
import '../../providers/books_provider.dart';
import '../../providers/liturgy_provider.dart';
import '../bible/bible_reader_view.dart';
import '../liturgies/liturgy_reader_view.dart';
import '../books/book_reader_view.dart';

class _SearchItem {
  final String category; // 'bible', 'liturgy', 'books', 'commentary'
  final String categoryLabel;
  final String title;
  final String snippet;
  final VoidCallback onTap;

  _SearchItem({
    required this.category,
    required this.categoryLabel,
    required this.title,
    required this.snippet,
    required this.onTap,
  });
}

class GlobalSearchView extends StatefulWidget {
  const GlobalSearchView({super.key});

  @override
  State<GlobalSearchView> createState() => _GlobalSearchViewState();
}

class _GlobalSearchViewState extends State<GlobalSearchView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _activeFilter = 'all'; // 'all', 'bible', 'liturgy', 'books'
  List<_SearchItem> _results = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BibleProvider>().loadBible();
      context.read<LiturgyProvider>().loadLiturgies();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _runSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.length < 2) {
      setState(() => _results = []);
      return;
    }

    final bible = context.read<BibleProvider>();
    final liturgyProv = context.read<LiturgyProvider>();
    final booksProv = context.read<BooksProvider>();

    final List<_SearchItem> items = [];

    // 1. Liturgies Search
    if (_activeFilter == 'all' || _activeFilter == 'liturgy') {
      for (final lit in liturgyProv.liturgies) {
        for (final sec in lit.sections) {
          for (final v in sec.verses) {
            if (v.arabic.toLowerCase().contains(q) ||
                v.arabized.toLowerCase().contains(q) ||
                sec.title.toLowerCase().contains(q)) {
              items.add(
                _SearchItem(
                  category: 'liturgy',
                  categoryLabel: 'القداسات',
                  title: '${lit.title} • ${sec.title}',
                  snippet: v.arabic,
                  onTap: () {
                    liturgyProv.selectLiturgy(lit);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LiturgyReaderView()),
                    );
                  },
                ),
              );
              break;
            }
          }
        }
      }
    }

    // 2. Books & Commentaries Search
    if (_activeFilter == 'all' || _activeFilter == 'books') {
      for (final book in booksProv.books) {
        if (book.title.toLowerCase().contains(q) ||
            book.description.toLowerCase().contains(q) ||
            book.author.toLowerCase().contains(q)) {
          items.add(
            _SearchItem(
              category: 'books',
              categoryLabel: 'المكتبة الآبائية',
              title: book.title,
              snippet: '${book.author} — ${book.description}',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BookReaderView(book: book)),
                );
              },
            ),
          );
        }
      }
    }

    // 3. Full Bible Search (66 Books)
    if (_activeFilter == 'all' || _activeFilter == 'bible') {
      bible.searchVerses(q);
      for (final r in bible.searchResults.take(40)) {
        items.add(
          _SearchItem(
            category: 'bible',
            categoryLabel: 'الكتاب المقدس',
            title: '${r.book.name} ${r.chapterNumber}:${r.verseNumber}',
            snippet: r.verseText,
            onTap: () {
              bible.setCurrentBookAndChapter(r.book, r.chapterNumber);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BibleReaderView()),
              );
            },
          ),
        );
      }
    }

    setState(() => _results = items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'محرك البحث الشامل',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              // Animated Search Input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: _runSearch,
                  style: GoogleFonts.cairo(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'ابحث في القداسات، الكتاب المقدس، أو كتب الآباء...',
                    hintStyle: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryGold),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                            onPressed: () {
                              _searchCtrl.clear();
                              _runSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.cardNavy,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.5),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 250.ms).slideY(begin: -0.05, end: 0),

              // Expandable Filter Chips
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _filterChip('all', 'الكل'),
                    const SizedBox(width: 8),
                    _filterChip('liturgy', 'القداسات'),
                    const SizedBox(width: 8),
                    _filterChip('bible', 'الكتاب المقدس'),
                    const SizedBox(width: 8),
                    _filterChip('books', 'الكتب والتفاسير'),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Results
              Expanded(
                child: _searchCtrl.text.trim().length < 2
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.manage_search_rounded,
                                size: 64, color: AppColors.primaryGold.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              'اكتب كلمة أو آية للبحث الفوري في كل المصادر',
                              style: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد نتائج مطابقة لـ "${_searchCtrl.text}"',
                              style: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 14),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _results.length,
                            itemBuilder: (ctx, idx) {
                              final item = _results[idx];
                              return Card(
                                color: AppColors.cardNavy,
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.2)),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(14),
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primaryGold.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.categoryLabel,
                                          style: GoogleFonts.cairo(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryGoldLight,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.cairo(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryGold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      item.snippet,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.cairo(
                                        fontSize: 13,
                                        color: AppColors.cream,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    item.onTap();
                                  },
                                ),
                              ).animate().fadeIn(duration: 220.ms, delay: (idx * 25).ms);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String id, String label) {
    final selected = _activeFilter == id;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? Colors.black : AppColors.primaryGoldLight,
        ),
      ),
      selected: selected,
      selectedColor: AppColors.primaryGold,
      backgroundColor: AppColors.cardNavy,
      side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.35)),
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() => _activeFilter = id);
        _runSearch(_searchCtrl.text);
      },
    );
  }
}
