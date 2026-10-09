import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/utils/utils/theme/theme.dart';
import 'package:quran/quran.dart' as quran;
import 'package:allah_everywhere/hifz_dashboard.dart';
import 'package:allah_everywhere/hifz_practice.dart';
import 'package:allah_everywhere/services/hifz_service.dart';
import 'package:allah_everywhere/services/quran_audio_handler.dart';
import 'package:allah_everywhere/services/quran_audio_service.dart';

/// Renders Hifz practice (Al-Mulk 1-5) and the dashboard in LTR and RTL
/// languages, light and dark, at the largest supported text size: hides
/// words, reveals one, marks an ayah, and checks the dashboard counts it.
/// Audio isn't played. Fails on any overflow or exception.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDir;

  setUpAll(() async {
    storageDir = await Directory.systemTemp.createTemp('hifz_screen_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => storageDir.path,
    );
    await GetStorage.init();
    QuranAudioService.handlerForTesting = QuranAudioHandler();
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
            home: HifzPracticeScreen(surahId: 67, from: 1, to: 5),
          ),
        ));
        await tester.pumpAndSettle();
        final t = await AppLocalizations.delegate.load(locale);
        expect(find.text(t.hifzMode), findsOneWidget);

        // Test yourself: hide everything, then reveal one word by tapping it.
        final hideAll = find.text(t.hideAll);
        await tester.dragUntilVisible(hideAll, find.byType(ListView), const Offset(0, -200));
        await tester.pumpAndSettle();
        await tester.tap(hideAll);
        await tester.pumpAndSettle();
        expect(find.text(t.hifzTapToReveal), findsOneWidget);
        final hidden = find.byWidgetPredicate((w) => w is Text && w.style?.color == Colors.transparent);
        // Ayah 1's end marker is unique on the page.
        await tester.dragUntilVisible(find.text(quran.getVerseEndSymbol(1)), find.byType(ListView), const Offset(0, -150));
        await tester.drag(find.byType(ListView), const Offset(0, -150));
        await tester.pumpAndSettle();
        final before = hidden.evaluate().length;
        await tester.tap(hidden.hitTestable().first);
        await tester.pumpAndSettle();
        expect(hidden.evaluate().length, before - 1);

        // Mark an ayah as remembered.
        final remembered = find.text(t.hifzRemembered);
        await tester.tap(remembered.hitTestable().first);
        await tester.pumpAndSettle();
        // Whichever ayah's button was on screen first.
        final marked = HifzService().load()[67]?.values.where((r) => r.status == HifzStatus.remembered) ?? [];
        expect(marked.length, 1);

        // The dashboard counts it.
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
            home: const HifzDashboardScreen(),
          ),
        ));
        await tester.pumpAndSettle();
        expect(find.text(t.hifzMemorizedTotal('1')), findsOneWidget);
        expect(find.text(t.hifzReviewEmpty), findsOneWidget); // due tomorrow, not today
        await tester.dragUntilVisible(find.text(quran.getSurahName(114)), find.byType(CustomScrollView), const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
