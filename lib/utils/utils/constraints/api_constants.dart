class ApiConstant {
  /// Supplied at build time: `flutter run --dart-define=HADITH_API_KEY=your_key_here`.
  /// Get a key from https://hadithapi.com - never hardcode it in source.
  static const String hadithApiKey = String.fromEnvironment('HADITH_API_KEY');
}