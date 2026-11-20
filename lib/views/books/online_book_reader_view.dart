import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/online_coptic_library_service.dart';
import '../../core/services/security_guard_service.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../providers/theme_provider.dart';
import '../liturgical/widgets/floating_church_bar.dart';

/// Unified editorial reader for ANY online Orthodox book across all sources:
/// - `in_app_chapters`: reads every chapter full-text right inside the app with offline caching & audio.
/// - `christianlib_post` / `archive_org`: displays rich Arabic book summary, details,
///   and direct PDF / Archive.org online reading & download buttons.
class OnlineBookReaderView extends StatefulWidget {
  final OnlineBookEntry book;

  const OnlineBookReaderView({super.key, required this.book});

  @override
  State<OnlineBookReaderView> createState() => _OnlineBookReaderViewState();
}

class _OnlineBookReaderViewState extends State<OnlineBookReaderView> {
  final OnlineCopticLibraryService _lib = OnlineCopticLibraryService();
  final SpeechPronunciationService _speech = SpeechPronunciationService();
  final ScrollController _scrollController = ScrollController();

  // For in_app_chapters mode
  List<OnlineChapterLink> _chapters = [];
  int _chapterIdx = 0;
  List<String> _paragraphs = [];
  bool _isCached = false;

  // For ChristianLib / Archive.org detail mode
  OnlineBookDetail? _detail;

