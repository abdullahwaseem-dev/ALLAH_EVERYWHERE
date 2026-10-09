import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/utils/utils/theme/theme.dart';
import 'package:allah_everywhere/adhan_sound_settings.dart';
import 'package:allah_everywhere/data/adhan_sounds.dart';
import 'package:allah_everywhere/services/adhan_sound_service.dart';

/// Renders Settings > Adhan Sound in LTR and RTL languages, light and dark,
/// at the largest supported text size; picks the gentle Fajr sound and turns
/// one prayer off, and checks both are saved. Fails on any overflow or
/// exception.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDir;

  setUpAll(() async {
    storageDir = await Directory.systemTemp.createTemp('adhan_sound_screen_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => storageDir.path,
    );
    await GetStorage.init();
  });

  setUp(() => GetStorage().erase());

  tearDownAll(() => storageDir.delete(recursive: true));

  for (final locale in const [Locale('en'), Locale('ar'), Locale('ur')]) {
    for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('renders in ${locale.languageCode} / ${mode.name}', (tester) async {
        tester.view.physicalSize = const Size(360, 690) * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          builder: (context, _) => MaterialApp(
            theme: VoidAppTheme.lightTheme,
            darkTheme: VoidAppTheme.darkTheme,
            themeMode: mode,
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: const AdhanSoundSettingsScreen(),
          ),
        ));
        await tester.pumpAndSettle();
        final t = await AppLocalizations.delegate.load(locale);
        expect(find.text(t.adhanSound), findsOneWidget);
        // Placeholders are listed but marked as not added yet.
        expect(find.text(t.soundNotAdded), findsWidgets);

        await tester.dragUntilVisible(find.text(t.soundGentle), find.byType(ListView), const Offset(0, -120));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.soundGentle));
        await tester.pumpAndSettle();
        expect(AdhanSoundService.fajrSound, gentleAdhan);

        // Tapping a placeholder does nothing.
        await tester.dragUntilVisible(find.text(t.soundMakkahFajr), find.byType(ListView), const Offset(0, -120));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.soundMakkahFajr));
        await tester.pumpAndSettle();
        expect(AdhanSoundService.fajrSound, gentleAdhan);

        // The per-prayer card is last; Isha is its last row.
        await tester.dragUntilVisible(find.text(t.isha), find.byType(ListView), const Offset(0, -200));
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();
        final off = find.text(t.alertOff);
        await tester.tap(off.last);
        await tester.pumpAndSettle();
        expect(AdhanSoundService.alertFor('Isha'), PrayerAlert.off);
        expect(AdhanSoundService.soundForPrayer('Isha'), isNull);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
