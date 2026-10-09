import 'dart:math';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:allah_everywhere/challenge_auto_progress.dart';
import 'package:allah_everywhere/models/challenge.dart';
import 'package:allah_everywhere/services/challenge_service.dart';
import 'package:allah_everywhere/utils/utils/validators/profanity_filter.dart';

/// Create / look up / join / leave against an in-memory Firestore. The
/// security rules themselves are tested in firestore-tests/.
void main() {
  late FakeFirebaseFirestore db;
  final events = <String>[];

  ChallengeService serviceFor(String uid, String name) => ChallengeService(
        firestore: db,
        auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: uid, displayName: name)),
        random: Random(uid.hashCode),
      );

  NewChallenge khatam({bool showExact = true, DateTime? start}) => NewChallenge(
        title: 'Ramadan Khatam',
        type: ChallengeType.khatam,
        unit: ChallengeUnits.juz,
        target: 30,
        startAt: start ?? DateTime.now(),
        durationDays: 30,
        intention: '  For my parents  ',
        showExactNumbers: showExact,
      );

  setUp(() {
    db = FakeFirebaseFirestore();
    events.clear();
    ChallengeService.logEvent = (name, _) => events.add(name);
  });

  group('invite codes', () {
    test('use 6 characters with no O, 0, I or 1', () {
      final svc = serviceFor('a', 'Amina');
      for (var i = 0; i < 500; i++) {
        final code = svc.newCode();
        expect(code, matches(RegExp(r'^[A-HJ-NP-Z2-9]{6}$')));
      }
    });

    test('typed codes are cleaned up', () {
      expect(ChallengeService.normalizeCode(' abc-234 '), 'ABC234');
      expect(ChallengeService.normalizeCode('o0i1abc'), 'ABC');
      expect(ChallengeService.isValidCode('ABC234'), isTrue);
      expect(ChallengeService.isValidCode('ABC23'), isFalse);
      expect(ChallengeService.isValidCode('ABC231'), isFalse);
    });
  });

  test('create writes the challenge, the creator and the invite preview', () async {
    final created = await serviceFor('alice', 'Amina').create(khatam());
    final doc = await db.collection('challenges').doc(created.id).get();
    expect(doc.data()!['memberUids'], ['alice']);
    expect(doc.data()!['memberCount'], 1);
    expect(doc.data()!['status'], 'active');
    expect(doc.data()!['intention'], 'For my parents');
    expect(doc.data()!['creatorName'], 'Amina');

    final me = await db.collection('challenges').doc(created.id).collection('participants').doc('alice').get();
    expect(me.data()!['percent'], 0);
    expect(me.data()!['progress'], 0);
    expect(me.data()!['showExactNumbers'], isTrue);

    final code = await db.collection('inviteCodes').doc(created.inviteCode).get();
    expect(code.data()!['challengeId'], created.id);
    expect(code.data()!['title'], 'Ramadan Khatam');
    expect(events, ['challenge_created']);
  });

  test('a challenge starting later is "upcoming"', () async {
    final created =
        await serviceFor('alice', 'Amina').create(khatam(start: DateTime.now().add(const Duration(days: 3))));
    final doc = await db.collection('challenges').doc(created.id).get();
    expect(doc.data()!['status'], 'upcoming');
  });

  test('"Only show %" keeps the exact number out of the shared doc', () async {
    final created = await serviceFor('alice', 'Amina').create(khatam(showExact: false));
    final me = await db.collection('challenges').doc(created.id).collection('participants').doc('alice').get();
    expect(me.data()!.containsKey('progress'), isFalse);
    final private = await db.collection('users').doc('alice').collection('challengeProgress').doc(created.id).get();
    expect(private.data()!['progress'], 0);
  });

  test('look up and join with a code', () async {
    final created = await serviceFor('alice', 'Amina').create(khatam());
    final bob = serviceFor('bob', 'Bilal');
    final preview = await bob.lookup(created.inviteCode.toLowerCase());
    expect(preview.title, 'Ramadan Khatam');
    expect(preview.creatorName, 'Amina');
    expect(preview.memberCount, 1);

    await bob.join(preview);
    final doc = await db.collection('challenges').doc(created.id).get();
    expect(doc.data()!['memberUids'], ['alice', 'bob']);
    expect(doc.data()!['memberCount'], 2);
    final code = await db.collection('inviteCodes').doc(created.inviteCode).get();
    expect(code.data()!['memberCount'], 2);
    final feed = await db.collection('challenges').doc(created.id).collection('feed').get();
    expect(feed.docs.single.data()['kind'], 'joined');
    expect(events, ['challenge_created', 'challenge_joined']);
  });

  test('join errors: unknown code, already a member, full, ended', () async {
    final bob = serviceFor('bob', 'Bilal');
    await expectLater(bob.lookup('ZZZZZZ'),
        throwsA(isA<ChallengeJoinException>().having((e) => e.reason, 'reason', ChallengeJoinError.notFound)));

    final created = await serviceFor('alice', 'Amina').create(khatam());
    final preview = await bob.lookup(created.inviteCode);
    await bob.join(preview);
    await expectLater(bob.join(preview),
        throwsA(isA<ChallengeJoinException>().having((e) => e.reason, 'reason', ChallengeJoinError.alreadyMember)));

    final full = ChallengePreview(
      code: 'ABC234',
      challengeId: 'x',
      title: 't',
      type: ChallengeType.custom,
      creatorName: 'c',
      startAt: DateTime.now(),
      endAt: DateTime.now().add(const Duration(days: 1)),
      memberCount: ChallengeService.maxMembers,
    );
    await expectLater(serviceFor('carol', 'Carol').join(full),
        throwsA(isA<ChallengeJoinException>().having((e) => e.reason, 'reason', ChallengeJoinError.full)));

    final ended = ChallengePreview(
      code: 'ABC234',
      challengeId: 'x',
      title: 't',
      type: ChallengeType.custom,
      creatorName: 'c',
      startAt: DateTime.now().subtract(const Duration(days: 3)),
      endAt: DateTime.now().subtract(const Duration(days: 1)),
      memberCount: 2,
    );
    await expectLater(serviceFor('carol', 'Carol').join(ended),
        throwsA(isA<ChallengeJoinException>().having((e) => e.reason, 'reason', ChallengeJoinError.ended)));
  });

  test('leave removes the member and their progress', () async {
    final created = await serviceFor('alice', 'Amina').create(khatam());
    final bob = serviceFor('bob', 'Bilal');
    await bob.join(await bob.lookup(created.inviteCode));
    await bob.leave(created);
    final doc = await db.collection('challenges').doc(created.id).get();
    expect(doc.data()!['memberUids'], ['alice']);
    expect(doc.data()!['memberCount'], 1);
    final p = await db.collection('challenges').doc(created.id).collection('participants').doc('bob').get();
    expect(p.exists, isFalse);
  });

  test('my challenges: active first, then upcoming, then finished', () async {
    final now = DateTime(2026, 10, 9);
    Challenge c(String id, int startOffset, int endOffset) => Challenge(
          id: id,
          title: id,
          type: ChallengeType.custom,
          unit: 'x',
          target: 1,
          startAt: now.add(Duration(days: startOffset)),
          endAt: now.add(Duration(days: endOffset)),
          creatorUid: 'a',
          creatorName: 'a',
          inviteCode: 'ABC234',
          memberUids: const ['a'],
          memberCount: 1,
        );
    final list = [c('old', -20, -10), c('soon', 2, 5), c('ends-late', -1, 9), c('ends-soon', -1, 1), c('older', -40, -30)];
    ChallengeService.sortChallenges(list, now);
    expect(list.map((e) => e.id), ['ends-soon', 'ends-late', 'soon', 'old', 'older']);
  });

  test('percent and days left', () {
    expect(percentOf(3, 30), 10);
    expect(percentOf(29, 30), 96.6);
    expect(percentOf(30, 30), 100);
    expect(percentOf(40, 30), 100);
    final now = DateTime(2026, 10, 9, 12);
    expect(daysUntil(now.add(const Duration(hours: 1)), now), 1);
    expect(daysUntil(now.add(const Duration(days: 3)), now), 3);
    expect(daysUntil(now.subtract(const Duration(hours: 1)), now), 0);
  });

  group('the challenge screen', () {
    late ChallengeService alice, bob;
    late Challenge created;

    Future<Map<String, dynamic>> participant(String uid) async =>
        (await db.collection('challenges').doc(created.id).collection('participants').doc(uid).get()).data()!;

    Future<List<Map<String, dynamic>>> feed() async =>
        (await db.collection('challenges').doc(created.id).collection('feed').orderBy('createdAt').get())
            .docs
            .map((d) => d.data())
            .toList();

    Future<void> start(NewChallenge c, {bool bobExact = true}) async {
      alice = serviceFor('alice', 'Amina');
      bob = serviceFor('bob', 'Bilal');
      created = await alice.create(c);
      await bob.join(await bob.lookup(created.inviteCode), showExactNumbers: bobExact);
      events.clear();
    }

    test('logging a number adds to progress and posts an update', () async {
      await start(NewChallenge(
          title: 'Durood',
          type: ChallengeType.dhikr,
          unit: ChallengeUnits.count,
          target: 1000,
          startAt: DateTime.now(),
          durationDays: 7));
      final r = await bob.logProgress(created, amount: 250);
      expect(r.added, 250);
      expect(r.percent, 25);
      final me = await participant('bob');
      expect(me['progress'], 250);
      expect(me['percent'], 25);
      expect(me['loggedDays'], [challengeDayKey(DateTime.now())]);
      final update = (await feed()).last;
      expect(update['kind'], 'progress');
      expect(update['value'], 250);
      expect(update['name'], 'Bilal');
      expect(events, ['progress_logged']);
    });

    test('ticked Juz count once, and never past the target', () async {
      await start(khatam());
      await bob.logProgress(created, items: [1, 2]);
      final r = await bob.logProgress(created, items: [2, 3]);
      expect(r.added, 1);
      expect((await feed()).last['items'], [3]);
      final mine = await bob.myProgress(created);
      expect(mine.progress, 3);
      expect(mine.items, {1, 2, 3});
      // Ticking everything completes it exactly once.
      final done = await bob.logProgress(created, items: List.generate(30, (i) => i + 1));
      expect(done.added, 27);
      expect(done.completedNow, isTrue);
      final me = await participant('bob');
      expect(me['progress'], 30);
      expect(me['percent'], 100);
      expect(me['completedAt'], isNotNull);
      expect((await feed()).map((f) => f['kind']).where((k) => k == 'completed').length, 1);
      expect(events, ['progress_logged', 'progress_logged', 'progress_logged', 'challenge_completed']);
      expect((await bob.logProgress(created, amount: 1)).added, 0);
    });

    test('"Only show %" keeps exact numbers out of the participant doc and the feed', () async {
      await start(khatam(), bobExact: false);
      await bob.logProgress(created, items: [5, 6, 7]);
      final me = await participant('bob');
      expect(me.containsKey('progress'), isFalse);
      expect(me['percent'], 10);
      final update = (await feed()).last;
      expect(update.containsKey('value'), isFalse);
      expect(update.containsKey('items'), isFalse);
      expect((await bob.myProgress(created)).progress, 3);
    });

    test('fasting and Tahajjud log once a day; nothing before the start', () async {
      await start(NewChallenge(
          title: 'Fasts',
          type: ChallengeType.fasting,
          unit: ChallengeUnits.days,
          target: 3,
          startAt: DateTime.now(),
          durationDays: 7));
      expect((await bob.logProgress(created, amount: 1)).added, 1);
      expect((await bob.logProgress(created, amount: 1)).added, 0);

      final later = await alice.create(khatam(start: DateTime.now().add(const Duration(days: 2))));
      expect((await alice.logProgress(later, amount: 1)).added, 0);
    });

    test('messages are trimmed, clipped to 300 characters and filtered', () async {
      await start(khatam());
      await bob.sendMessage(created, '  What the fuck, ${'a' * 400}  ');
      final msg = (await feed()).last;
      expect(msg['kind'], 'message');
      expect(msg['text'], startsWith('What the ****, '));
      expect((msg['text'] as String).length, ChallengeService.maxMessageLength);
      await bob.sendMessage(created, '   ');
      expect((await feed()).where((f) => f['kind'] == 'message').length, 1);
    });

    test('one nudge per member per day', () async {
      await start(khatam());
      expect(await bob.nudge(created, 'alice'), isTrue);
      expect(await bob.nudge(created, 'alice'), isFalse);
      expect(await bob.nudge(created, 'bob'), isFalse);
      final now = DateTime.now().toUtc();
      final id = ChallengeService.nudgeId('bob', 'alice', now);
      expect(id, 'nudge_bob_alice_${now.year}-${now.month}-${now.day}');
      final nudge = await db.collection('challenges').doc(created.id).collection('feed').doc(id).get();
      expect(nudge.data()!['targetUid'], 'alice');
    });

    test('reactions toggle on and off per member', () async {
      await start(khatam());
      await alice.sendMessage(created, 'Bismillah');
      Future<ChallengeFeedItem> message() async => ChallengeFeedItem.fromDoc((await db
              .collection('challenges')
              .doc(created.id)
              .collection('feed')
              .where('kind', isEqualTo: 'message')
              .get())
          .docs
          .single);
      await bob.toggleReaction(created, await message(), 'mashaallah');
      await alice.toggleReaction(created, await message(), 'mashaallah');
      await bob.toggleReaction(created, await message(), 'ameen');
      var m = await message();
      expect(m.reactionCount('mashaallah'), 2);
      expect(m.reactedBy('bob', 'ameen'), isTrue);
      await bob.toggleReaction(created, m, 'mashaallah');
      await bob.toggleReaction(created, await message(), 'ameen');
      m = await message();
      expect(m.reactionCount('mashaallah'), 1);
      expect(m.reactions.containsKey('bob'), isFalse);
    });

    test('the creator removes a member; members report items', () async {
      await start(khatam());
      await bob.sendMessage(created, 'Hello');
      final item = ChallengeFeedItem.fromDoc((await db
              .collection('challenges')
              .doc(created.id)
              .collection('feed')
              .where('kind', isEqualTo: 'message')
              .get())
          .docs
          .single);
      await alice.report(created, item, 'spam');
      final report = (await db.collection('reports').get()).docs.single.data();
      expect(report['reporterUid'], 'alice');
      expect(report['itemId'], item.id);

      await alice.removeMember(created, 'bob');
      final doc = await db.collection('challenges').doc(created.id).get();
      expect(doc.data()!['memberUids'], ['alice']);
      expect((await db.collection('inviteCodes').doc(created.inviteCode).get()).data()!['memberCount'], 1);
      expect(
          (await db.collection('challenges').doc(created.id).collection('participants').doc('bob').get()).exists,
          isFalse);
    });

    test('leaderboard: highest % first, then who finished first', () {
      ChallengeParticipant m(String uid, double percent, [DateTime? done]) =>
          ChallengeParticipant(uid: uid, displayName: uid, percent: percent, completedAt: done);
      final list = ChallengeService.sortLeaderboard([
        m('c', 40),
        m('late', 100, DateTime(2026, 10, 9, 12)),
        m('a', 40),
        m('early', 100, DateTime(2026, 10, 9, 8)),
      ]);
      expect(list.map((e) => e.uid), ['early', 'late', 'a', 'c']);
    });
  });

  test('ranges are written compactly', () {
    expect(compactRanges([5, 1, 2, 3, 8, 10, 11]), '1–3, 5, 8, 10–11');
    expect(compactRanges([7]), '7');
    expect(compactRanges([]), '');
  });

  test('the profanity filter masks obvious words only', () {
    expect(ProfanityFilter.clean('You are a bitch'), 'You are a *****');
    expect(ProfanityFilter.clean('Fucking hell'), '******* hell');
    expect(ProfanityFilter.clean('A prickly, laudable assessment in Scunthorpe'),
        'A prickly, laudable assessment in Scunthorpe');
    expect(ProfanityFilter.clean('MashaAllah, Juz 3 done!'), 'MashaAllah, Juz 3 done!');
    expect(ProfanityFilter.contains('bhenchod'), isTrue);
  });

  group('auto progress', () {
    setUp(ChallengeAutoProgress.reset);

    test('a Mushaf page counts after 15 seconds on it', () {
      final t0 = DateTime(2026, 10, 9, 10);
      ChallengeAutoProgress.notePage(1, now: t0);
      ChallengeAutoProgress.notePage(2, now: t0.add(const Duration(seconds: 3)));
      ChallengeAutoProgress.notePage(3, now: t0.add(const Duration(seconds: 40)));
      expect(ChallengeAutoProgress.pendingPages, {2});
    });

    test('a Juz is finished when its last page is read', () {
      expect(ChallengeAutoProgress.finishedJuz({21, 22, 604}), [1, 30]);
      expect(ChallengeAutoProgress.finishedJuz({20}), isEmpty);
    });

    test('offers only new items for a matching active challenge', () async {
      final alice = serviceFor('alice', 'Amina');
      final c = await alice.create(khatam());
      await alice.logProgress(c, items: [1]);
      final offer = await ChallengeAutoProgress.findOffer(alice, pages: {21, 41});
      expect(offer?.challenge.id, c.id);
      expect(offer?.items, [2]);
      expect(await ChallengeAutoProgress.findOffer(alice, pages: {21}), isNull);

      final surah = await alice.create(NewChallenge(
          title: 'Al-Mulk',
          type: ChallengeType.memorizeSurah,
          unit: ChallengeUnits.ayahs,
          target: 30,
          startAt: DateTime.now(),
          durationDays: 3,
          surah: 67));
      final hifz = await ChallengeAutoProgress.findOffer(alice, ayahs: {
        67: {1, 2},
        2: {5}
      });
      expect(hifz?.challenge.id, surah.id);
      expect(hifz?.items, [1, 2]);
    });
  });
}
