import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quran/quran.dart' as quran;
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

enum HifzStatus { remembered, needsPractice }

/// Review intervals after each successful recall, in days.
const List<int> hifzReviewIntervals = [1, 3, 7, 14, 30];

/// Memorization state of one ayah.
class AyahRecord {
  final HifzStatus status;

  /// Successful reviews so far, 0..[hifzReviewIntervals].length.
  final int stage;

  /// Day (yyyy-mm-dd) the ayah is next due for review.
  final String nextReview;

  /// When this record last changed - newer wins when syncing devices.
  final DateTime updatedAt;

  const AyahRecord({required this.status, required this.stage, required this.nextReview, required this.updatedAt});

  bool isDue(DateTime today) => nextReview.compareTo(hifzDateKey(today)) <= 0;

  Map<String, dynamic> toMap() =>
      {'status': status.name, 'stage': stage, 'nextReview': nextReview, 'updatedAt': updatedAt.toIso8601String()};

  static AyahRecord? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final status = HifzStatus.values.where((s) => s.name == raw['status']).firstOrNull;
    final next = raw['nextReview'];
    final updated = DateTime.tryParse(raw['updatedAt'] as String? ?? '');
    if (status == null || next is! String || updated == null) return null;
    final stage = raw['stage'] is num ? (raw['stage'] as num).toInt() : 0;
    return AyahRecord(
      status: status,
      stage: stage.clamp(0, hifzReviewIntervals.length),
      nextReview: next,
      updatedAt: updated,
    );
  }
}

String hifzDateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _addDays(DateTime d, int days) => DateTime(d.year, d.month, d.day + days);

/// "Remembered": the next review moves out along 1, 3, 7, 14, 30 days, then
/// stays at 30. Tapping it again before the ayah is due changes nothing, so
/// a double tap can't skip a step.
AyahRecord markRemembered(AyahRecord? current, DateTime now) {
  if (current != null && current.status == HifzStatus.remembered && !current.isDue(now)) return current;
  final stage = current == null || current.status == HifzStatus.needsPractice
      ? 1
      : (current.stage + 1).clamp(1, hifzReviewIntervals.length);
  return AyahRecord(
    status: HifzStatus.remembered,
    stage: stage,
    nextReview: hifzDateKey(_addDays(now, hifzReviewIntervals[stage - 1])),
    updatedAt: now,
  );
}

/// "Need practice": back to the start, and due again today.
AyahRecord markNeedsPractice(DateTime now) =>
    AyahRecord(status: HifzStatus.needsPractice, stage: 0, nextReview: hifzDateKey(now), updatedAt: now);

/// All progress: surah -> ayah -> record.
typedef HifzProgress = Map<int, Map<int, AyahRecord>>;

/// Per-ayah merge of two copies of the same progress (device and cloud):
/// the more recently updated record wins.
HifzProgress mergeHifzProgress(HifzProgress a, HifzProgress b) {
  final out = <int, Map<int, AyahRecord>>{for (final e in a.entries) e.key: {...e.value}};
  for (final surah in b.entries) {
    final target = out.putIfAbsent(surah.key, () => {});
    for (final ayah in surah.value.entries) {
      final mine = target[ayah.key];
      if (mine == null || ayah.value.updatedAt.isAfter(mine.updatedAt)) target[ayah.key] = ayah.value;
    }
  }
  return out;
}

int memorizedIn(HifzProgress progress, int surah) =>
    progress[surah]?.values.where((r) => r.status == HifzStatus.remembered).length ?? 0;

int totalMemorized(HifzProgress progress) =>
    progress.keys.fold(0, (total, surah) => total + memorizedIn(progress, surah));

/// Juz 30 (Juz Amma): An-Naba (78) to An-Nas (114).
const int juzAmmaFirstSurah = 78;

int get juzAmmaAyahCount =>
    [for (int s = juzAmmaFirstSurah; s <= 114; s++) quran.getVerseCount(s)].fold(0, (a, b) => a + b);

int juzAmmaMemorized(HifzProgress progress) =>
    [for (int s = juzAmmaFirstSurah; s <= 114; s++) memorizedIn(progress, s)].fold(0, (a, b) => a + b);

/// Ayahs due for review on [now], in Quran order.
List<({int surah, int ayah, AyahRecord record})> dueForReview(HifzProgress progress, DateTime now) {
  final due = <({int surah, int ayah, AyahRecord record})>[];
  for (final surah in (progress.keys.toList()..sort())) {
    final ayahs = progress[surah]!;
    for (final ayah in (ayahs.keys.toList()..sort())) {
      final r = ayahs[ayah]!;
      if (r.isDue(now)) due.add((surah: surah, ayah: ayah, record: r));
    }
  }
  return due;
}

/// Due ayahs grouped into runs of consecutive ayahs per surah, each at most
/// [maxLength] long, e.g. Al-Mulk 1-5 and 7-7.
List<({int surah, int from, int to})> groupReviewRanges(
  List<({int surah, int ayah, AyahRecord record})> due, {
  required int maxLength,
}) {
  final ranges = <({int surah, int from, int to})>[];
  for (final d in due) {
    final last = ranges.isEmpty ? null : ranges.last;
    if (last != null && last.surah == d.surah && last.to == d.ayah - 1 && d.ayah - last.from < maxLength) {
      ranges[ranges.length - 1] = (surah: last.surah, from: last.from, to: d.ayah);
    } else {
      ranges.add((surah: d.surah, from: d.ayah, to: d.ayah));
    }
  }
  return ranges;
}

