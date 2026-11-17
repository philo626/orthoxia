import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../models/bible_model.dart';
import '../../providers/bible_provider.dart';
import 'bible_reader_view.dart';

class BibleExplorerView extends StatefulWidget {
  const BibleExplorerView({super.key});

  @override
  State<BibleExplorerView> createState() => _BibleExplorerViewState();
}

class _BibleExplorerViewState extends State<BibleExplorerView> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BibleProvider>().loadBible();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showChapterPicker(BuildContext context, BibleBook book) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${book.name} - اختر الإصحاح',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                  return InkWell(
                    onTap: () {
                      context.read<BibleProvider>().setCurrentBookAndChapter(book, chNum);
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BibleReaderView(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        '$chNum',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                          color: AppColors.cream,
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
    final bible = context.watch<BibleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'الكتاب المقدس كاملاً',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: bible.isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.gold),
                  SizedBox(height: 16),
                  Text(
                    'جاري تحميل أسفار العهدين...',
                    style: TextStyle(fontFamily: 'Cairo', color: AppColors.goldLight),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Luxury Bible Cover Banner
                Container(
                  height: 110,
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/bible_cover.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    alignment: Alignment.bottomRight,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الكتاب المقدس كاملاً (٦٦ سفراً)',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.goldLight,
                          ),
                        ),
                        Icon(Icons.auto_stories, color: AppColors.gold),
                      ],
                    ),
                  ),
                ),

                // Search Field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) {
                      bible.searchVerses(val);
                    },
                    style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'ابحث في الآيات أو الأسفار (مثال: محبة، الله نور، تكوين)...',
                      hintStyle: TextStyle(
                        fontFamily: 'Cairo',
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(Icons.search, color: AppColors.gold),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                _searchCtrl.clear();
                                bible.clearSearch();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.gold),
                      ),
                    ),
                  ),
                ),

                // Testament Filter Tabs
                if (bible.searchResults.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Row(
                      children: [
                        _filterChip(context, bible, 'ALL', 'جميع الأسفار (٦٦)'),
                        const SizedBox(width: 8),
                        _filterChip(context, bible, 'OLD', 'العهد القديم (٣٩)'),
                        const SizedBox(width: 8),
                        _filterChip(context, bible, 'NEW', 'العهد الجديد (٢٧)'),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Content: Search Results OR Books Grid
                Expanded(
                  child: bible.searchResults.isNotEmpty
                      ? _buildSearchResults(context, bible)
                      : _buildBooksGrid(context, bible),
                ),
              ],
            ),
    );
  }

  Widget _filterChip(
      BuildContext context, BibleProvider bible, String key, String label) {
    final isSelected = bible.selectedTestament == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => bible.setTestament(key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.gold.withValues(alpha: 0.25)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.gold : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.goldLight : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, BibleProvider bible) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bible.searchResults.length,
      itemBuilder: (ctx, idx) {
        final res = bible.searchResults[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: Colors.black.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.gold.withValues(alpha: 0.2)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text(
              res.verseText,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 14,
                color: AppColors.cream,
                height: 1.5,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${res.book.name} ${res.chapterNumber}:${res.verseNumber}',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              bible.setCurrentBookAndChapter(res.book, res.chapterNumber);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BibleReaderView(),
                ),
              );
            },
          ),
        ).animate().fadeIn(duration: 200.ms, delay: (idx * 20).ms);
      },
    );
  }

  Widget _buildBooksGrid(BuildContext context, BibleProvider bible) {
    final books = bible.filteredBooks;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: books.length,
      itemBuilder: (ctx, idx) {
        final book = books[idx];
        final isNT = book.testament == 'NEW';

        return InkWell(
          onTap: () => _showChapterPicker(context, book),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isNT
                    ? [
                        AppColors.burgundy.withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.4),
                      ]
                    : [
                        const Color(0xFF1B2E3C).withValues(alpha: 0.6),
                        Colors.black.withValues(alpha: 0.4),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      book.name,
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.cream,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Icon(
                      isNT ? Icons.auto_stories : Icons.menu_book,
                      size: 18,
                      color: AppColors.gold,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${book.chaptersCount} إصحاح',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isNT ? 'جديد' : 'قديم',
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldLight,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 250.ms, delay: (idx * 15).ms);
      },
    );
  }
}
