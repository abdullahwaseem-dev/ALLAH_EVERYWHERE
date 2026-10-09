import 'package:allah_everywhere/data/hajj_umrah_data.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

/// Which round counter: Tawaf (around the Ka'bah) or Sa'i (Safa-Marwah).
enum HajjCounter { tawaf, sai }

/// One packing list entry: a default item (shown in the app language via
/// 'pack.<key>') or the user's own text.
class PackingItem {
  final String id;

  /// Default item key (e.g. 'ihram'), or null for the user's own item.
  final String? defaultKey;
  final String text;
  final bool packed;

  const PackingItem({required this.id, this.defaultKey, this.text = '', this.packed = false});

  bool get isCustom => defaultKey == null;

  String label(String languageCode) => defaultKey == null ? text : hajjText('pack.$defaultKey', languageCode);

  PackingItem withPacked(bool value) => PackingItem(id: id, defaultKey: defaultKey, text: text, packed: value);

  Map<String, dynamic> toMap() => {'id': id, if (defaultKey != null) 'key': defaultKey, 'text': text, 'packed': packed};

  static PackingItem? fromStored(Object? raw) {
    if (raw is! Map || raw['id'] is! String) return null;
    final key = raw['key'];
    final text = raw['text'];
    if (key is String) {
      if (!hajjPackingDefaults.contains(key)) return null; // dropped from a later app version
    } else if (text is! String || text.trim().isEmpty) {
      return null;
    }
    return PackingItem(
      id: raw['id'] as String,
      defaultKey: key is String ? key : null,
      text: text is String ? text : '',
      packed: raw['packed'] == true,
    );
  }
}

/// Hajj & Umrah guide progress, kept on the device only (works offline and
/// for guests): ticked steps, the round counters and the packing list.
class HajjService {
  static const _doneKey = 'hajj_done_steps';
  static const _packingKey = 'hajj_packing';
  static const _counterKeyPrefix = 'hajj_counter_';

  /// Rounds in one Tawaf or Sa'i.
  static const rounds = 7;

  // --- Checklist -----------------------------------------------------------

  Set<String> doneSteps() {
    try {
      final raw = VoidStorage().readData<Object>(_doneKey);
      if (raw is! List) return {};
      final ids = hajjSteps.map((s) => s.id).toSet();
      return raw.whereType<String>().where(ids.contains).toSet();
    } catch (e) {
      VoidLogger.error('Saved Hajj checklist was unreadable', e);
      return {};
    }
  }

  Future<void> setStepDone(String stepId, bool done) {
    final steps = doneSteps();
    done ? steps.add(stepId) : steps.remove(stepId);
    return VoidStorage().saveData(_doneKey, steps.toList());
  }

  int doneCount(HajjGuide guide, [Set<String>? done]) {
    final d = done ?? doneSteps();
    return hajjStepsFor(guide).where((s) => d.contains(s.id)).length;
  }

  // --- Round counters ------------------------------------------------------

  int counter(HajjCounter which) {
    try {
      final raw = VoidStorage().readData<Object>('$_counterKeyPrefix${which.name}');
      return raw is num ? raw.toInt().clamp(0, rounds) : 0;
    } catch (e) {
      VoidLogger.error('Saved round counter was unreadable', e);
      return 0;
    }
  }

  Future<void> setCounter(HajjCounter which, int value) =>
      VoidStorage().saveData('$_counterKeyPrefix${which.name}', value.clamp(0, rounds));

  // --- Packing list --------------------------------------------------------

  static List<PackingItem> get _defaults =>
      [for (final key in hajjPackingDefaults) PackingItem(id: 'default_$key', defaultKey: key)];

  /// The saved list, or the default list the first time.
  List<PackingItem> packing() {
    try {
      final raw = VoidStorage().readData<Object>(_packingKey);
      if (raw is! List) return _defaults;
      final seen = <String>{};
      return [
        for (final item in raw.map(PackingItem.fromStored))
          if (item != null && seen.add(item.id)) item,
      ];
    } catch (e) {
      VoidLogger.error('Saved packing list was unreadable', e);
      return _defaults;
    }
  }

  Future<void> _savePacking(List<PackingItem> items) =>
      VoidStorage().saveData(_packingKey, items.map((i) => i.toMap()).toList());

  Future<List<PackingItem>> setPacked(String id, bool packed) async {
    final items = [for (final i in packing()) i.id == id ? i.withPacked(packed) : i];
    await _savePacking(items);
    return items;
  }

  /// Adds the user's own item; blank text is ignored.
  Future<List<PackingItem>> addItem(String text, {DateTime? now}) async {
    final items = packing();
    final trimmed = text.trim();
    if (trimmed.isEmpty) return items;
    final id = 'custom_${(now ?? DateTime.now()).microsecondsSinceEpoch}';
    items.add(PackingItem(id: id, text: trimmed));
    await _savePacking(items);
    return items;
  }

  Future<List<PackingItem>> removeItem(String id) async {
    final items = packing()..removeWhere((i) => i.id == id);
    await _savePacking(items);
    return items;
  }

  /// Puts back any default items the user removed (their own items stay).
  Future<List<PackingItem>> restoreDefaults() async {
    final items = packing();
    final present = items.map((i) => i.defaultKey).whereType<String>().toSet();
    final missing = _defaults.where((d) => !present.contains(d.defaultKey));
    final restored = [...missing, ...items];
    await _savePacking(restored);
    return restored;
  }

  bool get hasAllDefaults {
    final present = packing().map((i) => i.defaultKey).whereType<String>().toSet();
    return hajjPackingDefaults.every(present.contains);
  }

  // --- New trip ------------------------------------------------------------

  /// Clears ticked steps, both counters and the packing ticks. The packing
  /// items themselves (including the user's own) are kept.
  Future<void> resetTrip() async {
    await VoidStorage().removeData(_doneKey);
    for (final c in HajjCounter.values) {
      await VoidStorage().removeData('$_counterKeyPrefix${c.name}');
    }
    final items = packing();
    if (VoidStorage().readData<Object>(_packingKey) != null) {
      await _savePacking([for (final i in items) i.withPacked(false)]);
    }
  }
}
