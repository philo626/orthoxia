import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/services/infinite_trivia_engine.dart';
import '../core/services/storage_service.dart';
import '../models/trivia_model.dart';

enum TriviaGameMode {
  endless('تحدي لا نهائي ∞'),
  bibleDetective('الكتاب المقدس وأكمل الآية'),
  deaconsHymns('تلمذة الشمامسة والألحان'),
  liturgyRites('الطقس والسنكسار والآباء');

  final String label;
  const TriviaGameMode(this.label);
}

class TriviaProvider with ChangeNotifier {
  final Random _rng = Random();
  final InfiniteTriviaEngine _engine = InfiniteTriviaEngine();
  final Set<String> _seenQuestions = {};
  List<TriviaTier> _tiers = [];
  List<TriviaQuestion> _curatedQuestions = [];

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

      // Load infinite multi-source Orthodox engine (35,000+ verses/hymns/saints/sayings!)
      await _engine.ensureLoaded();
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

    final categoryKey = switch (_activeMode) {
      TriviaGameMode.bibleDetective => 'الكتاب المقدس',
      TriviaGameMode.deaconsHymns => 'تلمذة الشمامسة والألحان',
      TriviaGameMode.liturgyRites => 'سير القديسين والآباء',
      TriviaGameMode.endless => 'الكل',
    };

    if (_engine.isLoaded) {
      final q = _engine.nextQuestion(
        rng: _rng,
        category: categoryKey,
        seenQuestions: _seenQuestions,
      );
      if (q != null) {
        _seenQuestions.add(q.question);
        if (_seenQuestions.length > 500) {
          _seenQuestions.remove(_seenQuestions.first);
        }
        _currentQuestion = q;
        notifyListeners();
        return;
      }
    }

    if (_curatedQuestions.isNotEmpty) {
      _currentQuestion = _curatedQuestions[_rng.nextInt(_curatedQuestions.length)];
    }
    notifyListeners();
  }
}
