import 'package:flutter/material.dart';
import '../core/services/audio_player_service.dart';
import '../models/hymn_model.dart';

class AudioProvider with ChangeNotifier {
  final AudioPlayerService _service = AudioPlayerService();

  Hymn? _currentHymn;
  bool _isPlaying = false;
  bool _isLoading = false;
  String? _playbackError;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  Hymn? get currentHymn => _currentHymn;
  String get activeAudioUrl => _service.activeAudioUrl;
  String get activeCantor => _service.activeCantor.isNotEmpty
      ? _service.activeCantor
      : (_currentHymn?.cantor ?? '');
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  String? get playbackError => _playbackError;
  Duration get duration => _duration;
  Duration get position => _position;
  double get playbackSpeed => _service.playbackSpeed;
  bool get isLooping => _service.isLooping;

  int get activeVerseIndex {
    if (_currentHymn == null || _currentHymn!.verses.isEmpty) {
      return 0;
    }
    final posMs = _position.inMilliseconds;
    final verses = _currentHymn!.verses;
    if (_duration > Duration.zero) {
      final progress = (posMs / _duration.inMilliseconds).clamp(0.0, 0.999);
      final idx = (progress * verses.length).floor();
      return idx.clamp(0, verses.length - 1);
    }
    for (int i = 0; i < verses.length; i++) {
      if (verses[i].endMs > 0 &&
          posMs >= verses[i].startMs &&
          posMs < verses[i].endMs) {
        return i;
      }
    }
    return 0;
  }

  AudioProvider() {
    _service.currentHymnStream.listen((hymn) {
      _currentHymn = hymn;
      notifyListeners();
    });

    _service.isPlayingStream.listen((playing) {
      _isPlaying = playing;
      notifyListeners();
    });

    _service.isLoadingStream.listen((loading) {
      _isLoading = loading;
      notifyListeners();
    });

    _service.errorStream.listen((err) {
      _playbackError = err;
      notifyListeners();
    });

    _service.durationStream.listen((d) {
      _duration = d;
      notifyListeners();
    });

    _service.positionStream.listen((pos) {
      _position = pos;
      notifyListeners();
    });
  }

  Future<bool> play(
    Hymn hymn, {
    String? customAudioUrl,
    String? customCantor,
  }) {
    return _service.playHymn(
      hymn,
      customAudioUrl: customAudioUrl,
      customCantor: customCantor,
    );
  }

  void clearError() {
    _service.clearError();
    _playbackError = null;
    notifyListeners();
  }

  void pause() {
    _service.pause();
  }

  void resume() {
    _service.resume();
  }

  void stop() {
    _service.stop();
  }

  void seek(Duration pos) {
    _service.seek(pos);
  }

  void setSpeed(double speed) {
    _service.setSpeed(speed);
    notifyListeners();
  }

  void toggleLoop() {
    _service.toggleLoop();
    notifyListeners();
  }
}
