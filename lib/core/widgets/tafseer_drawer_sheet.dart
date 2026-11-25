import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/services/online_coptic_library_service.dart';
import '../../core/theme/app_palette.dart';
import '../../models/commentary_model.dart';
import '../../providers/books_provider.dart';
import '../../views/books/online_tafsir_reader_view.dart';

class TafseerDrawerSheet extends StatelessWidget {
  final String title;
  final String localTafseer;
  final String? bookName;
  final int? chapterNumber;

  const TafseerDrawerSheet({
    super.key,
    required this.title,
    required this.localTafseer,
    this.bookName,
    this.chapterNumber,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String localTafseer,
    String? bookName,
    int? chapterNumber,
  }) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TafseerDrawerSheet(
        title: title,
        localTafseer: localTafseer,
        bookName: bookName,
        chapterNumber: chapterNumber,
      ),
    );
  }

  Future<void> _openFullBookTafsir(BuildContext context) async {
    if (bookName == null || bookName!.isEmpty) return;
    final catalog = await OnlineCopticLibraryService().loadTafsirCatalog();
    final cleaned = bookName!
        .replaceFirst('سفر ', '')
        .replaceFirst('إنجيل ', '')
        .trim();
    final match = catalog.where(
      (t) => t.name.contains(cleaned) || cleaned.contains(t.name),
    );
    if (!context.mounted) return;
    if (match.isNotEmpty) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OnlineTafsirReaderView(
            book: match.first,
            initialChapterNumber: chapterNumber,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final booksProv = context.watch<BooksProvider>();
    final commentaries = booksProv.commentaries;

    BibleBookCommentary? matchedBookComm;
    if (bookName != null && commentaries.isNotEmpty) {
      final matches = commentaries.where(
        (c) => c.bibleBookName.contains(bookName!) || bookName!.contains(c.bibleBookName),
      );
      matchedBookComm = matches.isNotEmpty ? matches.first : null;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: p.goldBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: p.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Icon(Icons.auto_stories_rounded, color: p.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'التفسير الآبائي: $title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.amiri(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: p.ink,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: p.inkMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Divider(color: p.border, height: 1),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: p.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: p.goldBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.offline_pin_rounded, size: 16, color: p.sage),
                            const SizedBox(width: 6),
                            Text(
                              'التأمل الآبائي السريع (متاح بدون إنترنت)',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: p.sage,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          localTafseer.isNotEmpty
                              ? localTafseer
                              : 'يشرح آباء الكنيسة الأرثوذكسية (القديس كيرلس الكبير، والقديس يوحنا ذهبي الفم، والقمص تادرس يعقوب ملطي) أن هذا النص الليتورجي أو الكتابي يرفع النفس نحو الشركة الحية مع الله.',
                          style: GoogleFonts.amiri(
                            fontSize: 17.5,
                            height: 1.8,
                            color: p.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (matchedBookComm != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: p.surfaceSubtle,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: p.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'من تفاسير ${matchedBookComm.commentator}:',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: p.accent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            matchedBookComm.chapters.isNotEmpty
                                ? matchedBookComm.chapters.first.introduction
                                : matchedBookComm.summary,
                            style: GoogleFonts.amiri(
                              fontSize: 17,
                              height: 1.75,
                              color: p.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (bookName != null && bookName!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _openFullBookTafsir(context),
                      icon: const Icon(Icons.menu_book_rounded, size: 18),
                      label: Text(
                        'قراءة التفسير الكامل للإصحاح (القمص تادرس ملطي وأنطونيوس فكري)',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.accent,
                        foregroundColor: p.onAccent,
                        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
