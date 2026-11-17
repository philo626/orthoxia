import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
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
  bool _showThreeColumnCards = false; // Default: Frame 08-09 Teleprompter mode
  bool _useYouTubeMode = true; // Default: Stream from YouTube online as requested!
  Duration _youtubePosition = Duration.zero;

  late final AnimationController _waveController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _activeHymn = widget.hymn;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_useYouTubeMode) {
        context.read<AudioProvider>().pause();
      } else {
        final audioProv = context.read<AudioProvider>();
        if (audioProv.currentHymn?.id != _activeHymn.id) {
          audioProv.play(_activeHymn);
        }
      }
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
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
    setState(() {
      _activeHymn = list[resolvedIdx];
      _youtubePosition = Duration.zero;
    });
    if (!_useYouTubeMode) {
      context.read<AudioProvider>().play(_activeHymn);
    }
  }

  void _showOptionsAndAnalysisSheet(BuildContext context, AudioProvider audioProv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.72,
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF141417),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.45)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primaryGold.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _activeHymn.title,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryGoldLight,
              ),
            ),
            if (_activeHymn.recordings.length > 1) ...[
              const SizedBox(height: 12),
              Text(
                'اختر المرتل / التسجيل الصوتي:',
                style: GoogleFonts.cairo(fontSize: 12.5, color: AppColors.textMuted),
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
                      color: sel ? Colors.black : AppColors.primaryGold,
                    ),
                    backgroundColor: sel ? AppColors.primaryGold : AppColors.cardNavy,
                    label: Text(
                      rec.cantor,
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: sel ? Colors.black : AppColors.textLight,
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
            const Divider(color: Colors.white12, height: 24),
            Row(
              children: [
                const Icon(Icons.translate_rounded, color: AppColors.primaryGold, size: 18),
                const SizedBox(width: 8),
                Text(
                  'تحليل الكلمات القبطية ومعانيها (${_activeHymn.analysis.length})',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGoldLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _activeHymn.analysis.isEmpty
                  ? Center(
                      child: Text(
                        'الكلمات الثلاثية (قبطي • معرب • عربي) معروضة بالكامل في شاشة اللحن',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(color: AppColors.textMuted, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _activeHymn.analysis.length,
                      separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                      itemBuilder: (context, idx) {
                        final item = _activeHymn.analysis[idx];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  item.coptic,
                                  textDirection: TextDirection.ltr,
                                  style: GoogleFonts.cairo(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGoldLight,
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
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  item.meaning,
                                  textAlign: TextAlign.right,
                                  style: GoogleFonts.cairo(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textLight,
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
    final fontScale = context.watch<ThemeProvider>().fontScale;

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: SafeArea(
        child: Consumer<AudioProvider>(
          builder: (context, audioProv, _) {
            final isLoaded = audioProv.currentHymn?.id == _activeHymn.id;
            final isAudioPlaying = isLoaded && audioProv.isPlaying;

            // Calculate active verse index:
            final pos = _useYouTubeMode
                ? _youtubePosition
                : (isLoaded ? audioProv.position : Duration.zero);

            final dur = _useYouTubeMode
                ? const Duration(minutes: 5)
                : (isLoaded && audioProv.duration > Duration.zero
                    ? audioProv.duration
                    : const Duration(seconds: 90));

            final rem = dur > pos ? dur - pos : Duration.zero;
            final maxSec = dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1.0;
            final curSec = pos.inMilliseconds.toDouble().clamp(0.0, maxSec);

            int activeIdx = 0;
            final posMs = pos.inMilliseconds;
            final verses = _activeHymn.verses;
            if (verses.isNotEmpty) {
              for (int i = 0; i < verses.length; i++) {
                if (verses[i].endMs > 0 && posMs >= verses[i].startMs && posMs < verses[i].endMs) {
                  activeIdx = i;
                  break;
                }
              }
              if (activeIdx == 0 && posMs > 0) {
                final estimatedDurationMs = verses.length * 12000;
                final progress = (posMs / estimatedDurationMs).clamp(0.0, 0.999);
                activeIdx = (progress * verses.length).floor().clamp(0, verses.length - 1);
              }
            }

            return Column(
              children: [
                // 1. Top Header Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      LuxeCircleButton(
                        icon: Icons.search_rounded,
                        onTap: () => Navigator.push(context, luxeRoute(const GlobalSearchView())),
                      ),
                      Text(
                        'الألحان والطقوس',
                        style: GoogleFonts.cairo(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textLight,
                        ),
                      ),
                      LuxeCircleButton(
                        icon: Icons.keyboard_arrow_down_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Mode Switcher Pill (بث يوتيوب أونلاين 🎥 vs المشغل الصوتي 🎵)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141418),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primaryGold.withValues(alpha: 0.35),
                    ),
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
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: _useYouTubeMode
                                  ? Colors.red.withValues(alpha: 0.25)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(13),
                              border: _useYouTubeMode
                                  ? Border.all(color: Colors.redAccent.withValues(alpha: 0.7))
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 15,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'بث يوتيوب مباشر (أونلاين)',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    fontWeight:
                                        _useYouTubeMode ? FontWeight.bold : FontWeight.w600,
                                    color: _useYouTubeMode ? Colors.white : AppColors.textMuted,
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
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: !_useYouTubeMode
                                  ? AppColors.primaryGold.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(13),
                              border: !_useYouTubeMode
                                  ? Border.all(color: AppColors.primaryGold)
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.audiotrack_rounded,
                                  size: 15,
                                  color: !_useYouTubeMode
                                      ? AppColors.primaryGold
                                      : AppColors.textMuted,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'مشغل الصوتيات',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11.5,
                                    fontWeight:
                                        !_useYouTubeMode ? FontWeight.bold : FontWeight.w600,
                                    color: !_useYouTubeMode ? AppColors.primaryGold : AppColors.textMuted,
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

                // 2. YouTube Online Player OR Album Art
                if (_useYouTubeMode)
                  YouTubeHymnPlayer(
                    hymn: _activeHymn,
                    onPositionChanged: (p) => setState(() => _youtubePosition = p),
                    onSwitchToAudio: () {
                      setState(() => _useYouTubeMode = false);
                      audioProv.play(_activeHymn);
                    },
                  )
                else
                  Column(
                    children: [
                      const SizedBox(height: 6),
                      Container(
                        width: 175,
                        height: 175,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          color: const Color(0xFF141416),
                          border: Border.all(
                            color: AppColors.primaryGold.withValues(alpha: 0.35),
                            width: 1.3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.65),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: AppColors.primaryGold.withValues(alpha: 0.14),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(21),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              const SafeAssetImage(
                                'assets/images/hymn_album_art.jpg',
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 10,
                                height: 24,
                                child: AnimatedBuilder(
                                  animation: _waveController,
                                  builder: (_, __) => CustomPaint(
                                    painter: _GoldWaveformPainter(
                                      phase: _waveController.value,
                                      active: isAudioPlaying,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                // 3. Hymn Title Row + Mode Switcher
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left_rounded,
                          color: AppColors.textLight,
                          size: 24,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() => _showThreeColumnCards = !_showThreeColumnCards);
                        },
                        tooltip: 'تبديل طريقة عرض الكلمات',
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
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGoldLight,
                              ),
                            ),
                            Text(
                              isLoaded ? audioProv.activeCantor : _activeHymn.cantor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: AppColors.textLight,
                          size: 22,
                        ),
                        onPressed: () => _showOptionsAndAnalysisSheet(context, audioProv),
                        tooltip: 'المرتلون ومعاني القبطي',
                      ),
                    ],
                  ),
                ),

                // 4. Center Synchronized Lyrics Area
                Expanded(
                  child: _showThreeColumnCards
                      ? _buildThreeColumnList(audioProv, activeIdx, isAudioPlaying || _useYouTubeMode, fontScale)
                      : _buildTeleprompterLyrics(audioProv, activeIdx, fontScale),
                ),

                // 5. Bottom Transport / Status controls when in audio mode
                if (!_useYouTubeMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 2, 24, 12),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3.0,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                            activeTrackColor: AppColors.primaryGold,
                            inactiveTrackColor: Colors.white.withValues(alpha: 0.16),
                            thumbColor: AppColors.primaryGoldLight,
                          ),
                          child: Slider(
                            value: curSec,
                            min: 0.0,
                            max: maxSec,
                            onChanged: (v) {
                              audioProv.seek(Duration(milliseconds: v.round()));
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatClock(rem, negative: true),
                                style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              Text(
                                _formatClock(pos),
                                style: GoogleFonts.roboto(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.shuffle_rounded,
                                  color: _showThreeColumnCards
                                      ? AppColors.primaryGold
                                      : AppColors.textMuted,
                                  size: 20,
                                ),
                                tooltip: 'عرض الثلاثة أعمدة (قبطي ومعرب وعربي)',
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  setState(
                                      () => _showThreeColumnCards = !_showThreeColumnCards);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.skip_previous_rounded,
                                  color: AppColors.textLight,
                                  size: 30,
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
                                  } else if (isLoaded) {
                                    audioProv.resume();
                                  } else {
                                    audioProv.play(_activeHymn);
                                  }
                                },
                                child: Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.06),
                                    border: Border.all(
                                      color: AppColors.textLight.withValues(alpha: 0.85),
                                      width: 1.8,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryGold.withValues(alpha: 0.2),
                                        blurRadius: 16,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isAudioPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: AppColors.textLight,
                                    size: 32,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.skip_next_rounded,
                                  color: AppColors.textLight,
                                  size: 30,
                                ),
                                onPressed: () => _skipHymn(1),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.repeat_rounded,
                                  color: audioProv.isLooping
                                      ? AppColors.primaryGold
                                      : AppColors.textMuted,
                                  size: 20,
                                ),
                                onPressed: audioProv.toggleLoop,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Bottom quick skip bar for YouTube mode
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded, color: AppColors.textLight, size: 28),
                          onPressed: () => _skipHymn(-1),
                          tooltip: 'اللحن السابق',
                        ),
                        const SizedBox(width: 16),
                        ActionChip(
                          avatar: const Icon(Icons.view_column_rounded, size: 16, color: AppColors.primaryGold),
                          backgroundColor: _showThreeColumnCards ? AppColors.primaryGold : AppColors.cardNavy,
                          label: Text(
                            _showThreeColumnCards ? 'عرض التلقين' : 'عرض الثلاث أعمدة',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _showThreeColumnCards ? Colors.black : AppColors.primaryGoldLight,
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() => _showThreeColumnCards = !_showThreeColumnCards);
                          },
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, color: AppColors.textLight, size: 28),
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

  /// Centered Teleprompter Lyrics with vertical fade mask (matches Video Frames 08 & 09)
  Widget _buildTeleprompterLyrics(
    AudioProvider audioProv,
    int activeIdx,
    double fontScale,
  ) {
    final verses = _activeHymn.verses;
    if (verses.isEmpty) {
      return Center(
        child: Text(
          'لا توجد كلمات مضافة لهذا اللحن',
          style: GoogleFonts.cairo(color: AppColors.textMuted),
        ),
      );
    }

    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white,
          Colors.white,
          Colors.white54,
          Colors.transparent,
        ],
        stops: [0.0, 0.58, 0.84, 1.0],
      ).createShader(rect),
      blendMode: BlendMode.modulate,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
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
              if (audioProv.duration.inMilliseconds > 0 && verses.isNotEmpty && !_useYouTubeMode) {
                final targetMs =
                    ((idx / verses.length) * audioProv.duration.inMilliseconds).round();
                audioProv.seek(Duration(milliseconds: targetMs));
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Text(
                    mainText,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: (isCurrent ? 19.5 : 16.5) * fontScale,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      height: 1.5,
                      color: isCurrent
                          ? AppColors.textLight
                          : AppColors.textLight.withValues(alpha: 0.62),
                    ),
                  ),
                  if (subText.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 13 * fontScale,
                        color: isCurrent
                            ? AppColors.primaryGoldLight
                            : AppColors.textMuted.withValues(alpha: 0.55),
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Detailed 3-Column Stanza Cards (Coptic + Arabized + Arabic)
  Widget _buildThreeColumnList(
    AudioProvider audioProv,
    int activeIdx,
    bool isPlaying,
    double fontScale,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      itemCount: _activeHymn.verses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final verse = _activeHymn.verses[index];
        final isActive = isPlaying && activeIdx == index;
        return GestureDetector(
          onTap: () {
            if (audioProv.duration.inMilliseconds > 0 && _activeHymn.verses.isNotEmpty && !_useYouTubeMode) {
              final ms = ((index / _activeHymn.verses.length) *
                      audioProv.duration.inMilliseconds)
                  .round();
              audioProv.seek(Duration(milliseconds: ms));
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primaryGold.withValues(alpha: 0.14)
                  : AppColors.cardNavy,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isActive
                    ? AppColors.primaryGold
                    : Colors.white.withValues(alpha: 0.08),
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
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGoldLight,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                if (verse.arabized.isNotEmpty) ...[
                  Text(
                    verse.arabized,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 13 * fontScale,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textArabized,
                    ),
                  ),
                  const SizedBox(height: 5),
                ],
                if (verse.arabic.isNotEmpty)
                  Text(
                    verse.arabic,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cairo(
                      fontSize: 13.5 * fontScale,
                      color: AppColors.textLight,
                    ),
                  ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 220.ms);
      },
    );
  }
}

class _GoldWaveformPainter extends CustomPainter {
  final double phase;
  final bool active;

  _GoldWaveformPainter({required this.phase, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    const bars = 29;
    final spacing = size.width / bars;
    final paint = Paint()
      ..color = AppColors.primaryGoldLight
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;

    for (int i = 0; i < bars; i++) {
      final centerFactor = 1.0 - ((i - bars / 2).abs() / (bars / 2));
      final wave = active
          ? (0.35 + 0.65 * math.sin((phase * 2 * math.pi) + i * 0.55).abs())
          : 0.25;
      final h = (size.height * 0.85 * centerFactor * wave).clamp(2.5, size.height);
      final x = i * spacing + spacing / 2;
      canvas.drawLine(
        Offset(x, size.height - h),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GoldWaveformPainter old) =>
      old.phase != phase || old.active != active;
}
