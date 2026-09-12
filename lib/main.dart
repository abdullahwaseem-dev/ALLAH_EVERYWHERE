import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'splash_screen.dart';
import 'package:flutter/services.dart';
import 'firebase_options.dart';
import 'controllers/theme_controller.dart';
import 'controllers/language_controller.dart';
import 'services/local_notifications_service.dart';
import 'services/quran_audio_service.dart';
import 'utils/utils/theme/theme.dart';
import 'l10n/generated/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Route uncaught errors to Crashlytics instead of only the console, so
  // crashes are visible after release instead of silently disappearing.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  Get.put(ThemeController());
  Get.put(LanguageController());
  await LocalNotificationsService().init();
  await QuranAudioService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    final themeController = Get.find<ThemeController>();
    final languageController = Get.find<LanguageController>();

    return ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, child) {
        return Obx(() => GetMaterialApp(
              title: 'Allah Everywhere',
              debugShowCheckedModeBanner: false,
              theme: VoidAppTheme.lightTheme,
              darkTheme: VoidAppTheme.darkTheme,
              themeMode: themeController.themeMode.value,
              locale: languageController.locale.value,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: const SplashScreen(),
            ));
      },
    );
  }
}
