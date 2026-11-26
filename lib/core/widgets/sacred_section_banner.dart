import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_palette.dart';
import 'coptic_cross.dart';
import 'luxe_widgets.dart';

/// Handcrafted Editorial Sacred Section Banner:
/// Uses authentic Coptic iconography & church sanctuary photography (never generic icons-in-a-box)
/// with warm vignette scrim and crisp Amiri calligraphy.
class SacredSectionBanner extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String? subtitle;
  final String? badge;
  final double height;
  final Widget? trailing;
  final EdgeInsetsGeometry margin;

  const SacredSectionBanner({
    super.key,
    required this.imageAsset,
    required this.title,
    this.subtitle,
    this.badge,
    this.height = 128,
    this.trailing,
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 10),
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      margin: margin,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.goldBorder.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: p.shadow.withValues(alpha: p.isDark ? 0.42 : 0.16),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeAssetImage(imageAsset, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.05, 0.55, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.86),
                  ],
                ),
              ),
            ),
            if (badge != null && badge!.isNotEmpty)
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.48),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.55)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CopticCross(size: 11, color: Color(0xFFEBD6A8)),
                      const SizedBox(width: 5),
                      Text(
                        badge!,
                        style: GoogleFonts.cairo(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF5E6C4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              right: 14,
              left: 14,
              bottom: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.amiri(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.15,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.cairo(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact Katameros-style Dropdown Selector Pill used across Prayers, Agpeya,
/// Tasbeha, Madayeh, Liturgies, and Church Rites for crisp 1-tap navigation.
class LiturgicalDropdownBox<T> extends StatelessWidget {
  final String? label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool dense;

  const LiturgicalDropdownBox({
    super.key,
    this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 12,
        vertical: dense ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: p.goldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null && label!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                label!,
                style: GoogleFonts.cairo(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: p.accent,
                  height: 1.0,
                ),
              ),
            ),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              isDense: dense,
              dropdownColor: p.surface,
              value: value,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: dense ? 18 : 21,
                color: p.accent,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Editorial Photo-Backed Navigation Card (replaces generic icon-in-a-box AI tiles).
class SacredImageTileCard extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final double height;

  const SacredImageTileCard({
    super.key,
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.height = 112,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PressScale(
      scale: 0.97,
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.goldBorder.withValues(alpha: 0.65)),
          boxShadow: p.isDark
              ? null
              : [
                  BoxShadow(
                    color: p.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: Stack(
            fit: StackFit.expand,
            children: [
              SafeAssetImage(imageAsset, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.1, 0.55, 1.0],
                    colors: [
                      Colors.black.withValues(alpha: 0.12),
                      Colors.black.withValues(alpha: 0.42),
                      Colors.black.withValues(alpha: 0.86),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 12,
                left: 12,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.amiri(
                        fontSize: 18.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 10.2,
                        color: Colors.white.withValues(alpha: 0.86),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact Photo-Thumbnail Directory Row/Grid Item (for Treasures, Tools & Liturgical Lists).
class SacredThumbItemCard extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool highlightBorder;

  const SacredThumbItemCard({
    super.key,
    required this.imageAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.highlightBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PressScale(
      scale: 0.97,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: highlightBorder ? p.goldBorder : p.border),
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
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: SizedBox(
                width: 44,
                height: 44,
                child: SafeAssetImage(imageAsset, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 12.2,
                      fontWeight: FontWeight.bold,
                      color: p.ink,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 9.8,
                      color: p.inkMuted,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
