import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:allah_everywhere/services/tasbeeh_service.dart';

/// In-memory stand-in for GetStorage. Values go through a JSON round trip,
/// like GetStorage's file does across an app restart, so the store is tested
/// against the same decoded types (Map<String, dynamic>, num) it gets on a
/// real device.
class _FakeStorage implements TasbeehKeyValue {
  final Map<String, String> data = {};

  @override
  Object? read(String key) => data.containsKey(key) ? jsonDecode(data[key]!) : null;

  @override
  Future<void> write(String key, Object value) async => data[key] = jsonEncode(value);

  @override
  Future<void> remove(String key) async => data.remove(key);
}

void main() {
  late _FakeStorage storage;
  late TasbeehCounterStore store;

  setUp(() {
    storage = _FakeStorage();
    store = TasbeehCounterStore(storage: storage);
  });

  group('fresh install', () {
    test('every colour starts at 0 with target 33, gold selected', () async {
      await store.migrateLegacy();
      final counters = store.loadAll();
      expect(counters.keys, tasbeehBeadIds);
      for (final c in counters.values) {
        expect(c.count, 0);
        expect(c.target, 33);
        expect(c.laps, 0);
        expect(c.name, '');
      }
      expect(store.selectedBeadId, 'gold');
    });

    test('migration with nothing to migrate writes nothing', () async {
      await store.migrateLegacy();
      expect(storage.data, isEmpty);
    });
  });

  group('migration from the old single counter', () {
    test('moves count, laps and target into gold and removes the old keys', () async {
      await storage.write(TasbeehCounterStore.legacyCountKey, 250);
      await storage.write(TasbeehCounterStore.legacyLapKey, 2);
      await storage.write(TasbeehCounterStore.legacyTargetKey, 100);

      await store.migrateLegacy();

      final gold = store.loadAll()['gold']!;
      expect(gold.count, 250);
      expect(gold.laps, 2);
      expect(gold.target, 100);
      expect(storage.data.containsKey(TasbeehCounterStore.legacyCountKey), isFalse);
      expect(storage.data.containsKey(TasbeehCounterStore.legacyLapKey), isFalse);
      expect(storage.data.containsKey(TasbeehCounterStore.legacyTargetKey), isFalse);
      // Other colours are untouched.
      expect(store.loadAll()['red']!.count, 0);
    });

    test('a missing old target falls back to 33', () async {
      await storage.write(TasbeehCounterStore.legacyCountKey, 12);

      await store.migrateLegacy();

      final gold = store.loadAll()['gold']!;
      expect(gold.count, 12);
      expect(gold.target, 33);
    });

    test('running it again does not change anything', () async {
      await storage.write(TasbeehCounterStore.legacyCountKey, 40);
      await store.migrateLegacy();
      await store.save('gold', store.loadAll()['gold']!.copyWith(count: 41));

      await store.migrateLegacy();

      expect(store.loadAll()['gold']!.count, 41);
    });

    test('never overwrites a gold counter already in the new format', () async {
      await store.save('gold', const TasbeehCounter(count: 7, target: 7));
      await storage.write(TasbeehCounterStore.legacyCountKey, 999);

      await store.migrateLegacy();

      expect(store.loadAll()['gold']!.count, 7);
      expect(storage.data.containsKey(TasbeehCounterStore.legacyCountKey), isFalse);
    });
  });

  group('independent counters per colour', () {
    test('the 4-step example: each colour keeps its own count and target across a restart', () async {
      // 1. Red, target 33, count to 33.
      await store.saveSelectedBeadId('red');
      await store.save('red', const TasbeehCounter(count: 33, target: 33, laps: 1));
      // 2. Olive, target 100, count to 100.
      await store.saveSelectedBeadId('olive');
      await store.save('olive', const TasbeehCounter(count: 100, target: 100, laps: 1));
      // 3. Back to red.
      await store.saveSelectedBeadId('red');
      expect(store.loadAll()['red']!.count, 33);
      expect(store.loadAll()['red']!.target, 33);

      // 4. "Restart": a new store reading the same persisted data.
      final reopened = TasbeehCounterStore(storage: storage);
      final counters = reopened.loadAll();
      expect(reopened.selectedBeadId, 'red');
      expect(counters['red']!.count, 33);
      expect(counters['red']!.target, 33);
      expect(counters['olive']!.count, 100);
      expect(counters['olive']!.target, 100);
      expect(counters['gold']!.count, 0);
    });

    test('names are saved per colour', () async {
      await store.save('red', const TasbeehCounter(name: 'SubhanAllah'));
      await store.save('olive', const TasbeehCounter(name: 'Astaghfirullah'));

      final counters = TasbeehCounterStore(storage: storage).loadAll();
      expect(counters['red']!.name, 'SubhanAllah');
      expect(counters['olive']!.name, 'Astaghfirullah');
    });

    test('data is keyed by stable colour IDs, not colour values', () async {
      await store.save('red', const TasbeehCounter(count: 5));

      final raw = storage.read(TasbeehCounterStore.countersKey) as Map;
      expect(raw.keys, ['red']);
      expect(raw['red'], {'count': 5, 'target': 33, 'laps': 0, 'name': ''});
    });

    test('reset all zeroes counts and laps but keeps targets and names', () async {
      await store.save('red', const TasbeehCounter(count: 33, target: 33, laps: 1, name: 'SubhanAllah'));
      await store.save('olive', const TasbeehCounter(count: 100, target: 100, laps: 1));

      await store.resetAll();

      final counters = store.loadAll();
      expect(counters['red']!.count, 0);
      expect(counters['red']!.laps, 0);
      expect(counters['red']!.target, 33);
      expect(counters['red']!.name, 'SubhanAllah');
      expect(counters['olive']!.count, 0);
      expect(counters['olive']!.target, 100);
    });
  });

  group('bad stored data does not crash', () {
    test('malformed values fall back to defaults', () async {
      await storage.write(TasbeehCounterStore.countersKey, {
        'red': {'count': 'abc', 'target': 0, 'laps': -3, 'name': 42},
        'green': 'not a map',
        'unknown_colour': {'count': 9},
      });

      final counters = store.loadAll();
      expect(counters['red']!.count, 0);
      expect(counters['red']!.target, 33);
      expect(counters['red']!.laps, 0);
      expect(counters['red']!.name, '');
      expect(counters['green']!.count, 0);
      expect(counters.containsKey('unknown_colour'), isFalse);
    });

    test('an unknown selected colour falls back to gold', () async {
      await storage.write(TasbeehCounterStore.selectedKey, 'blue');
      expect(store.selectedBeadId, 'gold');
    });

    test('a non-map counters value is treated as empty', () async {
      await storage.write(TasbeehCounterStore.countersKey, 'corrupt');
      expect(store.loadAll()['gold']!.count, 0);
    });
  });
}
