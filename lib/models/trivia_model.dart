class TriviaTier {
  final String id;
  final String name;
  final int minScore;
  final String badge;

  TriviaTier({
    required this.id,
    required this.name,
    required this.minScore,
    required this.badge,
  });

  factory TriviaTier.fromJson(Map<String, dynamic> json) {
    return TriviaTier(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      minScore: json['min_score'] ?? 0,
      badge: json['badge'] ?? '🌱',
    );
  }
}

class TriviaQuestion {
  final String id;
  final String category;
  final String difficulty;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  TriviaQuestion({
    required this.id,
    required this.category,
    required this.difficulty,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  factory TriviaQuestion.fromJson(Map<String, dynamic> json) {
    return TriviaQuestion(
      id: json['id'] ?? '',
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? 'متوسط',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctIndex: json['correct_index'] ?? 0,
      explanation: json['explanation'] ?? '',
    );
  }
}
