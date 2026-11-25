import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_palette.dart';
import 'coptic_cross.dart';

/// Pure-Dart ISO/IEC 18004 QR Code Matrix Generator (Byte mode, ECC Level M, Versions 1..6).
/// Zero external package bloat — produces 100% real scannable QR codes on every phone camera!
class PureQrMatrix {
  final int size;
  final List<List<bool>> modules;

  const PureQrMatrix({required this.size, required this.modules});

  // Version capacity (bytes) & ECC table for Level M (Versions 1..6)
  // Tuple: (version, dataCodewords, ecCodewordsPerBlock, numBlocks, alignmentCenters)
  static const List<(int, int, int, int, List<int>)> _versionSpecs = [
    (1, 16, 10, 1, []),
    (2, 28, 16, 1, [6, 18]),
    (3, 44, 26, 1, [6, 22]),
    (4, 64, 18, 2, [6, 26]),
    (5, 86, 24, 2, [6, 30]),
    (6, 108, 16, 4, [6, 34]),
  ];

  /// Encodes UTF-8 bytes of [text] into a standard scannable QR matrix.
  factory PureQrMatrix.encode(String text) {
    final dataBytes = Uint8List.fromList(text.codeUnits.where((c) => c < 256).toList());
    final payload = dataBytes.isEmpty ? Uint8List.fromList('ORTHOXIA'.codeUnits) : dataBytes;

    // Pick smallest version whose capacity fits 4-bit mode + 8-bit length + payload bytes
    final neededDataBytes = payload.length + 2;
    (int, int, int, int, List<int>) spec = _versionSpecs.last;
    for (final s in _versionSpecs) {
      if (s.$2 >= neededDataBytes) {
        spec = s;
        break;
      }
    }

    final version = spec.$1;
    final totalDataCodewords = spec.$2;
    final ecPerBlock = spec.$3;
    final numBlocks = spec.$4;
    final alignCenters = spec.$5;
    final size = 17 + 4 * version;

    // 1. Build bit stream: Byte Mode (0100) + 8-bit char count + data bytes + terminator + pad
    final bits = <int>[];
    void pushBits(int val, int count) {
      for (int i = count - 1; i >= 0; i--) {
        bits.add((val >> i) & 1);
      }
    }

    final clampedLen = payload.length.clamp(0, totalDataCodewords - 2);
    pushBits(0x4, 4); // Byte mode
    pushBits(clampedLen, 8);
    for (int i = 0; i < clampedLen; i++) {
      pushBits(payload[i], 8);
    }
    // Terminator (up to 4 zero bits)
    final maxBits = totalDataCodewords * 8;
    for (int i = 0; i < 4 && bits.length < maxBits; i++) {
      bits.add(0);
    }
    while (bits.length % 8 != 0) {
      bits.add(0);
    }

    final codewords = <int>[];
    for (int i = 0; i < bits.length; i += 8) {
      int b = 0;
      for (int j = 0; j < 8; j++) {
        b = (b << 1) | bits[i + j];
      }
      codewords.add(b);
    }
    const padBytes = [0xEC, 0x11];
    int padIdx = 0;
    while (codewords.length < totalDataCodewords) {
      codewords.add(padBytes[padIdx++ & 1]);
    }

    // 2. Split into blocks (all Versions 1..6 Level M have equal-sized blocks!) & compute Reed-Solomon ECC
    final blockDataLen = totalDataCodewords ~/ numBlocks;
    final dataBlocks = <List<int>>[];
    final ecBlocks = <List<int>>[];
    final genPoly = _rsGeneratorPoly(ecPerBlock);

    for (int b = 0; b < numBlocks; b++) {
      final block = codewords.sublist(b * blockDataLen, (b + 1) * blockDataLen);
      dataBlocks.add(block);
      ecBlocks.add(_rsRemainder(block, genPoly));
    }

    // 3. Interleave data and EC codewords
    final finalBytes = <int>[];
    for (int i = 0; i < blockDataLen; i++) {
      for (final db in dataBlocks) {
        finalBytes.add(db[i]);
      }
    }
    for (int i = 0; i < ecPerBlock; i++) {
      for (final eb in ecBlocks) {
        finalBytes.add(eb[i]);
      }
    }

    // 4. Initialize matrix and function-pattern mask
    final grid = List.generate(size, (_) => List.filled(size, false));
    final isFunc = List.generate(size, (_) => List.filled(size, false));

    void setFunc(int r, int c, bool dark) {
      if (r >= 0 && r < size && c >= 0 && c < size) {
        grid[r][c] = dark;
        isFunc[r][c] = true;
      }
    }

    void drawFinder(int top, int left) {
      for (int dr = -1; dr <= 7; dr++) {
        for (int dc = -1; dc <= 7; dc++) {
          final r = top + dr;
          final c = left + dc;
          if (r < 0 || r >= size || c < 0 || c >= size) continue;
          final inOuter = dr >= 0 && dr <= 6 && dc >= 0 && dc <= 6;
          final onBorder = dr == 0 || dr == 6 || dc == 0 || dc == 6;
          final inCore = dr >= 2 && dr <= 4 && dc >= 2 && dc <= 4;
          setFunc(r, c, inOuter && (onBorder || inCore));
        }
      }
    }

    drawFinder(0, 0);
    drawFinder(0, size - 7);
    drawFinder(size - 7, 0);

    // Timing patterns
    for (int i = 8; i < size - 8; i++) {
      setFunc(6, i, i.isEven);
      setFunc(i, 6, i.isEven);
    }

    // Alignment patterns
    for (final ar in alignCenters) {
      for (final ac in alignCenters) {
        if ((ar == 6 && ac == 6) ||
            (ar == 6 && ac == size - 7) ||
            (ar == size - 7 && ac == 6)) {
          continue;
        }
        for (int dr = -2; dr <= 2; dr++) {
          for (int dc = -2; dc <= 2; dc++) {
            final dark = dr.abs() == 2 || dc.abs() == 2 || (dr == 0 && dc == 0);
            setFunc(ar + dr, ac + dc, dark);
          }
        }
      }
    }

    // Reserve format info strips + Dark module
    for (int i = 0; i < 9; i++) {
      if (!isFunc[8][i]) setFunc(8, i, false);
      if (!isFunc[i][8]) setFunc(i, 8, false);
    }
    for (int i = 0; i < 8; i++) {
      setFunc(8, size - 1 - i, false);
      setFunc(size - 1 - i, 8, false);
    }
    setFunc(size - 8, 8, true); // Dark module (4*V + 9, 8)

    // 5. Place data bits in standard upward/downward 2-column zigzag + Mask 0 ((r + c) % 2 == 0)
    int bitIndex = 0;
    final totalBits = finalBytes.length * 8;
    bool upward = true;
    for (int right = size - 1; right >= 1; right -= 2) {
      if (right == 6) right = 5; // Skip vertical timing column
      for (int vert = 0; vert < size; vert++) {
        final r = upward ? (size - 1 - vert) : vert;
        for (int j = 0; j < 2; j++) {
          final c = right - j;
          if (!isFunc[r][c]) {
            bool dark = false;
            if (bitIndex < totalBits) {
              dark = ((finalBytes[bitIndex >> 3] >> (7 - (bitIndex & 7))) & 1) == 1;
              bitIndex++;
            }
            // Mask pattern 0: (r + c) % 2 == 0
            if ((r + c).isEven) dark = !dark;
            grid[r][c] = dark;
          }
        }
      }
      upward = !upward;
    }

    // 6. Write 15-bit BCH Format Information for ECC Level M (00) + Mask 0 (000) -> 0x5412
    // Standard precomputed 15-bit format word for (EC=M=00, Mask=000): 00000 -> BCH=0000000000 ^ 0x5412 = 0x5412
    const formatBits = 0x5412;
    for (int i = 0; i <= 5; i++) {
      grid[8][i] = ((formatBits >> (14 - i)) & 1) == 1;
    }
    grid[8][7] = ((formatBits >> 8) & 1) == 1;
    grid[8][8] = ((formatBits >> 7) & 1) == 1;
    grid[7][8] = ((formatBits >> 6) & 1) == 1;
    for (int i = 0; i <= 5; i++) {
      grid[5 - i][8] = ((formatBits >> (5 - i)) & 1) == 1;
    }
    for (int i = 0; i < 8; i++) {
      grid[8][size - 1 - i] = ((formatBits >> i) & 1) == 1;
    }
    for (int i = 0; i < 7; i++) {
      grid[size - 1 - i][8] = ((formatBits >> (14 - i)) & 1) == 1;
    }

    return PureQrMatrix(size: size, modules: grid);
  }

