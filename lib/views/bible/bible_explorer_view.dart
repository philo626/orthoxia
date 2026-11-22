import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/bible_reading_progress_service.dart';
import '../../core/services/reading_state_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../models/bible_model.dart';
import '../../providers/bible_provider.dart';
import 'bible_reader_view.dart';

class BibleExplorerView extends StatefulWidget {
  final bool embedded;

  const BibleExplorerView({super.key, this.embedded = false});

  @override
  State<BibleExplorerView> createState() => _BibleExplorerViewState();
}

class _BibleExplorerViewState extends State<BibleExplorerView> {
  final TextEditingController _searchCtrl = TextEditingController();
  final BibleReadingProgressService _progress = BibleReadingProgressService();
  final ReadingStateService _readingState = ReadingStateService();

  @override
  void initState() {
    super.initState();
    Future.wait([
      _progress.ensureLoaded(),
      _readingState.ensureLoaded(),
    ]).then((_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BibleProvider>().loadBible();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openFavoritesSheet(BuildContext context, BibleProvider bible) {
    final p = context.palette;
    final favs = _readingState.favoriteVerses;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.surface,
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.72,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
        child: Column(
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
            const SizedBox(height: 14),
            Text(
              'آياتي المفضلة (${favs.length})',
              style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.bold, color: p.ink),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: favs.isEmpty
                  ? Center(
                      child: Text(
                        'اضغط على أي آية أثناء القراءة لحفظها هنا والرجوع إليها في أي وقت.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(color: p.inkMuted, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      itemCount: favs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, idx) {
                        final fv = favs[idx];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: p.surfaceSubtle,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: p.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '«${fv.text}»',
                                style: GoogleFonts.amiri(fontSize: 18, color: p.ink, height: 1.65),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${fv.bookName} ${fv.chapter}:${fv.verse}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: p.accent,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      final matching = bible.allBooks.where((b) => b.abbrev == fv.bookAbbrev);
                                      if (matching.isNotEmpty) {
                                        bible.setCurrentBookAndChapter(matching.first, fv.chapter);
                                        Navigator.pop(ctx);
                                        Navigator.push(context, luxeRoute(const BibleReaderView()))
                                            .then((_) {
                                          if (mounted) setState(() {});
                                        });
                                      }
                                    },
                                    child: Text('فتح الإصحاح', style: GoogleFonts.cairo(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
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

  void _showChapterPicker(BuildContext context, BibleBook book) {
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: p.border)),
        ),
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${book.name} — اختر الإصحاح',
                  style: GoogleFonts.amiri(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: p.ink,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: p.inkMuted),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: book.chaptersCount,
                itemBuilder: (ctx, idx) {
                  final chNum = idx + 1;
                  final isDone = _progress.isChapterCompleted(book.abbrev, chNum);
                  return InkWell(
                    onTap: () {
                      context.read<BibleProvider>().setCurrentBookAndChapter(book, chNum);
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        luxeRoute(const BibleReaderView()),
                      ).then((_) {
                        if (mounted) setState(() {});
                      });
                    },
                    borderRadius: BorderRadius.circular(11),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDone ? p.sage.withValues(alpha: 0.16) : p.surfaceSubtle,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: isDone ? p.sage : p.border),
                      ),
                      child: Text(
                        '$chNum',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDone ? p.sage : p.ink,
                        ),
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

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bible = context.watch<BibleProvider>();
    final lastBible = _readingState.lastBible;

    final content = bible.isLoading
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: p.accent, strokeWidth: 2),
                const SizedBox(height: 14),
                Text(
                  'جاري تحميل أسفار الكتاب المقدس...',
                  style: GoogleFonts.cairo(color: p.inkSecondary),
                ),
              ],
            ),
          )
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  if (widget.embedded)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                      child: Row(
                        children: [
                          Text(
                            '٧٣ سفراً • فانديك الكنسية',
                            style: GoogleFonts.cairo(
                              fontSize: 11.5,
                              color: p.inkMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          ValueListenableBuilder<int>(
                            valueListenable: _readingState.favoritesCountNotifier,
                            builder: (_, count, _) => InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _openFavoritesSheet(context, bible),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: p.goldSoft,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: p.goldBorder),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.bookmark_outline_rounded, size: 15, color: p.accent),
                                    const SizedBox(width: 4),
                                    Text(
                                      count > 0 ? 'آياتي المفضلة ($count)' : 'آياتي المفضلة',
                                      style: GoogleFonts.cairo(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: p.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Resume Where You Left Off Card (when available!)
                  if (lastBible != null && bible.searchResults.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                        child: PressScale(
                          scale: 0.985,
                          onTap: () {
                            final match = bible.allBooks
                                .where((b) => b.abbrev == lastBible['abbrev']);
                            if (match.isNotEmpty) {
                              bible.setCurrentBookAndChapter(
                                match.first,
                                (lastBible['chapter'] as num?)?.toInt() ?? 1,
                              );
                              Navigator.push(context, luxeRoute(const BibleReaderView())).then((_) {
                                if (mounted) setState(() {});
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                            decoration: BoxDecoration(
                              color: p.goldSoft,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: p.goldBorder),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.history_rounded, color: p.accent, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'أكمل القراءة: ${lastBible['name']} • الإصحاح ${lastBible['chapter']}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.cairo(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: p.ink,
                                    ),
                                  ),
                                ),
                                Icon(Icons.chevron_left_rounded, color: p.accent, size: 19),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Bible Reading Completion Progress Bar
                    ValueListenableBuilder<int>(
                      valueListenable: _progress.completedCountNotifier,
                      builder: (context, completedCh, _) {
                        final totalCh = _progress.getTotalChaptersCount(bible.allBooks);
                        final pct = totalCh > 0 ? (completedCh / totalCh).clamp(0.0, 1.0) : 0.0;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: p.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: p.border),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'متابعة ختم الكتاب المقدس',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: p.ink,
                                    ),
                                  ),
                                  Text(
                                    '$completedCh / $totalCh إصحاح (${(pct * 100).toStringAsFixed(1)}%)',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11.5,
                                      color: p.inkSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: pct,
                                  minHeight: 5,
                                  backgroundColor: p.surfaceSubtle,
                                  valueColor: AlwaysStoppedAnimation<Color>(p.accent),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: bible.searchVerses,
                        style: GoogleFonts.cairo(color: p.ink, fontSize: 13.5),
                        decoration: InputDecoration(
                          hintText: 'ابحث في الآيات أو الأسفار (مثال: محبة، نور، تكوين)...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.close_rounded, color: p.inkMuted, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    bible.clearSearch();
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),

                    // Testament Filter Pills
                    if (bible.searchResults.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        child: Row(
                          children: [
                            _filterChip(p, bible, 'ALL', 'الكل (${bible.allBooks.length})'),
                            const SizedBox(width: 8),
                            _filterChip(p, bible, 'OLD', 'القديم (${bible.oldTestamentBooks.length})'),
                            const SizedBox(width: 8),
                            _filterChip(p, bible, 'NEW', 'الجديد (${bible.newTestamentBooks.length})'),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    Expanded(
                      child: bible.searchResults.isNotEmpty
                          ? _buildSearchResults(p, bible)
                          : _buildBooksGrid(p, bible),
                    ),
                  ],
                ),
              ),
            );

    if (widget.embedded) {
      return Material(color: p.canvas, child: content);
    }

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        foregroundColor: p.ink,
        title: Text(
          'الكتاب المقدس',
          style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 23, color: p.ink),
        ),
        actions: [
          ValueListenableBuilder<int>(
            valueListenable: _readingState.favoritesCountNotifier,
            builder: (_, count, _) => TextButton.icon(
              onPressed: () => _openFavoritesSheet(context, bible),
              icon: Icon(Icons.bookmark_outline_rounded, size: 18, color: p.accent),
              label: Text(
                count > 0 ? 'المفضلة ($count)' : 'المفضلة',
                style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: p.accent),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: content,
    );
  }

  Widget _filterChip(AppPalette p, BibleProvider bible, String key, String label) {
    final isSelected = bible.selectedTestament == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => bible.setTestament(key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? p.accent : p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? p.accent : p.border),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? p.onAccent : p.ink,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(AppPalette p, BibleProvider bible) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: bible.searchResults.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (ctx, idx) {
        final res = bible.searchResults[idx];
        return PressScale(
          scale: 0.985,
          onTap: () {
            bible.setCurrentBookAndChapter(res.book, res.chapterNumber);
            Navigator.push(context, luxeRoute(const BibleReaderView()));
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  res.verseText,
                  style: GoogleFonts.amiri(fontSize: 17.5, color: p.ink, height: 1.6),
                ),
                const SizedBox(height: 6),
                Text(
                  '${res.book.name} ${res.chapterNumber}:${res.verseNumber}',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: p.accent,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBooksGrid(AppPalette p, BibleProvider bible) {
    final books = bible.filteredBooks;
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: books.length,
      itemBuilder: (ctx, idx) {
        final book = books[idx];
        final isNT = book.testament == 'NEW';
        final doneCnt = _progress.getBookCompletedChaptersCount(book);

        return PressScale(
          scale: 0.97,
          onTap: () => _showChapterPicker(context, book),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isNT ? p.goldBorder : p.border),
              boxShadow: p.isDark
                  ? null
                  : [
                      BoxShadow(
                        color: p.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        book.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.amiri(
                          fontWeight: FontWeight.bold,
                          fontSize: 17.5,
                          color: p.ink,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isNT ? p.goldSoft : p.surfaceSubtle,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isNT ? 'جديد' : 'قديم',
                        style: GoogleFonts.cairo(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isNT ? p.accent : p.inkMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  doneCnt > 0
                      ? 'أتممت $doneCnt من ${book.chaptersCount} إصحاح'
                      : '${book.chaptersCount} إصحاح',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: doneCnt > 0 ? FontWeight.bold : FontWeight.w500,
                    color: doneCnt > 0 ? p.sage : p.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
