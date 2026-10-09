import 'dart:async';
import 'dart:convert';
import 'dart:io';
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

/// Why a question could not be answered. The Ask AI screen turns this into
/// a localized message, so the service and controller stay UI-free.
enum AiErrorKind {
  /// No connection, or the request never reached Google.
  offline,

  /// Every model was overloaded (HTTP 503/429/500) or too slow. Temporary.
  busy,

  /// The model returned no text (e.g. blocked by its safety filter).
  noAnswer,

  /// Bad or missing API key, or another non-temporary API error.
  unavailable,
}

class AiServiceException implements Exception {
  final AiErrorKind kind;
  final String detail;

  AiServiceException(this.kind, this.detail);

  @override
  String toString() => 'AiServiceException($kind): $detail';
}

/// Calls the Gemini API directly from the app (no server-side proxy - this
/// project stays on Firebase's free Spark plan, which doesn't support Cloud
/// Functions). [ApiConstant.geminiApiKey] is therefore shipped inside the
/// compiled app and is extractable by anyone who decompiles it; the key
/// should be restricted in Google Cloud Console to only the Generative
/// Language API and rotated periodically to limit the damage if it leaks.
class GeminiAiFatwaService implements AiFatwaService {
  // Tried in order. Gemini regularly answers "This model is currently
  // experiencing high demand" (HTTP 503) - sometimes only after ~50 s - and
  // the app used to give up on the first model, so many questions got no
  // answer. Falling through to lighter models keeps answers coming; the
  // lite models are the least likely to be overloaded.
  static const _models = [
    'gemini-3.6-flash',
    'gemini-3.5-flash',
    'gemini-3.5-flash-lite',
    'gemini-3.1-flash-lite',
  ];

  // Per-model wait before moving on to the next model.
  static const _attemptTimeout = Duration(seconds: 20);

  // After a fallback model answers, start there for a while instead of
  // waiting on the overloaded primary for every question.
  static const _stickyFor = Duration(minutes: 10);
  static int _preferredIndex = 0;
  static DateTime? _preferredSince;

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
      throw AiServiceException(AiErrorKind.unavailable,
          'GEMINI_API_KEY is not configured. Run with --dart-define=GEMINI_API_KEY=your_key_here');
    }

    final prompt = category != null ? 'Category: $category\nQuestion: $question' : question;
    final body = json.encode({
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
    });

    final since = _preferredSince;
    if (since == null || DateTime.now().difference(since) > _stickyFor) _preferredIndex = 0;

    AiServiceException? lastError;
    // Start at the preferred model, then wrap around so every model gets
    // one try per question.
    for (var step = 0; step < _models.length; step++) {
      final i = (_preferredIndex + step) % _models.length;
      try {
        final answer = await _askModel(_models[i], key, body);
        if (i != _preferredIndex) {
          _preferredIndex = i;
          _preferredSince = DateTime.now();
        }
        return AiAnswer(question: question, category: category, answer: answer);
      } on AiServiceException catch (e) {
        lastError = e;
        // Only temporary problems are worth trying another model for.
        if (e.kind != AiErrorKind.busy) rethrow;
        VoidLogger.warning('Gemini model ${_models[i]} unavailable (${e.detail}), trying the next one');
      }
    }
    throw lastError ?? AiServiceException(AiErrorKind.busy, 'No model answered');
  }

  Future<String> _askModel(String model, String key, String body) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key',
    );

    final http.Response response;
    try {
      response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(_attemptTimeout);
    } on TimeoutException {
      throw AiServiceException(AiErrorKind.busy, '$model timed out');
    } on SocketException catch (e) {
      throw AiServiceException(AiErrorKind.offline, e.message);
    } on http.ClientException catch (e) {
      throw AiServiceException(AiErrorKind.offline, e.message);
    }

    if (response.statusCode != 200) {
      VoidLogger.error('Gemini request to $model failed: HTTP ${response.statusCode}', response.body);
      // 404: model retired for this key - the next model may still work.
      const retryable = {404, 408, 429, 500, 502, 503, 504};
      throw AiServiceException(
        retryable.contains(response.statusCode) ? AiErrorKind.busy : AiErrorKind.unavailable,
        '$model HTTP ${response.statusCode}',
      );
    }

    final String? answer;
    try {
      answer = _extractText(json.decode(response.body));
    } on FormatException catch (e) {
      throw AiServiceException(AiErrorKind.busy, '$model returned invalid JSON: ${e.message}');
    }
    if (answer == null || answer.isEmpty) {
      throw AiServiceException(AiErrorKind.noAnswer, '$model returned no text');
    }
    return answer;
  }

  /// Joins every non-thought text part of the first candidate. Newer models
  /// can split an answer over several parts (or lead with a "thought" part),
  /// so reading only parts.first could drop the answer.
  static String? _extractText(Object? decoded) {
    if (decoded is! Map) return null;
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty || candidates.first is! Map) return null;
    final content = (candidates.first as Map)['content'];
    final parts = content is Map ? content['parts'] : null;
    if (parts is! List) return null;
    final text = parts
        .whereType<Map>()
        .where((part) => part['thought'] != true)
        .map((part) => part['text'])
        .whereType<String>()
        .join();
    return text.trim();
  }
}
