// Runs against the Firestore emulator (`npm test`), with a fake FCM client
// that records messages instead of sending them.
import assert from 'node:assert/strict';
import { after, beforeEach, describe, test } from 'node:test';
import { initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import type { BatchResponse, Messaging, TokenMessage } from 'firebase-admin/messaging';
import {
  ChallengeDoc,
  compactRanges,
  feedBody,
  localTime,
  notifyFeedItem,
  paceReminder,
  runReminders,
} from '../notify';

initializeApp({ projectId: 'demo-allah-everywhere' });
const db = getFirestore();
const day = 24 * 60 * 60 * 1000;

let sentMessages: TokenMessage[] = [];
const messaging = {
  async sendEach(messages: TokenMessage[]): Promise<BatchResponse> {
    sentMessages.push(...messages);
    const responses = messages.map((m) =>
      m.token === 'dead-token'
        ? { success: false, error: { code: 'messaging/registration-token-not-registered' } }
        : { success: true, messageId: 'x' },
    );
    return {
      responses,
      successCount: responses.filter((r) => r.success).length,
      failureCount: responses.filter((r) => !r.success).length,
    } as BatchResponse;
  },
} as unknown as Messaging;

async function clear() {
  const res = await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/demo-allah-everywhere/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  assert.ok(res.ok);
}

function challenge(overrides: Partial<ChallengeDoc> = {}, now = Date.now()): ChallengeDoc {
  return {
    title: 'Ramadan Khatam',
    type: 'khatam',
    unit: 'juz',
    target: 30,
    startAt: Timestamp.fromMillis(now - 5 * day),
    endAt: Timestamp.fromMillis(now + 5 * day),
    memberUids: ['alice', 'bob', 'carol', 'dave', 'erin'],
    status: 'active',
    ...overrides,
  };
}

async function seed(now = Date.now()) {
  await db.doc('challenges/ch1').set(challenge({}, now));
  const people: [string, string, Record<string, unknown>, Record<string, unknown>][] = [
    ['alice', 'Amina', { language: 'en', fcmToken: 'token-alice', timeZone: 'Asia/Karachi' }, { progress: 15, percent: 50 }],
    ['bob', 'Bilal', { language: 'ur', fcmToken: 'token-bob', timeZone: 'Asia/Karachi' }, { progress: 5, percent: 16.6 }],
    ['carol', 'Carol', { language: 'ar', fcmToken: 'dead-token', timeZone: 'Europe/London' }, { percent: 10, showExactNumbers: false }],
    ['dave', 'Dawud', { language: 'fr', fcmToken: 'token-dave' }, { progress: 0, percent: 0, muted: true }],
    ['erin', 'Erin', { language: 'de', fcmToken: 'token-erin', challengeNotifications: false }, { progress: 0, percent: 0 }],
  ];
  for (const [uid, name, user, part] of people) {
    await db.doc(`users/${uid}`).set(user);
    await db.doc(`challenges/ch1/participants/${uid}`).set({ displayName: name, muted: false, ...part });
  }
}

beforeEach(async () => {
  sentMessages = [];
  await clear();
});

after(clear);

describe('feed notifications', () => {
  test('a message reaches the other members in their own language, grouped per challenge', async () => {
    await seed();
    const result = await notifyFeedItem(db, messaging, 'ch1', { kind: 'message', uid: 'alice', name: 'Amina', text: 'Bismillah!' });
    // bob + carol; dave muted, erin turned challenge notifications off.
    assert.deepEqual(sentMessages.map((m) => m.token).sort(), ['dead-token', 'token-bob']);
    const toBob = sentMessages.find((m) => m.token === 'token-bob')!;
    assert.equal(toBob.notification?.title, 'Ramadan Khatam');
    assert.equal(toBob.notification?.body, 'Amina: Bismillah!');
    assert.equal(toBob.data?.challengeId, 'ch1');
    assert.equal(toBob.android?.notification?.tag, 'challenge_ch1');
    assert.equal((toBob.apns?.payload?.aps as Record<string, unknown>)['thread-id'], 'challenge_ch1');
    assert.equal(result.sent, 1);

    // The dead token is removed; the in-app notification center gets an entry.
    assert.equal((await db.doc('users/carol').get()).get('fcmToken'), undefined);
    const inbox = await db.collection('users/bob/notifications').get();
    assert.equal(inbox.size, 1);
    assert.equal(inbox.docs[0].get('type'), 'challenge');
    assert.equal(inbox.docs[0].get('challengeId'), 'ch1');
    assert.equal((await db.collection('users/dave/notifications').get()).size, 0);
    assert.equal((await db.collection('users/alice/notifications').get()).size, 0);
  });

  test('a nudge goes only to the member it was for', async () => {
    await seed();
    await notifyFeedItem(db, messaging, 'ch1', { kind: 'nudge', uid: 'alice', name: 'Amina', targetUid: 'bob' });
    assert.deepEqual(sentMessages.map((m) => m.token), ['token-bob']);
    assert.equal(sentMessages[0].notification?.body, 'Amina نے آپ کو آج درج کرنے کی یاد دلائی');
  });

  test('progress texts follow the challenge type and privacy', () => {
    const c = challenge();
    assert.equal(feedBody({ kind: 'progress', uid: 'a', value: 2, items: [11, 12], percent: 40 }, c, 'en', 'Ahmed'),
      'Ahmed finished Juz 11–12 · 40%');
    assert.equal(feedBody({ kind: 'progress', uid: 'a', percent: 40 }, c, 'en', 'Ahmed'), 'Ahmed made progress · 40%');
    const dhikr = challenge({ type: 'dhikr', unit: 'count', target: 1000 });
    assert.equal(feedBody({ kind: 'progress', uid: 'a', value: 100, percent: 10 }, dhikr, 'tr', 'Ali'), 'Ali: +100 kez · 10%');
    assert.equal(feedBody({ kind: 'completed', uid: 'a' }, c, 'ar', 'علي'), 'أتمّ علي التحدي! ما شاء الله');
    assert.equal(feedBody({ kind: 'message', uid: 'a', text: '   ' }, c, 'en', 'A'), null);
    assert.equal(compactRanges([3, 1, 2, 7]), '1–3, 7');
  });
});

describe('daily reminders', () => {
  test('behind pace and last day, at 7 pm local time, once a day', async () => {
    // 14:00 UTC = 19:00 in Karachi (alice, bob) and 15:00 in London (carol).
    const now = new Date('2026-10-09T14:00:00Z');
    await seed(now.getTime());
    await db.doc('challenges/ch2').set(challenge({
      title: 'Al-Mulk', type: 'memorizeSurah', unit: 'ayahs', target: 30, surah: 67,
      startAt: Timestamp.fromMillis(now.getTime() - 2 * day), endAt: Timestamp.fromMillis(now.getTime() + 10 * 60 * 60 * 1000),
      memberUids: ['alice'],
    }, now.getTime()));
    await db.doc('challenges/ch2/participants/alice').set({ displayName: 'Amina', progress: 29, percent: 96.6, muted: false });

    const result = await runReminders(db, messaging, now);
    // ch1: bob is 10 Juz behind (alice is on pace); ch2: alice has 1 day left.
    assert.equal(result.reminded, 2);
    const bodies = sentMessages.map((m) => `${m.token}|${m.notification?.title}|${m.notification?.body}`).sort();
    assert.deepEqual(bodies, [
      'token-alice|Al-Mulk|1 day left. Finish strong, in sha Allah!',
      'token-bob|Ramadan Khatam|آپ 10 پارے پیچھے ہیں۔ آپ اب بھی کر سکتے ہیں!',
    ]);

    sentMessages = [];
    await runReminders(db, messaging, new Date(now.getTime() + 10 * 60 * 1000));
    assert.equal(sentMessages.length, 0, 'not twice on the same day');
  });

  test('statuses follow the dates', async () => {
    const now = Date.now();
    await db.doc('challenges/soon').set(challenge({ status: 'upcoming', startAt: Timestamp.fromMillis(now - 1000) }, now));
    await db.doc('challenges/done').set(challenge({ status: 'active', endAt: Timestamp.fromMillis(now - 1000) }, now));
    await runReminders(db, messaging, new Date(now));
    assert.equal((await db.doc('challenges/soon').get()).get('status'), 'active');
    assert.equal((await db.doc('challenges/done').get()).get('status'), 'finished');
  });

  test('pace rules', () => {
    const now = new Date('2026-10-09T12:00:00Z');
    const c = challenge({}, now.getTime());
    assert.deepEqual(paceReminder(c, { uid: 'a', progress: 5 }, now), { kind: 'behind', behind: 10 });
    assert.equal(paceReminder(c, { uid: 'a', progress: 14 }, now), null);
    assert.equal(paceReminder(c, { uid: 'a', percent: 100 }, now), null);
    // "Only show %": the percentage stands in for the count.
    assert.deepEqual(paceReminder(c, { uid: 'a', percent: 10 }, now), { kind: 'behind', behind: 12 });
    assert.deepEqual(localTime(now, 'Asia/Karachi'), { hour: 17, day: '2026-10-09' });
    assert.deepEqual(localTime(now, 'Not/AZone'), { hour: 12, day: '2026-10-09' });
  });
});
