# Allah Everywhere

A Flutter app for prayer times, Qibla direction, Quran, Hadith, Dua, Tasbeeh, and AI-answered Islamic questions.

## External APIs used

All calls use HTTPS, are wrapped in try/catch with a client-side timeout, and log failures via
`VoidLogger` instead of failing silently. Verified reachable and working as of 2026-09-10:

| API | Used by | Auth | Verified |
|---|---|---|---|
| `quranapi.pages.dev` | `lib/services/QuranServices.dart` (Surah list) | None | `GET /api/surah.json` → HTTP 200, correct shape |
| `hadithapi.com` | `lib/services/HadithService.dart`, `HadithChaptersService.dart`, `HadithDetailService.dart` | API key (`HADITH_API_KEY`, see below) | `GET /api/books` → HTTP 403 `{"message":"API key is required."}` with no key, confirming the endpoint and auth gate both work as coded. Needs a real key to verify a full 200 response. |
| `overpass-api.de` (OpenStreetMap Overpass) | `lib/services/nearby_mosque_service.dart` (nearby mosques on Home) | None | Verified with real coordinates → HTTP 200 with mosque data. **Known limitation**: the free public instance can return HTTP 504 in extremely dense areas (reproduced querying around the Grand Mosque, Makkah) under load; the service retries once at a smaller radius and the UI shows a distinct "couldn't reach the mosque directory" + Retry state rather than misreporting it as "no mosques found". |
| Firebase (Auth, Firestore, Storage, Crashlytics, Analytics, Cloud Messaging) | throughout | Firebase project config in `lib/firebase_options.dart` | Configured via the Dart-side FlutterFire options (no `google-services.json` dependency); not independently load-tested here since it requires a live signed-in session. |

The bundled `quran` and `hadith` pub packages ship Quran text and provide Hadith data models
locally; Surah reading (`lib/surah.dart`) uses the bundled `quran` package instead of a network
call, so it works offline. `quranapi.pages.dev` is only used for the Surah list metadata (names,
ayah counts) shown before you open a Surah.

## Running the app

The Hadith book/chapter/detail screens call hadithapi.com and require an API key. Get one at
https://hadithapi.com and pass it at build/run time - it is never committed to source:

```
flutter run --dart-define=HADITH_API_KEY=your_key_here
```

Without it, those screens show a clear "not configured" error instead of silently failing.

## Release signing (Android)

`android/app/build.gradle` looks for `android/key.properties` (gitignored, never committed) to sign
release builds with a real upload key; without it, `flutter run --release` falls back to the debug
key so local builds still work. To set one up:

