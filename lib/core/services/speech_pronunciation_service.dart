import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// Neural Arabic & Coptic-Phonetic Speech Pronunciation Service
/// With reactive Play / Stop state and global floating Stop control.
class SpeechPronunciationService {
  static final SpeechPronunciationService _instance = SpeechPronunciationService._internal();
  factory SpeechPronunciationService() => _instance;

  final AudioPlayer _ttsPlayer = AudioPlayer();
  bool _isSpeaking = false;
  String _activeLabel = '';
  List<String> _queue = [];
  int _queueIndex = 0;

  final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> activeLabelNotifier = ValueNotifier<String>('');

  bool get isSpeaking => _isSpeaking;
  String get activeLabel => _activeLabel;

  SpeechPronunciationService._internal() {
    _ttsPlayer.onPlayerComplete.listen((_) {
      _playNextChunk();
    });
  }

  /// Toggles speech: if currently speaking this label (or any speech when stopIfAny=true), stops immediately.
  Future<void> toggleSpeak(
    String rawText, {
    required String label,
    bool stopIfAnySpeaking = false,
  }) async {
    if (_isSpeaking && (_activeLabel == label || stopIfAnySpeaking)) {
      await stop();
      return;
    }
    await speakText(rawText, label: label);
  }

  /// Pronounces a Coptic letter name & phonetic sound clearly
  Future<void> pronounceCopticLetter({
    required String letterName,
    required String sound,
    required String exampleArabized,
    required String exampleMeaning,
  }) async {
    final cleanSound = sound.split('/').first.trim();
    final script =
        'حرف $letterName. يُنطق $cleanSound. مثال: $exampleArabized، ومعناها $exampleMeaning.';
    await speakText(script, label: 'نطق حرف $letterName');
  }

  /// Pronounces only the Coptic example word and its meaning
  Future<void> pronounceCopticWord({
    required String arabized,
    required String meaning,
  }) async {
    final script = meaning.isNotEmpty
        ? '$arabized. ومعناها بالعربية: $meaning.'
        : arabized;
    await speakText(script, label: 'نطق كلمة $arabized');
  }

  /// Speaks any Arabic text (automatically splits long passages into natural sentence chunks)
  Future<void> speakText(String rawText, {String label = 'القارئ الصوتي'}) async {
    await stop();
    final cleaned = rawText
        .replaceAll(RegExp(r'[\*\#\_\~`]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return;

    _queue = _splitIntoChunks(cleaned, maxLen: 165);
    if (_queue.isEmpty) return;

    _queueIndex = 0;
    _isSpeaking = true;
    _activeLabel = label;
    isSpeakingNotifier.value = true;
    activeLabelNotifier.value = label;

    await _playChunkAt(_queueIndex);
  }

  Future<void> _playChunkAt(int idx) async {
    if (!_isSpeaking || idx < 0 || idx >= _queue.length) {
      await stop();
      return;
    }
    final chunk = _queue[idx].trim();
    if (chunk.isEmpty) {
      _playNextChunk();
      return;
    }
    final encoded = Uri.encodeComponent(chunk);
    final url = 'https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=ar&q=$encoded';
    try {
      await _ttsPlayer.stop();
      await _ttsPlayer.play(UrlSource(url, mimeType: 'audio/mpeg'));
    } catch (_) {
      await stop();
    }
  }

  void _playNextChunk() {
    if (!_isSpeaking) return;
    _queueIndex++;
    if (_queueIndex < _queue.length) {
      _playChunkAt(_queueIndex);
    } else {
      stop();
    }
  }

  Future<void> stop() async {
    _isSpeaking = false;
    _queue = [];
    _queueIndex = 0;
    _activeLabel = '';
    isSpeakingNotifier.value = false;
    activeLabelNotifier.value = '';
    try {
      await _ttsPlayer.stop();
    } catch (_) {}
  }

  List<String> _splitIntoChunks(String text, {int maxLen = 165}) {
    final sentences = text.split(RegExp(r'(?<=[\.!\؟\?،؛\n])\s+'));
    final chunks = <String>[];
    String current = '';

    for (final s in sentences) {
      final trimmed = s.trim();
      if (trimmed.isEmpty) continue;
      if (current.isEmpty) {
        if (trimmed.length <= maxLen) {
          current = trimmed;
        } else {
          final words = trimmed.split(' ');
          for (final w in words) {
            if ((current.length + w.length + 1) <= maxLen) {
              current = current.isEmpty ? w : '$current $w';
            } else {
              if (current.isNotEmpty) chunks.add(current);
              current = w;
            }
          }
        }
      } else if ((current.length + trimmed.length + 1) <= maxLen) {
        current = '$current $trimmed';
      } else {
        chunks.add(current);
        if (trimmed.length <= maxLen) {
          current = trimmed;
        } else {
          current = '';
          final words = trimmed.split(' ');
          for (final w in words) {
            if ((current.length + w.length + 1) <= maxLen) {
              current = current.isEmpty ? w : '$current $w';
            } else {
              if (current.isNotEmpty) chunks.add(current);
              current = w;
            }
          }
        }
      }
    }
    if (current.isNotEmpty) {
      chunks.add(current);
    }
    return chunks;
  }
}

/// Reusable Play / Stop Speech Button that automatically switches to "إيقاف الصوت" when active.
class SpeechPlayStopButton extends StatelessWidget {
  final String textToSpeak;
  final String label;
  final String playText;
  final String stopText;
  final bool compact;

  const SpeechPlayStopButton({
    super.key,
    required this.textToSpeak,
    required this.label,
    this.playText = 'استماع',
    this.stopText = 'إيقاف الصوت',
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final speech = SpeechPronunciationService();
    return ValueListenableBuilder<bool>(
      valueListenable: speech.isSpeakingNotifier,
      builder: (context, speaking, _) {
        return ValueListenableBuilder<String>(
          valueListenable: speech.activeLabelNotifier,
          builder: (context, activeLbl, _) {
            final isThisActive = speaking && (activeLbl == label || compact);
            return ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                if (speaking) {
                  speech.stop();
                } else {
                  speech.speakText(textToSpeak, label: label);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isThisActive
                    ? AppColors.sacredBurgundy
                    : AppColors.primaryGold.withValues(alpha: 0.14),
                foregroundColor: isThisActive ? Colors.white : AppColors.primaryGoldLight,
                elevation: 0,
                visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 14,
                  vertical: compact ? 6 : 10,
                ),
                side: BorderSide(
                  color: isThisActive
                      ? AppColors.rubricRed
                      : AppColors.primaryGold.withValues(alpha: 0.35),
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(
                isThisActive ? Icons.stop_rounded : Icons.volume_up_rounded,
                size: compact ? 15 : 17,
                color: isThisActive ? Colors.white : AppColors.primaryGold,
              ),
              label: Text(
                isThisActive ? stopText : playText,
                style: GoogleFonts.cairo(
                  fontSize: compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.bold,
                  color: isThisActive ? Colors.white : AppColors.primaryGoldLight,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
