import { FieldValue, Firestore, Timestamp } from 'firebase-admin/firestore';
import type { Messaging, TokenMessage } from 'firebase-admin/messaging';
import { fill, Lang, langOf, stringsFor, unitLabel } from './i18n';

// Challenge notifications. Firestore layout: see lib/models/challenge.dart.
// Receivers are the other members, minus anyone who muted the challenge
// (participants/{uid}.muted) or turned challenge notifications off in
// Settings (users/{uid}.challengeNotifications == false). Each receiver
// gets the text in users/{uid}.language, as a push (users/{uid}.fcmToken)
// and as an entry in the in-app notification center
// (users/{uid}/notifications).

export interface FeedItem {
  kind: string;
  uid: string;
  name?: string;
  text?: string;
  value?: number;
  percent?: number;
  items?: number[];
  targetUid?: string;
}

export interface ChallengeDoc {
  title: string;
  type: string;
  unit: string;
  target: number;
  startAt: Timestamp;
  endAt: Timestamp;
  memberUids: string[];
  status?: string;
  surah?: number;
}

export interface Participant {
  uid: string;
  displayName?: string;
  percent?: number;
  progress?: number;
  muted?: boolean;
  completedAt?: Timestamp;
  wasBehind?: boolean;
}

export interface Recipient {
  uid: string;
  lang: Lang;
  token?: string;
  timeZone?: string;
}

/// Pushes go out at most 500 at a time (the FCM batch limit), and so do
/// Firestore batched writes.
const chunkSize = 500;
const maxMessagePreview = 140;

function chunks<T>(list: T[], size = chunkSize): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < list.length; i += size) out.push(list.slice(i, i + size));
  return out;
}

export function itemKind(c: Pick<ChallengeDoc, 'type' | 'unit' | 'surah'>): 'juz' | 'pages' | 'ayahs' | 'none' {
  if (c.type === 'memorizeSurah' && c.surah != null) return 'ayahs';
  if (c.type === 'khatam' || c.type === 'readQuran') {
    if (c.unit === 'juz') return 'juz';
    if (c.unit === 'pages') return 'pages';
  }
  return 'none';
}

/// "1–5, 8, 10–12".
export function compactRanges(numbers: number[]): string {
  const sorted = [...new Set(numbers)].sort((a, b) => a - b);
  const parts: string[] = [];
  for (let i = 0; i < sorted.length; ) {
    let j = i;
    while (j + 1 < sorted.length && sorted[j + 1] === sorted[j] + 1) j++;
    parts.push(i === j ? `${sorted[i]}` : `${sorted[i]}–${sorted[j]}`);
    i = j + 1;
  }
  return parts.join(', ');
}

/// The notification text for a new feed item, or null for kinds that
/// don't notify.
export function feedBody(item: FeedItem, c: ChallengeDoc, lang: Lang, name: string): string | null {
  const s = stringsFor(lang);
  switch (item.kind) {
    case 'joined':
      return fill(s.joined, { name });
    case 'completed':
      return fill(s.completed, { name });
    case 'nudge':
      return fill(s.nudge, { name });
    case 'message': {
      const text = (item.text ?? '').trim();
      if (!text) return null;
      const preview = text.length > maxMessagePreview ? `${text.slice(0, maxMessagePreview - 1)}…` : text;
      return fill(s.message, { name, text: preview });
    }
    case 'progress': {
      let body: string;
      const kind = itemKind(c);
      if (item.value == null) {
        body = fill(s.progressed, { name });
      } else if (item.items?.length && kind !== 'none') {
        body = fill(s[kind], { name, items: compactRanges(item.items) });
      } else {
        body = fill(s.amount, { name, amount: item.value, unit: unitLabel(c.unit, lang) });
      }
      return item.percent != null ? `${body} · ${Math.floor(item.percent)}%` : body;
    }
    default:
      return null;
  }
}

/// Users who want challenge notifications, with their token and language.
export async function loadRecipients(db: Firestore, uids: string[]): Promise<Recipient[]> {
  const out: Recipient[] = [];
  for (const group of chunks([...new Set(uids)], 100)) {
    if (!group.length) continue;
    const docs = await db.getAll(...group.map((uid) => db.collection('users').doc(uid)));
    for (const doc of docs) {
      const d = doc.data() ?? {};
      if (d.challengeNotifications === false) continue;
      out.push({
        uid: doc.id,
        lang: langOf(d.language),
        token: typeof d.fcmToken === 'string' && d.fcmToken ? d.fcmToken : undefined,
        timeZone: typeof d.timeZone === 'string' ? d.timeZone : undefined,
      });
    }
  }
  return out;
}

