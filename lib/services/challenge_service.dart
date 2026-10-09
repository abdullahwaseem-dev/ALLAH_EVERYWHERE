import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:allah_everywhere/models/challenge.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';
import 'package:allah_everywhere/utils/utils/validators/profanity_filter.dart';

/// Why a join (or code lookup) did not go through.
enum ChallengeJoinError { notFound, full, ended, alreadyMember, network }

class ChallengeJoinException implements Exception {
  final ChallengeJoinError reason;
  const ChallengeJoinException(this.reason);

  @override
  String toString() => 'ChallengeJoinException($reason)';
}

/// Everything a new challenge needs; see [ChallengeService.create].
class NewChallenge {
  final String title;
  final ChallengeType type;
  final String unit;
  final int target;
  final DateTime startAt;
  final int durationDays;
  final String intention;
  final String dedication;
  final String familyPromise;
  final int? surah;
  final bool showExactNumbers;

  const NewChallenge({
    required this.title,
    required this.type,
    required this.unit,
    required this.target,
    required this.startAt,
    required this.durationDays,
    this.intention = '',
    this.dedication = '',
    this.familyPromise = '',
    this.surah,
    this.showExactNumbers = true,
  });

  DateTime get endAt => startAt.add(Duration(days: durationDays));
}

/// Creates, finds and joins Challenges in Firestore. All writes follow
/// firestore.rules (tested in firestore-tests/): the challenge, the
/// creator's participant doc and the invite code are written together, and
/// a join adds only the current user.
class ChallengeService {
  ChallengeService({FirebaseFirestore? firestore, FirebaseAuth? auth, Random? random})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _random = random ?? Random.secure();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final Random _random;

  static const maxMembers = 50;
  static const maxTitleLength = 80;
  static const maxIntentionLength = 200;
  static const maxDedicationLength = 100;
  static const maxPromiseLength = 100;
  static const maxDays = 365;
  static const codeLength = 6;

