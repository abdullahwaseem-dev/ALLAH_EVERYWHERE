import { FieldValue, Firestore, Timestamp } from 'firebase-admin/firestore';
import type { Messaging } from 'firebase-admin/messaging';
import { fill, stringsFor } from './i18n';
import { ChallengeDoc, deliver, loadRecipients } from './notify';

// Challenge rewards, awarded only here (the Admin SDK bypasses the rules;
// users can read users/{uid}/rewards but never write it). Badge ids and
// thresholds match lib/data/rewards_data.dart.

export const encouragerReactions = 50;
export const familyBuilderJoins = 5;
const day = 24 * 60 * 60 * 1000;

export interface CompletedParticipant {
  displayName?: string;
  completedAt?: Timestamp;
  loggedDays?: string[];
  wasBehind?: boolean;
}

export type CertificateResult = 'perfect' | 'early' | 'completed';

/// "Never missed a day" when a progress entry was logged on every day from
/// the start to the day of completion; "completed early" when it was done
/// at least a day before the end; otherwise "completed".
export function certificateResult(c: ChallengeDoc, p: CompletedParticipant): CertificateResult {
  const done = p.completedAt?.toMillis() ?? Date.now();
  const daysTaken = Math.max(1, Math.ceil((done - c.startAt.toMillis()) / day));
  const logged = new Set(p.loggedDays ?? []).size;
  if (daysTaken >= 2 && logged >= daysTaken) return 'perfect';
  if (c.endAt.toMillis() - done >= day) return 'early';
  return 'completed';
}

/// The badges a completion earns.
export function completionBadges(c: ChallengeDoc, p: CompletedParticipant): string[] {
  const result = certificateResult(c, p);
  return [
    'first_challenge',
    ...(c.type === 'khatam' ? ['khatam_finisher'] : []),
    ...(result === 'perfect' ? ['steadfast'] : []),
    ...(result === 'early' ? ['early_bird'] : []),
    ...(p.wasBehind ? ['comeback'] : []),
  ];
}

/// Gives [uid] the badge once (a second award keeps the first date).
/// Returns true when it is new.
export async function awardBadge(db: Firestore, uid: string, badgeId: string, source?: string): Promise<boolean> {
  try {
    await db.collection('users').doc(uid).collection('rewards').doc(`badge_${badgeId}`).create({
      type: 'badge',
      badgeId,
      ...(source ? { source } : {}),
      earnedAt: FieldValue.serverTimestamp(),
    });
    return true;
  } catch (e) {
    if ((e as { code?: number }).code === 6) return false; // ALREADY_EXISTS
    throw e;
  }
}

/// Copies the user's badge ids to publicProfiles/{uid} (readable by other
/// members, to show beside their name), or an empty list if they hid them.
export async function publishProfile(db: Firestore, uid: string): Promise<void> {
  const user = await db.collection('users').doc(uid).get();
  const hidden = user.get('hideBadges') === true;
  const earned = await db.collection('users').doc(uid).collection('rewards').where('type', '==', 'badge').get();
  const ids = earned.docs
    .sort((a, b) => (a.get('earnedAt')?.toMillis?.() ?? 0) - (b.get('earnedAt')?.toMillis?.() ?? 0))
    .map((d) => d.get('badgeId') as string);
  await db.collection('publicProfiles').doc(uid).set({ badges: hidden ? [] : ids, updatedAt: FieldValue.serverTimestamp() });
}

/// A member reached 100%: certificate, garden plants and badges.
export async function awardCompletion(
  db: Firestore,
  challengeId: string,
  uid: string,
  p: CompletedParticipant,
): Promise<string[]> {
  const snap = await db.collection('challenges').doc(challengeId).get();
  if (!snap.exists) return [];
  const c = snap.data() as ChallengeDoc & { dedication?: string };
  const rewards = db.collection('users').doc(uid).collection('rewards');
  const earnedAt = FieldValue.serverTimestamp();
  const batch = db.batch();
  batch.set(rewards.doc(`cert_${challengeId}`), {
    type: 'certificate',
    challengeId,
    title: c.title,
    challengeType: c.type,
    unit: c.unit,
    target: c.target,
    startAt: c.startAt,
    endAt: c.endAt,
    completedAt: p.completedAt ?? Timestamp.now(),
    result: certificateResult(c, p),
    name: p.displayName ?? '',
    ...(c.dedication ? { dedication: c.dedication } : {}),
    earnedAt,
  });
  batch.set(rewards.doc(`garden_tree_${challengeId}`), { type: 'garden', kind: 'tree', label: c.title, earnedAt });
  if (c.type === 'khatam') {
    batch.set(rewards.doc(`garden_fountain_${challengeId}`), { type: 'garden', kind: 'fountain', label: c.title, earnedAt });
  }
  await batch.commit();
  const fresh: string[] = [];
  for (const badge of completionBadges(c, p)) {
    if (await awardBadge(db, uid, badge, challengeId)) fresh.push(badge);
  }
  await publishProfile(db, uid);
  return fresh;
}

