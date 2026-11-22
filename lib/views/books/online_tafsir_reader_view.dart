import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/online_coptic_library_service.dart';
import '../../core/services/speech_pronunciation_service.dart';
import '../../core/theme/app_palette.dart';
import '../../providers/theme_provider.dart';
import '../liturgical/widgets/floating_church_bar.dart';

/// Full editorial chapter-by-chapter Patristic Bible Commentary reader
/// (Fr. Tadros Yacoub Malaty & Fr. Antonios Fekry), 100% adaptive to AppPalette.
class OnlineTafsirReaderView extends StatefulWidget {
  final TafsirBookEntry book;
  final String initialCommentator;
  final ValueChanged<String>? onSearchMatta;

  const OnlineTafsirReaderView({
    super.key,
    required this.book,
    this.initialCommentator = 'tadros',
    this.onSearchMatta,
  });

  @override
  State<OnlineTafsirReaderView> createState() => _OnlineTafsirReaderViewState();
}

class _OnlineTafsirReaderViewState extends State<OnlineTafsirReaderView> {
  final OnlineCopticLibraryService _lib = OnlineCopticLibraryService();
  final SpeechPronunciationService _speech = SpeechPronunciationService();
  final ScrollController _scrollController = ScrollController();

  late String _commentator;
  List<OnlineChapterLink> _chapters = [];
  int _selectedChapterIdx = 0;
  List<String> _paragraphs = [];
  bool _loadingIndex = true;
  bool _loadingChapter = false;
  bool _isCachedOffline = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _commentator =
        (widget.initialCommentator == 'tadros' && widget.book.tadrosUrl.isNotEmpty)
            ? 'tadros'
            : (widget.book.antoniosUrl.isNotEmpty ? 'antonios' : 'tadros');
    _loadChapterIndex();
  }

  @override
  void dispose() {
    _speech.stop();
    _scrollController.dispose();
    super.dispose();
  }

  String get _activeIndexUrl =>
      _commentator == 'tadros' ? widget.book.tadrosUrl : widget.book.antoniosUrl;

  String get _commentatorName => _commentator == 'tadros'
      ? 'القمص تادرس يعقوب ملطي'
      : 'القمص أنطونيوس فكري';

  Future<void> _loadChapterIndex() async {
    setState(() {
      _loadingIndex = true;
      _errorMsg = null;
      _chapters = [];
      _paragraphs = [];
    });
    try {
      final list = await _lib.fetchChapters(_activeIndexUrl);
      if (!mounted) return;
      if (list.isEmpty) {
        setState(() {
          _loadingIndex = false;
          _errorMsg =
              'لم يتم العثور على فهرس الأصحاحات لهذا المفسر. جرب التبديل للمفسر الآخر.';
        });
        return;
      }
      setState(() {
        _chapters = list;
        _selectedChapterIdx = 0;
        _loadingIndex = false;
      });
      await _loadChapterContent(0);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingIndex = false;
        _errorMsg =
            'يتطلب تحميل التفسير لأول مرة اتصالاً بالإنترنت؛ وبعد قراءته يُحفظ تلقائياً للعمل بدون إنترنت.';
      });
    }
  }

  Future<void> _loadChapterContent(int idx) async {
    if (idx < 0 || idx >= _chapters.length) return;
    _speech.stop();
    setState(() {
      _selectedChapterIdx = idx;
      _loadingChapter = true;
      _errorMsg = null;
    });
    try {
      final (paras, cached) =
          await _lib.fetchChapterParagraphs(_chapters[idx].url);
      if (!mounted) return;
      setState(() {
        _paragraphs = paras;
        _isCachedOffline = cached;
        _loadingChapter = false;
      });
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingChapter = false;
        _errorMsg =
            'تعذّر تحميل هذا الأصحاح الآن. تأكد من اتصالك بالإنترنت وحاول مرة أخرى.';
      });
    }
  }

  void _openChapterPicker() {
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
              'فهرس تفسير ${widget.book.name} (${_chapters.length})',
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
                  final sel = i == _selectedChapterIdx;
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
                    trailing: sel
                        ? Icon(Icons.check_rounded, color: p.accent, size: 18)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      _loadChapterContent(i);
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
    final p = context.palette;
    final fontScale = context.watch<ThemeProvider>().fontScale;
    final hasTadros = widget.book.tadrosUrl.isNotEmpty;
    final hasAntonios = widget.book.antoniosUrl.isNotEmpty;
    final activeTitle = _chapters.isNotEmpty
        ? _chapters[_selectedChapterIdx].title
        : 'تفسير ${widget.book.name}';

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تفسير ${widget.book.name}',
              style: GoogleFonts.amiri(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: p.ink,
              ),
            ),
            Text(
              _commentatorName,
              style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
            ),
          ],
        ),
        actions: [
          if (_chapters.isNotEmpty)
            IconButton(
              icon: Icon(Icons.format_list_numbered_rtl_rounded,
                  color: p.accent),
              tooltip: 'فهرس الأصحاحات',
              onPressed: _openChapterPicker,
            ),
          if (_paragraphs.isNotEmpty)
            IconButton(
              icon: Icon(Icons.share_outlined, color: p.accent, size: 20),
              tooltip: 'مشاركة',
              onPressed: () {
                final preview = _paragraphs.take(3).join('\n\n');
                SharePlus.instance.share(
                  ShareParams(
                    text:
                        '$activeTitle\n($_commentatorName)\n\n$preview\n\nمن تطبيق أرثوذكسيا',
                  ),
                );
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: p.border)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        if (hasTadros)
                          Expanded(
                            child: _buildCommentatorTab(
                              p: p,
                              keyId: 'tadros',
                              label: 'القمص تادرس يعقوب ملطي',
                            ),
                          ),
                        if (hasTadros && hasAntonios) const SizedBox(width: 8),
                        if (hasAntonios)
                          Expanded(
                            child: _buildCommentatorTab(
                              p: p,
                              keyId: 'antonios',
                              label: 'القمص أنطونيوس فكري',
                            ),
                          ),
                      ],
                    ),
                    if (widget.book.mattaQuery.isNotEmpty &&
                        widget.onSearchMatta != null) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSearchMatta!(widget.book.mattaQuery);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: p.surfaceMuted,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: p.border),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.menu_book_outlined,
                                  size: 15, color: p.accent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'تصفّح أيضاً شروح الأب متى المسكين لـ ${widget.book.name}',
                                  style: GoogleFonts.cairo(
                                      fontSize: 11, color: p.accent),
                                ),
                              ),
                              Icon(Icons.chevron_left_rounded,
                                  size: 15, color: p.inkMuted),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: _loadingIndex || _loadingChapter
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                                color: p.accent, strokeWidth: 2),
                            const SizedBox(height: 14),
                            Text(
                              _loadingIndex
                                  ? 'جارٍ تحميل فهرس التفسير...'
                                  : 'جارٍ تجهيز النص للقراءة...',
                              style: GoogleFonts.cairo(
                                  fontSize: 12.5, color: p.inkMuted),
                            ),
                          ],
                        ),
                      )
                    : _errorMsg != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cloud_off_rounded,
                                      color: p.inkSubtle, size: 42),
                                  const SizedBox(height: 12),
                                  Text(
                                    _errorMsg!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cairo(
                                      fontSize: 13.5,
                                      color: p.ink,
                                      height: 1.6,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _chapters.isEmpty
                                        ? _loadChapterIndex
                                        : () => _loadChapterContent(
                                            _selectedChapterIdx),
                                    icon: const Icon(Icons.refresh_rounded,
                                        size: 17),
                                    label: Text('إعادة المحاولة',
                                        style: GoogleFonts.cairo(
                                            fontWeight: FontWeight.w700)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: p.accent,
                                      foregroundColor: p.onAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: p.surfaceElevated,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: p.border),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            activeTitle,
                                            style: GoogleFonts.amiri(
                                              fontSize: 20 * fontScale,
                                              fontWeight: FontWeight.w700,
                                              color: p.ink,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                        if (_isCachedOffline)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: p.success
                                                  .withValues(alpha: 0.14),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'محفوظ أوفلاين',
                                              style: GoogleFonts.cairo(
                                                fontSize: 10,
                                                color: p.success,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        SpeechPlayStopButton(
                                          textToSpeak:
                                              _paragraphs.take(25).join(' '),
                                          label: activeTitle,
                                          playText: 'استماع للتفسير',
                                          stopText: 'إيقاف الصوت',
                                          compact: true,
                                        ),
                                        const Spacer(),
                                        TextButton.icon(
                                          onPressed: _openChapterPicker,
                                          icon: Icon(Icons.list_alt_rounded,
                                              size: 16, color: p.accent),
                                          label: Text(
                                            'الأصحاح (${_selectedChapterIdx + 1}/${_chapters.length})',
                                            style: GoogleFonts.cairo(
                                              fontSize: 11.5,
                                              color: p.accent,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
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
                              const SizedBox(height: 22),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  if (_selectedChapterIdx > 0)
                                    OutlinedButton.icon(
                                      onPressed: () => _loadChapterContent(
                                          _selectedChapterIdx - 1),
                                      icon: Icon(Icons.arrow_back_rounded,
                                          size: 16, color: p.accent),
                                      label: Text('الأصحاح السابق',
                                          style: GoogleFonts.cairo(
                                              color: p.accent, fontSize: 12.5)),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: p.border),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink(),
                                  if (_selectedChapterIdx <
                                      _chapters.length - 1)
                                    ElevatedButton.icon(
                                      onPressed: () => _loadChapterContent(
                                          _selectedChapterIdx + 1),
                                      icon: const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 16),
                                      label: Text('الأصحاح التالي',
                                          style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12.5)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: p.accent,
                                        foregroundColor: p.onAccent,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink(),
                                ],
                              ),
                            ],
                          ),
              ),
            ],
          ),
          const FloatingChurchBar(),
        ],
      ),
    );
  }

  Widget _buildCommentatorTab({
    required AppPalette p,
    required String keyId,
    required String label,
  }) {
    final active = _commentator == keyId;
    return GestureDetector(
      onTap: () {
        if (active) return;
        HapticFeedback.selectionClick();
        setState(() => _commentator = keyId);
        _loadChapterIndex();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: active ? p.accent : p.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? p.accent : p.border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.cairo(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: active ? p.onAccent : p.ink,
          ),
        ),
      ),
    );
  }
}
