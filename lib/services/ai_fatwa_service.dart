import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:allah_everywhere/utils/utils/constraints/api_constants.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

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
/// [AiFatwaService.instance] is swappable in one place - see
/// [GeminiAiFatwaService] for the real backend, wired in `main.dart`.
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

/// Calls the Gemini API directly from the app (no server-side proxy - this
/// project stays on Firebase's free Spark plan, which doesn't support Cloud
/// Functions). [ApiConstant.geminiApiKey] is therefore shipped inside the
/// compiled app and is extractable by anyone who decompiles it; the key
/// should be restricted in Google Cloud Console to only the Generative
/// Language API and rotated periodically to limit the damage if it leaks.
class GeminiAiFatwaService implements AiFatwaService {
  // Verified live against the API - gemini-2.5-flash is deprecated for new
  // callers as of this writing (Google's own error names this replacement).
  static const _model = 'gemini-3.6-flash';
  static const _systemInstruction =
      'You are the "Ask AI" assistant inside Allah Everywhere, an Islamic '
      'app used by Muslims of varying backgrounds and madhabs. You answer '
      'questions about Islam: Quran, Hadith, Fiqh, Seerah, and everyday '
      'Islamic living.\n\n'
      'Rules:\n'
      '- Ground answers in the Quran and authentic Hadith where possible, '
      'and cite the reference (e.g. "Quran 2:183" or "Sahih al-Bukhari 1") '
      'when you do.\n'
      "- Where the major schools of thought (Hanafi, Shafi'i, Maliki, "
      'Hanbali) genuinely differ on a ruling, briefly note that rather than '
      'presenting only one view as the single correct answer.\n'
      '- Keep answers focused and readable on a phone screen - a few short '
      'paragraphs, not an essay, unless the question needs more.\n'
      '- For significant personal rulings (divorce, inheritance, major '
      'financial matters), remind the user to confirm with a qualified '
      'local scholar who knows their full situation.\n'
      '- If a question falls outside Islamic knowledge entirely, answer '
      'briefly and say so rather than guessing.\n'
      '- Be respectful of the questioner regardless of their level of '
      'practice or knowledge - never condescending.';

  @override
  Future<AiAnswer> ask(String question, {String? category}) async {
    final key = ApiConstant.geminiApiKey;
    if (key.isEmpty) {
      throw StateError(
          'GEMINI_API_KEY is not configured. Run with --dart-define=GEMINI_API_KEY=your_key_here');
    }

    final prompt = category != null ? 'Category: $category\nQuestion: $question' : question;
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$key',
    );

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'systemInstruction': {
              'parts': [
                {'text': _systemInstruction}
              ],
            },
            'contents': [
              {
                'role': 'user',
                'parts': [
                  {'text': prompt}
                ],
              }
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      VoidLogger.error('Gemini request failed: HTTP ${response.statusCode}', response.body);
      throw Exception('Could not get an answer right now. Please try again.');
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>?;
    String? answer;
    if (candidates != null && candidates.isNotEmpty) {
      final content = (candidates.first as Map<String, dynamic>)['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts != null && parts.isNotEmpty) {
        answer = (parts.first as Map<String, dynamic>)['text'] as String?;
        answer = answer?.trim();
      }
    }

    if (answer == null || answer.isEmpty) {
      throw Exception('Received an empty answer. Please try again.');
    }

    return AiAnswer(question: question, category: category, answer: answer);
  }
}
