import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../../models/hymn_model.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  final AudioPlayer _player = AudioPlayer();
  Timer? _fallbackTimer;

  Hymn? _currentHymn;
  String _activeAudioUrl = '';
  String _activeCantor = '';
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;
  bool _isLooping = false;
  bool _isFallbackMode = false;

  final _hymnStreamController = StreamController<Hymn?>.broadcast();
  final _playingStreamController = StreamController<bool>.broadcast();
  final _positionStreamController = StreamController<Duration>.broadcast();
  final _durationStreamController = StreamController<Duration>.broadcast();

  Stream<Hymn?> get currentHymnStream => _hymnStreamController.stream;
  Stream<bool> get isPlayingStream => _playingStreamController.stream;
  Stream<Duration> get positionStream => _positionStreamController.stream;
  Stream<Duration> get durationStream => _durationStreamController.stream;

  Hymn? get currentHymn => _currentHymn;
  String get activeAudioUrl => _activeAudioUrl;
  String get activeCantor => _activeCantor;
  bool get isPlaying => _isPlaying;
  Duration get duration => _duration;
  Duration get position => _position;
  double get playbackSpeed => _playbackSpeed;
  bool get isLooping => _isLooping;

  AudioPlayerService._internal() {
    _player.setPlayerMode(PlayerMode.mediaPlayer);
    _player.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
        ),
      ),
    );

    _player.onPlayerStateChanged.listen((state) {
      if (!_isFallbackMode) {
        _isPlaying = state == PlayerState.playing;
        _playingStreamController.add(_isPlaying);
      }
    });

    _player.onDurationChanged.listen((newDuration) {
      if (!_isFallbackMode && newDuration > Duration.zero) {
        _duration = newDuration;
        _durationStreamController.add(_duration);
      }
    });

    _player.onPositionChanged.listen((newPosition) {
      if (!_isFallbackMode) {
        _position = newPosition;
        _positionStreamController.add(_position);
      }
    });

    _player.onPlayerComplete.listen((_) {
      if (_isLooping) {
        seek(Duration.zero);
        resume();
      } else {
        _isPlaying = false;
        _position = Duration.zero;
        _playingStreamController.add(false);
      }
    });
  }

  String _normalizeUrl(String url) {
    return url
        .trim()
        .replaceFirst(
          'https://media.stgeorgesaman.com/uploads/',
          'https://stgeorgesaman.com/wp-content/uploads/',
        )
        .replaceFirst(
          'http://media.stgeorgesaman.com/uploads/',
          'https://stgeorgesaman.com/wp-content/uploads/',
        );
  }

  Future<bool> _tryPlaySource(String rawSource) async {
    final source = _normalizeUrl(rawSource);
    if (source.isEmpty) return false;
    try {
      await _player.stop();
      await _player.setPlayerMode(PlayerMode.mediaPlayer);
      if (source.startsWith('assets/')) {
        final assetPath = source.replaceFirst('assets/', '');
        await _player.play(AssetSource(assetPath));
        await _player.setPlaybackRate(_playbackSpeed);
        return true;
      } else if (source.startsWith('http')) {
        final mime = source.toLowerCase().endsWith('.wav') ? 'audio/wav' : 'audio/mpeg';
        await _player
            .play(UrlSource(source, mimeType: mime))
            .timeout(const Duration(seconds: 20));
        await _player.setPlaybackRate(_playbackSpeed);
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  Future<void> playHymn(
    Hymn hymn, {
    String? customAudioUrl,
    String? customCantor,
  }) async {
    _currentHymn = hymn;
    _activeCantor = customCantor ?? hymn.cantor;
    _hymnStreamController.add(_currentHymn);
    _stopFallback();
    _isFallbackMode = false;

    final candidates = <Map<String, String>>[];

    if (customAudioUrl != null && customAudioUrl.isNotEmpty) {
      candidates.add({'url': customAudioUrl, 'cantor': customCantor ?? hymn.cantor});
    }
    if (hymn.localAsset.isNotEmpty) {
      candidates.add({'url': hymn.localAsset, 'cantor': hymn.cantor});
    }
    if (hymn.audioUrl.isNotEmpty) {
      candidates.add({'url': hymn.audioUrl, 'cantor': hymn.cantor});
    }
    for (final rec in hymn.recordings) {
      if (rec.url.isNotEmpty) {
        candidates.add({'url': rec.url, 'cantor': rec.cantor});
      }
    }

    bool nativeSuccess = false;
    final tried = <String>{};
    for (final cand in candidates) {
      final url = cand['url']!;
      if (tried.contains(url)) continue;
      tried.add(url);
      final ok = await _tryPlaySource(url);
      if (ok) {
        _activeAudioUrl = url;
        _activeCantor = cand['cantor'] ?? hymn.cantor;
        _isPlaying = true;
        _playingStreamController.add(true);
        _hymnStreamController.add(_currentHymn);
        nativeSuccess = true;
        break;
      }
    }

    if (!nativeSuccess) {
      _startFallbackMode(hymn);
    }
  }

  void _startFallbackMode(Hymn hymn) {
    _isFallbackMode = true;
    _isPlaying = true;
    _position = Duration.zero;
    final totalSec = (hymn.verses.isNotEmpty ? hymn.verses.length * 20 : 90);
    _duration = Duration(seconds: totalSec);

    _durationStreamController.add(_duration);
    _playingStreamController.add(true);
    _positionStreamController.add(Duration.zero);

    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!_isPlaying) return;
      final newPos = _position + Duration(milliseconds: (500 * _playbackSpeed).toInt());
      if (newPos >= _duration) {
        if (_isLooping) {
          _position = Duration.zero;
          _positionStreamController.add(_position);
        } else {
          _position = Duration.zero;
          _isPlaying = false;
          _playingStreamController.add(false);
          _positionStreamController.add(_position);
          timer.cancel();
        }
      } else {
        _position = newPos;
        _positionStreamController.add(_position);
      }
    });
  }

  void _stopFallback() {
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
  }

  Future<void> pause() async {
    _isPlaying = false;
    _playingStreamController.add(false);
    if (!_isFallbackMode) {
      await _player.pause();
    }
  }

  Future<void> resume() async {
    _isPlaying = true;
    _playingStreamController.add(true);
    if (!_isFallbackMode) {
      await _player.resume();
    }
  }

  Future<void> stop() async {
    _isPlaying = false;
    _position = Duration.zero;
    _stopFallback();
    _playingStreamController.add(false);
    _positionStreamController.add(Duration.zero);
    if (!_isFallbackMode) {
      await _player.stop();
    }
    _currentHymn = null;
    _activeAudioUrl = '';
    _hymnStreamController.add(null);
  }

  Future<void> seek(Duration target) async {
    _position = target;
    _positionStreamController.add(target);
    if (!_isFallbackMode) {
      await _player.seek(target);
    }
  }

  Future<void> setSpeed(double speed) async {
    _playbackSpeed = speed;
    if (!_isFallbackMode) {
      await _player.setPlaybackRate(speed);
    }
  }

  void toggleLoop() {
    _isLooping = !_isLooping;
  }

  void dispose() {
    _stopFallback();
    _player.dispose();
    _hymnStreamController.close();
    _playingStreamController.close();
    _positionStreamController.close();
    _durationStreamController.close();
  }
}
