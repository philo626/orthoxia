import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/services/coptic_youtube_registry.dart';
import '../../../core/services/security_guard_service.dart';
import '../../../core/theme/app_palette.dart';
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
  YoutubePlayerController? _controller;
  StreamSubscription? _videoStateSub;
  StreamSubscription? _valueSub;

  String _currentVideoId = '';
  String _activeCantorName = '';
  double _playbackRate = 1.0;
  bool _isLooping = false;
  bool _hasError = false;

  bool get _hasExactVideo => widget.hymn.exactYoutube;

  @override
  void initState() {
    super.initState();
    _syncFromHymn(initial: true);
  }

  void _syncFromHymn({bool initial = false}) {
    _currentVideoId = widget.hymn.resolvedYoutubeId;
    _activeCantorName = widget.hymn.youtubeTitle.isNotEmpty
        ? widget.hymn.youtubeTitle
        : '${widget.hymn.title} — ${widget.hymn.cantor}';
    _hasError = false;

    if (!_hasExactVideo) {
      _disposeController();
      return;
    }

    if (initial || _controller == null) {
      _initController();
    } else {
      _controller!.loadVideoById(videoId: _currentVideoId);
    }
  }

  void _initController() {
    _disposeController();
    _hasError = false;
    final ctrl = YoutubePlayerController.fromVideoId(
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
    _controller = ctrl;

    _videoStateSub = ctrl.videoStateStream.listen((state) {
      widget.onPositionChanged?.call(state.position);
    });

    _valueSub = ctrl.listen((value) {
      if (value.hasError && !_hasError && mounted) {
        setState(() => _hasError = true);
      }
      if (value.playerState == PlayerState.ended && _isLooping) {
        ctrl.seekTo(seconds: 0, allowSeekAhead: true);
        ctrl.playVideo();
      }
    });
  }

  void _disposeController() {
    _videoStateSub?.cancel();
    _videoStateSub = null;
    _valueSub?.cancel();
    _valueSub = null;
    _controller?.close();
    _controller = null;
  }

  @override
  void didUpdateWidget(covariant YouTubeHymnPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hymn.id != widget.hymn.id) {
      setState(() {
        _syncFromHymn();
      });
    }
  }

  void _cyclePlaybackSpeed() {
    HapticFeedback.selectionClick();
    final speeds = [0.75, 1.0, 1.25];
    final nextSpeed =
        speeds[(speeds.indexOf(_playbackRate) + 1) % speeds.length];
    setState(() => _playbackRate = nextSpeed);
    _controller?.setPlaybackRate(nextSpeed);
  }

  void _toggleLoop() {
    HapticFeedback.selectionClick();
    setState(() => _isLooping = !_isLooping);
    final p = context.palette;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isLooping ? 'تم تفعيل التكرار لحفظ اللحن' : 'تم إيقاف التكرار',
          style: GoogleFonts.cairo(fontSize: 12.5, color: p.onAccent),
        ),
        backgroundColor: p.accent,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  Future<void> _openExternalYouTube() async {
    final url = SecurityGuardService.upgradeToHttps(
      _hasExactVideo
          ? CopticYouTubeRegistry.buildWatchUrl(_currentVideoId)
          : widget.hymn.youtubeSearchUrl,
    );
    if (!SecurityGuardService.isSafeExternalUrl(url)) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _searchYouTubeMore() async {
    final url =
        SecurityGuardService.upgradeToHttps(widget.hymn.youtubeSearchUrl);
    if (!SecurityGuardService.isSafeExternalUrl(url)) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    // Honest card when this specific hymn has no exact verified YouTube video ID
    // (never plays an unrelated hymn under the wrong title!)
    if (!_hasExactVideo) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: p.accentSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.music_note_rounded, color: p.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'نص اللحن الكامل متاح للقراءة والحفظ',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: p.ink,
                        ),
                      ),
                      Text(
                        'لا يوجد فيديو يوتيوب مطابق مدمج لهذا اللحن بعد — يمكنك البحث عنه مباشرة على يوتيوب أو تجربة الصوت المباشر.',
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          height: 1.45,
                          color: p.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _actionPill(
                  p: p,
                  icon: Icons.search_rounded,
                  label: 'ابحث عن اللحن على يوتيوب',
                  highlighted: true,
                  onTap: _searchYouTubeMore,
                ),
                if (widget.onSwitchToAudio != null)
                  _actionPill(
                    p: p,
                    icon: Icons.headphones_rounded,
                    label: 'تجربة الصوت المباشر',
                    onTap: widget.onSwitchToAudio!,
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Badge + Cantor Speed Trainer
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.crimsonSoft,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: p.crimson.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_filled_rounded,
                          color: p.crimson, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'تسجيل موثّق',
                        style: GoogleFonts.cairo(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: p.crimson,
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
                      color: p.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: _cyclePlaybackSpeed,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: p.accentSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: p.accent.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${_playbackRate}x',
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: p.accent,
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
              borderRadius: BorderRadius.circular(13),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _hasError || _controller == null
                    ? Container(
                        color: p.surfaceMuted,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.wifi_off_rounded,
                                color: p.accent, size: 32),
                            const SizedBox(height: 8),
                            Text(
                              'تعذر تشغيل الفيديو داخل التطبيق حالياً',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                color: p.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: p.accent,
                                    foregroundColor: p.onAccent,
                                  ),
                                  onPressed: _openExternalYouTube,
                                  icon: const Icon(Icons.open_in_new_rounded,
                                      size: 15),
                                  label: Text(
                                    'فتح في يوتيوب',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                if (widget.onSwitchToAudio != null)
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: p.ink,
                                      side: BorderSide(color: p.borderStrong),
                                    ),
                                    onPressed: widget.onSwitchToAudio,
                                    icon: const Icon(Icons.headphones_rounded,
                                        size: 15),
                                    label: Text(
                                      'الصوت المباشر',
                                      style: GoogleFonts.cairo(fontSize: 11.5),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : YoutubePlayer(
                        controller: _controller!,
                        aspectRatio: 16 / 9,
                      ),
              ),
            ),
          ),

          // Action Controls Row
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _actionPill(
                  p: p,
                  icon: Icons.repeat_rounded,
                  label: _isLooping ? 'التكرار: مفعل' : 'تكرار للحفظ',
                  highlighted: _isLooping,
                  onTap: _toggleLoop,
                ),
                if (widget.onSwitchToAudio != null)
                  _actionPill(
                    p: p,
                    icon: Icons.headphones_rounded,
                    label: 'صوت بالخلفية',
                    onTap: widget.onSwitchToAudio!,
                  ),
                _actionPill(
                  p: p,
                  icon: Icons.open_in_new_rounded,
                  label: 'فتح في يوتيوب',
                  onTap: _openExternalYouTube,
                ),
                _actionPill(
                  p: p,
                  icon: Icons.search_rounded,
                  label: 'مرتلون آخرون',
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
    required AppPalette p,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: highlighted ? p.accent : p.surfaceMuted,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: highlighted ? p.accent : p.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: highlighted ? p.onAccent : p.accent,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: highlighted ? p.onAccent : p.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
