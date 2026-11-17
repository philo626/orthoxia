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
        final currentPos = audioProv.position;
        final totalDur = audioProv.duration;
        final maxSeconds = totalDur.inSeconds > 0 ? totalDur.inSeconds.toDouble() : 1.0;
        final currentSeconds = currentPos.inSeconds.toDouble().clamp(0.0, maxSeconds);

        return Container(
          height: MediaQuery.of(context).size.height * 0.72,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: const BoxDecoration(
            color: AppColors.deepNavy,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),

              // Coptic Hymn Art Disk
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [AppColors.sacredBurgundyDark, AppColors.cardNavy],
                  ),
                  border: Border.all(color: AppColors.primaryGold, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGold.withOpacity(0.25),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.music_note_rounded, size: 72, color: AppColors.primaryGold),
                ),
              ),

              const SizedBox(height: 24),

              // Hymn Title & Cantor
              Text(
                hymn.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryGold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hymn.cantor,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),

              const SizedBox(height: 20),

              // Slider
              Slider(
                value: currentSeconds,
                min: 0.0,
                max: maxSeconds,
                activeColor: AppColors.primaryGold,
                inactiveColor: Colors.white.withOpacity(0.15),
                onChanged: (val) {
                  audioProv.seek(Duration(seconds: val.toInt()));
                },
              ),

              // Time stamps
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatDuration(currentPos),
                        style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted)),
                    Text(_formatDuration(totalDur),
                        style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Media Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Loop Toggle
                  IconButton(
                    icon: Icon(
                      Icons.repeat_rounded,
                      color: audioProv.isLooping ? AppColors.primaryGold : AppColors.textMuted,
                      size: 24,
                    ),
                    onPressed: () => audioProv.toggleLoop(),
                  ),
                  const SizedBox(width: 16),

                  // Rewind 15s
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded, color: AppColors.textLight, size: 30),
                    onPressed: () {
                      final newPos = currentPos - const Duration(seconds: 10);
                      audioProv.seek(newPos < Duration.zero ? Duration.zero : newPos);
                    },
                  ),
                  const SizedBox(width: 16),

                  // Main Play / Pause Circle
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryGold,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGold.withOpacity(0.4),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        audioProv.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 36,
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
                  const SizedBox(width: 16),

                  // Forward 15s
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded, color: AppColors.textLight, size: 30),
                    onPressed: () {
                      final newPos = currentPos + const Duration(seconds: 10);
                      audioProv.seek(newPos > totalDur ? totalDur : newPos);
                    },
                  ),
                  const SizedBox(width: 16),

                  // Speed Switcher
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
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 0.75, child: Text('0.75x (تعليمي هادئ)')),
                      const PopupMenuItem(value: 1.0, child: Text('1.0x (السرعة العادية)')),
                      const PopupMenuItem(value: 1.25, child: Text('1.25x (سريع)')),
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
