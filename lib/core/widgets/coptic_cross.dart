import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Ornate Coptic cross drawn with vector paths and a champagne-gold gradient.
class CopticCross extends StatelessWidget {
  final double size;
  final double glow; // 0..1 glow intensity
  final Color? color;

  const CopticCross({super.key, this.size = 64, this.glow = 0.0, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _CopticCrossPainter(glow: glow, solid: color)),
    );
  }
}

class _CopticCrossPainter extends CustomPainter {
  final double glow;
  final Color? solid;
  _CopticCrossPainter({required this.glow, this.solid});

  Path _crossPath(double s) {
    final path = Path();
    for (int i = 0; i < 4; i++) {
      final m = Matrix4.rotationZ(i * math.pi / 2).storage;
      final arm = Path()
        ..moveTo(-0.075 * s, -0.12 * s)
        ..lineTo(-0.16 * s, -0.70 * s)
        ..lineTo(0.16 * s, -0.70 * s)
        ..lineTo(0.075 * s, -0.12 * s)
        ..close()
        ..addOval(Rect.fromCircle(center: Offset(0, -0.84 * s), radius: 0.085 * s))
        ..addOval(Rect.fromCircle(center: Offset(-0.15 * s, -0.74 * s), radius: 0.075 * s))
        ..addOval(Rect.fromCircle(center: Offset(0.15 * s, -0.74 * s), radius: 0.075 * s));
      path.addPath(arm.transform(m), Offset.zero);
    }
    path.addOval(Rect.fromCircle(center: Offset.zero, radius: 0.17 * s));
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 2;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final path = _crossPath(s);

    if (glow > 0) {
      canvas.drawPath(
        path,
        Paint()
          ..color = AppColors.primaryGold.withValues(alpha: 0.55 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.22),
      );
    }

    final rect = Rect.fromCircle(center: Offset.zero, radius: s);
    final fill = Paint()
      ..shader = solid != null
          ? LinearGradient(colors: [solid!, solid!]).createShader(rect)
          : const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF1D2), Color(0xFFE2C089), Color(0xFFB08A4F), Color(0xFFE9CC96)],
              stops: [0.0, 0.35, 0.7, 1.0],
            ).createShader(rect);
    canvas.drawPath(path, fill);

    // Engraved inner detailing
    final engrave = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.022
      ..color = const Color(0xFF6B4E25).withValues(alpha: 0.75);
    for (int i = 0; i < 4; i++) {
      final a = i * math.pi / 2;
      final dir = Offset(math.sin(a), -math.cos(a));
      canvas.drawLine(dir * (0.2 * s), dir * (0.66 * s), engrave);
    }
    canvas.drawCircle(Offset.zero, 0.1 * s, engrave);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.018
        ..color = const Color(0xFF8A6A38).withValues(alpha: 0.9),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CopticCrossPainter old) => old.glow != glow || old.solid != solid;
}

/// Animated hero: rotating light rays, floating sparks and a breathing glowing cross.
class GlowingCrossHero extends StatefulWidget {
  final double size;
  const GlowingCrossHero({super.key, this.size = 150});

  @override
  State<GlowingCrossHero> createState() => _GlowingCrossHeroState();
}

class _GlowingCrossHeroState extends State<GlowingCrossHero> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.size * 2.0;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        final breath = 0.65 + 0.35 * math.sin(t * 2 * math.pi * 2);
        return SizedBox(
          width: box,
          height: box,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(size: Size(box, box), painter: _RaysPainter(t: t, intensity: breath)),
              Transform.scale(
                scale: 0.97 + 0.03 * breath,
                child: CopticCross(size: widget.size, glow: breath),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RaysPainter extends CustomPainter {
  final double t;
  final double intensity;
  _RaysPainter({required this.t, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(
      c,
      r * 0.75,
      Paint()
        ..shader = RadialGradient(colors: [
          AppColors.primaryGold.withValues(alpha: 0.22 * intensity),
          Colors.transparent,
        ]).createShader(Rect.fromCircle(center: c, radius: r * 0.75)),
    );
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(t * 2 * math.pi / 3);
    final ray = Paint()..style = PaintingStyle.fill;
    const n = 14;
    for (int i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n;
      final p = Path()
        ..moveTo(0, 0)
        ..lineTo(math.cos(a - 0.04) * r, math.sin(a - 0.04) * r)
        ..lineTo(math.cos(a + 0.04) * r, math.sin(a + 0.04) * r)
        ..close();
      ray.shader = RadialGradient(colors: [
        AppColors.primaryGoldLight.withValues(alpha: 0.18 * intensity),
        Colors.transparent,
      ]).createShader(Rect.fromCircle(center: Offset.zero, radius: r));
      canvas.drawPath(p, ray);
    }
    canvas.restore();
    // sparks
    final rnd = math.Random(7);
    for (int i = 0; i < 26; i++) {
      final baseA = rnd.nextDouble() * 2 * math.pi;
      final dist = (0.35 + rnd.nextDouble() * 0.6) * r;
      final phase = (t + rnd.nextDouble()) % 1.0;
      final a = baseA + phase * 0.6;
      final pos = c + Offset(math.cos(a), math.sin(a)) * dist;
      final alpha = math.sin(phase * math.pi);
      canvas.drawCircle(
        pos,
        1.0 + rnd.nextDouble() * 1.6,
        Paint()..color = AppColors.primaryGoldLight.withValues(alpha: 0.7 * alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RaysPainter old) => true;
}