const invalidTokenCodes = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

/// Sends [bodyFor]'s text to [recipients] (push + in-app entry), grouped
/// per challenge: one Android tag and iOS thread per challenge, so a busy
/// day shows as one stack instead of many separate banners. Tokens FCM
/// reports as dead are removed from their user docs.
export async function deliver(
  db: Firestore,
  messaging: Messaging,
  challengeId: string,
  title: string,
  recipients: Recipient[],
  bodyFor: (lang: Lang) => string | null,
  kind: string,
): Promise<{ sent: number; removedTokens: number }> {
  const ready = recipients
    .map((r) => ({ r, body: bodyFor(r.lang) }))
    .filter((x): x is { r: Recipient; body: string } => x.body != null);
  if (!ready.length) return { sent: 0, removedTokens: 0 };

  for (const group of chunks(ready)) {
    const batch = db.batch();
    for (const { r, body } of group) {
      batch.set(db.collection('users').doc(r.uid).collection('notifications').doc(), {
        title,
        body,
        type: 'challenge',
        kind,
        challengeId,
        isRead: false,
        createdAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  const withToken = ready.filter((x) => x.r.token);
  let sent = 0;
  let removedTokens = 0;
  for (const group of chunks(withToken)) {
    const messages: TokenMessage[] = group.map(({ r, body }) => ({
      token: r.token!,
      notification: { title, body },
      data: { type: 'challenge', challengeId, kind },
      android: {
        collapseKey: challengeId,
        notification: { tag: `challenge_${challengeId}`, channelId: 'challenges' },
      },
      apns: { payload: { aps: { 'thread-id': `challenge_${challengeId}`, sound: 'default' } } },
    }));
    const res = await messaging.sendEach(messages);
    sent += res.successCount;
    await Promise.all(
      res.responses.map(async (response, i) => {
        if (response.success || !invalidTokenCodes.has(response.error?.code ?? '')) return;
        const { r } = group[i];
        const ref = db.collection('users').doc(r.uid);
        // Only if the user hasn't registered a newer token meanwhile.
        const removed = await db.runTransaction(async (tx) => {
          const snap = await tx.get(ref);
          if (snap.get('fcmToken') !== r.token) return false;
          tx.update(ref, { fcmToken: FieldValue.delete() });
          return true;
        });
        if (removed) removedTokens++;
      }),
    );
  }
  return { sent, removedTokens };
}

async function mutedUids(db: Firestore, challengeId: string): Promise<Set<string>> {
  const snap = await db.collection('challenges').doc(challengeId).collection('participants').where('muted', '==', true).get();
  return new Set(snap.docs.map((d) => d.id));
}

/// Handles a new challenges/{id}/feed item: everyone else hears about it,
/// except a nudge, which goes only to the member it was for.
export async function notifyFeedItem(
  db: Firestore,
  messaging: Messaging,
  challengeId: string,
  item: FeedItem,
): Promise<{ sent: number; removedTokens: number }> {
  const snap = await db.collection('challenges').doc(challengeId).get();
  if (!snap.exists) return { sent: 0, removedTokens: 0 };
  const c = snap.data() as ChallengeDoc;
  const members = c.memberUids ?? [];
  let uids =
    item.kind === 'nudge'
      ? members.filter((uid) => uid === item.targetUid)
      : members.filter((uid) => uid !== item.uid);
  if (!uids.length) return { sent: 0, removedTokens: 0 };
  const muted = await mutedUids(db, challengeId);
  uids = uids.filter((uid) => !muted.has(uid));

  let name = item.name ?? '';
  if (!name) {
    const sender = await db.collection('challenges').doc(challengeId).collection('participants').doc(item.uid).get();
    name = (sender.get('displayName') as string | undefined) ?? '';
  }
  const recipients = await loadRecipients(db, uids);
  return deliver(db, messaging, challengeId, c.title, recipients, (lang) => feedBody(item, c, lang, name), item.kind);
}

// --- Daily reminders ---------------------------------------------------------

/// The hour (0-23) and date ("yyyy-mm-dd") at [now] in [timeZone]; UTC
/// when the zone is missing or unknown.
export function localTime(now: Date, timeZone?: string): { hour: number; day: string } {
  let parts: Intl.DateTimeFormatPart[];
  try {
    parts = new Intl.DateTimeFormat('en-CA', {
      timeZone: timeZone || 'UTC',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      hourCycle: 'h23',
    }).formatToParts(now);
  } catch {
    return localTime(now, 'UTC');
  }
  const get = (type: string) => parts.find((p) => p.type === type)?.value ?? '';
  return { hour: Number(get('hour')) % 24, day: `${get('year')}-${get('month')}-${get('day')}` };
}

export type PaceReminder = { kind: 'lastDay' } | { kind: 'behind'; behind: number };

/// "1 day left" in the challenge's last 24 hours; otherwise "behind" when
/// the member is clearly behind an even pace (at least 1 unit and 5% of
/// the target). Nothing for members who finished.
export function paceReminder(c: ChallengeDoc, p: Participant, now: Date): PaceReminder | null {
  const start = c.startAt.toMillis();
  const end = c.endAt.toMillis();
  const t = now.getTime();
  if (t < start || t >= end) return null;
  if (p.completedAt || (p.percent ?? 0) >= 100) return null;
  if (end - t <= 24 * 60 * 60 * 1000) return { kind: 'lastDay' };
  const expected = (c.target * (t - start)) / (end - start);
  const progress = p.progress ?? Math.floor(((p.percent ?? 0) * c.target) / 100);
  const behind = Math.floor(expected - progress);
  return behind >= Math.max(1, Math.round(c.target * 0.05)) ? { kind: 'behind', behind } : null;
}

/// Keeps the stored `status` in step with the dates (used by the join rule
/// and the reminder query).
export async function updateStatuses(db: Firestore, now: Date): Promise<number> {
  const at = Timestamp.fromDate(now);
  const started = await db.collection('challenges').where('status', '==', 'upcoming').where('startAt', '<=', at).get();
  const ended = await db.collection('challenges').where('status', '==', 'active').where('endAt', '<=', at).get();
  const updates = [
    ...started.docs.map((d) => ({ ref: d.ref, status: d.get('endAt').toMillis() <= now.getTime() ? 'finished' : 'active' })),
    ...ended.docs.map((d) => ({ ref: d.ref, status: 'finished' })),
  ];
  for (const group of chunks(updates)) {
    const batch = db.batch();
    for (const u of group) batch.update(u.ref, { status: u.status });
    await batch.commit();
  }
  return updates.length;
}

/// Runs every hour: sends each member who is behind pace (or in the last
/// day) one reminder per challenge per day, at [reminderHour] in their own
/// time zone (users/{uid}.timeZone).
export async function runReminders(
  db: Firestore,
  messaging: Messaging,
  now: Date,
  reminderHour = 19,
): Promise<{ sent: number; reminded: number }> {
  await updateStatuses(db, now);
  const active = await db
    .collection('challenges')
    .where('status', '==', 'active')
    .where('endAt', '>', Timestamp.fromDate(now))
    .get();

  let sent = 0;
  let reminded = 0;
  for (const doc of active.docs) {
    const c = doc.data() as ChallengeDoc;
    const participants = await doc.ref.collection('participants').get();
    const due = new Map<string, PaceReminder>();
    for (const p of participants.docs) {
      const data = { uid: p.id, ...(p.data() as Omit<Participant, 'uid'>) };
      if (!(c.memberUids ?? []).includes(p.id)) continue;
      const reminder = paceReminder(c, data, now);
      if (reminder) due.set(p.id, reminder);
      // Remembered for the "Comeback" badge (finishing after falling behind).
      if (reminder?.kind === 'behind' && !data.wasBehind) await p.ref.update({ wasBehind: true });
    }
    for (const p of participants.docs) if (p.get('muted') === true) due.delete(p.id);
    if (!due.size) continue;

    const recipients = (await loadRecipients(db, [...due.keys()])).filter(
      (r) => localTime(now, r.timeZone).hour === reminderHour,
    );
    for (const r of recipients) {
      const { day } = localTime(now, r.timeZone);
      const logRef = db.collection('users').doc(r.uid).collection('serverState').doc('challengeReminders');
      // Once per challenge per local day, even if the job runs twice.
      const fresh = await db.runTransaction(async (tx) => {
        const log = await tx.get(logRef);
        if (log.get(doc.id) === day) return false;
        tx.set(logRef, { [doc.id]: day }, { merge: true });
        return true;
      });
      if (!fresh) continue;
      const reminder = due.get(r.uid)!;
      const res = await deliver(
        db,
        messaging,
        doc.id,
        c.title,
        [r],
        (lang) => {
          const s = stringsFor(lang);
          return reminder.kind === 'lastDay'
            ? s.lastDay
            : fill(s.behind, { n: reminder.behind, unit: unitLabel(c.unit, lang) });
        },
        reminder.kind,
      );
      sent += res.sent;
      reminded++;
    }
  }
  return { sent, reminded };
}
