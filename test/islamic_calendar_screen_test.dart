import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/utils/utils/theme/theme.dart';
import 'package:allah_everywhere/islamic_calendar.dart';

/// Renders the Islamic calendar in LTR and RTL languages, light and dark,
/// at the largest supported text size: opens on a known date, shows an
/// event sheet, swipes months and returns to today. Fails on any overflow
/// or exception.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDir;

  setUpAll(() async {
    storageDir = await Directory.systemTemp.createTemp('calendar_screen_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => storageDir.path,
    );
    await GetStorage.init();
  });

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
            home: IslamicCalendarScreen(initialDate: DateTime(2026, 6, 25)),
          ),
        ));
        await tester.pumpAndSettle();
        final t = await AppLocalizations.delegate.load(locale);
        expect(find.text(t.calendarTitle), findsOneWidget);
        expect(find.text('${t.hijriMonthName('1')} ${t.hijriYear('1448')}'), findsOneWidget);

        // The selected day (Ashura) lists its events; open one.
        final ashura = find.text(t.calEventAshura);
        // "This month" sits just below the selected day's card.
        await tester.dragUntilVisible(find.text(t.calendarThisMonth), find.byType(ListView), const Offset(0, -150));
        await tester.pumpAndSettle();
        expect(ashura, findsWidgets);
        await tester.pumpAndSettle();
        await tester.tap(ashura.hitTestable().first);
        await tester.pumpAndSettle();
        expect(find.text(t.calEventAshuraDesc), findsOneWidget);
        expect(find.textContaining('Sahih Muslim 1162'), findsOneWidget);
        Navigator.of(tester.element(find.text(t.calEventAshuraDesc))).pop();
        await tester.pumpAndSettle();

        // Swipe forward twice and back once (directions mirror in RTL),
        // then jump to today.
        await tester.drag(find.byType(ListView), const Offset(0, 2000));
        await tester.pumpAndSettle();
        final rtl = locale.languageCode != 'en';
        final pageWidth = tester.getSize(find.byType(PageView)).width;
        String monthTitle(int m) => '${t.hijriMonthName('$m')} ${t.hijriYear('1448')}';
        for (final (forward, expectMonth) in [(true, 2), (true, 3), (false, 2)]) {
          final dx = (forward != rtl ? -1 : 1) * pageWidth * 0.6;
          await tester.drag(find.byType(PageView), Offset(dx, 0));
          await tester.pumpAndSettle();
          expect(find.text(monthTitle(expectMonth)), findsOneWidget);
        }
        await tester.tap(find.text(t.calendarToday));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
