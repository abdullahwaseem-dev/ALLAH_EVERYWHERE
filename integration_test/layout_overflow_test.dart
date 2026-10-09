// Opens every screen of the app at several device sizes, in English and
// Urdu (RTL), with large text, and fails on any layout overflow (the
// yellow/black stripes). Each problem is printed with the screen, device,
// language and the source line of the widget that overflowed.
//
// Run on a booted iOS simulator (plugins like Firebase need a real device):
//   flutter test integration_test/layout_overflow_test.dart \
//     -d <simulator-id> --dart-define-from-file=dart_defines.json
//
// Device sizes are emulated through tester.view, so one simulator covers
// iPhone SE, iPhone 16, iPhone 16 Pro Max and iPad.

import 'package:flutter/material.dart';
import 'package:flutter_islamic_icons/flutter_islamic_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:integration_test/integration_test.dart';

import 'package:allah_everywhere/main.dart';
import 'package:allah_everywhere/About_us.dart';
import 'package:allah_everywhere/Hadith_detail.dart';
import 'package:allah_everywhere/ask_ai.dart';
import 'package:allah_everywhere/bookmarks_screen.dart';
import 'package:allah_everywhere/change_password_screen.dart';
import 'package:allah_everywhere/controllers/language_controller.dart';
import 'package:allah_everywhere/controllers/theme_controller.dart';
import 'package:allah_everywhere/data/dua_data.dart';
import 'package:allah_everywhere/dua.dart';
import 'package:allah_everywhere/dua_2.dart';
import 'package:allah_everywhere/duadetail.dart';
import 'package:allah_everywhere/editprofilescreen.dart';
import 'package:allah_everywhere/fiqh.dart';
import 'package:allah_everywhere/forget_password.dart';
import 'package:allah_everywhere/forget_password_success.dart';
import 'package:allah_everywhere/hadith.dart';
import 'package:allah_everywhere/hadith_chapters.dart';
import 'package:allah_everywhere/help_faq.dart';
import 'package:allah_everywhere/login.dart';
import 'package:allah_everywhere/notification.dart';
import 'package:allah_everywhere/onboarding.dart';
import 'package:allah_everywhere/prayer_timing.dart';
import 'package:allah_everywhere/privacy_policy.dart';
import 'package:allah_everywhere/qibla.dart';
import 'package:allah_everywhere/quran.dart';
import 'package:allah_everywhere/registration.dart';
import 'package:allah_everywhere/registration_success.dart';
import 'package:allah_everywhere/seerat.dart';
import 'package:allah_everywhere/share_cards/share_studio_screen.dart';
import 'package:allah_everywhere/surah.dart';
import 'package:allah_everywhere/widgets/bottom_navbar.dart';
import 'package:allah_everywhere/widgets/search_screen.dart';

class _Device {
  final String name;
  final Size size; // logical points
  final double pixelRatio;
  final double top; // status bar / notch / Dynamic Island
  final double bottom; // home indicator

  const _Device(this.name, this.size, this.pixelRatio, this.top, this.bottom);
}

const _devices = [
  _Device('iPhone SE', Size(375, 667), 2, 20, 0),
  _Device('iPhone 16', Size(393, 852), 3, 59, 34),
  _Device('iPhone 16 Pro Max', Size(440, 956), 3, 62, 34),
  _Device('iPad 11"', Size(834, 1210), 2, 24, 20),
  _Device('iPad 11" landscape', Size(1210, 834), 2, 24, 20),
];

// Tab screens, reached by tapping the nav bar (so they get its padding).
final _tabs = <String, IconData>{
  'Tib-e-Nabwi tab': FlutterIslamicIcons.mohammad,
  'Tasbeeh tab': FlutterIslamicIcons.tasbih,
  'Settings tab': Iconsax.settings,
  'Profile tab': Iconsax.profile_circle,
  'Home tab': Iconsax.home_2,
};

