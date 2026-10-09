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
import 'package:allah_everywhere/models/bookmark.dart';
import 'package:allah_everywhere/mushaf.dart';
import 'package:allah_everywhere/services/bookmark_service.dart';
import 'package:allah_everywhere/services/mushaf_service.dart';

/// Renders the Mushaf in LTR and RTL languages, light and dark, at the
/// largest supported text size: page 1, a swipe to page 2, jumping to Juz 30,
/// long-pressing an ayah, bookmarking the page and the reading settings.
/// Fails on any overflow or exception.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDir;

  setUpAll(() async {
    storageDir = await Directory.systemTemp.createTemp('mushaf_screen_test');
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
            home: const MushafScreen(initialPage: 1),
          ),
        ));
        await tester.pumpAndSettle();
        final t = await AppLocalizations.delegate.load(locale);
        expect(find.text(quran.getSurahName(1)), findsOneWidget);
        expect(find.text(t.mushafJuzN('1')), findsOneWidget);
        expect(MushafService.lastPage, 1);

        // Next page is to the left: swipe left-to-right.
        await tester.drag(find.byType(PageView), Offset(tester.getSize(find.byType(PageView)).width * 0.6, 0));
        await tester.pumpAndSettle();
        expect(MushafService.lastPage, 2);
        expect(find.text(quran.getSurahName(2)), findsOneWidget);

        // Jump to Juz 30.
        await tester.tap(find.byTooltip(t.mushafGoTo));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.mushafJumpJuz));
        await tester.pumpAndSettle();
        await tester.tap(find.text('30'));
        await tester.pumpAndSettle();
        expect(MushafService.lastPage, MushafService.pageForSurah(78));

        // Long-press the start of the first ayah (RTL: top right of its text):
        // the ayah sheet opens with its actions.
        final ayahText = find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().contains(quran.getVerse(78, 1)));
        expect(ayahText, findsOneWidget);
        await tester.longPressAt(tester.getTopRight(ayahText) + const Offset(-12, 12));
        await tester.pumpAndSettle();
        expect(find.text(t.mushafPlayFromAyah), findsOneWidget);
        expect(find.text(t.mushafAyahTitle(quran.getSurahName(78), '1')), findsOneWidget);
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // The end of the block (RTL: bottom left) is the block's last ayah.
        final seg = MushafService.segments(MushafService.pageForSurah(78)).firstWhere((x) => x.surah == 78);
        // Scroll the page to its end so the block's last line is on screen.
        await tester.dragFrom(tester.getCenter(find.byType(PageView)), const Offset(0, -3000));
        await tester.pumpAndSettle();
        final bottomLeft = tester.getBottomLeft(ayahText) + const Offset(12, -12);
        expect(bottomLeft.dy, lessThan(tester.view.physicalSize.height / tester.view.devicePixelRatio));
        await tester.longPressAt(bottomLeft);
        await tester.pumpAndSettle();
        expect(find.text(t.mushafAyahTitle(quran.getSurahName(78), '${seg.end}')), findsOneWidget);
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();

        // ignore: avoid_print
        print('MUSHAF_FIT ${locale.languageCode} block=${tester.getSize(ayahText).height.round()} '
            'screen=${(tester.view.physicalSize.height / tester.view.devicePixelRatio).round()}');

        // Bookmark the page.
        await tester.tap(find.byTooltip(t.mushafBookmarkPage));
        await tester.pumpAndSettle();
        final page = '${MushafService.pageForSurah(78)}';
        expect(await BookmarkService().isBookmarked(BookmarkType.mushafPage, page), isTrue);

        // Reading settings: sepia, larger text.
        await tester.tap(find.byTooltip(t.mushafSettings));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.mushafBgSepia));
        await tester.pumpAndSettle();
        expect(MushafService.background, MushafBackground.sepia);
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