  bool _loading = true;
  bool _loadingChapter = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _speech.stop();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    if (widget.book.readerType == 'in_app_chapters') {
      try {
        final list = await _lib.fetchChapters(widget.book.url);
        if (!mounted) return;
        if (list.isEmpty) {
          // Single-page book: load the page itself directly
          final (paras, cached) = await _lib.fetchChapterParagraphs(widget.book.url);
          if (!mounted) return;
          setState(() {
            _chapters = [OnlineChapterLink(title: widget.book.title, url: widget.book.url)];
            _paragraphs = paras;
            _isCached = cached;
            _loading = false;
          });
        } else {
          setState(() {
            _chapters = list;
            _loading = false;
          });
          await _loadChapter(0);
        }
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'تعذّر تحميل فصول الكتاب حالياً. يمكنك إعادة المحاولة أو فتحه مباشرة في المتصفح.';
        });
      }
    } else {
      try {
        final det = await _lib.fetchChristianLibDetail(widget.book);
        if (!mounted) return;
        setState(() {
          _detail = det;
          _loading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _detail = OnlineBookDetail(
            title: widget.book.title,
            bodyText: widget.book.description,
            downloadLinks: widget.book.pdfUrl.isNotEmpty ? [widget.book.pdfUrl] : [],
            webUrl: widget.book.url,
          );
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadChapter(int idx) async {
    if (idx < 0 || idx >= _chapters.length) return;
    _speech.stop();
    setState(() {
      _chapterIdx = idx;
      _loadingChapter = true;
      _error = null;
    });
    try {
      final (paras, cached) = await _lib.fetchChapterParagraphs(_chapters[idx].url);
      if (!mounted) return;
      setState(() {
        _paragraphs = paras;
        _isCached = cached;
        _loadingChapter = false;
      });
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingChapter = false;
        _error = 'تعذّر تحميل هذا الفصل الآن. تأكد من اتصالك بالإنترنت.';
      });
    }
  }

  Future<void> _openExternal(String url) async {
    final safeUrl = SecurityGuardService.upgradeToHttps(url);
    if (!SecurityGuardService.isSafeExternalUrl(safeUrl)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حجب هذا الرابط تلقائياً لأمانك (يجب أن يكون رابطاً مشفراً HTTPS).',
              style: GoogleFonts.cairo(fontSize: 12),
            ),
          ),
        );
      }
      return;
    }
    final uri = Uri.tryParse(safeUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openChapterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.72,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: AppColors.deepNavy,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: AppColors.hairline)),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 3.5,
              decoration: BoxDecoration(
                color: AppColors.primaryGold.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'فهرس الكتاب (${_chapters.length} فصلاً)',
              style: GoogleFonts.amiri(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGoldLight,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: _chapters.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) {
                  final sel = i == _chapterIdx;
                  return ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: sel ? AppColors.primaryGold : AppColors.hairline,
                      ),
                    ),
                    tileColor: sel
                        ? AppColors.primaryGold.withValues(alpha: 0.14)
                        : AppColors.cardNavy,
                    title: Text(
                      _chapters[i].title,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.bold : FontWeight.w500,
                        color: sel ? AppColors.primaryGoldLight : AppColors.textLight,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _loadChapter(i);
                    },
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
    final fontScale = context.watch<ThemeProvider>().fontScale;

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        title: Text(
          widget.book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.amiri(
            fontWeight: FontWeight.bold,
            fontSize: 19,
            color: AppColors.primaryGoldLight,
          ),
        ),
        actions: [
          if (_chapters.length > 1)
            IconButton(
              icon: const Icon(Icons.format_list_bulleted_rounded, color: AppColors.primaryGold),
              tooltip: 'فهرس الفصول',
              onPressed: _openChapterSheet,
            ),
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded, color: AppColors.primaryGoldLight, size: 20),
            tooltip: 'فتح المصدر الأصلي',
            onPressed: () => _openExternal(widget.book.url),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_loading || _loadingChapter)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primaryGold, strokeWidth: 2),
                  const SizedBox(height: 12),
                  Text(
                    'جاري فتح الكتاب وتجهيز القراءة...',
                    style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu_book_outlined, color: AppColors.textMuted, size: 42),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(fontSize: 13.5, color: AppColors.textLight, height: 1.6),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      children: [
                        ElevatedButton(
                          onPressed: _init,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryGold,
                            foregroundColor: Colors.black,
                          ),
                          child: Text('إعادة المحاولة', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        ),
                        OutlinedButton(
                          onPressed: () => _openExternal(widget.book.url),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.hairline),
                          ),
                          child: Text('فتح في المتصفح', style: GoogleFonts.cairo(color: AppColors.primaryGoldLight)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else if (widget.book.readerType == 'in_app_chapters')
            _buildChaptersReader(fontScale)
          else
            _buildExternalLibraryDetail(fontScale),
          const FloatingChurchBar(),
        ],
      ),
    );
  }

  Widget _buildChaptersReader(double fontScale) {
    final chapterTitle = _chapters.isNotEmpty ? _chapters[_chapterIdx].title : widget.book.title;
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardNavy,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.book.author,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_isCached)
                    Text(
                      'محفوظ أوفلاين',
                      style: GoogleFonts.cairo(fontSize: 10.5, color: AppColors.successGreen),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                chapterTitle,
                style: GoogleFonts.amiri(
                  fontSize: 21 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SpeechPlayStopButton(
                    textToSpeak: _paragraphs.take(25).join(' '),
                    label: chapterTitle,
                    playText: 'استماع للفصل',
                    stopText: 'إيقاف الصوت',
                    compact: true,
                  ),
                  const Spacer(),
                  if (_chapters.length > 1)
                    TextButton.icon(
                      onPressed: _openChapterSheet,
                      icon: const Icon(Icons.list_rounded, size: 16, color: AppColors.primaryGold),
                      label: Text(
                        'فصل ${_chapterIdx + 1} من ${_chapters.length}',
                        style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.primaryGoldLight),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        for (final p in _paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SelectableText(
              p,
              style: GoogleFonts.amiri(
                fontSize: 19 * fontScale,
                height: 1.9,
                color: AppColors.textLight,
              ),
            ),
          ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_chapterIdx > 0)
              OutlinedButton.icon(
                onPressed: () => _loadChapter(_chapterIdx - 1),
                icon: const Icon(Icons.arrow_back_rounded, size: 16, color: AppColors.primaryGold),
                label: Text('الفصل السابق', style: GoogleFonts.cairo(color: AppColors.primaryGoldLight)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.hairline)),
              )
            else
              const SizedBox.shrink(),
            if (_chapterIdx < _chapters.length - 1)
              ElevatedButton.icon(
                onPressed: () => _loadChapter(_chapterIdx + 1),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text('الفصل التالي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGold,
                  foregroundColor: Colors.black,
                  elevation: 0,
                ),
              )
            else
              const SizedBox.shrink(),
          ],
        ),
      ],
    );
  }

  Widget _buildExternalLibraryDetail(double fontScale) {
    final det = _detail;
    final downloads = det?.downloadLinks ?? [];
    final isArchive = widget.book.readerType == 'archive_org';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.cardNavy,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceNavy,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      widget.book.source,
                      style: GoogleFonts.cairo(
                        fontSize: 10.5,
                        color: AppColors.primaryGoldLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                det?.title ?? widget.book.title,
                style: GoogleFonts.amiri(
                  fontSize: 22 * fontScale,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.book.author,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: AppColors.primaryGold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Primary Read / Download Actions
              if (downloads.isNotEmpty) ...[
                for (int i = 0; i < downloads.take(3).length; i++) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openExternal(downloads[i]),
                      icon: Icon(
                        isArchive ? Icons.auto_stories_rounded : Icons.picture_as_pdf_rounded,
                        size: 18,
                      ),
                      label: Text(
                        isArchive
                            ? 'تصفح وقراءة الكتاب كاملاً (Archive Reader / PDF)'
                            : (downloads.length == 1
                                ? 'تحميل وقراءة الكتاب (PDF)'
                                : 'رابط التحميل والقراءة #${i + 1} (PDF)'),
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _openExternal(widget.book.url),
                  icon: const Icon(Icons.open_in_new_rounded, size: 17, color: AppColors.primaryGold),
                  label: Text(
                    'فتح صفحة الكتاب في المكتبة الأصلية',
                    style: GoogleFonts.cairo(
                      color: AppColors.primaryGoldLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.hairline),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    SharePlus.instance.share(
                      ShareParams(
                        text: '${widget.book.title}\n${widget.book.author}\n${widget.book.url}\n\nمن تطبيق أرثوذكسيا',
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_outlined, size: 15, color: AppColors.textMuted),
                  label: Text('مشاركة رابط الكتاب', style: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
        if ((det?.bodyText ?? '').isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            'نبذة عن الكتاب ومحتوياته',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryGoldLight,
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(
            det!.bodyText,
            style: GoogleFonts.amiri(
              fontSize: 18.5 * fontScale,
              height: 1.85,
              color: AppColors.textLight,
            ),
          ),
        ],
      ],
    );
  }
}
