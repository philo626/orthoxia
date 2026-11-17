import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/coptic_youtube_registry.dart';
import '../../../models/hymn_model.dart';

class YouTubeHymnPlayer extends StatefulWidget {
  final Hymn hymn;
  final ValueChanged<Duration>? onPositionChanged;
  final VoidCallback? onSwitchToAudio;

  const YouTubeHymnPlayer({
    super.key,
    required this.hymn,
    this.onPositionChanged,
    this.onSwitchToAudio,
  });

  @override
  State<YouTubeHymnPlayer> createState() => _YouTubeHymnPlayerState();
}

class _YouTubeHymnPlayerState extends State<YouTubeHymnPlayer> {
  late YoutubePlayerController _controller;
  StreamSubscription? _videoStateSubscription;
  String _currentVideoId = '';
  String _activeCantorName = '';

  @override
  void initState() {
    super.initState();
    _currentVideoId = widget.hymn.resolvedYoutubeId;
    _activeCantorName = widget.hymn.cantor;
    _initController();
  }

  void _initController() {
    _controller = YoutubePlayerController.fromVideoId(
      videoId: _currentVideoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
        mute: false,
        enableCaption: false,
      ),
    );

    _videoStateSubscription = _controller.videoStateStream.listen((state) {
      widget.onPositionChanged?.call(state.position);
    });
  }

  @override
  void didUpdateWidget(covariant YouTubeHymnPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hymn.id != widget.hymn.id) {
      final newId = widget.hymn.resolvedYoutubeId;
      _currentVideoId = newId;
      _activeCantorName = widget.hymn.cantor;
      _controller.loadVideoById(videoId: newId);
    }
  }

  @override
  void dispose() {
    _videoStateSubscription?.cancel();
    _controller.close();
    super.dispose();
  }

  Future<void> _openExternalYouTube() async {
    final uri = Uri.parse(CopticYouTubeRegistry.buildWatchUrl(_currentVideoId));
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _searchYouTubeMore() async {
    final uri = Uri.parse(widget.hymn.youtubeSearchUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _selectCantorSheet(BuildContext context) {
    final cantors = CopticYouTubeRegistry.getAvailableCantors(
      widget.hymn.title,
      widget.hymn.cantor,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF141417),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.45)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'اختر أداء المرتل عبر يوتيوب',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'تسجيلات عالية الجودة مسجلة طقسياً من قنوات التراث القبطي',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: cantors.length,
                separatorBuilder: (_, __) => Divider(
                  color: AppColors.primaryGold.withValues(alpha: 0.15),
                  height: 1,
                ),
                itemBuilder: (ctx, idx) {
                  final c = cantors[idx];
                  final isSelected = c.videoId == _currentVideoId;
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.primaryGold
                            : AppColors.primaryGold.withValues(alpha: 0.12),
                      ),
                      child: Icon(
                        Icons.music_note,
                        size: 18,
                        color: isSelected ? Colors.black : AppColors.primaryGold,
                      ),
                    ),
                    title: Text(
                      c.name,
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? AppColors.primaryGold : Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      c.description,
                      style: GoogleFonts.cairo(fontSize: 11, color: Colors.white54),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: AppColors.primaryGold, size: 20)
                        : null,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.pop(ctx);
                      setState(() {
                        _currentVideoId = c.videoId;
                        _activeCantorName = c.name;
                      });
                      _controller.loadVideoById(videoId: c.videoId);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _searchYouTubeMore();
              },
              icon: const Icon(Icons.search, color: AppColors.primaryGold, size: 18),
              label: Text(
                'البحث عن تسجيلات إضافية لهذا اللحن في يوتيوب ↗',
                style: GoogleFonts.cairo(fontSize: 13, color: AppColors.primaryGold),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141417),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryGold.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withValues(alpha: 0.12),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // YouTube Player Screen
          AspectRatio(
            aspectRatio: 16 / 9,
            child: YoutubePlayer(
              controller: _controller,
              aspectRatio: 16 / 9,
            ),
          ),

          // Player bar controls & metadata
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1E),
              border: Border(
                top: BorderSide(
                  color: AppColors.primaryGold.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_circle_filled, color: Colors.redAccent, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'بث مباشر يوتيوب أونلاين',
                            style: GoogleFonts.cairo(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _activeCantorName,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: AppColors.primaryGold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Change cantor button
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectCantorSheet(context),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primaryGold.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people_outline, color: AppColors.primaryGold, size: 15),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  'تغيير المرتل',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    color: AppColors.primaryGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Open in YouTube app button
                    InkWell(
                      onTap: _openExternalYouTube,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.redAccent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.open_in_new, color: Colors.redAccent, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'يوتيوب',
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (widget.onSwitchToAudio != null) ...[
                      const SizedBox(width: 8),
                      // Switch to audio player button
                      InkWell(
                        onTap: widget.onSwitchToAudio,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.audiotrack, color: Colors.white70, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'صوتي فقط',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
