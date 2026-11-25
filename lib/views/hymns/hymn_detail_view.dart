import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/security_guard_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../models/hymn_model.dart';
import '../../providers/audio_provider.dart';
import '../../providers/theme_provider.dart';
import '../search/global_search_view.dart';
import 'widgets/youtube_hymn_player.dart';

class HymnDetailView extends StatefulWidget {
  final Hymn hymn;
  final List<Hymn>? playlist;

  const HymnDetailView({super.key, required this.hymn, this.playlist});

  @override
  State<HymnDetailView> createState() => _HymnDetailViewState();
}

class _HymnDetailViewState extends State<HymnDetailView>
    with SingleTickerProviderStateMixin {
  late Hymn _activeHymn;
  bool _showThreeColumnCards = true; // Clean 3-script Cantor Study View by default
  bool _useYouTubeMode = true;
  Duration _youtubePosition = Duration.zero;
  final ScrollController _lyricsScrollCtrl = ScrollController();
  int _lastScrolledIdx = -1;

  late final AnimationController _waveController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _activeHymn = widget.hymn;
    // Prefer direct MP3 audio when available so Media Notification + Dynamic Island + synced lyrics work seamlessly!
    _useYouTubeMode = _activeHymn.audioUrl.isEmpty && _activeHymn.exactYoutube;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final audioProv = context.read<AudioProvider>();
      if (widget.playlist != null && widget.playlist!.isNotEmpty) {
        audioProv.setPlaylist(widget.playlist!);
      }
      audioProv.clearError();
      if (_useYouTubeMode) {
        audioProv.pause();
      } else {
        if (audioProv.currentHymn?.id != _activeHymn.id || !audioProv.isPlaying) {
          audioProv.play(_activeHymn, playlist: widget.playlist);
        }
      }
    });
  }

  @override
  void dispose() {
    _lyricsScrollCtrl.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _maybeAutoScrollToActiveVerse(int activeIdx, int totalVerses) {
    if (activeIdx == _lastScrolledIdx || totalVerses <= 1) return;
    _lastScrolledIdx = activeIdx;
    if (!_lyricsScrollCtrl.hasClients) return;
    final maxExtent = _lyricsScrollCtrl.position.maxScrollExtent;
    if (maxExtent <= 0) return;
    final target = ((activeIdx / (totalVerses - 1).clamp(1, 999)) * maxExtent)
        .clamp(0.0, maxExtent);
    _lyricsScrollCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  String _formatClock(Duration d, {bool negative = false}) {
    final totalSec = d.inSeconds.abs();
    final m = (totalSec ~/ 60).toString();
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '${negative ? "-" : ""}$m:$s';
  }

  void _skipHymn(int delta) {
    final list = widget.playlist;
    if (list == null || list.isEmpty) return;
    final idx = list.indexWhere((h) => h.id == _activeHymn.id);
    final nextIdx = idx == -1 ? 0 : (idx + delta) % list.length;
    final resolvedIdx = nextIdx < 0 ? list.length - 1 : nextIdx;
    HapticFeedback.selectionClick();
    final audioProv = context.read<AudioProvider>();
    audioProv.clearError();
    setState(() {
      _activeHymn = list[resolvedIdx];
      _youtubePosition = Duration.zero;
      _useYouTubeMode = _activeHymn.exactYoutube;
    });
    if (_useYouTubeMode) {
      audioProv.pause();
    } else {
      audioProv.play(_activeHymn);
    }
  }

  void _cycleAudioSpeed(AudioProvider audioProv) {
    HapticFeedback.selectionClick();
    const speeds = [0.75, 1.0, 1.25];
    final idx = speeds.indexOf(audioProv.playbackSpeed);
    final next = speeds[(idx + 1) % speeds.length];
    audioProv.setSpeed(next);
  }

  Future<void> _openYoutubeSearch() async {
    final url = SecurityGuardService.upgradeToHttps(_activeHymn.youtubeSearchUrl);
    if (!SecurityGuardService.isSafeExternalUrl(url)) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showOptionsAndAnalysisSheet(
      BuildContext context, AudioProvider audioProv) {
    final p = context.palette;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.72,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: p.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: p.borderStrong,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _activeHymn.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.amiri(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: p.ink,
              ),
            ),
            if (_activeHymn.recordings.length > 1) ...[
              const SizedBox(height: 12),
              Text(
                'اختر المرتل / التسجيل الصوتي:',
                style: GoogleFonts.cairo(fontSize: 12.5, color: p.inkMuted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _activeHymn.recordings.map((rec) {
                  final sel = audioProv.activeAudioUrl == rec.url;
                  return ActionChip(
                    avatar: Icon(
                      sel ? Icons.volume_up_rounded : Icons.mic_rounded,
                      size: 15,
                      color: sel ? p.onAccent : p.accent,
                    ),
                    backgroundColor: sel ? p.accent : p.surfaceElevated,
                    side: BorderSide(color: sel ? p.accent : p.border),
                    label: Text(
                      rec.cantor,
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: sel ? p.onAccent : p.ink,
                      ),
                    ),
                    onPressed: () {
                      setState(() => _useYouTubeMode = false);
                      audioProv.play(
                        _activeHymn,
                        customAudioUrl: rec.url,
                        customCantor: rec.cantor,
                      );
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ],
            Divider(color: p.border, height: 24),
            Row(
              children: [
                Icon(Icons.translate_rounded, color: p.accent, size: 18),
                const SizedBox(width: 8),
                Text(
                  'تحليل الكلمات القبطية ومعانيها (${_activeHymn.analysis.length})',
                  style: GoogleFonts.cairo(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _activeHymn.analysis.isEmpty
                  ? Center(
                      child: Text(
                        'الكلمات معروضة بالكامل في شاشة اللحن الرئيسية (قبطي • معرب • عربي).',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                            color: p.inkMuted, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _activeHymn.analysis.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: p.border, height: 1),
                      itemBuilder: (context, idx) {
                        final item = _activeHymn.analysis[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 6),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  item.coptic,
                                  textDirection: TextDirection.ltr,
                                  style: GoogleFonts.cairo(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: p.accent,
                                  ),
                                ),
                              ),
                              if (item.origin.isNotEmpty)
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    item.origin,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.cairo(
                                      fontSize: 11.5,
                                      color: p.inkMuted,
                                    ),
                                  ),
                                ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  item.meaning,
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: p.ink,
                                  ),
                                ),
                              ),
                            ],
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
    final p = context.palette;
    final fontScale = context.watch<ThemeProvider>().fontScale;

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: Consumer<AudioProvider>(
          builder: (context, audioProv, _) {
            final isLoaded = audioProv.currentHymn?.id == _activeHymn.id;
            final isAudioPlaying = isLoaded && audioProv.isPlaying;
            final isAudioLoading = isLoaded && audioProv.isLoading;
            final audioError = isLoaded ? audioProv.playbackError : null;

            final pos = _useYouTubeMode
                ? _youtubePosition
                : (isLoaded ? audioProv.position : Duration.zero);

            final dur = _useYouTubeMode
                ? const Duration(minutes: 5)
                : (isLoaded && audioProv.duration > Duration.zero
                    ? audioProv.duration
                    : Duration.zero);

            final rem = dur > pos ? dur - pos : Duration.zero;
            final maxSec =
                dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1.0;
            final curSec = pos.inMilliseconds.toDouble().clamp(0.0, maxSec);

            int activeIdx = 0;
            final posMs = pos.inMilliseconds;
            final verses = _activeHymn.verses;
            if (verses.isNotEmpty) {
              for (int i = 0; i < verses.length; i++) {
                if (verses[i].endMs > 0 &&
                    posMs >= verses[i].startMs &&
                    posMs < verses[i].endMs) {
                  activeIdx = i;
                  break;
                }
              }
              if (activeIdx == 0 && posMs > 0 && dur.inMilliseconds > 0) {
                final progress =
                    (posMs / dur.inMilliseconds).clamp(0.0, 0.999);
                activeIdx = (progress * verses.length)
                    .floor()
                    .clamp(0, verses.length - 1);
              }
            }

            return Column(
              children: [
                // 1. Top Header Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      LuxeCircleButton(
                        icon: Icons.keyboard_arrow_down_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              _activeHymn.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: p.ink,
                              ),
                            ),
                            Text(
                              isLoaded
                                  ? audioProv.activeCantor
                                  : _activeHymn.cantor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: p.inkMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          LuxeCircleButton(
                            icon: Icons.translate_rounded,
                            onTap: () =>
                                _showOptionsAndAnalysisSheet(context, audioProv),
                          ),
                          const SizedBox(width: 6),
                          LuxeCircleButton(
                            icon: Icons.search_rounded,
                            onTap: () => Navigator.push(
                                context, luxeRoute(const GlobalSearchView())),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 2. Mode Switcher Pill (فيديو يوتيوب vs مشغل الصوت المباشر)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: p.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _useYouTubeMode = true);
                            audioProv.pause();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: _useYouTubeMode
                                  ? p.surfaceElevated
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(11),
                              border: _useYouTubeMode
                                  ? Border.all(
                                      color: p.crimson.withValues(alpha: 0.45))
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.play_circle_filled_rounded,
                                  size: 15,
                                  color: _useYouTubeMode
                                      ? p.crimson
                                      : p.inkMuted,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _activeHymn.exactYoutube
                                      ? 'فيديو يوتيوب موثّق'
                                      : 'بحث يوتيوب',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    fontWeight: _useYouTubeMode
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color:
                                        _useYouTubeMode ? p.ink : p.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _useYouTubeMode = false);
                            audioProv.play(_activeHymn);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                              color: !_useYouTubeMode
                                  ? p.surfaceElevated
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(11),
                              border: !_useYouTubeMode
                                  ? Border.all(
                                      color: p.accent.withValues(alpha: 0.55))
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.audiotrack_rounded,
                                  size: 15,
                                  color: !_useYouTubeMode
                                      ? p.accent
                                      : p.inkMuted,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'الصوت المباشر (MP3)',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    fontWeight: !_useYouTubeMode
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color:
                                        !_useYouTubeMode ? p.ink : p.inkMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. YouTube Online Player OR Audio Studio Card
                if (_useYouTubeMode)
                  YouTubeHymnPlayer(
                    hymn: _activeHymn,
                    onPositionChanged: (posYt) =>
                        setState(() => _youtubePosition = posYt),
                    onSwitchToAudio: () {
                      setState(() => _useYouTubeMode = false);
                      audioProv.play(_activeHymn);
                    },
                  )
                else
                  _buildAudioStudioCard(
                    p: p,
                    audioProv: audioProv,
                    isAudioPlaying: isAudioPlaying,
                    isAudioLoading: isAudioLoading,
                    audioError: audioError,
                  ),

                // 4a. LIVE «اللي بيتقال دلوقتي» (Now Chanting Spotlight Card)
                if (verses.isNotEmpty) ...[
                  Builder(
                    builder: (_) {
                      final safeIdx = activeIdx.clamp(0, verses.length - 1);
                      final cur = verses[safeIdx];
                      if (isAudioPlaying || _useYouTubeMode) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) _maybeAutoScrollToActiveVerse(safeIdx, verses.length);
                        });
                      }
                      return Container(
                        margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        decoration: BoxDecoration(
                          color: p.goldSoft,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: p.gold, width: 1.4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isAudioPlaying
                                      ? Icons.graphic_eq_rounded
                                      : Icons.subtitles_outlined,
                                  size: 16,
                                  color: p.accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'اللي بيتقال دلوقتي • فقرة ${safeIdx + 1} من ${verses.length}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: p.accent,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'اضغط أي فقرة تحت للانتقال',
                                  style: GoogleFonts.cairo(fontSize: 10, color: p.inkMuted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (cur.arabized.isNotEmpty)
                              Text(
                                cur.arabized,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 13 * fontScale,
                                  fontWeight: FontWeight.bold,
                                  color: p.crimson,
                                  height: 1.4,
                                ),
                              ),
                            if (cur.arabic.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                cur.arabic,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.amiri(
                                  fontSize: 17 * fontScale,
                                  fontWeight: FontWeight.bold,
                                  color: p.ink,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ],

                // 4. Lyrics View Mode Toggle Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
                  child: Row(
                    children: [
                      Text(
                        'كلمات اللحن (${verses.length} فقرة)',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: p.inkMuted,
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() =>
                              _showThreeColumnCards = !_showThreeColumnCards);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: p.accentSoft,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: p.accent.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _showThreeColumnCards
                                    ? Icons.view_headline_rounded
                                    : Icons.view_agenda_rounded,
                                size: 14,
                                color: p.accent,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _showThreeColumnCards
                                    ? 'وضع التلقين المركز'
                                    : 'البطاقات الثلاثية',
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: p.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 5. Center Synchronized Lyrics Area
                Expanded(
                  child: _showThreeColumnCards
                      ? _buildThreeColumnList(
                          p,
                          audioProv,
                          activeIdx,
                          isAudioPlaying || _useYouTubeMode,
                          fontScale,
                        )
                      : _buildTeleprompterLyrics(
                          p, audioProv, activeIdx, fontScale),
                ),

                // 6. Bottom Cantor Transport Controls
                if (!_useYouTubeMode)
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                    decoration: BoxDecoration(
                      color: p.surfaceElevated,
                      border: Border(top: BorderSide(color: p.border)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3.0,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 13),
                            activeTrackColor: p.accent,
                            inactiveTrackColor: p.border,
                            thumbColor: p.accent,
                          ),
                          child: Slider(
                            value: curSec,
                            min: 0.0,
                            max: maxSec,
                            onChanged: dur > Duration.zero
                                ? (v) => audioProv
                                    .seek(Duration(milliseconds: v.round()))
                                : null,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                dur > Duration.zero
                                    ? _formatClock(rem, negative: true)
                                    : '--:--',
                                style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  color: p.inkMuted,
                                ),
                              ),
                              Text(
                                _formatClock(pos),
                                style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  color: p.inkMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Cantor Speed Trainer button (0.75x / 1.0x / 1.25x)
                              InkWell(
                                onTap: () => _cycleAudioSpeed(audioProv),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: p.accentSoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${audioProv.playbackSpeed}x',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: p.accent,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.skip_previous_rounded,
                                  color: p.ink,
                                  size: 28,
                                ),
                                onPressed: () {
                                  if (pos.inSeconds > 4) {
                                    audioProv.seek(Duration.zero);
                                  } else {
                                    _skipHymn(-1);
                                  }
                                },
                              ),
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.mediumImpact();
                                  if (isAudioPlaying) {
                                    audioProv.pause();
                                  } else if (isLoaded &&
                                      audioProv.activeAudioUrl.isNotEmpty) {
                                    audioProv.resume();
                                  } else {
                                    audioProv.play(_activeHymn);
                                  }
                                },
                                child: Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: p.accent,
                                  ),
                                  child: isAudioLoading
                                      ? Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: p.onAccent,
                                          ),
                                        )
                                      : Icon(
                                          isAudioPlaying
                                              ? Icons.pause_rounded
                                              : Icons.play_arrow_rounded,
                                          color: p.onAccent,
                                          size: 30,
                                        ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.skip_next_rounded,
                                  color: p.ink,
                                  size: 28,
                                ),
                                onPressed: () => _skipHymn(1),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.repeat_rounded,
                                  color: audioProv.isLooping
                                      ? p.accent
                                      : p.inkMuted,
                                  size: 21,
                                ),
                                tooltip: 'تكرار للحفظ',
                                onPressed: audioProv.toggleLoop,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    decoration: BoxDecoration(
                      color: p.surfaceElevated,
                      border: Border(top: BorderSide(color: p.border)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.skip_previous_rounded,
                              color: p.ink, size: 26),
                          onPressed: () => _skipHymn(-1),
                          tooltip: 'اللحن السابق',
                        ),
                        const SizedBox(width: 14),
                        Text(
                          _activeHymn.categoryName,
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.inkMuted,
                          ),
                        ),
                        const SizedBox(width: 14),
                        IconButton(
                          icon: Icon(Icons.skip_next_rounded,
                              color: p.ink, size: 26),
                          onPressed: () => _skipHymn(1),
                          tooltip: 'اللحن التالي',
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAudioStudioCard({
    required AppPalette p,
    required AudioProvider audioProv,
    required bool isAudioPlaying,
    required bool isAudioLoading,
    required String? audioError,
  }) {
    if (audioError != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.crimson.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.cloud_off_rounded, color: p.crimson, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    audioError,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: p.ink,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_activeHymn.exactYoutube)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.crimson,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    onPressed: () => setState(() => _useYouTubeMode = true),
                    icon: const Icon(Icons.play_circle_filled_rounded, size: 16),
                    label: Text(
                      'تشغيل فيديو يوتيوب الموثّق',
                      style: GoogleFonts.cairo(
                          fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p.ink,
                    side: BorderSide(color: p.borderStrong),
                  ),
                  onPressed: _openYoutubeSearch,
                  icon: const Icon(Icons.search_rounded, size: 15),
                  label: Text(
                    'بحث على يوتيوب',
                    style: GoogleFonts.cairo(fontSize: 11.5),
                  ),
                ),
                TextButton(
                  onPressed: () => audioProv.play(_activeHymn),
                  child: Text(
                    'إعادة المحاولة',
                    style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        color: p.accent,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: const SizedBox(
              width: 68,
              height: 68,
              child: SafeAssetImage(
                'assets/images/hymn_album_art.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAudioLoading
                      ? 'جارٍ تحميل التسجيل الصوتي...'
                      : (isAudioPlaying
                          ? 'استوديو المرتل — قيد التشغيل'
                          : 'استوديو المرتل — جاهز للتشغيل'),
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: p.accent,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 22,
                  child: AnimatedBuilder(
                    animation: _waveController,
                    builder: (_, __) => CustomPaint(
                      size: const Size(double.infinity, 22),
                      painter: _WaveformPainter(
                        phase: _waveController.value,
                        active: isAudioPlaying,
                        color: p.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Centered Teleprompter Lyrics
  Widget _buildTeleprompterLyrics(
    AppPalette p,
    AudioProvider audioProv,
    int activeIdx,
    double fontScale,
  ) {
    final verses = _activeHymn.verses;
    if (verses.isEmpty) {
      return Center(
        child: Text(
          'لا توجد كلمات مضافة لهذا اللحن',
          style: GoogleFonts.cairo(color: p.inkMuted),
        ),
      );
    }

    return ListView.builder(
      controller: _lyricsScrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      itemCount: verses.length,
      itemBuilder: (context, idx) {
        final v = verses[idx];
        final isCurrent = idx == activeIdx;
        final mainText = v.arabic.isNotEmpty
            ? v.arabic
            : (v.arabized.isNotEmpty ? v.arabized : v.coptic);
        final subText = v.arabized.isNotEmpty && v.arabized != mainText
            ? v.arabized
            : v.coptic;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            if (audioProv.duration.inMilliseconds > 0 &&
                verses.isNotEmpty &&
                !_useYouTubeMode) {
              final targetMs =
                  ((idx / verses.length) * audioProv.duration.inMilliseconds)
                      .round();
              audioProv.seek(Duration(milliseconds: targetMs));
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isCurrent ? p.accentSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Text(
                  mainText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    fontSize: (isCurrent ? 22 : 19) * fontScale,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    height: 1.55,
                    color: isCurrent ? p.ink : p.inkMuted,
                  ),
                ),
                if (subText.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 13 * fontScale,
                      color: isCurrent ? p.accent : p.inkSubtle,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Detailed 3-Script Stanza Cards (Coptic + Arabized + Arabic)
  Widget _buildThreeColumnList(
    AppPalette p,
    AudioProvider audioProv,
    int activeIdx,
    bool isPlaying,
    double fontScale,
  ) {
    return ListView.separated(
      controller: _lyricsScrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: _activeHymn.verses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final verse = _activeHymn.verses[index];
        final isActive = isPlaying && activeIdx == index;
        return GestureDetector(
          onTap: () {
            if (audioProv.duration.inMilliseconds > 0 &&
                _activeHymn.verses.isNotEmpty &&
                !_useYouTubeMode) {
              final ms = ((index / _activeHymn.verses.length) *
                      audioProv.duration.inMilliseconds)
                  .round();
              audioProv.seek(Duration(milliseconds: ms));
            }
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isActive ? p.accentSoft : p.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive ? p.accent : p.border,
                width: isActive ? 1.3 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (verse.coptic.isNotEmpty) ...[
                  Text(
                    verse.coptic,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: GoogleFonts.cairo(
                      fontSize: 14.5 * fontScale,
                      fontWeight: FontWeight.w700,
                      color: p.accent,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                if (verse.arabized.isNotEmpty) ...[
                  Text(
                    verse.arabized,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 13.5 * fontScale,
                      fontWeight: FontWeight.w600,
                      color: p.crimson,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                if (verse.arabic.isNotEmpty)
                  Text(
                    verse.arabic,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(
                      fontSize: 17.5 * fontScale,
                      fontWeight: FontWeight.w600,
                      color: p.ink,
                      height: 1.55,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double phase;
  final bool active;
  final Color color;

  _WaveformPainter({
    required this.phase,
    required this.active,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const bars = 26;
    final spacing = size.width / bars;
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;

    for (int i = 0; i < bars; i++) {
      final centerFactor = 1.0 - ((i - bars / 2).abs() / (bars / 2));
      final wave = active
          ? (0.3 + 0.7 * math.sin((phase * 2 * math.pi) + i * 0.55).abs())
          : 0.22;
      final h =
          (size.height * 0.85 * centerFactor * wave).clamp(2.5, size.height);
      final x = i * spacing + spacing / 2;
      canvas.drawLine(
        Offset(x, size.height - h),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter old) =>
      old.phase != phase || old.active != active || old.color != color;
}
