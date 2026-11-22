import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/online_coptic_library_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../models/book_model.dart';
import '../../providers/books_provider.dart';
import 'book_reader_view.dart';
import 'online_book_reader_view.dart';
import 'online_tafsir_reader_view.dart';

/// Unified Fine-Press Orthodox Digital Library & 73-Book Tafsir Encyclopedia:
/// - Opens directly on rich clothbound readable Orthodox Books (13 rich offline classics + 98 full-chapter books)
/// - Full 73-Book Patristic Bible Commentaries (Fr. Tadros Yacoub Malaty & Fr. Antonios Fekry)
/// - Comprehensive Multi-Source Internet Library Search
class BooksLibraryView extends StatefulWidget {
  final int initialTabIndex;

  const BooksLibraryView({super.key, this.initialTabIndex = 0});

  @override
  State<BooksLibraryView> createState() => _BooksLibraryViewState();
}

class _BooksLibraryViewState extends State<BooksLibraryView>
    with SingleTickerProviderStateMixin {
  final OnlineCopticLibraryService _lib = OnlineCopticLibraryService();
  late TabController _tabController;

  List<TafsirBookEntry> _tafsirBooks = [];
  List<OnlineBookEntry> _onlineBooks = [];
  bool _loadingCatalogs = true;

  String _readableQuery = '';
  String _readableCategory = 'الكل';

  String _tafsirQuery = '';
  String _tafsirTestament = 'all';

  final TextEditingController _webSearchCtrl = TextEditingController();
  String _webCategory = 'الكل';
  List<OnlineBookEntry>? _liveSearchResults;
  bool _isSearchingWeb = false;

  static const List<Color> _clothSpineColors = [
    Color(0xFF72242D), // Monastic crimson
    Color(0xFF213A52), // Cathedral slate indigo
    Color(0xFF2B4C3C), // Monastery olive
    Color(0xFF6B4C23), // Antique bronze
    Color(0xFF472C4E), // Lenten plum
    Color(0xFF39444B), // Basalt slate
  ];

  static const List<String> _webCategories = [
    'الكل',
    'كتب الأب متى المسكين',
    'آبائيات ودراسات آبائية',
    'كتب روحية وتأملات',
    'لاهوت وعقيدة أرثوذكسية',
    'تاريخ الكنيسة وسير القديسين',
    'طقوس وألحان كنسية',
    'الكتاب المقدس وتفاسير',
    'كتب الأنبا غريغوريوس',
    'كتب القمص تادرس يعقوب ملطي',
    'أرشيف التراث القبطي ومكتبة الإسكندرية',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _loadCatalogs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _webSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogs() async {
    final results = await Future.wait([
      _lib.loadTafsirCatalog(),
      _lib.loadOnlineBooksCatalog(),
    ]);
    if (!mounted) return;
    setState(() {
      _tafsirBooks = results[0] as List<TafsirBookEntry>;
      _onlineBooks = results[1] as List<OnlineBookEntry>;
      _loadingCatalogs = false;
    });
  }

  Future<void> _runLiveInternetSearch(String query) async {
    final q = query.trim();
    if (q.length < 2) {
      setState(() => _liveSearchResults = null);
      return;
    }
    setState(() => _isSearchingWeb = true);
    final res = await _lib.searchInternetLibraries(q);
    if (!mounted) return;
    setState(() {
      _liveSearchResults = res;
      _isSearchingWeb = false;
    });
  }

  void _jumpToWebSearch(String query) {
    _tabController.animateTo(2);
    _webSearchCtrl.text = query;
    _runLiveInternetSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final booksProv = context.watch<BooksProvider>();

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        foregroundColor: p.ink,
        title: Text(
          'المكتبة الأرثوذكسية والتفاسير',
          style: GoogleFonts.amiri(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: p.ink,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: p.accent,
          indicatorWeight: 2.2,
          labelColor: p.accent,
          unselectedLabelColor: p.inkMuted,
          labelStyle: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.cairo(fontSize: 12),
          tabs: const [
            Tab(text: 'الكتب المقروءة'),
            Tab(text: 'التفاسير (٧٣ سفراً)'),
            Tab(text: 'المكتبة الشاملة'),
          ],
        ),
      ),
      body: _loadingCatalogs
          ? Center(child: CircularProgressIndicator(color: p.accent, strokeWidth: 2))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReadableBooksTab(p, booksProv),
                _buildTafsirTab(p),
                _buildComprehensiveWebTab(p),
              ],
            ),
    );
  }

  // ===========================================================================
  // TAB 1: FULL READABLE BOOKS (OFFLINE CLASSICS SHELF FIRST + LIVE FULL CHAPTERS)
  // ===========================================================================
  Widget _buildReadableBooksTab(AppPalette p, BooksProvider booksProv) {
    final inAppOnline = _onlineBooks.where((b) => b.readerType == 'in_app_chapters').toList();
    final categories = <String>{'الكل', 'مكتبة أوفلاين'};
    for (final b in inAppOnline) {
      categories.add(b.category);
    }

    final q = _readableQuery.trim();
    final offlineBooks = (_readableCategory == 'الكل' || _readableCategory == 'مكتبة أوفلاين')
        ? booksProv.books.where((b) {
            return q.isEmpty || b.title.contains(q) || b.author.contains(q) || b.description.contains(q);
          }).toList()
        : <Book>[];

    final filteredOnline = _readableCategory == 'مكتبة أوفلاين'
        ? <OnlineBookEntry>[]
        : inAppOnline.where((b) {
            final matchCat = _readableCategory == 'الكل' || b.category == _readableCategory;
            final matchQ = q.isEmpty || b.title.contains(q) || b.author.contains(q);
            return matchCat && matchQ;
          }).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _readableQuery = v),
                style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                decoration: const InputDecoration(
                  hintText: 'ابحث باسم الكتاب أو المؤلف (أثناسيوس، بستان الرهبان، الديداخي...)...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                ),
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: categories.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: _buildFilterPill(
                      p,
                      cat,
                      _readableCategory == cat,
                      () => setState(() => _readableCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                children: [
                  // 1. Offline Classics Visual Hardcover Shelf (ALWAYS INSTANT & RICH!)
                  if (offlineBooks.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'مكتبة الآباء والكلاسيكيات (${offlineBooks.length} كتاباً أوفلاين)',
                          style: GoogleFonts.amiri(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: p.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: offlineBooks.length,
                      itemBuilder: (ctx, idx) {
                        final book = offlineBooks[idx];
                        final coverColor = _clothSpineColors[idx % _clothSpineColors.length];
                        return _buildHardcoverBookCard(p, book, coverColor);
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 2. Full-Chapter Online Books
                  if (filteredOnline.isNotEmpty) ...[
                    Text(
                      'كتب أرثوذكسية كاملة الفصول (${filteredOnline.length} كتاباً)',
                      style: GoogleFonts.amiri(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (int i = 0; i < filteredOnline.length; i++) ...[
                      _buildOnlineBookCard(
                        p,
                        filteredOnline[i],
                        _clothSpineColors[(i + 2) % _clothSpineColors.length],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],

                  if (filteredOnline.isEmpty && offlineBooks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Text(
                          'لا توجد نتائج مطابقة؛ جرب البحث في تبويب «المكتبة الشاملة».',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(color: p.inkMuted, fontSize: 13.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHardcoverBookCard(AppPalette p, Book book, Color clothColor) {
    return PressScale(
      scale: 0.97,
      onTap: () {
        Navigator.push(
          context,
          luxeRoute(BookReaderView(book: book)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.border),
          boxShadow: [
            BoxShadow(
              color: p.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Printed Clothbound Cover Top
            Expanded(
              flex: 11,
              child: Container(
                margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: clothColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFD8B872).withValues(alpha: 0.45),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const CopticCross(size: 16, color: Color(0xFFEBD6A4)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${book.chaptersCount} فصول',
                            style: GoogleFonts.cairo(
                              fontSize: 9.5,
                              color: const Color(0xFFEBD6A4),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      book.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFFAF0),
                        height: 1.3,
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 1.5,
                      color: const Color(0xFFD8B872).withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ),
            // Author & Offline tag Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: p.ink,
                    ),
                  ),
                  Text(
                    'متاح للقراءة بدون إنترنت',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 10,
                      color: p.sage,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 2: ALL 73 BIBLE BOOKS FULL PATRISTIC COMMENTARIES
  // ===========================================================================
  Widget _buildTafsirTab(AppPalette p) {
    final filtered = _tafsirBooks.where((b) {
      final matchTest = _tafsirTestament == 'all' || b.testament == _tafsirTestament;
      final q = _tafsirQuery.trim();
      final matchQ = q.isEmpty || b.name.contains(q);
      return matchTest && matchQ;
    }).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _tafsirQuery = v),
                style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                decoration: const InputDecoration(
                  hintText: 'ابحث باسم السفر (مثال: تكوين، مزامير، متى، رومية، رؤيا)...',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                ),
              ),
            ),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterPill(p, 'الكل (${_tafsirBooks.length})', _tafsirTestament == 'all',
                      () => setState(() => _tafsirTestament = 'all')),
                  const SizedBox(width: 6),
                  _buildFilterPill(p, 'العهد القديم', _tafsirTestament == 'old',
                      () => setState(() => _tafsirTestament = 'old')),
                  const SizedBox(width: 6),
                  _buildFilterPill(p, 'القانونية الثانية', _tafsirTestament == 'deuterocanon',
                      () => setState(() => _tafsirTestament = 'deuterocanon')),
                  const SizedBox(width: 6),
                  _buildFilterPill(p, 'العهد الجديد', _tafsirTestament == 'new',
                      () => setState(() => _tafsirTestament = 'new')),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  Icon(Icons.auto_stories_outlined, size: 15, color: p.gold),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'تفسير القمص تادرس يعقوب ملطي • القمص أنطونيوس فكري • شروح الأب متى المسكين',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkMuted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final b = filtered[idx];
                  final testLabel = b.testament == 'new'
                      ? 'العهد الجديد'
                      : (b.testament == 'deuterocanon' ? 'قانونية ثانية' : 'العهد القديم');
                  return PressScale(
                    scale: 0.985,
                    onTap: () {
                      Navigator.push(
                        context,
                        luxeRoute(
                          OnlineTafsirReaderView(
                            book: b,
                            onSearchMatta: _jumpToWebSearch,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: p.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: p.goldSoft,
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(color: p.goldBorder),
                            ),
                            child: Center(
                              child: Text(
                                '${b.chaptersCount}',
                                style: GoogleFonts.cairo(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: p.isDark ? p.gold : p.accent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تفسير ${b.name}',
                                  style: GoogleFonts.amiri(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: p.ink,
                                  ),
                                ),
                                Text(
                                  '$testLabel • ${b.chaptersCount} أصحاحاً',
                                  style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkMuted),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_left_rounded, color: p.inkMuted, size: 20),
                        ],
                      ),
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

  // ===========================================================================
  // TAB 3: MULTI-SOURCE COMPREHENSIVE INTERNET ORTHODOX LIBRARY
  // ===========================================================================
  Widget _buildComprehensiveWebTab(AppPalette p) {
    final curatedWebBooks = _onlineBooks
        .where((b) => b.readerType != 'in_app_chapters')
        .where((b) => _webCategory == 'الكل' || b.category == _webCategory)
        .toList();

    final displayList = _liveSearchResults ?? curatedWebBooks;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _webSearchCtrl,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _runLiveInternetSearch,
                      style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'ابحث في آلاف الكتب (متى المسكين، أثناسيوس، حبيب جرجس...)',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _webSearchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.close_rounded, color: p.inkMuted, size: 18),
                                onPressed: () {
                                  _webSearchCtrl.clear();
                                  setState(() => _liveSearchResults = null);
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _runLiveInternetSearch(_webSearchCtrl.text),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('بحث'),
                  ),
                ],
              ),
            ),
            if (_liveSearchResults == null)
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _webCategories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (_, idx) {
                    final cat = _webCategories[idx];
                    return _buildFilterPill(
                      p,
                      cat,
                      _webCategory == cat,
                      () => setState(() => _webCategory = cat),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _isSearchingWeb
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: p.accent, strokeWidth: 2),
                          const SizedBox(height: 12),
                          Text(
                            'جاري البحث في المكتبات الأرثوذكسية...',
                            style: GoogleFonts.cairo(fontSize: 13, color: p.inkSecondary),
                          ),
                        ],
                      ),
                    )
                  : displayList.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'لا توجد نتائج مطابقة لهذا البحث.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(color: p.inkMuted, fontSize: 13.5),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                          itemCount: displayList.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (_, idx) => _buildOnlineBookCard(
                            p,
                            displayList[idx],
                            _clothSpineColors[idx % _clothSpineColors.length],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineBookCard(AppPalette p, OnlineBookEntry book, Color spineColor) {
    final isInApp = book.readerType == 'in_app_chapters';

    return PressScale(
      scale: 0.985,
      onTap: () {
        Navigator.push(
          context,
          luxeRoute(OnlineBookReaderView(book: book)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Miniature Clothbound Book Spine Emblem
            Container(
              width: 44,
              height: 58,
              decoration: BoxDecoration(
                color: spineColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFD8B872).withValues(alpha: 0.45),
                ),
              ),
              child: Center(
                child: Icon(
                  isInApp ? Icons.menu_book_rounded : Icons.picture_as_pdf_outlined,
                  color: const Color(0xFFF6E7C1),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.amiri(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: p.ink,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: p.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (book.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      book.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkSecondary, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Icon(Icons.chevron_left_rounded, color: p.inkMuted, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPill(AppPalette p, String label, bool active, VoidCallback onTap) {
    return ChoiceChip(
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
      backgroundColor: p.surface,
      showCheckmark: false,
      side: BorderSide(color: active ? p.accent : p.border),
      onSelected: (_) => onTap(),
    );
  }
}
