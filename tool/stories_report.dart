// ignore_for_file: avoid_print
// Reports what is missing from the Stories of the Prophets translations.
//
//   dart run tool/stories_report.dart            # summary per language
//   dart run tool/stories_report.dart --details  # list every problem
//   dart run tool/stories_report.dart --strict   # exit 1 if anything is missing
//
// For each language in assets/stories it checks, against the English files:
// - Prophets in index.json with no story file in that language;
// - chapters missing, extra or out of order (by chapter id);
// - paragraphs, kids paragraphs, lessons, blocks or quiz questions whose
//   number differs from English;
// - empty strings, and strings identical to the English one (usually not
//   translated yet; names and short items are ignored).
import 'dart:convert';
import 'dart:io';

const languages = ['ar', 'ur', 'fr', 'de', 'tr', 'hi', 'zh'];
const root = 'assets/stories';

Map<String, dynamic> readJson(String path) => jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// Every translatable string of a story, by a readable path.
Map<String, String> strings(Map<String, dynamic> story) {
  final out = <String, String>{};
  for (final f in ['name', 'title', 'sentTo', 'era', 'summary']) {
    out[f] = story[f] as String? ?? '';
  }
  final places = story['places'] as List;
  for (var i = 0; i < places.length; i++) {
    out['places[$i]'] = (places[i] as Map)['name'] as String? ?? '';
  }
  final notes = story['notes'] as List;
  for (var i = 0; i < notes.length; i++) {
    out['notes[$i]'] = notes[i] as String;
  }
  for (final c in (story['chapters'] as List).cast<Map>()) {
    final id = c['id'];
    out['$id.title'] = c['title'] as String;
    for (final list in ['paragraphs', 'kidsParagraphs', 'lessons']) {
      final items = c[list] as List;
      for (var i = 0; i < items.length; i++) {
        out['$id.$list[$i]'] = items[i] as String;
      }
    }
    final blocks = (c['blocks'] as List).cast<Map>();
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      if (b['type'] == 'narrationNote') out['$id.blocks[$i].text'] = b['text'] as String;
      if (b['type'] == 'hadith') {
        out['$id.blocks[$i].narrator'] = b['narrator'] as String;
        out['$id.blocks[$i].translation'] = b['translation'] as String;
      }
    }
    final quiz = (c['quiz'] as List).cast<Map>();
    for (var j = 0; j < quiz.length; j++) {
      out['$id.quiz[$j].question'] = quiz[j]['question'] as String;
      final options = quiz[j]['options'] as List;
      for (var m = 0; m < options.length; m++) {
        out['$id.quiz[$j].options[$m]'] = options[m] as String;
      }
    }
  }
  return out;
}

void main(List<String> args) {
  final details = args.contains('--details');
  final strict = args.contains('--strict');
  final index = readJson('$root/index.json');
  final ids = [for (final p in index['prophets'] as List) (p as Map)['id'] as String];
  final english = {
    for (final id in ids)
      if (File('$root/en/$id.json').existsSync()) id: readJson('$root/en/$id.json'),
  };

  var total = 0;
  print('English stories: ${english.length} of ${ids.length}');
  for (final lang in languages) {
    final problems = <String>[];
    var files = 0;
    for (final id in english.keys) {
      final file = File('$root/$lang/$id.json');
      if (!file.existsSync()) {
        problems.add('$id: no file');
        continue;
      }
      files++;
      final en = english[id]!;
      final story = readJson(file.path);
      final enChapters = [for (final c in en['chapters'] as List) (c as Map)['id']];
      final chapters = [for (final c in story['chapters'] as List) (c as Map)['id']];
      if (enChapters.join(',') != chapters.join(',')) {
        problems.add('$id: chapters ${chapters.join(',')} instead of ${enChapters.join(',')}');
        continue;
      }
      for (var i = 0; i < enChapters.length; i++) {
        final a = (en['chapters'] as List)[i] as Map;
        final b = (story['chapters'] as List)[i] as Map;
        for (final list in ['paragraphs', 'kidsParagraphs', 'lessons', 'blocks', 'quiz']) {
          if ((a[list] as List).length != (b[list] as List).length) {
            problems.add('${a['id']}: $list has ${(b[list] as List).length} items, English has ${(a[list] as List).length}');
          }
        }
      }
      final enStrings = strings(en);
      strings(story).forEach((path, value) {
        if (value.trim().isEmpty) {
          problems.add('$id $path: empty');
        } else if (path != 'name' && value.length > 24 && value == enStrings[path]) {
          problems.add('$id $path: same as English');
        }
      });
    }
    for (final id in ids.where((id) => !english.containsKey(id))) {
      problems.add('$id: no English story yet');
    }
    total += problems.length;
    print('$lang: $files/${english.length} stories, ${problems.isEmpty ? 'complete' : '${problems.length} problem(s)'}');
    if (details) {
      for (final p in problems) {
        print('   - $p');
      }
    }
  }
  if (strict && total > 0) exit(1);
}
