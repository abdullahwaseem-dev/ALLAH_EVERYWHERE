// Security-rules tests for ../firestore.rules, run against the Firestore
// emulator: `npm test` in this folder.
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  arrayRemove,
  arrayUnion,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  getDocs,
  collection,
  increment,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  writeBatch,
} from 'firebase/firestore';

let env;
const ID = 'ch1';
const CODE = 'ABC234';
const day = 24 * 60 * 60 * 1000;

const db = (uid) => env.authenticatedContext(uid).firestore();
const guest = () => env.unauthenticatedContext().firestore();

function newChallenge(uid, overrides = {}) {
  return {
    title: 'Ramadan Khatam',
    type: 'khatam',
    unit: 'juz',
    target: 30,
    startAt: Timestamp.fromMillis(Date.now() - day),
    endAt: Timestamp.fromMillis(Date.now() + 10 * day),
    creatorUid: uid,
    creatorName: 'Amina',
    inviteCode: CODE,
    memberUids: [uid],
    memberCount: 1,
    status: 'active',
    createdAt: serverTimestamp(),
    intention: 'For the sake of Allah',
    ...overrides,
  };
}

function participant(name, overrides = {}) {
  return {
    displayName: name,
    percent: 0,
    showExactNumbers: true,
    progress: 0,
    muted: false,
    joinedAt: serverTimestamp(),
    lastLoggedAt: serverTimestamp(),
    loggedDays: [],
    ...overrides,
  };
}

function preview(overrides = {}) {
  const c = newChallenge('alice');
  return {
    challengeId: ID,
    title: c.title,
    type: c.type,
    creatorName: c.creatorName,
    startAt: c.startAt,
    endAt: c.endAt,
    memberCount: 1,
    ...overrides,
  };
}

// The create flow the app runs (in a transaction): challenge, the creator's
// participant doc and the invite code, in one write.
async function createAsAlice() {
  const fs = db('alice');
  const c = newChallenge('alice');
  const b = writeBatch(fs);
  b.set(doc(fs, 'challenges', ID), c);
  b.set(doc(fs, 'challenges', ID, 'participants', 'alice'), participant('Amina'));
  b.set(doc(fs, 'inviteCodes', CODE), { ...preview(), startAt: c.startAt, endAt: c.endAt });
  return b.commit();
}

function joinBatch(uid, name, overrides = {}) {
  const fs = db(uid);
  const b = writeBatch(fs);
  b.update(doc(fs, 'challenges', ID), { memberUids: arrayUnion(uid), memberCount: increment(1) });
  b.set(doc(fs, 'challenges', ID, 'participants', uid), participant(name, overrides));
  b.update(doc(fs, 'inviteCodes', CODE), { memberCount: increment(1) });
  b.set(doc(collection(fs, 'challenges', ID, 'feed')), { kind: 'joined', uid, createdAt: serverTimestamp() });
  return b;
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-allah-everywhere',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8'), host: '127.0.0.1', port: 8080 },
  });
});

after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

describe('existing user data', () => {
  test('a user reads and writes only their own doc and subcollections', async () => {
    await assertSucceeds(setDoc(doc(db('alice'), 'users', 'alice'), { name: 'Amina', fcmToken: 't' }));
    await assertSucceeds(setDoc(doc(db('alice'), 'users', 'alice', 'bookmarks', 'b1'), { x: 1 }));
    await assertSucceeds(setDoc(doc(db('alice'), 'users', 'alice', 'hifz', '1'), { x: 1 }));
    await assertSucceeds(setDoc(doc(db('alice'), 'users', 'alice', 'notifications', 'n1'), { x: 1 }));
    await assertSucceeds(setDoc(doc(db('alice'), 'users', 'alice', 'ai_questions', 'q1'), { x: 1 }));
    await assertFails(getDoc(doc(db('bob'), 'users', 'alice')));
    await assertFails(setDoc(doc(db('bob'), 'users', 'alice', 'bookmarks', 'b2'), { x: 1 }));
    await assertFails(getDoc(doc(guest(), 'users', 'alice')));
  });

  test('rewards are read-only for the user', async () => {
    await assertSucceeds(getDoc(doc(db('alice'), 'users', 'alice', 'rewards', 'r1')));
    await assertFails(setDoc(doc(db('alice'), 'users', 'alice', 'rewards', 'r1'), { badge: 'firstChallenge' }));
  });
});

