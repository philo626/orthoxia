import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/storage_service.dart';
import '../../core/widgets/coptic_cross.dart';
import 'auth_view.dart';
import '../main_navigation_shell.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  final StorageService _storage = StorageService();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _storage.init();
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    // Show AuthView unless the user has explicitly completed the new v2 login/Google sign-in
    final next = _storage.isAuthV2Completed() ? const MainNavigationShell() : const AuthView();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 850),
        pageBuilder: (_, _, _) => next,
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          child: ScaleTransition(
            scale: Tween(begin: 1.04, end: 1.0).animate(anim),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 1.1,
            colors: [Color(0xFF1C1710), Colors.black],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const GlowingCrossHero(size: 120)
                  .animate()
                  .fadeIn(duration: 900.ms)
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    curve: Curves.easeOutBack,
                    duration: 1100.ms,
                  ),
              const SizedBox(height: 4),
              Text(
                'أرثوذكسيا',
                style: GoogleFonts.amiri(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGoldLight,
                  letterSpacing: 1.2,
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 800.ms)
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic)
                  .then()
                  .shimmer(duration: 1400.ms, color: Colors.white),
              const SizedBox(height: 6),
              Text(
                'صلاتك وتراثك القبطي الأرثوذكسي في كل حين',
                style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textMuted),
              ).animate().fadeIn(delay: 1000.ms, duration: 800.ms),
              const SizedBox(height: 46),
              SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: const LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Color(0xFF2A241A),
                    valueColor: AlwaysStoppedAnimation(AppColors.primaryGold),
                  ),
                ),
              ).animate().fadeIn(delay: 1200.ms),
            ],
          ),
        ),
      ),
    );
  }
}
