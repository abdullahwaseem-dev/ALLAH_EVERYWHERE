import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/controllers/prayer_times_controller.dart';
import 'package:allah_everywhere/services/local_notifications_service.dart';
import 'package:allah_everywhere/services/push_notification_service.dart';
import 'package:allah_everywhere/services/home_widget_service.dart';

/// The 8 languages the app ships with. `nativeName` is what's shown in the
/// picker (so a user who can't read English can still recognize their own
/// language), `isRtl` drives text direction (handled automatically by
/// `MaterialApp.supportedLocales`/`locale`, listed here just for the picker).
class AppLanguage {
  final String code;
  final String englishName;
  final String nativeName;

  const AppLanguage({required this.code, required this.englishName, required this.nativeName});
}

const List<AppLanguage> supportedAppLanguages = [
  AppLanguage(code: 'en', englishName: 'English', nativeName: 'English'),
  AppLanguage(code: 'ar', englishName: 'Arabic', nativeName: 'العربية'),
  AppLanguage(code: 'ur', englishName: 'Urdu', nativeName: 'اردو'),
  AppLanguage(code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी'),
  AppLanguage(code: 'zh', englishName: 'Chinese', nativeName: '中文'),
  AppLanguage(code: 'fr', englishName: 'French', nativeName: 'Français'),
  AppLanguage(code: 'tr', englishName: 'Turkish', nativeName: 'Türkçe'),
  AppLanguage(code: 'de', englishName: 'German', nativeName: 'Deutsch'),
];

class LanguageController extends GetxController {
  static const _key = 'app_language_code';

  final Rx<Locale> locale = const Locale('en').obs;

  @override
  void onInit() {
    super.onInit();
    final stored = VoidStorage().readData<String>(_key);
    if (stored != null && supportedAppLanguages.any((l) => l.code == stored)) {
      locale.value = Locale(stored);
    }
  }

  Future<void> setLanguage(String code) async {
    final newLocale = Locale(code);
    locale.value = newLocale;
    // GetMaterialApp resolves Localizations from Get.locale, not just the
    // `locale:` constructor param - without this call the app keeps
    // rendering in the old language until it's fully restarted.
    Get.updateLocale(newLocale);
    await VoidStorage().saveData(_key, code);

    // Re-issue the scheduled notifications so their text switches to the new
    // language immediately, rather than only after the next prayer-time
    // recompute (e.g. a location refresh or app restart).
    try {
      if (Get.isRegistered<PrayerTimesController>()) {
        await Get.find<PrayerTimesController>().rescheduleNotifications();
      }
      await LocalNotificationsService().scheduleDailyQuranReminder();
      await HomeWidgetService.sync();
      await LocalNotificationsService().scheduleJumuahReminders();
      await LocalNotificationsService().scheduleIslamicCalendarReminders();
      await LocalNotificationsService().scheduleChallengeReminders();
      // Challenge pushes are written by the server in this language.
      await PushNotificationService().syncProfile();
    } catch (_) {
      // Rescheduling is best-effort; a failure here must not block the
      // language change itself.
    }
  }
}
