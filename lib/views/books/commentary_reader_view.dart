import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_palette.dart';
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
    _currentChapterIndex = widget.initialChapterIndex
        .clamp(0, widget.commentary.chapters.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fontScale = Provider.of<ThemeProvider>(context).fontScale;
    final chapter = widget.commentary.chapters[_currentChapterIndex];

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        elevation: 0,
        title: Column(
          children: [
            Text(
              widget.commentary.bibleBookName,
              style: GoogleFonts.amiri(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: p.ink,
              ),
            ),
            Text(
              widget.commentary.commentator,
              style: GoogleFonts.cairo(fontSize: 11, color: p.accent),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<int>(
            icon: Icon(Icons.format_list_bulleted_rounded, color: p.accent),
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
                      fontWeight: entry.key == _currentChapterIndex
                          ? FontWeight.w700
                          : FontWeight.normal,
                      color: entry.key == _currentChapterIndex
                          ? p.accent
                          : p.ink,
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
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: p.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        chapter.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 20 * fontScale,
                          fontWeight: FontWeight.w700,
                          color: p.accent,
                        ),
                      ),
                      if (chapter.introduction.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          chapter.introduction,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 13 * fontScale,
                            color: p.inkMuted,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                for (var v in chapter.verses) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: p.surfaceElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: p.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: p.accentSoft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: p.accent.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: p.accent,
                                ),
                                child: Center(
                                  child: Text(
                                    '${v.verseNumber}',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: p.onAccent,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  v.scriptureText,
                                  style: GoogleFonts.amiri(
                                    fontSize: 17.5 * fontScale,
                                    fontWeight: FontWeight.w700,
                                    color: p.ink,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'التفسير والتأمل الآبائي:',
                          style: GoogleFonts.cairo(
                            fontSize: 12.5 * fontScale,
                            fontWeight: FontWeight.w700,
                            color: p.accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          v.patristicCommentary,
                          style: GoogleFonts.amiri(
                            fontSize: 17.5 * fontScale,
                            color: p.ink,
                            height: 1.85,
                          ),
                        ),
                        if (v.citation.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: p.surfaceMuted,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: p.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bookmark_added_rounded,
                                      size: 12, color: p.accent),
                                  const SizedBox(width: 4),
                                  Text(
                                    v.citation,
                                    style: GoogleFonts.cairo(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: p.inkMuted,
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentChapterIndex > 0)
                      OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => _currentChapterIndex -= 1),
                        icon: Icon(Icons.arrow_back_rounded,
                            size: 16, color: p.accent),
                        label: Text('الأصحاح السابق',
                            style: GoogleFonts.cairo(color: p.accent)),
                        style: OutlinedButton.styleFrom(
                            side: BorderSide(color: p.border)),
                      )
                    else
                      const SizedBox.shrink(),
                    if (_currentChapterIndex <
                        widget.commentary.chapters.length - 1)
                      ElevatedButton.icon(
                        onPressed: () =>
                            setState(() => _currentChapterIndex += 1),
                        label: Text('الأصحاح التالي',
                            style:
                                GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: p.accent,
                          foregroundColor: p.onAccent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ],
            ),
          ),
          const FloatingChurchBar(),
        ],
      ),
    );
  }
}
