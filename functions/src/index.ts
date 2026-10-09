import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { setGlobalOptions } from 'firebase-functions/v2';
import { logger } from 'firebase-functions';
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { FeedItem, notifyFeedItem, runReminders } from './notify';
import { awardCompletion, CompletedParticipant, countJoin, countReactions, Dua, notifyDua, publishProfile } from './rewards';

initializeApp();
// A cap so a bug or a burst of chat can never run up a large bill.
setGlobalOptions({ region: 'us-central1', maxInstances: 10 });

/// A new challenge update, message, nudge, join or completion: notify the
/// other members (see notify.ts). A join also counts toward the creator's
/// "Family Builder" badge.
export const onChallengeFeedItem = onDocumentCreated('challenges/{challengeId}/feed/{itemId}', async (event) => {
  const item = event.data?.data() as FeedItem | undefined;
  if (!item) return;
  const db = getFirestore();
  const result = await notifyFeedItem(db, getMessaging(), event.params.challengeId, item);
  if (item.kind === 'joined') await countJoin(db, event.params.challengeId, item.uid);
  logger.info('challenge feed notification', { challengeId: event.params.challengeId, kind: item.kind, ...result });
});

/// Reactions changed on a feed item: counts toward "Encourager".
export const onChallengeFeedReaction = onDocumentUpdated('challenges/{challengeId}/feed/{itemId}', async (event) => {
  const before = event.data?.before.get('reactions') as Record<string, string[]> | undefined;
  const after = event.data?.after.get('reactions') as Record<string, string[]> | undefined;
  await countReactions(getFirestore(), event.params.challengeId, event.params.itemId, before, after);
});

/// A member reached 100%: certificate, Jannah Garden plants and badges.
export const onChallengeCompleted = onDocumentUpdated('challenges/{challengeId}/participants/{uid}', async (event) => {
  const before = event.data?.before.data();
  const after = event.data?.after.data() as CompletedParticipant | undefined;
  if (!after?.completedAt || before?.completedAt) return;
  const badges = await awardCompletion(getFirestore(), event.params.challengeId, event.params.uid, after);
  logger.info('challenge completed', { challengeId: event.params.challengeId, badges });
});

/// A dua on the Dua Wall: tell the person it was made for.
export const onChallengeDua = onDocumentCreated('challenges/{challengeId}/duas/{duaId}', async (event) => {
  const dua = event.data?.data() as Dua | undefined;
  if (!dua) return;
  await notifyDua(getFirestore(), getMessaging(), event.params.challengeId, dua);
});

/// "Show my badges" toggled in My Rewards: update what other members see.
export const onUserBadgeVisibility = onDocumentUpdated('users/{uid}', async (event) => {
  if (event.data?.before.get('hideBadges') === event.data?.after.get('hideBadges')) return;
  await publishProfile(getFirestore(), event.params.uid);
});

/// Every hour: "behind pace" and "1 day left" reminders at 7 pm in each
/// member's time zone, and challenge status upkeep.
export const challengeReminders = onSchedule({ schedule: '0 * * * *', timeZone: 'UTC' }, async () => {
  const result = await runReminders(getFirestore(), getMessaging(), new Date());
  logger.info('challenge reminders', result);
});
