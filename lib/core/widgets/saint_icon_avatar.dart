import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import 'coptic_cross.dart';

enum SaintAvatarShape { circle, arch }

/// Renders an authentic Coptic/Orthodox saint icon portrait inside a restrained
/// antique-gold liturgical frame (circular medallion or cathedral arch).
/// Never falls back to emojis; gracefully falls back to a dignified sacred emblem offline.
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

  void _openViewer(BuildContext context) {
    if (!enableFullViewer || imageUrl.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardNavy,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.primaryGold.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const CopticCross(size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      saintName ?? 'أيقونة القديس',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.amiri(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGoldLight,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.56,
                  ),
                  child: Image.network(
                    imageUrl,
                    headers: _imageHeaders,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _buildFallback(180),
                  ),
                ),
              ),
              if (saintTitle != null && saintTitle!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  saintTitle!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    color: AppColors.textMuted,
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

  Widget _buildFallback(double dim) {
    return Container(
      width: dim,
      height: dim,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF28221A), Color(0xFF15120F)],
        ),
      ),
      child: Center(
        child: CopticCross(
          size: (dim * 0.42).clamp(16.0, 48.0),
          color: AppColors.primaryGold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = size;
    final height = shape == SaintAvatarShape.arch ? size * 1.24 : size;
    final radius = shape == SaintAvatarShape.arch
        ? BorderRadius.only(
            topLeft: Radius.circular(size * 0.52),
            topRight: Radius.circular(size * 0.52),
            bottomLeft: const Radius.circular(12),
            bottomRight: const Radius.circular(12),
          )
        : BorderRadius.circular(size);

    final imageWidget = imageUrl.isEmpty
        ? _buildFallback(width)
        : Image.network(
            imageUrl,
            headers: _imageHeaders,
            width: width,
            height: height,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            cacheWidth: (width * 2.5).round().clamp(120, 420),
            frameBuilder: (ctx, child, frame, wasSync) {
              if (wasSync) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                child: child,
              );
            },
            loadingBuilder: (ctx, child, progress) {
              if (progress == null) return child;
              return Container(
                width: width,
                height: height,
                color: const Color(0xFF1F1C18),
                child: Center(
                  child: CopticCross(
                    size: (width * 0.34).clamp(14.0, 28.0),
                    color: AppColors.primaryGold.withValues(alpha: 0.45),
                  ),
                ),
              );
            },
            errorBuilder: (_, __, ___) => _buildFallback(width),
          );

    final framed = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: const Color(0xFF1C1915),
        border: showBorder
            ? Border.all(
                color: AppColors.primaryGold.withValues(alpha: 0.42),
                width: size >= 70 ? 1.4 : 1.0,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: imageWidget,
      ),
    );

    if (!enableFullViewer) return framed;
    return GestureDetector(
      onTap: () => _openViewer(context),
      child: framed,
    );
  }
}
