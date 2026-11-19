import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Scales down on press with haptic feedback (micro-interaction).
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const PressScale({super.key, required this.child, this.onTap, this.scale = 0.94});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onTap!();
            },
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}

/// Asset image that never crashes if the file is missing.
class SafeAssetImage extends StatelessWidget {
  final String path;
  final BoxFit fit;
  final IconData fallbackIcon;
  const SafeAssetImage(this.path, {super.key, this.fit = BoxFit.cover, this.fallbackIcon = Icons.church_rounded});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        decoration: const BoxDecoration(gradient: AppColors.obsidianCard),
        alignment: Alignment.center,
        child: Icon(fallbackIcon, color: AppColors.primaryGold, size: 30),
      ),
    );
  }
}

/// Small dark circular icon button used in headers.
class LuxeCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool badge;
  final double size;
  const LuxeCircleButton({super.key, required this.icon, this.onTap, this.badge = false, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.45),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Icon(icon, color: AppColors.primaryGoldLight, size: size * 0.5),
          ),
          if (badge)
            Positioned(
              top: 6,
              right: 7,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Color(0xFFE5533D), shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}

/// Editorial matte-basalt icon tile with delicate antique-gold hairline border.
class GoldIconTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const GoldIconTile({super.key, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.cardNavy,
              border: Border.all(
                color: AppColors.primaryGold.withValues(alpha: 0.24),
                width: 0.9,
              ),
            ),
            child: Icon(
              icon,
              size: 26,
              color: AppColors.primaryGoldLight,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}

/// Editorial horizontal list card with subtle hairline frame and clean typography.
class ThumbListCard extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData fallbackIcon;
  const ThumbListCard({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.fallbackIcon = Icons.church_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.cardNavy,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.hairline, width: 0.9),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.amiri(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.textMuted, height: 1.45),
                    ),
                  ],
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(width: 72, height: 64, child: SafeAssetImage(image, fallbackIcon: fallbackIcon)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wraps body-only screens with a luxe app bar when pushed as a route.
class TitledPage extends StatelessWidget {
  final String title;
  final Widget child;
  const TitledPage({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        title: Text(title, style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryGoldLight)),
      ),
      body: child,
    );
  }
}

/// Fade + slide route used across the app.
Route<T> luxeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 480),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, a, __, child) {
      final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.05), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}