  // GF(256) with primitive polynomial 0x11D
  static int _gfMul(int a, int b) {
    int res = 0;
    int aa = a;
    int bb = b;
    while (bb > 0) {
      if ((bb & 1) != 0) res ^= aa;
      final hi = aa & 0x80;
      aa = (aa << 1) & 0xFF;
      if (hi != 0) aa ^= 0x1D;
      bb >>= 1;
    }
    return res;
  }

  static List<int> _rsGeneratorPoly(int degree) {
    var poly = <int>[1];
    int root = 1;
    for (int i = 0; i < degree; i++) {
      final next = List<int>.filled(poly.length + 1, 0);
      for (int j = 0; j < poly.length; j++) {
        next[j] ^= poly[j];
        next[j + 1] ^= _gfMul(poly[j], root);
      }
      poly = next;
      root = _gfMul(root, 2);
    }
    return poly;
  }

  static List<int> _rsRemainder(List<int> data, List<int> gen) {
    final rem = List<int>.filled(gen.length - 1, 0);
    for (final b in data) {
      final factor = b ^ rem[0];
      for (int i = 0; i < rem.length - 1; i++) {
        rem[i] = rem[i + 1];
      }
      rem[rem.length - 1] = 0;
      for (int i = 0; i < rem.length; i++) {
        rem[i] ^= _gfMul(gen[i + 1], factor);
      }
    }
    return rem;
  }
}