/// Counts reactions a member sends, once per feed item (taking a reaction
/// back and adding it again doesn't count twice). 50 earn "Encourager".
export async function countReactions(
  db: Firestore,
  challengeId: string,
  itemId: string,
  before: Record<string, string[]> | undefined,
  after: Record<string, string[]> | undefined,
): Promise<string[]> {
  const added = Object.entries(after ?? {})
    .filter(([uid, keys]) => keys?.length && !(before?.[uid]?.length))
    .map(([uid]) => uid);
  const earned: string[] = [];
  for (const uid of added) {
    const marker = db.collection('challenges').doc(challengeId).collection('feed').doc(itemId).collection('reactors').doc(uid);
    const stats = db.collection('users').doc(uid).collection('serverState').doc('stats');
    const total = await db.runTransaction(async (tx) => {
      const [m, s] = await Promise.all([tx.get(marker), tx.get(stats)]);
      if (m.exists) return null;
      const next = ((s.get('reactionsSent') as number | undefined) ?? 0) + 1;
      tx.create(marker, { at: FieldValue.serverTimestamp() });
      tx.set(stats, { reactionsSent: next }, { merge: true });
      return next;
    });
    if (total != null && total >= encouragerReactions && (await awardBadge(db, uid, 'encourager', challengeId))) {
      await publishProfile(db, uid);
      earned.push(uid);
    }
  }
  return earned;
}

/// Counts the different people who joined the creator's challenges. 5 earn
/// "Family Builder".
export async function countJoin(db: Firestore, challengeId: string, joinerUid: string): Promise<boolean> {
  const snap = await db.collection('challenges').doc(challengeId).get();
  const creator = snap.get('creatorUid') as string | undefined;
  if (!creator || creator === joinerUid) return false;
  const stats = db.collection('users').doc(creator).collection('serverState').doc('stats');
  const invited = await db.runTransaction(async (tx) => {
    const s = await tx.get(stats);
    const set = new Set<string>((s.get('invitedUids') as string[] | undefined) ?? []);
    set.add(joinerUid);
    tx.set(stats, { invitedUids: [...set] }, { merge: true });
    return set.size;
  });
  if (invited >= familyBuilderJoins && (await awardBadge(db, creator, 'family_builder', challengeId))) {
    await publishProfile(db, creator);
    return true;
  }
  return false;
}

export interface Dua {
  fromUid: string;
  fromName?: string;
  toUid: string;
  text: string;
}

/// "Your family made 6 duas for you" to the receiver (one notification per
/// challenge that updates as duas come in), or, for a dua for everyone,
/// "{name} made a dua for everyone" to the other members.
export async function notifyDua(db: Firestore, messaging: Messaging, challengeId: string, dua: Dua) {
  const snap = await db.collection('challenges').doc(challengeId).get();
  if (!snap.exists) return { sent: 0, removedTokens: 0 };
  const c = snap.data() as ChallengeDoc;
  const name = dua.fromName ?? '';
  if (dua.toUid === 'all') {
    const recipients = await loadRecipients(db, (c.memberUids ?? []).filter((u) => u !== dua.fromUid));
    return deliver(db, messaging, challengeId, c.title, recipients, (lang) => fill(stringsFor(lang).duaAll, { name }), 'dua');
  }
  if (!(c.memberUids ?? []).includes(dua.toUid)) return { sent: 0, removedTokens: 0 };
  const count = (await db.collection('challenges').doc(challengeId).collection('duas').where('toUid', '==', dua.toUid).count().get())
    .data().count;
  const recipients = await loadRecipients(db, [dua.toUid]);
  return deliver(
    db,
    messaging,
    challengeId,
    c.title,
    recipients,
    (lang) => {
      const s = stringsFor(lang);
      return count <= 1 ? fill(s.duaOne, { name }) : fill(s.duaMany, { n: count });
    },
    'dua',
  );
}
