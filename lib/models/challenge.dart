import 'package:cloud_firestore/cloud_firestore.dart';

// Challenges: a shared goal (e.g. a Khatam in 10 days) that family and
// friends join with an invite code. Firestore layout (see firestore.rules):
// - challenges/{id}                      [Challenge]
// - challenges/{id}/participants/{uid}   [ChallengeParticipant]
// - challenges/{id}/feed/{itemId}        progress, messages, reactions
// - inviteCodes/{code}                   [ChallengePreview], read before joining
// - users/{uid}/challengeProgress/{id}   the member's exact number when they
//                                        chose "Only show %"

/// The kinds of challenge a user can start. [name] is the Firestore value.
enum ChallengeType {
  khatam,
  readQuran,
  memorizeSurah,
  memorizeHadith,
  dhikr,
  fasting,
  dailyPrayer,
  custom;

  static ChallengeType fromName(String? name) =>
      ChallengeType.values.firstWhere((t) => t.name == name, orElse: () => ChallengeType.custom);
}

/// Units with a translated label; any other string is a custom unit typed by
/// the creator.
class ChallengeUnits {
  ChallengeUnits._();

  static const juz = 'juz';
  static const pages = 'pages';
  static const ayahs = 'ayahs';
  static const ahadith = 'ahadith';
  static const count = 'count';
  static const days = 'days';
}

enum ChallengeStatus { upcoming, active, finished }

/// Days remaining until [end], counting a part day as a whole day.
int daysUntil(DateTime end, DateTime now) {
  final ms = end.difference(now).inMilliseconds;
  if (ms <= 0) return 0;
  return (ms / Duration.millisecondsPerDay).ceil();
}

/// The progress stored for others to see, 0-100, rounded down so a member
/// never shows 100% before actually finishing.
double percentOf(int progress, int target) {
  if (target <= 0) return 0;
  final p = progress * 100 / target;
  if (p >= 100) return 100;
  return (p * 10).floorToDouble() / 10;
}

class Challenge {
  final String id;
  final String title;
  final ChallengeType type;
  final String unit;
  final int target;
  final DateTime startAt;
  final DateTime endAt;
  final String creatorUid;
  final String creatorName;
  final String inviteCode;
  final List<String> memberUids;
  final int memberCount;
  final String intention;

  /// Optional, e.g. "For my late grandmother" (shown on the certificate).
  final String dedication;

  /// Optional non-money promise from the creator to the winner.
  final String familyPromise;

  /// Surah number for [ChallengeType.memorizeSurah].
  final int? surah;

  const Challenge({
    required this.id,
    required this.title,
    required this.type,
    required this.unit,
    required this.target,
    required this.startAt,
    required this.endAt,
    required this.creatorUid,
    required this.creatorName,
    required this.inviteCode,
    required this.memberUids,
    required this.memberCount,
    this.intention = '',
    this.dedication = '',
    this.familyPromise = '',
    this.surah,
  });

  /// Worked out from the dates, so it is right even before the server's
  /// daily job updates the stored `status`.
  ChallengeStatus statusAt(DateTime now) {
    if (now.isBefore(startAt)) return ChallengeStatus.upcoming;
    if (!now.isBefore(endAt)) return ChallengeStatus.finished;
    return ChallengeStatus.active;
  }

  int get durationDays => daysUntil(endAt, startAt);

  factory Challenge.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return Challenge(
      id: doc.id,
      title: d['title'] as String? ?? '',
      type: ChallengeType.fromName(d['type'] as String?),
      unit: d['unit'] as String? ?? ChallengeUnits.count,
      target: (d['target'] as num?)?.toInt() ?? 1,
      startAt: (d['startAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endAt: (d['endAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      creatorUid: d['creatorUid'] as String? ?? '',
      creatorName: d['creatorName'] as String? ?? '',
      inviteCode: d['inviteCode'] as String? ?? '',
      memberUids: List<String>.from(d['memberUids'] as List? ?? const []),
      memberCount: (d['memberCount'] as num?)?.toInt() ?? 0,
      intention: d['intention'] as String? ?? '',
      dedication: d['dedication'] as String? ?? '',
      familyPromise: d['familyPromise'] as String? ?? '',
      surah: (d['surah'] as num?)?.toInt(),
    );
  }
}

/// What a joiner sees before confirming, from inviteCodes/{code}.
class ChallengePreview {
  final String code;
  final String challengeId;
  final String title;
  final ChallengeType type;
  final String creatorName;
  final DateTime startAt;
  final DateTime endAt;
  final int memberCount;

  const ChallengePreview({
    required this.code,
    required this.challengeId,
    required this.title,
    required this.type,
    required this.creatorName,
    required this.startAt,
    required this.endAt,
    required this.memberCount,
  });

