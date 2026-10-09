import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

/// Persists the Tasbeeh counter so it survives app restarts (it used to
/// reset every time) and keeps a real lifetime total that Profile can show
/// instead of the old hardcoded "656".
class TasbeehService {
  static const _lifetimeKey = 'tasbeeh_lifetime_total';
  static const _todayKey = 'tasbeeh_today_total';

  int get lifetimeTotal => VoidStorage().readData<int>(_lifetimeKey) ?? 0;

  /// Bumped whenever the totals change, so the Tasbeeh screen (kept alive
  /// in the bottom nav) shows adhkar counted elsewhere without a restart.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  /// Everything counted today: Tasbeeh taps and morning/evening adhkar.
  int get todayTotal => todayCount(VoidStorage().readData<Object>(_todayKey), DateTime.now());

  /// Today's count from the stored {date, count}; 0 on another day or if
  /// the stored value is malformed.
  static int todayCount(Object? stored, DateTime now) {
    if (stored is! Map || stored['date'] != _dateKey(now)) return 0;
    final count = stored['count'];
    return count is num && count > 0 ? count.toInt() : 0;
  }

  /// The stored {date, count} after adding [delta] on [now]'s date.
  static Map<String, Object> addToToday(Object? stored, DateTime now, int delta) =>
      {'date': _dateKey(now), 'count': todayCount(stored, now) + delta};

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> addToLifetimeTotal(int delta) async {
    if (delta <= 0) return;
    final newTotal = lifetimeTotal + delta;
    await VoidStorage().saveData(_lifetimeKey, newTotal);
    await VoidStorage().saveData(_todayKey, addToToday(VoidStorage().readData<Object>(_todayKey), DateTime.now(), delta));
    changes.value++;

    // The device totals above are already saved; the Firestore mirror is
    // best-effort (offline, or Firebase unavailable) and must never throw
    // into the fire-and-forget callers.
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {'tasbeehTotal': FieldValue.increment(delta)},
          SetOptions(merge: true),
        );
      }
    } catch (e) {
      VoidLogger.error('Failed to sync Tasbeeh total to Firestore', e);
    }
  }
}

/// Stable IDs of the bead colours, in the order the dots are shown. Each one
/// is an independent counter. Stored by these IDs (never by Color.value) so
/// a palette tweak can't orphan anyone's saved count.
const List<String> tasbeehBeadIds = ['gold', 'olive', 'green', 'red', 'purple', 'orange'];
const String defaultTasbeehBeadId = 'gold';
const int defaultTasbeehTarget = 33;

class TasbeehCounter {
  final int count;
  final int target;
  final int laps;
  final String name;

  const TasbeehCounter({
    this.count = 0,
    this.target = defaultTasbeehTarget,
    this.laps = 0,
    this.name = '',
  });

  TasbeehCounter copyWith({int? count, int? target, int? laps, String? name}) => TasbeehCounter(
        count: count ?? this.count,
        target: target ?? this.target,
        laps: laps ?? this.laps,
        name: name ?? this.name,
      );

  Map<String, dynamic> toMap() => {'count': count, 'target': target, 'laps': laps, 'name': name};

  /// Defensive: GetStorage hands back JSON-decoded data after a restart, so
  /// numbers may arrive as num and anything may be missing or malformed.
  factory TasbeehCounter.fromMap(Object? raw) {
    if (raw is! Map) return const TasbeehCounter();
    int readInt(String key, int fallback, {int min = 0}) {
      final value = raw[key];
      if (value is num && value.toInt() >= min) return value.toInt();
      return fallback;
    }

    final name = raw['name'];
    return TasbeehCounter(
      count: readInt('count', 0),
      target: readInt('target', defaultTasbeehTarget, min: 1),
      laps: readInt('laps', 0),
      name: name is String ? name : '',
    );
  }
}

/// Minimal key-value backend so the store can be unit-tested without
/// GetStorage's platform plugin.
abstract class TasbeehKeyValue {
  Object? read(String key);
  Future<void> write(String key, Object value);
  Future<void> remove(String key);
}

class _VoidStorageKeyValue implements TasbeehKeyValue {
  @override
  Object? read(String key) => VoidStorage().readData<Object>(key);

  @override
  Future<void> write(String key, Object value) => VoidStorage().saveData(key, value);

  @override
  Future<void> remove(String key) => VoidStorage().removeData(key);
}

/// Per-colour Tasbeeh counters: { beadId: {count, target, laps, name} }.
class TasbeehCounterStore {
  static const countersKey = 'tasbeeh_counters';
  static const selectedKey = 'tasbeeh_selected_bead';

  // Pre-per-colour keys: one shared count/laps/target for every colour.
  static const legacyCountKey = 'tasbeeh_session_count';
  static const legacyLapKey = 'tasbeeh_session_laps';
  static const legacyTargetKey = 'tasbeeh_target';

  final TasbeehKeyValue _storage;

  TasbeehCounterStore({TasbeehKeyValue? storage}) : _storage = storage ?? _VoidStorageKeyValue();

  /// Moves the old shared counter into the default (gold) colour so updating
  /// users keep their count, then deletes the old keys. Safe to call on every
  /// launch: once the old keys are gone it does nothing.
  Future<void> migrateLegacy() async {
    final oldCount = _storage.read(legacyCountKey);
    final oldLaps = _storage.read(legacyLapKey);
    final oldTarget = _storage.read(legacyTargetKey);
    if (oldCount == null && oldLaps == null && oldTarget == null) return;

    final counters = _readAll();
    // Never overwrite a gold counter that already exists in the new format.
    if (!counters.containsKey(defaultTasbeehBeadId)) {
      counters[defaultTasbeehBeadId] = TasbeehCounter.fromMap({
        'count': oldCount,
        'laps': oldLaps,
        'target': oldTarget,
      });
      await _writeAll(counters);
    }
    await _storage.remove(legacyCountKey);
    await _storage.remove(legacyLapKey);
    await _storage.remove(legacyTargetKey);
  }

  Map<String, TasbeehCounter> loadAll() {
    final stored = _readAll();
    return {for (final id in tasbeehBeadIds) id: stored[id] ?? const TasbeehCounter()};
  }

  Future<void> save(String beadId, TasbeehCounter counter) async {
    final counters = _readAll()..[beadId] = counter;
    await _writeAll(counters);
  }

  /// Zeroes count and laps of every colour, keeping each target and name.
  Future<void> resetAll() async {
    final counters = loadAll().map((id, c) => MapEntry(id, c.copyWith(count: 0, laps: 0)));
    await _writeAll(counters);
  }

  String get selectedBeadId {
    final id = _storage.read(selectedKey);
    return id is String && tasbeehBeadIds.contains(id) ? id : defaultTasbeehBeadId;
  }

  Future<void> saveSelectedBeadId(String beadId) => _storage.write(selectedKey, beadId);

  Map<String, TasbeehCounter> _readAll() {
    final raw = _storage.read(countersKey);
    if (raw is! Map) return {};
    return {
      for (final entry in raw.entries)
        if (entry.key is String && tasbeehBeadIds.contains(entry.key))
          entry.key as String: TasbeehCounter.fromMap(entry.value),
    };
  }

  Future<void> _writeAll(Map<String, TasbeehCounter> counters) =>
      _storage.write(countersKey, counters.map((id, c) => MapEntry(id, c.toMap())));
}
