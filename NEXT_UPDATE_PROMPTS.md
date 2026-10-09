# Next Update: Build Prompts

One prompt per feature. Use them **one at a time**, in the order below
(easiest first). After each feature: run the app, check it, commit, then
start the next prompt in a fresh session.

**Always paste Section 0 (Shared Context) above every feature prompt.**

---

## 0. Shared Context (paste above every prompt) -> DONE

```
You are working on "Allah Everywhere", a Flutter Islamic app (Dart SDK ^3.5.1)
in this repository. Before writing code, read the files mentioned below and
match their style exactly.

Project conventions:
- State management: GetX. Screens are opened with Get.to(() => Screen()).
  Controllers live in lib/controllers/ (e.g. prayer_times_controller.dart,
  theme_controller.dart, language_controller.dart).
- Services live in lib/services/, static content in lib/data/
  (see dua_data.dart, seerah_data.dart, reciters_data.dart for the pattern).
- Local storage: VoidStorage in lib/utils/utils/local_storage/storage.dart.
- Theming: lib/utils/utils/theme/ and lib/utils/utils/constraints/colors.dart,
  ThemedBackground widget in lib/widgets/themed_background.dart. Every new
  screen must support light AND dark mode via the existing theme, with no
  hard-coded colors.
- Arabic text: use the existing fonts (Amiri, NotoNaskhArabic) via
  lib/utils/utils/theme/scripture_text.dart. Urdu uses NotoNastaliqUrdu.
- Localization: the app supports en, ar, ur, fr, de, hi, tr, zh. Add every new
  UI string to ALL 8 files in lib/l10n/*.arb, then run `flutter gen-l10n`.
  Arabic and Urdu are RTL, so check layouts in RTL.
- Home grid: new features get a tile in lib/home.dart using IconButtonWidget
  with an Iconsax icon, like the existing Quran/Hadith/Dua tiles.
- Notifications: lib/services/local_notifications_service.dart. Existing IDs
  are taken: 100-104 (legacy), 200 (Quran reminder), 300-334 (prayers).
  Use only the ID range given in the feature prompt for new notifications.
- Ads: the app promises ONE small banner ad only. Do not add any new ad
  placements, interstitials or rewarded ads.
- Quran data: use the `quran` package already in pubspec. Quran audio comes
  from api.alquran.cloud (see lib/services/quran_audio_service.dart and
  lib/data/reciters_data.dart).
- Firebase (Auth, Firestore, Storage, Messaging) is already set up. Guests
  must still be able to use every feature that does not need sharing;
  store guest data locally like lib/services/bookmark_service.dart does.

Religious content rules (very important):
- NEVER write Quran verses, Hadith, Duas or Arabic religious text from memory.
  Take Quran text from the `quran` package. For Duas/Adhkar/Hadith, use an
  authentic source (e.g. Hisn al-Muslim) and include the source reference
  (book + number) next to every item.
- Mark every new religious-content data file with a comment at the top:
  "// CONTENT REVIEW REQUIRED: verify against source before release".
- Where madhabs differ, say so instead of picking one view.

Quality bar:
- Run `flutter analyze` and fix all new warnings.
- No crashes when offline, when location/mic permission is denied, or on
  first launch with empty storage.
- Do not change unrelated files or reformat existing code.
- When done, list every file you created or changed, and anything I must do
  by hand (assets to add, Xcode steps, Firebase console steps).
```

---

## 1. Jumu'ah (Friday) Reminder -> DONE

```
Build a Jumu'ah (Friday) reminder feature.

What it does:
- Every Friday morning, send a local notification: "It's Jumu'ah! Read
  Surah Al-Kahf and send Durood upon the Prophet ﷺ".
- Tapping the notification opens Surah Al-Kahf (Surah 18) in the existing
  Quran reader (lib/surah.dart).
- A second optional reminder ~1 hour before Asr on Friday saying the hour
  before Maghrib is a time when duas are accepted (with the hadith reference).

Settings (add to lib/settings.dart, in the notifications area):
- Toggle "Jumu'ah reminder" (default ON).
- Time picker for the morning reminder (default 9:00 AM local time).
- Toggle for the Asr-time reminder (default OFF).

Implementation:
- Schedule as a weekly repeating zoned notification with the existing
  timezone setup in local_notifications_service.dart.
- Use notification IDs 400-401 only.
- Re-schedule when the user changes time or language (follow how the Quran
  reminder does it).
- On Friday, show a small "Jumu'ah Mubarak - Read Al-Kahf" card on the home
  screen that opens Surah 18; hide it on other days.

Done when: toggling works, the notification fires on Friday at the chosen
time, tapping it opens Al-Kahf, and strings exist in all 8 languages.
```

---

## 2. Asma-ul-Husna (99 Names of Allah) ->DONE

```
Build an "Asma-ul-Husna" (99 Names of Allah) screen.

Content:
- Create lib/data/asma_ul_husna_data.dart with all 99 names, in the order of
  the Tirmidhi narration (Jami' at-Tirmidhi 3507). Each entry has:
  number, Arabic name (with tashkeel), transliteration, English meaning, and
  a short 1-2 line explanation. Add translations of the meaning for the other
  app languages in the same style as lib/data/i18n/.
- Add the CONTENT REVIEW REQUIRED comment.

Screens:
- List/grid screen: beautiful cards showing number, large Arabic name,
  transliteration and meaning. Search box filters by transliteration or
  meaning.
- Detail screen (tap a card): big Arabic name, meaning, explanation,
  and buttons for: Bookmark, Share, Copy.
- Share: open the existing share studio (lib/share_cards/) with the name pre-
  filled, so users can make a share card from it.
- "Name of the day" card on the home screen that rotates daily
  (day-of-year % 99).

Audio (optional, do only if possible):
- If a free, properly licensed audio recitation of the 99 names is available,
  add a play button. If not, skip audio and tell me, do NOT add unlicensed
  audio.

Add a home-grid tile "99 Names". Done when: all 99 names show correctly in
light/dark mode and RTL, search works, share card works.
```

---

## 3. Zakat Calculator -> DONE

```
Build a Zakat Calculator screen.

Inputs (all optional, currency-aware):
- Cash in hand and bank
- Gold (grams) and silver (grams)
- Investments / shares / crypto (current value)
- Business stock / inventory value
- Money owed TO you (that you expect to receive)
- Debts you owe that are due now (deducted)

Nisab:
- Show both nisab standards: gold (87.48 g) and silver (612.36 g), and let
  the user choose which one to use. Add a short note that many scholars
  recommend the silver nisab because it benefits more poor people, and that
  this differs between scholars.
- Gold and silver price per gram: try to fetch a live price from a free API
  with no key; cache the last value with its date. If fetching fails, let the
  user enter the price manually. Always show "Price as of <date>".

Currency:
- Default currency based on device locale (PKR, INR, USD, GBP, EUR, SAR,
  AED, TRY, etc.), changeable in a dropdown. Format numbers with `intl`.

Result:
- Total zakatable wealth, nisab value, whether zakat is due, and the amount
  due (2.5%). Show a clear breakdown.
- Save the last calculation locally so it's there next time.
- A "How Zakat works" info section with sources.
- A disclaimer: "For complex cases (business, property, pensions), consult a
  qualified scholar."

Add a home-grid tile "Zakat". Put calculation logic in a separate
lib/services/zakat_service.dart with unit tests in test/ for the math.
```

---

## 4. Hijri Calendar + Islamic Events -> DONE

```
Build a Hijri Calendar screen with Islamic events and fasting reminders.

Calendar:
- Monthly calendar showing Hijri dates with the Gregorian date small
  underneath (the `hijri` package is already used in
  prayer_times_controller.dart). Swipe between months. "Today" button.
- Settings option "Hijri date adjustment" (-2 to +2 days) because moon
  sighting differs by country. Apply this adjustment everywhere the app shows
  a Hijri date, including the prayer times screen.

Events (highlight on calendar + list below the calendar):
- Islamic New Year (1 Muharram), Ashura (10 Muharram, plus note to fast 9th
  or 11th too), Mawlid note (12 Rabi al-Awwal, mention scholars differ),
  Isra & Mi'raj (27 Rajab, note that the date is debated), 15 Sha'ban,
  start of Ramadan, last 10 nights / Laylatul Qadr (odd nights),
  Eid al-Fitr, Day of Arafah (9 Dhul Hijjah), Eid al-Adha, Days of Tashreeq.
- Sunnah fasts: Mondays & Thursdays, White Days (13, 14, 15 of every Hijri
  month), Arafah, Ashura, 6 days of Shawwal.
- Tapping an event shows a short description with its source.

Reminders:
- In settings, toggles for: "White Days fasting reminder",
  "Monday/Thursday fasting reminder", "Important Islamic dates".
- Notify the evening before (after Maghrib-ish, e.g. 8 PM) so people can
  plan suhoor. Use notification IDs 500-599 only. Schedule only the next
  ~30 days and re-schedule when the app opens.
- Never schedule fasting reminders on days when fasting is forbidden
  (Eid days, Days of Tashreeq).

Add a home-grid tile "Calendar". Put event logic in
lib/services/islamic_calendar_service.dart.
```

