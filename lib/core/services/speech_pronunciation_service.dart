import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../theme/app_palette.dart';

/// Authentic Bohairic Egyptian Coptic -> Vocalized Arabic Phonetic Engine.
/// Converts raw Coptic Unicode (`Ⲡⲓⲭ̀ⲣⲓⲥⲧⲟⲥ`, `Ⲑⲉⲟ̀ⲧⲟⲕⲟⲥ`, `Ⲙⲁⲣⲉⲛϣⲉⲡϩ̀ⲙⲟⲧ`) into
/// accurately vocalized Egyptian-Coptic Arabic pronunciation so BOTH Online Neural Audio
/// and Native Offline Android TTS read Coptic correctly instead of skipping/mangling it!
class CopticPhoneticEngine {
  static final RegExp _copticRegex = RegExp(
    r'[\u2C80-\u2CFF\u03E2-\u03EF][\u2C80-\u2CFF\u03E2-\u03EF\u0300-\u036F\uFE24-\uFE26]*',
  );

  static const Set<String> _vowels = {'ⲁ', 'ⲉ', 'ⲏ', 'ⲓ', 'ⲟ', 'ⲩ', 'ⲱ'};
  static const Set<String> _frontVowels = {'ⲉ', 'ⲏ', 'ⲓ', 'ⲩ'};
  static const Set<String> _gutturals = {'ⲅ', 'ⲕ', 'ⲝ', 'ⲭ'};

  /// Well-known liturgical Coptic words with exact canonical Egyptian-Coptic vocalization
  static const Map<String, String> _exactLiturgicalDict = {
    'ⲡⲓⲭⲣⲓⲥⲧⲟⲥ': 'بِي إِخْرِيسْتُوس',
    'ⲭⲣⲓⲥⲧⲟⲥ': 'إِخْرِيسْتُوس',
    'ⲓⲏⲥⲟⲩⲥ': 'إِيسُوس',
    'ⲫⲛⲟⲩϯ': 'إِفْنُوتِي',
    'ⲛⲟⲩϯ': 'نُوتِي',
    'ⲡϭⲟⲓⲥ': 'إِبْشُويس',
    'ⲡⲁϭⲟⲓⲥ': 'بَاشُويس',
    'ⲑⲉⲟⲧⲟⲕⲟⲥ': 'ثِيئُوطُوكُوس',
    'ⲕⲩⲣⲓⲉ': 'كِيرِيِي',
    'ⲉⲗⲉⲏⲥⲟⲛ': 'إِلِيسُون',
    'ⲁⲅⲓⲟⲥ': 'أَجِيُوس',
    'ⲁⲗⲗⲏⲗⲟⲩⲓⲁ': 'أَلِّيلُويَا',
    'ⲁⲙⲏⲛ': 'آمِين',
    'ϣⲗⲏⲗ': 'إِشْلِيل',
    'ⲓⲣⲏⲛⲏ': 'إِيرِينِي',
    'ϩⲓⲣⲏⲛⲏ': 'هِيرِينِي',
    'ⲡⲁⲥⲓ': 'بَاسِي',
    'ⲡⲛⲉⲩⲙⲁ': 'إِبْنِيفْمَا',
    'ⲡⲛⲉⲩⲙⲁⲧⲓ': 'إِبْنِيفْمَاتِي',
    'ⲉⲕⲕⲗⲏⲥⲓⲁ': 'إِكْلِيسِيَا',
    'ⲙⲁⲣⲓⲁ': 'مَارِيَا',
    'ⲭⲉⲣⲉ': 'شِيرِي',
    'ⲡⲟⲩⲣⲟ': 'إِبْؤُرُو',
    'ⲟⲩⲣⲟ': 'أُورُو',
    'ⲁⲝⲓⲟⲥ': 'أَكْسِيُوس',
    'ⲧⲉⲛⲟⲩⲱϣⲧ': 'تِين أُوأُوشْت',
    'ⲙⲁⲣⲉⲛϣⲉⲡϩⲙⲟⲧ': 'مَارِين شِيب إِهْمُوت',
    'ⲥⲙⲟⲩ': 'إِسْمُو',
    'ⲉⲣⲟϥ': 'إِيرُوف',
    'ϧⲉⲛ': 'خِين',
    'ⲫⲣⲁⲛ': 'إِفْرَان',
    'ⲙⲫⲓⲱⲧ': 'إِمْفِيُوت',
    'ⲛⲉⲙ': 'نِيم',
    'ⲡϣⲏⲣⲓ': 'إِبْشِيرِي',
    'ϣⲏⲣⲓ': 'شِيرِي',
    'ⲉⲩⲁⲅⲅⲉⲗⲓⲟⲛ': 'إِيف أَنْجِيلِيُون',
    'ⲯⲁⲗⲙⲟⲥ': 'إِبْسَالْمُوس',
    'ⲇⲟⲝⲁ': 'ذُوكْسَا',
    'ⲥⲱⲧⲏⲣ': 'سُوتِير',
    'ⲁⲅⲁⲡⲏ': 'أَغَابِي',
    'ⲧⲣⲓⲁⲥ': 'إِتْرِيَاس',
    'ⲱⲥⲁⲛⲛⲁ': 'أُوصَنَّا',
  };

