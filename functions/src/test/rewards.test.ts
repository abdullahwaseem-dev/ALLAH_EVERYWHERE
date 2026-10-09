// Reward awarding against the Firestore emulator (`npm test`).
import assert from 'node:assert/strict';
import { after, beforeEach, describe, test } from 'node:test';
import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import type { BatchResponse, Messaging, TokenMessage } from 'firebase-admin/messaging';
import { ChallengeDoc, runReminders } from '../notify';
import {
  awardCompletion,
  certificateResult,
  countJoin,
  countReactions,
  notifyDua,
  publishProfile,
} from '../rewards';

if (!getApps().length) initializeApp({ projectId: 'demo-allah-everywhere' });
const db = getFirestore();
const day = 24 * 60 * 60 * 1000;

let sent: TokenMessage[] = [];
const messaging = {
  async sendEach(messages: TokenMessage[]): Promise<BatchResponse> {
    sent.push(...messages);
    return { responses: messages.map(() => ({ success: true })), successCount: messages.length, failureCount: 0 } as BatchResponse;
  },
} as unknown as Messaging;

async function clear() {
  const res = await fetch(
    `http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/demo-allah-everywhere/databases/(default)/documents`,
    { method: 'DELETE' },
  );
  assert.ok(res.ok);
}

const start = Date.UTC(2026, 9, 1, 8);
function challenge(overrides: Partial<ChallengeDoc> = {}): ChallengeDoc & Record<string, unknown> {
  return {
    title: 'Ramadan Khatam',
    type: 'khatam',
    unit: 'juz',
    target: 30,
    startAt: Timestamp.fromMillis(start),
    endAt: Timestamp.fromMillis(start + 10 * day),
    memberUids: ['alice', 'bob', 'carol'],
    status: 'active',
    creatorUid: 'alice',
    ...overrides,
  };
}

const badgesOf = async (uid: string) =>
  (await db.collection(`users/${uid}/rewards`).where('type', '==', 'badge').get()).docs.map((d) => d.get('badgeId')).sort();

beforeEach(async () => {
  sent = [];
  await clear();
});
after(clear);

describe('completing a challenge', () => {
  test('certificate result: never missed a day, early, or completed', () => {
    const c = challenge();
    const days = (n: number) => Array.from({ length: n }, (_, i) => `2026-10-0${i + 1}`);
    assert.equal(certificateResult(c, { completedAt: Timestamp.fromMillis(start + 4.5 * day), loggedDays: days(5) }), 'perfect');
    assert.equal(certificateResult(c, { completedAt: Timestamp.fromMillis(start + 4.5 * day), loggedDays: days(3) }), 'early');
    assert.equal(certificateResult(c, { completedAt: Timestamp.fromMillis(start + 9.5 * day), loggedDays: days(3) }), 'completed');
  });

  test('certificate, garden tree and fountain, badges, public profile', async () => {
    await db.doc('challenges/ch1').set({ ...challenge(), dedication: 'For my late grandmother' });
    const badges = await awardCompletion(db, 'ch1', 'bob', {
      displayName: 'Bilal',
      completedAt: Timestamp.fromMillis(start + 2.5 * day),
      loggedDays: ['2026-10-01', '2026-10-02', '2026-10-03'],
      wasBehind: true,
    });
    assert.deepEqual(badges.sort(), ['comeback', 'first_challenge', 'khatam_finisher', 'steadfast']);
    const cert = await db.doc('users/bob/rewards/cert_ch1').get();
    assert.equal(cert.get('result'), 'perfect');
    assert.equal(cert.get('name'), 'Bilal');
    assert.equal(cert.get('dedication'), 'For my late grandmother');
    assert.equal((await db.doc('users/bob/rewards/garden_tree_ch1').get()).get('kind'), 'tree');
    assert.equal((await db.doc('users/bob/rewards/garden_fountain_ch1').get()).get('kind'), 'fountain');
    assert.deepEqual(((await db.doc('publicProfiles/bob').get()).get('badges') as string[]).sort(), badges.sort());

    // A second completion keeps the first badges' dates and adds nothing new.
    await db.doc('challenges/ch2').set(challenge({ type: 'dhikr', unit: 'count', target: 100 }));
    const again = await awardCompletion(db, 'ch2', 'bob', { displayName: 'Bilal', completedAt: Timestamp.fromMillis(start + 9.5 * day) });
    assert.deepEqual(again, []);
    assert.equal((await db.doc('users/bob/rewards/garden_fountain_ch2').get()).exists, false);
  });

  test('hidden badges are not shown to others', async () => {
    await db.doc('users/bob').set({ hideBadges: true });
    await db.doc('users/bob/rewards/badge_first_challenge').set({ type: 'badge', badgeId: 'first_challenge', earnedAt: Timestamp.now() });
    await publishProfile(db, 'bob');
    assert.deepEqual((await db.doc('publicProfiles/bob').get()).get('badges'), []);
  });
});

