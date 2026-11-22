import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_palette.dart';
import 'coptic_cross.dart';

/// Official four-color geometric Google "G" vector emblem.
class GoogleLogoMark extends StatelessWidget {
  final double size;
  const GoogleLogoMark({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.21;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;

    // Red top-left arc
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -2.55, 1.85, false, paint);

    // Yellow left arc
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 2.55, 1.18, false, paint);

    // Green bottom arc
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 0.72, 1.85, false, paint);

    // Blue right arc
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -0.04, 0.80, false, paint);

    // Blue horizontal crossbar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final cy = size.height / 2;
    canvas.drawRect(
      Rect.fromLTRB(
        size.width * 0.50,
        cy - stroke / 2,
        size.width * 0.98,
        cy + stroke / 2,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Restrained architectural emblem framing the engraved Coptic Cross —
/// zero neon rays or artificial particle sparkles.
class OrthodoxEmblem extends StatelessWidget {
  final double size;
  const OrthodoxEmblem({super.key, this.size = 76});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: p.surface,
        border: Border.all(color: p.goldBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size - 10,
            height: size - 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: p.gold.withValues(alpha: 0.28),
                width: 0.8,
              ),
            ),
          ),
          CopticCross(
            size: size * 0.52,
            color: p.isDark ? p.gold : p.accent,
          ),
        ],
      ),
    );
  }
}

/// Subtle liturgical arch ornament painted behind headers (quiet architectural texture).
class SubtleArchWatermark extends StatelessWidget {
  final double height;
  const SubtleArchWatermark({super.key, this.height = 140});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IgnorePointer(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _ArchWatermarkPainter(
            color: p.gold.withValues(alpha: p.isDark ? 0.08 : 0.12),
          ),
        ),
      ),
    );
  }
}

class _ArchWatermarkPainter extends CustomPainter {
  final Color color;
  _ArchWatermarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final cx = size.width / 2;
    for (final factor in [0.42, 0.54]) {
      final r = size.width * factor;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, size.height * 1.15), radius: r),
        math.pi,
        math.pi,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ArchWatermarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
