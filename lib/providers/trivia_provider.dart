import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/storage_service.dart';
import '../models/trivia_model.dart';

enum TriviaGameMode {
  endless('التحدي اللانهائي ♾️'),
  bibleDetective('من القائل / أي سفر؟ 📖'),
  liturgyRites('طقس القداس والسنكسار ☦️');

  final String label;
  const TriviaGameMode(this.label);
}

class TriviaProvider with ChangeNotifier {
  final Random _rng = Random();
  List<TriviaTier> _tiers = [];
  List<TriviaQuestion> _curatedQuestions = [];
  List<dynamic> _bibleBooksRaw = [];
  Map<String, dynamic>? _lectionaryRaw;

  TriviaGameMode _activeMode = TriviaGameMode.endless;
  TriviaQuestion? _currentQuestion;
  int _questionCounter = 1;
  int _score = 120;
  int _coins = 50;
  int _streak = 3;
  int _totalAnswered = 0;

  int? _selectedAnswerIndex;
  bool _isAnswered = false;
  Set<int> _hiddenOptions = {}; // For 50/50 lifeline
  bool _hintRevealed = false; // For Patristic Hint lifeline

  List<TriviaTier> get tiers => _tiers;
  TriviaGameMode get activeMode => _activeMode;
  TriviaQuestion? get currentQuestion => _currentQuestion;
  int get currentQuestionIndex => _questionCounter - 1;
  int get questionNumber => _questionCounter;
  int get score => _score;
  int get coins => _coins;
  int get streak => _streak;
  int get streakWeeks => _streak; // backwards compatibility
  int get totalAnswered => _totalAnswered;
  int? get selectedAnswerIndex => _selectedAnswerIndex;
  bool get isAnswered => _isAnswered;
  Set<int> get hiddenOptions => _hiddenOptions;
  bool get hintRevealed => _hintRevealed;

  // Backward-compatible list getter
  List<TriviaQuestion> get questions => _curatedQuestions;

  TriviaTier get currentTier {
    if (_tiers.isEmpty) {
      return TriviaTier(id: 'deacon_novice', name: 'شماس مبتدئ (إبصالتيس)', minScore: 0, badge: '🕯️');
    }
    TriviaTier tier = _tiers.first;
    for (var t in _tiers) {
      if (_score >= t.minScore) {
        tier = t;
      }
    }
    return tier;
  }

  TriviaTier? get nextTier {
    for (var t in _tiers) {
      if (t.minScore > _score) return t;
    }
    return null;
  }

  double get tierProgress {
    final curr = currentTier;
    final nxt = nextTier;
    if (nxt == null) return 1.0;
    final span = (nxt.minScore - curr.minScore).clamp(1, 100000);
    return ((_score - curr.minScore) / span).clamp(0.0, 1.0);
  }

  TriviaProvider() {
    _score = StorageService().getTriviaScore();
    _coins = StorageService().getTriviaCoins();
    _streak = StorageService().getTriviaStreak();
    _totalAnswered = StorageService().getTotalQuestionsAnswered();
    loadTriviaData();
  }

  Future<void> loadTriviaData() async {
    try {
      final raw = await rootBundle.loadString('assets/data/trivia.json');
      final data = jsonDecode(raw);
      _tiers = (data['tiers'] as List).map((t) => TriviaTier.fromJson(t)).toList();
      _curatedQuestions = (data['questions'] as List).map((q) => TriviaQuestion.fromJson(q)).toList();
      _curatedQuestions.shuffle(_rng);
      if (_curatedQuestions.isNotEmpty) {
        _currentQuestion = _curatedQuestions.first;
      }
      notifyListeners();

      // Load Bible & Lectionary in background for infinite dynamic question generation
      final bibleStr = await rootBundle.loadString('assets/data/bible.json');
      _bibleBooksRaw = jsonDecode(bibleStr) as List<dynamic>;

      final lectStr = await rootBundle.loadString('assets/data/synaxarium_ar.json');
      _lectionaryRaw = jsonDecode(lectStr) as Map<String, dynamic>;
      notifyListeners();
    } catch (e) {
      // Fallback
    }
  }

  void setGameMode(TriviaGameMode mode) {
    if (_activeMode == mode) return;
    _activeMode = mode;
    _questionCounter = 1;
    _generateNextInfiniteQuestion();
  }

