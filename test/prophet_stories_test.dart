import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hadith/hadith.dart' show Collections, Languages;
import 'package:hadith/hadith.dart' as hadith show getHadithDataByNumber;
import 'package:quran/quran.dart' as quran;
import 'package:allah_everywhere/models/prophet_story.dart';
import 'package:allah_everywhere/services/prophet_stories_service.dart';

/// Validates every Stories of the Prophets file in assets/stories: required
/// fields, chapter structure, every Quran reference against the `quran`
/// package, every hadith number against the `hadith` package (its Arabic
/// must contain the block's `match` phrase), quiz answers and references,
/// and the Quran name counts in index.json.
void main() {
  const languages = ['en', 'ar', 'ur', 'fr', 'de', 'tr', 'hi', 'zh'];
  const reviewNote = 'CONTENT REVIEW REQUIRED: verify against source before release';
  final root = Directory('assets/stories');

  Map<String, dynamic> readJson(String path) =>
      jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

  final index = readJson('${root.path}/index.json');
  final prophets = [
    for (final p in index['prophets'] as List) ProphetIndexEntry.fromJson(Map<String, dynamic>.from(p as Map)),
  ];

  /// Harakat, Quranic marks, tatweel, direction marks and punctuation
  /// removed, and the alif forms unified, so phrases match across editions.
  String plainArabic(String s) => s
      .replaceAll(RegExp('<[^>]*>'), '')
      .replaceAll(RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ‎‏]'), '')
      .replaceAll(RegExp('[أإآٱ]'), 'ا')
      .replaceAll(RegExp('[،؛؟.,:"{}()]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');

  final hadithCache = <String, String>{};
  String hadithArabic(String collection, String number) => hadithCache.putIfAbsent('$collection $number', () {
        final c = switch (collection) {
          'bukhari' => Collections.bukhari,
          'muslim' => Collections.muslim,
          _ => throw StateError('Only al-Bukhari and Muslim are used: $collection'),
        };
        return plainArabic(hadith.getHadithDataByNumber(c, number, Languages.ar).body);
      });

  group('index.json', () {
    test('lists the 25 Prophets named in the Quran, in order, named in every language', () {
      expect(index['_note'], reviewNote);
      expect(index['reviewed'], isA<bool>());
      expect(prophets.map((p) => p.id).toList(), [
        'adam', 'idris', 'nuh', 'hud', 'salih', 'ibrahim', 'lut', 'ismail', 'ishaq', 'yaqub', 'yusuf', 'ayyub', //
        'shuayb', 'musa', 'harun', 'dhulkifl', 'dawud', 'sulayman', 'ilyas', 'alyasa', 'yunus', 'zakariya', 'yahya',
        'isa', 'muhammad',
      ]);
      for (int i = 0; i < prophets.length; i++) {
        final p = prophets[i];
        expect(p.order, i + 1, reason: p.id);
        expect(p.arabicName.trim(), isNotEmpty, reason: p.id);
        for (final lang in languages) {
          expect(p.names[lang]?.trim(), isNotEmpty, reason: '${p.id} has no $lang name');
        }
      }
      expect(prophets.where((p) => p.isFinalMessenger).map((p) => p.id), ['muhammad']);
    });

    test('languages match the story files on disk', () {
      for (final p in prophets) {
        for (final lang in languages) {
          final exists = File('${root.path}/$lang/${p.id}.json').existsSync();
          expect(p.languages.contains(lang), exists, reason: '${p.id} / $lang');
        }
        if (p.hasStory) expect(p.languages, contains('en'), reason: 'English is written first: ${p.id}');
      }
    });

    test('timesNamed and surahs match the Quran text', () {
      // Every spelling of the name in the `quran` package text (harakat
      // removed), with its attached prefixes.
      const forms = {
        'adam': {'ءادم', 'يادم', 'لادم', 'ويادم'},
        'idris': {'ادريس', 'وادريس'},
        'nuh': {'نوح', 'نوحا', 'ونوحا', 'ينوح'},
        'hud': {'هودا', 'هود', 'يهود'},
        'salih': {'صلحا', 'صلح', 'يصلح'},
        'ibrahim': {'ابرهيم', 'بابرهيم', 'يابرهيم', 'لابرهيم', 'وابرهيم', 'ابرهم'},
        'lut': {'لوط', 'لوطا', 'ولوطا', 'يلوط'},
        'ismail': {'اسمعيل', 'واسمعيل'},
        'ishaq': {'اسحق', 'واسحق', 'باسحق'},
        'yaqub': {'يعقوب', 'ويعقوب'},
        'yusuf': {'يوسف', 'ويوسف', 'ليوسف', 'بيوسف'},
        'ayyub': {'ايوب', 'وايوب'},
        'shuayb': {'شعيب', 'شعيبا', 'يشعيب'},
        'musa': {'موسى', 'يموسى', 'وموسى', 'بموسى', 'لموسى'},
        'harun': {'هرون', 'وهرون', 'يهرون'},
        'dhulkifl': {'الكفل'},
        'dawud': {'داود', 'وداود', 'يداود', 'لداود'},
        'sulayman': {'سليمن', 'وسليمن', 'ولسليمن', 'لسليمن'},
        'ilyas': {'الياس', 'والياس'},
        'alyasa': {'واليسع'},
        'yunus': {'يونس', 'ويونس'},
        'zakariya': {'زكريا', 'وزكريا', 'يزكريا'},
        'yahya': {'يحيى', 'ويحيى', 'بيحيى', 'ييحيى'},
        'isa': {'عيسى', 'وعيسى', 'يعيسى', 'بعيسى'},
        'muhammad': {'محمد'},
      };
      // These spellings are also ordinary words (هود "Jews", صالح
      // "righteous", يحيى "gives life"), so only these verses count.
      const verses = {
        'hud': {'7:65', '11:50', '11:53', '11:58', '11:60', '11:89', '26:124'},
        'salih': {'7:73', '7:75', '7:77', '11:61', '11:62', '11:66', '11:89', '26:142', '27:45'},
        'yahya': {'3:39', '6:85', '19:7', '19:12', '21:90'},
      };
      for (final p in prophets.where((p) => p.timesNamed != null)) {
        final names = forms[p.id];
        expect(names, isNotNull, reason: 'Add the spellings of ${p.id} to this test to check its count');
        var count = 0;
        final surahs = <int>{};
        for (var s = 1; s <= quran.totalSurahCount; s++) {
          for (var a = 1; a <= quran.getVerseCount(s); a++) {
            if (verses[p.id] != null && !verses[p.id]!.contains('$s:$a')) continue;
            for (final word in plainArabic(quran.getVerse(s, a)).split(' ')) {
              if (names!.contains(word)) {
                count++;
                surahs.add(s);
              }
            }
          }
        }
        expect(p.timesNamed, count, reason: p.id);
        expect(p.surahs, surahs.toList()..sort(), reason: p.id);
      }
    });

    test('story of the day is the same all day and visits every Prophet in turn', () {
      final withStory = prophets.where((p) => p.hasStory).toList();
      final start = DateTime(2026, 3, 29); // includes a DST change in many regions
      expect(ProphetStoriesService.storyOfTheDay(prophets, DateTime(2026, 3, 29, 0, 5)),
          ProphetStoriesService.storyOfTheDay(prophets, DateTime(2026, 3, 29, 23, 55)));
      final seen = <String>[
        for (int d = 0; d < withStory.length; d++)
          ProphetStoriesService.storyOfTheDay(prophets, DateTime(start.year, start.month, start.day + d))!.id,
      ];
      expect(seen.toSet(), withStory.map((p) => p.id).toSet());
      expect(ProphetStoriesService.storyOfTheDay(const [], start), isNull);
    });
  });

  group('story files', () {
    final files = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.json') && !f.path.endsWith('index.json'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    test('there are story files', () => expect(files, isNotEmpty));

    for (final file in files) {
      final lang = file.parent.uri.pathSegments.where((s) => s.isNotEmpty).last;
      final id = file.uri.pathSegments.last.replaceAll('.json', '');

      test('$lang/$id is complete and every reference is valid', () {
        expect(languages, contains(lang));
        final json = readJson(file.path);
        expect(json['_note'], reviewNote);
        expect(json['reviewed'], isA<bool>());
        final story = ProphetStory.fromJson(json);
        expect(story.id, id);
        expect(story.language, lang);
        for (final field in [story.name, story.title, story.sentTo, story.era, story.summary]) {
          expect(field.trim(), isNotEmpty);
        }
        for (final place in story.places) {
          expect(place.name.trim(), isNotEmpty);
          expect(place.lat == null, place.lng == null, reason: 'lat and lng go together: ${place.name}');
          if (place.lat != null) {
            expect(place.lat, inInclusiveRange(-90, 90));
            expect(place.lng, inInclusiveRange(-180, 180));
          }
        }
        expect(story.chapters, isNotEmpty);
        expect(story.chapters.map((c) => c.id).toSet().length, story.chapters.length, reason: 'duplicate chapter id');

        final citedHadith = <String>{};
        for (final chapter in story.chapters) {
          final where = '${chapter.id}:';
          expect(chapter.id, startsWith('$id-'));
          expect(chapter.title.trim(), isNotEmpty, reason: where);
          expect(chapter.paragraphs, isNotEmpty, reason: where);
          expect(chapter.kidsParagraphs, isNotEmpty, reason: '$where kidsParagraphs');
          for (final text in [...chapter.paragraphs, ...chapter.kidsParagraphs, ...chapter.lessons]) {
            expect(text.trim(), isNotEmpty, reason: where);
          }
          expect(chapter.lessons.length, inInclusiveRange(3, 5), reason: '$where lessons');

          var lastAfter = 0;
          for (final block in chapter.blocks) {
            expect(block.after, inInclusiveRange(0, chapter.paragraphs.length - 1), reason: '$where block position');
            expect(block.after, greaterThanOrEqualTo(lastAfter), reason: '$where blocks out of order');
            lastAfter = block.after;
            switch (block) {
              case QuranStoryBlock():
                final ref = '$where ${block.surah}:${block.ayahStart}-${block.ayahEnd}';
                expect(block.surah, inInclusiveRange(1, quran.totalSurahCount), reason: ref);
                expect(block.ayahStart, inInclusiveRange(1, block.ayahEnd), reason: ref);
                expect(block.ayahEnd, lessThanOrEqualTo(quran.getVerseCount(block.surah)), reason: ref);
              case HadithStoryBlock():
                final ref = '$where ${block.reference}';
                expect(block.source, block.collection == 'bukhari' ? 'Sahih al-Bukhari' : 'Sahih Muslim', reason: ref);
                expect(block.translation.trim(), isNotEmpty, reason: ref);
                expect(block.narrator.trim(), isNotEmpty, reason: ref);
                final arabic = hadithArabic(block.collection, block.number);
                expect(arabic, isNotEmpty, reason: '$ref does not exist');
                expect(arabic, contains(plainArabic(block.match)), reason: '$ref does not contain its match phrase');
                if (lang == 'ar') {
                  // The Arabic file quotes the original text itself.
                  expect(plainArabic(block.translation), contains(plainArabic(block.match)), reason: '$ref (Arabic text)');
                }
                citedHadith.add(block.reference);
              case NarrationNoteBlock():
                expect(block.text.trim(), isNotEmpty, reason: where);
            }
          }

          expect(chapter.quiz.length, inInclusiveRange(3, 5), reason: '$where quiz');
          for (final q in chapter.quiz) {
            final ref = '$where ${q.question}';
            expect(q.question.trim(), isNotEmpty);
            expect(q.options.length, greaterThanOrEqualTo(2), reason: ref);
            expect(q.options.toSet().length, q.options.length, reason: '$ref has duplicate options');
            expect(q.answer, inInclusiveRange(0, q.options.length - 1), reason: ref);
            final quranRef = RegExp(r'^Quran (\d+):(\d+)(?:-(\d+))?$').firstMatch(q.reference);
            if (quranRef != null) {
              final s = int.parse(quranRef[1]!);
              final a = int.parse(quranRef[2]!);
              final b = int.parse(quranRef[3] ?? quranRef[2]!);
              expect(s, inInclusiveRange(1, quran.totalSurahCount), reason: ref);
              expect(a, inInclusiveRange(1, b), reason: ref);
              expect(b, lessThanOrEqualTo(quran.getVerseCount(s)), reason: ref);
            } else {
              expect(q.reference, matches(RegExp(r'^Sahih (al-Bukhari|Muslim) \d+( [a-z])?$')), reason: ref);
            }
          }
        }
        // A quiz may only cite a hadith that the story quotes.
        for (final q in story.chapters.expand((c) => c.quiz)) {
          if (q.reference.startsWith('Sahih')) {
            expect(citedHadith, contains(q.reference), reason: '${q.question} cites a hadith not quoted in the story');
          }
        }
      });

      if (lang != 'en') {
        test('$lang/$id has the same chapters and references as English', () {
          final en = ProphetStory.fromJson(readJson('${root.path}/en/$id.json'));
          final story = ProphetStory.fromJson(readJson(file.path));
          String refs(StoryChapter c) => [
                for (final b in c.blocks)
                  switch (b) {
                    QuranStoryBlock() => 'q${b.after}:${b.surah}:${b.ayahStart}-${b.ayahEnd}',
                    HadithStoryBlock() => 'h${b.after}:${b.collection}:${b.number}',
                    NarrationNoteBlock() => 'n${b.after}',
                  },
              ].join(',');
          expect(story.chapters.map((c) => c.id), en.chapters.map((c) => c.id));
          for (int i = 0; i < en.chapters.length; i++) {
            expect(refs(story.chapters[i]), refs(en.chapters[i]), reason: en.chapters[i].id);
            expect(story.chapters[i].paragraphs.length, en.chapters[i].paragraphs.length, reason: en.chapters[i].id);
            expect(story.chapters[i].quiz.map((q) => q.answer), en.chapters[i].quiz.map((q) => q.answer),
                reason: en.chapters[i].id);
          }
        });
      }
    }
  });
}
