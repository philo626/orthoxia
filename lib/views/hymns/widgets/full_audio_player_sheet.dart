import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/hymn_model.dart';
import '../../../providers/audio_provider.dart';

class FullAudioPlayerSheet extends StatelessWidget {
  final Hymn hymn;

  const FullAudioPlayerSheet({super.key, required this.hymn});

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioProvider>(
      builder: (context, audioProv, _) {
        final activeHymn = audioProv.currentHymn ?? hymn;
        final currentPos = audioProv.position;
        final totalDur = audioProv.duration;
        final maxSeconds = totalDur.inSeconds > 0 ? totalDur.inSeconds.toDouble() : 1.0;
        final currentSeconds = currentPos.inSeconds.toDouble().clamp(0.0, maxSeconds);
        final verses = activeHymn.verses;
        final activeIdx = audioProv.activeVerseIndex.clamp(
          0,
          (verses.length - 1).clamp(0, 999),
        );
        final curVerse = verses.isNotEmpty ? verses[activeIdx] : null;

        return Container(
          height: MediaQuery.of(context).size.height * 0.80,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: const BoxDecoration(
            color: AppColors.deepNavy,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Drag Handle + Close & Stop Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'تصغير',
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      audioProv.stop();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.stop_circle_outlined,
                        size: 18, color: Colors.redAccent),
                    label: Text(
                      'إيقاف',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Hymn Title & Cantor
              Text(
                activeHymn.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.amiri(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                audioProv.activeCantor.isNotEmpty
                    ? audioProv.activeCantor
                    : activeHymn.cantor,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),

              const SizedBox(height: 14),

              // LIVE SYNCED LYRICS SPOTLIGHT («اللي بيتقال دلوقتي»)
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardNavy,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.primaryGold.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                  ),
                  child: curVerse == null
                      ? Center(
                          child: Icon(
                            Icons.music_note_rounded,
                            size: 64,
                            color: AppColors.primaryGold.withValues(alpha: 0.6),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGold.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  'اللي بيتقال دلوقتي • فقرة ${activeIdx + 1} من ${verses.length}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (curVerse.coptic.isNotEmpty) ...[
                                Text(
                                  curVerse.coptic,
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.ltr,
                                  style: GoogleFonts.cairo(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryGold,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                              if (curVerse.arabized.isNotEmpty) ...[
                                Text(
                                  curVerse.arabized,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.cairo(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFF3B4A7),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                              if (curVerse.arabic.isNotEmpty)
                                Text(
                                  curVerse.arabic,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.amiri(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textLight,
                                    height: 1.6,
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Slider
              Slider(
                value: currentSeconds,
                min: 0.0,
                max: maxSeconds,
                activeColor: AppColors.primaryGold,
                inactiveColor: Colors.white.withValues(alpha: 0.15),
                onChanged: (val) {
                  audioProv.seek(Duration(seconds: val.toInt()));
                },
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(currentPos),
                        style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.textMuted)),
                    Text(_formatDuration(totalDur),
                        style: GoogleFonts.cairo(fontSize: 11.5, color: AppColors.textMuted)),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Media Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.repeat_rounded,
                      color: audioProv.isLooping
                          ? AppColors.primaryGold
                          : AppColors.textMuted,
                      size: 23,
                    ),
                    onPressed: () => audioProv.toggleLoop(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded,
                        color: AppColors.textLight, size: 30),
                    onPressed: () => audioProv.skipPrevious(),
                  ),
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryGold,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGold.withValues(alpha: 0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        audioProv.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 34,
                      ),
                      onPressed: () {
                        if (audioProv.isPlaying) {
                          audioProv.pause();
                        } else {
                          audioProv.resume();
                        }
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded,
                        color: AppColors.textLight, size: 30),
                    onPressed: () => audioProv.skipNext(),
                  ),
                  PopupMenuButton<double>(
                    initialValue: audioProv.playbackSpeed,
                    icon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cardNavy,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${audioProv.playbackSpeed}x',
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryGold,
                        ),
                      ),
                    ),
                    onSelected: (speed) => audioProv.setSpeed(speed),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 0.75, child: Text('0.75x (تعليمي هادئ)')),
                      PopupMenuItem(value: 1.0, child: Text('1.0x (السرعة العادية)')),
                      PopupMenuItem(value: 1.25, child: Text('1.25x (سريع)')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
