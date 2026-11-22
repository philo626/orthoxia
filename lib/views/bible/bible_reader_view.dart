import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/bible_reading_progress_service.dart';
import '../../core/services/online_coptic_library_service.dart';
import '../../core/services/reading_state_service.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/blessing_poster_studio_sheet.dart';
import '../../models/bible_model.dart';
import '../../providers/bible_provider.dart';
import '../books/online_tafsir_reader_view.dart';

class BibleReaderView extends StatefulWidget {
  const BibleReaderView({super.key});

  @override
  State<BibleReaderView> createState() => _BibleReaderViewState();
}

class _BibleReaderViewState extends State<BibleReaderView> {
  double _fontSize = 19.5;
  final ScrollController _scrollController = ScrollController();
  final SpeechPronunciationService _speech = SpeechPronunciationService();
  final BibleReadingProgressService _progress = BibleReadingProgressService();
  final ReadingStateService _readingState = ReadingStateService();

  @override
  void initState() {
    super.initState();
    Future.wait([
      _progress.ensureLoaded(),
      _readingState.ensureLoaded(),
    ]).then((_) {
      _saveCurrentLocation();
      if (mounted) setState(() {});
    });
  }

  void _saveCurrentLocation() {
    if (!mounted) return;
    final bible = context.read<BibleProvider>();
    final book = bible.currentBook;
    if (book != null) {
      _readingState.saveLastBible(
        bookAbbrev: book.abbrev,
        bookName: book.name,
        chapter: bible.currentChapter,
      );
    }
  }

  @override
  void dispose() {
    _speech.stop();
    _scrollController.dispose();
    super.dispose();
  }

  void _onVerseTapped(
    BuildContext context,
    BibleBook book,
    int chapter,
    int verseNum,
    String verseText,
  ) {
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final isFav = _readingState.isVerseFavorited(book.abbrev, chapter, verseNum);
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
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
                const SizedBox(height: 14),
                Row(
                  children: [
                    IconButton(
                      tooltip: isFav ? 'إزالة من المفضلة' : 'حفظ في المفضلة',
                      icon: Icon(
                        isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: p.accent,
                      ),
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await _readingState.toggleFavoriteVerse(
                          FavoriteVerse(
                            bookAbbrev: book.abbrev,
                            bookName: book.name,
                            chapter: chapter,
                            verse: verseNum,
                            text: verseText,
                            savedAt: DateTime.now(),
                          ),
                        );
                        setSheet(() {});
                        if (mounted) setState(() {});
                      },
                    ),
                    Expanded(
                      child: Text(
                        '${book.name} $chapter : $verseNum',
                        style: GoogleFonts.amiri(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: p.ink,
                        ),
                      ),
                    ),
                    SpeechPlayStopButton(
                      textToSpeak: '$verseText. ${book.name} إصحاح $chapter آية $verseNum',
                      label: '${book.name} $chapter:$verseNum',
                      playText: 'استماع',
                      stopText: 'إيقاف',
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.surfaceSubtle,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    verseText,
                    style: GoogleFonts.amiri(
                      fontSize: 19,
                      color: p.ink,
                      height: 1.7,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.copy_rounded, size: 17),
                        label: const Text('نسخ الآية'),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: '«$verseText» (${book.name} $chapter: $verseNum)'),
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تم نسخ الآية', style: GoogleFonts.cairo())),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.share_rounded, size: 17),
                        label: const Text('مشاركة'),
                        onPressed: () {
                          SharePlus.instance.share(
                            ShareParams(text: '«$verseText»\n(${book.name} $chapter: $verseNum)'),
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
                    backgroundColor: p.goldSoft,
                    side: BorderSide(color: p.goldBorder),
                  ),
                  icon: Icon(Icons.photo_camera_back_outlined, size: 18, color: p.accent),
                  label: Text(
                    'تصميم الآية كبطاقة مصورة',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold, color: p.ink),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    BlessingPosterStudioSheet.show(
                      context,
                      title: 'آية من الكتاب المقدس',
                      bodyText: verseText,
                      reference: '${book.name} $chapter : $verseNum',
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bible = context.watch<BibleProvider>();
    final book = bible.currentBook;
    final chapter = bible.currentChapter;

    if (book == null) {
      return Scaffold(
        backgroundColor: p.canvas,
        appBar: AppBar(title: const Text('الكتاب المقدس')),
        body: Center(child: Text('لم يتم اختيار سفر.', style: GoogleFonts.cairo(color: p.inkMuted))),
      );
    }

    final chapterIndex = chapter - 1;
    final verses = (chapterIndex >= 0 && chapterIndex < book.chapters.length)
        ? book.chapters[chapterIndex]
        : <String>[];

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        foregroundColor: p.ink,
        title: Text(
          '${book.name} • الإصحاح $chapter',
          style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 21, color: p.ink),
        ),
        actions: [
          IconButton(
            tooltip: 'التفسير الآبائي لهذا الإصحاح',
            icon: Icon(Icons.menu_book_rounded, color: p.accent),
            onPressed: () async {
              final catalog = await OnlineCopticLibraryService().loadTafsirCatalog();
              final match = catalog.where(
                (t) =>
                    t.id.toLowerCase() == book.abbrev.toLowerCase() ||
                    book.name.contains(t.name) ||
                    t.name.contains(book.name.replaceFirst('سفر ', '').replaceFirst('إنجيل ', '')),
              );
              if (!context.mounted) return;
              if (match.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OnlineTafsirReaderView(
                      book: match.first,
                      initialChapterNumber: chapter,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'يمكنك تصفح كل التفاسير من تبويب «المكتبة» -> «التفاسير».',
                      style: GoogleFonts.cairo(fontSize: 12),
                    ),
                  ),
                );
              }
            },
          ),
          ValueListenableBuilder<bool>(
            valueListenable: _speech.isSpeakingNotifier,
            builder: (context, speaking, _) {
              return IconButton(
                tooltip: speaking ? 'إيقاف القراءة' : 'استماع للإصحاح',
                icon: Icon(
                  speaking ? Icons.stop_circle_rounded : Icons.volume_up_outlined,
                  color: speaking ? p.crimson : p.accent,
                ),
                onPressed: () {
                  if (speaking) {
                    _speech.stop();
                  } else {
                    final fullChapterText = '${book.name}، الإصحاح $chapter. ${verses.join('. ')}';
                    _speech.speakText(
                      fullChapterText,
                      label: '${book.name} - إصحاح $chapter',
                    );
                  }
                },
              );
            },
          ),
          IconButton(
            tooltip: 'حجم الخط',
            icon: Icon(Icons.format_size_rounded, color: p.ink),
            onPressed: () {
              setState(() {
                _fontSize = _fontSize >= 26.0 ? 17.5 : _fontSize + 2.0;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick Chapter Selector Strip
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: p.surface,
              border: Border(
                top: BorderSide(color: p.border, width: 0.7),
                bottom: BorderSide(color: p.border, width: 0.7),
              ),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: book.chaptersCount,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, idx) {
                final chNum = idx + 1;
                final isSel = chNum == chapter;
                final isDone = _progress.isChapterCompleted(book.abbrev, chNum);
                return ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  showCheckmark: false,
                  label: Text(
                    isDone ? '✓ $chNum' : 'إصحاح $chNum',
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isSel ? p.onAccent : (isDone ? p.sage : p.ink),
                    ),
                  ),
                  selected: isSel,
                  selectedColor: p.accent,
                  backgroundColor: p.surfaceSubtle,
                  side: BorderSide(color: isSel ? p.accent : p.border),
                  onSelected: (_) {
                    _speech.stop();
                    bible.setCurrentBookAndChapter(book, chNum);
                    _saveCurrentLocation();
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(0);
                    }
                  },
                );
              },
            ),
          ),

