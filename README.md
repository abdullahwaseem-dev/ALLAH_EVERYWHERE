# Allah Everywhere

A Flutter app for prayer times, Qibla direction, Quran, Hadith, Dua, Tasbeeh, and AI-answered Islamic questions.

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
