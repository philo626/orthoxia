import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/services/online_coptic_library_service.dart';
import '../../core/services/security_guard_service.dart';
import '../../core/theme/app_palette.dart';

/// True In-App Visual Page-by-Page Book Reader (ZERO extracted plain text!):
/// - Mode 1 (`native_pdf`): Downloads the PDF once into private app cache (100% offline reuse),
///   renders real scanned pages natively via Android's built-in `android.graphics.pdf.PdfRenderer`
///   inside an RTL right-to-left horizontal PageView with pinch-to-zoom, page scrubber,
///   auto-saved reading bookmark, and Warm Parchment / Night eye-comfort modes.
/// - Mode 2 (`flipbook`): Streams real scanned visual pages instantaneously via Archive.org's
///   BookReader embed (`https://archive.org/embed/<id>?ui=embed`) — ideal for large books (>22MB)
///   so Page 1 opens in ~1.5s without waiting for a large download.
class VisualBookPagesReaderView extends StatefulWidget {
  final OnlineBookEntry book;
  final String? overridePdfUrl;

  const VisualBookPagesReaderView({
    super.key,
    required this.book,
    this.overridePdfUrl,
  });

  @override
  State<VisualBookPagesReaderView> createState() =>
      _VisualBookPagesReaderViewState();
}

class _VisualBookPagesReaderViewState extends State<VisualBookPagesReaderView> {
  static const MethodChannel _pdfChannel =
      MethodChannel('com.orthodox.app/pdf_renderer');

  late String _pdfUrl;
  late String _embedUrl;
  bool get _hasDirectPdf =>
      _pdfUrl.isNotEmpty && _pdfUrl.toLowerCase().contains('.pdf');
  bool get _hasFlipbook => _embedUrl.isNotEmpty;

  // 'native_pdf' | 'flipbook'
  late String _activeMode;

  // Native PDF state
  bool _downloading = false;
  double? _downloadProgress; // 0.0..1.0 or null if indeterminate
  String _statusText = '';
  String? _errorMsg;
  String? _docId;
  int _pageCount = 0;
  int _currentPage = 0; // 0-indexed
  bool _isCachedOffline = false;
  String _eyeMode = 'original'; // 'original' | 'parchment' | 'night'

  PageController? _pageController;
  final LinkedHashMap<int, Uint8List> _pageCache = LinkedHashMap();
  final Set<int> _inFlightPages = {};
  http.Client? _httpClient;

  // Flipbook WebView state
  WebViewController? _webController;
  int _webProgress = 0;

  @override
  void initState() {
    super.initState();
    _pdfUrl = SecurityGuardService.upgradeToHttps(
      widget.overridePdfUrl ?? widget.book.pdfUrl,
    );
    _embedUrl = _resolveEmbedUrl();

    // Smart initial mode:
    // - If a book has a direct PDF <= 22MB (or no flipbook), open Native PDF PageView directly!
    // - If it's a huge book (> 22MB) with a flipbook, open Flipbook instantly unless PDF is already cached!
    if (_hasDirectPdf && (widget.book.fileSizeMb <= 22.0 || !_hasFlipbook)) {
      _activeMode = 'native_pdf';
    } else if (_hasFlipbook) {
      _activeMode = 'flipbook';
    } else {
      _activeMode = 'native_pdf';
    }

    _bootstrap();
  }

  String _resolveEmbedUrl() {
    if (widget.book.embedUrl.isNotEmpty) {
      return SecurityGuardService.upgradeToHttps(widget.book.embedUrl);
    }
    final m = RegExp(r'archive\.org/details/([^/?#]+)').firstMatch(widget.book.url);
    if (m != null) {
      return 'https://archive.org/embed/${m.group(1)}?ui=embed';
    }
    return '';
  }

  Future<void> _bootstrap() async {
    // Check if PDF is already cached locally; if so, ALWAYS open instant offline native pages!
    if (_hasDirectPdf) {
      final cachedFile = await _getLocalCacheFile();
      if (cachedFile != null && await cachedFile.exists() && await cachedFile.length() > 1024) {
        _isCachedOffline = true;
        _activeMode = 'native_pdf';
      }
    }
    if (!mounted) return;
    if (_activeMode == 'native_pdf') {
      await _initNativePdf();
    } else {
      _initFlipbookWebView();
    }
  }