describe('create', () => {
  test('a signed-in user creates a challenge with its invite code', async () => {
    await assertSucceeds(createAsAlice());
  });

  test('guests cannot create', async () => {
    await assertFails(setDoc(doc(guest(), 'challenges', ID), newChallenge('alice')));
  });

  test('cannot create for someone else or with members already in it', async () => {
    await assertFails(setDoc(doc(db('alice'), 'challenges', ID), newChallenge('bob')));
    await assertFails(setDoc(doc(db('alice'), 'challenges', ID), newChallenge('alice', { memberUids: ['alice', 'bob'], memberCount: 2 })));
  });

  test('invite codes avoid O, 0, I and 1, and are 6 characters', async () => {
    await assertFails(setDoc(doc(db('alice'), 'challenges', ID), newChallenge('alice', { inviteCode: 'ABCD10' })));
    await assertFails(setDoc(doc(db('alice'), 'challenges', ID), newChallenge('alice', { inviteCode: 'ABC23' })));
  });

  test('an invite code that is already taken cannot be overwritten', async () => {
    await createAsAlice();
    const fs = db('carol');
    const b = writeBatch(fs);
    b.set(doc(fs, 'challenges', 'ch2'), newChallenge('carol'));
    b.set(doc(fs, 'inviteCodes', CODE), preview({ challengeId: 'ch2', creatorName: 'Amina' }));
    await assertFails(b.commit());
  });
});

describe('join and preview', () => {
  test('any signed-in user can preview one code but not list codes', async () => {
    await createAsAlice();
    await assertSucceeds(getDoc(doc(db('bob'), 'inviteCodes', CODE)));
    await assertFails(getDocs(collection(db('bob'), 'inviteCodes')));
    await assertFails(getDoc(doc(guest(), 'inviteCodes', CODE)));
  });

  test('a non-member cannot read the challenge before joining', async () => {
    await createAsAlice();
    await assertFails(getDoc(doc(db('bob'), 'challenges', ID)));
    await assertFails(getDocs(collection(db('bob'), 'challenges', ID, 'feed')));
  });

  test('joining adds only yourself, then you can read', async () => {
    await createAsAlice();
    await assertSucceeds(joinBatch('bob', 'Bilal').commit());
    await assertSucceeds(getDoc(doc(db('bob'), 'challenges', ID)));
    await assertSucceeds(getDocs(collection(db('bob'), 'challenges', ID, 'feed')));
    const snap = await getDoc(doc(db('bob'), 'inviteCodes', CODE));
    if (snap.data().memberCount !== 2) throw new Error('preview count not updated');
  });

  test('cannot add someone else', async () => {
    await createAsAlice();
    const fs = db('bob');
    const b = writeBatch(fs);
    b.update(doc(fs, 'challenges', ID), { memberUids: arrayUnion('carol'), memberCount: increment(1) });
    b.set(doc(fs, 'challenges', ID, 'participants', 'carol'), participant('Carol'));
    await assertFails(b.commit());
  });

  test('cannot join without a participant doc, or join twice', async () => {
    await createAsAlice();
    await assertFails(updateDoc(doc(db('bob'), 'challenges', ID), { memberUids: arrayUnion('bob'), memberCount: increment(1) }));
    await joinBatch('bob', 'Bilal').commit();
    await assertFails(joinBatch('bob', 'Bilal').commit());
  });

  test('cannot join a challenge that has ended', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'challenges', ID), {
        ...newChallenge('alice'), createdAt: Timestamp.now(), endAt: Timestamp.fromMillis(Date.now() - day),
      });
      await setDoc(doc(ctx.firestore(), 'inviteCodes', CODE), { ...preview(), endAt: Timestamp.fromMillis(Date.now() - day) });
    });
    await assertFails(joinBatch('bob', 'Bilal').commit());
  });

  test('at most 50 members', async () => {
    const members = Array.from({ length: 50 }, (_, i) => `m${i}`);
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'challenges', ID), {
        ...newChallenge('m0'), createdAt: Timestamp.now(), memberUids: members, memberCount: 50,
      });
      await setDoc(doc(ctx.firestore(), 'inviteCodes', CODE), preview({ memberCount: 50 }));
    });
    await assertFails(joinBatch('bob', 'Bilal').commit());
  });
});