  static bool containsCoptic(String text) => _copticRegex.hasMatch(text);

  /// Replaces any Coptic Unicode segments in [text] with vocalized Egyptian-Coptic Arabic.
  static String prepareForSpeech(String text) {
    if (!containsCoptic(text)) return text;
    return text.replaceAllMapped(_copticRegex, (m) {
      final rawWord = m.group(0) ?? '';
      return transliterateWord(rawWord);
    });
  }

  static String transliterateWord(String raw) {
    final lower = raw.toLowerCase();
    // Strip combining marks (jenkim U+0300, overline U+0304/U+0305) for dict check
    final stripped = lower.replaceAll(RegExp(r'[\u0300-\u036F\uFE24-\uFE26]'), '');
    if (_exactLiturgicalDict.containsKey(stripped)) {
      return _exactLiturgicalDict[stripped]!;
    }

    final chars = lower.runes.map((r) => String.fromCharCode(r)).toList();
    final out = StringBuffer();

    for (int i = 0; i < chars.length; i++) {
      final ch = chars[i];
      final next = (i + 1 < chars.length) ? chars[i + 1] : '';
      final prev = (i > 0) ? chars[i - 1] : '';

      // Combining Jenkim (̀) adds a soft initial 'إِ' before consonant
      if (ch == '\u0300' || ch == '\u0304' || ch == '\u0305') {
        continue;
      }
      final hasJenkimAfter = next == '\u0300';
      if (hasJenkimAfter && !_vowels.contains(ch)) {
        out.write('إِ');
      }

      // Diphthongs first
      if (ch == 'ⲟ' && next == 'ⲩ') {
        out.write(i == 0 ? 'أُو' : 'ُو');
        i++;
        continue;
      }
      if (ch == 'ⲁ' && next == 'ⲩ') {
        out.write(i == 0 ? 'أَفْ' : 'َافْ');
        i++;
        continue;
      }
      if (ch == 'ⲉ' && next == 'ⲩ') {
        out.write(i == 0 ? 'إِيفْ' : 'ِيفْ');
        i++;
        continue;
      }
      if (ch == 'ⲟ' && next == 'ⲓ') {
        out.write('ُوي');
        i++;
        continue;
      }

      switch (ch) {
        case 'ⲁ':
          out.write(i == 0 ? 'آ' : 'ا');
          break;
        case 'ⲃ':
          out.write(_vowels.contains(next) ? 'ف' : 'ب');
          break;
        case 'ⲅ':
          if (_gutturals.contains(next)) {
            out.write('ن');
          } else if (_frontVowels.contains(next)) {
            out.write('ج');
          } else {
            out.write('غ');
          }
          break;
        case 'ⲇ':
          out.write(i == 0 ? 'د' : 'ذ');
          break;
        case 'ⲉ':
          out.write(i == 0 ? 'إِ' : 'ِي');
          break;
        case 'ⲋ':
          out.write('سُو');
          break;
        case 'ⲍ':
          out.write('ز');
          break;
        case 'ⲏ':
          out.write(i == 0 ? 'إِي' : 'ي');
          break;
        case 'ⲑ':
          out.write((prev == 'ⲥ' || prev == 'ϣ') ? 'ت' : 'ث');
          break;
        case 'ⲓ':
          out.write(i == 0 ? 'إِي' : 'ي');
          break;
        case 'ⲕ':
          out.write('ك');
          break;
        case 'ⲗ':
          out.write('ل');
          break;
        case 'ⲙ':
          out.write('م');
          break;
        case 'ⲛ':
          out.write('ن');
          break;
        case 'ⲝ':
          out.write('كْس');
          break;
        case 'ⲟ':
          out.write(i == 0 ? 'أُ' : 'و');
          break;
        case 'ⲡ':
          out.write('ب');
          break;
        case 'ⲣ':
          out.write('ر');
          break;
        case 'ⲥ':
          out.write('س');
          break;
        case 'ⲧ':
          out.write(prev == 'ⲛ' ? 'د' : 'ت');
          break;
        case 'ⲩ':
          out.write(i == 0 ? 'إِي' : 'ي');
          break;
        case 'ⲫ':
          out.write('ف');
          break;
        case 'ⲭ':
          if (_frontVowels.contains(next)) {
            out.write('ش');
          } else {
            out.write('خ');
          }
          break;
        case 'ⲯ':
          out.write('بْس');
          break;
        case 'ⲱ':
          out.write(i == 0 ? 'أُو' : 'و');
          break;
        case 'ϣ':
          out.write('ش');
          break;
        case 'ϥ':
          out.write('ف');
          break;
        case 'ϧ':
          out.write('خ');
          break;
        case 'ϩ':
          out.write('ه');
          break;
        case 'ϫ':
          out.write('ج');
          break;
        case 'ϭ':
          out.write('تْش');
          break;
        case 'ϯ':
          out.write('تِي');
          break;
        default:
          out.write(ch);
      }
    }
    return out.toString();
  }
}

