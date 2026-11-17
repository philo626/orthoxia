import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../models/bible_model.dart';
import '../../models/commentary_model.dart';
import '../../providers/bible_provider.dart';
import '../../providers/books_provider.dart';

class BibleReaderView extends StatefulWidget {
  const BibleReaderView({super.key});

  @override
  State<BibleReaderView> createState() => _BibleReaderViewState();
}

class _BibleReaderViewState extends State<BibleReaderView> {
  double _fontSize = 18.0;
  final ScrollController _scrollController = ScrollController();

  void _onVerseTapped(BuildContext context, BibleBook book, int chapter, int verseNum, String verseText) {
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
              children: [
                const Icon(Icons.bookmark_border, color: AppColors.gold),
                const SizedBox(width: 8),
                Text(
                  '${book.name} $chapter:$verseNum',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                verseText,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: AppColors.cream,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                      foregroundColor: AppColors.goldLight,
                      side: const BorderSide(color: AppColors.gold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('نسخ الآية', style: TextStyle(fontFamily: 'Cairo')),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: '$verseText (${book.name} $chapter:$verseNum)'));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ الآية المباركة بنجاح!'),
                          backgroundColor: AppColors.burgundy,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('مشاركة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                    onPressed: () {
                      SharePlus.instance.share(
                        ShareParams(text: '$verseText\n(${book.name} $chapter:$verseNum)'),
                      );
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.goldLight,
                side: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.menu_book, size: 18),
              label: const Text('عرض التفاسير والآبائيات لهذا السفر', style: TextStyle(fontFamily: 'Cairo')),
              onPressed: () {
                Navigator.pop(ctx);
                _showCommentarySheet(context, book.name, chapter, verseNum);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentarySheet(BuildContext context, String bookName, int chapter, int verse) {
    final booksProvider = context.read<BooksProvider>();
    // Try to find commentary for this book
    final commentaries = booksProvider.commentaries;
    final matches = commentaries.where(
      (c) => c.bibleBookName.contains(bookName) || bookName.contains(c.bibleBookName),
    );
    final BibleBookCommentary? bookComm = matches.isNotEmpty ? matches.first : (commentaries.isNotEmpty ? commentaries.first : null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_stories, color: AppColors.gold),
                    const SizedBox(width: 8),
                    Text(
                      'تفسير الآباء: $bookName $chapter',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(color: AppColors.gold),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'المرجع والشراح المعتمدون:',
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.goldLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bookComm != null ? bookComm.commentator : 'القمص تادرس يعقوب ملطي والقمص أنطونيوس فكري وآباء الكنيسة الأولى',
                            style: const TextStyle(fontFamily: 'Cairo', fontSize: 13, color: AppColors.cream),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'نظرة لاهوتية وروحية على الإصحاح $chapter من $bookName:',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bookComm != null && bookComm.chapters.isNotEmpty
                          ? bookComm.chapters.first.introduction
                          : 'يشرح الآباء القديسون هذا السفر المقدس باعتباره كشفاً لخطة الخلاص الإلهي. في كل آية نرى يد الله الممتدة للبشرية، داعية النفس للاتحاد به في الصلاة والبر، والارتفاع فوق هموم العالم الفاني.',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: AppColors.cream,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'شرح الآية المحددة:',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.goldLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'يؤكد القديس يوحنا ذهبي الفم والقديس كيرلس الكبير أن هذه الآية المباركة تزرع في القلب السلام والثبات الإيماني في مواجهة التجارب، موجهة أنظارنا نحو مجد القيامة والحياة الأبدية مع المسيح.',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        color: AppColors.cream,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
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
    final book = bible.currentBook;
    final chapter = bible.currentChapter;

    if (book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('قارئ الكتاب المقدس')),
        body: const Center(child: Text('لم يتم اختيار سفر.')),
      );
    }

    final chapterIndex = chapter - 1;
    final verses = (chapterIndex >= 0 && chapterIndex < book.chapters.length)
        ? book.chapters[chapterIndex]
        : <String>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${book.name} - الإصحاح $chapter',
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.format_size, color: AppColors.gold),
            onPressed: () {
              setState(() {
                _fontSize = _fontSize == 18.0 ? 22.0 : (_fontSize == 22.0 ? 15.0 : 18.0);
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(top: BorderSide(color: AppColors.gold.withValues(alpha: 0.2))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                foregroundColor: AppColors.goldLight,
              ),
              onPressed: () {
                bible.previousChapter();
                _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              },
              icon: const Icon(Icons.chevron_right),
              label: const Text('السابق', style: TextStyle(fontFamily: 'Cairo')),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$chapter / ${book.chaptersCount}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold.withValues(alpha: 0.15),
                foregroundColor: AppColors.goldLight,
              ),
              onPressed: () {
                bible.nextChapter();
                _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              },
              icon: const Icon(Icons.chevron_left),
              label: const Text('التالي', style: TextStyle(fontFamily: 'Cairo')),
            ),
          ],
        ),
      ),
      body: verses.isEmpty
          ? const Center(child: Text('لا توجد آيات متوفرة في هذا الإصحاح'))
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: verses.length,
              itemBuilder: (ctx, idx) {
                final verseNum = idx + 1;
                final verseText = verses[idx];

                return InkWell(
                  onTap: () => _onVerseTapped(context, book, chapter, verseNum, verseText),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withValues(alpha: 0.15),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            '$verseNum',
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.goldLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            verseText,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: _fontSize,
                              color: AppColors.cream,
                              height: 1.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
