import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:allah_everywhere/models/prophet_story.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

/// Where the reader last was: a chapter of a Prophet's story and how far
/// down it was scrolled.
class StoryPosition {
  final String prophetId;
  final int chapter;
  final double offset;

  const StoryPosition({required this.prophetId, required this.chapter, this.offset = 0});
}

/// Loads the Stories of the Prophets from the bundled JSON (fully offline,
/// one file at a time, cached for the session) and keeps reading progress on
/// the device, so it works for guests and with empty storage.
class ProphetStoriesService {
  /// Shows the Home tile, Story of the Day card and search results. It was
  /// off for the 1.1.0 release; the translations still await scholar review
  /// (scratchpad scholar_review.md) before shipping to the stores.
  static const enabled = true;

  static const _root = 'assets/stories';
  static const _readKey = 'stories_read_chapters';
  static const _positionKey = 'stories_last_position';
  static const _textScaleKey = 'stories_text_scale';
  static const _kidsModeKey = 'stories_kids_mode';

  static const minTextScale = 0.85;
  static const maxTextScale = 1.6;

  final AssetBundle _bundle;

  ProphetStoriesService({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static List<ProphetIndexEntry>? _index;
  static final Map<String, ProphetStory> _stories = {};

  // --- Content -------------------------------------------------------------

  /// The 25 Prophets in order. Empty (never throws) if the index is missing.
  Future<List<ProphetIndexEntry>> loadIndex() async {
    final cached = _index;
    if (cached != null) return cached;
    try {
      final json = jsonDecode(await _bundle.loadString('$_root/index.json')) as Map<String, dynamic>;
      final entries = [
        for (final p in json['prophets'] as List) ProphetIndexEntry.fromJson(Map<String, dynamic>.from(p as Map)),
      ]..sort((a, b) => a.order.compareTo(b.order));
      return _index = entries;
    } catch (e) {
      VoidLogger.error('Could not load the Prophets\' Stories index', e);
      return const [];
    }
  }

  /// [entry]'s story in [languageCode], or in English when it isn't
  /// translated yet. Null if it has no story at all or the file is broken.
  Future<ProphetStory?> loadStory(ProphetIndexEntry entry, String languageCode) async {
    final language = entry.languages.contains(languageCode)
        ? languageCode
        : entry.languages.contains('en')
            ? 'en'
            : null;
    if (language == null) return null;
    final key = '$language/${entry.id}';
    final cached = _stories[key];
    if (cached != null) return cached;
    try {
      final json = jsonDecode(await _bundle.loadString('$_root/$key.json')) as Map<String, dynamic>;
      return _stories[key] = ProphetStory.fromJson(json);
    } catch (e) {
      VoidLogger.error('Could not load the story $key', e);
      return null;
    }
  }

  /// The Prophet after [entry] on the timeline, or null after the last one.
  Future<ProphetIndexEntry?> nextProphet(ProphetIndexEntry entry) async {
    final index = await loadIndex();
    final i = index.indexWhere((p) => p.id == entry.id);
    return i < 0 || i + 1 >= index.length ? null : index[i + 1];
  }

  /// The Prophet for Home's "Story of the day" on [day]: the Prophets with a
  /// story take turns in timeline order, one per calendar day, so everyone
  /// sees the same story on the same date. Null when no story is available.
  static ProphetIndexEntry? storyOfTheDay(List<ProphetIndexEntry> entries, DateTime day) {
    final withStory = entries.where((e) => e.hasStory).toList();
    if (withStory.isEmpty) return null;
    // Count whole days from the local date (UTC midnight avoids DST shifts).
    final dayNumber = DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    return withStory[dayNumber % withStory.length];
  }

  // --- Reading progress ----------------------------------------------------

  Set<String> _readIds() {
    final raw = VoidStorage().readData<Object>(_readKey);
    return raw is List ? raw.whereType<String>().toSet() : <String>{};
  }

  bool isChapterRead(String chapterId) => _readIds().contains(chapterId);

  int readCount(Iterable<String> chapterIds) {
    final read = _readIds();
    return chapterIds.where(read.contains).length;
  }

  Future<void> markChapterRead(String chapterId) async {
    final read = _readIds();
    if (read.add(chapterId)) await VoidStorage().saveData(_readKey, read.toList());
  }

  StoryPosition? lastPosition() {
    final raw = VoidStorage().readData<Object>(_positionKey);
    if (raw is! Map || raw['prophetId'] is! String || raw['chapter'] is! int) return null;
    return StoryPosition(
      prophetId: raw['prophetId'] as String,
      chapter: raw['chapter'] as int,
      offset: (raw['offset'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<void> savePosition(StoryPosition position) => VoidStorage().saveData(_positionKey, {
        'prophetId': position.prophetId,
        'chapter': position.chapter,
        'offset': position.offset,
      });

  // --- Reader settings -----------------------------------------------------

  double get textScale {
    final raw = VoidStorage().readData<Object>(_textScaleKey);
    return raw is num ? raw.toDouble().clamp(minTextScale, maxTextScale) : 1.0;
  }

  Future<void> setTextScale(double scale) =>
      VoidStorage().saveData(_textScaleKey, scale.clamp(minTextScale, maxTextScale));

  bool get kidsMode => VoidStorage().readData<Object>(_kidsModeKey) == true;

  Future<void> setKidsMode(bool value) => VoidStorage().saveData(_kidsModeKey, value);
}
