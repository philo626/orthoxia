import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import '../../models/hymn_model.dart';
import 'security_guard_service.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  final AudioPlayer _player = AudioPlayer();
  final LinkedHashMap<String, Uint8List> _audioCache =
      LinkedHashMap<String, Uint8List>();
  static const int _maxCachedTracks = 3;
  static const int _maxAudioBytes = 25 * 1024 * 1024; // 25 MB safety cap

  Hymn? _currentHymn;
  String _activeAudioUrl = '';
  String _activeCantor = '';
  bool _isPlaying = false;
  bool _isLoading = false;
  String? _lastError;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _playbackSpeed = 1.0;
  bool _isLooping = false;

  final _hymnStreamController = StreamController<Hymn?>.broadcast();
  final _playingStreamController = StreamController<bool>.broadcast();
  final _loadingStreamController = StreamController<bool>.broadcast();
  final _errorStreamController = StreamController<String?>.broadcast();
  final _positionStreamController = StreamController<Duration>.broadcast();
  final _durationStreamController = StreamController<Duration>.broadcast();

  Stream<Hymn?> get currentHymnStream => _hymnStreamController.stream;
  Stream<bool> get isPlayingStream => _playingStreamController.stream;
  Stream<bool> get isLoadingStream => _loadingStreamController.stream;
  Stream<String?> get errorStream => _errorStreamController.stream;
  Stream<Duration> get positionStream => _positionStreamController.stream;
  Stream<Duration> get durationStream => _durationStreamController.stream;

  Hymn? get currentHymn => _currentHymn;
  String get activeAudioUrl => _activeAudioUrl;
  String get activeCantor => _activeCantor;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
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
      _isPlaying = state == PlayerState.playing;
      if (_isPlaying) {
        _isLoading = false;
        _loadingStreamController.add(false);
      }
      _playingStreamController.add(_isPlaying);
    });

    _player.onDurationChanged.listen((newDuration) {
      if (newDuration > Duration.zero) {
        _duration = newDuration;
        _durationStreamController.add(_duration);
      }
    });

    _player.onPositionChanged.listen((newPosition) {
      _position = newPosition;
      _positionStreamController.add(_position);
    });

    _player.onPlayerComplete.listen((_) {
      if (_isLooping) {
        seek(Duration.zero);
        resume();
      } else {
        _isPlaying = false;
        _position = Duration.zero;
        _playingStreamController.add(false);
        _positionStreamController.add(Duration.zero);
      }
    });
  }

  String _normalizeUrl(String url) {
    final upgraded = SecurityGuardService.upgradeToHttps(url);
    return upgraded.replaceFirst(
      'https://media.stgeorgesaman.com/uploads/',
      'https://stgeorgesaman.com/wp-content/uploads/',
    );
  }

  void clearError() {
    _lastError = null;
    _errorStreamController.add(null);
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
      } else if (SecurityGuardService.isSafeExternalUrl(source)) {
        final mime =
            source.toLowerCase().endsWith('.wav') ? 'audio/wav' : 'audio/mpeg';

        // 1. Check tiny in-memory LRU cache first
        Uint8List? bytes = _audioCache[source];
        if (bytes == null) {
          // 2. Fetch with standard browser User-Agent so liturgical servers
          //    (e.g. stgeorgesaman.com) do not reject Android MediaPlayer with HTTP 406.
          try {
            final resp = await http.get(
              Uri.parse(source),
              headers: const {
                'User-Agent':
                    'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
                'Accept': 'audio/mpeg, audio/wav, audio/*;q=0.9, */*;q=0.5',
              },
            ).timeout(const Duration(seconds: 15));
            if (resp.statusCode == 200 &&
                resp.bodyBytes.length > 1024 &&
                resp.bodyBytes.length <= _maxAudioBytes) {
              bytes = resp.bodyBytes;
              _audioCache[source] = bytes;
              if (_audioCache.length > _maxCachedTracks) {
                _audioCache.remove(_audioCache.keys.first);
              }
            }
          } catch (_) {
            bytes = null;
          }
        }

        if (bytes != null) {
          await _player
              .play(BytesSource(bytes, mimeType: mime))
              .timeout(const Duration(seconds: 12));
          await _player.setPlaybackRate(_playbackSpeed);
          return true;
        }

        // 3. Direct stream fallback for non-WAF hosts
        await _player
            .play(UrlSource(source, mimeType: mime))
            .timeout(const Duration(seconds: 12));
        await _player.setPlaybackRate(_playbackSpeed);
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  /// Attempts to play real audio from local asset or verified remote recording.
  /// Never simulates fake silent playback on network failure — instead reports
  /// an honest error so the UI can switch smoothly to YouTube or inform the user.
  Future<bool> playHymn(
    Hymn hymn, {
    String? customAudioUrl,
    String? customCantor,
  }) async {
    _currentHymn = hymn;
    _activeCantor = customCantor ?? hymn.cantor;
    _isLoading = true;
    _isPlaying = false;
    _position = Duration.zero;
    _duration = Duration.zero;
    _lastError = null;

    _hymnStreamController.add(_currentHymn);
    _loadingStreamController.add(true);
    _playingStreamController.add(false);
    _positionStreamController.add(Duration.zero);
    _durationStreamController.add(Duration.zero);
    _errorStreamController.add(null);

    final candidates = <Map<String, String>>[];

    if (customAudioUrl != null && customAudioUrl.isNotEmpty) {
      candidates
          .add({'url': customAudioUrl, 'cantor': customCantor ?? hymn.cantor});
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

    final tried = <String>{};
    for (final cand in candidates) {
      final url = cand['url']!;
      if (tried.contains(url)) continue;
      tried.add(url);
      final ok = await _tryPlaySource(url);
      if (ok) {
        _activeAudioUrl = url;
        _activeCantor = cand['cantor'] ?? hymn.cantor;
        _isLoading = false;
        _isPlaying = true;
        _lastError = null;
        _loadingStreamController.add(false);
        _playingStreamController.add(true);
        _errorStreamController.add(null);
        _hymnStreamController.add(_currentHymn);
        return true;
      }
    }

    // Honest failure: do NOT tick a fake silent timer.
    _isLoading = false;
    _isPlaying = false;
    _activeAudioUrl = '';
    _lastError =
        'خادم الصوت المباشر لهذا اللحن غير مستجيب حالياً — يمكنك الاستماع عبر يوتيوب مباشرة.';
    _loadingStreamController.add(false);
    _playingStreamController.add(false);
    _errorStreamController.add(_lastError);
    return false;
  }

  Future<void> pause() async {
    _isPlaying = false;
    _playingStreamController.add(false);
    try {
      await _player.pause();
    } catch (_) {}
  }

  Future<void> resume() async {
    if (_activeAudioUrl.isEmpty && _currentHymn != null) {
      await playHymn(_currentHymn!);
      return;
    }
    _isPlaying = true;
    _playingStreamController.add(true);
    try {
      await _player.resume();
    } catch (_) {}
  }

  Future<void> stop() async {
    _isPlaying = false;
    _isLoading = false;
    _lastError = null;
    _position = Duration.zero;
    _duration = Duration.zero;
    _playingStreamController.add(false);
    _loadingStreamController.add(false);
    _errorStreamController.add(null);
    _positionStreamController.add(Duration.zero);
    _durationStreamController.add(Duration.zero);
    try {
      await _player.stop();
    } catch (_) {}
    _currentHymn = null;
    _activeAudioUrl = '';
    _hymnStreamController.add(null);
  }

  Future<void> seek(Duration target) async {
    _position = target;
    _positionStreamController.add(target);
    try {
      await _player.seek(target);
    } catch (_) {}
  }

  Future<void> setSpeed(double speed) async {
    _playbackSpeed = speed;
    try {
      await _player.setPlaybackRate(speed);
    } catch (_) {}
  }

  void toggleLoop() {
    _isLooping = !_isLooping;
  }

  void dispose() {
    _player.dispose();
    _hymnStreamController.close();
    _playingStreamController.close();
    _loadingStreamController.close();
    _errorStreamController.close();
    _positionStreamController.close();
    _durationStreamController.close();
  }
}
