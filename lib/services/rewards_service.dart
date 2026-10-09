import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:quran/quran.dart' as quran;
import 'package:allah_everywhere/data/rewards_data.dart';
import 'package:allah_everywhere/services/hifz_service.dart';
import 'package:allah_everywhere/services/tasbeeh_service.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

/// A completed challenge's certificate (awarded by the server).
class ChallengeCertificate {
  final String challengeId;
  final String title;
  final String challengeType;
  final DateTime startAt;
  final DateTime endAt;
  final DateTime completedAt;

  /// "perfect" (never missed a day), "early" or "completed".
  final String result;
  final String name;
  final String dedication;

  const ChallengeCertificate({
    required this.challengeId,
    required this.title,
    required this.challengeType,
    required this.startAt,
    required this.endAt,
    required this.completedAt,
    required this.result,
    required this.name,
    this.dedication = '',
  });

  static DateTime _date(Object? v) =>
      v is Timestamp ? v.toDate() : (v is int ? DateTime.fromMillisecondsSinceEpoch(v) : DateTime.now());

  factory ChallengeCertificate.fromMap(Map<String, dynamic> d) => ChallengeCertificate(
        challengeId: d['challengeId'] as String? ?? '',
        title: d['title'] as String? ?? '',
        challengeType: d['challengeType'] as String? ?? 'custom',
        startAt: _date(d['startAt']),
        endAt: _date(d['endAt']),
        completedAt: _date(d['completedAt']),
        result: d['result'] as String? ?? 'completed',
        name: d['name'] as String? ?? '',
        dedication: d['dedication'] as String? ?? '',
      );
}

class GardenPlant {
  final GardenKind kind;
  final String label;
  final DateTime? earnedAt;

  const GardenPlant(this.kind, this.label, this.earnedAt);
}

/// Everything the user has earned.
class RewardsState {
  /// Badge id -> date earned.
  final Map<String, DateTime> badges;
  final List<ChallengeCertificate> certificates;

  /// Trees, fountains and flowers (palms are counted separately).
  final List<GardenPlant> plants;
  final int palms;

  const RewardsState({
    this.badges = const {},
    this.certificates = const [],
    this.plants = const [],
    this.palms = 0,
  });

  bool has(String badgeId) => badges.containsKey(badgeId);

  bool unlocked(CosmeticDef c) => c.unlockedBy == null || has(c.unlockedBy!);
}

