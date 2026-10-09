// CONTENT REVIEW REQUIRED: verify against source before release

// Stories of the Prophets. The data lives in JSON under assets/stories/:
// - index.json: the 25 Prophets named in the Quran, in order, with their
//   names in every app language and which languages have a story.
// - <lang>/<id>.json: one Prophet's story in one language.
// Quran text is never stored: a [QuranStoryBlock] holds only the reference,
// and the reader takes the Arabic and the translation from the `quran`
// package. See ProphetStoriesService for loading.

/// One of the 25 Prophets in index.json.
class ProphetIndexEntry {
  final String id;

  /// 1-based position on the timeline (Adam = 1, Muhammad ﷺ = 25).
  final int order;
  final String arabicName;

  /// Name in each app language. Urdu includes the "حضرت" prefix.
  final Map<String, String> names;

  /// Other names people search for (e.g. "Noah", "Abraham").
  final List<String> alsoKnownAs;

  /// Muhammad ﷺ: shown with ﷺ and linked to the Seerah section.
  final bool isFinalMessenger;

  /// Scholars differ on when he lived, so his place in the order is
  /// approximate (e.g. Ayyub, Dhul-Kifl).
  final bool orderUncertain;

  /// Languages that have a story file for this Prophet.
  final List<String> languages;

  /// Times his name occurs in the Quran, counted from the `quran` package
  /// text; null until counted.
  final int? timesNamed;

  /// Surahs in which his name occurs.
  final List<int> surahs;

  const ProphetIndexEntry({
    required this.id,
    required this.order,
    required this.arabicName,
    required this.names,
    this.alsoKnownAs = const [],
    this.isFinalMessenger = false,
    this.orderUncertain = false,
    this.languages = const [],
    this.timesNamed,
    this.surahs = const [],
  });

  bool get hasStory => languages.isNotEmpty;

  /// Name in [languageCode], falling back to English.
  String nameIn(String languageCode) => names[languageCode] ?? names['en'] ?? id;

  factory ProphetIndexEntry.fromJson(Map<String, dynamic> json) => ProphetIndexEntry(
        id: json['id'] as String,
        order: json['order'] as int,
        arabicName: json['arabicName'] as String,
        names: Map<String, String>.from(json['names'] as Map),
        alsoKnownAs: List<String>.from(json['alsoKnownAs'] as List? ?? const []),
        isFinalMessenger: json['isFinalMessenger'] == true,
        orderUncertain: json['orderUncertain'] == true,
        languages: List<String>.from(json['languages'] as List? ?? const []),
        timesNamed: json['timesNamed'] as int?,
        surahs: List<int>.from(json['surahs'] as List? ?? const []),
      );
}

/// A place in a Prophet's life. [lat]/[lng] are null when the place is not
/// known; [approximate] when it is only a broad region.
class StoryPlace {
  final String name;
  final double? lat;
  final double? lng;
  final bool approximate;

  const StoryPlace({required this.name, this.lat, this.lng, this.approximate = false});

  factory StoryPlace.fromJson(Map<String, dynamic> json) => StoryPlace(
        name: json['name'] as String,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        approximate: json['approximate'] == true,
      );
}

/// Something shown between the paragraphs of a chapter, after paragraph
/// [after] (0-based).
sealed class StoryBlock {
  final int after;

  const StoryBlock(this.after);

  static StoryBlock fromJson(Map<String, dynamic> json) {
    final after = json['after'] as int;
    switch (json['type']) {
      case 'quran':
        return QuranStoryBlock(
          after: after,
          surah: json['surah'] as int,
          ayahStart: json['ayahStart'] as int,
          ayahEnd: json['ayahEnd'] as int,
        );
      case 'hadith':
        return HadithStoryBlock(
          after: after,
          collection: json['collection'] as String,
          source: json['source'] as String,
          number: json['number'] as String,
          narrator: json['narrator'] as String,
          translation: json['translation'] as String,
          match: json['match'] as String,
          shortened: json['shortened'] == true,
        );
      case 'narrationNote':
        return NarrationNoteBlock(after: after, text: json['text'] as String);
      default:
        throw FormatException('Unknown story block type: ${json['type']}');
    }
  }
}

/// Ayat [ayahStart]-[ayahEnd] of [surah]; the text comes from the `quran`
/// package.
class QuranStoryBlock extends StoryBlock {
  final int surah;
  final int ayahStart;
  final int ayahEnd;

  const QuranStoryBlock({required int after, required this.surah, required this.ayahStart, required this.ayahEnd})
      : super(after);
}