---

## 5. Morning & Evening Adhkar Player -> DONE

```
Build a Morning & Evening Adhkar feature.

Content:
- Create lib/data/adhkar_data.dart with the morning and evening adhkar from
  Hisn al-Muslim. Each item: Arabic text, transliteration, translation,
  how many times to repeat, the virtue (fadilah) if any, and the source
  reference (book + hadith number). Add the CONTENT REVIEW REQUIRED comment.
  Translations for the other app languages in the same style as lib/data/i18n/.

Screen:
- Two tabs: Morning (after Fajr) / Evening (after Asr). Auto-open the right
  tab based on the current time and today's prayer times.
- One dhikr per page (swipe), with a large tap-to-count button. Each tap
  counts down from the repeat number (e.g. 3 -> 2 -> 1 -> done), with light
  haptic feedback, then auto-moves to the next dhikr.
- Progress bar at the top ("7 of 24").
- Link the counts to the existing Tasbeeh (lib/services/tasbeeh_service.dart):
  total dhikr counted today should also show in the Tasbeeh stats.
- Completion screen when finished, plus mark today as completed.

Audio:
- Play/pause button per dhikr IF free, properly licensed audio exists. If it
  doesn't, leave audio out and tell me. Do NOT add unlicensed audio. Use
  just_audio like the Quran player.

Reminders:
- Settings toggles for "Morning adhkar reminder" (30 min after Fajr) and
  "Evening adhkar reminder" (30 min after Asr), based on the user's prayer
  times. Use notification IDs 410-411 only, and re-schedule together with
  the prayer notifications.

Add a home-grid tile "Adhkar".
```

---

## 6. Adhan Sound Picker -> DONE

```
Build an Adhan sound picker for prayer notifications.

What it does:
- In settings, a screen "Adhan Sound" with options:
  Makkah Adhan, Madinah Adhan, Mishary Alafasy Adhan, the current default
  adhan (assets/audio/adhan.ogg), "Short beep", and "Silent (notification
  only)".
- Each option has a preview play button.
- A separate choice for Fajr (Fajr adhan has "As-salatu khayrun min an-nawm"),
  with an option to use a quieter/shorter sound for Fajr.
- Per-prayer control: for each of the 5 prayers choose Adhan / Beep / Silent
  / Off.

Implementation notes (read carefully):
- Look at how local_notifications_service.dart currently plays adhan
  (iOS uses 'adhan.caf', Android uses a channel).
- iOS: notification sounds must be in the app bundle, be .caf/.aiff/.wav, and
  be 30 seconds or less. Provide trimmed iOS versions and tell me exactly which
  Xcode steps are needed to add them to the Runner target.
- Android: put sounds in android/app/src/main/res/raw/. Android notification
  channel sounds CANNOT be changed after the channel is created, so create one
  channel per sound (e.g. prayer_times_makkah, prayer_times_madinah...), and
  pick the channel based on the user's choice.
- After the user changes a sound, re-schedule all prayer notifications.

Audio files:
- I must supply the audio files. Do NOT download random audio. Create
  placeholder entries and a clear list of the files I need to add (names,
  formats, max length, folder). Add each file's license info to
  assets/audio/LICENSE.md when I add them.
```

---

## 7. Hifz (Memorization) Mode ->DONE

```
Build a Hifz (Quran memorization) mode.

Entry:
- In the Quran reader (lib/surah.dart), add a "Hifz mode" button. Also add a
  "Hifz" tile on the home grid that opens a Hifz dashboard.

Repeat practice:
- User selects an ayah range (e.g. Al-Mulk 1-5).
- Plays verse-by-verse audio with the selected reciter (reuse
  quran_audio_service.dart / api.alquran.cloud verse-by-verse audio).
- Options: repeat each ayah N times (1-20), repeat the whole range M times,
  pause gap between repeats (0-10 s), playback speed (0.75x-1.25x).
- Highlight the ayah currently playing.

Test yourself:
- "Hide words" mode: progressively hide words of the ayah (first letters only
  -> every other word -> all hidden). Tap a hidden word to reveal it.
- User marks each ayah as "Remembered" or "Need practice".

Progress tracking:
- Dashboard: list of surahs with % memorized, total ayahs memorized,
  Juz Amma progress, and a "Review today" list using simple spaced
  repetition (review an ayah after 1, 3, 7, 14, 30 days).
- Store locally; if the user is signed in, sync to Firestore under their user
  document, following the bookmark_service.dart pattern (local first,
  mirror to Firestore, never fail if Firestore fails).

Must work with the screen locked / in the background using the existing
audio_service handler (lib/services/quran_audio_handler.dart).
```

---

## 8. Mushaf Page View -> DONE

```
Add a page-by-page Mushaf view to the Quran reader.

What it does:
- In the Quran section, add a toggle "Surah view / Mushaf view".
- Mushaf view shows the Quran page by page (604 pages, standard Madani
  Mushaf page numbering), swiping right-to-left like a real Mushaf.
- Each page shows: Juz number, surah name, page number, surah headers and
  Bismillah where a surah starts.
- Jump to: page number, Juz (1-30), Hizb, or surah.
- Remember the last read page and offer "Continue from page X" on the
  Quran screen.
- Bookmark a page (reuse the existing bookmark system with a new bookmark
  type for pages).
- Long-press an ayah: show translation, play audio from that ayah, bookmark,
  share.

Implementation:
- Use the `quran` package page data (getPageData / getPageNumber etc.) to
  get which verses belong to each page. Do not hard-code Quran text.
- Render with the existing Arabic font (Amiri/NotoNaskhArabic). Use justified
  text, and make it look as close to a printed Mushaf as possible.
  Support font-size adjustment.
- Night/sepia/white page backgrounds that follow the app theme.
- Keep scrolling smooth: build pages lazily with PageView.builder.

Note: an exact printed-Mushaf look needs the per-page QCF fonts (604 font
files). Do NOT add those now. Tell me the size and effort involved so I can
decide later.
```

---

## 9. Ask AI with Voice

```
Add voice input and clickable references to the Ask AI screen
(lib/ask_ai.dart, controller lib/controllers/ai_qa_controller.dart,
service lib/services/ai_fatwa_service.dart).

Voice input:
- Add a microphone button next to the text field. Hold or tap to speak,
  using the `speech_to_text` package.
- Recognize speech in the current app language (Urdu ur-PK, Arabic ar-SA,
  English, Hindi, Turkish, French, German, Chinese). Add a small language
  switcher on the mic button so a user can speak Urdu even if the app is in
  English.
- Show live transcription in the text field; the user can edit before
  sending.
- Permissions: add NSMicrophoneUsageDescription and
  NSSpeechRecognitionUsageDescription to ios/Runner/Info.plist and
  RECORD_AUDIO to AndroidManifest.xml. Handle "permission denied" with a
  friendly message and a button to open settings.

Listen to answers (optional toggle):
- A speaker button on each answer that reads it aloud with `flutter_tts` in
  the matching language.

Clickable references:
- Parse references in AI answers, e.g. "Quran 2:255", "Surah Al-Baqarah
  2:255", "Sahih Bukhari 1", "Sahih Muslim 2564".
- Make them tappable chips: Quran references open the Quran reader at that
  ayah; Hadith references open the matching book in the Hadith screens if it
  exists, otherwise do nothing harmful.
- Update the system prompt in ai_fatwa_service.dart so the AI formats
  references in one consistent, parseable format.
- Put the parser in its own file with unit tests in test/.

Keep the existing disclaimers about confirming rulings with a qualified
scholar.
```

---

## 10. Family / Group Khatam (EXCLUDE)