describe('progress', () => {
  beforeEach(async () => {
    await createAsAlice();
    await joinBatch('bob', 'Bilal').commit();
  });

  const me = (uid) => doc(db(uid), 'challenges', ID, 'participants', uid);

  test('a member logs their own progress upwards', async () => {
    await assertSucceeds(updateDoc(me('bob'), { progress: 3, percent: 10, lastLoggedAt: serverTimestamp(), loggedDays: ['2026-10-09'] }));
  });

  test('progress cannot go down or above the target', async () => {
    await updateDoc(me('bob'), { progress: 3, percent: 10, lastLoggedAt: serverTimestamp() });
    await assertFails(updateDoc(me('bob'), { progress: 2, percent: 6, lastLoggedAt: serverTimestamp() }));
    await assertFails(updateDoc(me('bob'), { progress: 31, percent: 100, lastLoggedAt: serverTimestamp() }));
    await assertFails(updateDoc(me('bob'), { percent: 101 }));
  });

  test('cannot write another member’s progress', async () => {
    await assertFails(updateDoc(doc(db('bob'), 'challenges', ID, 'participants', 'alice'), { progress: 30, percent: 100 }));
  });

  test('"Only show %" stores no exact number', async () => {
    await assertFails(updateDoc(me('bob'), { showExactNumbers: false, progress: 5, percent: 16 }));
    await assertSucceeds(updateDoc(me('bob'), { showExactNumbers: false, progress: deleteField(), percent: 16 }));
  });

  test('completedAt is set once, only at 100%', async () => {
    await assertFails(updateDoc(me('bob'), { percent: 50, progress: 15, completedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(me('bob'), { percent: 100, progress: 30, completedAt: serverTimestamp(), lastLoggedAt: serverTimestamp() }));
    await assertFails(updateDoc(me('bob'), { completedAt: serverTimestamp() }));
  });
});

describe('feed', () => {
  beforeEach(async () => {
    await createAsAlice();
    await joinBatch('bob', 'Bilal').commit();
  });

  const feed = (uid) => collection(db(uid), 'challenges', ID, 'feed');

  test('members post messages as themselves, up to 300 characters', async () => {
    await assertSucceeds(setDoc(doc(feed('bob')), { kind: 'message', uid: 'bob', text: 'Bismillah!', createdAt: serverTimestamp() }));
    await assertFails(setDoc(doc(feed('bob')), { kind: 'message', uid: 'alice', text: 'Hi', createdAt: serverTimestamp() }));
    await assertFails(setDoc(doc(feed('bob')), { kind: 'message', uid: 'bob', text: 'x'.repeat(301), createdAt: serverTimestamp() }));
    await assertFails(setDoc(doc(feed('carol')), { kind: 'message', uid: 'carol', text: 'Hi', createdAt: serverTimestamp() }));
  });

  test('"completed" only after reaching 100%', async () => {
    await assertFails(setDoc(doc(feed('bob')), { kind: 'completed', uid: 'bob', createdAt: serverTimestamp() }));
    await updateDoc(doc(db('bob'), 'challenges', ID, 'participants', 'bob'),
      { percent: 100, progress: 30, completedAt: serverTimestamp(), lastLoggedAt: serverTimestamp() });
    await assertSucceeds(setDoc(doc(feed('bob')), { kind: 'completed', uid: 'bob', createdAt: serverTimestamp() }));
  });

  test('reactions: each member edits only their own entry', async () => {
    const item = doc(feed('alice'), 'm1');
    await setDoc(item, { kind: 'message', uid: 'alice', text: 'Done Juz 1', createdAt: serverTimestamp() });
    await assertSucceeds(updateDoc(doc(db('bob'), 'challenges', ID, 'feed', 'm1'), { 'reactions.bob': ['mashaallah'] }));
    await assertFails(updateDoc(doc(db('bob'), 'challenges', ID, 'feed', 'm1'), { 'reactions.alice': ['ameen'] }));
    await assertFails(updateDoc(doc(db('bob'), 'challenges', ID, 'feed', 'm1'), { 'reactions.bob': ['laugh'] }));
    await assertFails(updateDoc(doc(db('bob'), 'challenges', ID, 'feed', 'm1'), { text: 'edited' }));
  });

  test('one nudge per member per day', async () => {
    const now = new Date();
    const id = `nudge_bob_alice_${now.getUTCFullYear()}-${now.getUTCMonth() + 1}-${now.getUTCDate()}`;
    const nudge = { kind: 'nudge', uid: 'bob', targetUid: 'alice', createdAt: serverTimestamp() };
    await assertSucceeds(setDoc(doc(feed('bob'), id), nudge));
    await assertFails(setDoc(doc(feed('bob'), id), nudge));
    await assertFails(setDoc(doc(feed('bob'), 'nudge_other_id'), nudge));
  });

  test('members report items; nobody reads reports', async () => {
    const report = { challengeId: ID, itemId: 'm1', reporterUid: 'bob', reason: 'spam', createdAt: serverTimestamp() };
    await assertSucceeds(setDoc(doc(db('bob'), 'reports', 'r1'), report));
    await assertFails(getDoc(doc(db('bob'), 'reports', 'r1')));
    await assertFails(setDoc(doc(db('carol'), 'reports', 'r2'), { ...report, reporterUid: 'carol' }));
  });
});

describe('leave, remove, edit, delete', () => {
  beforeEach(async () => {
    await createAsAlice();
    await joinBatch('bob', 'Bilal').commit();
    await joinBatch('carol', 'Carol').commit();
  });

  test('a member leaves (the app batch, which also updates the invite preview)', async () => {
    const fs = db('bob');
    const b = writeBatch(fs);
    b.update(doc(fs, 'challenges', ID), { memberUids: arrayRemove('bob'), memberCount: increment(-1) });
    b.delete(doc(fs, 'challenges', ID, 'participants', 'bob'));
    b.update(doc(fs, 'inviteCodes', CODE), { memberCount: increment(-1) });
    await assertSucceeds(b.commit());
    await assertFails(getDoc(doc(db('bob'), 'challenges', ID)));
  });

  test('only the creator removes another member', async () => {
    await assertFails(updateDoc(doc(db('bob'), 'challenges', ID), { memberUids: arrayRemove('carol'), memberCount: increment(-1) }));
    await assertSucceeds(updateDoc(doc(db('alice'), 'challenges', ID), { memberUids: arrayRemove('carol'), memberCount: increment(-1) }));
    await assertSucceeds(deleteDoc(doc(db('alice'), 'challenges', ID, 'participants', 'carol')));
  });

  test('only the creator edits the wording; nobody edits the target', async () => {
    await assertFails(updateDoc(doc(db('bob'), 'challenges', ID), { title: 'Mine now' }));
    await assertSucceeds(updateDoc(doc(db('alice'), 'challenges', ID), { intention: 'For my parents' }));
    await assertFails(updateDoc(doc(db('alice'), 'challenges', ID), { target: 10 }));
  });

  test('only the creator deletes (with the invite code, as the app does)', async () => {
    await assertFails(deleteDoc(doc(db('bob'), 'challenges', ID)));
    await assertFails(deleteDoc(doc(db('bob'), 'inviteCodes', CODE)));
    const fs = db('alice');
    const b = writeBatch(fs);
    b.delete(doc(fs, 'inviteCodes', CODE));
    b.delete(doc(fs, 'challenges', ID));
    await assertSucceeds(b.commit());
  });

  test('the creator cannot leave (they delete instead)', async () => {
    const fs = db('alice');
    await assertFails(updateDoc(doc(fs, 'challenges', ID), { memberUids: arrayRemove('alice'), memberCount: increment(-1) }));
  });

  test('"my challenges" query returns only mine', async () => {
    await assertSucceeds(getDocs(query(collection(db('bob'), 'challenges'), where('memberUids', 'array-contains', 'bob'))));
    await assertFails(getDocs(collection(db('bob'), 'challenges')));
  });
});

// The writes the challenge screen makes (lib/services/challenge_service.dart).
describe('challenge screen writes', () => {
  beforeEach(async () => {
    await createAsAlice();
    await joinBatch('bob', 'Bilal').commit();
  });

  function logBatch(uid, { progress, percent, exact = true, completed = false, items = [] }) {
    const fs = db(uid);
    const b = writeBatch(fs);
    b.update(doc(fs, 'challenges', ID, 'participants', uid), {
      percent,
      ...(exact ? { progress } : {}),
      lastLoggedAt: serverTimestamp(),
      loggedDays: arrayUnion('2026-10-09'),
      ...(completed ? { completedAt: serverTimestamp() } : {}),
    });
    b.set(doc(collection(fs, 'challenges', ID, 'feed')), {
      kind: 'progress', uid, name: 'Bilal', percent,
      ...(exact ? { value: 2, ...(items.length ? { items } : {}) } : {}),
      createdAt: serverTimestamp(),
    });
    b.set(doc(fs, 'users', uid, 'challengeProgress', ID),
      { progress, ...(items.length ? { items: arrayUnion(...items) } : {}), updatedAt: serverTimestamp() }, { merge: true });
    if (completed) {
      b.set(doc(collection(fs, 'challenges', ID, 'feed')), { kind: 'completed', uid, name: 'Bilal', createdAt: serverTimestamp() });
    }
    return b;
  }

  test('logging progress with the Juz ticked', async () => {
    await assertSucceeds(logBatch('bob', { progress: 2, percent: 6.6, items: [1, 2] }).commit());
  });

  test('logging the last Juz completes the challenge in the same batch', async () => {
    await logBatch('bob', { progress: 28, percent: 93.3 }).commit();
    await assertSucceeds(logBatch('bob', { progress: 30, percent: 100, completed: true, items: [29, 30] }).commit());
  });

  test('a "completed" post is refused if the batch does not reach 100%', async () => {
    await assertFails(logBatch('bob', { progress: 29, percent: 96.6, completed: true }).commit());
  });

  test('"Only show %" members log only a percentage', async () => {
    const fs = db('dave');
    const b = writeBatch(fs);
    b.update(doc(fs, 'challenges', ID), { memberUids: arrayUnion('dave'), memberCount: increment(1) });
    b.set(doc(fs, 'challenges', ID, 'participants', 'dave'), (({ progress, ...rest }) => rest)(participant('Dawud', { showExactNumbers: false })));
    b.update(doc(fs, 'inviteCodes', CODE), { memberCount: increment(1) });
    await assertSucceeds(b.commit());
    await assertSucceeds(logBatch('dave', { progress: 3, percent: 10, exact: false }).commit());
    await assertFails(logBatch('dave', { progress: 4, percent: 13.3, exact: true }).commit());
  });

  test('muting is a member’s own setting', async () => {
    await assertSucceeds(updateDoc(doc(db('bob'), 'challenges', ID, 'participants', 'bob'), { muted: true }));
    await assertFails(updateDoc(doc(db('bob'), 'challenges', ID, 'participants', 'alice'), { muted: true }));
  });

  test('removing a reaction', async () => {
    const item = doc(db('alice'), 'challenges', ID, 'feed', 'm1');
    await setDoc(item, { kind: 'message', uid: 'alice', name: 'Amina', text: 'Bismillah', createdAt: serverTimestamp() });
    const asBob = doc(db('bob'), 'challenges', ID, 'feed', 'm1');
    await updateDoc(asBob, { 'reactions.bob': ['ameen', 'dua'] });
    await assertSucceeds(updateDoc(asBob, { 'reactions.bob': deleteField() }));
  });

  test('deleting messages: your own, or any as the creator', async () => {
    await setDoc(doc(db('bob'), 'challenges', ID, 'feed', 'b1'), { kind: 'message', uid: 'bob', name: 'Bilal', text: 'Hi', createdAt: serverTimestamp() });
    await setDoc(doc(db('bob'), 'challenges', ID, 'feed', 'b2'), { kind: 'message', uid: 'bob', name: 'Bilal', text: 'Hi', createdAt: serverTimestamp() });
    await joinBatch('erin', 'Erin').commit();
    await assertFails(deleteDoc(doc(db('erin'), 'challenges', ID, 'feed', 'b1')));
    await assertSucceeds(deleteDoc(doc(db('bob'), 'challenges', ID, 'feed', 'b1')));
    await assertSucceeds(deleteDoc(doc(db('alice'), 'challenges', ID, 'feed', 'b2')));
  });

  test('the creator removes a member (the app batch)', async () => {
    const fs = db('alice');
    const b = writeBatch(fs);
    b.update(doc(fs, 'challenges', ID), { memberUids: arrayRemove('bob'), memberCount: increment(-1) });
    b.delete(doc(fs, 'challenges', ID, 'participants', 'bob'));
    b.update(doc(fs, 'inviteCodes', CODE), { memberCount: increment(-1) });
    await assertSucceeds(b.commit());
    await assertFails(getDoc(doc(db('bob'), 'challenges', ID)));
    await assertFails(getDocs(collection(db('bob'), 'challenges', ID, 'feed')));
  });
});

describe('rewards and Dua Wall', () => {
  // An ended challenge: Bilal completed it, Carol did not.
  async function seedEnded() {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const fs = ctx.firestore();
      await setDoc(doc(fs, 'challenges', ID), newChallenge('alice', {
        memberUids: ['alice', 'bob', 'carol'], memberCount: 3,
        startAt: Timestamp.fromMillis(Date.now() - 10 * day), endAt: Timestamp.fromMillis(Date.now() - day),
        createdAt: Timestamp.fromMillis(Date.now() - 10 * day), status: 'finished',
      }));
      await setDoc(doc(fs, 'challenges', ID, 'participants', 'bob'),
        { ...participant('Bilal'), percent: 100, progress: 30, completedAt: Timestamp.now(), joinedAt: Timestamp.now(), lastLoggedAt: Timestamp.now() });
      await setDoc(doc(fs, 'challenges', ID, 'participants', 'carol'),
        { ...participant('Carol'), percent: 40, progress: 12, joinedAt: Timestamp.now(), lastLoggedAt: Timestamp.now() });
    });
  }

  const dua = (from, to, text = 'May Allah accept it from you') =>
    ({ fromUid: from, fromName: from, toUid: to, text, createdAt: serverTimestamp() });

  test('rewards and server state are read-only; device rewards are the user’s own', async () => {
    await assertFails(setDoc(doc(db('bob'), 'users', 'bob', 'rewards', 'badge_steadfast'), { type: 'badge' }));
    await assertFails(setDoc(doc(db('bob'), 'users', 'bob', 'serverState', 'stats'), { reactionsSent: 50 }));
    await assertSucceeds(getDoc(doc(db('bob'), 'users', 'bob', 'serverState', 'stats')));
    await assertSucceeds(setDoc(doc(db('bob'), 'users', 'bob', 'localRewards', 'badge_dhikr_1000'), { type: 'badge' }));
    await assertFails(getDoc(doc(db('bob'), 'users', 'alice', 'localRewards', 'x')));
  });

  test('public badges: readable when signed in, written only by the server', async () => {
    await assertSucceeds(getDoc(doc(db('bob'), 'publicProfiles', 'alice')));
    await assertFails(getDoc(doc(guest(), 'publicProfiles', 'alice')));
    await assertFails(setDoc(doc(db('bob'), 'publicProfiles', 'bob'), { badges: ['steadfast'] }));
  });

  test('members cannot set or clear the server’s "fell behind" flag', async () => {
    await createAsAlice();
    await joinBatch('bob', 'Bilal').commit();
    const me = doc(db('bob'), 'challenges', ID, 'participants', 'bob');
    await assertFails(updateDoc(me, { wasBehind: true }));
    await env.withSecurityRulesDisabled((ctx) => updateDoc(doc(ctx.firestore(), 'challenges', ID, 'participants', 'bob'), { wasBehind: true }));
    await assertFails(updateDoc(me, { wasBehind: false }));
    await assertSucceeds(updateDoc(me, { muted: true }));
  });

  test('duas only after the end, only for members who completed, once each', async () => {
    await seedEnded();
    const duas = (uid) => collection(db(uid), 'challenges', ID, 'duas');
    await assertSucceeds(setDoc(doc(duas('alice'), 'alice_bob'), dua('alice', 'bob')));
    await assertFails(setDoc(doc(duas('alice'), 'alice_bob'), dua('alice', 'bob', 'Again')));
    await assertFails(setDoc(doc(duas('alice'), 'alice_carol'), dua('alice', 'carol')));
    await assertFails(setDoc(doc(duas('alice'), 'x'), dua('alice', 'bob')));
    await assertFails(setDoc(doc(duas('carol'), 'carol_bob'), dua('carol', 'bob', 'x'.repeat(201))));
    await assertFails(setDoc(doc(duas('carol'), 'carol_bob'), dua('alice', 'bob')));
    // Those who completed write one dua back for everyone.
    await assertSucceeds(setDoc(doc(duas('bob'), 'bob_all'), dua('bob', 'all')));
    await assertFails(setDoc(doc(duas('carol'), 'carol_all'), dua('carol', 'all')));
    await assertFails(setDoc(doc(duas('bob'), 'bob_bob'), dua('bob', 'bob')));
    await assertSucceeds(getDocs(duas('carol')));
    await assertFails(getDocs(duas('dave')));
    await assertSucceeds(deleteDoc(doc(duas('alice'), 'alice_bob')));
  });

  test('no duas while the challenge is still running', async () => {
    await createAsAlice();
    await joinBatch('bob', 'Bilal').commit();
    await env.withSecurityRulesDisabled((ctx) =>
      updateDoc(doc(ctx.firestore(), 'challenges', ID, 'participants', 'bob'), { percent: 100, completedAt: Timestamp.now() }));
    await assertFails(setDoc(doc(db('alice'), 'challenges', ID, 'duas', 'alice_bob'), dua('alice', 'bob')));
  });
});
