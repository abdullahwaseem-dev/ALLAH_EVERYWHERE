// Checks on a real device/simulator (real Amiri font - widget tests draw
// every glyph as a box, so they can't measure Arabic) that Mushaf pages fit
// the screen at the default text size, and pauses on a few pages so they
// can be screenshotted:
//
//   flutter test integration_test/mushaf_fit_test.dart \
//     -d <simulator-id> --dart-define-from-file=dart_defines.json
//
// While it runs, `xcrun simctl io <id> screenshot page.png` captures the
// page named in the MUSHAF_SHOT log line.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:integration_test/integration_test.dart';

import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/mushaf.dart';
import 'package:allah_everywhere/utils/utils/theme/theme.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Mushaf pages fit the screen with real fonts', (tester) async {
    await GetStorage.init();
    await GetStorage().erase();

    Future<void> show(int page) async {
      await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, _) => MaterialApp(
          key: ValueKey(page),
          theme: VoidAppTheme.lightTheme,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: MushafScreen(initialPage: page),
        ),
      ));
      await tester.pumpAndSettle();
    }

    final results = <String>[];
    for (final page in [1, 2, 3, 50, 300, 582, 604]) {
      await show(page);
      // The page's own vertical scroll (not the horizontal PageView).
      final vertical = find.byWidgetPredicate(
          (w) => w is Scrollable && axisDirectionToAxis(w.axisDirection) == Axis.vertical);
      final position = tester.state<ScrollableState>(vertical.hitTestable().first).position;
      final overflow = position.maxScrollExtent;
      results.add('page $page: scroll extent ${overflow.round()} px');
      // ignore: avoid_print
      print('MUSHAF_FIT page=$page scrollExtent=${overflow.round()} viewport=${position.viewportDimension.round()}');
      if (page == 1 || page == 3 || page == 582) {
        // ignore: avoid_print
        print('MUSHAF_SHOT page=$page');
        await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 4)));
      }
      // At the default size a page should fit with at most a small scroll.
      expect(overflow, lessThan(60), reason: 'page $page should fit the screen');
    }
    // ignore: avoid_print
    print('MUSHAF_RESULTS $results');
  });
}