```
Build a Group Khatam feature: complete the whole Quran together by splitting
the 30 Juz between family or friends.

Flow:
- "Group Khatam" tile on home. Requires sign-in (show a friendly sign-in
  prompt for guests).
- Create a Khatam: name (e.g. "Family Ramadan Khatam"), optional intention
  (e.g. "for grandmother"), optional deadline date.
- Share it with a 6-character invite code and a share link/text via
  share_plus.
- Join with the invite code.
- Juz board: a grid of 30 Juz showing status: Available / Taken by <name> /
  Completed. Tap an available Juz to take it. Tap your own Juz to open it in
  the Quran reader, or mark it Completed, or release it.
- Progress bar (e.g. 18/30) and a celebration screen when all 30 are done,
  with an option to start a new round.
- The creator can remove members and reassign Juz.

Firestore design:
- Collection `khatams/{khatamId}` with name, intention, createdBy,
  inviteCode, deadline, round, createdAt, and a `members` list of uids.
- Subcollection or map for the 30 Juz assignments.
- Use transactions when taking a Juz so two people can't take the same one.
- Real-time updates with snapshots().
- Write Firestore security rules: only members can read; members can
  only change their own Juz; only the creator can delete or remove members.
  Put them in firestore.rules and wire it into firebase.json, and tell me
  the command to deploy them.

Notifications:
- Use Firebase Messaging (already set up in
  lib/services/push_notification_service.dart) to notify members when the
  khatam is completed, and a reminder 2 days before the deadline if their Juz
  is not done. If that needs a Cloud Function, write it in functions/ and
  tell me how to deploy it.
```

---

## 11. Hajj & Umrah Guide -> DONE

```
Build an offline Hajj & Umrah Guide.

Structure:
- Home-grid tile "Hajj & Umrah". Two sections: Umrah guide and Hajj guide
  (day by day: 8th to 13th Dhul Hijjah).
- Each guide is a list of steps: Ihram (and its restrictions), Tawaf, Sa'i,
  Halq/Taqsir, Mina, Arafah, Muzdalifah, Rami (stoning), Qurbani, Tawaf
  al-Ifadah, Tawaf al-Wada.
- Each step has: what to do, its ruling (Rukn / Wajib / Sunnah), the duas to
  say (Arabic + transliteration + translation + source), common mistakes,
  and where madhabs differ, a short note.
- Checklist mode: tick off each step as you go; save progress locally so it
  works with no internet. A "Reset" button for a new trip.
- Tawaf and Sa'i round counter: a big tap counter for 7 rounds with
  haptics.
- Packing checklist (editable: add/remove your own items).
- "Places" section: Masjid al-Haram, Masjid an-Nabawi, Mina, Arafah,
  Muzdalifah, Jamarat, with an "Open in Maps" button (url_launcher).

Content:
- Create lib/data/hajj_umrah_data.dart with the CONTENT REVIEW REQUIRED
  comment, sources for every dua and ruling, and translations for the other
  app languages in the style of lib/data/i18n/.
- Everything must work fully offline.
- Show a note at the top: "Follow the guidance of your group's scholar."
```

---

## 12. Apple Watch & Wear OS App -> (REPLACED by 23)

```
Build companion watch apps: Apple Watch (watchOS) and Wear OS.
Features on the watch: today's prayer times with a next-prayer countdown,
and a Tasbeeh counter.

IMPORTANT: Flutter cannot build watch UIs. Use native code:
- watchOS: SwiftUI watch app target inside ios/Runner.xcodeproj.
- Wear OS: a separate Kotlin + Jetpack Compose for Wear OS module in
  android/.

Prayer times on the watch:
- Calculate prayer times ON the watch so it works without the phone, using
  the Adhan library for Swift (adhan-swift) and Kotlin (adhan-kotlin), the
  same library family as the Flutter `adhan` package in pubspec.
- Sync the user's settings from the phone: location (lat/lng), calculation
  method, madhab and Hijri adjustment.
  - iOS: WatchConnectivity (updateApplicationContext), sent from Flutter via a
    MethodChannel in ios/Runner/AppDelegate.swift.
  - Android: Wearable Data Layer API (DataClient), sent via a MethodChannel
    in MainActivity.
- Show: next prayer name + countdown, all 5 times, Hijri date.
- Complications / tiles: next prayer + time (watchOS complication and Wear OS
  Tile).

Tasbeeh on the watch:
- Big tap area, haptic on each tap, presets 33 / 99 / 100 / custom, reset.
- Sync totals back to the phone's Tasbeeh (lib/services/tasbeeh_service.dart).

Deliver:
- Step-by-step instructions for what I must do by hand in Xcode and
  Android Studio (adding targets, signing, bundle IDs, capabilities).
- Do this in two phases: Phase 1 = Apple Watch, Phase 2 = Wear OS. Stop after
  Phase 1 so I can test it before you continue.
```

---

# Part 2: Platform, Quality & UX Fixes

These are smaller and fix things users notice right away. Do them
**before** Part 1. Suggested order: 18 → 15 → 16 → 17 → 14 → 14B → 13.
Remember to paste Section 0 above each one.

---

## 13. macOS Optimization

```
Make the app run properly and look native on macOS (the macos/ folder and
Firebase macOS options in lib/firebase_options.dart already exist).

Step 1 - Make it build and run without crashes:
- Run `flutter run -d macos`, fix every build and runtime error.
- macos/Runner/DebugProfile.entitlements and Release.entitlements:
  add com.apple.security.network.client (needed for Firebase, Quran audio,
  Hadith API, Ask AI - it is currently missing) and
  com.apple.security.personal-information.location for prayer times.
  Add NSLocationUsageDescription to macos/Runner/Info.plist.
- Guard every plugin that does not support macOS with a platform check so
  it never crashes:
  - google_mobile_ads: no ads on macOS. BannerAdWidget
    (lib/widgets/banner_ad_widget.dart) must return SizedBox.shrink() on
    macOS. Check its Platform.isIOS logic so macOS never gets an Android ad ID.
  - flutter_qiblah / sensors_plus: Macs have no compass. On macOS, show the
    Qibla direction as a bearing in degrees from North plus a static map-
    style arrow, with a note "Use your phone for the live compass".
  - image_picker, file_picker, permission_handler, firebase_messaging,
    flutter_local_notifications, audio_service: check macOS support for each
    and disable/adapt what doesn't work. Keep Quran audio working.
- Create one helper, lib/utils/utils/platform_utils.dart, with getters like
  isMacOS, isMobile, supportsAds, hasCompass. Use it everywhere instead of
  scattered Platform checks.

Step 2 - Desktop layout:
- The app uses flutter_screenutil with designSize 360x690 (lib/main.dart).
  On a big Mac window this makes text and icons huge. Fix it so on macOS
  (and any width > 600) sizes do NOT scale up with window size: cap the
  scale or use fixed sizes on desktop.
- Set a sensible minimum window size (e.g. 900x640) and default size in
  macos/Runner/MainFlutterWindow.swift.
- Replace the floating bottom nav bar with a left sidebar
  (NavigationRail) when the window is wider than 900 px.
- Constrain reading content (Quran, Hadith, Dua, Ask AI chat) to a max
  width of ~760 px, centered, so lines are not too long to read.
- Home grid: more columns on wide windows (use LayoutBuilder).

Step 3 - Feel like a Mac app:
- Mouse hover effects and click cursor (SystemMouseCursors.click) on all
  tappable items.
- Keyboard shortcuts: Cmd+F search, Space play/pause Quran audio,
  Left/Right arrow previous/next page in the Quran reader, Cmd+, open
  Settings, Esc go back.
- Text in Quran/Hadith/Dua is selectable (SelectableText) so users can copy.
- Scrollbars visible on desktop.
- Proper app name, icon and About menu in the macOS menu bar.

Done when: the app runs on macOS with no red error screens, every screen is
usable with mouse and keyboard, the window resizes without overflow errors,
and NOTHING changes on iPhone or Android (test both after).
List every manual step I need in Xcode (signing, App Sandbox, Mac App Store).
```

---

## 14. iPhone (All Sizes) Optimization -> (DONE)