  String get _bookmarkKey => 'visual_book_page_${widget.book.id.hashCode.abs()}';

  Future<File?> _getLocalCacheFile() async {
    try {
      final dirPath = await _pdfChannel.invokeMethod<String>('getBooksCacheDir');
      if (dirPath == null || dirPath.isEmpty) return null;
      final safeName = widget.book.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      return File('$dirPath/$safeName.pdf');
    } catch (_) {
      return null;
    }
  }

  Future<void> _initNativePdf() async {
    if (!mounted) return;
    setState(() {
      _downloading = true;
      _errorMsg = null;
      _downloadProgress = null;
      _statusText = 'جارٍ فتح صفحات الكتاب...';
    });

    try {
      final cacheFile = await _getLocalCacheFile();
      if (cacheFile == null) {
        // Non-Android / test environment fallback to Flipbook
        if (_hasFlipbook) {
          setState(() {
            _downloading = false;
            _activeMode = 'flipbook';
          });
          _initFlipbookWebView();
          return;
        }
        throw Exception('القارئ الأصلي لملفات PDF يعمل على أجهزة Android.');
      }

      if (!await cacheFile.exists() || await cacheFile.length() < 1024) {
        await _downloadPdfToFile(_pdfUrl, cacheFile);
      }

      if (!mounted) return;
      setState(() {
        _isCachedOffline = true;
        _statusText = 'جارٍ تجهيز الصفحات...';
      });

      final openRes = await _pdfChannel.invokeMapMethod<String, dynamic>(
        'openDocument',
        {'path': cacheFile.path},
      );
      if (openRes == null) {
        throw Exception('تعذّر فتح ملف الكتاب.');
      }

      final docId = openRes['docId'] as String?;
      final count = (openRes['pageCount'] as num?)?.toInt() ?? 0;
      if (docId == null || count <= 0) {
        throw Exception('تعذّر قراءة صفحات هذا الملف.');
      }

      final prefs = await SharedPreferences.getInstance();
      final savedPage = (prefs.getInt(_bookmarkKey) ?? 0).clamp(0, count - 1);

      _pageController?.dispose();
      _pageController = PageController(initialPage: savedPage);

      if (!mounted) return;
      setState(() {
        _docId = docId;
        _pageCount = count;
        _currentPage = savedPage;
        _downloading = false;
      });

      // Render current page + prefetch adjacent pages immediately
      unawaited(_ensurePageRendered(savedPage));
      if (savedPage + 1 < count) unawaited(_ensurePageRendered(savedPage + 1));
    } catch (e) {
      if (!mounted) return;
      // Seamless fallback to Archive.org Flipbook if PDF download or render fails!
      if (_hasFlipbook) {
        setState(() {
          _downloading = false;
          _activeMode = 'flipbook';
        });
        _initFlipbookWebView();
      } else {
        setState(() {
          _downloading = false;
          _errorMsg = 'تعذّر تحميل صفحات الكتاب حالياً. تأكد من الاتصال بالإنترنت وحاول مرة أخرى.';
        });
      }
    }
  }

