import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/services/multiplayer_trivia_service.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/luxe_widgets.dart';
import '../../models/trivia_model.dart';
import '../onboarding/auth_view.dart';

/// 100% FREE Live Online Multiplayer Trivia with Friends (Private Room Code `OR-XXXX`)
/// + Free Daily Online Challenge & Top 20 Leaderboard across Egypt!
class OnlineTriviaArenaView extends StatefulWidget {
  final int initialTab; // 0 = مع أصحابك | 1 = التحدي اليومي
  const OnlineTriviaArenaView({super.key, this.initialTab = 0});

  @override
  State<OnlineTriviaArenaView> createState() => _OnlineTriviaArenaViewState();
}

class _OnlineTriviaArenaViewState extends State<OnlineTriviaArenaView>
    with SingleTickerProviderStateMixin {
  final MultiplayerTriviaService _service = MultiplayerTriviaService();
  late final TabController _tabCtrl;

  List<TriviaQuestion> _pool = [];
  bool _loadingPool = true;

  // Friend Room State
  final TextEditingController _joinCodeCtrl = TextEditingController();
  String _selectedCat = 'الكل';
  int _selectedQCount = 8;
  bool _busyRoom = false;
  String? _activeRoomCode;
  int _roomQIndex = 0;
  int _roomScore = 0;
  int _roomCorrect = 0;
  int? _roomSelectedOpt;
  bool _roomFinished = false;
  DateTime _questionStartedAt = DateTime.now();

  // Daily Online Challenge State
  bool _playingDaily = false;
  List<int> _dailyIndices = [];
  int _dailyIdx = 0;
  int _dailyScore = 0;
  int _dailyCorrect = 0;
  int? _dailySelectedOpt;
  bool _dailyFinished = false;

  static const _categories = <String>[
    'الكل',
    'تلمذة الشمامسة والألحان',
    'الكتاب المقدس',
    'طقوس الكنيسة',
    'سير القديسين والآباء',
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this, initialIndex: widget.initialTab.clamp(0, 1));
    _loadPool();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _joinCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPool() async {
    try {
      final raw = await rootBundle.loadString('assets/data/trivia.json');
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final list = (decoded['questions'] as List)
          .map((q) => TriviaQuestion.fromJson(q as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _pool = list;
          _dailyIndices = MultiplayerTriviaService.dailyQuestionIndices(list.length, count: 10);
          _loadingPool = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPool = false);
    }
  }

  List<int> _candidateIndicesForCategory() {
    if (_selectedCat == 'الكل') {
      return List<int>.generate(_pool.length, (i) => i);
    }
    final matched = <int>[];
    for (int i = 0; i < _pool.length; i++) {
      if (_pool[i].category.contains(_selectedCat) ||
          (_selectedCat == 'تلمذة الشمامسة والألحان' &&
              (_pool[i].category.contains('ألحان') || _pool[i].category.contains('شمامسة')))) {
        matched.add(i);
      }
    }
    return matched.length >= 5 ? matched : List<int>.generate(_pool.length, (i) => i);
  }

  Future<void> _createRoom() async {
    if (_service.currentUid == null) {
      _promptLogin();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _busyRoom = true);
    final (code, msg) = await _service.createFriendRoom(
      candidateIndices: _candidateIndicesForCategory(),
      questionCount: _selectedQCount,
      categoryLabel: _selectedCat == 'الكل' ? 'تحدي شامل' : _selectedCat,
    );
    if (!mounted) return;
    setState(() {
      _busyRoom = false;
      if (code != null) {
        _activeRoomCode = code;
        _resetLocalRoomProgress();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.cairo())),
    );
  }

  Future<void> _joinRoom() async {
    if (_service.currentUid == null) {
      _promptLogin();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _busyRoom = true);
    final (code, msg) = await _service.joinFriendRoom(_joinCodeCtrl.text);
    if (!mounted) return;
    setState(() {
      _busyRoom = false;
      if (code != null) {
        _activeRoomCode = code;
        _joinCodeCtrl.clear();
        _resetLocalRoomProgress();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: GoogleFonts.cairo())),
    );
  }

  void _resetLocalRoomProgress() {
    _roomQIndex = 0;
    _roomScore = 0;
    _roomCorrect = 0;
    _roomSelectedOpt = null;
    _roomFinished = false;
    _questionStartedAt = DateTime.now();
  }

  void _promptLogin() {
    final p = context.palette;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text(
          'سجّل دخول عشان تلعب أونلاين 🎮',
          style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.bold, color: p.ink),
        ),
        content: Text(
          'اللعب أونلاين مع أصحابك والتحدي اليومي مجاني ١٠٠٪ — محتاجين بس تسجيل دخول عشان اسمك ونقاطك تظهر في الغرفة ولوحة المتصدرين.',
          style: GoogleFonts.cairo(fontSize: 13, color: p.inkSecondary, height: 1.55),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('بعدين', style: GoogleFonts.cairo(color: p.inkMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, luxeRoute(const AuthView()));
            },
            child: const Text('تسجيل الدخول'),
          ),
        ],
      ),
    );
  }

  Future<void> _answerRoomQuestion(TriviaRoomState room, int optIdx) async {
    if (_roomSelectedOpt != null) return;
    final qPoolIdx = room.questionIndices[_roomQIndex].clamp(0, _pool.length - 1);
    final q = _pool[qPoolIdx];
    final isCorrect = optIdx == q.correctIndex;
    final elapsedSec = DateTime.now().difference(_questionStartedAt).inSeconds;
    final speedBonus = isCorrect ? (20 - elapsedSec).clamp(0, 20) * 3 : 0;
    final gained = isCorrect ? (100 + speedBonus) : 0;

    HapticFeedback.lightImpact();
    final nextScore = _roomScore + gained;
    final nextCorrect = _roomCorrect + (isCorrect ? 1 : 0);
    final isLast = _roomQIndex + 1 >= room.questionIndices.length;

    setState(() {
      _roomSelectedOpt = optIdx;
      _roomScore = nextScore;
      _roomCorrect = nextCorrect;
    });

    await _service.updateMyRoomScore(
      roomCode: room.roomCode,
      score: nextScore,
      answeredCount: _roomQIndex + 1,
      correctCount: nextCorrect,
      finished: isLast,
    );
  }

  void _nextRoomQuestion(TriviaRoomState room) {
    if (_roomQIndex + 1 >= room.questionIndices.length) {
      setState(() => _roomFinished = true);
    } else {
      setState(() {
        _roomQIndex++;
        _roomSelectedOpt = null;
        _questionStartedAt = DateTime.now();
      });
    }
  }

  Future<void> _answerDailyQuestion(int optIdx) async {
    if (_dailySelectedOpt != null) return;
    final q = _pool[_dailyIndices[_dailyIdx].clamp(0, _pool.length - 1)];
    final isCorrect = optIdx == q.correctIndex;
    final elapsedSec = DateTime.now().difference(_questionStartedAt).inSeconds;
    final speedBonus = isCorrect ? (20 - elapsedSec).clamp(0, 20) * 3 : 0;
    final gained = isCorrect ? (100 + speedBonus) : 0;

    HapticFeedback.lightImpact();
    setState(() {
      _dailySelectedOpt = optIdx;
      _dailyScore += gained;
      if (isCorrect) _dailyCorrect++;
    });
  }

  Future<void> _nextDailyQuestion() async {
    if (_dailyIdx + 1 >= _dailyIndices.length) {
      setState(() => _dailyFinished = true);
      if (_service.currentUid != null) {
        await _service.submitDailyScore(
          score: _dailyScore,
          correctCount: _dailyCorrect,
          totalCount: _dailyIndices.length,
        );
      }
    } else {
      setState(() {
        _dailyIdx++;
        _dailySelectedOpt = null;
        _questionStartedAt = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.canvas,
      appBar: AppBar(
        backgroundColor: p.canvas,
        foregroundColor: p.ink,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المسابقات أونلاين ومع أصحابك',
              style: GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 22, color: p.ink, height: 1.15),
            ),
            Text(
              'مجانية ١٠٠٪ • تنافس مباشر مع أصحابك أو في التحدي اليومي',
              style: GoogleFonts.cairo(fontSize: 10.5, color: p.inkMuted),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: p.gold,
          labelColor: p.ink,
          unselectedLabelColor: p.inkMuted,
          labelStyle: GoogleFonts.cairo(fontSize: 12.5, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'العب مع أصحابك 🎮'),
            Tab(text: 'التحدي اليومي 🏆'),
          ],
        ),
      ),
      body: _loadingPool
          ? Center(child: CircularProgressIndicator(color: p.gold, strokeWidth: 2))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildFriendsTab(p),
                _buildDailyTab(p),
              ],
            ),
    );
  }

  // ===========================================================================
  // TAB 1: LIVE FRIENDS PRIVATE ROOM (`OR-XXXX`)
  // ===========================================================================

  Widget _buildFriendsTab(AppPalette p) {
    if (_activeRoomCode != null) {
      return _buildActiveFriendRoom(p, _activeRoomCode!);
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
          children: [
            // Join Friend's Room Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.goldSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: p.goldBorder, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'عندك كود غرفة من صاحبك؟',
                    style: GoogleFonts.amiri(fontSize: 21, fontWeight: FontWeight.bold, color: p.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اكتب الكود هنا وادخل معاهم المسابقة لايف علطول:',
                    style: GoogleFonts.cairo(fontSize: 12, color: p.inkSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _joinCodeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          style: GoogleFonts.cairo(
                            color: p.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.4,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'مثال: OR-4829',
                            prefixIcon: Icon(Icons.vpn_key_outlined, size: 19),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _busyRoom ? null : _joinRoom,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: p.gold,
                          foregroundColor: const Color(0xFF19130A),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                        ),
                        child: Text('دخول', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Create New Room Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: p.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'أو اعمل غرفة جديدة واعزم أصحابك / أسرتك 🎉',
                    style: GoogleFonts.amiri(fontSize: 21, fontWeight: FontWeight.bold, color: p.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اختار الموضوع وعدد الأسئلة، هيطلعلك كود تبعته على واتساب والكل يدخل يتنافس على نفس الأسئلة في وقت واحد!',
                    style: GoogleFonts.cairo(fontSize: 12, color: p.inkSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'موضوع المسابقة:',
                    style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: p.ink),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: _categories.map((cat) {
                      final sel = _selectedCat == cat;
                      return ChoiceChip(
                        selected: sel,
                        selectedColor: p.gold,
                        backgroundColor: p.surfaceSubtle,
                        label: Text(
                          cat,
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: sel ? const Color(0xFF19130A) : p.ink,
                          ),
                        ),
                        onSelected: (_) => setState(() => _selectedCat = cat),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'عدد الأسئلة:',
                    style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: p.ink),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [5, 8, 10, 15].map((cnt) {
                      final sel = _selectedQCount == cnt;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ChoiceChip(
                            showCheckmark: false,
                            selected: sel,
                            selectedColor: p.accent,
                            backgroundColor: p.surfaceSubtle,
                            label: Center(
                              child: Text(
                                '$cnt',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  color: sel ? p.onAccent : p.ink,
                                ),
                              ),
                            ),
                            onSelected: (_) => setState(() => _selectedQCount = cnt),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _busyRoom ? null : _createRoom,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.accent,
                      foregroundColor: p.onAccent,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _busyRoom
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: p.onAccent),
                          )
                        : const Icon(Icons.groups_rounded, size: 20),
                    label: Text(
                      'اعمل غرفة جديدة وطلّع الكود',
                      style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFriendRoom(AppPalette p, String roomCode) {
    return StreamBuilder<TriviaRoomState?>(
      stream: _service.watchRoom(roomCode),
      builder: (context, roomSnap) {
        final room = roomSnap.data;
        if (roomSnap.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: p.gold, strokeWidth: 2));
        }
        if (room == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('الغرفة مش موجودة أو اتقفلت.', style: GoogleFonts.cairo(color: p.inkMuted)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => setState(() => _activeRoomCode = null),
                  child: const Text('رجوع'),
                ),
              ],
            ),
          );
        }

        final isHost = room.hostUid == _service.currentUid;

        return StreamBuilder<List<TriviaRoomPlayer>>(
          stream: _service.watchRoomPlayers(roomCode),
          builder: (context, playersSnap) {
            final players = playersSnap.data ?? [];

            // A) WAITING LOBBY
            if (room.status == 'waiting') {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: p.goldSoft,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: p.goldBorder, width: 1.4),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'كود الغرفة (ابعته لأصحابك)',
                              style: GoogleFonts.cairo(fontSize: 12, color: p.inkSecondary),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              room.roomCode,
                              style: GoogleFonts.cairo(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: p.ink,
                                letterSpacing: 3.0,
                              ),
                            ),
                            Text(
                              '${room.categoryLabel} • ${room.questionIndices.length} أسئلة',
                              style: GoogleFonts.cairo(fontSize: 12, color: p.accent, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      SharePlus.instance.share(
                                        ShareParams(
                                          text: MultiplayerTriviaService.buildFriendRoomShareText(
                                            hostName: room.hostName,
                                            roomCode: room.roomCode,
                                            categoryLabel: room.categoryLabel,
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: p.gold,
                                      foregroundColor: const Color(0xFF19130A),
                                    ),
                                    icon: const Icon(Icons.share_rounded, size: 18),
                                    label: Text('شير على واتساب', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton(
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: room.roomCode));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('اتنسخ الكود ${room.roomCode}', style: GoogleFonts.cairo())),
                                    );
                                  },
                                  child: const Icon(Icons.copy_rounded, size: 18),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'اللاعبين اللي دخلوا الغرفة (${players.length}):',
                        style: GoogleFonts.amiri(fontSize: 20, fontWeight: FontWeight.bold, color: p.ink),
                      ),
                      const SizedBox(height: 8),
                      ...players.map((pl) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: p.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: p.border),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.person_rounded, size: 20, color: p.gold),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    pl.name,
                                    style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.bold, color: p.ink),
                                  ),
                                ),
                                if (pl.uid == room.hostUid)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: p.goldSoft,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'المضيف 👑',
                                      style: GoogleFonts.cairo(fontSize: 10.5, fontWeight: FontWeight.bold, color: p.gold),
                                    ),
                                  ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 16),
                      if (isHost)
                        ElevatedButton.icon(
                          onPressed: () {
                            _resetLocalRoomProgress();
                            _service.startFriendRoom(room.roomCode);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: p.sage,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 22),
                          label: Text(
                            'ابدأ المسابقة دلوقتي للكل! 🚀',
                            style: GoogleFonts.cairo(fontSize: 14.5, fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: p.surfaceSubtle,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'مستنيين ${room.hostName} يضغط «ابدأ المسابقة» وهتبدأ عند الكل في نفس اللحظة 🔥',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.cairo(fontSize: 12.5, color: p.inkSecondary),
                          ),
                        ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => setState(() => _activeRoomCode = null),
                        child: Text('الخروج من الغرفة', style: GoogleFonts.cairo(color: p.danger)),
                      ),
                    ],
                  ),
                ),
              );
            }

            // B) FINISHED PODIUM + LIVE SCORES
            if (_roomFinished || room.status == 'finished') {
              return _buildRoomResultsPodium(p, room, players);
            }

            // C) LIVE SYNCHRONIZED MATCH
            final qIdx = room.questionIndices[_roomQIndex].clamp(0, _pool.length - 1);
            final q = _pool[qIdx];
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 36),
                  children: [
                    // Compact Live Mini-Scoreboard of all friends
                    SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: players.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final pl = players[i];
                          final isMe = pl.uid == _service.currentUid;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              color: isMe ? p.goldSoft : p.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isMe ? p.gold : p.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  i == 0 ? '🥇' : (i == 1 ? '🥈' : (i == 2 ? '🥉' : '#${i + 1}')),
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '${pl.name.split(' ').first}: ${pl.score}',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: p.ink,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildQuestionCard(
                      p: p,
                      question: q,
                      stepLabel: 'سؤال ${_roomQIndex + 1} من ${room.questionIndices.length}',
                      scoreLabel: 'نقاطك: $_roomScore',
                      selectedOpt: _roomSelectedOpt,
                      onSelect: (idx) => _answerRoomQuestion(room, idx),
                      onNext: () => _nextRoomQuestion(room),
                      isLast: _roomQIndex + 1 >= room.questionIndices.length,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoomResultsPodium(AppPalette p, TriviaRoomState room, List<TriviaRoomPlayer> players) {
    final winner = players.isNotEmpty ? players.first : null;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D1C12), Color(0xFF19120C)],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE5C175), width: 1.5),
              ),
              child: Column(
                children: [
                  const Text('🏆', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 6),
                  Text(
                    winner != null ? 'المركز الأول: ${winner.name}!' : 'انتهت المسابقة!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.amiri(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF6DC9F),
                    ),
                  ),
                  Text(
                    'نتيجتك: $_roomScore نقطة ($_roomCorrect / ${room.questionIndices.length} إجابة صح)',
                    style: GoogleFonts.cairo(fontSize: 12.5, color: const Color(0xFFDDCBB0)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'ترتيب الأصدقاء المباشر:',
              style: GoogleFonts.amiri(fontSize: 20, fontWeight: FontWeight.bold, color: p.ink),
            ),
            const SizedBox(height: 8),
            ...List.generate(players.length, (i) {
              final pl = players[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: i == 0 ? p.goldSoft : p.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: i == 0 ? p.gold : p.border),
                ),
                child: Row(
                  children: [
                    Text(
                      i == 0 ? '🥇' : (i == 1 ? '🥈' : (i == 2 ? '🥉' : '${i + 1}.')),
                      style: GoogleFonts.cairo(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pl.name,
                            style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.bold, color: p.ink),
                          ),
                          Text(
                            pl.finished
                                ? 'خلص المسابقة (${pl.correctCount} صح)'
                                : 'لسه بيلعب (${pl.answeredCount}/${room.questionIndices.length})',
                            style: GoogleFonts.cairo(fontSize: 11, color: p.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${pl.score} نقطة',
                      style: GoogleFonts.cairo(fontSize: 14, fontWeight: FontWeight.w800, color: p.gold),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () => setState(() => _activeRoomCode = null),
              icon: const Icon(Icons.replay_rounded, size: 19),
              label: Text('العب غرفة جديدة مع أصحابك', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // TAB 2: FREE DAILY ONLINE CHALLENGE + LIVE LEADERBOARD
  // ===========================================================================

  Widget _buildDailyTab(AppPalette p) {
    if (_playingDaily && !_dailyFinished && _dailyIndices.isNotEmpty) {
      final q = _pool[_dailyIndices[_dailyIdx].clamp(0, _pool.length - 1)];
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
            children: [
              _buildQuestionCard(
                p: p,
                question: q,
                stepLabel: 'التحدي اليومي • ${_dailyIdx + 1} / ${_dailyIndices.length}',
                scoreLabel: 'نقاطك: $_dailyScore',
                selectedOpt: _dailySelectedOpt,
                onSelect: _answerDailyQuestion,
                onNext: _nextDailyQuestion,
                isLast: _dailyIdx + 1 >= _dailyIndices.length,
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: p.goldSoft,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: p.goldBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _dailyFinished
                        ? 'عاش يا بطل! خلّصت تحدي النهاردة 🎉'
                        : 'تحدي أرثوذكسيا اليومي أونلاين 🏆',
                    style: GoogleFonts.amiri(fontSize: 22, fontWeight: FontWeight.bold, color: p.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dailyFinished
                        ? 'جبت $_dailyScore نقطة ($_dailyCorrect من ${_dailyIndices.length} صح) واتسجّلت في لوحة المتصدرين!'
                        : 'نفس الـ ١٠ أسئلة لكل الناس النهاردة — جاوب أسرع عشان تاخد بونص سرعة وتطلع الأول على لوحة المتصدرين!',
                    style: GoogleFonts.cairo(fontSize: 12.5, color: p.inkSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _playingDaily = true;
                        _dailyFinished = false;
                        _dailyIdx = 0;
                        _dailyScore = 0;
                        _dailyCorrect = 0;
                        _dailySelectedOpt = null;
                        _questionStartedAt = DateTime.now();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: p.gold,
                      foregroundColor: const Color(0xFF19130A),
                    ),
                    icon: const Icon(Icons.bolt_rounded, size: 20),
                    label: Text(
                      _dailyFinished ? 'العب تحدي النهاردة تاني' : 'ابدأ تحدي النهاردة (١٠ أسئلة)',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'أبطال النهاردة (${MultiplayerTriviaService.todayIso()})',
              style: GoogleFonts.amiri(fontSize: 21, fontWeight: FontWeight.bold, color: p.ink),
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<DailyLeaderboardEntry>>(
              stream: _service.watchTodayLeaderboard(),
              builder: (_, snap) {
                final list = snap.data ?? [];
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                if (list.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: p.border),
                    ),
                    child: Text(
                      'خليك أول واحد يلعب تحدي النهاردة ويتصدر القائمة! 🏆',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(fontSize: 13, color: p.inkMuted),
                    ),
                  );
                }
                return Column(
                  children: List.generate(list.length, (i) {
                    final e = list[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 7),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: i == 0 ? p.goldSoft : p.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: i == 0 ? p.gold : p.border),
                      ),
                      child: Row(
                        children: [
                          Text(
                            i == 0 ? '🥇' : (i == 1 ? '🥈' : (i == 2 ? '🥉' : '#${i + 1}')),
                            style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e.name,
                              style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.bold, color: p.ink),
                            ),
                          ),
                          Text(
                            '${e.score} نقطة',
                            style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w800, color: p.gold),
                          ),
                        ],
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard({
    required AppPalette p,
    required TriviaQuestion question,
    required String stepLabel,
    required String scoreLabel,
    required int? selectedOpt,
    required void Function(int) onSelect,
    required VoidCallback onNext,
    required bool isLast,
  }) {
    final answered = selectedOpt != null;
    const letters = ['أ', 'ب', 'ج', 'د'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.goldBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(stepLabel, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: p.accent)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: p.goldSoft, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  scoreLabel,
                  style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: p.gold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            question.question,
            style: GoogleFonts.amiri(fontSize: 21, fontWeight: FontWeight.bold, color: p.ink, height: 1.45),
          ),
          const SizedBox(height: 14),
          ...List.generate(question.options.length, (i) {
            final isRight = i == question.correctIndex;
            final isPicked = selectedOpt == i;
            Color bg = p.surfaceSubtle;
            Color border = p.border;
            if (answered) {
              if (isRight) {
                bg = p.sage.withValues(alpha: 0.16);
                border = p.sage;
              } else if (isPicked) {
                bg = p.danger.withValues(alpha: 0.14);
                border = p.danger;
              }
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: answered ? null : () => onSelect(i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border, width: answered && (isRight || isPicked) ? 1.5 : 1),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: p.surface,
                        child: Text(
                          letters[i % 4],
                          style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: p.ink),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          question.options[i],
                          style: GoogleFonts.cairo(fontSize: 13.5, fontWeight: FontWeight.w600, color: p.ink),
                        ),
                      ),
                      if (answered && isRight) Icon(Icons.check_circle_rounded, color: p.sage, size: 20),
                      if (answered && isPicked && !isRight) Icon(Icons.cancel_rounded, color: p.danger, size: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (answered) ...[
            if (question.explanation.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: p.goldSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  question.explanation,
                  style: GoogleFonts.cairo(fontSize: 12, color: p.inkSecondary, height: 1.5),
                ),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onNext,
              icon: Icon(isLast ? Icons.emoji_events_rounded : Icons.arrow_back_rounded, size: 19),
              label: Text(
                isLast ? 'عرض النتيجة والترتيب 🏆' : 'السؤال اللي بعده',
                style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
