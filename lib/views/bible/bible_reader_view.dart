import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/bible_reading_progress_service.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/widgets/blessing_poster_studio_sheet.dart';
import '../../models/bible_model.dart';
import '../../providers/bible_provider.dart';

class BibleReaderView extends StatefulWidget {
  const BibleReaderView({super.key});

  @override
  State<BibleReaderView> createState() => _BibleReaderViewState();
}

class _BibleReaderViewState extends State<BibleReaderView> {
  double _fontSize = 19.0;
  final ScrollController _scrollController = ScrollController();
  final SpeechPronunciationService _speech = SpeechPronunciationService();
  final BibleReadingProgressService _progress = BibleReadingProgressService();

  @override
  void initState() {
    super.initState();
    _progress.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF13151D),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.bookmark_border_rounded, color: AppColors.primaryGold),
                const SizedBox(width: 8),
                Text(
                  '${book.name} $chapter : $verseNum',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGoldLight,
                  ),
                ),
                const Spacer(),
                SpeechPlayStopButton(
                  textToSpeak: '$verseText. ${book.name} إصحاح $chapter آية $verseNum',
                  label: '${book.name} $chapter:$verseNum',
                  playText: 'استماع',
                  stopText: 'إيقاف الصوت ⏹️',
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                verseText,
                style: GoogleFonts.amiri(
                  fontSize: 18,
                  color: Colors.white,
                  height: 1.65,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryGoldLight,
                      side: const BorderSide(color: AppColors.primaryGold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.copy_rounded, size: 17),
                    label: Text('نسخ الآية', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: '«$verseText» (${book.name} $chapter: $verseNum)'),
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('تم نسخ الآية المباركة بنجاح', style: GoogleFonts.cairo()),
                          backgroundColor: AppColors.cardNavy,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.share_rounded, size: 17),
                    label: Text('مشاركة نص', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF281F12),
                foregroundColor: AppColors.primaryGoldLight,
                side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.photo_camera_back_rounded, size: 18, color: AppColors.primaryGold),
              label: Text(
                'تصميم كبطاقة مصورة للمشاركة',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.5),
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
        backgroundColor: AppColors.deepNavy,
        appBar: AppBar(title: const Text('الكتاب المقدس')),
        body: const Center(child: Text('لم يتم اختيار سفر.')),
      );
    }

    final chapterIndex = chapter - 1;
    final verses = (chapterIndex >= 0 && chapterIndex < book.chapters.length)
        ? book.chapters[chapterIndex]
        : <String>[];

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: const Color(0xFF10121A),
        title: Text(
          '${book.name} • الإصحاح $chapter',
          style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          // Audio Reader Button for the Chapter
          ValueListenableBuilder<bool>(
            valueListenable: _speech.isSpeakingNotifier,
            builder: (context, speaking, _) {
              return IconButton(
                tooltip: speaking ? 'إيقاف القراءة الصوتية' : 'استماع للإصحاح صوتياً',
                icon: Icon(
                  speaking ? Icons.stop_circle_rounded : Icons.volume_up_rounded,
                  color: speaking ? Colors.redAccent : AppColors.primaryGold,
                ),
                onPressed: () {
                  if (speaking) {
                    _speech.stop();
                  } else {
                    final fullChapterText =
                        '${book.name}، الإصحاح $chapter. ${verses.join('. ')}';
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
            icon: const Icon(Icons.format_size_rounded, color: AppColors.primaryGold),
            onPressed: () {
              setState(() {
                _fontSize = _fontSize >= 25.0 ? 17.0 : _fontSize + 2.0;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Horizontal Quick Chapter Selector Bar
          Container(
            height: 44,
            color: const Color(0xFF13151E),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: book.chaptersCount,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, idx) {
                final chNum = idx + 1;
                final isSel = chNum == chapter;
                final isDone = _progress.isChapterCompleted(book.abbrev, chNum);
                return ChoiceChip(
                  visualDensity: VisualDensity.compact,
                  showCheckmark: false,
                  label: Text(
                    isDone ? '✓ إصحاح $chNum' : 'إصحاح $chNum',
                    style: GoogleFonts.cairo(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isSel
                          ? Colors.black
                          : (isDone ? Colors.greenAccent : AppColors.textLight),
                    ),
                  ),
                  selected: isSel,
                  selectedColor: AppColors.primaryGold,
                  backgroundColor: const Color(0xFF1E212D),
                  onSelected: (_) {
                    _speech.stop();
                    bible.setCurrentBookAndChapter(book, chNum);
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(0);
                    }
                  },
                );
              },
            ),
          ),

          // Chapter Navigation & Completion Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              border: Border(
                bottom: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    _speech.stop();
                    bible.previousChapter();
                    if (_scrollController.hasClients) _scrollController.jumpTo(0);
                  },
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 13, color: AppColors.primaryGold),
                  label: Text(
                    'السابق',
                    style: GoogleFonts.cairo(color: AppColors.primaryGoldLight, fontSize: 12),
                  ),
                ),
                // Mark Chapter Completed Button ("أتممت قراءة الإصحاح")
                Builder(
                  builder: (context) {
                    final completed = _progress.isChapterCompleted(book.abbrev, chapter);
                    return ElevatedButton.icon(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        final nowDone = await _progress.toggleChapterCompleted(book.abbrev, chapter);
                        if (!mounted) return;
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              nowDone
                                  ? 'بارك الله قراءتك! تم تسجيل قراءة ${book.name} إصحاح $chapter'
                                  : 'تم إلغاء علامة القراءة لهذا الإصحاح',
                              style: GoogleFonts.cairo(fontSize: 12),
                            ),
                            backgroundColor: AppColors.cardNavy,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: completed
                            ? Colors.green.withValues(alpha: 0.25)
                            : AppColors.primaryGold.withValues(alpha: 0.16),
                        foregroundColor: completed ? Colors.greenAccent : AppColors.primaryGoldLight,
                        elevation: 0,
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(
                          color: completed ? Colors.greenAccent : AppColors.primaryGold,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(
                        completed ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                        size: 16,
                        color: completed ? Colors.greenAccent : AppColors.primaryGold,
                      ),
                      label: Text(
                        completed ? 'تمت قراءة الإصحاح ✓' : 'أتممت قراءة الإصحاح',
                        style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                ),
                TextButton.icon(
                  onPressed: () {
                    _speech.stop();
                    bible.nextChapter();
                    if (_scrollController.hasClients) _scrollController.jumpTo(0);
                  },
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.primaryGold),
                  label: Text(
                    'التالي',
                    style: GoogleFonts.cairo(color: AppColors.primaryGoldLight, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Verses List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              itemCount: verses.length,
              itemBuilder: (ctx, idx) {
                final vNum = idx + 1;
                final vText = verses[idx];
                return InkWell(
                  onTap: () => _onVerseTapped(context, book, chapter, vNum, vText),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                    child: RichText(
                      textDirection: TextDirection.rtl,
                      text: TextSpan(
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGold.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.primaryGold.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                '$vNum',
                                style: GoogleFonts.cairo(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryGoldLight,
                                ),
                              ),
                            ),
                          ),
                          TextSpan(
                            text: vText,
                            style: GoogleFonts.amiri(
                              fontSize: _fontSize + 2,
                              color: const Color(0xFFF7F4EC),
                              height: 1.8,
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
        ],
      ),
    );
  }
}
