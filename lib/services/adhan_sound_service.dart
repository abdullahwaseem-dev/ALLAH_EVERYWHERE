import 'package:allah_everywhere/data/adhan_sounds.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';

/// What a prayer's notification does.
enum PrayerAlert { adhan, beep, silent, off }

/// The prayers, by the English keys used in prayer scheduling.
const List<String> alertPrayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

/// The user's prayer-notification sound choices.
class AdhanSoundService {
  static const _soundKey = 'adhan_sound';
  static const _fajrSoundKey = 'adhan_sound_fajr';
  static const _alertKeyPrefix = 'prayer_alert_';

  /// Sound for Dhuhr, Asr, Maghrib and Isha.
  static AdhanSound get sound => _read(_soundKey, prayerSounds);

  /// Sound for Fajr.
  static AdhanSound get fajrSound => _read(_fajrSoundKey, fajrSounds);

  static PrayerAlert alertFor(String prayer) {
    final stored = VoidStorage().readData<String>('$_alertKeyPrefix$prayer');
    return PrayerAlert.values.where((a) => a.name == stored).firstOrNull ?? PrayerAlert.adhan;
  }

  static Future<void> setSound(AdhanSound sound) => VoidStorage().saveData(_soundKey, sound.id);
  static Future<void> setFajrSound(AdhanSound sound) => VoidStorage().saveData(_fajrSoundKey, sound.id);
  static Future<void> setAlert(String prayer, PrayerAlert alert) =>
      VoidStorage().saveData('$_alertKeyPrefix$prayer', alert.name);

  /// A stored choice that's unknown, not offered for that slot, or whose
  /// files aren't in the app yet falls back to the default adhan.
  static AdhanSound _read(String key, List<AdhanSound> options) =>
      resolveChoice(VoidStorage().readData<String>(key), options);

  static AdhanSound resolveChoice(String? id, List<AdhanSound> options) {
    final match = options.where((s) => s.id == id).firstOrNull;
    return match != null && match.available ? match : defaultAdhan;
  }

  /// What [prayer]'s notification uses, or null when its alert is off.
  static AdhanSound? soundForPrayer(String prayer) => resolve(
        prayer: prayer,
        alert: alertFor(prayer),
        sound: sound,
        fajrSound: fajrSound,
      );

  /// Pure form of [soundForPrayer].
  static AdhanSound? resolve({
    required String prayer,
    required PrayerAlert alert,
    required AdhanSound sound,
    required AdhanSound fajrSound,
  }) {
    switch (alert) {
      case PrayerAlert.off:
        return null;
      case PrayerAlert.beep:
        return beepSound;
      case PrayerAlert.silent:
        return silentSound;
      case PrayerAlert.adhan:
        return prayer == 'Fajr' ? fajrSound : sound;
    }
  }
}