  Future<void> _downloadPdfToFile(String url, File targetFile) async {
    if (!SecurityGuardService.isSafeExternalUrl(url)) {
      throw Exception('رابط غير آمن');
    }
    _httpClient?.close();
    _httpClient = http.Client();
    final req = http.Request('GET', Uri.parse(url));
    req.headers['User-Agent'] =
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Mobile Safari/537.36';
    final res = await _httpClient!.send(req).timeout(const Duration(seconds: 30));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}');
    }
    final totalBytes = res.contentLength ?? 0;
    final tmpFile = File('${targetFile.path}.part');
    final sink = tmpFile.openWrite();
    int received = 0;
    int lastPercent = -1;
    try {
      await for (final chunk in res.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (totalBytes > 0) {
          final pct = ((received / totalBytes) * 100).round().clamp(0, 100);
          if (pct != lastPercent && mounted) {
            lastPercent = pct;
            final mbRec = (received / (1024 * 1024)).toStringAsFixed(1);
            final mbTot = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
            setState(() {
              _downloadProgress = received / totalBytes;
              _statusText = 'جارٍ تجهيز صفحات الكتاب ($pct٪ • $mbRec / $mbTot ميجابايت)...';
            });
          }
        } else if (mounted && received % (256 * 1024) < chunk.length) {
          final mbRec = (received / (1024 * 1024)).toStringAsFixed(1);
          setState(() {
            _statusText = 'جارٍ تجهيز صفحات الكتاب ($mbRec ميجابايت)...';
          });
        }
      }
      await sink.flush();
      await sink.close();
      if (await tmpFile.length() < 1024) {
        throw Exception('ملف غير مكتمل');
      }
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await tmpFile.rename(targetFile.path);
    } catch (e) {
      await sink.close();
      if (await tmpFile.exists()) {
        try {
          await tmpFile.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  Future<void> _ensurePageRendered(int pageIdx) async {
    if (_docId == null || pageIdx < 0 || pageIdx >= _pageCount) return;
    if (_pageCache.containsKey(pageIdx) || _inFlightPages.contains(pageIdx)) {
      return;
    }
    _inFlightPages.add(pageIdx);
    try {
      final bytes = await _pdfChannel.invokeMethod<Uint8List>('renderPage', {
        'docId': _docId,
        'pageIndex': pageIdx,
        'widthPx': 1120,
      });
      if (bytes != null && bytes.isNotEmpty && mounted) {
        // LRU eviction (keep max 8 crisp pages in RAM so memory stays feather-light!)
        if (_pageCache.length >= 8) {
          _pageCache.remove(_pageCache.keys.first);
        }
        _pageCache[pageIdx] = bytes;
        setState(() {});
      }
    } catch (_) {
    } finally {
      _inFlightPages.remove(pageIdx);
    }
  }

  Future<void> _saveBookmark(int pageIdx) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bookmarkKey, pageIdx);
    } catch (_) {}
  }

  void _initFlipbookWebView() {
    if (_webController != null || !_hasFlipbook) return;
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (prog) {
            if (mounted) setState(() => _webProgress = prog);
          },
          onNavigationRequest: (req) {
            if (SecurityGuardService.isSafeExternalUrl(req.url)) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(_embedUrl));
    if (mounted) setState(() {});
  }

  void _switchMode(String target) {
    if (_activeMode == target) return;
    HapticFeedback.selectionClick();
    setState(() {
      _activeMode = target;
      _errorMsg = null;
    });
    if (target == 'native_pdf') {
      if (_docId == null) {
        _initNativePdf();
      }
    } else {
      _initFlipbookWebView();
    }
  }

  void _jumpToPage(int target) {
    final safe = target.clamp(0, (_pageCount - 1).clamp(0, 99999));
    _pageController?.jumpToPage(safe);
    setState(() => _currentPage = safe);
    _saveBookmark(safe);
    unawaited(_ensurePageRendered(safe));
    if (safe + 1 < _pageCount) unawaited(_ensurePageRendered(safe + 1));
  }

  void _showJumpToPageDialog() {
    final p = context.palette;
    final ctrl = TextEditingController(text: '${_currentPage + 1}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text(
          'الانتقال إلى صفحة',
          style: GoogleFonts.amiri(fontWeight: FontWeight.bold, color: p.ink),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: GoogleFonts.cairo(color: p.ink),
          decoration: InputDecoration(
            hintText: 'اكتب رقم الصفحة (١ - $_pageCount)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: GoogleFonts.cairo(color: p.inkMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              final numVal = int.tryParse(ctrl.text.trim());
              Navigator.pop(ctx);
              if (numVal != null && numVal >= 1 && numVal <= _pageCount) {
                _jumpToPage(numVal - 1);
              }
            },
            child: Text('انتقال', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _httpClient?.close();
    _pageController?.dispose();
    if (_docId != null) {
      unawaited(_pdfChannel.invokeMethod('closeDocument', {'docId': _docId}));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: _eyeMode == 'night'
          ? const Color(0xFF0E0E10)
          : (_eyeMode == 'parchment' ? const Color(0xFFF3E9D2) : p.canvas),
      appBar: AppBar(
        backgroundColor: p.canvas,
        foregroundColor: p.ink,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.amiri(
                fontWeight: FontWeight.bold,
                fontSize: 19,
                color: p.ink,
              ),
            ),
            Text(
              _activeMode == 'native_pdf' && _pageCount > 0
                  ? '${widget.book.author} • صفحة ${_currentPage + 1} من $_pageCount${_isCachedOffline ? ' (أوفلاين)' : ''}'
                  : widget.book.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
            ),
          ],
        ),
        actions: [
          // Toggle between Native Offline Pages (PDF) and Instant Streaming Flipbook
          if (_hasDirectPdf && _hasFlipbook)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: GestureDetector(
                onTap: () => _switchMode(
                  _activeMode == 'native_pdf' ? 'flipbook' : 'native_pdf',
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.goldSoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.goldBorder),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _activeMode == 'native_pdf' ? 'تصفّح فوري' : 'صفحات أوفلاين',
                    style: GoogleFonts.cairo(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: p.isDark ? p.gold : p.accent,
                    ),
                  ),
                ),
              ),
            ),
          if (_activeMode == 'native_pdf' && _pageCount > 0)
            IconButton(
              tooltip: 'وضع راحة العين (أصلي / ورق دافئ / ليلي)',
              icon: Icon(
                _eyeMode == 'night'
                    ? Icons.dark_mode_rounded
                    : (_eyeMode == 'parchment'
                        ? Icons.wb_sunny_outlined
                        : Icons.contrast_rounded),
                color: p.accent,
                size: 20,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _eyeMode = _eyeMode == 'original'
                      ? 'parchment'
                      : (_eyeMode == 'parchment' ? 'night' : 'original');
                });
              },
            ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: p.inkMuted, size: 20),
            onSelected: (val) async {
              if (val == 'share') {
                SharePlus.instance.share(
                  ShareParams(
                    text:
                        '${widget.book.title}\n${widget.book.author}\n${widget.book.url}\n\nمن تطبيق أرثوذكسيا',
                  ),
                );
              } else if (val == 'external') {
                final u = Uri.tryParse(SecurityGuardService.upgradeToHttps(widget.book.url));
                if (u != null) {
                  await launchUrl(u, mode: LaunchMode.externalApplication);
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'share',
                child: Text('مشاركة الكتاب', style: GoogleFonts.cairo(fontSize: 13)),
              ),
              PopupMenuItem(
                value: 'external',
                child: Text('فتح المصدر الأصلي', style: GoogleFonts.cairo(fontSize: 13)),
              ),
            ],
          ),
        ],
        bottom: _activeMode == 'flipbook' && _webProgress > 0 && _webProgress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _webProgress / 100.0,
                  color: p.accent,
                  backgroundColor: p.border,
                ),
              )
            : null,
      ),
      body: _activeMode == 'flipbook'
          ? _buildFlipbookBody(p)
          : _buildNativePdfBody(p),
    );
  }

  Widget _buildFlipbookBody(AppPalette p) {
    if (_webController == null) {
      return Center(child: CircularProgressIndicator(color: p.accent, strokeWidth: 2));
    }
    return Column(
      children: [
        if (_hasDirectPdf && !_isCachedOffline)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: p.surfaceSubtle,
              border: Border(bottom: BorderSide(color: p.border, width: 0.7)),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_stories_rounded, size: 15, color: p.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'تصفّح مصوّر فوري بصفحات الكتاب الأصلية',
                    style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkSecondary),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => _switchMode('native_pdf'),
                  child: Text(
                    'حفظ أوفلاين',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: p.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: WebViewWidget(controller: _webController!)),
      ],
    );
  }

  Widget _buildNativePdfBody(AppPalette p) {
    if (_downloading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.book.coverUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    widget.book.coverUrl,
                    width: 110,
                    height: 155,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.menu_book_rounded,
                      size: 56,
                      color: p.accent,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: 240,
                child: LinearProgressIndicator(
                  value: _downloadProgress,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(6),
                  color: p.accent,
                  backgroundColor: p.border,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _statusText.isNotEmpty ? _statusText : 'جارٍ تجهيز صفحات الكتاب...',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 13, color: p.ink),
              ),
              const SizedBox(height: 6),
              Text(
                'يُحفظ الكتاب على جهازك تلقائياً للتقليب أوفلاين في أي وقت.',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkMuted),
              ),
              if (_hasFlipbook) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    _httpClient?.close();
                    _switchMode('flipbook');
                  },
                  icon: Icon(Icons.bolt_rounded, size: 17, color: p.accent),
                  label: Text(
                    'التصفّح الفوري الآن بدون انتظار التحميل',
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: p.accent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (_errorMsg != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_outlined, size: 46, color: p.inkMuted),
              const SizedBox(height: 12),
              Text(
                _errorMsg!,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 13.5, color: p.ink, height: 1.6),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _initNativePdf,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('إعادة المحاولة',
                    style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    if (_pageCount <= 0 || _pageController == null) {
      return Center(child: CircularProgressIndicator(color: p.accent, strokeWidth: 2));
    }

    return Column(
      children: [
        // Real Physical-Book RTL PageView with Pinch-to-Zoom!
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pageCount,
            onPageChanged: (idx) {
              setState(() => _currentPage = idx);
              _saveBookmark(idx);
              unawaited(_ensurePageRendered(idx));
              if (idx + 1 < _pageCount) unawaited(_ensurePageRendered(idx + 1));
              if (idx - 1 >= 0) unawaited(_ensurePageRendered(idx - 1));
            },
            itemBuilder: (ctx, pageIdx) {
              final bytes = _pageCache[pageIdx];
              if (bytes == null) {
                unawaited(_ensurePageRendered(pageIdx));
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: p.accent, strokeWidth: 2),
                      const SizedBox(height: 10),
                      Text(
                        'صفحة ${pageIdx + 1}',
                        style: GoogleFonts.cairo(fontSize: 12, color: p.inkMuted),
                      ),
                    ],
                  ),
                );
              }

              Widget pageImg = Image.memory(
                bytes,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              );

              if (_eyeMode == 'night') {
                pageImg = ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    -1, 0, 0, 0, 240,
                    0, -1, 0, 0, 236,
                    0, 0, -1, 0, 228,
                    0, 0, 0, 1, 0,
                  ]),
                  child: pageImg,
                );
              } else if (_eyeMode == 'parchment') {
                pageImg = ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    const Color(0xFFF6EAD0).withValues(alpha: 0.35),
                    BlendMode.multiply,
                  ),
                  child: pageImg,
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Center(
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 3.5,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: pageImg,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Bottom Book Page Scrubber Bar
        Container(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          decoration: BoxDecoration(
            color: p.surface,
            border: Border(top: BorderSide(color: p.border)),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'الصفحة السابقة',
                  icon: Icon(Icons.chevron_right_rounded, color: p.accent),
                  onPressed: _currentPage > 0
                      ? () => _jumpToPage(_currentPage - 1)
                      : null,
                ),
                GestureDetector(
                  onTap: _showJumpToPageDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: p.goldSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.goldBorder),
                    ),
                    child: Text(
                      '${_currentPage + 1} / $_pageCount',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: p.isDark ? p.gold : p.accent,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _currentPage.toDouble().clamp(0, (_pageCount - 1).toDouble()),
                    min: 0,
                    max: (_pageCount - 1).clamp(1, 99999).toDouble(),
                    activeColor: p.accent,
                    onChanged: (v) => _jumpToPage(v.round()),
                  ),
                ),
                IconButton(
                  tooltip: 'الصفحة التالية',
                  icon: Icon(Icons.chevron_left_rounded, color: p.accent),
                  onPressed: _currentPage < _pageCount - 1
                      ? () => _jumpToPage(_currentPage + 1)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
