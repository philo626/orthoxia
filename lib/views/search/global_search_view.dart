import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/bible_provider.dart';
import '../../providers/books_provider.dart';
import '../../providers/liturgy_provider.dart';
import '../bible/bible_reader_view.dart';
import '../books/book_reader_view.dart';
import '../liturgies/liturgy_reader_view.dart';

class _SearchItem {
  final String category;
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
  String _activeFilter = 'all';
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
                      MaterialPageRoute(
                          builder: (_) => const LiturgyReaderView()),
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
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        elevation: 0,
        title: Text(
          'البحث الشامل',
          style: GoogleFonts.amiri(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: p.ink,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: _runSearch,
                  style: GoogleFonts.cairo(color: p.ink, fontSize: 14),
                  decoration: InputDecoration(
                    hintText:
                        'ابحث في القداسات، الكتاب المقدس، أو كتب الآباء...',
                    hintStyle:
                        GoogleFonts.cairo(color: p.inkSubtle, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: p.accent),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: p.inkMuted),
                            onPressed: () {
                              _searchCtrl.clear();
                              _runSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: p.surfaceElevated,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: p.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: p.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: p.accent, width: 1.3),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _filterChip(p, 'all', 'الكل'),
                    const SizedBox(width: 8),
                    _filterChip(p, 'liturgy', 'القداسات'),
                    const SizedBox(width: 8),
                    _filterChip(p, 'bible', 'الكتاب المقدس'),
                    const SizedBox(width: 8),
                    _filterChip(p, 'books', 'الكتب والتفاسير'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _searchCtrl.text.trim().length < 2
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.manage_search_rounded,
                                size: 58,
                                color: p.accent.withValues(alpha: 0.45)),
                            const SizedBox(height: 10),
                            Text(
                              'اكتب كلمة أو آية للبحث الفوري في كل المصادر',
                              style: GoogleFonts.cairo(
                                  color: p.inkMuted, fontSize: 13.5),
                            ),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
                            child: Text(
                              'لا توجد نتائج مطابقة لـ "${_searchCtrl.text}"',
                              style: GoogleFonts.cairo(
                                  color: p.inkMuted, fontSize: 14),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _results.length,
                            itemBuilder: (ctx, idx) {
                              final item = _results[idx];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: p.surfaceElevated,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: p.border),
                                ),
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: ListTile(
                                  contentPadding: const EdgeInsets.all(14),
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: p.accentSoft,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.categoryLabel,
                                          style: GoogleFonts.cairo(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: p.accent,
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
                                            fontWeight: FontWeight.w700,
                                            color: p.ink,
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
                                        fontSize: 12.5,
                                        color: p.inkMuted,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    item.onTap();
                                  },
                                ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(AppPalette p, String id, String label) {
    final selected = _activeFilter == id;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? p.onAccent : p.ink,
        ),
      ),
      selected: selected,
      selectedColor: p.accent,
      backgroundColor: p.surfaceElevated,
      showCheckmark: false,
      side: BorderSide(color: selected ? p.accent : p.border),
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() => _activeFilter = id);
        _runSearch(_searchCtrl.text);
      },
    );
  }
}
