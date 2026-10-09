/// Sounds for prayer-time notifications, and where each one's files live.
///
/// Every adhan needs three files (see tool/prepare_adhan_audio.sh and
/// assets/audio/LICENSE.md):
/// - Android: `android/app/src/main/res/raw/<androidRaw>.<ext>` - any length.
///   Android fixes a channel's sound when the channel is first created, so
///   each sound has its own channel ([channelId]) and the notification picks
///   the channel.
/// - iOS: `ios/Runner/<iosFile>` - .caf/.aiff/.wav, at most 30 seconds, and
///   a member of the Runner target (Copy Bundle Resources).
/// - Preview in Settings: `assets/audio/<preview>` (.m4a, plays on both).
///
/// Entries with [available] false are placeholders: shown in the picker but
/// not selectable until their files are added and the flag is flipped.
/// test/adhan_sounds_test.dart checks every available sound's files exist.
enum AdhanSoundKind { adhan, beep, silent }

class AdhanSound {
  final String id;
  final AdhanSoundKind kind;

  /// Notification channel on Android; one per sound.
  final String channelId;

  /// Name shown for [channelId] in Android's notification settings.
  final String channelName;

  /// res/raw resource name (no extension); null for beep and silent.
  final String? androidRaw;

  /// File name in the iOS app bundle; null for beep and silent.
  final String? iosFile;

  /// Flutter asset played by the preview button; null when there's none.
  final String? preview;

  /// A Fajr recording (with "as-salatu khayrun min an-nawm").
  final bool isFajr;

  final bool available;

  const AdhanSound({
    required this.id,
    required this.kind,
    required this.channelId,
    required this.channelName,
    this.androidRaw,
    this.iosFile,
    this.preview,
    this.isFajr = false,
    this.available = true,
  });
}

/// The adhan the app has always used (CC0, Wikimedia Commons). Its channel
/// id is the original one, so updating users keep their existing channel.
const defaultAdhan = AdhanSound(
  id: 'default',
  kind: AdhanSoundKind.adhan,
  channelId: 'prayer_times',
  channelName: 'Prayer Times',
  androidRaw: 'adhan',
  iosFile: 'adhan.caf',
  preview: 'assets/audio/preview_adhan_default.m4a',
);

/// Quieter, shorter alert for Fajr: the opening takbir of [defaultAdhan],
/// 10 dB quieter (tool/make_gentle_adhan.py).
const gentleAdhan = AdhanSound(
  id: 'gentle',
  kind: AdhanSoundKind.adhan,
  channelId: 'prayer_times_gentle',
  channelName: 'Prayer Times - Gentle',
  androidRaw: 'adhan_gentle',
  iosFile: 'adhan_gentle.caf',
  preview: 'assets/audio/preview_adhan_gentle.m4a',
);

/// The device's default notification sound.
const beepSound = AdhanSound(
  id: 'beep',
  kind: AdhanSoundKind.beep,
  channelId: 'prayer_times_beep',
  channelName: 'Prayer Times - Short beep',
);

/// Notification only, no sound.
const silentSound = AdhanSound(
  id: 'silent',
  kind: AdhanSoundKind.silent,
  channelId: 'prayer_times_silent',
  channelName: 'Prayer Times - Silent',
);

const _makkah = AdhanSound(
  id: 'makkah',
  kind: AdhanSoundKind.adhan,
  channelId: 'prayer_times_makkah',
  channelName: 'Prayer Times - Makkah Adhan',
  androidRaw: 'adhan_makkah',
  iosFile: 'adhan_makkah.caf',
  preview: 'assets/audio/preview_adhan_makkah.m4a',
  available: false,
);

const _madinah = AdhanSound(
  id: 'madinah',
  kind: AdhanSoundKind.adhan,
  channelId: 'prayer_times_madinah',
  channelName: 'Prayer Times - Madinah Adhan',
  androidRaw: 'adhan_madinah',
  iosFile: 'adhan_madinah.caf',
  preview: 'assets/audio/preview_adhan_madinah.m4a',
  available: false,
);

const _alafasy = AdhanSound(
  id: 'alafasy',
  kind: AdhanSoundKind.adhan,
  channelId: 'prayer_times_alafasy',
  channelName: 'Prayer Times - Mishary Alafasy Adhan',
  androidRaw: 'adhan_alafasy',
  iosFile: 'adhan_alafasy.caf',
  preview: 'assets/audio/preview_adhan_alafasy.m4a',
  available: false,
);

const _makkahFajr = AdhanSound(
  id: 'makkah_fajr',
  kind: AdhanSoundKind.adhan,
  channelId: 'prayer_times_makkah_fajr',
  channelName: 'Prayer Times - Makkah Fajr Adhan',
  androidRaw: 'adhan_makkah_fajr',
  iosFile: 'adhan_makkah_fajr.caf',
  preview: 'assets/audio/preview_adhan_makkah_fajr.m4a',
  isFajr: true,
  available: false,
);

const _madinahFajr = AdhanSound(
  id: 'madinah_fajr',
  kind: AdhanSoundKind.adhan,
  channelId: 'prayer_times_madinah_fajr',
  channelName: 'Prayer Times - Madinah Fajr Adhan',
  androidRaw: 'adhan_madinah_fajr',
  iosFile: 'adhan_madinah_fajr.caf',
  preview: 'assets/audio/preview_adhan_madinah_fajr.m4a',
  isFajr: true,
  available: false,
);

const _alafasyFajr = AdhanSound(
  id: 'alafasy_fajr',
  kind: AdhanSoundKind.adhan,
  channelId: 'prayer_times_alafasy_fajr',
  channelName: 'Prayer Times - Mishary Alafasy Fajr Adhan',
  androidRaw: 'adhan_alafasy_fajr',
  iosFile: 'adhan_alafasy_fajr.caf',
  preview: 'assets/audio/preview_adhan_alafasy_fajr.m4a',
  isFajr: true,
  available: false,
);

/// Choices for Dhuhr, Asr, Maghrib and Isha.
const List<AdhanSound> prayerSounds = [defaultAdhan, _makkah, _madinah, _alafasy, beepSound, silentSound];

/// Choices for Fajr: the Fajr recordings, the gentle alert, and the rest.
const List<AdhanSound> fajrSounds = [
  _makkahFajr,
  _madinahFajr,
  _alafasyFajr,
  gentleAdhan,
  defaultAdhan,
  beepSound,
  silentSound,
];

/// Every distinct sound (one Android channel each).
final List<AdhanSound> allAdhanSounds = {...prayerSounds, ...fajrSounds}.toList();

AdhanSound? adhanSoundById(String? id) {
  for (final s in allAdhanSounds) {
    if (s.id == id) return s;
  }
  return null;
}