/// A hadith in the app language, with its reference.
class HadithStoryBlock extends StoryBlock {
  /// `hadith` package collection name, e.g. "bukhari".
  final String collection;

  /// Display name of the collection, e.g. "Sahih al-Bukhari".
  final String source;

  /// sunnah.com number, e.g. "3326".
  final String number;
  final String narrator;
  final String translation;

  /// A phrase from the Arabic original (without harakat). The data test
  /// checks it occurs in [collection] [number], so a wrong number fails.
  final String match;

  /// Only part of a longer hadith is quoted.
  final bool shortened;

  const HadithStoryBlock({
    required int after,
    required this.collection,
    required this.source,
    required this.number,
    required this.narrator,
    required this.translation,
    required this.match,
    this.shortened = false,
  }) : super(after);

  String get reference => '$source $number';
}

/// A well-known detail that has no basis in the Quran or authentic hadith
/// (often from Isra'iliyyat), shown under the app's standard warning label.
class NarrationNoteBlock extends StoryBlock {
  final String text;

  const NarrationNoteBlock({required int after, required this.text}) : super(after);
}

/// A multiple-choice question for the games; [answer] indexes [options].
class StoryQuizQuestion {
  final String question;
  final List<String> options;
  final int answer;
  final String reference;

  const StoryQuizQuestion({required this.question, required this.options, required this.answer, required this.reference});

  factory StoryQuizQuestion.fromJson(Map<String, dynamic> json) => StoryQuizQuestion(
        question: json['question'] as String,
        options: List<String>.from(json['options'] as List),
        answer: json['answer'] as int,
        reference: json['reference'] as String,
      );
}

class StoryChapter {
  /// Stable id (e.g. "adam-3"), used for read marks and bookmarks.
  final String id;
  final String title;
  final List<String> paragraphs;

  /// Shorter, simpler telling for Kids mode.
  final List<String> kidsParagraphs;
  final List<StoryBlock> blocks;
  final List<String> lessons;
  final List<StoryQuizQuestion> quiz;

  const StoryChapter({
    required this.id,
    required this.title,
    required this.paragraphs,
    required this.kidsParagraphs,
    required this.blocks,
    required this.lessons,
    required this.quiz,
  });

  /// Blocks to show after paragraph [index], in file order.
  Iterable<StoryBlock> blocksAfter(int index) => blocks.where((b) => b.after == index);

  factory StoryChapter.fromJson(Map<String, dynamic> json) => StoryChapter(
        id: json['id'] as String,
        title: json['title'] as String,
        paragraphs: List<String>.from(json['paragraphs'] as List),
        kidsParagraphs: List<String>.from(json['kidsParagraphs'] as List),
        blocks: [for (final b in json['blocks'] as List) StoryBlock.fromJson(Map<String, dynamic>.from(b as Map))],
        lessons: List<String>.from(json['lessons'] as List),
        quiz: [for (final q in json['quiz'] as List) StoryQuizQuestion.fromJson(Map<String, dynamic>.from(q as Map))],
      );
}

/// One Prophet's story in one language.
class ProphetStory {
  final String id;
  final String language;

  /// False until a scholar has checked this file; the reader shows an
  /// "Under review" label on unreviewed stories in debug builds.
  final bool reviewed;
  final String name;

  /// Honorific title, e.g. "Khalilullah, the Friend of Allah".
  final String title;
  final String sentTo;
  final String era;
  final List<StoryPlace> places;
  final String summary;

  /// Points where scholars differ, or popular details left out and why.
  final List<String> notes;
  final List<StoryChapter> chapters;

  const ProphetStory({
    required this.id,
    required this.language,
    required this.reviewed,
    required this.name,
    required this.title,
    required this.sentTo,
    required this.era,
    required this.places,
    required this.summary,
    required this.notes,
    required this.chapters,
  });

  factory ProphetStory.fromJson(Map<String, dynamic> json) => ProphetStory(
        id: json['id'] as String,
        language: json['language'] as String,
        reviewed: json['reviewed'] == true,
        name: json['name'] as String,
        title: json['title'] as String,
        sentTo: json['sentTo'] as String,
        era: json['era'] as String,
        places: [for (final p in json['places'] as List) StoryPlace.fromJson(Map<String, dynamic>.from(p as Map))],
        summary: json['summary'] as String,
        notes: List<String>.from(json['notes'] as List),
        chapters: [for (final c in json['chapters'] as List) StoryChapter.fromJson(Map<String, dynamic>.from(c as Map))],
      );
}