describe('encourager and family builder', () => {
  test('reactions count once per item; 50 earn Encourager', async () => {
    for (let i = 0; i < 49; i++) {
      await countReactions(db, 'ch1', `item${i}`, undefined, { bob: ['ameen'] });
    }
    // Taking a reaction back and adding it again doesn't count twice.
    await countReactions(db, 'ch1', 'item0', { bob: ['ameen'] }, {});
    await countReactions(db, 'ch1', 'item0', {}, { bob: ['dua'] });
    assert.deepEqual(await badgesOf('bob'), []);
    assert.equal((await db.doc('users/bob/serverState/stats').get()).get('reactionsSent'), 49);
    const earned = await countReactions(db, 'ch1', 'item49', { alice: ['love'] }, { alice: ['love'], bob: ['mashaallah'] });
    assert.deepEqual(earned, ['bob']);
    assert.deepEqual(await badgesOf('bob'), ['encourager']);
  });

  test('5 different people joining your challenges earn Family Builder', async () => {
    await db.doc('challenges/ch1').set(challenge());
    for (const uid of ['b', 'c', 'd', 'd', 'alice', 'e']) await countJoin(db, 'ch1', uid);
    assert.deepEqual(await badgesOf('alice'), []);
    assert.equal(await countJoin(db, 'ch1', 'f'), true);
    assert.deepEqual(await badgesOf('alice'), ['family_builder']);
  });
});

describe('Dua Wall and Comeback', () => {
  test('the receiver hears how many duas their family made', async () => {
    await db.doc('challenges/ch1').set(challenge());
    for (const uid of ['alice', 'bob', 'carol']) await db.doc(`users/${uid}`).set({ fcmToken: `t-${uid}`, language: 'en' });
    await db.doc('challenges/ch1/duas/alice_bob').set({ fromUid: 'alice', fromName: 'Amina', toUid: 'bob', text: 'May Allah accept it' });
    await notifyDua(db, messaging, 'ch1', { fromUid: 'alice', fromName: 'Amina', toUid: 'bob', text: '' });
    assert.equal(sent.at(-1)?.notification?.body, 'Amina made a dua for you');
    await db.doc('challenges/ch1/duas/carol_bob').set({ fromUid: 'carol', fromName: 'Carol', toUid: 'bob', text: 'Ameen' });
    await notifyDua(db, messaging, 'ch1', { fromUid: 'carol', fromName: 'Carol', toUid: 'bob', text: '' });
    assert.equal(sent.at(-1)?.notification?.body, 'Your family made 2 duas for you');
    assert.equal(sent.at(-1)?.token, 't-bob');

    sent = [];
    await notifyDua(db, messaging, 'ch1', { fromUid: 'bob', fromName: 'Bilal', toUid: 'all', text: '' });
    assert.deepEqual(sent.map((m) => m.token).sort(), ['t-alice', 't-carol']);
    assert.equal(sent[0].notification?.body, 'Bilal made a dua for everyone');
  });

  test('falling behind is remembered on the participant for Comeback', async () => {
    const now = new Date(start + 5 * day);
    await db.doc('challenges/ch1').set(challenge());
    await db.doc('challenges/ch1/participants/bob').set({ displayName: 'Bilal', progress: 2, percent: 6.6, muted: true });
    await db.doc('challenges/ch1/participants/carol').set({ displayName: 'Carol', progress: 15, percent: 50 });
    await runReminders(db, messaging, now);
    assert.equal((await db.doc('challenges/ch1/participants/bob').get()).get('wasBehind'), true);
    assert.equal((await db.doc('challenges/ch1/participants/carol').get()).get('wasBehind'), undefined);
  });
});
