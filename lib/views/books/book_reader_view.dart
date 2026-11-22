import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/reading_state_service.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/theme/app_palette.dart';
import '../../models/book_model.dart';
import '../../providers/ai_companion_provider.dart';
import '../../providers/books_provider.dart';
import '../../providers/theme_provider.dart';
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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.initialChapterIndex.clamp(
      0,
      widget.book.chapters.isEmpty ? 0 : widget.book.chapters.length - 1,
    );
    _recordProgress();
  }

  @override
  void dispose() {
    SpeechPronunciationService().stop();
    _scrollController.dispose();
    super.dispose();
  }

  void _recordProgress() {
    ReadingStateService().saveLastBook(
      bookId: widget.book.id,
      bookTitle: widget.book.title,
      chapterIndex: _currentChapterIndex,
    );
  }

  void _goToChapter(int idx) {
    if (idx < 0 || idx >= widget.book.chapters.length) return;
    SpeechPronunciationService().stop();
    setState(() => _currentChapterIndex = idx);
    _recordProgress();
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  void _askAiAboutChapter(BuildContext context, BookChapter chapter) {
    final aiProv = Provider.of<AiCompanionProvider>(context, listen: false);
    final excerpt = chapter.content.length > 300
        ? chapter.content.substring(0, 300)
        : chapter.content;
    final question = 'أريد شرحاً وتأملاً آبائياً حول "${widget.book.title} - ${chapter.title}":\n\n$excerpt';
    aiProv.sendMessage(question);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم إرسال الفصل للمساعد الآبائي — يمكنك قراءة الشرح في تبويب «اسأل».',
          style: GoogleFonts.cairo(fontSize: 12.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final themeProv = Provider.of<ThemeProvider>(context);
    final booksProv = Provider.of<BooksProvider>(context);
    final fontScale = themeProv.fontScale;

    if (widget.book.chapters.isEmpty) {
      return Scaffold(
        backgroundColor: p.canvas,
        appBar: AppBar(title: Text(widget.book.title)),
        body: Center(
          child: Text('لا توجد فصول متاحة حالياً.', style: GoogleFonts.cairo(color: p.inkMuted)),
        ),
      );
    }

    final chapter = widget.book.chapters[_currentChapterIndex];
    final isBookmarked = booksProv.isBookmarked(chapter.id);

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        foregroundColor: p.ink,
        title: Text(
          widget.book.title,
          style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 20, color: p.ink),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: isBookmarked ? p.accent : p.inkSecondary,
            ),
            tooltip: 'حفظ علامة مرجعية',
            onPressed: () => booksProv.toggleBookmark(chapter.id),
          ),
          PopupMenuButton<int>(
            icon: Icon(Icons.format_list_bulleted_rounded, color: p.accent),
            tooltip: 'فهرس الفصول',
            initialValue: _currentChapterIndex,
            onSelected: _goToChapter,
            itemBuilder: (context) {
              return widget.book.chapters.asMap().entries.map((entry) {
                return PopupMenuItem<int>(
                  value: entry.key,
                  child: Text(
                    entry.value.title,
                    style: GoogleFonts.cairo(
                      fontSize: 12.5,
                      fontWeight: entry.key == _currentChapterIndex ? FontWeight.bold : FontWeight.normal,
                      color: entry.key == _currentChapterIndex ? p.accent : p.ink,
                    ),
                  ),
                );
              }).toList();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 115),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Book Chapter Title Block
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: p.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: p.border),
                      ),
                      child: Column(
                        children: [
                          Text(
                            widget.book.author,
                            style: GoogleFonts.cairo(
                              fontSize: 12,
                              color: p.accent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            chapter.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.amiri(
                              fontSize: 22 * fontScale.clamp(0.85, 1.3),
                              fontWeight: FontWeight.bold,
                              color: p.ink,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SpeechPlayStopButton(
                            textToSpeak: '${chapter.title}. ${chapter.content}',
                            label: chapter.title,
                            playText: 'استماع للفصل',
                            stopText: 'إيقاف القراءة',
                            compact: true,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Fine-Printed Chapter Prose
                    SelectableText(
                      chapter.content,
                      style: GoogleFonts.amiri(
                        fontSize: 20 * fontScale,
                        color: p.ink,
                        height: 1.95,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Prev / Next Chapter Controls
                    Row(
                      children: [
                        if (_currentChapterIndex > 0)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _goToChapter(_currentChapterIndex - 1),
                              icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                              label: const Text('الفصل السابق'),
                            ),
                          ),
                        if (_currentChapterIndex > 0 &&
                            _currentChapterIndex < widget.book.chapters.length - 1)
                          const SizedBox(width: 10),
                        if (_currentChapterIndex < widget.book.chapters.length - 1)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _goToChapter(_currentChapterIndex + 1),
                              icon: const Icon(Icons.arrow_back_rounded, size: 17),
                              label: const Text('الفصل التالي'),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Ask Patristic Companion Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: p.goldSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: p.goldBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.forum_outlined, color: p.accent, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تأمل أعمق في هذا الفصل',
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: p.ink,
                                  ),
                                ),
                                Text(
                                  'اطلب شرحاً آبائياً مبسطاً لهذا النص',
                                  style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkSecondary),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () => _askAiAboutChapter(context, chapter),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            child: const Text('اسأل'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const FloatingChurchBar(),
        ],
      ),
    );
  }
}
