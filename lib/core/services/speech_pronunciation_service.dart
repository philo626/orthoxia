import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Neural Arabic & Coptic-Phonetic Speech Pronunciation Service
/// Powers:
/// 1. Coptic Academy letter & word pronunciation (نطق الحروف والكلمات القبطية صوتياً)
/// 2. Audio Reader for Bible chapters, Synaxarium biographies, Agpeya, and Patristic AI answers
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
    final script = '$arabized. ومعناها بالعربية: $meaning.';
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
          // Split long sentence by words
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