```
Optimize the app for every iPhone, from the smallest (iPhone SE, 4.7")
to the biggest (Pro Max), and for Dynamic Island and notch phones. Also
make it look good on iPad.

Check and fix on these simulators: iPhone SE (3rd gen), iPhone 16,
iPhone 16 Pro Max, and an iPad. (Run with
--dart-define-from-file=dart_defines.json.)

Layout:
- Go through EVERY screen and fix overflow errors (yellow/black stripes)
  and text that gets cut off, especially on iPhone SE and with large
  text sizes.
- Safe areas: nothing hidden under the notch, Dynamic Island or the
  home indicator. The floating glass bottom nav bar must sit above the home
  indicator and must not cover the last item of any list (add bottom
  padding to scrollable content).
- Respect the user's iOS text size (Settings > Accessibility > Larger Text)
  up to at least 1.3x without breaking layouts. Use a text scale clamp in
  MaterialApp's builder rather than ignoring the setting.
- flutter_screenutil (designSize 360x690 in lib/main.dart): make sure
  sizes don't get too big on Pro Max and iPad. Use minTextAdapt and cap
  the scale factor on wide screens.
- Landscape: either support it properly on the Quran reader, Hadith and
  Ask AI, or lock the app to portrait on iPhone (not iPad). Pick one and
  tell me.

iPad:
- Allow all orientations on iPad, use the wider layout: 2-3 column home
  grid, centered reading content with max width ~760 px.

iOS feel:
- iOS swipe-back gesture works on every screen opened with Get.to.
- Haptic feedback on Tasbeeh taps and important buttons
  (HapticFeedback.lightImpact).
- Keyboard: tapping outside a text field closes the keyboard; text
  fields scroll above the keyboard (Ask AI, Login, Registration, Search).
- Smooth 120 Hz scrolling on ProMotion phones: find and fix janky screens
  (heavy rebuilds inside Obx, large images not cached, shrinkWrap lists
  inside scroll views like in lib/quran.dart).

Done when: no overflow on any screen on the 4 devices above, in light and
dark mode, in English and Urdu (RTL). Give me a short list of what you
changed per screen.
```

---

## 14B. iPhone Duo (Foldable) Optimization -> (REPLACED by 22)

```
Optimize the app for iPhone Duo, Apple's foldable iPhone (iOS 27).
Facts about the device:
- Closed: 5.4" outer display. Open: 7.6" inner display that opens like a
  book into a wide screen. Both run the SAME app instance, and the window
  size changes instantly when the user folds/unfolds.
- On the inner display, iOS 27 supports Split View (two apps side by side)
  and resizable app windows, so our app can be ANY width, not just the
  two screen sizes.
- Apps that are not adaptive do not use the full inner screen. Ours must
  be adaptive.
Use the iPhone Duo simulator in Xcode 27 to get the real point sizes; do
NOT hard-code device sizes or detect the device model. Base everything on
the current window size (MediaQuery.sizeOf / LayoutBuilder).

Step 1 - Adaptive foundation:
- Create lib/utils/utils/layout/breakpoints.dart with width-based layout
  classes: compact (< 600), medium (600-840), expanded (> 840). Use it in
  all screens. (Share it with the macOS/iPad work in prompts 13 and 14.)
- flutter_screenutil is initialized with designSize 360x690 in
  lib/main.dart. On the inner display this would blow up all text and
  icons. Fix it so sizes do not scale up past a sensible maximum on wide
  windows, and so fonts don't jump in size on fold/unfold.
- ios/Runner/Info.plist: make sure the app is allowed to run in Split View
  and resizable windows (do NOT add UIRequiresFullScreen), and check that
  the orientation settings work on the inner display. Tell me exactly what
  you changed.

Step 2 - Fold/unfold continuity (most important):
Folding or unfolding must NEVER lose what the user is doing. Test each:
- Quran audio keeps playing, the highlighted ayah and page stay the same.
- Scroll position in Quran, Hadith, Dua lists is kept.
- Tasbeeh count is kept (no double count from the resize).
- Text typed in Ask AI / Search / Login stays, keyboard behaves properly.
- No screen pops back to Home, no controller is re-created, no splash
  screen again. Check GetX controllers are not disposed/re-put on resize,
  and that nothing heavy runs in build() when the size changes.
- No overflow errors during the fold/unfold animation.

Step 3 - Use the big inner screen well (two-pane layouts when expanded):
- Quran: Surah list on the left, reader on the right. Selecting a surah
  updates the right pane instead of pushing a new screen.
- Hadith: books/chapters on the left, hadith detail on the right.
- Dua and Fiqh: categories left, content right.
- Ask AI: previous questions list left, chat right.
- Mushaf view (if prompt 8 is done): show TWO pages side by side like an
  open printed Mushaf (right page = odd page, RTL order).
- Home: wider grid (4+ columns) and prayer times + next prayer card side by
  side with the feature grid.
- Prayer Times: times list + Qibla/map side by side.
- Bottom nav bar: on expanded width, switch to a side NavigationRail.
- Reading text never stretches across the full 7.6" width: max ~760 px,
  centered.
When the user folds the phone while in a two-pane view, collapse to the
single-pane screen showing the SAME item they had open (e.g. the open
Surah), not the list.

Step 4 - Split View:
- With our app taking half or a third of the inner screen, it must look
  like the normal phone layout (compact), and switch layouts live as the
  user drags the divider.

Done when: in the iPhone Duo simulator, folded, unfolded, and in Split
View at different widths, every screen works with no overflow, in light
and dark mode, English and Urdu (RTL), and fold/unfold during audio
playback loses nothing. Do not change the phone layout on normal iPhones.
Give me a checklist of what I should test on a real device.
```

---

## 15. Highlight the Ayah Being Recited -> (DONE)

```
When Quran audio is playing in the Surah reader (lib/surah.dart), highlight
the ayah the Qari is reciting right now, so the user can follow along.

How the audio works now (read these first):
- lib/services/quran_audio_handler.dart plays a ConcatenatingAudioSource
  with ONE audio item per ayah (verse-by-verse from api.alquran.cloud), and
  exposes currentIndexStream. So currentIndex = the ayah being recited
  (index 0 = ayah 1, unless playback started from a later ayah - check
  startIndex in the loading code and map it correctly).
- lib/surah.dart shows the ayahs paginated, 3 per page (currentPage).
- surah.dart already tracks whether THIS surah is the one playing
  (_isThisSurahPlaying). Only highlight when this surah is the one loaded.

What to build:
1. Listen to currentIndexStream in surah.dart (cancel the subscription in
   dispose, like _playingSub).
2. Highlight the current ayah card clearly: tinted background using the
   theme accent color, a colored left border (right border in RTL), and a
   small "now playing" sound-wave icon. Animate the change smoothly
   (AnimatedContainer, ~300 ms). Must look good in light and dark mode.
3. Auto-follow: when the playing ayah moves to an ayah on another page,
   automatically switch currentPage to that page and scroll the highlighted
   ayah into view. If the user manually changes page while audio plays,
   stop auto-following until they tap a "Follow recitation" button that
   appears at the bottom.
4. Tap any ayah to start playing from that ayah
   (handler.seekToAyahIndex), with the highlight jumping there.
5. When audio is paused, keep the highlight on the paused ayah. When
   stopped or finished, remove it.
6. Save the last recited ayah as "last read" (QuranController
   updateLastReadSurah) so Continue Reading returns to it.
7. Works with the screen locked: when the user comes back, the correct
   ayah is highlighted immediately.

Do not change how audio is fetched or played. Done when: playing Al-Fatiha
and Al-Mulk highlights each ayah in sync, pages turn automatically, and
tapping an ayah jumps the audio there.
```

---

## 16. Make "Ask AI" Easy to Find -> (DONE)