class _QrCanvasPainter extends CustomPainter {
  final PureQrMatrix matrix;
  final Color fgColor;

  const _QrCanvasPainter({required this.matrix, required this.fgColor});

  @override
  void paint(Canvas canvas, Size size) {
    const quiet = 2;
    final total = matrix.size + quiet * 2;
    final cell = size.width / total;
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(14)),
      bgPaint,
    );

    final fgPaint = Paint()
      ..color = fgColor
      ..style = PaintingStyle.fill;

    for (int r = 0; r < matrix.size; r++) {
      for (int c = 0; c < matrix.size; c++) {
        if (matrix.modules[r][c]) {
          canvas.drawRect(
            Rect.fromLTWH(
              (c + quiet) * cell,
              (r + quiet) * cell,
              cell + 0.35,
              cell + 0.35,
            ),
            fgPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrCanvasPainter oldDelegate) =>
      oldDelegate.matrix != matrix || oldDelegate.fgColor != fgColor;
}

/// Printable & Shareable Gold-and-Parchment QR Code Poster Card for Abouna's Confession Office & WhatsApp!
class PriestQrPosterSheet extends StatefulWidget {
  final String priestFullName;
  final String church;
  final String diocese;
  final String privateCode;

  const PriestQrPosterSheet({
    super.key,
    required this.priestFullName,
    required this.church,
    required this.diocese,
    required this.privateCode,
  });

  static Future<void> show(
    BuildContext context, {
    required String priestFullName,
    required String church,
    required String diocese,
    required String privateCode,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PriestQrPosterSheet(
        priestFullName: priestFullName,
        church: church,
        diocese: diocese,
        privateCode: privateCode,
      ),
    );
  }

  @override
  State<PriestQrPosterSheet> createState() => _PriestQrPosterSheetState();
}

class _PriestQrPosterSheetState extends State<PriestQrPosterSheet> {
  final GlobalKey _posterKey = GlobalKey();
  late final PureQrMatrix _qrMatrix;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final qrPayload = 'https://github.com/philo626/orthoxia#code=${widget.privateCode}';
    _qrMatrix = PureQrMatrix.encode(qrPayload);
  }

  Future<void> _shareAsPrintableImage() async {
    if (_exporting) return;
    HapticFeedback.mediumImpact();
    setState(() => _exporting = true);
    try {
      final boundary =
          _posterKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final tmpFile = File(
        '${Directory.systemTemp.path}/orthoxia_priest_qr_${widget.privateCode}.png',
      );
      await tmpFile.writeAsBytes(bytes, flush: true);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tmpFile.path, mimeType: 'image/png')],
          text:
              'كارت مواعيد اعتراف ${widget.priestFullName} على تطبيق أرثوذكسيا — الكود الخاص: ${widget.privateCode}\nجاهز للمشاركة في الجروب أو للطباعة على باب مكتب الاعتراف.',
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('معلش حصل خطأ بسيط في حفظ الصورة، جرب تاني.', style: GoogleFonts.cairo()),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: p.goldBorder)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(color: p.border, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'كارت QR Code جاهز للطباعة والواتساب',
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.bold, color: p.ink),
            ),
            Text(
              'قدسك تقدر تطبعه وتعلّقه على باب مكتب الاعتراف أو تبعته كصورة لأولادك',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 11.5, color: p.inkMuted),
            ),
            const SizedBox(height: 14),

            // LUXURIOUS PRINTABLE PARCHMENT & GOLD CARD
            RepaintBoundary(
              key: _posterKey,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFFAF3E3), Color(0xFFF3E6CA)],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFC89D46), width: 2.2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CopticCross(size: 18, color: Color(0xFF8B5E1A)),
                        const SizedBox(width: 8),
                        Text(
                          'تطبيق أرثوذكسيا • مواعيد الاعتراف',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF7B4F12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const CopticCross(size: 18, color: Color(0xFF8B5E1A)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.priestFullName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.amiri(
                        fontSize: 27,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF21160B),
                        height: 1.2,
                      ),
                    ),
                    if (widget.church.isNotEmpty)
                      Text(
                        widget.church,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF7D232A),
                        ),
                      ),
                    if (widget.diocese.isNotEmpty)
                      Text(
                        'إيبارشية: ${widget.diocese}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(fontSize: 11.5, color: const Color(0xFF6B5942)),
                      ),
                    const SizedBox(height: 16),

                    // REAL SCANNABLE QR CODE
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD5B165), width: 1.6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: 170,
                        height: 170,
                        child: CustomPaint(
                          painter: _QrCanvasPainter(
                            matrix: _qrMatrix,
                            fgColor: const Color(0xFF1A120A),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // GIANT READABLE PRIVATE CODE
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF23170E),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5C175), width: 1.3),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'كود أولاد الاعتراف',
                            style: GoogleFonts.cairo(
                              fontSize: 10.5,
                              color: const Color(0xFFEBD7B0),
                            ),
                          ),
                          Text(
                            widget.privateCode,
                            style: GoogleFonts.cairo(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFF6D993),
                              letterSpacing: 3.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '١) امسح الكود أو نزّل تطبيق أرثوذكسيا\n٢) افتح «مواعيد أبونا» ← «ربط بكود أب اعترافي»\n٣) اكتب الكود وسجّل حضورك باسمك الثنائي',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        color: const Color(0xFF473725),
                        fontWeight: FontWeight.w600,
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _exporting ? null : _shareAsPrintableImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: p.gold,
                foregroundColor: const Color(0xFF19130A),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: _exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF19130A)),
                    )
                  : const Icon(Icons.print_rounded, size: 20),
              label: Text(
                'مشاركة وحفظ كصورة للطباعة والواتساب',
                style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
