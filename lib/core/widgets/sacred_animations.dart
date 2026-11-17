import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Custom Glowing Coptic Lamp / Cross Vector Loader replacing static spinners
class SacredCopticLoader extends StatelessWidget {
  final String message;

  const SacredCopticLoader({
    super.key,
    this.message = 'جاري التحميل بنعمة الله...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing golden halo
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryGold.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(0.85, 0.85), end: const Offset(1.3, 1.3), duration: 1200.ms),

              // Glowing Coptic Sanctuary Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.sacredBurgundy.withValues(alpha: 0.45),
                  border: Border.all(color: AppColors.primaryGold, width: 1.5),
                ),
                child: const Icon(Icons.church_rounded, color: AppColors.primaryGold, size: 28),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(duration: 1600.ms, color: AppColors.primaryGoldLight),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.cairo(
              fontSize: 13,
              color: AppColors.primaryGoldLight,
              fontWeight: FontWeight.w600,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(begin: 0.5, end: 1.0, duration: 900.ms),
        ],
      ),
    );
  }
}

/// Tactile Spring Scale Button with Haptic Feedback
class SacredScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const SacredScaleButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<SacredScaleButton> createState() => _SacredScaleButtonState();
}

class _SacredScaleButtonState extends State<SacredScaleButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        setState(() => _pressed = true);
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// Smooth Fade + Slide Page Route for Liturgical Screens
Route<T> sacredRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}
