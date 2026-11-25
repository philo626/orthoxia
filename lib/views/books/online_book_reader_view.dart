import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/services/online_coptic_library_service.dart';
import '../../core/services/security_guard_service.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/theme_provider.dart';
import '../liturgical/widgets/floating_church_bar.dart';
import 'visual_book_pages_reader_view.dart';

/// Unified full-book reader for Orthodox books across all sources:
/// - `in_app_chapters`: reads every full chapter directly inside the app with Windows-1256 support & offline caching.
/// - `archive_org`: opens the REAL full visual page-flip book inside an embedded in-app reader (`archive.org/embed/<id>`).
/// - `christianlib_post`: opens PDF links directly in an in-app PDF viewer (Google Docs Viewer) or the full book page.
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

  List<OnlineChapterLink> _chapters = [];
  int _chapterIdx = 0;
  List<String> _paragraphs = [];
  bool _isCached = false;

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
          final (paras, cached) =
              await _lib.fetchChapterParagraphs(widget.book.url);
          if (!mounted) return;
          setState(() {
            _chapters = [
              OnlineChapterLink(title: widget.book.title, url: widget.book.url)
            ];
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
          _error =
              'تعذّر تحميل فصول الكتاب حالياً. يمكنك إعادة المحاولة أو فتحه في القارئ الداخلي.';
        });
      }
    } else if (widget.book.readerType == 'archive_org') {
      // Archive.org books open straight into the real interactive page-flip book reader!
      setState(() {
        _detail = OnlineBookDetail(
          title: widget.book.title,
          bodyText: widget.book.description,
          downloadLinks: [widget.book.url],
          webUrl: widget.book.url,
        );
        _loading = false;
      });
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
            downloadLinks:
                widget.book.pdfUrl.isNotEmpty ? [widget.book.pdfUrl] : [],
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
      final (paras, cached) =
          await _lib.fetchChapterParagraphs(_chapters[idx].url);
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

  String _resolveArchiveEmbedUrl(String url) {
    final m = RegExp(r'archive\.org/details/([^/?#]+)').firstMatch(url);
    if (m != null) {
      return 'https://archive.org/embed/${m.group(1)}';
    }
    return SecurityGuardService.upgradeToHttps(url);
  }

  String _resolveInAppViewerUrl(String rawUrl) {
    final safe = SecurityGuardService.upgradeToHttps(rawUrl);
    if (safe.contains('archive.org/details/')) {
      return _resolveArchiveEmbedUrl(safe);
    }
    if (safe.toLowerCase().endsWith('.pdf')) {
      return 'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(safe)}';
    }
    return safe;
  }

  void _openInAppViewer(String url, {String? title}) {
    final safe = SecurityGuardService.upgradeToHttps(url);
    if (!SecurityGuardService.isSafeExternalUrl(safe)) return;
    // Open direct PDFs or Archive.org books straight into the true Visual Page-by-Page Book Reader!
    if (safe.toLowerCase().contains('.pdf') || safe.contains('archive.org/')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VisualBookPagesReaderView(
            book: widget.book,
            overridePdfUrl: safe.toLowerCase().contains('.pdf') ? safe : null,
          ),
        ),
      );
      return;
    }
    final viewerUrl = _resolveInAppViewerUrl(safe);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _InAppFullBookWebView(
          title: title ?? widget.book.title,
          viewerUrl: viewerUrl,
          originalUrl: safe,
        ),
      ),
    );
  }

  Future<void> _openExternal(String url) async {
    final safeUrl = SecurityGuardService.upgradeToHttps(url);
    if (!SecurityGuardService.isSafeExternalUrl(safeUrl)) return;
    final uri = Uri.tryParse(safeUrl);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openChapterSheet() {
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.72,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: p.border)),
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 3.5,
              decoration: BoxDecoration(
                color: p.borderStrong,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'فهرس الكتاب (${_chapters.length} فصلاً)',
              style: GoogleFonts.amiri(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: p.ink,
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
                      side: BorderSide(color: sel ? p.accent : p.border),
                    ),
                    tileColor: sel ? p.accentSoft : p.surfaceElevated,
                    title: Text(
                      _chapters[i].title,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        color: sel ? p.accent : p.ink,
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
    // Visual page-by-page books open IMMEDIATELY as real scanned book pages inside the app!
    if (widget.book.isVisualBook) {
      return VisualBookPagesReaderView(book: widget.book);
    }

    final p = context.palette;
    final fontScale = context.watch<ThemeProvider>().fontScale;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        elevation: 0,
        title: Text(
          widget.book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.amiri(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: p.ink,
          ),
        ),
        actions: [
          if (_chapters.length > 1)
            IconButton(
              icon: Icon(Icons.format_list_bulleted_rounded, color: p.accent),
              tooltip: 'فهرس الفصول',
              onPressed: _openChapterSheet,
            ),
          IconButton(
            icon: Icon(Icons.open_in_browser_rounded,
                color: p.inkMuted, size: 20),
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
                  CircularProgressIndicator(color: p.accent, strokeWidth: 2),
                  const SizedBox(height: 12),
                  Text(
                    'جارٍ فتح الكتاب الكامل وتجهيز القراءة...',
                    style: GoogleFonts.cairo(fontSize: 12.5, color: p.inkMuted),
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
                    Icon(Icons.menu_book_outlined,
                        color: p.inkSubtle, size: 42),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                          fontSize: 13.5, color: p.ink, height: 1.6),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      children: [
                        ElevatedButton(
                          onPressed: _init,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: p.accent,
                            foregroundColor: p.onAccent,
                          ),
                          child: Text('إعادة المحاولة',
                              style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.w700)),
                        ),
                        OutlinedButton(
                          onPressed: () => _openInAppViewer(widget.book.url),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: p.border),
                          ),
                          child: Text('فتح بالقارئ الداخلي',
                              style: GoogleFonts.cairo(color: p.accent)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else if (widget.book.readerType == 'in_app_chapters')
            _buildChaptersReader(p, fontScale)
          else
            _buildExternalLibraryDetail(p, fontScale),
          const FloatingChurchBar(),
        ],
      ),
    );
  }

  Widget _buildChaptersReader(AppPalette p, double fontScale) {
    final chapterTitle =
        _chapters.isNotEmpty ? _chapters[_chapterIdx].title : widget.book.title;
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
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
                        color: p.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_isCached)
                    Text(
                      'محفوظ للقراءة بدون إنترنت',
                      style: GoogleFonts.cairo(fontSize: 10.5, color: p.success),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                chapterTitle,
                style: GoogleFonts.amiri(
                  fontSize: 21 * fontScale,
                  fontWeight: FontWeight.w700,
                  color: p.ink,
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
                      icon: Icon(Icons.list_rounded, size: 16, color: p.accent),
                      label: Text(
                        'فصل ${_chapterIdx + 1} من ${_chapters.length}',
                        style:
                            GoogleFonts.cairo(fontSize: 11.5, color: p.accent),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_paragraphs.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  Text(
                    'يمكنك تصفح هذا الفصل مباشرة داخل القارئ الكامل',
                    style: GoogleFonts.cairo(color: p.inkMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _openInAppViewer(
                      _chapters.isNotEmpty
                          ? _chapters[_chapterIdx].url
                          : widget.book.url,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.accent,
                      foregroundColor: p.onAccent,
                    ),
                    icon: const Icon(Icons.auto_stories_rounded, size: 18),
                    label: Text('فتح القارئ الكامل',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          )
        else
          for (final para in _paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SelectableText(
                para,
                style: GoogleFonts.amiri(
                  fontSize: 19 * fontScale,
                  height: 1.9,
                  color: p.ink,
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
                icon:
                    Icon(Icons.arrow_back_rounded, size: 16, color: p.accent),
                label: Text('الفصل السابق',
                    style: GoogleFonts.cairo(color: p.accent)),
                style: OutlinedButton.styleFrom(
                    side: BorderSide(color: p.border)),
              )
            else
              const SizedBox.shrink(),
            if (_chapterIdx < _chapters.length - 1)
              ElevatedButton.icon(
                onPressed: () => _loadChapter(_chapterIdx + 1),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text('الفصل التالي',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: p.accent,
                  foregroundColor: p.onAccent,
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

  Widget _buildExternalLibraryDetail(AppPalette p, double fontScale) {
    final det = _detail;
    final downloads = det?.downloadLinks ?? [];
    final isArchive = widget.book.readerType == 'archive_org';
    final primaryReadUrl =
        downloads.isNotEmpty ? downloads.first : widget.book.url;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: p.surfaceElevated,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: p.accentSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isArchive ? 'كتاب مصوّر كامل (صفحة بصفحة)' : widget.book.source,
                      style: GoogleFonts.cairo(
                        fontSize: 10.5,
                        color: p.accent,
                        fontWeight: FontWeight.w700,
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
                  fontWeight: FontWeight.w700,
                  color: p.ink,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.book.author,
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: p.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              // PRIMARY CTA: Open REAL full visual book/PDF right INSIDE the app!
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openInAppViewer(
                    primaryReadUrl,
                    title: det?.title ?? widget.book.title,
                  ),
                  icon: Icon(
                    isArchive
                        ? Icons.auto_stories_rounded
                        : Icons.menu_book_rounded,
                    size: 19,
                  ),
                  label: Text(
                    isArchive
                        ? 'تصفح الكتاب المصوّر كاملاً داخل التطبيق'
                        : 'قراءة الكتاب الكامل (PDF) داخل التطبيق',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.accent,
                    foregroundColor: p.onAccent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Secondary external PDF download links
              if (downloads.isNotEmpty) ...[
                for (int i = 0; i < downloads.take(2).length; i++) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openExternal(downloads[i]),
                      icon: Icon(Icons.download_rounded,
                          size: 17, color: p.accent),
                      label: Text(
                        downloads.length == 1
                            ? 'تحميل نسخة PDF على الجهاز'
                            : 'تحميل نسخة PDF #${i + 1}',
                        style: GoogleFonts.cairo(
                          color: p.accent,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: p.border),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _openExternal(widget.book.url),
                    icon: Icon(Icons.open_in_new_rounded,
                        size: 15, color: p.inkMuted),
                    label: Text('فتح بالمتصفح',
                        style:
                            GoogleFonts.cairo(color: p.inkMuted, fontSize: 12)),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      SharePlus.instance.share(
                        ShareParams(
                          text:
                              '${widget.book.title}\n${widget.book.author}\n${widget.book.url}\n\nمن تطبيق أرثوذكسيا',
                        ),
                      );
                    },
                    icon: Icon(Icons.share_outlined,
                        size: 15, color: p.inkMuted),
                    label: Text('مشاركة الكتاب',
                        style:
                            GoogleFonts.cairo(color: p.inkMuted, fontSize: 12)),
                  ),
                ],
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
              fontWeight: FontWeight.w700,
              color: p.accent,
            ),
          ),
          const SizedBox(height: 10),
          SelectableText(
            det!.bodyText,
            style: GoogleFonts.amiri(
              fontSize: 18.5 * fontScale,
              height: 1.85,
              color: p.ink,
            ),
          ),
        ],
      ],
    );
  }
}

/// Embedded In-App Full Book & PDF Visual Reader (supports Archive.org flip-book & PDFs).
class _InAppFullBookWebView extends StatefulWidget {
  final String title;
  final String viewerUrl;
  final String originalUrl;

  const _InAppFullBookWebView({
    required this.title,
    required this.viewerUrl,
    required this.originalUrl,
  });

  @override
  State<_InAppFullBookWebView> createState() => _InAppFullBookWebViewState();
}

class _InAppFullBookWebViewState extends State<_InAppFullBookWebView> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (prog) {
            if (mounted) setState(() => _progress = prog);
          },
          onNavigationRequest: (req) {
            if (SecurityGuardService.isSafeExternalUrl(req.url)) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.viewerUrl));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        elevation: 0,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.amiri(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: p.ink,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: Icon(Icons.refresh_rounded, color: p.accent),
            onPressed: () => _controller.reload(),
          ),
          IconButton(
            tooltip: 'فتح خارجياً / تحميل',
            icon: Icon(Icons.open_in_new_rounded, color: p.inkMuted, size: 20),
            onPressed: () async {
              final uri = Uri.tryParse(widget.originalUrl);
              if (uri != null) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _progress / 100.0,
                  color: p.accent,
                  backgroundColor: p.border,
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
