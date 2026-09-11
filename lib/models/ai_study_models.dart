class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctOptionIndex: json['correctOptionIndex'] ?? 0,
      explanation: json['explanation'] ?? '',
    );
  }
}

class Flashcard {
  final String front;
  final String back;

  Flashcard({
    required this.front,
    required this.back,
  });

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      front: json['front'] ?? '',
      back: json['back'] ?? '',
    );
  }
}
