/// A single AI-generated answer to an Islamic question.
class AiAnswer {
  final String question;
  final String answer;
  final String? category;
  final DateTime createdAt;

  AiAnswer({
    required this.question,
    required this.answer,
    this.category,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
        'question': question,
        'answer': answer,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AiAnswer.fromMap(Map<String, dynamic> map) => AiAnswer(
        question: map['question'] as String? ?? '',
        answer: map['answer'] as String? ?? '',
        category: map['category'] as String?,
        createdAt: map['createdAt'] != null
            ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

/// Abstraction over "ask an Islamic question, get an AI-generated answer".
///
/// This replaces the old human-Aalim flow (Masail submission / Live Q&A chat):
/// nobody has to be on call to answer questions, an AI model answers instead.
///
/// [AiFatwaService.instance] is swappable in one place. To wire in a real
/// backend later (recommended: a Firebase Cloud Function that calls the
/// Claude API server-side, so no AI provider key ships inside the app):
///
/// ```dart
/// AiFatwaService.instance = FirebaseFunctionsAiFatwaService();
/// ```
///
/// ...and implement a class that calls
/// `FirebaseFunctions.instance.httpsCallable('askIslamicQuestion')` (or
/// any other backend) inside [ask]. No UI code needs to change.
abstract class AiFatwaService {
  static AiFatwaService instance = PlaceholderAiFatwaService();

  Future<AiAnswer> ask(String question, {String? category});
}

/// Default implementation used until a real AI backend is wired in.
/// Returns immediately with a clear, honest placeholder answer instead of
/// pretending to give real Islamic guidance.
class PlaceholderAiFatwaService implements AiFatwaService {
  @override
  Future<AiAnswer> ask(String question, {String? category}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return AiAnswer(
      question: question,
      category: category,
      answer:
          "AI answering isn't connected yet in this build. Once a backend "
          "is wired in, your question${category != null ? ' about $category' : ''} "
          "will be answered here by an AI model that has researched authentic "
          "Islamic sources. As always, verify important rulings with a "
          "qualified scholar.",
    );
  }
}