/// Hybrid Online (Disk-Cached Neural Audio) + 100% Offline Native Android TTS Service
/// with Authentic Bohairic Coptic Phonetic Engine and reactive Play / Stop controls.
class SpeechPronunciationService {
  static final SpeechPronunciationService _instance =
      SpeechPronunciationService._internal();
  factory SpeechPronunciationService() => _instance;

  static const MethodChannel _ttsChannel = MethodChannel('com.orthodox.app/tts');

  final AudioPlayer _ttsPlayer = AudioPlayer();
  bool _isSpeaking = false;
  bool _usingOfflineEngine = false;
  String _activeLabel = '';
  List<String> _queue = [];
  int _queueIndex = 0;
  String? _cacheDirPath;

  final ValueNotifier<bool> isSpeakingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String> activeLabelNotifier = ValueNotifier<String>('');

  bool get isSpeaking => _isSpeaking;
  String get activeLabel => _activeLabel;

  SpeechPronunciationService._internal() {
    _ttsPlayer.onPlayerComplete.listen((_) {
      if (!_usingOfflineEngine) {
        _playNextChunk();
      }
    });
    _ttsChannel.setMethodCallHandler((call) async {
      if (call.method == 'onOfflineDone' && _usingOfflineEngine && _isSpeaking) {
        _playNextChunk();
      }
    });
  }

  Future<String?> _getCacheDir() async {
    if (_cacheDirPath != null) return _cacheDirPath;
    try {
      final path = await _ttsChannel.invokeMethod<String>('getTtsCacheDir');
      if (path != null && path.isNotEmpty) {
        _cacheDirPath = path;
      }
    } catch (_) {}
    return _cacheDirPath;
  }