  /// No O/0 or I/1, so a code read aloud or from a screenshot is not
  /// mistyped.
  static const codeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  /// Logs an analytics event; replaced in tests (Firebase is not set up there).
  static void Function(String name, Map<String, Object> parameters) logEvent = (name, parameters) {
    FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters).catchError((Object e) {
      VoidLogger.error('Failed to log $name', e);
    });
  };

  User? get currentUser => _auth.currentUser;
  Stream<User?> authChanges() => _auth.authStateChanges();
  bool get isSignedIn => currentUser != null;

  CollectionReference<Map<String, dynamic>> get _challenges => _db.collection('challenges');
  CollectionReference<Map<String, dynamic>> get _codes => _db.collection('inviteCodes');

  String newCode() => String.fromCharCodes(
      List.generate(codeLength, (_) => codeAlphabet.codeUnitAt(_random.nextInt(codeAlphabet.length))));

  /// Upper-cases [input] and keeps only characters a code can contain.
  static String normalizeCode(String input) =>
      input.toUpperCase().split('').where((c) => codeAlphabet.contains(c)).join();

  static bool isValidCode(String code) => code.length == codeLength && normalizeCode(code) == code;

  /// The name shown to other members: the profile name, else the account
  /// name, else the part of the email before the @.
  Future<String> displayName() async {
    final user = currentUser;
    if (user == null) return '';
    final cached = _nameCache;
    if (cached != null && cached.$1 == user.uid) return cached.$2;
    final name = await _loadDisplayName(user);
    if (name.isNotEmpty) _nameCache = (user.uid, name);
    return name;
  }

  (String, String)? _nameCache;

  Future<String> _loadDisplayName(User user) async {
    try {
      final doc = await _db.collection('users').doc(user.uid).get().timeout(const Duration(seconds: 5));
      final name = (doc.data()?['name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) return _clip(name, 60);
    } catch (e) {
      VoidLogger.error('Could not read the profile name', e);
    }
    final fallback = user.displayName?.trim();
    if (fallback != null && fallback.isNotEmpty) return _clip(fallback, 60);
    return _clip(user.email?.split('@').first ?? '', 60);
  }

  static String _clip(String s, int max) => s.length <= max ? s : s.substring(0, max);

  Map<String, dynamic> _participantData(String name, bool showExactNumbers) => {
        'displayName': name,
        'percent': 0,
        if (showExactNumbers) 'progress': 0,
        'showExactNumbers': showExactNumbers,
        'muted': false,
        'joinedAt': FieldValue.serverTimestamp(),
        'lastLoggedAt': FieldValue.serverTimestamp(),
        'loggedDays': <String>[],
      };

  /// Creates the challenge with a unique invite code (retrying if a code
  /// is taken) and returns it.
  Future<Challenge> create(NewChallenge c) async {
    final user = currentUser;
    if (user == null) throw StateError('Sign in to create a challenge');
    final name = await displayName();
    final now = DateTime.now();
    final status = c.startAt.isAfter(now) ? 'upcoming' : 'active';
    final title = _clip(c.title.trim(), maxTitleLength);
    final intention = _clip(c.intention.trim(), maxIntentionLength);
    final dedication = _clip(ProfanityFilter.clean(c.dedication.trim()), maxDedicationLength);
    final promise = _clip(ProfanityFilter.clean(c.familyPromise.trim()), maxPromiseLength);
    final startAt = Timestamp.fromDate(c.startAt);
    final endAt = Timestamp.fromDate(c.endAt);

    for (var attempt = 0; attempt < 6; attempt++) {
      final code = newCode();
      final ref = _challenges.doc();
      final created = await _db.runTransaction<bool>((tx) async {
        final existing = await tx.get(_codes.doc(code));
        if (existing.exists) return false;
        tx.set(ref, {
          'title': title,
          'type': c.type.name,
          'unit': c.unit,
          'target': c.target,
          'startAt': startAt,
          'endAt': endAt,
          'creatorUid': user.uid,
          'creatorName': name,
          'inviteCode': code,
          'memberUids': [user.uid],
          'memberCount': 1,
          'status': status,
          'createdAt': FieldValue.serverTimestamp(),
          if (intention.isNotEmpty) 'intention': intention,
          if (dedication.isNotEmpty) 'dedication': dedication,
          if (promise.isNotEmpty) 'familyPromise': promise,
          if (c.surah != null) 'surah': c.surah,
        });
        tx.set(ref.collection('participants').doc(user.uid), _participantData(name, c.showExactNumbers));
        tx.set(_codes.doc(code), {
          'challengeId': ref.id,
          'title': title,
          'type': c.type.name,
          'creatorName': name,
          'startAt': startAt,
          'endAt': endAt,
          'memberCount': 1,
        });
        return true;
      });
      if (created) {
        if (!c.showExactNumbers) await _savePrivateProgress(ref.id, 0);
        logEvent('challenge_created', {'type': c.type.name, 'days': c.durationDays});
        return Challenge(
          id: ref.id,
          title: title,
          type: c.type,
          unit: c.unit,
          target: c.target,
          startAt: c.startAt,
          endAt: c.endAt,
          creatorUid: user.uid,
          creatorName: name,
          inviteCode: code,
          memberUids: [user.uid],
          memberCount: 1,
          intention: intention,
          dedication: dedication,
          familyPromise: promise,
          surah: c.surah,
        );
      }
    }
    throw StateError('Could not find a free invite code');
  }

  /// The join preview for [code], or a [ChallengeJoinException].
  Future<ChallengePreview> lookup(String code) async {
    final normalized = normalizeCode(code);
    if (!isValidCode(normalized)) throw const ChallengeJoinException(ChallengeJoinError.notFound);
    DocumentSnapshot<Map<String, dynamic>> doc;
    try {
      doc = await _codes.doc(normalized).get().timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const ChallengeJoinException(ChallengeJoinError.network);
    } on FirebaseException catch (e) {
      VoidLogger.error('Invite code lookup failed', e);
      throw ChallengeJoinException(e.code == 'unavailable' ? ChallengeJoinError.network : ChallengeJoinError.notFound);
    }
    if (!doc.exists) throw const ChallengeJoinException(ChallengeJoinError.notFound);
    return ChallengePreview.fromDoc(doc);
  }

  /// Joins the challenge behind [preview]. Members can't read a challenge
  /// before joining, so "already a member" shows up as a readable doc.
  Future<void> join(ChallengePreview preview, {bool showExactNumbers = true}) async {
    final user = currentUser;
    if (user == null) throw StateError('Sign in to join a challenge');
    if (!preview.endAt.isAfter(DateTime.now())) throw const ChallengeJoinException(ChallengeJoinError.ended);
    if (preview.memberCount >= maxMembers) throw const ChallengeJoinException(ChallengeJoinError.full);
    final ref = _challenges.doc(preview.challengeId);
    try {
      final existing = await ref.get();
      if (existing.exists && (existing.data()?['memberUids'] as List? ?? const []).contains(user.uid)) {
        throw const ChallengeJoinException(ChallengeJoinError.alreadyMember);
      }
    } on FirebaseException {
      // Permission denied: not a member yet, which is expected.
    }
    final name = await displayName();
    final batch = _db.batch()
      ..update(ref, {
        'memberUids': FieldValue.arrayUnion([user.uid]),
        'memberCount': FieldValue.increment(1),
      })
      ..set(ref.collection('participants').doc(user.uid), _participantData(name, showExactNumbers))
      ..update(_codes.doc(preview.code), {'memberCount': FieldValue.increment(1)})
      ..set(ref.collection('feed').doc(), {
        'kind': 'joined',
        'uid': user.uid,
        'name': name,
        'text': name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    try {
      await batch.commit().timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const ChallengeJoinException(ChallengeJoinError.network);
    } on FirebaseException catch (e) {
      VoidLogger.error('Joining the challenge failed', e);
      // The rules deny a join when the challenge filled up or ended since
      // the preview was read.
      throw ChallengeJoinException(e.code == 'unavailable' ? ChallengeJoinError.network : ChallengeJoinError.full);
    }
    if (!showExactNumbers) await _savePrivateProgress(preview.challengeId, 0);
    logEvent('challenge_joined', {'type': preview.type.name});
  }

  /// Leaves [challenge]: removes the user from the member list and deletes
  /// their participant doc. The creator deletes the challenge instead.
  Future<void> leave(Challenge challenge) async {
    final user = currentUser;
    if (user == null) return;
    final ref = _challenges.doc(challenge.id);
    final batch = _db.batch()
      ..update(ref, {
        'memberUids': FieldValue.arrayRemove([user.uid]),
        'memberCount': FieldValue.increment(-1),
      })
      ..delete(ref.collection('participants').doc(user.uid))
      ..update(_codes.doc(challenge.inviteCode), {'memberCount': FieldValue.increment(-1)});
    await batch.commit();
  }

  /// Deletes [challenge] and its invite code (creator only).
  Future<void> delete(Challenge challenge) async {
    final batch = _db.batch()
      ..delete(_codes.doc(challenge.inviteCode))
      ..delete(_challenges.doc(challenge.id));
    await batch.commit();
  }

  /// The user's challenges, sorted: active, then upcoming, then finished;
  /// each group by end date. Sorted here rather than in the query so it
  /// works before the composite index is deployed.
  Stream<List<Challenge>> myChallenges() {
    final user = currentUser;
    if (user == null) return Stream.value(const []);
    return _challenges.where('memberUids', arrayContains: user.uid).snapshots().map((snap) {
      final list = snap.docs.map(Challenge.fromDoc).toList();
      sortChallenges(list, DateTime.now());
      return list;
    });
  }

  static void sortChallenges(List<Challenge> list, DateTime now) {
    int rank(Challenge c) => switch (c.statusAt(now)) {
          ChallengeStatus.active => 0,
          ChallengeStatus.upcoming => 1,
          ChallengeStatus.finished => 2,
        };
    list.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      // Finished: most recent first; otherwise the soonest deadline first.
      return rank(a) == 2 ? b.endAt.compareTo(a.endAt) : a.endAt.compareTo(b.endAt);
    });
  }

  /// The user's own participant doc in [challengeId].
  Stream<ChallengeParticipant?> myParticipant(String challengeId) {
    final user = currentUser;
    if (user == null) return Stream.value(null);
    return _challenges
        .doc(challengeId)
        .collection('participants')
        .doc(user.uid)
        .snapshots()
        .map((d) => d.exists ? ChallengeParticipant.fromDoc(d) : null);
  }

  // --- The challenge screen -------------------------------------------------

  static const feedPageSize = 30;
  static const maxMessageLength = 300;
  static const maxReportLength = 300;

  DocumentReference<Map<String, dynamic>> _participantRef(String challengeId, String uid) =>
      _challenges.doc(challengeId).collection('participants').doc(uid);

  DocumentReference<Map<String, dynamic>> _privateRef(String challengeId, String uid) =>
      _db.collection('users').doc(uid).collection('challengeProgress').doc(challengeId);

  CollectionReference<Map<String, dynamic>> _feed(String challengeId) =>
      _challenges.doc(challengeId).collection('feed');

  /// The challenge, live. Emits null once it is deleted (or the user was
  /// removed and can no longer read it).
  Stream<Challenge?> watch(String challengeId) => _challenges
      .doc(challengeId)
      .snapshots()
      .map((d) => d.exists ? Challenge.fromDoc(d) : null)
      .handleError((Object e) => VoidLogger.error('Challenge stream failed', e), test: (e) => e is! FirebaseException);

  /// Every member's progress (at most [maxMembers]), highest first.
  Stream<List<ChallengeParticipant>> participants(String challengeId, {int? limit}) {
    Query<Map<String, dynamic>> q = _challenges.doc(challengeId).collection('participants');
    if (limit != null) q = q.limit(limit);
    return q.snapshots().map((snap) => sortLeaderboard(snap.docs.map(ChallengeParticipant.fromDoc).toList()));
  }

  /// Highest percentage first; among equals, whoever finished first.
  static List<ChallengeParticipant> sortLeaderboard(List<ChallengeParticipant> list) {
    list.sort((a, b) {
      final byPercent = b.percent.compareTo(a.percent);
      if (byPercent != 0) return byPercent;
      final ad = a.completedAt, bd = b.completedAt;
      if (ad != null && bd != null) return ad.compareTo(bd);
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });
    return list;
  }

  /// The newest [limit] feed items, newest first. Ask for a bigger limit to
  /// page back through older items (it stays one live query).
  Stream<List<ChallengeFeedItem>> feed(String challengeId, {int limit = feedPageSize}) => _feed(challengeId)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snap) => snap.docs.map(ChallengeFeedItem.fromDoc).toList());

  /// The user's own numbers: the shared participant doc plus the private
  /// doc that holds the exact count ("Only show %") and which items
  /// (Juz / pages / ayahs) are already ticked.
  Future<MyChallengeProgress> myProgress(Challenge c) async {
    final user = currentUser;
    if (user == null) return const MyChallengeProgress(progress: 0);
    final partDoc = await _participantRef(c.id, user.uid).get();
    final part = partDoc.exists ? ChallengeParticipant.fromDoc(partDoc) : null;
    Map<String, dynamic>? private;
    try {
      private = (await _privateRef(c.id, user.uid).get()).data();
    } catch (e) {
      VoidLogger.error('Could not read private challenge progress', e);
    }
    final privateProgress = (private?['progress'] as num?)?.toInt() ?? 0;
    return MyChallengeProgress(
      progress: max<int>(part?.progress ?? 0, privateProgress),
      items: {for (final i in private?['items'] as List? ?? const []) if (i is num) i.toInt()},
      participant: part,
    );
  }

  /// Adds [amount], or the [items] (Juz / pages / ayah numbers) not already
  /// ticked, to the user's progress. Progress never goes down or past the
  /// target. Posts a feed update and, on reaching 100%, a "completed" one.
  Future<ProgressResult> logProgress(Challenge c, {int amount = 0, Iterable<int> items = const []}) async {
    final user = currentUser;
    if (user == null) throw StateError('Sign in to log progress');
    final now = DateTime.now();
    if (c.statusAt(now) != ChallengeStatus.active) return ProgressResult.nothing;
    final mine = await myProgress(c);
    final part = mine.participant;
    if (part == null) throw StateError('Not a member of this challenge');
    final today = challengeDayKey(now);
    if (c.oncePerDay && part.loggedDays.contains(today)) return ProgressResult.nothing;

    final newItems = items.toSet().difference(mine.items).toList()..sort();
    final wanted = items.isEmpty ? amount : newItems.length;
    final progress = min<int>(c.target, mine.progress + max<int>(0, wanted));
    final added = progress - mine.progress;
    if (added <= 0) return ProgressResult.nothing;
    // Items past the target (e.g. a 31st Juz) are not recorded.
    final recorded = newItems.take(added).toList();
    final percent = percentOf(progress, c.target);
    final completedNow = percent >= 100 && part.completedAt == null;
    final exact = part.showExactNumbers;

    final batch = _db.batch()
      ..update(_participantRef(c.id, user.uid), {
        'percent': percent,
        if (exact) 'progress': progress,
        'lastLoggedAt': FieldValue.serverTimestamp(),
        'loggedDays': FieldValue.arrayUnion([today]),
        if (completedNow) 'completedAt': FieldValue.serverTimestamp(),
      })
      ..set(_feed(c.id).doc(), {
        'kind': FeedKind.progress.name,
        'uid': user.uid,
        'name': part.displayName,
        'percent': percent,
        if (exact) 'value': added,
        if (exact && recorded.isNotEmpty) 'items': recorded,
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..set(
          _privateRef(c.id, user.uid),
          {
            'progress': progress,
            if (recorded.isNotEmpty) 'items': FieldValue.arrayUnion(recorded),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    if (completedNow) {
      batch.set(_feed(c.id).doc(), {
        'kind': FeedKind.completed.name,
        'uid': user.uid,
        'name': part.displayName,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await _commit(batch);
    logEvent('progress_logged', {'type': c.type.name, 'amount': added});
    if (completedNow) logEvent('challenge_completed', {'type': c.type.name, 'days': c.durationDays});
    return ProgressResult(added: added, progress: progress, percent: percent, completedNow: completedNow);
  }

  /// Commits [batch]; offline it stays queued and is sent later, so a
  /// slow server doesn't block the screen.
  Future<void> _commit(WriteBatch batch) async {
    try {
      await batch.commit().timeout(const Duration(seconds: 10));
    } on TimeoutException {
      VoidLogger.error('Challenge write queued (offline?)', 'timeout');
    }
  }

  /// Posts a short message (max [maxMessageLength], obvious profanity masked).
  Future<void> sendMessage(Challenge c, String text) async {
    final user = currentUser;
    if (user == null) return;
    final clean = _clip(ProfanityFilter.clean(text.trim()), maxMessageLength);
    if (clean.isEmpty) return;
    final name = await displayName();
    await _commit(_db.batch()
      ..set(_feed(c.id).doc(), {
        'kind': FeedKind.message.name,
        'uid': user.uid,
        'name': name,
        'text': clean,
        'createdAt': FieldValue.serverTimestamp(),
      }));
  }

  /// The id that limits nudges to one per sender, member and (UTC) day; it
  /// must match the one built in firestore.rules.
  static String nudgeId(String fromUid, String toUid, DateTime nowUtc) =>
      'nudge_${fromUid}_${toUid}_${nowUtc.year}-${nowUtc.month}-${nowUtc.day}';

  Future<bool> nudgedToday(Challenge c, String toUid) async {
    final user = currentUser;
    if (user == null) return true;
    try {
      final doc = await _feed(c.id).doc(nudgeId(user.uid, toUid, DateTime.now().toUtc())).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Sends [toUid] a gentle reminder to log today. Returns false if they
  /// were already nudged by this user today.
  Future<bool> nudge(Challenge c, String toUid) async {
    final user = currentUser;
    if (user == null || toUid == user.uid) return false;
    if (await nudgedToday(c, toUid)) return false;
    final name = await displayName();
    try {
      await _feed(c.id).doc(nudgeId(user.uid, toUid, DateTime.now().toUtc())).set({
        'kind': FeedKind.nudge.name,
        'uid': user.uid,
        'name': name,
        'targetUid': toUid,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // Queued offline.
    } on FirebaseException catch (e) {
      // Denied: a nudge with today's id already exists.
      VoidLogger.error('Nudge failed', e);
      return false;
    }
    return true;
  }

  /// Adds or removes the user's [key] reaction on [item].
  Future<void> toggleReaction(Challenge c, ChallengeFeedItem item, String key) async {
    final user = currentUser;
    if (user == null || !challengeReactionKeys.contains(key)) return;
    final mine = [...item.reactions[user.uid] ?? const <String>[]];
    if (!mine.remove(key)) mine.add(key);
    await _feed(c.id).doc(item.id).update({
      'reactions.${user.uid}': mine.isEmpty ? FieldValue.delete() : mine,
    }).timeout(const Duration(seconds: 10), onTimeout: () {});
  }

  /// Reports a feed item for review (admins read reports in the console).
  Future<void> report(Challenge c, ChallengeFeedItem item, String reason) async {
    final user = currentUser;
    if (user == null) return;
    await _db.collection('reports').add({
      'challengeId': c.id,
      'itemId': item.id,
      'itemUid': item.uid,
      'itemText': item.text,
      'reporterUid': user.uid,
      'reason': _clip(reason.trim(), maxReportLength),
      'createdAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 10));
    logEvent('challenge_report', {'kind': item.kind.name});
  }

  /// Deletes the user's own item (or any item, for the creator).
  Future<void> deleteItem(Challenge c, ChallengeFeedItem item) =>
      _feed(c.id).doc(item.id).delete().timeout(const Duration(seconds: 10));

  /// Creator only: removes [uid] and their progress from the challenge.
  Future<void> removeMember(Challenge c, String uid) async {
    final ref = _challenges.doc(c.id);
    await (_db.batch()
          ..update(ref, {
            'memberUids': FieldValue.arrayRemove([uid]),
            'memberCount': FieldValue.increment(-1),
          })
          ..delete(_participantRef(c.id, uid))
          ..update(_codes.doc(c.inviteCode), {'memberCount': FieldValue.increment(-1)}))
        .commit()
        .timeout(const Duration(seconds: 15));
  }

  /// Turns challenge notifications off or on for the user.
  Future<void> setMuted(Challenge c, bool muted) async {
    final user = currentUser;
    if (user == null) return;
    await _participantRef(c.id, user.uid).update({'muted': muted}).timeout(const Duration(seconds: 10), onTimeout: () {});
  }

  /// The user's active challenges, read once (for auto progress and the
  /// Home card). Empty when signed out or offline with nothing cached.
  Future<List<Challenge>> activeChallenges() async {
    final user = currentUser;
    if (user == null) return const [];
    try {
      final snap = await _challenges
          .where('memberUids', arrayContains: user.uid)
          .get()
          .timeout(const Duration(seconds: 8));
      final now = DateTime.now();
      final list = snap.docs.map(Challenge.fromDoc).where((c) => c.statusAt(now) == ChallengeStatus.active).toList();
      sortChallenges(list, now);
      return list;
    } catch (e) {
      VoidLogger.error('Could not load active challenges', e);
      return const [];
    }
  }

  // --- Dua Wall and public badges ---------------------------------------------

  static const maxDuaLength = 200;

  Stream<List<ChallengeDua>> duas(String challengeId) => _challenges
      .doc(challengeId)
      .collection('duas')
      .orderBy('createdAt')
      .snapshots()
      .map((snap) => snap.docs.map(ChallengeDua.fromDoc).toList());

  /// Writes the user's one dua for [toUid] (or [ChallengeDua.everyone]).
  Future<void> writeDua(Challenge c, String toUid, String text) async {
    final user = currentUser;
    if (user == null) return;
    final clean = _clip(ProfanityFilter.clean(text.trim()), maxDuaLength);
    if (clean.isEmpty) return;
    await _challenges.doc(c.id).collection('duas').doc('${user.uid}_$toUid').set({
      'fromUid': user.uid,
      'fromName': await displayName(),
      'toUid': toUid,
      'text': clean,
      'createdAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 10));
  }

  Future<void> deleteDua(Challenge c, ChallengeDua dua) =>
      _challenges.doc(c.id).collection('duas').doc(dua.id).delete().timeout(const Duration(seconds: 10));

  Future<void> reportDua(Challenge c, ChallengeDua dua, String reason) async {
    final user = currentUser;
    if (user == null) return;
    await _db.collection('reports').add({
      'challengeId': c.id,
      'itemId': 'dua:${dua.id}',
      'itemUid': dua.fromUid,
      'itemText': dua.text,
      'reporterUid': user.uid,
      'reason': _clip(reason.trim(), maxReportLength),
      'createdAt': FieldValue.serverTimestamp(),
    }).timeout(const Duration(seconds: 10));
  }

  /// The badges each member shows beside their name (empty when hidden).
  Future<Map<String, List<String>>> memberBadges(Iterable<String> uids) async {
    final out = <String, List<String>>{};
    await Future.wait(uids.toSet().map((uid) async {
      try {
        final doc = await _db.collection('publicProfiles').doc(uid).get().timeout(const Duration(seconds: 8));
        out[uid] = List<String>.from((doc.data()?['badges'] as List?)?.whereType<String>() ?? const <String>[]);
      } catch (_) {
        out[uid] = const [];
      }
    }));
    return out;
  }

  Future<void> _savePrivateProgress(String challengeId, int progress) async {
    final user = currentUser;
    if (user == null) return;
    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('challengeProgress')
          .doc(challengeId)
          .set({'progress': progress, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (e) {
      VoidLogger.error('Could not save private challenge progress', e);
    }
  }
}