/// Hifz progress, stored on the device first and mirrored to Firestore for
/// signed-in users (users/{uid}/hifz/{surah}), like BookmarkService: saving
/// never waits on or fails because of the network, and failed uploads are
/// retried on the next [sync].
class HifzService {
  static const _guestKey = 'hifz_progress_guest';
  static const _remoteTimeout = Duration(seconds: 8);

  /// Bumped on every change so open screens (dashboard, practice) refresh.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  User? get _user {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null; // Firebase unavailable: behave as a guest
    }
  }

  String get _storageKey {
    final user = _user;
    return user == null ? _guestKey : 'hifz_progress_${user.uid}';
  }

  String get _pendingKey => '${_storageKey}_pending';

  CollectionReference<Map<String, dynamic>>? get _collection {
    final user = _user;
    if (user == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.uid).collection('hifz');
  }

  static Map<int, AyahRecord> _decodeSurah(Object? raw) {
    final out = <int, AyahRecord>{};
    if (raw is! Map) return out;
    raw.forEach((k, v) {
      final ayah = int.tryParse('$k');
      final r = AyahRecord.fromMap(v);
      if (ayah != null && r != null) out[ayah] = r;
    });
    return out;
  }

  static Map<String, dynamic> _encodeSurah(Map<int, AyahRecord> ayahs) =>
      {for (final e in ayahs.entries) '${e.key}': e.value.toMap()};

  HifzProgress load() {
    try {
      final raw = VoidStorage().readData<Object>(_storageKey);
      if (raw is! Map) return {};
      final out = <int, Map<int, AyahRecord>>{};
      raw.forEach((k, v) {
        final surah = int.tryParse('$k');
        if (surah != null) out[surah] = _decodeSurah(v);
      });
      return out;
    } catch (e) {
      VoidLogger.error('Stored Hifz progress was unreadable; starting fresh', e);
      return {};
    }
  }

  Future<void> _save(HifzProgress progress) => VoidStorage().saveData(
        _storageKey,
        {for (final e in progress.entries) '${e.key}': _encodeSurah(e.value)},
      );

  Set<int> _pending() =>
      (VoidStorage().readData<List<dynamic>>(_pendingKey) ?? const []).whereType<num>().map((n) => n.toInt()).toSet();

  Future<void> _setPending(Set<int> surahs) => VoidStorage().saveData(_pendingKey, surahs.toList());

  /// Marks an ayah. Saved on the device immediately; mirrored in the background.
  Future<AyahRecord> mark(int surah, int ayah, {required bool remembered, DateTime? now}) async {
    final at = now ?? DateTime.now();
    final progress = load();
    final current = progress[surah]?[ayah];
    final updated = remembered ? markRemembered(current, at) : markNeedsPractice(at);
    progress.putIfAbsent(surah, () => {})[ayah] = updated;
    await _save(progress);
    changes.value++;

    if (_collection != null) {
      await _setPending(_pending()..add(surah));
      unawaited(_upload(surah, progress[surah]!));
    }
    return updated;
  }

  Future<void> _upload(int surah, Map<int, AyahRecord> ayahs) async {
    final collection = _collection;
    if (collection == null) return;
    try {
      await collection.doc('$surah').set({'ayahs': _encodeSurah(ayahs)}).timeout(_remoteTimeout);
      await _setPending(_pending()..remove(surah));
    } catch (e) {
      VoidLogger.warning('Could not save Hifz progress to Firestore (kept on device, will retry): $e');
    }
  }

  /// Signed in: uploads changes that failed earlier, then merges the cloud
  /// copy into the device one (newest record per ayah wins). Never throws;
  /// returns the device copy if Firestore can't be reached.
  Future<HifzProgress> sync() async {
    var local = load();
    final collection = _collection;
    if (collection == null) return local;
    try {
      for (final surah in _pending()) {
        final ayahs = local[surah];
        if (ayahs != null) {
          await collection.doc('$surah').set({'ayahs': _encodeSurah(ayahs)}).timeout(_remoteTimeout);
        }
        await _setPending(_pending()..remove(surah));
      }
      final snapshot = await collection.get().timeout(_remoteTimeout);
      final remote = <int, Map<int, AyahRecord>>{};
      for (final doc in snapshot.docs) {
        final surah = int.tryParse(doc.id);
        if (surah != null) remote[surah] = _decodeSurah(doc.data()['ayahs']);
      }
      final merged = mergeHifzProgress(local, remote);
      await _save(merged);
      // Anything the device had newer than the cloud goes back up.
      for (final surah in merged.keys) {
        final cloud = remote[surah] ?? const {};
        final differs = merged[surah]!.entries.any((e) => cloud[e.key]?.updatedAt != e.value.updatedAt);
        if (differs) {
          await collection.doc('$surah').set({'ayahs': _encodeSurah(merged[surah]!)}).timeout(_remoteTimeout);
        }
      }
      local = merged;
      changes.value++;
    } catch (e) {
      VoidLogger.warning('Hifz sync with Firestore failed, using device copy: $e');
    }
    return local;
  }

  // Practice settings, shared by every session.
  static const _settingsKey = 'hifz_settings';
  static Object? get storedSettings => VoidStorage().readData<Object>(_settingsKey);
  static Future<void> saveSettings(Map<String, dynamic> settings) => VoidStorage().saveData(_settingsKey, settings);
}