1. Copy `android/key.properties.example` to `android/key.properties`.
2. Generate a keystore if you don't have one:
   ```
   keytool -genkeypair -v -keystore android/app/upload-keystore.jks -storetype JKS \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
3. Fill in the real passwords/alias in `android/key.properties`.
4. **Back up `android/app/upload-keystore.jks` and `android/key.properties` somewhere safe** (a
   password manager or secure vault). If you lose them after publishing to Play Store, you can
   never update that app listing again.

## Before publishing

- Register `com.allaheverywhere.app` as a new Android/iOS app in the Firebase console (the current
  `android/app/google-services.json` was generated for older package names) so native Firebase
  features (Crashlytics symbol upload, Play Integrity, etc.) work fully. The app itself already
  works without this via the Dart-side `lib/firebase_options.dart` configuration.
- Confirm Firestore security rules are locked down in the Firebase console (not left in open test
  mode) before going live - user profiles, Tasbeeh counts, and Ask AI history all live there.
- Wire a real backend into `lib/services/ai_fatwa_service.dart` (`AiFatwaService.instance`) -
  it currently ships with a placeholder implementation that explains AI answering isn't connected
  yet, by design, until a backend (e.g. a Firebase Cloud Function calling the Claude API
  server-side) is deployed.
- Get a real `HADITH_API_KEY` from https://hadithapi.com before shipping - the endpoint is
  confirmed live but every request currently needs a key this repo doesn't ship.

## Android toolchain

The project ships with Gradle 8.12, Android Gradle Plugin 8.7.0, and Kotlin 2.0.20
(`android/settings.gradle`, `android/gradle/wrapper/gradle-wrapper.properties`). These were
upgraded from the original Gradle 7.6.3 / AGP 7.3.1 / Kotlin 1.9.0 because that combination could
not build at all on a JDK 21 machine, and separately could not compile `flutter_qiblah`'s Android
plugin code (which used the removed Flutter v1 embedding `Registrar` API in the version this
project originally depended on). `flutter_qiblah` is now pinned to `^3.1.0+1`, which fixed that.
Flutter's own tooling will periodically warn these versions are older than its latest-recommended
set - that's expected and non-blocking; verified end-to-end with `flutter build apk --debug`.

## Changelog (production-readiness pass)

**Security & release readiness**
- Removed a hardcoded hadithapi.com API key from source (3 files) - now supplied via
  `--dart-define=HADITH_API_KEY`.
- Generated a real Android upload keystore and wired proper release signing into Gradle.
- Renamed the app from the default `com.example.allah_everywhere` to `com.allaheverywhere.app`.
- Added the iOS permission usage strings the app was missing entirely (location, photo library,
  motion) - previously would have crashed on first use of those features.
- Upgraded the Android build toolchain and `flutter_qiblah` (see above) after discovering neither
  could build against a current JDK.

**Removed the Aalim (human-scholar) feature**
- Deleted `alim.dart`, `chat.dart`, `live_messages.dart`, `masail&issues.dart`.
- Replaced with a single **Ask AI** screen behind a swappable `AiFatwaService` interface (currently
  a clear placeholder pending a real backend), with saved history per user.

**Fixed broken/fake features**
- Prayer Timing screen showed hardcoded times unrelated to Home's real computed times - both now
  share one `PrayerTimesController`.
- Qibla compass rotated off the raw gyroscope axis (angular velocity, not orientation) instead of
  the correct value `flutter_qiblah` already computes - fixed.
- "Nearby Masjids" were two hardcoded cards regardless of location - now a real, keyless
  OpenStreetMap Overpass lookup, with graceful handling of the free server's occasional overload.
- Notifications were entirely mocked (including literal unfilled template text) - rebuilt around
  real Firestore-backed data, with FCM plumbing to populate it.
- Tasbeeh and Hadith-read counts now persist and feed real Profile stats instead of the previous
  hardcoded 656/47/27.
- Fixed the Dua flow: dropped a duplicate "Ramadan" category card, gave every category real
  content, and fixed a bug where the detail screen always showed the same hardcoded dua regardless
  of which one was tapped.
- Replaced the empty Seerat and Tib-e-Nabwi stub screens (one of which is a main bottom-nav tab)
  with real, sourced content.
- Added a real "last read Hadith book" tracker (mirroring the one Quran already had) - the
  "Continue" button on the Hadith screen previously did nothing and always showed a hardcoded book.
- Wired "Join as Guest" on the Registration screen, which previously had an empty handler.

**Code quality & dead code removal**
- Removed `SurahController`/`SurahService` (superseded by the offline `quran` package used in
  `surah.dart`, never actually called), `VoidHttpClient` (unused, pointed at an unrelated
  third-party domain), and `NetworkManager` (unused, and its `onClose` called `.cancel()` on a
  `late` subscription that was never initialized since its `onInit` was commented out).
- Removed a large amount of unused leftover boilerplate from what was originally a different
  (e-commerce) UI-kit template and never adapted for this app: fully commented-out dead files
  (`device.dart`, `padding_values.dart`, `formatter.dart`, `helper_functions.dart`,
  `full_screen_loader.dart`), unused Lorem-ipsum text constants, unused e-commerce enums
  (`PaymentMethods.paypal/googlePay/...`), and an unrelated third-party API URL from a tutorial
  project (`constants.dart`).
- Removed all remaining `print()` debug statements app-wide in favor of the existing `VoidLogger`
  utility, and fixed a real bug in it (`VoidLogger.error()` referenced an undefined `error`
  identifier in its own body).
- Fixed a real bug where 4 data controllers (Hadith books/chapters/detail, Quran surahs) never
  cleared their `errorMessage` between fetches, so a stale error from one failed request could
  permanently overlay a later successful one - most reachable via Hadith Detail/Chapters, whose
  controller is reused across multiple chapter navigations.
- Fixed `quran.dart` never actually displaying `QuranController.errorMessage` at all - a network
  failure silently rendered a blank list with no feedback; added the same error+Retry treatment
  already used on the Hadith screens.
- Fixed `HidthChaptersScreen` calling `fetchChapters()` directly inside `build()` instead of
  `initState()`, re-firing the network request on every rebuild.
- Added request timeouts to every remaining HTTP call that didn't already have one.
- Fixed `editprofilescreen.dart`: no loading/error feedback on image upload or save, a `dispose()`
  that never disposed `_nameController`, and a new `TextEditingController` constructed on every
  rebuild for the read-only email field; also refactored it to reuse the existing
  `pickSingleImage()` helper instead of duplicating `ImagePicker` calls inline.
- Cleaned up ~20 unused/unnecessary import warnings across the codebase.
- Wired the previously unused `VoidValidator` into Login/Registration/Forget Password/Change
  Password (fixing a bug where Forget Password rejected every non-`@gmail.com` address) and the
  previously unused `VoidAppTheme` into a working light/dark theme.
- Replaced the broken default counter-app test with real unit tests for `VoidValidator`.
- Added a Delete Account flow and Crashlytics/Analytics initialization.

Verified throughout via `flutter analyze` (0 errors), `flutter test` (all passing), and repeated
`flutter build apk --debug` runs.
