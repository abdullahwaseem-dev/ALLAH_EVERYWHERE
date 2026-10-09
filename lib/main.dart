import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'splash_screen.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'controllers/theme_controller.dart';
import 'controllers/language_controller.dart';
import 'services/local_notifications_service.dart';
import 'services/quran_audio_service.dart';
import 'services/ai_fatwa_service.dart';
import 'services/tasbeeh_service.dart';
import 'services/home_widget_service.dart';
import 'utils/utils/theme/theme.dart';
import 'l10n/generated/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap();
  runApp(const MyApp());
}

/// Everything main() sets up before runApp. Shared with the integration
/// tests (integration_test/), which pass [reportErrorsToCrashlytics]: false
/// so deliberate test failures don't land in Crashlytics.
Future<void> bootstrap({bool reportErrorsToCrashlytics = true}) async {
  await lockPhoneToPortrait();
  await GetStorage.init();
  // Move the old single Tasbeeh counter into the gold bead before any screen
  // reads the new per-colour counters.
  await TasbeehCounterStore().migrateLegacy();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // On some Android devices the native FirebaseInitProvider races our
    // own initializeApp call and wins, so the [DEFAULT] app already
    // exists by the time we get here. That's harmless - fall through and
    // use the app it already created. Anything else is a real failure.
    if (!e.toString().contains('already exists')) rethrow;
  }

  // Route uncaught errors to Crashlytics instead of only the console, so
  // crashes are visible after release instead of silently disappearing.
  if (reportErrorsToCrashlytics) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  Get.put(ThemeController());
  Get.put(LanguageController());
  await LocalNotificationsService().init();
  await QuranAudioService.init();
  // Play Families policy: the app's audience includes children, so every ad
  // request gets child age treatment (no personalised ads) and is capped at
  // a "G" rating. Must be set before initialize() so the first request uses it.
  await MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
    maxAdContentRating: MaxAdContentRating.g,
    ageRestrictedTreatment: AgeRestrictedTreatment.child,
  ));
  unawaited(MobileAds.instance.initialize());
  AiFatwaService.instance = GeminiAiFatwaService();
  // Refreshes the home screen widgets (date, daily reminder, and prayer
  // times from the last known location) on every launch.
  unawaited(HomeWidgetService.sync());
}

/// Phones run portrait-only (the layouts are designed for it, and a
/// 375pt-tall landscape phone can't fit the reader's header + text);
/// tablets keep every orientation. Also enforced in Info.plist for iPhone.
Future<void> lockPhoneToPortrait() async {
  final views = PlatformDispatcher.instance.views;
  if (views.isEmpty) return;
  final view = views.first;
  final shortestSide = view.physicalSize.shortestSide / view.devicePixelRatio;
  if (shortestSide > 0 && shortestSide < 600) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
}

/// flutter_screenutil scales every .w/.h/.sp/.r by screen size / design
/// size. Uncapped, a Pro Max scaled height by ~1.39x and an iPad by ~3x,
/// blowing paddings and fonts up. Growing the design size on big screens
/// caps the scale at [maxScale] while small phones keep the original
/// 360x690 design (scale ~1).
Size cappedDesignSize(Size screen, {double maxScale = 1.3}) {
  const base = Size(360, 690);
  if (screen.isEmpty) return base;
  return Size(
    math.max(base.width, screen.width / maxScale),
    math.max(base.height, screen.height / maxScale),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    final themeController = Get.find<ThemeController>();
    final languageController = Get.find<LanguageController>();

    return ScreenUtilInit(
      designSize: cappedDesignSize(MediaQuery.maybeSizeOf(context) ?? Size.zero),
      // .sp uses the smaller of the width/height scales, so text never
      // outgrows the layout on tall-and-narrow or short-and-wide screens.
      minTextAdapt: true,
      builder: (context, child) {
        return Obx(() => GetMaterialApp(
              title: 'Allah Everywhere',
              debugShowCheckedModeBanner: false,
              theme: themeController.withAccent(VoidAppTheme.lightTheme),
              darkTheme: themeController.withAccent(VoidAppTheme.darkTheme),
              themeMode: themeController.themeMode.value,
              locale: languageController.locale.value,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) {
                final mediaQuery = MediaQuery.of(context);
                return MediaQuery(
                  // Honour the iOS/Android text size setting, but within a
                  // range every layout is tested at (up to 1.3x).
                  data: mediaQuery.copyWith(
                    textScaler: mediaQuery.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.3),
                  ),
                  // Tapping anywhere that isn't a control closes the
                  // keyboard (text fields and buttons win the tap first).
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                    child: child,
                  ),
                );
              },
              home: const SplashScreen(),
            ));
      },
    );
  }
}