          // Chapter Navigation & Completion Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: p.surfaceSubtle,
              border: Border(bottom: BorderSide(color: p.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _speech.stop();
                    bible.previousChapter();
                    _saveCurrentLocation();
                    if (_scrollController.hasClients) _scrollController.jumpTo(0);
                  },
                  icon: Icon(Icons.chevron_right_rounded, size: 18, color: p.accent),
                  label: Text('السابق', style: GoogleFonts.cairo(color: p.ink, fontSize: 12)),
                ),
                Builder(
                  builder: (context) {
                    final completed = _progress.isChapterCompleted(book.abbrev, chapter);
                    return OutlinedButton.icon(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        final nowDone = await _progress.toggleChapterCompleted(book.abbrev, chapter);
                        if (!context.mounted) return;
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              nowDone
                                  ? 'تم تسجيل قراءة ${book.name} إصحاح $chapter'
                                  : 'تم إلغاء علامة القراءة',
                              style: GoogleFonts.cairo(fontSize: 12.5),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: completed ? p.sage.withValues(alpha: 0.14) : p.surface,
                        side: BorderSide(color: completed ? p.sage : p.goldBorder),
                      ),
                      icon: Icon(
                        completed ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                        size: 16,
                        color: completed ? p.sage : p.accent,
                      ),
                      label: Text(
                        completed ? 'تمت القراءة' : 'أتممت الإصحاح',
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: completed ? p.sage : p.ink,
                        ),
                      ),
                    );
                  },
                ),
                TextButton.icon(
                  onPressed: () {
                    _speech.stop();
                    bible.nextChapter();
                    _saveCurrentLocation();
                    if (_scrollController.hasClients) _scrollController.jumpTo(0);
                  },
                  icon: Icon(Icons.chevron_left_rounded, size: 18, color: p.accent),
                  label: Text('التالي', style: GoogleFonts.cairo(color: p.ink, fontSize: 12)),
                ),
              ],
            ),
          ),

          // Book-Printed Verses List
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 36),
                  itemCount: verses.length,
                  itemBuilder: (ctx, idx) {
                    final vNum = idx + 1;
                    final vText = verses[idx];
                    final isFav = _readingState.isVerseFavorited(book.abbrev, chapter, vNum);

                    return InkWell(
                      onTap: () => _onVerseTapped(context, book, chapter, vNum, vText),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                        decoration: isFav
                            ? BoxDecoration(
                                color: p.goldSoft.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(10),
                              )
                            : null,
                        child: RichText(
                          textDirection: TextDirection.rtl,
                          text: TextSpan(
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: isFav ? p.accent : p.goldSoft,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isFav ? p.accent : p.goldBorder,
                                    ),
                                  ),
                                  child: Text(
                                    '$vNum',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isFav ? p.onAccent : p.accent,
                                    ),
                                  ),
                                ),
                              ),
                              TextSpan(
                                text: vText,
                                style: GoogleFonts.amiri(
                                  fontSize: _fontSize + 2,
                                  color: p.ink,
                                  height: 1.85,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
