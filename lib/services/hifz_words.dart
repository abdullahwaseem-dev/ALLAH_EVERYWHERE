/// "Test yourself": hides the words of an ayah at increasing levels. Pure
/// Dart, working on the Quran text from the `quran` package.
enum HideLevel {
  /// Everything visible.
  none,

  /// Each word shows only its first letter.
  firstLetters,

  /// Every other word hidden.
  everyOther,

  /// All words hidden.
  all,
}

/// One word of an ayah and how it's shown at a given level.
class HifzWord {
  final String text;

  /// Pause and ornament marks (ۚ ۖ ۗ ...) that stand alone between words;
  /// always shown, never counted as a word to hide.
  final bool isMark;

  const HifzWord(this.text, {this.isMark = false});
}

final RegExp _letter = RegExp('[ء-يٱ-ۓە]');

/// Splits Quran text into words, keeping standalone pause marks separate.
List<HifzWord> splitAyah(String text) => text
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .map((w) => HifzWord(w, isMark: !_letter.hasMatch(w)))
    .toList();

/// The first letter of [word] with the marks written on it (so "بِسْمِ"
/// gives "بِ"), skipping any leading marks.
String firstLetter(String word) {
  final runes = word.runes.toList();
  final start = runes.indexWhere((r) => _letter.hasMatch(String.fromCharCode(r)));
  if (start == -1) return word;
  var end = start + 1;
  while (end < runes.length && !_letter.hasMatch(String.fromCharCode(runes[end]))) {
    end++;
  }
  return String.fromCharCodes(runes.sublist(start, end));
}

/// How word [index] (counting only real words, not marks) is shown at
/// [level]: null when fully hidden, otherwise the visible text.
String? visibleText(HifzWord word, int index, HideLevel level) {
  if (word.isMark) return word.text;
  switch (level) {
    case HideLevel.none:
      return word.text;
    case HideLevel.firstLetters:
      return firstLetter(word.text);
    case HideLevel.everyOther:
      return index.isEven ? word.text : null;
    case HideLevel.all:
      return null;
  }
}
