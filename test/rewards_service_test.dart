import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:allah_everywhere/data/rewards_data.dart';
import 'package:allah_everywhere/services/hifz_service.dart';
import 'package:allah_everywhere/services/rewards_service.dart';

/// Device rewards (Tasbeeh, Hifz), the guest-to-account merge, server
/// rewards and cosmetics.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDir;

  setUpAll(() async {
    storageDir = await Directory.systemTemp.createTemp('rewards_service_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => storageDir.path,
    );
    await GetStorage.init();
  });

  setUp(() => GetStorage().erase());
  tearDownAll(() => storageDir.delete(recursive: true));

  HifzProgress memorized(int surah, int ayahs) => {
        surah: {
          for (var a = 1; a <= ayahs; a++)
            a: AyahRecord(
                status: HifzStatus.remembered, stage: 1, nextReview: '2026-10-20', updatedAt: DateTime(2026, 10, 9)),
        },
      };

  test('Tasbeeh and Hifz earn device badges, flowers and palms, once', () async {
    var dhikr = 999;
    HifzProgress hifz = {};
    final svc = RewardsService(dhikrTotal: () => dhikr, hifzProgress: () => hifz, auth: MockFirebaseAuth());
    expect(await svc.checkLocal(), isEmpty);

    dhikr = 10500;
    hifz = {...memorized(112, 4), ...memorized(1, 3)}; // Al-Ikhlas done, Al-Fatiha not
    expect((await svc.checkLocal()).toSet(), {'dhikr_1000', 'dhikr_10000', 'first_surah'});
    expect(await svc.checkLocal(), isEmpty);

    final state = await svc.watch().first;
    expect(state.badges.keys.toSet(), {'dhikr_1000', 'dhikr_10000', 'first_surah'});
    expect(state.plants.map((p) => p.kind), [GardenKind.flower]);
    expect(state.plants.single.label, 'Al Ikhlaas');
    expect(state.palms, 10);
  });

  test('server rewards and device rewards together; guests keep theirs on sign-in', () async {
    final db = FakeFirebaseFirestore();
    // Earned as a guest.
    await RewardsService(dhikrTotal: () => 1200, hifzProgress: () => {}, auth: MockFirebaseAuth()).checkLocal();

    // Signed in: the server already gave a certificate, a tree and a badge.
    final rewards = db.collection('users').doc('u1').collection('rewards');
    await rewards.doc('badge_first_challenge').set({'type': 'badge', 'badgeId': 'first_challenge', 'earnedAt': Timestamp.now()});
    await rewards.doc('cert_ch1').set({
      'type': 'certificate',
      'challengeId': 'ch1',
      'title': 'Ramadan Khatam',
      'challengeType': 'khatam',
      'startAt': Timestamp.fromDate(DateTime(2026, 10, 1)),
      'endAt': Timestamp.fromDate(DateTime(2026, 10, 11)),
      'completedAt': Timestamp.fromDate(DateTime(2026, 10, 9)),
      'result': 'early',
      'name': 'Bilal',
    });
    await rewards.doc('garden_tree_ch1').set({'type': 'garden', 'kind': 'tree', 'label': 'Ramadan Khatam'});
    // Earned on another device.
    await db.collection('users').doc('u1').collection('localRewards').doc('badge_first_surah').set(
        {'type': 'badge', 'badgeId': 'first_surah', 'earnedAt': DateTime(2026, 9, 1).millisecondsSinceEpoch});

    final svc = RewardsService(
      firestore: db,
      auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1')),
      dhikrTotal: () => 1200,
      hifzProgress: () => {},
    );
    await svc.syncLocal();
    final uploaded = await db.collection('users').doc('u1').collection('localRewards').get();
    expect(uploaded.docs.map((d) => d.id).toSet(), {'badge_dhikr_1000', 'badge_first_surah'});

    final state = await svc.watch().firstWhere((s) => s.certificates.isNotEmpty);
    expect(state.badges.keys.toSet(), {'first_challenge', 'dhikr_1000', 'first_surah'});
    expect(state.certificates.single.result, 'early');
    expect(state.certificates.single.name, 'Bilal');
    expect(state.plants.single.kind, GardenKind.tree);
    expect(state.unlocked(cosmeticById('madinah_green')!), isTrue);
    expect(state.unlocked(cosmeticById('night_of_qadr')!), isFalse);
    expect(state.unlocked(cosmeticById('frame_arch')!), isTrue);
  });

  test('old badges stay quiet the first time; new ones are shown once', () async {
    final before = RewardsState(badges: {'first_challenge': DateTime(2026, 9, 1)});
    expect(await RewardsService.takeUnseen(before), isEmpty);
    final after = RewardsState(badges: {'first_challenge': DateTime(2026, 9, 1), 'steadfast': DateTime(2026, 10, 9)});
    expect(await RewardsService.takeUnseen(after), ['steadfast']);
    expect(await RewardsService.takeUnseen(after), isEmpty);
  });

  test('cosmetics: defaults, choices, and badge visibility', () async {
    expect(RewardsService.selected(CosmeticKind.bead), 'bead_classic');
    expect(RewardsService.selected(CosmeticKind.accent), 'classic_gold');
    await RewardsService.select(cosmeticById('bead_pearl')!);
    expect(RewardsService.selected(CosmeticKind.bead), 'bead_pearl');
    // Every cosmetic is unlocked by a real badge (or is a default).
    for (final c in cosmetics) {
      expect(c.unlockedBy == null || badgeById(c.unlockedBy!) != null, isTrue, reason: c.id);
    }

    final db = FakeFirebaseFirestore();
    final svc = RewardsService(firestore: db, auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1')));
    expect(await svc.badgesVisible(), isTrue);
    await svc.setBadgesVisible(false);
    expect((await db.collection('users').doc('u1').get()).data()!['hideBadges'], isTrue);
    expect(await svc.badgesVisible(), isFalse);
  });
}
