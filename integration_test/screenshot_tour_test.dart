// Visits the main screens on a real simulator and pauses on each, printing
// "SHOT_READY <name>" so a host script can grab `xcrun simctl io <id>
// screenshot`. Used to eyeball layouts per device (safe areas, notch,
// home indicator, iPad width) - layout_overflow_test.dart is the
// automated pass/fail check.
//
//   flutter test integration_test/screenshot_tour_test.dart \
//     -d <simulator-id> --dart-define-from-file=dart_defines.json

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';

import 'package:allah_everywhere/main.dart';
import 'package:allah_everywhere/Hadith_detail.dart';
import 'package:allah_everywhere/ask_ai.dart';
import 'package:allah_everywhere/controllers/language_controller.dart';
import 'package:allah_everywhere/controllers/theme_controller.dart';
import 'package:allah_everywhere/dua.dart';
import 'package:allah_everywhere/login.dart';
import 'package:allah_everywhere/quran.dart';
import 'package:allah_everywhere/settings.dart';
import 'package:allah_everywhere/surah.dart';
import 'package:allah_everywhere/tasbeeh.dart';
import 'package:allah_everywhere/widgets/bottom_navbar.dart';

final _screens = <String, Widget Function()>{
  'quran': () => QuranScreen(),
  'surah': () => SurahScreen(surahName: 'Al-Mulk', surahId: 67),
  'hadith': () => const HadithDetail(bookSlug: 'sahih-bukhari', chapterNumber: 1),
  'dua': () => DuaScreen(),
  'askai': () => const AskAiScreen(),
  'settings': () => SettingsScreen(),
  'tasbeeh': () => TasbeehScreen(),
  'login': () => const Login(),
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot tour', (tester) async {
    await bootstrap(reportErrorsToCrashlytics: false);
    final language = Get.find<LanguageController>();
    final theme = Get.find<ThemeController>();
    final originalLanguage = language.locale.value.languageCode;
    final originalDark = theme.isDarkMode;

    Future<void> wait(int ms) async {
      for (var t = 0; t < ms; t += 250) {
        await tester.pump(const Duration(milliseconds: 250));
      }
    }

    Future<void> shot(String name) async {
      debugPrint('SHOT_READY $name');
      await wait(2500); // host takes the screenshot meanwhile
    }

    try {
      await tester.pumpWidget(const MyApp());
      await wait(6000);
      for (final mode in [('en', false), ('ur', true)]) {
        await language.setLanguage(mode.$1);
        await theme.setDarkMode(mode.$2);
        Get.offAll(() => BottomNavBarApp(), transition: Transition.noTransition);
        await wait(4000);
        await shot('${mode.$1}_home');
        for (final screen in _screens.entries) {
          Get.to(screen.value, transition: Transition.noTransition, preventDuplicates: false);
          await wait(3500);
          await shot('${mode.$1}_${screen.key}');
          Get.back();
          await wait(500);
        }
      }
    } finally {
      await language.setLanguage(originalLanguage);
      await theme.setDarkMode(originalDark);
    }
  });
}
