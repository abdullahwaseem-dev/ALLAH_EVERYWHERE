import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/models/bookmark.dart';
import 'package:allah_everywhere/prophet_stories.dart';
import 'package:allah_everywhere/services/bookmark_service.dart';
import 'package:allah_everywhere/services/prophet_stories_service.dart';
import 'package:allah_everywhere/utils/utils/theme/theme.dart';
import 'package:allah_everywhere/widgets/void_back_button.dart';

/// Renders the Prophets' Stories timeline and reader in LTR and RTL
/// languages, light and dark, at a large text size, starting from empty
/// storage: opens Adam's story, reads through a chapter, bookmarks it,
/// switches to Kids mode, and checks the position is remembered. Fails on
/// any overflow or exception.
/// Scrolls [list] by [step] until [finder] has a match (one or more), then
/// brings the first match into view.
Future<void> _scrollTo(WidgetTester tester, Finder finder, Finder list, {Offset step = const Offset(0, -300)}) async {
  for (var i = 0; i < 60 && finder.evaluate().isEmpty; i++) {
    await tester.drag(list, step);
    await tester.pump();
  }
  expect(finder, findsWidgets);
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}

/// Asset loading is real I/O, so it runs outside the fake clock: waits until
/// no loading spinner is left, then lets the screen settle.
Future<void> _waitForLoad(WidgetTester tester) async {
  for (var i = 0; i < 100; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDir;

  setUpAll(() async {
    storageDir = await Directory.systemTemp.createTemp('stories_screen_test');
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
            home: const ProphetStoriesScreen(),
          ),
        ));
        // Asset loading is real I/O, so let it finish outside the fake clock.
        await _waitForLoad(tester);
        final t = await AppLocalizations.delegate.load(locale);
        final service = ProphetStoriesService();
        final prophets = await tester.runAsync(service.loadIndex);
        final adam = prophets!.first;
        final story = (await tester.runAsync(() => service.loadStory(adam, locale.languageCode)))!;

        // Timeline: all 25 Prophets, down to Muhammad ﷺ at the bottom.
        expect(find.text(t.storiesTitle), findsOneWidget);
        expect(find.text(t.storiesChaptersRead(0, story.chapters.length)), findsWidgets);
        await _scrollTo(tester, find.text('محمد ﷺ'), find.byType(Scrollable).first, step: const Offset(0, -400));
        expect(find.text(t.storiesComingSoon), findsNothing);
        await _scrollTo(tester, find.text(t.storiesSubtitle), find.byType(Scrollable).first, step: const Offset(0, 600));
        await tester.pumpAndSettle();

        // Open Adam (AS).
        await tester.tap(find.text('${adam.arabicName} عليه السلام').first);
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
        await tester.pumpAndSettle();
        expect(find.text(t.storiesChapterOf(1, story.chapters.length)), findsOneWidget);
        // Every story is translated, so the reader shows it in the app
        // language with no "English only" notice.
        expect(story.language, locale.languageCode);
        expect(find.text(t.storiesEnglishOnly), findsNothing);
        await _scrollTo(tester, find.text(story.chapters.first.title), find.byType(Scrollable).last, step: const Offset(0, -200));
        await tester.pumpAndSettle();

        // Quran blocks come from the quran package, with an Open in Quran link.
        await _scrollTo(tester, find.text(t.storiesOpenInQuran), find.byType(Scrollable).last, step: const Offset(0, -300));
        await tester.pumpAndSettle();

        // Read to the end of the chapter, then go on to chapter 2.
        await _scrollTo(tester, find.text(t.storiesNextChapter), find.byType(Scrollable).last, step: const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(find.text(t.storiesLessons), findsOneWidget);
        await tester.tap(find.text(t.storiesNextChapter));
        await tester.pumpAndSettle();
        expect(find.text(t.storiesChapterOf(2, story.chapters.length)), findsOneWidget);
        expect(service.isChapterRead(story.chapters.first.id), isTrue);

        // Bookmark chapter 2.
        await tester.tap(find.byTooltip(t.bookmark));
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
        await tester.pumpAndSettle();
        expect(
          await tester.runAsync(() => BookmarkService().isBookmarked(BookmarkType.prophetStory, '${adam.id}|1')),
          isTrue,
        );

        // Kids mode and a bigger text size.
        await tester.tap(find.byTooltip(t.storiesTextSize));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.storiesKidsMode));
        await tester.pumpAndSettle();
        // Towards "bigger": right in LTR, left in RTL.
        final rtl = locale.languageCode == 'ar' || locale.languageCode == 'ur';
        await tester.drag(find.byType(Slider), Offset(rtl ? -400 : 400, 0));
        await tester.pumpAndSettle();
        await tester.tapAt(const Offset(180, 40));
        await tester.pumpAndSettle();
        expect(find.text(story.chapters[1].kidsParagraphs.first), findsOneWidget);
        expect(service.kidsMode, isTrue);
        expect(service.textScale, greaterThan(1));

        // Chapter list, jump to the last chapter: the Next Prophet button (Idris).
        await tester.tap(find.text(t.storiesChapterOf(2, story.chapters.length)));
        await tester.pumpAndSettle();
        await _scrollTo(tester, find.text(story.chapters.last.title), find.byType(Scrollable).last);
        await tester.tap(find.text(story.chapters.last.title));
        await tester.pumpAndSettle();
        await _scrollTo(tester, find.text(t.storiesNextProphet), find.byType(Scrollable).last, step: const Offset(0, -400));
        await tester.pumpAndSettle();

        // Back on the timeline: Continue reading points at the last chapter.
        await tester.tap(find.byType(VoidBackButton));
        await tester.pumpAndSettle();
        expect(service.lastPosition()?.prophetId, adam.id);
        expect(service.lastPosition()?.chapter, story.chapters.length - 1);
        expect(find.text(t.storiesContinue), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  // Home's Story of the day card, on a narrow phone at a large text size.
  for (final locale in const [Locale('en'), Locale('ar'), Locale('ur'), Locale('zh'), Locale('hi')]) {
    for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('story of the day card in ${locale.languageCode} / ${mode.name}', (tester) async {
        tester.view.physicalSize = const Size(320, 640) * 3;
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
            home: const Scaffold(
              body: SingleChildScrollView(child: StoryOfTheDayCard(padding: EdgeInsets.all(16))),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        final t = await AppLocalizations.delegate.load(locale);
        final entry = ProphetStoriesService.storyOfTheDay(await ProphetStoriesService().loadIndex(), DateTime.now())!;
        expect(find.text(t.storiesOfTheDay), findsOneWidget);
        expect(find.text(prophetDisplayName(entry, locale.languageCode, t)), findsOneWidget);

        await tester.tap(find.text(t.storiesOfTheDay));
        await tester.pumpAndSettle();
        expect(find.byType(ProphetStoryReaderScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
