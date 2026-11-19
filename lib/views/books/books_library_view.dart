import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/online_coptic_library_service.dart';
import '../../models/book_model.dart';
import '../../providers/books_provider.dart';
import 'book_reader_view.dart';
import 'online_book_reader_view.dart';
import 'online_tafsir_reader_view.dart';

/// Unified Multi-Source Coptic Orthodox Digital Library & Full 73-Book Tafsir Encyclopedia.
/// Combines:
/// 1) Full 73-book Patristic Bible Commentaries (Fr. Tadros Yacoub Malaty & Fr. Antonios Fekry + Fr. Matta El Meskeen)
/// 2) 100+ Full-Chapter In-App Readable Orthodox Books (offline classics + live full-chapter books)
/// 3) Multi-Source Comprehensive Internet Library (ChristianLib.com 6,000+ books, Father Matta El Meskeen,
///    Patristic Studies Center, Bishop Gregorios, & Archive.org / Bibliotheca Alexandrina) with LIVE search.
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

  // Tab 1 (Tafsir) filters
  String _tafsirQuery = '';
  String _tafsirTestament = 'all'; // all | old | deuterocanon | new

  // Tab 2 (In-App Readable Books) filters
  String _readableQuery = '';
  String _readableCategory = 'الكل';

  // Tab 3 (Comprehensive Multi-Source Internet Library) filters + live search
  final TextEditingController _webSearchCtrl = TextEditingController();
  String _webCategory = 'الكل';
  List<OnlineBookEntry>? _liveSearchResults;
  bool _isSearchingWeb = false;

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
    final booksProv = context.watch<BooksProvider>();

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'المكتبة الأرثوذكسية والتفاسير',
          style: GoogleFonts.amiri(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppColors.primaryGoldLight,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGold,
          indicatorWeight: 2,
          labelColor: AppColors.primaryGoldLight,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.cairo(fontSize: 11.5),
          tabs: const [
            Tab(text: 'التفاسير (٧٣ سفراً)'),
            Tab(text: 'الكتب المقروءة'),
            Tab(text: 'المكتبة الشاملة'),
          ],
        ),
      ),
      body: _loadingCatalogs
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGold, strokeWidth: 2),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTafsirTab(),
                _buildReadableBooksTab(booksProv),
                _buildComprehensiveWebTab(),
              ],
            ),
    );
  }

  // ===========================================================================
  // TAB 1: ALL 73 BIBLE BOOKS FULL PATRISTIC COMMENTARIES
  // ===========================================================================
  Widget _buildTafsirTab() {
    final filtered = _tafsirBooks.where((b) {
      final matchTest = _tafsirTestament == 'all' || b.testament == _tafsirTestament;
      final q = _tafsirQuery.trim();
      final matchQ = q.isEmpty || b.name.contains(q);
      return matchTest && matchQ;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _tafsirQuery = v),
            style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13),
            decoration: _searchInputDecoration('ابحث باسم السفر (مثال: تكوين، مزامير، متى، رومية، رؤيا)...'),
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildFilterPill('الكل (${_tafsirBooks.length})', _tafsirTestament == 'all',
                  () => setState(() => _tafsirTestament = 'all')),
              const SizedBox(width: 6),
              _buildFilterPill('العهد القديم', _tafsirTestament == 'old',
                  () => setState(() => _tafsirTestament = 'old')),
              const SizedBox(width: 6),
              _buildFilterPill('القانونية الثانية', _tafsirTestament == 'deuterocanon',
                  () => setState(() => _tafsirTestament = 'deuterocanon')),
              const SizedBox(width: 6),
              _buildFilterPill('العهد الجديد', _tafsirTestament == 'new',
                  () => setState(() => _tafsirTestament = 'new')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              const Icon(Icons.auto_stories_outlined, size: 14, color: AppColors.primaryGold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'تفسير القمص تادرس يعقوب ملطي • القمص أنطونيوس فكري • شروح الأب متى المسكين',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
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
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final b = filtered[idx];
              final testLabel = b.testament == 'new'
                  ? 'العهد الجديد'
                  : (b.testament == 'deuterocanon' ? 'قانونية ثانية' : 'العهد القديم');
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OnlineTafsirReaderView(
                        book: b,
                        onSearchMatta: _jumpToWebSearch,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardNavy,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.hairline),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceNavy,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.25)),
                        ),
                        child: Center(
                          child: Text(
                            '${b.chaptersCount}',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGoldLight,
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
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$testLabel • ${b.chaptersCount} أصحاحاً${b.mattaQuery.isNotEmpty ? ' • متاح شرح الأب متى المسكين' : ''}',
                              style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_left_rounded, color: AppColors.primaryGold, size: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: FULL-CHAPTER IN-APP READABLE BOOKS (OFFLINE CLASSICS + LIVE FULL CHAPTERS)
  // ===========================================================================
  Widget _buildReadableBooksTab(BooksProvider booksProv) {
    final inAppOnline = _onlineBooks.where((b) => b.readerType == 'in_app_chapters').toList();
    final categories = <String>{'الكل', 'كلاسيكيات أوفلاين'};
    for (final b in inAppOnline) {
      categories.add(b.category);
    }

    final q = _readableQuery.trim();
    final offlineBooks = (_readableCategory == 'الكل' || _readableCategory == 'كلاسيكيات أوفلاين')
        ? booksProv.books.where((b) {
            return q.isEmpty || b.title.contains(q) || b.author.contains(q);
          }).toList()
        : <Book>[];

    final filteredOnline = _readableCategory == 'كلاسيكيات أوفلاين'
        ? <OnlineBookEntry>[]
        : inAppOnline.where((b) {
            final matchCat = _readableCategory == 'الكل' || b.category == _readableCategory;
            final matchQ = q.isEmpty || b.title.contains(q) || b.author.contains(q);
            return matchCat && matchQ;
          }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _readableQuery = v),
            style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13),
            decoration: _searchInputDecoration('ابحث في الكتب المقروءة كاملة الفصول داخل التطبيق...'),
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
                  cat,
                  _readableCategory == cat,
                  () => setState(() => _readableCategory = cat),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            children: [
              if (filteredOnline.isNotEmpty) ...[
                _buildSectionLabel('كتب أرثوذكسية كاملة الفصول (${filteredOnline.length} كتاباً)'),
                const SizedBox(height: 8),
                for (final ob in filteredOnline) ...[
                  _buildOnlineBookCard(ob),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 16),
              ],
              if (offlineBooks.isNotEmpty) ...[
                _buildSectionLabel('مختارات روحية وآبائية بدون إنترنت (${offlineBooks.length})'),
                const SizedBox(height: 8),
                for (final book in offlineBooks) ...[
                  _buildOfflineBookCard(book),
                  const SizedBox(height: 8),
                ],
              ],
              if (filteredOnline.isEmpty && offlineBooks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: Text(
                      'لا توجد نتائج مطابقة؛ جرب البحث في تبويب «المكتبة الشاملة» للوصول لآلاف الكتب.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // TAB 3: MULTI-SOURCE COMPREHENSIVE INTERNET ORTHODOX LIBRARY (+6,000 BOOKS)
  // ===========================================================================
  Widget _buildComprehensiveWebTab() {
    final curatedWebBooks = _onlineBooks
        .where((b) => b.readerType != 'in_app_chapters')
        .where((b) => _webCategory == 'الكل' || b.category == _webCategory)
        .toList();

    final displayList = _liveSearchResults ?? curatedWebBooks;

    return Column(
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
                  style: GoogleFonts.cairo(color: AppColors.textLight, fontSize: 13),
                  decoration: _searchInputDecoration(
                    'ابحث في آلاف الكتب (متى المسكين، بستان الرهبان، أثناسيوس، حبيب جرجس...)',
                    suffixIcon: _webSearchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
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
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('بحث حي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.5)),
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
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, idx) {
                final cat = _webCategories[idx];
                return _buildFilterPill(
                  cat,
                  _webCategory == cat,
                  () => setState(() => _webCategory = cat),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              const Icon(Icons.public_rounded, size: 14, color: AppColors.primaryGold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _liveSearchResults != null
                      ? 'نتائج البحث الحي من المكتبات الأرثوذكسية (${_liveSearchResults!.length} كتاب)'
                      : 'مكتبة الكتب المسيحية • دير الأنبا مقار • المركز الآبائي • أرشيف مكتبة الإسكندرية',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _isSearchingWeb
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primaryGold, strokeWidth: 2),
                      const SizedBox(height: 12),
                      Text(
                        'جاري البحث الحي في المكتبات الأرثوذكسية وأرشيف التراث القبطي...',
                        style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                )
              : displayList.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'لا توجد نتائج مطابقة لهذا البحث؛ جرب كتابة كلمة أقصر أو اسم المؤلف.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                      itemCount: displayList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, idx) => _buildOnlineBookCard(displayList[idx]),
                    ),
        ),
      ],
    );
  }

  Widget _buildOnlineBookCard(OnlineBookEntry book) {
    final isInApp = book.readerType == 'in_app_chapters';
    final isArchive = book.readerType == 'archive_org';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OnlineBookReaderView(book: book)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardNavy,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surfaceNavy,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.28)),
              ),
              child: Center(
                child: Icon(
                  isInApp
                      ? Icons.menu_book_rounded
                      : (isArchive ? Icons.account_balance_outlined : Icons.picture_as_pdf_outlined),
                  color: AppColors.primaryGold,
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
                      fontSize: 17.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      color: AppColors.primaryGoldLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (book.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      book.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textMuted, height: 1.4),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceNavy,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.hairline),
                        ),
                        child: Text(
                          book.source,
                          style: GoogleFonts.cairo(fontSize: 9.5, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Icon(Icons.chevron_left_rounded, color: AppColors.primaryGold, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineBookCard(Book book) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BookReaderView(book: book)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardNavy,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.surfaceNavy,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.28)),
              ),
              child: const Center(
                child: Icon(Icons.auto_stories_outlined, color: AppColors.primaryGold, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.amiri(
                      fontSize: 17.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${book.author} • ${book.chaptersCount} فصول أوفلاين',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: AppColors.primaryGold, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Text(
      title,
      style: GoogleFonts.cairo(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.primaryGoldLight,
      ),
    );
  }

  Widget _buildFilterPill(String label, bool active, VoidCallback onTap) {
    return ChoiceChip(
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
      showCheckmark: false,
      side: BorderSide(color: active ? AppColors.primaryGold : AppColors.hairline),
      onSelected: (_) => onTap(),
    );
  }

  InputDecoration _searchInputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryGold, size: 20),
      suffixIcon: suffixIcon,
      hintText: hint,
      hintStyle: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 12),
      filled: true,
      fillColor: AppColors.cardNavy,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.6)),
      ),
    );
  }
}
