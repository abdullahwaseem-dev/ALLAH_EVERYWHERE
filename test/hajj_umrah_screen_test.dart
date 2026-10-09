import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/utils/utils/theme/theme.dart';
import 'package:allah_everywhere/hajj_umrah.dart';
import 'package:allah_everywhere/data/hajj_umrah_data.dart';
import 'package:allah_everywhere/services/hajj_service.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';

/// Renders the Hajj & Umrah guide in LTR and RTL languages, light and dark,
/// at a large text size: opens a step, ticks it, visits every tab, adds a
/// packing item, counts Tawaf rounds and resets the trip. Fails on any
/// overflow or exception.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDir;

  setUpAll(() async {
    storageDir = await Directory.systemTemp.createTemp('hajj_screen_test');
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
          builder: (context, _) => GetMaterialApp(
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
            home: const HajjUmrahScreen(),
          ),
        ));
        await tester.pumpAndSettle();
        final t = await AppLocalizations.delegate.load(locale);
        final lang = locale.languageCode;
        final service = HajjService();

        expect(find.text(t.hajjTitle), findsOneWidget);
        expect(find.text(t.hajjScholarNote), findsOneWidget);
        expect(find.text(t.hajjProgress(0, 4)), findsOneWidget);

        // Tick the first step.
        await tester.tap(find.byType(Checkbox).first);
        await tester.pumpAndSettle();
        expect(find.text(t.hajjProgress(1, 4)), findsOneWidget);
        expect(service.doneSteps(), {'umrahIhram'});

        // Open the Tawaf step: what to do, duas (incl. the Quran one), mistakes.
        Finder list(HajjGuide g) => find
            .descendant(of: find.byKey(PageStorageKey('hajj_guide_${g.name}')), matching: find.byType(Scrollable))
            .first;
        final tawaf = find.text(hajjText('umrahTawaf.title', lang));
        await tester.dragUntilVisible(tawaf, list(HajjGuide.umrah), const Offset(0, -150));
        await tester.pumpAndSettle();
        await tester.tap(tawaf);
        await tester.pumpAndSettle();
        await tester.dragUntilVisible(find.text(t.hajjMistakes), list(HajjGuide.umrah), const Offset(0, -200));
        await tester.pumpAndSettle();

        // Hajj tab with its day headers; open Arafah.
        await tester.ensureVisible(find.text(t.hajjTabHajj));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.hajjTabHajj));
        await tester.pumpAndSettle();
        expect(find.text(t.hajjDay8), findsOneWidget);
        final arafah = find.text(hajjText('arafah.title', lang));
        await tester.dragUntilVisible(arafah, list(HajjGuide.hajj), const Offset(0, -200));
        await tester.pumpAndSettle();
        await tester.tap(arafah);
        await tester.pumpAndSettle();

        // Packing: add an item of your own.
        await tester.ensureVisible(find.text(t.hajjTabPacking));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.hajjTabPacking));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Snacks');
        await tester.tap(find.byTooltip(t.hajjPackingAdd));
        await tester.pumpAndSettle();
        expect(service.packing().last.text, 'Snacks');

        // Places.
        await tester.ensureVisible(find.text(t.hajjTabPlaces));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.hajjTabPlaces));
        await tester.pumpAndSettle();
        expect(find.text(t.hajjOpenInMaps), findsWidgets);

        // Round counter: three taps, undo one.
        await tester.ensureVisible(find.text(t.hajjTabUmrah));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.hajjTabUmrah));
        await tester.pumpAndSettle();
        await tester.dragUntilVisible(find.text(t.hajjCounterOpen), list(HajjGuide.umrah), const Offset(0, 300));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.hajjCounterOpen));
        await tester.pumpAndSettle();
        for (var i = 0; i < 3; i++) {
          await tester.tap(find.text(t.hajjCounterTapHint));
          await tester.pump();
        }
        expect(find.text('3'), findsOneWidget);
        await tester.tap(find.text(t.hajjCounterUndo));
        await tester.pump();
        expect(service.counter(HajjCounter.tawaf), 2);
        await tester.tap(find.text(t.hajjCounterSai));
        await tester.pumpAndSettle();
        expect(find.text('0'), findsOneWidget);
        await tester.tap(find.byType(VoidBackButton));
        await tester.pumpAndSettle();

        // Reset for a new trip.
        await tester.tap(find.byTooltip(t.reset));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.reset).last);
        await tester.pumpAndSettle();
        expect(find.text(t.hajjProgress(0, 4)), findsOneWidget);
        expect(service.counter(HajjCounter.tawaf), 0);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
