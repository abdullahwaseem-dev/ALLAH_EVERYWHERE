/// Masks obvious profanity in short user messages (Challenges chat). A
/// small list of common English words and romanised Urdu/Hindi insults; it
/// is a courtesy filter, not moderation (members can still report).
class ProfanityFilter {
  ProfanityFilter._();

  // Stems: any word that starts with one of these is masked.
  static const _stems = [
    'fuck', 'motherfuck', 'shit', 'bullshit', 'bitch', 'bastard', 'asshole', 'arsehole', 'cunt',
    'pussy', 'whore', 'slut', 'wank', 'twat', 'bollock', 'nigga', 'nigger', 'faggot', 'retard',
    'madarchod', 'maderchod', 'behenchod', 'bhenchod', 'benchod', 'bhosdi', 'chutiy', 'chootiy',
    'gaandu', 'gandu', 'randi', 'harami', 'kutti', 'kamina',
  ];

  // Masked only as the whole word ("prickly", "laudable" are fine).
  static const _exact = ['ass', 'arse', 'dick', 'dicks', 'prick', 'pricks', 'fk', 'fck', 'wtf', 'stfu', 'lund', 'lauda', 'lavda'];

  static final _word = RegExp(r"[A-Za-z']+");

  static bool _bad(String word) {
    final w = word.toLowerCase().replaceAll("'", '');
    return _exact.contains(w) || _stems.any(w.startsWith);
  }

  /// [text] with each offending word replaced by asterisks.
  static String clean(String text) =>
      text.replaceAllMapped(_word, (m) => _bad(m[0]!) ? '*' * m[0]!.length : m[0]!);

  static bool contains(String text) => _word.allMatches(text).any((m) => _bad(m[0]!));
}
