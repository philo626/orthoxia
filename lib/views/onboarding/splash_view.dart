import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/storage_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/coptic_cross.dart';
import '../main_navigation_shell.dart';
import '../priest/priest_navigation_shell.dart';
import 'auth_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  final StorageService _storage = StorageService();
  late final AnimationController _revealCtrl;
  late final AnimationController _haloCtrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _haloCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _opacity = CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOutBack),
    );

    _revealCtrl.forward();
    _bootstrap();
  }

  @override
  void dispose() {
    _revealCtrl.dispose();
    _haloCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _storage.init();
    await Future.delayed(const Duration(milliseconds: 1150));
    if (!mounted) return;

    final Widget next;
    if (!_storage.isAuthV2Completed()) {
      next = const AuthView();
    } else if (_storage.isPriestRole()) {
      next = const PriestNavigationShell();
    } else {
      next = const MainNavigationShell();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 620),
        pageBuilder: (_, _, _) => next,
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: const Color(0xFF120E0B),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Deep warm sanctuary radial glow
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.22),
                radius: 0.95,
                colors: [
                  Color(0xFF332316),
                  Color(0xFF1A130D),
                  Color(0xFF0E0B08),
                ],
              ),
            ),
          ),

          // Rotating sacred light aura behind Christ medallion
          Center(
            child: FadeTransition(
              opacity: _opacity,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 196,
                      height: 196,
                      child: AnimatedBuilder(
                        animation: _haloCtrl,
                        builder: (_, child) {
                          final pulse = 0.5 + 0.5 * math.sin(_haloCtrl.value * 2 * math.pi);
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 174 + (pulse * 16),
                                height: 174 + (pulse * 16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      const Color(0xFFE6C174).withValues(alpha: 0.34 + pulse * 0.14),
                                      const Color(0xFFA47A2E).withValues(alpha: 0.08),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                              Transform.rotate(
                                angle: _haloCtrl.value * 2 * math.pi,
                                child: CustomPaint(
                                  size: const Size(184, 184),
                                  painter: _SplashHaloRaysPainter(),
                                ),
                              ),
                              child!,
                            ],
                          );
                        },
                        child: Container(
                          width: 138,
                          height: 138,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFF3D591),
                                Color(0xFFA47A2E),
                                Color(0xFF6B4A18),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD8B46C).withValues(alpha: 0.35),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/christ_pantocrator.jpg',
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CopticCross(size: 16, color: p.gold),
                        const SizedBox(width: 10),
                        Text(
                          'أرثوذكسيا',
                          style: GoogleFonts.amiri(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFF9F1E1),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(width: 10),
                        CopticCross(size: 16, color: p.gold),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '«أَنَا هُوَ نُورُ الْعَالَمِ» • الكنيسة في قلب يومك',
                      style: GoogleFonts.cairo(
                        fontSize: 12.5,
                        color: const Color(0xFFD9C7A7),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashHaloRaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = const Color(0xFFE5C175).withValues(alpha: 0.28)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, size.width * 0.44, paint);

    final rayPaint = Paint()
      ..color = const Color(0xFFE5C175).withValues(alpha: 0.22)
      ..strokeWidth = 1.0;

    const count = 24;
    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * math.pi) / count;
      final r1 = size.width * 0.42;
      final r2 = i.isEven ? size.width * 0.50 : size.width * 0.465;
      canvas.drawLine(
        Offset(center.dx + r1 * math.cos(angle), center.dy + r1 * math.sin(angle)),
        Offset(center.dx + r2 * math.cos(angle), center.dy + r2 * math.sin(angle)),
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
