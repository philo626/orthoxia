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
  StreamSubscription? _videoStateSub;
  StreamSubscription? _valueSub;

  String _currentVideoId = '';
  String _activeCantorName = '';
  double _playbackRate = 1.0;
  bool _isLooping = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _currentVideoId = widget.hymn.resolvedYoutubeId;
    _activeCantorName = widget.hymn.youtubeTitle.isNotEmpty
        ? widget.hymn.youtubeTitle
        : '${widget.hymn.title} • ${widget.hymn.cantor}';
    _initController();
  }

  void _initController() {
    _hasError = false;
    _controller = YoutubePlayerController.fromVideoId(
      videoId: _currentVideoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
        mute: false,
        enableCaption: false,
        origin: 'https://www.youtube-nocookie.com',
        strictRelatedVideos: true,
      ),
    );

    _videoStateSub = _controller.videoStateStream.listen((state) {
      widget.onPositionChanged?.call(state.position);
    });

    _valueSub = _controller.listen((value) {
      if (value.hasError && !_hasError && mounted) {
        setState(() => _hasError = true);
      }
      if (value.playerState == PlayerState.ended && _isLooping) {
        _controller.seekTo(seconds: 0, allowSeekAhead: true);
        _controller.playVideo();
      }
    });
  }

  @override
  void didUpdateWidget(covariant YouTubeHymnPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hymn.id != widget.hymn.id) {
      _loadNewVideo(
        widget.hymn.resolvedYoutubeId,
        widget.hymn.youtubeTitle.isNotEmpty
            ? widget.hymn.youtubeTitle
            : '${widget.hymn.title} • ${widget.hymn.cantor}',
      );
    }
  }

  void _loadNewVideo(String newId, String cantorName) {
    setState(() {
      _currentVideoId = newId;
      _activeCantorName = cantorName;
      _hasError = false;
    });
    _controller.loadVideoById(videoId: newId);
  }

  void _cyclePlaybackSpeed() {
    HapticFeedback.selectionClick();
    final speeds = [0.75, 1.0, 1.25];
    final nextSpeed = speeds[(speeds.indexOf(_playbackRate) + 1) % speeds.length];
    setState(() => _playbackRate = nextSpeed);
    _controller.setPlaybackRate(nextSpeed);
  }

  void _toggleLoop() {
    HapticFeedback.selectionClick();
    setState(() => _isLooping = !_isLooping);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isLooping ? 'تم تفعيل وضع التكرار لحفظ اللحن 🔁' : 'تم إيقاف التكرار',
          style: GoogleFonts.cairo(fontSize: 12),
        ),
        backgroundColor: AppColors.cardNavy,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _videoStateSub?.cancel();
    _valueSub?.cancel();
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
      hymnTitle: widget.hymn.title,
      defaultCantor: widget.hymn.cantor,
      primaryVideoId: widget.hymn.resolvedYoutubeId,
      primaryVideoTitle: widget.hymn.youtubeTitle,
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
              'تسجيلات كنسية موثقة تعمل مباشرة بدون تقطيع',
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: cantors.length,
                separatorBuilder: (_, _) => Divider(
                  color: AppColors.primaryGold.withValues(alpha: 0.15),
                  height: 1,
                ),
                itemBuilder: (ctx, idx) {
                  final c = cantors[idx];
                  final isSelected = c.videoId == _currentVideoId;
                  return Material(
                    type: MaterialType.transparency,
                    child: ListTile(
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
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primaryGoldLight : Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        c.description,
                        style: GoogleFonts.cairo(fontSize: 11, color: Colors.white60),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.primaryGold, size: 20)
                          : const Icon(Icons.play_arrow_rounded, color: Colors.white54),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Navigator.pop(ctx);
                        _loadNewVideo(c.videoId, c.name);
                      },
                    ),
                  );
                },
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.45), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGold.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFF4444).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFFF4444), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'يوتيوب أونلاين',
                        style: GoogleFonts.cairo(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _activeCantorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppColors.primaryGoldLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Deacon speed trainer button
                InkWell(
                  onTap: _cyclePlaybackSpeed,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_playbackRate}x',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGoldLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Video Player Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _hasError
                    ? Container(
                        color: Colors.black,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.wifi_off_rounded, color: AppColors.primaryGold, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              'تعذر تشغيل فيديو يوتيوب حالياً',
                              style: GoogleFonts.cairo(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (widget.onSwitchToAudio != null)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryGold,
                                      foregroundColor: Colors.black,
                                    ),
                                    onPressed: widget.onSwitchToAudio,
                                    icon: const Icon(Icons.headphones_rounded, size: 16),
                                    label: Text('تشغيل الصوت المباشر', style: GoogleFonts.cairo(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: _openExternalYouTube,
                                  child: Text('فتح في يوتيوب', style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.primaryGold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : YoutubePlayer(
                        controller: _controller,
                        aspectRatio: 16 / 9,
                      ),
              ),
            ),
          ),

          // Action Controls Row (Cantors, Loop, Direct Audio, Open in YouTube)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _actionPill(
                  icon: Icons.people_alt_rounded,
                  label: 'تغيير المرتل',
                  onTap: () => _selectCantorSheet(context),
                ),
                _actionPill(
                  icon: Icons.repeat_rounded,
                  label: _isLooping ? 'التكرار: مفعل' : 'تكرار للحفظ',
                  highlighted: _isLooping,
                  onTap: _toggleLoop,
                ),
                if (widget.onSwitchToAudio != null)
                  _actionPill(
                    icon: Icons.headphones_rounded,
                    label: 'صوت بالخلفية (MP3)',
                    onTap: widget.onSwitchToAudio!,
                  ),
                _actionPill(
                  icon: Icons.open_in_new_rounded,
                  label: 'فتح في يوتيوب',
                  onTap: _openExternalYouTube,
                ),
                _actionPill(
                  icon: Icons.search_rounded,
                  label: 'تسجيلات أخرى',
                  onTap: _searchYouTubeMore,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: highlighted ? AppColors.primaryGold : AppColors.cardNavy,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryGold.withValues(alpha: highlighted ? 1.0 : 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: highlighted ? Colors.black : AppColors.primaryGold,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: highlighted ? Colors.black : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
