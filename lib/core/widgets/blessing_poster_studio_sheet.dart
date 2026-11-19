import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_colors.dart';
import 'coptic_cross.dart';

/// Studio for generating & sharing high-resolution luxury Coptic Blessing Cards as PNG Images
/// directly to WhatsApp Status, Instagram Stories, and Facebook.
class BlessingPosterStudioSheet extends StatefulWidget {
  final String title;
  final String bodyText;
  final String reference;
  final String footerPrayer;

  const BlessingPosterStudioSheet({
    super.key,
    required this.title,
    required this.bodyText,
    required this.reference,
    this.footerPrayer = '',
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String bodyText,
    required String reference,
    String footerPrayer = '',
  }) async {
    HapticFeedback.mediumImpact();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlessingPosterStudioSheet(
        title: title,
        bodyText: bodyText,
        reference: reference,
        footerPrayer: footerPrayer,
      ),
    );
  }

  @override
  State<BlessingPosterStudioSheet> createState() => _BlessingPosterStudioSheetState();
}

class _BlessingPosterStudioSheetState extends State<BlessingPosterStudioSheet> {
  final GlobalKey _posterKey = GlobalKey();
  int _themeIndex = 0;
  bool _isExporting = false;

  static const List<Map<String, dynamic>> _themes = [
    {
      'name': 'ذهبي ملكي',
      'colors': [Color(0xFF2B1F11), Color(0xFF10121A)],
      'border': AppColors.primaryGold,
    },
    {
      'name': 'نبيذي قبطي',
      'colors': [Color(0xFF3D1318), Color(0xFF120C10)],
      'border': Color(0xFFE5B869),
    },
    {
      'name': 'ياقوتي سماوي',
      'colors': [Color(0xFF12263F), Color(0xFF0C1018)],
      'border': Color(0xFF81D4FA),
    },
  ];

  Future<void> _exportAndShareImage() async {
    setState(() => _isExporting = true);
    try {
      final boundary =
          _posterKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final Uint8List pngBytes = byteData.buffer.asUint8List();

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              pngBytes,
              mimeType: 'image/png',
              name: 'orthodoxia_blessing.png',
            ),
          ],
          text: '✝ ${widget.title}\n«${widget.bodyText}»\n— ${widget.reference}\nتطبيق أرثوذكسيا',
        ),
      );
    } catch (_) {
      await SharePlus.instance.share(
        ShareParams(
          text: '✝ ${widget.title}\n«${widget.bodyText}»\n— ${widget.reference}\nتطبيق أرثوذكسيا',
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = _themes[_themeIndex];
    final colors = activeTheme['colors'] as List<Color>;
    final borderCol = activeTheme['border'] as Color;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF13151D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: AppColors.primaryGold, width: 1.5)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'استوديو كارت البركة المصور',
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGoldLight,
              ),
            ),
            Text(
              'اختر التصميم وشاركه كصورة عالية الجودة على حالة الواتساب أو فيسبوك',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),

            // Theme selector chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_themes.length, (i) {
                final sel = i == _themeIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(
                      _themes[i]['name'] as String,
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: sel ? Colors.black : Colors.white,
                      ),
                    ),
                    selected: sel,
                    selectedColor: AppColors.primaryGold,
                    backgroundColor: const Color(0xFF1C1F2B),
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _themeIndex = i),
                  ),
                );
              }),
            ),
            const SizedBox(height: 14),

            // RepaintBoundary Poster Card
            RepaintBoundary(
              key: _posterKey,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderCol, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CopticCross(size: 32, glow: 0.6),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: borderCol.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderCol.withValues(alpha: 0.45)),
                      ),
                      child: Text(
                        widget.title,
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGoldLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '«${widget.bodyText}»',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.75,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '— ${widget.reference}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGold,
                      ),
                    ),
                    if (widget.footerPrayer.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.footerPrayer,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.amiri(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CopticCross(size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'تطبيق أرثوذكسيا • الكنيسة القبطية الأرثوذكسية',
                          style: GoogleFonts.cairo(
                            fontSize: 10.5,
                            color: Colors.white60,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _isExporting ? null : _exportAndShareImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.share_rounded, size: 20),
              label: Text(
                _isExporting ? 'جاري تجهيز الصورة...' : 'مشاركة كصورة للواتساب وستوري',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
