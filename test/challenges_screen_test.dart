import 'dart:math';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/challenges.dart';
import 'package:allah_everywhere/data/challenge_templates.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/models/challenge.dart';
import 'package:allah_everywhere/services/challenge_service.dart';
import 'package:allah_everywhere/utils/utils/theme/theme.dart';

/// Renders the Challenges screens for a guest and a signed-in user, in LTR
/// and RTL, light and dark, on a small phone at a large text size: creates
/// a challenge from every template's form, then joins it as another user.
/// Fails on any overflow or exception.
Widget _app(Widget home, Locale locale, ThemeMode mode) => ScreenUtilInit(
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
        home: home,
      ),
    );

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  final list = find.byType(Scrollable).first;
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.drag(list, const Offset(0, -250));
    await tester.pump();
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => ChallengeService.logEvent = (_, __) {});

  for (final locale in const [Locale('en'), Locale('ur'), Locale('ar')]) {
    for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
      final tag = '${locale.languageCode} / ${mode.name}';

      testWidgets('guest sees the sign-in prompt ($tag)', (tester) async {
        tester.view.physicalSize = const Size(360, 690) * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final svc = ChallengeService(firestore: FakeFirebaseFirestore(), auth: MockFirebaseAuth());
        await tester.pumpWidget(_app(ChallengesScreen(service: svc), locale, mode));
        await tester.pumpAndSettle();
        final t = await AppLocalizations.delegate.load(locale);
        expect(find.text(t.challengesGuestTitle), findsOneWidget);
        expect(find.text(t.challengesSignIn), findsOneWidget);
        expect(find.text(t.challengesCreate), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('create every type, then join with the code ($tag)', (tester) async {
        tester.view.physicalSize = const Size(360, 690) * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final db = FakeFirebaseFirestore();
        final alice = ChallengeService(
          firestore: db,
          auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'alice', displayName: 'Amina')),
          random: Random(1),
        );
        final t = await AppLocalizations.delegate.load(locale);

        await tester.pumpWidget(_app(ChallengesScreen(service: alice), locale, mode));
        await tester.pumpAndSettle();
        expect(find.text(t.challengesEmpty), findsOneWidget);

        // Create: visit every template's form, then create a Khatam.
        await tester.tap(find.text(t.challengesCreate));
        await tester.pumpAndSettle();
        for (final tpl in challengeTemplates.reversed) {
          // The type chips are at the top of the form.
          await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(ChoiceChip, challengeTypeLabel(tpl.type, t)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: tpl.type.name);
        }
        // Custom needs a title and a unit: an empty title shows an error.
        await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ChoiceChip, challengeTypeLabel(ChallengeType.custom, t)));
        await tester.pumpAndSettle();
        await _scrollTo(tester, find.widgetWithText(FilledButton, t.challengesCreateButton));
        await tester.tap(find.widgetWithText(FilledButton, t.challengesCreateButton));
        await tester.pumpAndSettle();
        expect(find.text(t.challengesErrorTitle), findsOneWidget);

        await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ChoiceChip, challengeTypeLabel(ChallengeType.khatam, t)));
        await tester.pumpAndSettle();
        await _scrollTo(tester, find.widgetWithText(FilledButton, t.challengesCreateButton));
        await tester.tap(find.widgetWithText(FilledButton, t.challengesCreateButton));
        await tester.pumpAndSettle();

        // The invite sheet with the code.
        expect(find.text(t.challengesCreated), findsOneWidget);
        final created = (await db.collection('challenges').get()).docs.single;
        final code = created.data()['inviteCode'] as String;
        expect(find.text(code), findsOneWidget);
        expect(created.data()['target'], 30);
        expect(created.data()['title'], t.challengesDefaultTitle(30, t.challengesTypeKhatam));
        Navigator.of(tester.element(find.text(code))).pop();
        await tester.pumpAndSettle();

        // Back on the hub: the new challenge is listed.
        expect(find.text(t.challengesActive), findsOneWidget);
        expect(find.textContaining(t.challengesTypeKhatam), findsWidgets);
        expect(tester.takeException(), isNull);

        // Bob joins with the code.
        final bob = ChallengeService(
          firestore: db,
          auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'bob', displayName: 'Bilal')),
        );
        // Bob opens Join from his hub; a wrong code first shows an error.
        await tester.pumpWidget(_app(ChallengesScreen(service: bob), locale, mode));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.challengesJoin));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'ZZZZZZ');
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.challengesFind));
        await tester.pumpAndSettle();
        expect(find.text(t.challengesErrorNotFound), findsOneWidget);

        await tester.enterText(find.byType(TextField), code.toLowerCase());
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.challengesFind));
        await tester.pumpAndSettle();
        expect(find.text(t.challengesBy('Amina')), findsOneWidget);
        expect(find.text(t.challengesMembers(1)), findsOneWidget);
        await _scrollTo(tester, find.text(t.challengesJoinButton));
        await tester.tap(find.text(t.challengesJoinButton));
        await tester.pumpAndSettle();
        final doc = await db.collection('challenges').doc(created.id).get();
        expect(doc.data()!['memberUids'], ['alice', 'bob']);

        // Back on Bob's hub, with the challenge listed.
        expect(find.text(t.challengesJoined), findsOneWidget);
        expect(find.text(t.challengesMembers(2)), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
