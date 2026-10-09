import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:allah_everywhere/data/hajj_umrah_data.dart';
import 'package:allah_everywhere/services/hajj_service.dart';

const _languages = ['en', 'ar', 'ur', 'fr', 'de', 'hi', 'tr', 'zh'];

void main() {
  group('hajj & umrah data', () {
    test('Umrah steps in order, Hajj covers the 8th to 13th and departure', () {
      expect(hajjStepsFor(HajjGuide.umrah).map((s) => s.id), ['umrahIhram', 'umrahTawaf', 'umrahSai', 'umrahHalq']);
      final hajj = hajjStepsFor(HajjGuide.hajj);
      expect(hajj.map((s) => s.day).toSet().toList(), ['8', '9', '10', '11-13', 'depart']);
      for (final id in ['mina8', 'arafah', 'muzdalifah', 'rami10', 'qurbani', 'hajjHalq', 'ifadah', 'tashreeq', 'wada']) {
        expect(hajj.map((s) => s.id), contains(id));
      }
      expect(hajjSteps.where((s) => s.guide == HajjGuide.umrah).every((s) => s.day == null), isTrue);
    });

    test('Arafah and Tawaf al-Ifadah are pillars of Hajj', () {
      HajjStep step(String id) => hajjSteps.firstWhere((s) => s.id == id);
      expect(step('arafah').ruling, HajjRuling.rukn);
      expect(step('ifadah').ruling, HajjRuling.rukn);
    });

    test('step ids unique; every step has sources and text in every language', () {
      expect(hajjSteps.map((s) => s.id).toSet().length, hajjSteps.length);
      for (final s in hajjSteps) {
        expect(s.sources.trim(), isNotEmpty, reason: s.id);
        for (final lang in _languages) {
          for (final part in ['title', 'what', 'mistakes']) {
            expect(hajjText('${s.id}.$part', lang).trim(), isNotEmpty, reason: '${s.id}.$part $lang');
          }
          if (hajjHasText('${s.id}.note')) {
            expect(hajjText('${s.id}.note', lang).trim(), isNotEmpty);
          }
        }
        // Bullet lists line up across languages.
        final lines = hajjText('${s.id}.what', 'en').split('\n').length;
        for (final lang in _languages) {
          expect(hajjText('${s.id}.what', lang).split('\n').length, lines, reason: '${s.id} $lang');
        }
      }
    });

    test('only the Ihram steps show the restrictions', () {
      expect(hajjSteps.where((s) => s.showsRestrictions).map((s) => s.id), ['umrahIhram', 'hajjIhram']);
      for (final lang in _languages) {
        expect(hajjText('ihram.restrictions', lang).trim(), isNotEmpty);
      }
    });

    test('every dua has a source and text; steps only use known duas', () {
      for (final d in hajjDuas.values) {
        expect(d.source.trim(), isNotEmpty, reason: d.id);
        expect(d.transliteration.trim(), isNotEmpty, reason: d.id);
        expect(d.arabic.isNotEmpty || d.quran != null, isTrue, reason: d.id);
        if (d.quran == null) {
          expect(d.translation.trim(), isNotEmpty, reason: d.id);
          for (final lang in _languages) {
            expect(hajjText('dua.${d.id}', lang).trim(), isNotEmpty, reason: '${d.id} $lang');
          }
        }
      }
      for (final s in hajjSteps) {
        for (final id in s.duaIds) {
          expect(hajjDuas, contains(id), reason: s.id);
        }
      }
    });

    test('packing defaults and places have text in every language', () {
      for (final lang in _languages) {
        for (final p in hajjPackingDefaults) {
          expect(hajjText('pack.$p', lang).trim(), isNotEmpty);
        }
        for (final place in hajjPlaces) {
          expect(hajjText('place.${place.id}.name', lang).trim(), isNotEmpty);
          expect(hajjText('place.${place.id}.desc', lang).trim(), isNotEmpty);
        }
      }
      expect(hajjPlaces.map((p) => p.id), ['haram', 'nabawi', 'mina', 'arafah', 'muzdalifah', 'jamarat']);
    });

    test('unknown language falls back to English', () {
      expect(hajjText('arafah.title', 'xx'), hajjText('arafah.title', 'en'));
      expect(hajjText('no.such.key', 'en'), '');
    });
  });

  group('hajj service', () {
    late Directory storageDir;
    final service = HajjService();

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      storageDir = await Directory.systemTemp.createTemp('hajj_service_test');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => storageDir.path,
      );
      await GetStorage.init();
    });

    setUp(() => GetStorage().erase());

    tearDownAll(() => storageDir.delete(recursive: true));

    test('ticks steps and counts them per guide', () async {
      expect(service.doneSteps(), isEmpty);
      await service.setStepDone('umrahTawaf', true);
      await service.setStepDone('arafah', true);
      expect(service.doneCount(HajjGuide.umrah), 1);
      expect(service.doneCount(HajjGuide.hajj), 1);
      await service.setStepDone('umrahTawaf', false);
      expect(service.doneSteps(), {'arafah'});
    });

    test('ignores malformed or unknown saved data', () async {
      await GetStorage().write('hajj_done_steps', ['arafah', 42, 'gone']);
      expect(service.doneSteps(), {'arafah'});
      await GetStorage().write('hajj_done_steps', 'nonsense');
      expect(service.doneSteps(), isEmpty);
      await GetStorage().write('hajj_counter_tawaf', 99);
      expect(service.counter(HajjCounter.tawaf), HajjService.rounds);
      await GetStorage().write('hajj_packing', [
        {'id': 'x', 'key': 'removedInNewVersion'},
        {'id': 'y', 'text': '   '},
        {'id': 'z', 'text': 'Snacks', 'packed': true},
        'junk',
      ]);
      expect(service.packing().map((i) => i.id), ['z']);
    });

    test('round counters are separate and clamped to 7', () async {
      await service.setCounter(HajjCounter.tawaf, 3);
      await service.setCounter(HajjCounter.sai, 10);
      expect(service.counter(HajjCounter.tawaf), 3);
      expect(service.counter(HajjCounter.sai), 7);
      await service.setCounter(HajjCounter.tawaf, -1);
      expect(service.counter(HajjCounter.tawaf), 0);
    });

    test('packing list: defaults, add, tick, remove, restore', () async {
      expect(service.packing().length, hajjPackingDefaults.length);
      expect(service.hasAllDefaults, isTrue);

      var items = await service.addItem('  Phone charger ');
      final mine = items.last;
      expect(mine.isCustom, isTrue);
      expect(mine.label('ar'), 'Phone charger');
      expect((await service.addItem('   ')).length, items.length);

      items = await service.setPacked(mine.id, true);
      expect(items.firstWhere((i) => i.id == mine.id).packed, isTrue);

      items = await service.removeItem('default_ihram');
      expect(items.any((i) => i.defaultKey == 'ihram'), isFalse);
      expect(service.hasAllDefaults, isFalse);

      items = await service.restoreDefaults();
      expect(items.where((i) => i.defaultKey == 'ihram').length, 1);
      expect(items.any((i) => i.id == mine.id), isTrue);
      expect(service.hasAllDefaults, isTrue);
    });

    test('reset for a new trip clears ticks and counters, keeps own items', () async {
      await service.setStepDone('arafah', true);
      await service.setCounter(HajjCounter.sai, 4);
      final items = await service.addItem('Snacks');
      await service.setPacked(items.last.id, true);
      await service.setPacked('default_belt', true);

      await service.resetTrip();
      expect(service.doneSteps(), isEmpty);
      expect(service.counter(HajjCounter.sai), 0);
      final after = service.packing();
      expect(after.any((i) => i.text == 'Snacks'), isTrue);
      expect(after.every((i) => !i.packed), isTrue);
    });
  });
}
