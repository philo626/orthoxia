import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/commentary_model.dart';
import '../../providers/theme_provider.dart';
import '../liturgical/widgets/floating_church_bar.dart';

class CommentaryReaderView extends StatefulWidget {
  final BibleBookCommentary commentary;
  final int initialChapterIndex;

  const CommentaryReaderView({
    super.key,
    required this.commentary,
    this.initialChapterIndex = 0,
  });

  @override
  State<CommentaryReaderView> createState() => _CommentaryReaderViewState();
}

class _CommentaryReaderViewState extends State<CommentaryReaderView> {
  late int _currentChapterIndex;

  @override
  void initState() {
    super.initState();
    _currentChapterIndex = widget.initialChapterIndex.clamp(0, widget.commentary.chapters.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = Provider.of<ThemeProvider>(context);
    final fontScale = themeProv.fontScale;
    final chapter = widget.commentary.chapters[_currentChapterIndex];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.commentary.bibleBookName,
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              widget.commentary.commentator,
              style: GoogleFonts.cairo(fontSize: 11, color: AppColors.primaryGoldLight),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.format_list_bulleted_rounded, color: AppColors.primaryGold),
            tooltip: 'فهرس الأصحاحات',
            initialValue: _currentChapterIndex,
            onSelected: (idx) => setState(() => _currentChapterIndex = idx),
            itemBuilder: (context) {
              return widget.commentary.chapters.asMap().entries.map((entry) {
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
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Chapter Title Box
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
                        chapter.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 17 * fontScale,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                      ),
                      if (chapter.introduction.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          chapter.introduction,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 13 * fontScale,
                            color: AppColors.textLight.withValues(alpha: 0.9),
                            height: 1.6,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Verse by Verse breakdown
                for (var v in chapter.verses) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardNavy,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Verse Scripture in Sacred Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceNavy,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryGold.withValues(alpha: 0.2),
                                ),
                                child: Center(
                                  child: Text(
                                    '${v.verseNumber}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryGold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  v.scriptureText,
                                  style: GoogleFonts.cairo(
                                    fontSize: 15 * fontScale,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGoldLight,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Patristic Commentary
                        Text(
                          'التفسير والتأمل الآبائي:',
                          style: GoogleFonts.cairo(
                            fontSize: 13 * fontScale,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          v.patristicCommentary,
                          style: GoogleFonts.cairo(
                            fontSize: 15 * fontScale,
                            color: AppColors.textLight,
                            height: 1.8,
                          ),
                        ),

                        // Citation Pill
                        if (v.citation.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.sacredBurgundy.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.bookmark_added_rounded, size: 12, color: AppColors.primaryGold),
                                  const SizedBox(width: 4),
                                  Text(
                                    v.citation,
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryGoldLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

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
                        label: Text('الأصحاح السابق', style: GoogleFonts.cairo(color: AppColors.primaryGold)),
                      )
                    else
                      const SizedBox.shrink(),
                    if (_currentChapterIndex < widget.commentary.chapters.length - 1)
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _currentChapterIndex += 1);
                        },
                        label: Text('الأصحاح التالي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
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

          // Floating Church Bar
          const FloatingChurchBar(),
        ],
      ),
    );
  }
}