final _screens = <String, Widget Function()>{
  'Quran': () => QuranScreen(),
  'Surah (Al-Mulk)': () => SurahScreen(surahName: 'Al-Mulk', surahId: 67),
  'Surah (Al-Baqarah)': () => SurahScreen(surahName: 'Al-Baqarah', surahId: 2, initialAyah: 255),
  'Hadith books': () => HadithScreen(),
  'Hadith chapters': () => const HidthChaptersScreen(bookSlug: 'sahih-bukhari', bookNameInArabic: 'Sahih Bukhari'),
  'Hadith detail': () => const HadithDetail(bookSlug: 'sahih-bukhari', chapterNumber: 1),
  'Dua': () => DuaScreen(),
  'Dua list': () => Dua2Screen(category: duaCategories.first),
  'Dua detail': () => DuaDetailScreen(
        dua: duaCategories.first.duas.first,
        index: 1,
        total: duaCategories.first.duas.length,
        categoryTitle: duaCategories.first.title,
      ),
  'Fiqh': () => FiqhScreen(),
  'Seerah': () => SeeratScreen(),
  'Qibla': () => QiblaScreen(),
  'Prayer times': () => const PrayerTimingScreen(),
  'Ask AI': () => const AskAiScreen(),
  'Search': () => const SearchScreen(),
  'Notifications': () => NotificationsScreen(),
  'Bookmarks': () => const BookmarksScreen(),
  'Share studio': () => const ShareStudioScreen(),
  'Help & FAQ': () => HelpFaqScreen(),
  'About us': () => AboutUsScreen(),
  'Privacy policy': () => PrivacyPolicyScreen(),
  'Edit profile': () => EditProfileScreen(),
  'Change password': () => ChangePasswordScreen(),
  'Onboarding': () => const OnboardingScreen(),
  'Login': () => const Login(),
  'Registration': () => const RegisterScreen(),
  'Forgot password': () => const ForgetPassword(),
  'Forgot password sent': () => const ForgetPasswordSuccess(),
  'Registration done': () => const RegistrationSuccess(),
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('no layout overflow on any screen, device, language', (tester) async {
    await bootstrap(reportErrorsToCrashlytics: false);

    final overflows = <String>{};
    final swipeBackFailures = <String>[];
    final otherErrors = <String>{};
    var where = 'startup';
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final text = details.toString();
      final message = details.exceptionAsString().split('\n').first;
      final location = RegExp(r'(lib/[\w/]+\.dart):(\d+)').firstMatch(text);
      final at = location == null ? '' : ' at ${location.group(1)}:${location.group(2)}';
      if (message.contains('overflowed')) {
        if (overflows.add('$where | $message$at')) debugPrint('LAYOUT_OVERFLOW | $where | $message$at');
      } else if (otherErrors.add('$where | $message$at')) {
        debugPrint('LAYOUT_OTHER_ERROR | $where | $message$at');
      }
    };

    final languageController = Get.find<LanguageController>();
    final themeController = Get.find<ThemeController>();
    final originalLanguage = languageController.locale.value.languageCode;
    final originalDark = themeController.isDarkMode;

    Future<void> settle([int steps = 8]) async {
      // Not pumpAndSettle: clocks, rotating prompts and the Tasbeeh pulse
      // never settle. Long enough for network content to arrive.
      for (var i = 0; i < steps; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
    }

    try {
      await tester.pumpWidget(const MyApp());
      // Let the splash screen finish its own navigation, then take over.
      await settle(20);
      Get.offAll(() => BottomNavBarApp(), transition: Transition.noTransition);
      await settle();

      // iOS swipe-back: an edge swipe must close every pushed screen.
      final iPhone16 = _devices[1];
      tester.view.devicePixelRatio = iPhone16.pixelRatio;
      tester.view.physicalSize = iPhone16.size * iPhone16.pixelRatio;
      final root = Get.currentRoute;
      for (final screen in _screens.entries) {
        where = 'swipe-back | ${screen.key}';
        Get.to(screen.value, preventDuplicates: false);
        await settle(4);
        await tester.timedDragFrom(
          Offset(4, iPhone16.size.height / 2),
          Offset(iPhone16.size.width * 0.7, 0),
          const Duration(milliseconds: 300),
        );
        await settle(4);
        if (Get.currentRoute != root) {
          swipeBackFailures.add(screen.key);
          debugPrint('SWIPE_BACK_FAILED | ${screen.key} | still on ${Get.currentRoute}');
          Get.until((route) => Get.currentRoute == root);
          await settle(2);
        }
      }

      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      for (final device in _devices) {
        tester.view.devicePixelRatio = device.pixelRatio;
        tester.view.physicalSize = device.size * device.pixelRatio;
        final insets = FakeViewPadding(top: device.top * device.pixelRatio, bottom: device.bottom * device.pixelRatio);
        tester.view.padding = insets;
        tester.view.viewPadding = insets;

        for (final language in ['en', 'ur']) {
          await languageController.setLanguage(language);
          await themeController.setDarkMode(language == 'ur');
          await settle(4);

          for (final tab in _tabs.entries) {
            where = '${device.name} | $language | ${tab.key}';
            final icon = find.byIcon(tab.value);
            if (icon.evaluate().isNotEmpty) {
              await tester.tap(icon.first, warnIfMissed: false);
              await settle(5);
            }
          }

          for (final screen in _screens.entries) {
            where = '${device.name} | $language | ${screen.key}';
            Get.to(screen.value, transition: Transition.noTransition, preventDuplicates: false);
            await settle();
            // Scroll to the end too: overflows often hide further down.
            final scrollable = find.byType(Scrollable);
            if (scrollable.evaluate().isNotEmpty) {
              await tester.drag(scrollable.first, const Offset(0, -3000), warnIfMissed: false);
              await settle(3);
            }
            Get.back();
            await settle(2);
          }
        }
      }
    } finally {
      tester.platformDispatcher.clearAllTestValues();
      tester.view.reset();
      await languageController.setLanguage(originalLanguage);
      await themeController.setDarkMode(originalDark);
      FlutterError.onError = originalOnError;
    }

    debugPrint('LAYOUT_SUMMARY overflows=${overflows.length} otherErrors=${otherErrors.length} '
        'swipeBackFailures=${swipeBackFailures.length}');
    expect(overflows, isEmpty, reason: overflows.join('\n'));
    expect(swipeBackFailures, isEmpty, reason: 'Swipe-back did not close: ${swipeBackFailures.join(', ')}');
  });
}
