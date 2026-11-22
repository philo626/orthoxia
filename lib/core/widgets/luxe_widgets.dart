import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_palette.dart';

/// Scales down gently on press with light haptic feedback.
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const PressScale({super.key, required this.child, this.onTap, this.scale = 0.96});

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
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
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
  const SafeAssetImage(
    this.path, {
    super.key,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.church_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Image.asset(
      path,
      fit: fit,
      errorBuilder: (_, _, _) => Container(
        color: p.surfaceSubtle,
        alignment: Alignment.center,
        child: Icon(fallbackIcon, color: p.gold, size: 28),
      ),
    );
  }
}

/// Adaptive circular icon button used in top bars.
class LuxeCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool badge;
  final double size;
  final String? tooltip;

  const LuxeCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.badge = false,
    this.size = 40,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final button = PressScale(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.surface,
              border: Border.all(color: p.border, width: 1),
              boxShadow: p.isDark
                  ? null
                  : [
                      BoxShadow(
                        color: p.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Icon(icon, color: p.ink, size: size * 0.48),
          ),
          if (badge)
            Positioned(
              top: 6,
              right: 7,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: p.crimson,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// Adaptive editorial icon tile (warm paper in daylight, warm charcoal at night).
class GoldIconTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;

  const GoldIconTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PressScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: p.surface,
              border: Border.all(color: p.border, width: 1),
              boxShadow: p.isDark
                  ? null
                  : [
                      BoxShadow(
                        color: p.shadow,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Icon(
              icon,
              size: 24,
              color: iconColor ?? (p.isDark ? p.gold : p.accent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: p.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Adaptive editorial horizontal list card.
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
    this.fallbackIcon = Icons.church_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PressScale(
      scale: 0.985,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border, width: 1),
          boxShadow: p.isDark
              ? null
              : [
                  BoxShadow(
                    color: p.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.amiri(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        color: p.inkSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 64,
                child: SafeAssetImage(image, fallbackIcon: fallbackIcon),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Adaptive page scaffold wrapper for pushed sub-views.
class TitledPage extends StatelessWidget {
  final String title;
  final Widget child;
  const TitledPage({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        foregroundColor: p.ink,
        title: Text(
          title,
          style: GoogleFonts.amiri(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: p.ink,
          ),
        ),
      ),
      body: child,
    );
  }
}

/// Smooth subtle fade + slide transition used across the app.
Route<T> luxeRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 360),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, _, _) => page,
    transitionsBuilder: (_, a, _, child) {
      final curved = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}