  void selectAnswer(int index) {
    if (_isAnswered || _hiddenOptions.contains(index)) return;
    _selectedAnswerIndex = index;
    _isAnswered = true;
    _totalAnswered += 1;

    if (_currentQuestion != null && index == _currentQuestion!.correctIndex) {
      _streak += 1;
      final streakBonus = (_streak >= 5) ? 10 : 0;
      _score += 25 + streakBonus;
      _coins += 10;
    } else {
      _streak = 0;
    }

    StorageService().setTriviaScore(_score);
    StorageService().setTriviaCoins(_coins);
    StorageService().setTriviaStreak(_streak);
    StorageService().setTotalQuestionsAnswered(_totalAnswered);
    notifyListeners();
  }

  /// Lifeline 1: 50/50 (Removes 2 wrong options, costs 15 coins)
  bool useFiftyFifty() {
    if (_isAnswered || _hiddenOptions.isNotEmpty || _currentQuestion == null || _coins < 15) {
      return false;
    }
    _coins -= 15;
    StorageService().setTriviaCoins(_coins);

    final wrongIndices = <int>[];
    for (int i = 0; i < _currentQuestion!.options.length; i++) {
      if (i != _currentQuestion!.correctIndex) wrongIndices.add(i);
    }
    wrongIndices.shuffle(_rng);
    _hiddenOptions = wrongIndices.take(2).toSet();
    notifyListeners();
    return true;
  }

  /// Lifeline 2: Patristic Hint (Reveals explanation clue before answering, costs 10 coins)
  bool useHint() {
    if (_isAnswered || _hintRevealed || _currentQuestion == null || _coins < 10) {
      return false;
    }
    _coins -= 10;
    _hintRevealed = true;
    StorageService().setTriviaCoins(_coins);
    notifyListeners();
    return true;
  }

  /// Lifeline 3: Skip Question without losing streak (costs 10 coins)
  bool skipQuestion() {
    if (_isAnswered || _coins < 10) return false;
    _coins -= 10;
    StorageService().setTriviaCoins(_coins);
    nextQuestion();
    return true;
  }

  void nextQuestion() {
    _questionCounter += 1;
    _generateNextInfiniteQuestion();
  }

  void _generateNextInfiniteQuestion() {
    _selectedAnswerIndex = null;
    _isAnswered = false;
    _hiddenOptions = {};
    _hintRevealed = false;

    if (_activeMode == TriviaGameMode.bibleDetective && _bibleBooksRaw.isNotEmpty) {
      _currentQuestion = _generateDynamicBibleQuestion();
      notifyListeners();
      return;
    }

    if (_activeMode == TriviaGameMode.liturgyRites) {
      if (_rng.nextBool() && _lectionaryRaw != null) {
        _currentQuestion = _generateDynamicSynaxariumOrLectionaryQuestion();
      } else {
        final liturgicalPool = _curatedQuestions
            .where((q) => q.category != 'الكتاب المقدس')
            .toList();
        if (liturgicalPool.isNotEmpty) {
          _currentQuestion = liturgicalPool[_rng.nextInt(liturgicalPool.length)];
        }
      }
      notifyListeners();
      return;
    }

    // Endless Mode: Mix curated questions + dynamic Bible verses + dynamic Synaxarium/Katameros!
    final roll = _rng.nextInt(100);
    if (roll < 45 && _bibleBooksRaw.isNotEmpty) {
      _currentQuestion = _generateDynamicBibleQuestion();
    } else if (roll < 70 && _lectionaryRaw != null) {
      _currentQuestion = _generateDynamicSynaxariumOrLectionaryQuestion();
    } else if (_curatedQuestions.isNotEmpty) {
      _currentQuestion = _curatedQuestions[_rng.nextInt(_curatedQuestions.length)];
    }

    notifyListeners();
  }