```
Many users don't discover the Ask AI feature (lib/ask_ai.dart). It is only
one tile in the home grid. Make it clearly visible as soon as the app opens.

Build BOTH of these:

1. "Ask AI" search-style bar at the top of the home screen
   (lib/home.dart, in or just below _buildHeaderCard):
   - Looks like a rounded search bar with a sparkle/AI icon
     (Iconsax.magic_star) and placeholder text that rotates every few
     seconds through example questions, e.g.
     "Ask AI: How do I pray Witr?",
     "Ask AI: Dua for anxiety",
     "Ask AI: What breaks the fast?"
     (all localized in the 8 .arb files).
   - Tapping it opens AskAiScreen with the keyboard already open.
   - Keep the existing search icon for normal app search; the two must
     look clearly different (one says "Ask AI").

2. Floating "Ask AI" button:
   - A pill-shaped floating action button with the AI icon + "Ask AI" text,
     shown on Home, Quran, Hadith, Dua and Fiqh screens.
   - Position it bottom-right (bottom-left in RTL), ABOVE the floating
     glass bottom nav bar (lib/widgets/bottom_navbar.dart) so it never
     overlaps it or the banner ad.
   - When the user scrolls down, shrink it to just the icon; when they
     scroll up, expand it again.
   - Context-aware: when opened from a Hadith, Dua or Surah screen, pre-fill
     the question with context, e.g. "Explain Surah Al-Mulk, ayah 2", so
     the user can just press send.
   - Do NOT show it on the Ask AI screen itself, Login, Registration,
     Settings or Tasbeeh.

3. First-launch hint: the first time Home opens, show a one-time small
   tooltip pointing at the Ask AI button ("Ask any Islamic question").
   Save that it was shown in VoidStorage so it never appears again.

Must look good in light/dark mode and RTL, on small and big phones.
```

---

## 17. Tasbeeh: Count of 7 + a Separate Counter per Color -> (DONE)

```
Improve the Tasbeeh screen (lib/tasbeeh.dart and
lib/services/tasbeeh_service.dart).

Part A - Add a target of 7 (for Tawaf and Sa'i during Umrah/Hajj):
- Currently _targetOptions = [33, 99, 100]. Change to [7, 33, 99, 100]
  and keep the Custom option.
- When target is 7, show a small label "Tawaf / Sa'i rounds" under the
  counter, and give a stronger vibration + short sound when 7 is reached.

Part B - Each bead color is its own separate tasbeeh with its own saved
count:
- Right now changing color only changes the color, and there is ONE shared
  count (key 'tasbeeh_session_count') and ONE target ('tasbeeh_target').
- New behavior: each color (gold, oliveDeep, green, red, purple, orange)
  is an independent counter with its OWN count AND its OWN target.
  Example:
    1. User picks Red, sets target 33, counts to 33.
    2. Switches to Brown/Olive, sets target 100, counts to 100.
    3. Switches back to Red -> shows 33 with target 33, exactly as left.
    4. Closes the app, opens it again -> still Red 33, Olive 100.
- Also remember which color was selected last and open on it.
- Optional: let the user give each color a name (long-press the color
  dot), e.g. Red = "SubhanAllah", Olive = "Astaghfirullah". Show the name
  under the counter.
- Reset only resets the CURRENT color's count (ask for confirmation).
  Add a "Reset all" option in a menu.
- Show a tiny count badge on each color dot so the user can see all
  counters at a glance.

Storage:
- Store per-color data in VoidStorage as a map keyed by a stable color ID
  (e.g. 'red', 'olive'), NOT by Color.value, with { count, target, name }.
- Migrate existing users: on first launch after the update, move the old
  'tasbeeh_session_count' and 'tasbeeh_target' into the gold (default)
  color so nobody loses their count. Then remove the old keys.
- Keep TasbeehService.addToLifetimeTotal working: every tap on ANY color
  still adds to the lifetime total and Firestore sync as now.

Add unit tests for the storage + migration logic. Done when the 4-step
example above works exactly as described.
```

---

## 18. Make Whole List Rows Tappable (Surah list and all lists) -> (DONE)

