import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_palette.dart';
import 'coptic_cross.dart';

enum SaintAvatarShape { circle, arch, museumCard }

/// Renders an authentic Coptic/Orthodox saint icon portrait — supporting both
/// instant bundled Neo-Coptic assets (`assets/...`) and curated online portraits
/// inside a museum-grade frame that adapts seamlessly to Parchment & Dark modes.
class SaintIconAvatar extends StatelessWidget {
  final String imageUrl;
  final double size;
  final SaintAvatarShape shape;
  final bool showBorder;
  final String? saintName;
  final String? saintTitle;
  final bool enableFullViewer;

  const SaintIconAvatar({
    super.key,
    required this.imageUrl,
    this.size = 52,
    this.shape = SaintAvatarShape.circle,
    this.showBorder = true,
    this.saintName,
    this.saintTitle,
    this.enableFullViewer = false,
  });

  static const Map<String, String> _imageHeaders = {
    'User-Agent': 'OrthodoxiaCopticApp/1.0 (https://github.com/philo626/orthoxia)',
    'Accept': 'image/webp,image/apng,image/*,*/*;q=0.8',
  };

  bool get _isAsset => imageUrl.startsWith('assets/');

  void _openViewer(BuildContext context) {
    if (!enableFullViewer || imageUrl.isEmpty) return;
    final p = context.palette;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: p.goldBorder, width: 1.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  CopticCross(size: 16, color: p.isDark ? p.gold : p.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      saintName ?? 'أيقونة القديس',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.amiri(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: p.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: p.inkMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.58,
                  ),
                  child: _isAsset
                      ? Image.asset(
                          imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => _buildFallback(p, 180),
                        )
                      : Image.network(
                          imageUrl,
                          headers: _imageHeaders,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => _buildFallback(p, 180),
                        ),
                ),
              ),
              if (saintTitle != null && saintTitle!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  saintTitle!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 12.5,
                    color: p.inkSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(AppPalette p, double dim) {
    return Container(
      width: dim,
      height: dim,
      color: p.goldSoft,
      child: Center(
        child: CopticCross(
          size: (dim * 0.38).clamp(16.0, 44.0),
          color: p.gold,
        ),
      ),
    );
  }

  Widget _buildImage(AppPalette p, double width, double height) {
    if (imageUrl.isEmpty) return _buildFallback(p, width);
    if (_isAsset) {
      return Image.asset(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (_, _, _) => _buildFallback(p, width),
      );
    }
    return Image.network(
      imageUrl,
      headers: _imageHeaders,
      width: width,
      height: height,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      cacheWidth: (width * 2.5).round().clamp(120, 440),
      frameBuilder: (ctx, child, frame, wasSync) {
        if (wasSync) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: child,
        );
      },
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return Container(
          width: width,
          height: height,
          color: p.surfaceSubtle,
          child: Center(
            child: CopticCross(
              size: (width * 0.32).clamp(14.0, 28.0),
              color: p.gold.withValues(alpha: 0.45),
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) => _buildFallback(p, width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final width = size;
    final double height;
    final BorderRadius radius;

    switch (shape) {
      case SaintAvatarShape.museumCard:
        height = size * 1.32;
        radius = BorderRadius.circular(18);
      case SaintAvatarShape.arch:
        height = size * 1.24;
        radius = BorderRadius.only(
          topLeft: Radius.circular(size * 0.52),
          topRight: Radius.circular(size * 0.52),
          bottomLeft: const Radius.circular(12),
          bottomRight: const Radius.circular(12),
        );
      case SaintAvatarShape.circle:
        height = size;
        radius = BorderRadius.circular(size);
    }

    final framed = Container(
      width: width,
      height: height,
      padding: shape == SaintAvatarShape.museumCard ? const EdgeInsets.all(5) : EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: shape == SaintAvatarShape.museumCard ? p.surface : p.surfaceSubtle,
        border: showBorder
            ? Border.all(
                color: p.goldBorder,
                width: shape == SaintAvatarShape.museumCard ? 1.4 : (size >= 70 ? 1.2 : 0.9),
              )
            : null,
        boxShadow: shape == SaintAvatarShape.museumCard
            ? [
                BoxShadow(
                  color: p.shadow.withValues(alpha: p.isDark ? 0.5 : 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: shape == SaintAvatarShape.museumCard
            ? BorderRadius.circular(13)
            : radius,
        child: _buildImage(p, width, height),
      ),
    );

    if (!enableFullViewer) return framed;
    return GestureDetector(
      onTap: () => _openViewer(context),
      child: framed,
    );
  }
}
