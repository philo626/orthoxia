import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';
import 'security_guard_service.dart';
import 'storage_service.dart';

class TriviaRoomState {
  final String roomCode;
  final String hostUid;
  final String hostName;
  final String categoryLabel;
  final String status; // 'waiting' | 'playing' | 'finished'
  final List<int> questionIndices;
  final DateTime? createdAt;

  const TriviaRoomState({
    required this.roomCode,
    required this.hostUid,
    required this.hostName,
    required this.categoryLabel,
    required this.status,
    required this.questionIndices,
    this.createdAt,
  });

  factory TriviaRoomState.fromMap(String code, Map<String, dynamic> d) {
    final ts = d['createdAt'];
    final rawQ = (d['questionIndices'] as List?) ?? const [];
    return TriviaRoomState(
      roomCode: code,
      hostUid: '${d['hostUid'] ?? ''}',
      hostName: '${d['hostName'] ?? ''}',
      categoryLabel: '${d['categoryLabel'] ?? 'تحدي شامل'}',
      status: '${d['status'] ?? 'waiting'}',
      questionIndices: rawQ.map((e) => (e as num).toInt()).toList(),
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}

class TriviaRoomPlayer {
  final String uid;
  final String name;
  final int score;
  final int answeredCount;
  final int correctCount;
  final bool finished;

  const TriviaRoomPlayer({
    required this.uid,
    required this.name,
    required this.score,
    required this.answeredCount,
    required this.correctCount,
    required this.finished,
  });

  factory TriviaRoomPlayer.fromMap(String uid, Map<String, dynamic> d) => TriviaRoomPlayer(
        uid: uid,
        name: '${d['name'] ?? 'صديق'}',
        score: (d['score'] as num?)?.toInt() ?? 0,
        answeredCount: (d['answeredCount'] as num?)?.toInt() ?? 0,
        correctCount: (d['correctCount'] as num?)?.toInt() ?? 0,
        finished: d['finished'] == true,
      );
}

class DailyLeaderboardEntry {
  final String uid;
  final String name;
  final int score;
  final int correctCount;
  final int totalCount;

  const DailyLeaderboardEntry({
    required this.uid,
    required this.name,
    required this.score,
    required this.correctCount,
    required this.totalCount,
  });

  factory DailyLeaderboardEntry.fromMap(String uid, Map<String, dynamic> d) =>
      DailyLeaderboardEntry(
        uid: uid,
        name: '${d['name'] ?? 'مشارك'}',
        score: (d['score'] as num?)?.toInt() ?? 0,
        correctCount: (d['correctCount'] as num?)?.toInt() ?? 0,
        totalCount: (d['totalCount'] as num?)?.toInt() ?? 10,
      );
}

/// 100% FREE Live Online Multiplayer Trivia & Daily Leaderboard Service powered by Firestore Free Tier!
/// - Friends Private Rooms (`OR-XXXX`): create room, share code on WhatsApp, see friends join live, race on the same questions!
/// - Daily Online Challenge: deterministic date-seeded 10 questions shared by every user today + live Top 20 leaderboard!
class MultiplayerTriviaService {
  static final MultiplayerTriviaService _instance = MultiplayerTriviaService._internal();
  factory MultiplayerTriviaService() => _instance;
  MultiplayerTriviaService._internal();

  final FirebaseService _firebase = FirebaseService();
  final StorageService _storage = StorageService();
  final Random _rng = Random.secure();

  FirebaseFirestore? get _db =>
      _firebase.isFirebaseReady ? FirebaseFirestore.instance : null;

  String? get currentUid => _firebase.currentUser?.uid;

  static String todayIso([DateTime? now]) {
    final d = now ?? DateTime.now();
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Generates deterministic 10 daily question indices from today's date so every player gets the exact same Daily Challenge!
  static List<int> dailyQuestionIndices(int poolSize, {int count = 10, DateTime? date}) {
    if (poolSize <= 0) return const [];
    final d = date ?? DateTime.now();
    final seed = d.year * 10000 + d.month * 100 + d.day;
    final indices = List<int>.generate(poolSize, (i) => i);
    indices.shuffle(Random(seed));
    return indices.take(count.clamp(1, poolSize)).toList();
  }

  /// Normalizes room codes: handles spaces, lowercase, Arabic digits, missing `OR-` prefix
  static String normalizeRoomCode(String raw) {
    var s = raw.trim().toUpperCase();
    const ar = '٠١٢٣٤٥٦٧٨٩';
    for (int i = 0; i < ar.length; i++) {
      s = s.replaceAll(ar[i], '$i');
    }
    s = s.replaceAll(RegExp(r'[\s_–—]+'), '-');
    if (s.isEmpty) return '';
    if (!s.contains('-')) {
      if (s.startsWith('OR') && s.length > 2) {
        s = 'OR-${s.substring(2)}';
      } else if (s.length == 4) {
        s = 'OR-$s';
      }
    }
    return s;
  }

  String _generateRoomCode() {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final buf = StringBuffer('OR-');
    for (int i = 0; i < 4; i++) {
      buf.write(chars[_rng.nextInt(chars.length)]);
    }
    return buf.toString();
  }

  String _myPlayerName() {
    final raw = _storage.hasCustomUserName()
        ? _storage.getUserName()
        : (_firebase.currentUser?.displayName ?? 'بطل أرثوذكسيا');
    final clean = SecurityGuardService.sanitizeText(raw, maxLength: 50, allowNewlines: false);
    return clean.isEmpty ? 'بطل أرثوذكسيا' : clean;
  }

  static String buildFriendRoomShareText({
    required String hostName,
    required String roomCode,
    required String categoryLabel,
  }) {
    return 'يلا نتحدى بعض في مسابقة أرثوذكسيا أونلاين! 🏆\n'
        'الموضوع: $categoryLabel\n'
        'المضيف: $hostName\n'
        '🎮 كود الغرفة: $roomCode\n\n'
        'افتح تطبيق أرثوذكسيا ← المسابقات ← العب مع أصحابك ← اكتب الكود وادخل علطول!';
  }

  Future<(String?, String)> createFriendRoom({
    required List<int> candidateIndices,
    required int questionCount,
    required String categoryLabel,
  }) async {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) {
      return (null, 'سجّل دخولك الأول عشان تعمل غرفة أونلاين مع أصحابك.');
    }
    if (candidateIndices.length < 3) {
      return (null, 'مفيش أسئلة كافية في القسم ده.');
    }

    final shuffled = List<int>.from(candidateIndices)..shuffle(_rng);
    final picked = shuffled.take(questionCount.clamp(3, 15)).toList();

    try {
      String code = _generateRoomCode();
      for (int i = 0; i < 5; i++) {
        final exists = await db.collection('trivia_rooms').doc(code).get();
        if (!exists.exists) break;
        code = _generateRoomCode();
      }

      final myName = _myPlayerName();
      final roomRef = db.collection('trivia_rooms').doc(code);
      await roomRef.set({
        'roomCode': code,
        'hostUid': uid,
        'hostName': myName,
        'categoryLabel': SecurityGuardService.sanitizeText(categoryLabel, maxLength: 40, allowNewlines: false),
        'status': 'waiting',
        'questionIndices': picked,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await roomRef.collection('players').doc(uid).set({
        'uid': uid,
        'name': myName,
        'score': 0,
        'answeredCount': 0,
        'correctCount': 0,
        'finished': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return (code, 'اتعملت الغرفة ($code)! ابعت الكود لأصحابك وابدأوا التحدي 🏆');
    } catch (e) {
      if (kDebugMode) debugPrint('createFriendRoom err: $e');
      return (null, 'مش قادرين نعمل الغرفة دلوقتي. اتأكد من النت وحاول تاني.');
    }
  }

  Future<(String?, String)> joinFriendRoom(String rawCode) async {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) {
      return (null, 'سجّل دخولك الأول عشان تدخل غرفة صاحبك.');
    }
    final code = normalizeRoomCode(rawCode);
    if (code.length < 6) {
      return (null, 'اكتب كود الغرفة صح (مثال: OR-4829).');
    }

    try {
      final roomRef = db.collection('trivia_rooms').doc(code);
      final snap = await roomRef.get();
      if (!snap.exists || snap.data() == null) {
        return (null, 'ملقيناش غرفة بالكود ده ($code). اتأكد من صاحبك!');
      }
      final state = TriviaRoomState.fromMap(snap.id, snap.data()!);
      if (state.status == 'finished') {
        return (null, 'المسابقة في الغرفة دي خلصت خلاص — اعملوا غرفة جديدة!');
      }

      await roomRef.collection('players').doc(uid).set({
        'uid': uid,
        'name': _myPlayerName(),
        'score': 0,
        'answeredCount': 0,
        'correctCount': 0,
        'finished': false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return (code, 'دخلت غرفة ${state.hostName} بنجاح! استعد للتحدي 🔥');
    } catch (e) {
      if (kDebugMode) debugPrint('joinFriendRoom err: $e');
      return (null, 'مش قادرين ندخل الغرفة دلوقتي. اتأكد من النت وحاول تاني.');
    }
  }

  Future<bool> startFriendRoom(String roomCode) async {
    final db = _db;
    if (db == null) return false;
    try {
      await db.collection('trivia_rooms').doc(roomCode).update({
        'status': 'playing',
        'startedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateMyRoomScore({
    required String roomCode,
    required int score,
    required int answeredCount,
    required int correctCount,
    required bool finished,
  }) async {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) return;
    try {
      await db
          .collection('trivia_rooms')
          .doc(roomCode)
          .collection('players')
          .doc(uid)
          .set({
        'uid': uid,
        'name': _myPlayerName(),
        'score': score,
        'answeredCount': answeredCount,
        'correctCount': correctCount,
        'finished': finished,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Stream<TriviaRoomState?> watchRoom(String roomCode) {
    final db = _db;
    if (db == null || roomCode.isEmpty) return Stream.value(null);
    return db.collection('trivia_rooms').doc(roomCode).snapshots().map((s) {
      if (!s.exists || s.data() == null) return null;
      return TriviaRoomState.fromMap(s.id, s.data()!);
    });
  }

  Stream<List<TriviaRoomPlayer>> watchRoomPlayers(String roomCode) {
    final db = _db;
    if (db == null || roomCode.isEmpty) return Stream.value(const []);
    return db
        .collection('trivia_rooms')
        .doc(roomCode)
        .collection('players')
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((d) => TriviaRoomPlayer.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => b.score.compareTo(a.score));
      return list;
    });
  }

  // ===========================================================================
  // FREE DAILY ONLINE CHALLENGE LEADERBOARD
  // ===========================================================================

  Future<bool> submitDailyScore({
    required int score,
    required int correctCount,
    required int totalCount,
  }) async {
    final db = _db;
    final uid = currentUid;
    if (db == null || uid == null) return false;
    final dateKey = todayIso();
    try {
      final ref = db
          .collection('daily_trivia')
          .doc(dateKey)
          .collection('scores')
          .doc(uid);
      final existing = await ref.get();
      final prevScore = (existing.data()?['score'] as num?)?.toInt() ?? 0;
      if (existing.exists && prevScore >= score) return true;

      await ref.set({
        'uid': uid,
        'name': _myPlayerName(),
        'score': score.clamp(0, 2500),
        'correctCount': correctCount,
        'totalCount': totalCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('submitDailyScore err: $e');
      return false;
    }
  }

  Stream<List<DailyLeaderboardEntry>> watchTodayLeaderboard() {
    final db = _db;
    if (db == null) return Stream.value(const []);
    final dateKey = todayIso();
    return db
        .collection('daily_trivia')
        .doc(dateKey)
        .collection('scores')
        .orderBy('score', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => DailyLeaderboardEntry.fromMap(d.id, d.data()))
            .toList());
  }
}