```
Bug: in the Surah list (lib/quran.dart), the user must tap exactly on the
surah name text to open it. Tapping the empty space in the row, the number
circle, or the Arabic name does nothing. New users think the app is broken.

Root cause: the row is wrapped in a GestureDetector WITHOUT
`behavior: HitTestBehavior.opaque` (lib/quran.dart, the ListView.builder
around line 162 and buildSurahTile). A GestureDetector without opaque
behavior only receives taps on painted pixels (the text), not on the
empty space between them.

Fix it strictly and correctly:
1. In lib/quran.dart replace the GestureDetector with Material + InkWell
   (so the user also sees a ripple / pressed effect) that covers the
   ENTIRE row: full width, full height, including the number circle,
   name, translation, ayah count, Arabic name and all empty space in
   between and the padding above/below. Use the existing theme colors for
   the ripple and give it a rounded shape matching the design.
2. Keep the exact same onTap logic (updateLastReadSurah + Get.to
   SurahScreen). Do not change how the row looks.
3. Make sure the divider line between rows is not part of the tappable
   area of the wrong surah.
4. Minimum tap height 48 px (accessibility guideline).
5. Add Semantics(button: true, label: "<surah name>") for screen readers.

Then check EVERY other list in the app for the same bug and fix it the
same way. At minimum:
- lib/hadith.dart (Hadith books)
- lib/hadith_chapters.dart (chapters)
- lib/dua.dart and lib/dua_2.dart (dua categories and duas)
- lib/fiqh.dart, lib/seerat.dart, lib/tib_e_nabwi.dart
- lib/bookmarks_screen.dart, lib/notification.dart,
  lib/widgets/search_screen.dart, lib/widgets/MosqueCardWidget.dart
- Settings and Profile rows (lib/settings.dart, lib/profile.dart)
- Home grid tiles in lib/home.dart (whole tile tappable, not just the
  icon/text)
Search the project for `GestureDetector(` and check each one that wraps a
row, card or tile.

Done when: on every list in the app, tapping ANYWHERE on a row or card
opens it, with a visible press effect. Give me a list of every file and
widget you fixed.
```

---

# Part 3: Community, Games, Stories & New Devices

Suggested order: 21 (Stories) → 19 (Challenges) → 20 (Games) → 22 (Foldable)
→ 23 (Watch). Stories come first because the games reuse their content, and
Challenges come before Games because "challenge a friend" in the games uses
the Challenges system. Paste Section 0 above each one, as usual.

Big features (19, 20, 21, 23) are split into phases. Tell Claude to STOP after
each phase so you can run the app and commit before it continues.

---

## 19. Islamic Challenges (compete with friends & family) -> DONE

```
Build "Challenges": a user creates a goal, shares a code, friends and family
join, everyone marks their progress, and everyone sees each other's updates
in a chat-style feed with push notifications.
Examples: "I will read the whole Quran in 10 days, compete with me",
"I will memorize Surah Al-Mulk in 2 days", "I will memorize 10 ahadith in
3 days".

Read first: lib/home.dart, lib/services/push_notification_service.dart,
lib/services/reading_stats_service.dart, lib/services/hifz_service.dart,
lib/services/tasbeeh_service.dart, lib/services/app_share_service.dart,
lib/notification.dart, firebase.json. Section 10 of NEXT_UPDATE_PROMPTS.md
was a similar idea (Group Khatam) that we dropped; this feature replaces it.

--- Phase 1: Data + create/join ---

Challenge types (templates). Each has a unit and a target:
- Quran Khatam: read the whole Quran in N days (unit: Juz, target 30;
  or pages, target 604).
- Read X Juz / X pages in N days.
- Memorize a Surah in N days (pick the surah from the `quran` package list;
  unit: ayahs, target = that surah's ayah count).
- Memorize X ahadith in N days (unit: ahadith).
- Dhikr / Durood count (e.g. 10,000 Durood in 7 days; unit: count).
- Fasting: X voluntary fasts in N days (unit: days).
- Tahajjud / Fajr on time for N nights (unit: days, one tick per day).
- Custom: free title + unit + target.

Create screen: pick a template, set the target and duration (start now or
on a date), optional intention (niyyah) text, privacy option "Show my exact
numbers" vs "Only show %" (some people prefer hiding their worship).
Max 50 members per challenge.

Join: 6-character invite code (no confusing letters: no O/0/I/1), plus a
share message via share_plus with the code and a link. If a deep link is
easy with the current setup, open the join screen from it; otherwise the
code is enough. Joining shows a preview (title, creator, members, days left)
before confirming.

Requires sign-in: guests see a friendly explanation and a sign-in button.

Firestore design (write it, then show me before coding the UI):
- challenges/{id}: title, type, unit, target, startAt, endAt, creatorUid,
  inviteCode, memberUids (array), memberCount, status
  (upcoming/active/finished), createdAt.
- challenges/{id}/participants/{uid}: displayName, photoUrl, progress,
  completedAt, showExactNumbers, muted, joinedAt.
- challenges/{id}/feed/{msgId}: kind (joined / progress / completed /
  message / reaction / nudge), uid, text, value, createdAt.
- inviteCodes/{code} -> challengeId, so joining is one lookup. Create the
  code in a transaction so codes are unique.
- firestore.rules: only members can read a challenge, its participants and
  feed; a user can only write their own participant doc and their own feed
  items; progress can't go down or above target via the rules; only the
  creator can edit/delete the challenge or remove a member. Add the rules
  to firebase.json and tell me the deploy command.
- Composite indexes needed -> firestore.indexes.json.

--- Phase 2: The challenge screen (make this look premium) ---

My Challenges list: active first, then upcoming, then finished. Each card:
title, days left, my progress ring, small avatar stack of members.

Challenge detail screen, three parts:
1. Header: title, intention, days left countdown, my big progress ring with
   "+1" / "+ add" buttons and a "Log progress" sheet (enter a number, or for
   Quran pick which Juz/pages, for memorize pick which ayahs).
2. Leaderboard strip: members sorted by % with rings, crown on the leader,
   check mark when completed. Respect "Only show %".
3. Feed (looks like a chat): bubbles for messages, special cards for
   "Ahmed finished Juz 12 (40%)", "Fatima joined", "Ali completed the
   challenge! MashaAllah". Reactions on each item: MashaAllah,
   BarakAllahu feek, Ameen, 🤲, ❤️ (counts shown). A text box to send short
   messages and a "Nudge" button for members who haven't logged today
   (max one nudge per person per day).
Real-time with snapshots(), paginate the feed (load 30 at a time).
Celebration screen with a subtle animation when someone reaches 100%, and
an end-of-challenge summary card that can be shared as an image (reuse
lib/share_cards/ style).

Auto progress (nice touch, optional per challenge): if the user reads in
our Quran reader or marks ayahs memorized in Hifz mode while a matching
challenge is active, ask "Add this to your challenge?" instead of
silently adding.

Safety: members can report a message or leave; the creator can remove a
member. Filter obvious profanity in messages. Messages max 300 chars.

--- Phase 3: Notifications ---

- Cloud Function in functions/ (TypeScript): on new feed item, send FCM to
  all other members (tokens are on users/{uid}.fcmToken) unless they muted
  the challenge. Batch it, and remove invalid tokens. Group notifications
  per challenge (thread-id on iOS, tag on Android) so 10 updates don't
  become 10 separate banners. Notification text in the RECEIVER's app
  language (store `language` on the user doc).
- Tapping the notification opens that challenge's detail screen (handle
  cold start, background and foreground).
- Scheduled function (once a day): remind members who are behind pace,
  e.g. "You're 2 Juz behind in 'Ramadan Khatam'. You can still make it!",
  and a "1 day left" reminder. Respect the settings toggle.
- Local reminder (no server): optional daily "Log your progress" reminder
  per challenge at a time the user picks. Use notification IDs 700-799
  only.
- Show challenge notifications in the existing in-app notification center
  (lib/notification.dart).
- Tell me exactly how to deploy the functions and what Firebase plan is
  needed (Cloud Functions need the Blaze plan).

--- Phase 4: Rewards (no money, nothing to buy) ---

Build ONE shared reward system that Challenges use now and Games (prompt
20) will reuse: lib/services/rewards_service.dart,
lib/data/rewards_data.dart (all badge/unlock definitions), and a
"My Rewards" screen opened from Profile.

Ground rules:
- Rewards are earned only by doing. Nothing can be bought, no money, no
  vouchers, no prizes, no paid "boosts".
- Core religious features (Quran, audio, prayer times, duas, stories)
  are NEVER locked behind rewards. Rewards are only cosmetic or
  meaningful.
- Never say or imply that app rewards equal reward from Allah. Wherever
  it fits, show: "The real reward is with Allah. This is only a
  reminder."
- Users can hide their badges from others (avoid showing off / riya).
- Avoid titles that sound like real religious ranks ("Hafiz", "Sheikh",
  "Mufti", "Wali"). Use words like "Finisher", "Steadfast", "Encourager".

The rewards:
1. Certificates: when someone completes a challenge, generate a beautiful
   certificate: their name, the challenge, dates, Islamic geometric border,
   "MashaAllah" / "BarakAllahu feek" calligraphy (Amiri font). Border style
   by result: Completed / Completed early / Never missed a day. Save as
   image or PDF and share (reuse lib/share_cards/ style).
2. Badges: a collection screen with locked (grey outline + how to earn
   it) and earned badges with the earned date. Examples: "First
   Challenge", "Khatam Finisher", "Steadfast" (logged every day of a
   challenge), "Early Bird" (completed early), "Encourager" (50 reactions
   sent), "Family Builder" (5 people joined from your codes), "Comeback"
   (finished after falling behind). Earned badges show as a small icon next
   to the user's name in challenge feeds (unless hidden). Unlock moment: a
   short, elegant animation + haptic, not a casino effect.
3. Cosmetic unlocks (earned at badge / level milestones):
   - Extra app accent themes (e.g. "Madinah Green", "Night of Qadr",
     "Desert Gold"), using the existing theme system.
   - Quran reader page frames / border styles.
   - Tasbeeh bead styles and colors.
   - Profile avatar frames.
   - Alternate app icons (iOS alternate icons + Android activity-alias;
     check a maintained Flutter package first, tell me the native steps).
4. My Jannah Garden: a calm, beautiful garden screen. Every completed
   challenge, finished Khatam, memorized surah or dhikr milestone plants a
   palm tree, flower or fountain there. Inspired by the hadith that
   saying "SubhanAllahi wa bihamdihi" plants a palm tree in Jannah
   (Jami' at-Tirmidhi, verify the exact number and grading and show it
   with the reference). Show clearly: "This garden is a reminder, the real
   garden is with Allah." No plant ever dies or is taken away (no guilt
   mechanics).
5. Dua Wall (the most Islamic reward): when a challenge ends, everyone who
   completed it gets a Dua Wall: the other members are invited to write a
   short dua for them, and they can write one back for everyone. Push
   notification: "Your family made 6 duas for you". Duas are only visible
   to challenge members, max 200 chars, can be reported.
6. Dedicate a challenge (optional field on create): "Dedicated to my late
   grandmother" or "For the people of Gaza". Shown on the challenge and the
   certificate. Note in the UI, neutrally, that scholars differ on whether
   the reward of acts like recitation reaches the deceased, and that dua
   for them is agreed upon.
7. Family Promise (optional text on create, max 100 chars): a non-money
   promise from the creator to the winner, e.g. "Winner chooses Friday
   dinner" or "I'll gift the winner a new Mushaf". Just text; the app
   doesn't handle anything. Placeholder examples must not mention money.

Anti-cheat and storage:
- Challenge-based badges and certificates are awarded by the Cloud Function
  (server side) from the Firestore data, so a user can't give themselves
  badges. Store in users/{uid}/rewards; rules: the user can read, only the
  server can write.
- Guests: local-only rewards for local actions (stored like
  bookmark_service), merged into the account on sign-in.
- Rewards screen and all reward texts in all 8 languages.

Islamic etiquette: show a small reminder on the create screen: "Purify
your intention. This is to encourage each other, not to show off." No
public/global leaderboard with strangers, only people with the code.

Home: add a "Challenges" tile, and if the user has an active challenge, a
small card on Home with progress + days left.

Analytics events: challenge_created, challenge_joined, progress_logged,
challenge_completed.

Done when: two test accounts on two simulators can create, join with the
code, log progress, chat, react and receive each other's notifications,
and when one finishes they get the certificate, badge, garden tree and Dua
Wall, all in light/dark mode and in English and Urdu (RTL).
```

---

## 20. Islamic Games ("Noor Journey")

```
Build a games section that makes people read and learn the Quran and keeps
them coming back every day. Call it "Noor Journey". It's one world map with
several mini-games, a daily puzzle, XP called "Noor", levels, badges and a
streak.

Read first: lib/home.dart, lib/surah.dart, lib/services/quran_audio_service.dart,
lib/data/reciters_data.dart, lib/services/reading_stats_service.dart,
lib/services/hifz_service.dart, lib/share_cards/, and the Prophets' Stories
data from prompt 21 if it exists.

Rules for respect (very important):
- Never show pictures, faces or figures of any Prophet, Sahabi or angel.
  Use calligraphy, geometric patterns, landscapes and places only.
- Quran text is never thrown around, exploded, or used as a "wrong answer"
  joke. Ayah words are shown on calm tiles. Wrong answers just show the
  correct ayah with its translation.
- No music. Sound effects are soft, with an on/off switch in Settings;
  haptics on. Quran audio clips are fine.
- No gambling mechanics, no loot boxes, nothing to buy, no ads inside games
  (Section 0: only the one banner ad in the app).
- All Quran text comes from the `quran` package; never type ayahs by hand.

--- Phase 1: Three Quran mini-games ---

1. Ayah Builder: shows an ayah's translation and the Arabic words shuffled;
   the user taps/drags the words into the right order (right-to-left). Hint
   button shows the first word. Great for Hifz.
2. Guess the Surah: play a short audio clip of a recitation (or show an
   ayah's text) and pick the surah from 4 options. Difficulty: Juz Amma ->
   whole Quran.
3. Complete the Ayah: an ayah with one or two words missing, pick the
   right word from 4 options.

Each game: choose a level (Juz 30 / Juz 29 / custom Juz range / "surahs I
memorized" from Hifz), 10 questions per round, results screen with the
ayahs to review and a "Read this surah" button that opens the reader.
Questions are generated from the Quran data, so there are endless
questions without hand-written content. Works offline (except audio clips
that aren't cached; cache them like hifz_audio_cache.dart does).

--- Phase 2: The world map + progression ---

- "Noor Journey" map: a vertical scrolling path of beautiful stages
  (Makkah, Madinah, Masjid al-Aqsa, the desert, the sea of Musa, the city
  of Yusuf...). Each stage is a set of levels using the mini-games and the
  Prophets' Stories quiz (step 3). Finishing a stage unlocks the next.
- Noor (XP) for games, AND for real worship actions already in the app:
  reading Quran pages, finishing adhkar, tasbeeh, memorizing ayahs. The
  game should push people to READ, not only play.
- Levels, badges (e.g. "First Juz", "7-day streak", "Juz Amma Master",
  "Story Seeker"), a daily streak with one free "streak freeze" per week.
- Daily Puzzle: the same Ayah Builder puzzle for everyone each day (pick
  the ayah from the date as a seed). After solving, share a result card
  like Wordle (no spoilers, just squares + time) via share_plus.
- Local daily reminder for the puzzle/streak: notification IDs 800-809.
- Store progress locally (guests) and sync to Firestore users/{uid}/games
  when signed in.

Rewards: REUSE the reward system from prompt 19 Phase 4
(lib/services/rewards_service.dart, My Rewards screen, Jannah Garden,
certificates). If 19 isn't done yet, build that shared system first,
exactly as described there. Same ground rules: nothing to buy, no money,
core features never locked. Noor is NOT a currency: it can't be spent,
it only fills levels. Game rewards to add:
- Level milestones unlock cosmetics: Ayah Builder tile styles, map themes
  (night map, Ramadan lanterns), app accent themes, avatar frames.
- Stage rewards: finishing a stage unlocks a "Place Card" for that place
  (e.g. Masjid al-Aqsa: the first Qibla, with source), collected in an
  album. Facts must be sourced and marked CONTENT REVIEW REQUIRED.
- 99 Names collection: earn one Name of Allah card per day of streak,
  linked to the existing Asma-ul-Husna screen (lib/asma_ul_husna.dart),
  with its meaning. Collecting all 99 earns a special badge.
- Streak rewards: every 7-day streak plants a tree in the Jannah Garden.
  Missing a day never removes anything.
- Seasonal frames: playing during Ramadan or the first 10 days of Dhul
  Hijjah (use the Hijri calendar service) earns a frame for that year.
- Game badges: "Juz Amma Master", "Ayah Builder 100", "Story Seeker" (all
  25 prophets' quizzes), "Perfect Round", "Daily Puzzle 30 days".
- Each badge shows a short related ayah or hadith with the reference
  (from the `quran` package / reviewed sources), so the reward itself
  teaches something.

--- Phase 3: Quiz + play with friends ---

- Prophets & Seerah Quiz: questions about the Prophets' Stories (prompt 21)
  and Seerah. Every question must come from our reviewed story data with a
  reference; mark the question bank with CONTENT REVIEW REQUIRED.
- Quiz Duel with a friend: create a duel, share a code (reuse the invite
  code system from Challenges, prompt 19), both answer the same 10
  questions (async, no need to be online together), see who won, with a
  push notification when the friend finishes. The winner gets a "Duel
  Winner" badge, and the other player is invited to make a short dua for
  them (same Dua Wall as Challenges); a draw means both make dua for
  each other.
- Family leaderboard: optional, only among people who share a code. No
  global leaderboard with strangers.

UI: this must feel like a modern premium game (smooth animations, haptics,
progress bars, confetti on stage complete) while matching our theme in
light and dark mode. Home tile: "Games". Accessible: big tap targets, and
works with larger font sizes.

Done when: all games work offline with Juz Amma, the map and streak
persist after app restart, the daily puzzle is the same on two devices,
and a duel works between two accounts.
```

---

## 21. Stories of the Prophets (Qasas al-Anbiya), all 8 languages -> DONE

```
Build "Stories of the Prophets": the stories from Prophet Adam (AS) to
Prophet Muhammad ﷺ in order, in all 8 app languages, fully offline.

Where the content comes from (there is NO trustworthy ready-made
multilingual API for this, so we build our own dataset):
- Main reference: Ibn Kathir, Qasas al-Anbiya (classical Arabic, 14th
  century). A digital Arabic text is in the OpenITI corpus:
  https://github.com/OpenITI/RELEASE/tree/master/data/0774IbnKathir/0774IbnKathir.QisasAnbiya
  Use it as the REFERENCE for the story order and events. Do not ship the
  raw OpenITI text before I confirm its license allows use in an app with
  ads.
- The Quran: every story chapter is built around the ayahs about that
  Prophet. Pull the Arabic text and translations from the `quran` package
  by surah:ayah reference, never typed by hand.
- Authentic hadith only (Bukhari/Muslim first), each with a sunnah.com
  style reference (book + number).
- Do NOT include Isra'iliyyat (stories from Jewish/Christian sources with no
  Quran/Sunnah basis) as fact. If a famous detail is only from such
  sources, either leave it out or label it clearly: "This detail is reported
  in some narrations and is not confirmed by the Quran or authentic hadith."
- English modern books (Darussalam, IIPH etc.) are copyrighted. Do NOT copy
  their text.

The 25 Prophets named in the Quran, in order: Adam, Idris, Nuh, Hud, Salih,
Ibrahim, Lut, Ismail, Ishaq, Yaqub, Yusuf, Ayyub, Shu'ayb, Musa, Harun,
Dhul-Kifl, Dawud, Sulayman, Ilyas, Al-Yasa, Yunus, Zakariya, Yahya, Isa,
Muhammad ﷺ. Where the order/timing is uncertain (e.g. Dhul-Kifl, Ayyub),
say so. For Muhammad ﷺ, write a short overview and link to our existing
Seerah section (lib/seerat.dart, lib/data/seerah_data.dart) instead of
repeating it.

--- Phase 1: Data format + reader, 3 prophets only ---

Data:
- JSON files in assets/stories/<lang>/<prophet_id>.json (en, ar, ur, fr,
  de, hi, tr, zh), loaded lazily, plus assets/stories/index.json.
- Each prophet: id, name in each language + Arabic name, title (e.g.
  Khalilullah for Ibrahim), people he was sent to, place (with lat/lng),
  approximate era, mentioned in which surahs, number of times named in the
  Quran, and chapters.
- Each chapter: title, paragraphs (simple, warm storytelling language), and
  "blocks" of type quran {surah, ayahStart, ayahEnd} or hadith {text
  translation, source, number} placed inside the story where they belong,
  plus "Lessons" (3-5 bullet points) and 3-5 quiz questions with answers
  and references (used by the games in prompt 20).
- Top of every file / a sidecar: "CONTENT REVIEW REQUIRED: verify against
  source before release" and a `reviewed: false` flag. The app shows a
  small "Under review" label on unreviewed stories in debug builds only.
- Write ENGLISH first for Adam, Nuh and Ibrahim (AS). Stop and show me.

Reader screen:
- Prophets list as a timeline (Adam at top to Muhammad ﷺ at bottom) with
  each Prophet's Arabic name in calligraphy style (Amiri font) and a
  geometric card, NO images of people. Always write "(AS)" / "عليه السلام"
  after names and ﷺ after the Prophet Muhammad's name.
- Story reader: chapters with progress, beautiful reading typography, font
  size control, Quran blocks shown with Arabic + translation in the user's
  language + a play button for that ayah's audio (reuse
  quran_audio_service), "Open in Quran" button, hadith blocks with the
  reference, a "Lessons" card at the end, "Next Prophet" button.
- Remember last position, mark chapters read, bookmarks (reuse
  bookmark_service), and add stories to the global search.
- Optional "Listen" mode using text-to-speech for the narration
  (flutter_tts) where the device supports that language; hide it if not.
- Kids mode toggle: shorter, simpler version of each chapter (a
  `kidsParagraphs` field).
- RTL perfect for Arabic and Urdu.

--- Phase 2: All 25 prophets, English ---

Write the remaining prophets in English, same rules, chapter by chapter.
Check every Quran reference actually exists and matches the story
(validate surah/ayah numbers with the `quran` package in a test). Write a
test that loads every JSON file and fails on a bad reference or a missing
field.

--- Phase 3: Translate to the other 7 languages ---

Translate from the English files to ar, ur, fr, de, hi, tr, zh. For Arabic,
you may use wording close to Ibn Kathir's classical Arabic where helpful.
Quran blocks need no translation (they come from the package); translate
only the narration, lessons, quiz and hadith translations. Keep religious
terms correct per language (e.g. Urdu: حضرت ابراہیم علیہ السلام). Add a
script in tool/ that reports missing keys or chapters per language.

Home: add a "Prophets' Stories" tile (and show "Story of the day" on Home
if it's easy).

When done, give me a list of all claims that are disputed or that a
scholar must double-check, per prophet, so I can send it for review before
release.
```

---

## 22. Foldable iPhone (and Android foldables) Optimization

```
Optimize the app for Apple's foldable iPhone (iOS 27, small outer display
when closed, large book-style inner display when open, same app instance
moves between them instantly). Also make it work on Android foldables
(Galaxy Z Fold, Pixel Fold) since it's the same Flutter code.

Rules:
- Do NOT detect the device model or hard-code screen sizes. Use the real
  sizes from the Xcode 27 foldable simulator only for testing. Everything
  is based on the current window size (MediaQuery.sizeOf, LayoutBuilder).
- iOS 27 on the inner display allows Split View and resizable windows, so
  our app can be ANY width.
- Read section 14B of NEXT_UPDATE_PROMPTS.md first: this prompt replaces
  it, and keep anything from section 14 (iPhone all sizes) that is already
  done.

Step 1 - Adaptive foundation:
- lib/utils/utils/layout/breakpoints.dart (create it if 13/14 didn't):
  compact < 600, medium 600-840, expanded > 840, plus a helper widget
  AdaptiveLayout(compact:, medium:, expanded:).
- flutter_screenutil (designSize 360x690 in lib/main.dart) would make text
  and icons huge on the inner display. Cap the scale on wide windows so
  fonts and icons stay a sensible size, and make sure fonts don't jump
  when folding/unfolding.
- ios/Runner/Info.plist: allow Split View / resizable windows (no
  UIRequiresFullScreen), orientations that make sense on the inner
  display. AndroidManifest: resizeableActivity=true, and handle
  configChanges so Android doesn't restart the activity on fold.
- Android hinge: use MediaQuery.displayFeatures so no content (buttons,
  ayah text) sits under the hinge in half-open (tabletop/book) postures.

Step 2 - Fold/unfold continuity (most important). Folding or unfolding
must NEVER lose what the user is doing:
- Quran audio keeps playing, the highlighted ayah and page stay the same.
- Scroll position in Quran, Hadith, Dua, Stories lists is kept.
- Tasbeeh count kept (no extra count from the resize).
- Typed text in Ask AI / Search / Login / Challenge chat stays.
- No pop back to Home, no splash, no GetX controller re-created, no heavy
  work in build() on resize.
- No overflow errors during the fold/unfold animation.

Step 3 - Use the big screen well (two-pane when expanded):
- Quran: surah list left, reader right. Mushaf: two pages side by side
  like a printed Mushaf (right page first, RTL).
- Hadith: books/chapters left, detail right. Dua, Fiqh, Adhkar, Prophets'
  Stories: list left, content right.
- Ask AI: history left, chat right. Challenges: list left, challenge
  detail + feed right. Games: map left, game right, or a bigger game board.
- Home: 4+ column grid, prayer card next to the grid.
- Prayer Times: times next to Qibla/map.
- Bottom nav -> NavigationRail on expanded width.
- Reading text max ~760 px wide, centered.
When folding while in two-pane, show the SAME open item single-pane (e.g.
the open Surah), not the list.

Step 4 - Split View / any width: switch layouts live while the user drags
the divider. Half-screen looks like the normal phone layout.

Step 5 - Home screen widgets (if done earlier): check they look right on
the inner display sizes too.

Done when: in the foldable simulator (folded, unfolded, Split View at
several widths) and an Android foldable emulator (including half-open
posture), every screen works with no overflow, light and dark mode,
English and Urdu (RTL), and folding during Quran playback loses nothing.
Normal iPhones must look exactly as before. Give me a real-device test
checklist.
```

---

## 23. Apple Watch & Wear OS Apps

```
Build companion watch apps for Apple Watch (watchOS) and Wear OS. This
replaces section 12 of NEXT_UPDATE_PROMPTS.md.

IMPORTANT: Flutter can't build good watch apps. Use native code:
- watchOS: SwiftUI watch app target in ios/Runner.xcodeproj (watchOS 11+),
  complications with WidgetKit (not old ClockKit).
- Wear OS: Kotlin + Compose for Wear OS module in android/ (Wear OS 4+),
  with a Tile and a Complication data source.
- Bundle/application IDs must match the phone app's so they install
  together. Check the App Group setup we already use for home widgets (see
  ios/ and the home_widget setup) and reuse it where possible.

Watch features:
1. Prayer times: next prayer name + live countdown, all 5 times, sunrise,
   Hijri date. Calculated ON the watch (works without the phone) with
   adhan-swift and adhan-kotlin, the same library family as the Flutter
   `adhan` package, using the SAME settings as the phone: lat/lng,
   calculation method, madhab, high-latitude rule, manual minute
   adjustments, Hijri adjustment. Times on the watch must equal the phone
   exactly. Write a test comparing them for 3 cities.
2. Complications / Tile: next prayer + time (circular, rectangular, inline
   on watchOS; Tile + complication on Wear OS). Update at each prayer
   time, not every minute (battery).
3. Tasbeeh: big tap area, haptic on each tap and a stronger one at 33 /
   the target, presets 33 / 99 / 100 / custom, the Digital Crown / rotary
   bezel also counts, reset. Works offline; sync totals to the phone's
   lib/services/tasbeeh_service.dart when connected (no double counting).
4. Qibla: arrow using the compass on watches that have one; hide it on
   ones that don't.
5. Today's adhkar reminder and active Challenge progress (from prompt 19,
   if done): show my % and a "+1" button that syncs to the phone, which
   then writes it to Firestore. The watch never talks to Firebase directly.
6. Prayer notifications: make sure the phone's prayer notifications appear
   on the watch (they mirror by default; check the categories are set so
   they look good on the watch).

Sync from Flutter:
- iOS: WatchConnectivity (updateApplicationContext for settings,
  transferUserInfo for tasbeeh/challenge counts), via a MethodChannel in
  ios/Runner/AppDelegate.swift.
- Android: Wearable Data Layer (DataClient for settings, MessageClient for
  counts), via a MethodChannel in MainActivity.
- Send settings again whenever the user changes location, method, madhab
  or language on the phone.
- Language: watch UI in the same 8 languages (Localizable.strings /
  strings.xml), RTL for Arabic and Urdu.

Design: dark, high-contrast, our brand colors, big text, readable at a
glance. Support all Apple Watch sizes (41-49 mm) and round + square Wear OS.

Phases (STOP after each so I can test):
- Phase 1: Apple Watch app (prayer times + tasbeeh + complications).
- Phase 2: Apple Watch extras (Qibla, challenges, adhkar).
- Phase 3: Wear OS app with the same features + Tile.

Deliver: step-by-step instructions for what I must do by hand in Xcode and
Android Studio (adding targets, signing, bundle IDs, capabilities, App
Groups), how to run it on the watch simulator / emulator, and what I need
for App Store / Play Store review (watch screenshots sizes, Wear OS store
listing requirements).
```