/// Rewards: challenge badges and certificates come from the server
/// (users/{uid}/rewards, read-only for the user). Badges for things done on
/// this device (Tasbeeh, Hifz) are kept on the device, also for guests, and
/// copied to users/{uid}/localRewards once signed in so they follow the
/// account. Nothing here can be bought.
class RewardsService {
  RewardsService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    int Function()? dhikrTotal,
    HifzProgress Function()? hifzProgress,
  })  : _firestore = firestore,
        _auth = auth,
        _dhikrTotal = dhikrTotal ?? (() => TasbeehService().lifetimeTotal),
        _hifzProgress = hifzProgress ?? (() => HifzService().load());

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  final int Function() _dhikrTotal;
  final HifzProgress Function() _hifzProgress;

  static const _localKey = 'local_rewards';
  static const _seenKey = 'rewards_seen_badges';
  static const _cosmeticPrefix = 'cosmetic_';

  /// Bumped when device rewards or the selected cosmetics change.
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  User? get _user {
    try {
      return (_auth ?? FirebaseAuth.instance).currentUser;
    } catch (_) {
      return null; // Firebase unavailable: behave as a guest
    }
  }

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  bool get isSignedIn => _user != null;

  // --- Device rewards ----------------------------------------------------------

  Map<String, Map<String, dynamic>> _local() {
    final raw = VoidStorage().readData<Object>(_localKey);
    if (raw is! Map) return {};
    return {
      for (final e in raw.entries)
        if (e.key is String && e.value is Map) e.key as String: Map<String, dynamic>.from(e.value as Map),
    };
  }

  Future<void> _saveLocal(Map<String, Map<String, dynamic>> all) async {
    await VoidStorage().saveData(_localKey, all);
    changes.value++;
  }

  /// Fully memorised surahs in Hifz mode.
  List<int> _memorizedSurahs() {
    final progress = _hifzProgress();
    return [
      for (final surah in progress.keys)
        if (memorizedIn(progress, surah) >= quran.getVerseCount(surah)) surah,
    ]..sort();
  }

  /// Awards device badges and flowers for what Tasbeeh and Hifz show, and
  /// returns the badge ids that are new.
  Future<List<String>> checkLocal({DateTime? now}) async {
    final at = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final all = _local();
    final fresh = <String>[];
    void badge(String id) {
      if (all.containsKey('badge_$id')) return;
      all['badge_$id'] = {'type': 'badge', 'badgeId': id, 'earnedAt': at};
      fresh.add(id);
    }

    final dhikr = _dhikrTotal();
    for (final e in RewardRules.dhikrBadges.entries) {
      if (dhikr >= e.value) badge(e.key);
    }
    var changed = false;
    final surahs = _memorizedSurahs();
    if (surahs.isNotEmpty) badge('first_surah');
    for (final surah in surahs) {
      final id = 'garden_flower_$surah';
      if (all.containsKey(id)) continue;
      all[id] = {'type': 'garden', 'kind': GardenKind.flower.name, 'surah': surah, 'earnedAt': at};
      changed = true;
    }
    if (fresh.isNotEmpty || changed) {
      await _saveLocal(all);
      unawaited(syncLocal());
    }
    return fresh;
  }

  /// Copies device rewards to the account and brings back those earned on
  /// other devices. Never throws.
  Future<void> syncLocal() async {
    final user = _user;
    if (user == null) return;
    try {
      final ref = _db.collection('users').doc(user.uid).collection('localRewards');
      final all = _local();
      final remote = await ref.get().timeout(const Duration(seconds: 8));
      var changed = false;
      for (final doc in remote.docs) {
        if (all.containsKey(doc.id)) continue;
        final data = Map<String, dynamic>.from(doc.data());
        final at = data['earnedAt'];
        if (at is Timestamp) data['earnedAt'] = at.millisecondsSinceEpoch;
        all[doc.id] = data;
        changed = true;
      }
      final have = remote.docs.map((d) => d.id).toSet();
      final batch = _db.batch();
      var uploads = 0;
      for (final e in all.entries) {
        if (have.contains(e.key)) continue;
        batch.set(ref.doc(e.key), e.value);
        uploads++;
      }
      if (uploads > 0) await batch.commit().timeout(const Duration(seconds: 8));
      if (changed) await _saveLocal(all);
    } catch (e) {
      VoidLogger.error('Could not sync device rewards', e);
    }
  }

  // --- Everything earned -------------------------------------------------------

  RewardsState _build(Iterable<Map<String, dynamic>> server, Map<String, Map<String, dynamic>> local) {
    final badges = <String, DateTime>{};
    final certificates = <ChallengeCertificate>[];
    final plants = <GardenPlant>[];
    DateTime? date(Object? v) =>
        v is Timestamp ? v.toDate() : (v is int ? DateTime.fromMillisecondsSinceEpoch(v) : null);
    for (final d in [...server, ...local.values]) {
      switch (d['type']) {
        case 'badge':
          final id = d['badgeId'] as String?;
          if (id != null && badgeById(id) != null) badges.putIfAbsent(id, () => date(d['earnedAt']) ?? DateTime.now());
        case 'certificate':
          certificates.add(ChallengeCertificate.fromMap(d));
        case 'garden':
          final kind = GardenKind.values.where((k) => k.name == d['kind']).firstOrNull;
          if (kind == null) continue;
          final surah = (d['surah'] as num?)?.toInt();
          final label = surah != null ? quran.getSurahName(surah) : d['label'] as String? ?? '';
          plants.add(GardenPlant(kind, label, date(d['earnedAt'])));
      }
    }
    certificates.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    plants.sort((a, b) => (a.earnedAt ?? DateTime(2000)).compareTo(b.earnedAt ?? DateTime(2000)));
    return RewardsState(
      badges: badges,
      certificates: certificates,
      plants: plants,
      palms: _dhikrTotal() ~/ RewardRules.dhikrPerPalm,
    );
  }

  /// Everything earned, live: server rewards (when signed in) and device
  /// rewards. Works offline and for guests.
  Stream<RewardsState> watch() {
    late final StreamController<RewardsState> controller;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? sub;
    var server = <Map<String, dynamic>>[];
    void emit() {
      if (!controller.isClosed) controller.add(_build(server, _local()));
    }

    controller = StreamController<RewardsState>(
      onListen: () {
        emit();
        changes.addListener(emit);
        final user = _user;
        if (user == null) return;
        sub = _db.collection('users').doc(user.uid).collection('rewards').snapshots().listen((snap) {
          server = snap.docs.map((d) => d.data()).toList();
          emit();
        }, onError: (Object e) => VoidLogger.error('Rewards stream failed', e));
      },
      onCancel: () {
        changes.removeListener(emit);
        sub?.cancel();
      },
    );
    return controller.stream;
  }

  // --- Badge visibility ----------------------------------------------------------

  /// Whether other challenge members see the user's badges (on by default).
  Future<bool> badgesVisible() async {
    final user = _user;
    if (user == null) return true;
    try {
      final doc = await _db.collection('users').doc(user.uid).get().timeout(const Duration(seconds: 8));
      return doc.data()?['hideBadges'] != true;
    } catch (_) {
      return true;
    }
  }

  Future<void> setBadgesVisible(bool visible) async {
    final user = _user;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).set({'hideBadges': !visible}, SetOptions(merge: true));
  }

  // --- New-badge moments -------------------------------------------------------

  /// Badges in [state] the user hasn't been shown yet (marks them seen).
  /// The first time this runs on a device, everything already earned is
  /// marked seen silently, so old badges don't all pop up at once.
  static Future<List<String>> takeUnseen(RewardsState state) async {
    final raw = VoidStorage().readData<Object>(_seenKey);
    final seen = raw is List ? raw.whereType<String>().toSet() : null;
    final fresh = seen == null ? <String>[] : state.badges.keys.where((id) => !seen.contains(id)).toList();
    if (seen == null || fresh.isNotEmpty) {
      await VoidStorage().saveData(_seenKey, {...?seen, ...state.badges.keys}.toList());
    }
    return fresh;
  }

  // --- Cosmetics -----------------------------------------------------------------

  // The accent shares ThemeController's key, which applies it app-wide.
  static String _key(CosmeticKind kind) => kind == CosmeticKind.accent ? 'accent_theme' : '$_cosmeticPrefix${kind.name}';

  static String _defaultFor(CosmeticKind kind) => cosmetics.firstWhere((c) => c.kind == kind && c.unlockedBy == null).id;

  /// The chosen cosmetic of [kind], or its default.
  static String selected(CosmeticKind kind) {
    try {
      final id = VoidStorage().readData<String>(_key(kind));
      if (id != null && cosmeticById(id)?.kind == kind) return id;
    } catch (_) {}
    return _defaultFor(kind);
  }

  static Future<void> select(CosmeticDef cosmetic) async {
    await VoidStorage().saveData(_key(cosmetic.kind), cosmetic.id);
    changes.value++;
  }
}
