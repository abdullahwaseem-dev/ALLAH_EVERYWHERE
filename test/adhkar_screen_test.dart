import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/utils/utils/theme/theme.dart';
import 'package:allah_everywhere/adhkar.dart';
import 'package:allah_everywhere/data/adhkar_data.dart';

/// Renders the adhkar screen in LTR and RTL languages, light and dark, at the
/// largest supported text size; counts through the first two adhkar and
/// checks it auto-advances, then opens the evening tab. Fails on any
/// overflow or exception.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDir;

  setUpAll(() async {
    storageDir = await Directory.systemTemp.createTemp('adhkar_screen_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => storageDir.path,
    );
    await GetStorage.init();
  });

  // Saved progress would otherwise carry over between the cases.
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
            home: const AdhkarScreen(initialTime: AdhkarTime.morning),
          ),
        ));
        await tester.pumpAndSettle();
        final t = await AppLocalizations.delegate.load(locale);
        final total = '${morningAdhkar.length}';
        expect(find.text(t.adhkarTitle), findsOneWidget);
        expect(find.text(t.adhkarProgress('1', total)), findsOneWidget);

        // Ayat al-Kursi: once, then it moves on by itself.
        final counter = find.text(t.adhkarTapToCount);
        await tester.tap(counter);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
        expect(find.text(t.adhkarProgress('2', total)), findsOneWidget);

        // The three Quls: 3, 2, 1, done.
        expect(find.text('3'), findsOneWidget);
        for (final left in ['2', '1']) {
          await tester.tap(find.text('/ 3'));
          await tester.pump();
          expect(find.text(left), findsOneWidget);
        }
        await tester.tap(find.text('/ 3'));
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
        expect(find.text(t.adhkarProgress('3', total)), findsOneWidget);

        // Evening tab has its own set and progress.
        await tester.tap(find.text(t.adhkarEvening));
        await tester.pumpAndSettle();
        expect(find.text(t.adhkarProgress('1', '${eveningAdhkar.length}')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
