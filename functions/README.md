# Cloud Functions (Challenges notifications)

Two functions, in `src/index.ts`:

| Function | Trigger | What it does |
|---|---|---|
| `onChallengeFeedItem` | New doc in `challenges/{id}/feed` | Pushes the update, message, nudge, join or completion to the other members (a nudge goes only to its target). It skips members who muted the challenge or turned off **Challenge notifications** in Settings. The text is in each receiver's app language. Each push also gets an entry in the in-app notification center. Dead tokens are removed. |
| `challengeReminders` | Every hour | Sends "You're 2 Juz behind…" and "1 day left" at 7 pm in each member's time zone, at most once per challenge per day. It also keeps each challenge's `status` up to date. |

## Before the first deploy

1. **Blaze plan.** Cloud Functions need the pay-as-you-go Blaze plan. Upgrade in Firebase console → ⚙ → Usage and billing. At this app's scale it should stay inside the free monthly quota (2M invocations), but add a budget alert anyway (Google Cloud console → Billing → Budgets & alerts, e.g. $5).
2. **iOS push key.** Firebase console → Project settings → Cloud Messaging → Apple app configuration → upload an **APNs Authentication Key** (.p8). You create it at developer.apple.com → Certificates, IDs & Profiles → Keys → + → "Apple Push Notifications service". Without it, Android gets pushes but iPhones don't.
3. **Push capability on the App ID.** The app now has the `aps-environment` entitlement. With automatic signing, Xcode adds the Push Notifications capability to the App ID by itself. With manual profiles, enable it on the App ID and regenerate the profiles.
4. **Region.** The functions deploy to `us-central1`. If your Firestore database is in a different region and the deploy complains, change `region` in `src/index.ts` to match.

## Deploy

From the project root:

```sh
cd functions && npm install && cd ..
firebase deploy --only firestore:rules,firestore:indexes,functions
```

The first deploy asks to enable Cloud Functions, Cloud Build, Artifact Registry, Eventarc and Cloud Scheduler. Answer yes.

## Test

The tests run against the Firestore emulator (this needs Java 21) with a fake FCM client:

```sh
cd functions && npm test
```
