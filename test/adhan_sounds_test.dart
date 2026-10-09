import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:allah_everywhere/data/adhan_sounds.dart';
import 'package:allah_everywhere/services/adhan_sound_service.dart';

/// Run from the project root (flutter test does this).
File _file(String path) => File(path);

void main() {
  group('catalog', () {
    test('ids, Android channels and file names are unique', () {
      expect(allAdhanSounds.map((s) => s.id).toSet().length, allAdhanSounds.length);
      expect(allAdhanSounds.map((s) => s.channelId).toSet().length, allAdhanSounds.length);
      final raws = allAdhanSounds.map((s) => s.androidRaw).whereType<String>().toList();
      expect(raws.toSet().length, raws.length);
    });

    test('the default adhan keeps the original channel, so updating users keep theirs', () {
      expect(defaultAdhan.channelId, 'prayer_times');
      expect(defaultAdhan.androidRaw, 'adhan');
      expect(defaultAdhan.iosFile, 'adhan.caf');
    });

    test('both lists offer beep, silent and the default adhan', () {
      for (final list in [prayerSounds, fajrSounds]) {
        expect(list, containsAll([defaultAdhan, beepSound, silentSound]));
      }
      expect(fajrSounds, contains(gentleAdhan));
      expect(prayerSounds.where((s) => s.isFajr), isEmpty);
    });

    test('adhans have every file name; beep and silent have none', () {
      for (final s in allAdhanSounds) {
        final isAdhan = s.kind == AdhanSoundKind.adhan;
        expect(s.androidRaw != null, isAdhan, reason: s.id);
        expect(s.iosFile != null, isAdhan, reason: s.id);
        expect(s.preview != null, isAdhan, reason: s.id);
      }
    });

    test('Android resource names are valid (lowercase letters, digits, _)', () {
      for (final s in allAdhanSounds.where((s) => s.androidRaw != null)) {
        expect(RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(s.androidRaw!), isTrue, reason: s.id);
      }
    });

    test('previews live directly in assets/audio/ (the folder pubspec bundles)', () {
      final pubspec = _file('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('- assets/audio/'));
      for (final s in allAdhanSounds.where((s) => s.preview != null)) {
        expect(s.preview, matches(RegExp(r'^assets/audio/[^/]+\.m4a$')), reason: s.id);
      }
    });

    test('adhanSoundById', () {
      expect(adhanSoundById('gentle'), gentleAdhan);
      expect(adhanSoundById('nope'), isNull);
      expect(adhanSoundById(null), isNull);
    });
  });

  // When you add a recording and set `available: true`, these check that
  // every file is in place - including the iOS file's target membership.
  group('files of every available sound', () {
    final pbxproj = _file('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

    for (final s in allAdhanSounds.where((s) => s.available && s.kind == AdhanSoundKind.adhan)) {
      test('${s.id}: Android raw resource exists', () {
        final dir = Directory('android/app/src/main/res/raw');
        final matches = dir.listSync().whereType<File>().where((f) {
          final name = f.uri.pathSegments.last;
          return name.substring(0, name.lastIndexOf('.')) == s.androidRaw;
        });
        expect(matches.length, 1, reason: 'need exactly one res/raw/${s.androidRaw}.<ogg|mp3|wav>');
      });

      test('${s.id}: iOS sound is bundled with the Runner target', () {
        expect(_file('ios/Runner/${s.iosFile}').existsSync(), isTrue);
        expect(s.iosFile, matches(RegExp(r'\.(caf|aiff|wav)$')));
        expect(pbxproj, contains('/* ${s.iosFile} in Resources */,'),
            reason: 'add ${s.iosFile} to the Runner target (Copy Bundle Resources) in Xcode');
      });

      test('${s.id}: iOS sound is 30 seconds or less', () async {
        if (!Platform.isMacOS) return; // afinfo is macOS-only
        final info = await Process.run('afinfo', ['ios/Runner/${s.iosFile}']);
        final match = RegExp(r'estimated duration: ([0-9.]+)').firstMatch(info.stdout as String);
        expect(match, isNotNull);
        expect(double.parse(match!.group(1)!), lessThanOrEqualTo(30.0));
      });

      test('${s.id}: preview asset exists', () {
        expect(_file(s.preview!).existsSync(), isTrue);
      });
    }
  });

  group('choice resolution', () {
    test('unknown, unoffered or not-yet-added sounds fall back to the default adhan', () {
      expect(AdhanSoundService.resolveChoice(null, prayerSounds), defaultAdhan);
      expect(AdhanSoundService.resolveChoice('bogus', prayerSounds), defaultAdhan);
      expect(AdhanSoundService.resolveChoice('gentle', prayerSounds), defaultAdhan); // Fajr-only
      for (final s in allAdhanSounds.where((s) => !s.available)) {
        expect(AdhanSoundService.resolveChoice(s.id, [...prayerSounds, ...fajrSounds]), defaultAdhan);
      }
    });

    test('available choices are kept', () {
      expect(AdhanSoundService.resolveChoice('gentle', fajrSounds), gentleAdhan);
      expect(AdhanSoundService.resolveChoice('beep', prayerSounds), beepSound);
      expect(AdhanSoundService.resolveChoice('silent', fajrSounds), silentSound);
    });

    AdhanSound? resolve(String prayer, PrayerAlert alert) => AdhanSoundService.resolve(
          prayer: prayer,
          alert: alert,
          sound: defaultAdhan,
          fajrSound: gentleAdhan,
        );

    test('Fajr uses the Fajr sound; the other prayers use the main sound', () {
      expect(resolve('Fajr', PrayerAlert.adhan), gentleAdhan);
      for (final p in ['Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
        expect(resolve(p, PrayerAlert.adhan), defaultAdhan);
      }
    });

    test('per-prayer beep, silent and off', () {
      for (final p in alertPrayers) {
        expect(resolve(p, PrayerAlert.beep), beepSound);
        expect(resolve(p, PrayerAlert.silent), silentSound);
        expect(resolve(p, PrayerAlert.off), isNull);
      }
    });
  });
}
