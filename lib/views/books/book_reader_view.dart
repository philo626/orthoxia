import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/book_model.dart';
import '../../providers/books_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/ai_companion_provider.dart';
import '../liturgical/widgets/floating_church_bar.dart';

class BookReaderView extends StatefulWidget {
  final Book book;
  final int initialChapterIndex;

  const BookReaderView({
    super.key,
    required this.book,
    this.initialChapterIndex = 0,
  });

  @override
  State<BookReaderView> createState() => _BookReaderViewState();
}

class _BookReaderViewState extends State<BookReaderView> {
  late int _currentChapterIndex;

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.initialChapterIndex.clamp(0, widget.book.chapters.length - 1);
  }

  void _askAiAboutChapter(BuildContext context, BookChapter chapter) {
    final aiProv = Provider.of<AiCompanionProvider>(context, listen: false);
    final question = 'أريد شرحاً وتأملاً آبائياً حول "${widget.book.title} - ${chapter.title}":\n\n${chapter.content.substring(0, chapter.content.length > 300 ? 300 : chapter.content.length)}...';
    aiProv.sendMessage(question);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم توجيه السؤال إلى المساعد الآبائي بنجاح. يمكنك مراجعته في تبويب المساعد الروحي.',
          style: GoogleFonts.cairo(),
        ),
        backgroundColor: AppColors.sacredBurgundy,
        action: SnackBarAction(
          label: 'فتح المساعد',
          textColor: AppColors.primaryGold,
          onPressed: () {
            Navigator.pop(context); // Return to navigation
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final booksProv = Provider.of<BooksProvider>(context);
    final fontScale = themeProv.fontScale;
    final chapter = widget.book.chapters[_currentChapterIndex];
    final isBookmarked = booksProv.isBookmarked(chapter.id);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.book.title,
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isBookmarked ? AppColors.primaryGold : AppColors.textLight,
            ),
            tooltip: 'حفظ إشارة مرجعية',
            onPressed: () => booksProv.toggleBookmark(chapter.id),
          ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.format_list_bulleted_rounded, color: AppColors.primaryGold),
            tooltip: 'فهرس الفصول',
            initialValue: _currentChapterIndex,
            onSelected: (idx) => setState(() => _currentChapterIndex = idx),
            itemBuilder: (context) {
              return widget.book.chapters.asMap().entries.map((entry) {
                return PopupMenuItem<int>(
                  value: entry.key,
                  child: Text(
                    entry.value.title,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: entry.key == _currentChapterIndex ? FontWeight.bold : FontWeight.normal,
                      color: entry.key == _currentChapterIndex ? AppColors.primaryGold : null,
                    ),
                  ),
                );
              }).toList();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Chapter Info Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardNavy,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.book.author,
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          color: AppColors.primaryGoldLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        chapter.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 16 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Chapter Content
                Text(
                  chapter.content,
                  style: GoogleFonts.cairo(
                    fontSize: 16 * fontScale,
                    color: AppColors.textLight,
                    height: 1.9,
                  ),
                ),

                const SizedBox(height: 30),

                // Button: Ask AI Companion about this chapter
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceNavy,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryGold, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'المساعد الآبائي الذكي',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'هل تريد شرحاً أو تأملاً آبائياً حول هذا الفصل؟',
                        style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _askAiAboutChapter(context, chapter),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        label: Text(
                          'اسأل المساعد الآبائي حول هذا الفصل',
                          style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sacredBurgundy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Navigation Buttons (Previous / Next Chapter)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentChapterIndex > 0)
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _currentChapterIndex -= 1);
                        },
                        icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.primaryGold),
                        label: Text('الفصل السابق', style: GoogleFonts.cairo(color: AppColors.primaryGold)),
                      )
                    else
                      const SizedBox.shrink(),
                    if (_currentChapterIndex < widget.book.chapters.length - 1)
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _currentChapterIndex += 1);
                        },
                        label: Text('الفصل التالي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ],
            ),
          ),

          // Floating Church Bar (Brightness, Font scaling, AMOLED)
          const FloatingChurchBar(),
        ],
      ),
    );
  }
}
