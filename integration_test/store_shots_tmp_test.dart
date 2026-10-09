// TEMPORARY - captures localized App Store creative-asset screens; deleted after use.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';

import 'package:allah_everywhere/main.dart';
import 'package:allah_everywhere/controllers/language_controller.dart';
import 'package:allah_everywhere/controllers/theme_controller.dart';
import 'package:allah_everywhere/hajj_umrah.dart';
import 'package:allah_everywhere/islamic_calendar.dart';
import 'package:allah_everywhere/mushaf.dart';
import 'package:allah_everywhere/prayer_timing.dart';
import 'package:allah_everywhere/widgets/bottom_navbar.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('store shots', (tester) async {
    await bootstrap(reportErrorsToCrashlytics: false);
    final language = Get.find<LanguageController>();
    final theme = Get.find<ThemeController>();

    Future<void> wait(int ms) async {
      for (var t = 0; t < ms; t += 250) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    Future<void> shot(String name) async {
      debugPrint('STORE_SHOT $name');
      await wait(3000);
    }

    Future<void> open(String name, Widget Function() screen) async {
      Get.to(screen, transition: Transition.noTransition, preventDuplicates: false);
      await wait(4500);
      await shot(name);
      Get.back();
      await wait(600);
    }

    await tester.pumpWidget(const MyApp());
    await wait(6000);
    for (final lang in ['en', 'ar', 'ur', 'fr', 'de', 'hi', 'tr', 'zh']) {
      await language.setLanguage(lang);
      // Light: Home, Mushaf, Hajj guide.
      await theme.setDarkMode(false);
      Get.offAll(() => BottomNavBarApp(), transition: Transition.noTransition);
      await wait(9000);
      await shot('${lang}_light_home');
      await open('${lang}_light_mushaf', () => const MushafScreen(initialPage: 1));
      await open('${lang}_light_hajj', () => const HajjUmrahScreen());
      // Dark: Prayer times, Calendar.
      await theme.setDarkMode(true);
      await wait(1500);
      await open('${lang}_dark_prayer', () => const PrayerTimingScreen());
      await open('${lang}_dark_calendar', () => const IslamicCalendarScreen());
    }
    await language.setLanguage('en');
    await theme.setDarkMode(false);
  });
}