  TriviaQuestion _generateDynamicBibleQuestion() {
    final typeRoll = _rng.nextInt(3);

    // Type A: Which book contains this authentic verse?
    if (typeRoll <= 1) {
      final bookIdx = _rng.nextInt(_bibleBooksRaw.length);
      final book = _bibleBooksRaw[bookIdx] as Map<String, dynamic>;
      final bookName = book['name'] as String;
      final chapters = book['chapters'] as List<dynamic>;
      final chIdx = _rng.nextInt(chapters.length);
      final verses = chapters[chIdx] as List<dynamic>;
      final vIdx = _rng.nextInt(verses.length);
      String verseText = '${verses[vIdx]}';
      if (verseText.length > 140) {
        verseText = '${verseText.substring(0, 140)}...';
      }

      final optionsSet = <String>{bookName};
      while (optionsSet.length < 4) {
        final rBook = _bibleBooksRaw[_rng.nextInt(_bibleBooksRaw.length)]['name'] as String;
        optionsSet.add(rBook);
      }
      final options = optionsSet.toList()..shuffle(_rng);
      final correctIdx = options.indexOf(bookName);

      return TriviaQuestion(
        id: 'dyn_bible_${DateTime.now().microsecondsSinceEpoch}',
        category: 'آيات الكتاب المقدس ♾️',
        difficulty: 'متجدد',
        question: 'في أي سفر من أسفار الكتاب المقدس وردت هذه الآية المباركة:\n«$verseText»؟',
        options: options,
        correctIndex: correctIdx,
        explanation: 'وردت هذه الآية في سفر $bookName (إصحاح ${chIdx + 1}: آية ${vIdx + 1}).',
      );
    }

    // Type B: How many chapters are in this Bible book?
    final bookIdx = _rng.nextInt(_bibleBooksRaw.length);
    final book = _bibleBooksRaw[bookIdx] as Map<String, dynamic>;
    final bookName = book['name'] as String;
    final chaptersCount = (book['chapters'] as List).length;
    final correctAnswer = '$chaptersCount إصحاح';

    final countsSet = <int>{chaptersCount};
    while (countsSet.length < 4) {
      final delta = _rng.nextInt(15) + 1;
      final candidate = (_rng.nextBool() ? chaptersCount + delta : (chaptersCount - delta).clamp(1, 150));
      if (candidate != chaptersCount) countsSet.add(candidate);
    }
    final options = countsSet.map((c) => '$c إصحاح').toList()..shuffle(_rng);
    final correctIdx = options.indexOf(correctAnswer);

    return TriviaQuestion(
      id: 'dyn_ch_${DateTime.now().microsecondsSinceEpoch}',
      category: 'علوم الكتاب المقدس ♾️',
      difficulty: 'متوسط',
      question: 'كم عدد إصحاحات سفر «$bookName» في الكتاب المقدس؟',
      options: options,
      correctIndex: correctIdx,
      explanation: 'يتكون سفر $bookName من $chaptersCount إصحاحاً في الكتاب المقدس.',
    );
  }

  TriviaQuestion _generateDynamicSynaxariumOrLectionaryQuestion() {
    final copticMonths = [
      'توت', 'بابه', 'هاتور', 'كيهك', 'طوبة', 'أمشير',
      'برمهات', 'برمودة', 'بشنس', 'بؤونة', 'أبيب', 'مسرى', 'النسيء'
    ];
    final synMap = _lectionaryRaw;
    if (synMap != null && synMap.isNotEmpty) {
      final keys = synMap.keys.toList();
      final randomKey = keys[_rng.nextInt(keys.length)];
      final parts = randomKey.split('-');
      final mNum = int.tryParse(parts[0]) ?? 1;
      final dNum = int.tryParse(parts[1]) ?? 1;
      final mName = copticMonths[(mNum - 1).clamp(0, 12)];
      final events = synMap[randomKey] as List<dynamic>;
      if (events.isNotEmpty) {
        final ev = events.first as Map<String, dynamic>;
        final rawTitle = '${ev['title'] ?? ''}'.trim();
        final correctDate = '$dNum $mName';
        final optionsSet = <String>{correctDate};
        while (optionsSet.length < 4) {
          final rm = copticMonths[_rng.nextInt(12)];
          final rd = _rng.nextInt(30) + 1;
          optionsSet.add('$rd $rm');
        }
        final options = optionsSet.toList()..shuffle(_rng);
        final correctIdx = options.indexOf(correctDate);

        return TriviaQuestion(
          id: 'dyn_syn_${DateTime.now().microsecondsSinceEpoch}',
          category: 'السنكسار القبطي ♾️',
          difficulty: 'متجدد',
          question: 'في أي يوم من أيام السنة القبطية تعيّد الكنيسة بتذكار:\n«$rawTitle»؟',
          options: options,
          correctIndex: correctIdx,
          explanation: 'تحتفل الكنيسة القبطية الأرثوذكسية بهذا التذكار المبارك في يوم $correctDate حسب السنكسار القبطي.',
        );
      }
    }

    return _curatedQuestions[_rng.nextInt(_curatedQuestions.length)];
  }
}
