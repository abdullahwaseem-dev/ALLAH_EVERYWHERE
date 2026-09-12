class ApiConstant {
  /// Supplied at build time: `flutter run --dart-define=HADITH_API_KEY=your_key_here`.
  /// Get a key from https://hadithapi.com - never hardcode it in source.
  static const String hadithApiKey = String.fromEnvironment('HADITH_API_KEY');

  /// Supplied at build time: `flutter run --dart-define=GEMINI_API_KEY=your_key_here`.
  /// Get a key from https://aistudio.google.com/apikey - never hardcode it in
  /// source. Called directly from the client (no server-side proxy), so this
  /// key is extractable from the compiled app by anyone who decompiles it -
  /// restrict it in Google Cloud Console to only the Generative Language API
  /// to limit the blast radius if it leaks, and rotate it periodically.
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
}