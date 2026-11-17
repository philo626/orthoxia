import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/books_provider.dart';
import '../../models/commentary_model.dart';

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

  @override
  Widget build(BuildContext context) {
    final booksProv = context.watch<BooksProvider>();
    final commentaries = booksProv.commentaries;

    BibleBookCommentary? matchedBookComm;
    if (bookName != null && commentaries.isNotEmpty) {
      final matches = commentaries.where(
        (c) => c.bibleBookName.contains(bookName!) || bookName!.contains(c.bibleBookName),
      );
      matchedBookComm = matches.isNotEmpty ? matches.first : commentaries.first;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withValues(alpha: 0.15),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.auto_stories_rounded, color: AppColors.primaryGold),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'التفسير الآبائي: $title',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: AppColors.primaryGold, thickness: 0.5),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Local Offline Patristic Commentary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.sacredBurgundy.withValues(alpha: 0.35),
                          AppColors.cardNavy,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.25)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.offline_pin_rounded, size: 16, color: AppColors.successGreen),
                            const SizedBox(width: 6),
                            Text(
                              'التفسير المعتمد (متاح بدون إنترنت)',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.successGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          localTafseer.isNotEmpty
                              ? localTafseer
                              : 'يشرح آباء الكنيسة الأرثوذكسية (القديس كيرلس الكبير، والقديس يوحنا ذهبي الفم، والقمص تادرس يعقوب ملطي) أن هذا النص الليتورجي أو الكتابي يرفع النفس نحو الشركة الحية مع الله.',
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            height: 1.75,
                            color: AppColors.cream,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),

                  if (matchedBookComm != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cardNavy,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'من تفاسير ${matchedBookComm.commentator}:',
                            style: GoogleFonts.cairo(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGoldLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            matchedBookComm.chapters.isNotEmpty
                                ? matchedBookComm.chapters.first.introduction
                                : matchedBookComm.summary,
                            style: GoogleFonts.cairo(
                              fontSize: 13.5,
                              height: 1.7,
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 350.ms, delay: 80.ms),
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
