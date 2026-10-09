import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/utils/utils/theme/theme.dart';
import 'package:allah_everywhere/asma_ul_husna.dart';
import 'package:allah_everywhere/data/asma_ul_husna_data.dart';

/// Renders the 99 Names grid in LTR and RTL languages, light and dark, at
/// the largest supported text size, and checks search; fails on any
/// overflow or exception.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDir;

  setUpAll(() async {
    storageDir = await Directory.systemTemp.createTemp('asma_screen_test');
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
            home: const AsmaUlHusnaScreen(),
          ),
        ));
        await tester.pumpAndSettle();
        final t = await AppLocalizations.delegate.load(locale);
        expect(find.text(t.asmaUlHusnaTitle), findsOneWidget);
        expect(find.text(asmaUlHusna.first.arabic), findsOneWidget);

        // Accent-insensitive search on the transliteration.
        await tester.enterText(find.byType(TextField), 'rahim');
        await tester.pumpAndSettle();
        expect(find.text('Ar-Raḥīm'), findsOneWidget);
        expect(find.text('Al-Malik'), findsNothing);

        await tester.enterText(find.byType(TextField), 'zzzz');
        await tester.pumpAndSettle();
        expect(find.text(t.asmaNoResults), findsOneWidget);

        // Scroll the full list so every card is laid out.
        await tester.enterText(find.byType(TextField), '');
        await tester.pumpAndSettle();
        await tester.dragUntilVisible(
          find.text(asmaUlHusna.last.transliteration),
          find.byType(CustomScrollView),
          const Offset(0, -400),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