  factory ChallengePreview.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return ChallengePreview(
      code: doc.id,
      challengeId: d['challengeId'] as String? ?? '',
      title: d['title'] as String? ?? '',
      type: ChallengeType.fromName(d['type'] as String?),
      creatorName: d['creatorName'] as String? ?? '',
      startAt: (d['startAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endAt: (d['endAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      memberCount: (d['memberCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChallengeParticipant {
  final String uid;
  final String displayName;
  final double percent;

  /// Null when the member chose "Only show %".
  final int? progress;
  final bool showExactNumbers;
  final bool muted;
  final DateTime? completedAt;
  final List<String> loggedDays;

  const ChallengeParticipant({
    required this.uid,
    required this.displayName,
    required this.percent,
    this.progress,
    this.showExactNumbers = true,
    this.muted = false,
    this.completedAt,
    this.loggedDays = const [],
  });

  factory ChallengeParticipant.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return ChallengeParticipant(
      uid: doc.id,
      displayName: d['displayName'] as String? ?? '',
      percent: (d['percent'] as num?)?.toDouble() ?? 0,
      progress: (d['progress'] as num?)?.toInt(),
      showExactNumbers: d['showExactNumbers'] as bool? ?? true,
      muted: d['muted'] as bool? ?? false,
      completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
      loggedDays: List<String>.from(d['loggedDays'] as List? ?? const []),
    );
  }
}

/// The reactions members can leave on a feed item, in display order.
/// Stored as `reactions: {uid: [key, ...]}` on the item.
const challengeReactionKeys = ['mashaallah', 'barakallah', 'ameen', 'dua', 'love'];

enum FeedKind {
  joined,
  progress,
  completed,
  message,
  nudge,
  unknown;

  static FeedKind fromName(String? name) =>
      FeedKind.values.firstWhere((k) => k.name == name, orElse: () => FeedKind.unknown);
}

/// One entry in a challenge's chat-style feed.
class ChallengeFeedItem {
  final String id;
  final FeedKind kind;
  final String uid;

  /// The sender's name when the item was posted (shown if they later leave).
  final String name;
  final String text;

  /// How much was added (progress items, exact numbers only).
  final int? value;

  /// The sender's percentage after a progress update.
  final double? percent;

  /// Which Juz / pages / ayahs a progress update covered (exact numbers only).
  final List<int> items;
  final String? targetUid;
  final DateTime createdAt;
  final Map<String, List<String>> reactions;

  const ChallengeFeedItem({
    required this.id,
    required this.kind,
    required this.uid,
    required this.createdAt,
    this.name = '',
    this.text = '',
    this.value,
    this.percent,
    this.items = const [],
    this.targetUid,
    this.reactions = const {},
  });

  int reactionCount(String key) => reactions.values.where((keys) => keys.contains(key)).length;

  bool reactedBy(String uid, String key) => reactions[uid]?.contains(key) ?? false;

  factory ChallengeFeedItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    final rawReactions = d['reactions'];
    return ChallengeFeedItem(
      id: doc.id,
      kind: FeedKind.fromName(d['kind'] as String?),
      uid: d['uid'] as String? ?? '',
      // "joined" items from before `name` existed carry the name in `text`.
      name: d['name'] as String? ?? (d['kind'] == 'joined' ? d['text'] as String? ?? '' : ''),
      text: d['text'] as String? ?? '',
      value: (d['value'] as num?)?.toInt(),
      percent: (d['percent'] as num?)?.toDouble(),
      items: [for (final i in d['items'] as List? ?? const []) if (i is num) i.toInt()],
      targetUid: d['targetUid'] as String?,
      // Null while the server timestamp of a just-sent item is pending.
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reactions: {
        if (rawReactions is Map)
          for (final e in rawReactions.entries)
            if (e.key is String && e.value is List) e.key as String: List<String>.from((e.value as List).whereType<String>()),
      },
    );
  }
}

/// What a member logs against: numbered items (Juz, Mushaf pages, ayahs of
/// a surah) that can each be ticked once, or a plain count.
enum ChallengeItemKind { none, juz, pages, ayahs }

extension ChallengeLogging on Challenge {
  ChallengeItemKind get itemKind {
    if (type == ChallengeType.memorizeSurah && surah != null) return ChallengeItemKind.ayahs;
    if (type == ChallengeType.khatam || type == ChallengeType.readQuran) {
      if (unit == ChallengeUnits.juz) return ChallengeItemKind.juz;
      if (unit == ChallengeUnits.pages) return ChallengeItemKind.pages;
    }
    return ChallengeItemKind.none;
  }

  /// Fasting and Tahajjud / Fajr: at most one tick per day.
  bool get oncePerDay => type == ChallengeType.fasting || type == ChallengeType.dailyPrayer;
}

/// The local calendar day as "yyyy-mm-dd" (stored in `loggedDays`).
String challengeDayKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

/// "1–5, 8, 10–12" for a list of item numbers.
String compactRanges(Iterable<int> numbers) {
  final sorted = numbers.toSet().toList()..sort();
  final parts = <String>[];
  var i = 0;
  while (i < sorted.length) {
    var j = i;
    while (j + 1 < sorted.length && sorted[j + 1] == sorted[j] + 1) {
      j++;
    }
    parts.add(i == j ? '${sorted[i]}' : '${sorted[i]}–${sorted[j]}');
    i = j + 1;
  }
  return parts.join(', ');
}

/// The member's own numbers, including the exact count kept privately when
/// they chose "Only show %".
class MyChallengeProgress {
  final int progress;
  final Set<int> items;
  final ChallengeParticipant? participant;

  const MyChallengeProgress({required this.progress, this.items = const {}, this.participant});
}

/// The outcome of [ChallengeService.logProgress].
class ProgressResult {
  final int added;
  final int progress;
  final double percent;
  final bool completedNow;

  const ProgressResult({required this.added, required this.progress, required this.percent, this.completedNow = false});

  static const nothing = ProgressResult(added: 0, progress: 0, percent: 0);
}

/// A dua on a finished challenge's Dua Wall, for one member who completed
/// it, or for everyone ([toUid] "all").
class ChallengeDua {
  static const everyone = 'all';

  final String id;
  final String fromUid;
  final String fromName;
  final String toUid;
  final String text;
  final DateTime createdAt;

  const ChallengeDua({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.toUid,
    required this.text,
    required this.createdAt,
  });

  factory ChallengeDua.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const <String, dynamic>{};
    return ChallengeDua(
      id: doc.id,
      fromUid: d['fromUid'] as String? ?? '',
      fromName: d['fromName'] as String? ?? '',
      toUid: d['toUid'] as String? ?? '',
      text: d['text'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