  String _hashChunk(String text) {
    final bytes = utf8.encode(text);
    int h1 = 0x811c9dc5;
    int h2 = 0x9e3779b9;
    for (final b in bytes) {
      h1 ^= b;
      h1 = (h1 * 0x01000193) & 0xFFFFFFFF;
      h2 ^= (b + 31);
      h2 = (h2 * 0x85ebca6b) & 0xFFFFFFFF;
    }
    return '${h1.toRadixString(16)}_${h2.toRadixString(16)}';
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

  /// Pronounces a Coptic letter name, phonetic sound & vocalized example word (Online Cached + Offline!)
  Future<void> pronounceCopticLetter({
    required String letterName,
    required String sound,
    required String exampleArabized,
    required String exampleMeaning,
  }) async {
    final cleanSound = sound.split('/').first.trim();
    final script =
        'حرف $letterName. بيتنطق $cleanSound. مثال: $exampleArabized، ومعناها $exampleMeaning.';
    await speakText(script, label: 'نطق حرف $letterName');
  }

  /// Pronounces a Coptic word (accepts raw Coptic Unicode OR vocalized arabized text!)
  Future<void> pronounceCopticWord({
    required String arabized,
    required String meaning,
    String? rawCoptic,
  }) async {
    final spokenWord = arabized.trim().isNotEmpty
        ? arabized.trim()
        : CopticPhoneticEngine.prepareForSpeech(rawCoptic ?? '');
    final script = meaning.isNotEmpty
        ? '$spokenWord. ومعناها بالعربي: $meaning.'
        : spokenWord;
    await speakText(script, label: 'نطق $spokenWord');
  }

  /// Speaks any Arabic or Coptic text:
  ///   1) Converts any Coptic Unicode to accurate vocalized Egyptian-Coptic Arabic
  ///   2) Plays from disk cache if previously downloaded (100% OFFLINE!)
  ///   3) Downloads & caches crisp online neural audio when connected
  ///   4) Falls back smoothly to Native Android Offline TTS if no internet!
  Future<void> speakText(String rawText, {String label = 'القارئ الصوتي'}) async {
    await stop();
    final phoneticReady = CopticPhoneticEngine.prepareForSpeech(rawText);
    final cleaned = phoneticReady
        .replaceAll(RegExp(r'[\*\#\_\~`]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return;

    _queue = _splitIntoChunks(cleaned, maxLen: 165);
    if (_queue.isEmpty) return;

    _queueIndex = 0;
    _isSpeaking = true;
    _usingOfflineEngine = false;
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

    // 1. Try disk-cached neural MP3 first (instant & works 100% offline!)
    final cacheDir = await _getCacheDir();
    File? cacheFile;
    if (cacheDir != null) {
      cacheFile = File('$cacheDir/tts_${_hashChunk(chunk)}.mp3');
      if (await cacheFile.exists() && await cacheFile.length() > 512) {
        try {
          _usingOfflineEngine = false;
          await _ttsPlayer.stop();
          await _ttsPlayer.play(DeviceFileSource(cacheFile.path));
          return;
        } catch (_) {}
      }
    }

    // 2. Try fetching crisp online neural audio & saving to disk cache for offline reuse
    final encoded = Uri.encodeComponent(chunk);
    final url =
        'https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=ar&q=$encoded';
    try {
      final resp = await http
          .get(
            Uri.parse(url),
            headers: const {
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
            },
          )
          .timeout(const Duration(seconds: 7));
      if (resp.statusCode == 200 && resp.bodyBytes.length > 512) {
        _usingOfflineEngine = false;
        await _ttsPlayer.stop();
        if (cacheFile != null) {
          try {
            await cacheFile.writeAsBytes(resp.bodyBytes, flush: true);
            await _ttsPlayer.play(DeviceFileSource(cacheFile.path));
            return;
          } catch (_) {}
        }
        await _ttsPlayer
            .play(BytesSource(resp.bodyBytes, mimeType: 'audio/mpeg'));
        return;
      }
    } catch (_) {
      // Offline or blocked -> seamlessly fall back to Native Android Offline TTS!
    }

    // 3. 100% Offline Native Android TextToSpeech Fallback
    try {
      _usingOfflineEngine = true;
      final ok = await _ttsChannel.invokeMethod<bool>('speakOffline', {
        'text': chunk,
        'rate': 0.90,
      });
      if (ok == true) return;
    } catch (_) {}

    await stop();
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
    _usingOfflineEngine = false;
    _queue = [];
    _queueIndex = 0;
    _activeLabel = '';
    isSpeakingNotifier.value = false;
    activeLabelNotifier.value = '';
    try {
      await _ttsPlayer.stop();
    } catch (_) {}
    try {
      await _ttsChannel.invokeMethod('stopOffline');
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
    this.playText = 'اسمع النطق',
    this.stopText = 'إيقاف الصوت',
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
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
                backgroundColor: isThisActive ? p.crimson : p.accentSoft,
                foregroundColor: isThisActive ? Colors.white : p.accent,
                elevation: 0,
                visualDensity:
                    compact ? VisualDensity.compact : VisualDensity.standard,
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 14,
                  vertical: compact ? 6 : 10,
                ),
                side: BorderSide(
                  color: isThisActive
                      ? p.crimson
                      : p.accent.withValues(alpha: 0.35),
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(
                isThisActive ? Icons.stop_rounded : Icons.volume_up_rounded,
                size: compact ? 15 : 17,
                color: isThisActive ? Colors.white : p.accent,
              ),
              label: Text(
                isThisActive ? stopText : playText,
                style: GoogleFonts.cairo(
                  fontSize: compact ? 11.5 : 12.5,
                  fontWeight: FontWeight.w700,
                  color: isThisActive ? Colors.white : p.accent,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
