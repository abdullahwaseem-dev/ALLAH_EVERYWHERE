import 'dart:io';
import 'dart:math';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconsax/iconsax.dart';
import 'package:allah_everywhere/challenges.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/models/challenge.dart';
import 'package:allah_everywhere/services/challenge_service.dart';
import 'package:allah_everywhere/utils/utils/theme/theme.dart';

/// The challenge screen on a small phone at a large text size, in LTR and
/// RTL, light and dark: log progress (+1 and the Juz picker) to 100%, see
/// the celebration and summary card, chat, react, nudge and remove a
/// member. Fails on any overflow or exception.
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

Finder get _list => find.byType(Scrollable).first;

/// Scrolls the screen from the top until [finder] is built, then shows it.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.drag(_list, const Offset(0, 3000));
  await tester.pumpAndSettle();
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.drag(_list, const Offset(0, -200));
    await tester.pump();
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDir;

  setUpAll(() async {
    storageDir = await Directory.systemTemp.createTemp('challenge_detail_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => storageDir.path,
    );
    await GetStorage.init();
  });

  setUp(() {
    ChallengeService.logEvent = (_, __) {};
    return GetStorage().erase();
  });

  tearDownAll(() => storageDir.delete(recursive: true));

  for (final locale in const [Locale('en'), Locale('ur'), Locale('ar')]) {
    for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
      final tag = '${locale.languageCode} / ${mode.name}';

      testWidgets('log to 100%, celebrate, chat, react, nudge, remove ($tag)', (tester) async {
        tester.view.physicalSize = const Size(360, 690) * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final t = await AppLocalizations.delegate.load(locale);

        final db = FakeFirebaseFirestore();
        ChallengeService user(String uid, String name) => ChallengeService(
              firestore: db,
              auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: uid, displayName: name)),
              random: Random(uid.hashCode),
            );
        final alice = user('alice', 'Amina');
        final bob = user('bob', 'Bilal');
        final carol = user('carol', 'Carol');
        final c = await alice.create(NewChallenge(
          title: 'Ramadan Khatam',
          type: ChallengeType.khatam,
          unit: ChallengeUnits.juz,
          target: 30,
          startAt: DateTime.now(),
          durationDays: 30,
          intention: 'For my parents',
        ));
        await bob.join(await bob.lookup(c.inviteCode));
        await carol.join(await carol.lookup(c.inviteCode), showExactNumbers: false);
        await bob.logProgress(c, items: [1]);

        await tester.pumpWidget(_app(ChallengeDetailScreen(challengeId: c.id, service: alice), locale, mode));
        await tester.pumpAndSettle();
        expect(find.text('For my parents'), findsOneWidget);
        await _scrollTo(tester, find.text('1/30'));
        expect(find.text(t.challengesMembersTitle), findsOneWidget);
        // Bilal leads with 1 Juz.
        expect(find.byIcon(Iconsax.crown_1), findsOneWidget);
        expect(find.text('1/30'), findsOneWidget);
        // Carol shares only her percentage.
        expect(find.text('0%'), findsWidgets);
        await _scrollTo(tester, find.text(t.challengesFeedJuz('Bilal', '1')));
        expect(find.text(t.challengesFeedJoined('Carol')), findsOneWidget);
        expect(tester.takeException(), isNull);

        // +1 ticks the first Juz Amina hasn't done.
        await _scrollTo(tester, find.text('+1'));
        await tester.tap(find.text('+1'));
        await tester.pumpAndSettle();
        await _scrollTo(tester, find.text(t.challengesFeedJuz('Amina', '1')));

        // The Juz picker: tick 2-30, which completes the challenge.
        await _scrollTo(tester, find.widgetWithText(FilledButton, t.challengesLogProgress));
        await tester.tap(find.widgetWithText(FilledButton, t.challengesLogProgress));
        await tester.pumpAndSettle();
        expect(find.text(t.challengesPickJuz), findsOneWidget);
        final grid = find.byType(GridView);
        for (var n = 2; n <= 30; n++) {
          final cell = find.descendant(of: grid, matching: find.text('$n'));
          await tester.ensureVisible(cell);
          await tester.tap(cell);
          await tester.pump();
        }
        await tester.tap(find.widgetWithText(FilledButton, t.challengesSave));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Celebration, then the shareable summary.
        expect(find.text(t.challengesCelebrationTitle), findsOneWidget);
        expect(find.text(t.challengesCelebrationBody('Ramadan Khatam')), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, t.challengesShareResult));
        await tester.pumpAndSettle();
        expect(find.byType(ChallengeSummaryCard), findsOneWidget);
        expect(find.text(t.challengesSummaryCompleted('1', '3')), findsOneWidget);
        expect(tester.takeException(), isNull);
        Navigator.of(tester.element(find.byType(ChallengeSummaryCard))).pop();
        await tester.pumpAndSettle();
        expect(find.text(t.challengesCertificateSoon), findsOneWidget);
        await tester.ensureVisible(find.text(t.challengesBackToChallenge));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.challengesBackToChallenge));
        await tester.pumpAndSettle();

        final me = await db.collection('challenges').doc(c.id).collection('participants').doc('alice').get();
        expect(me.data()!['percent'], 100);
        await _scrollTo(tester, find.text(t.challengesAllItemsDone));
        await _scrollTo(tester, find.text(t.challengesFeedCompleted('Amina')));
        // Amina now leads.
        await _scrollTo(tester, find.text('30/30'));
        expect(find.byIcon(Iconsax.crown_1), findsOneWidget);

        // Chat: profanity is masked.
        await tester.enterText(find.byType(TextField), 'Bismillah, what the fuck');
        await tester.tap(find.byTooltip(t.challengesSend));
        await tester.pumpAndSettle();
        await _scrollTo(tester, find.text('Bismillah, what the ****'));

        // React from the long-press sheet.
        await tester.longPress(find.text('Bismillah, what the ****'));
        await tester.pumpAndSettle();
        expect(find.text(t.challengesDeleteItem), findsOneWidget);
        await tester.tap(find.text(t.challengesReactMashaAllah));
        await tester.pumpAndSettle();
        await _scrollTo(tester, find.text('${t.challengesReactMashaAllah} 1'));

        // Nudge: only Carol hasn't logged today.
        await tester.tap(find.byTooltip(t.challengesNudge));
        await tester.pumpAndSettle();
        expect(find.text(t.challengesNudgeTitle), findsOneWidget);
        expect(find.descendant(of: find.byType(BottomSheet), matching: find.text('Carol')), findsOneWidget);
        expect(find.descendant(of: find.byType(BottomSheet), matching: find.text('Bilal')), findsNothing);
        await tester.tap(find.descendant(of: find.byType(BottomSheet), matching: find.text(t.challengesNudge)));
        await tester.pumpAndSettle();
        expect(find.text(t.challengesNudgeSent), findsOneWidget);
        await tester.tapAt(const Offset(180, 40));
        await tester.pumpAndSettle();
        await _scrollTo(tester, find.text(t.challengesFeedNudge('Amina', 'Carol')));
        expect(tester.takeException(), isNull);

        // The creator removes Carol from the leaderboard.
        await _scrollTo(tester, find.text('Carol'));
        await tester.tap(find.text('Carol'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(t.challengesRemoveMember));
        await tester.pumpAndSettle();
        expect(find.text(t.challengesRemoveConfirm('Carol')), findsOneWidget);
        await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text(t.challengesRemoveMember)));
        await tester.pumpAndSettle();
        final doc = await db.collection('challenges').doc(c.id).get();
        expect(doc.data()!['memberUids'], ['alice', 'bob']);
        await tester.drag(_list, const Offset(0, 3000));
        await tester.pumpAndSettle();
        expect(find.text('Carol'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('a removed member sees that the challenge is gone ($tag)', (tester) async {
        tester.view.physicalSize = const Size(360, 690) * 3;
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final t = await AppLocalizations.delegate.load(locale);
        final db = FakeFirebaseFirestore();
        final alice = ChallengeService(
            firestore: db, auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'alice', displayName: 'A')));
        final bob = ChallengeService(
            firestore: db, auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'bob', displayName: 'B')));
        final c = await alice.create(NewChallenge(
            title: 'Durood',
            type: ChallengeType.dhikr,
            unit: ChallengeUnits.count,
            target: 1000,
            startAt: DateTime.now(),
            durationDays: 7));
        await bob.join(await bob.lookup(c.inviteCode));

        await tester.pumpWidget(_app(ChallengeDetailScreen(challengeId: c.id, service: bob), locale, mode));
        await tester.pumpAndSettle();
        // A count challenge: "+1" and a number sheet.
        await tester.tap(find.widgetWithText(FilledButton, t.challengesLogProgress));
        await tester.pumpAndSettle();
        await tester.tap(find.text('+100'));
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, t.challengesSave));
        await tester.pumpAndSettle();
        expect(find.text(t.challengesProgressOf('100', '1000', t.challengesUnitCount)), findsOneWidget);

        await alice.removeMember(c, 'bob');
        await tester.pumpAndSettle();
        expect(find.text(t.challengesNotAvailable), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('Home card shows the active challenge, nothing for guests', (tester) async {
    tester.view.physicalSize = const Size(360, 690) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final t = await AppLocalizations.delegate.load(const Locale('en'));
    final db = FakeFirebaseFirestore();
    final guest = ChallengeService(firestore: db, auth: MockFirebaseAuth());
    await tester.pumpWidget(_app(Scaffold(body: ActiveChallengeCard(key: const ValueKey('guest'), service: guest)), const Locale('en'), ThemeMode.light));
    await tester.pumpAndSettle();
    expect(find.descendant(of: find.byType(ActiveChallengeCard), matching: find.byType(Text)), findsNothing);

    final alice = ChallengeService(
        firestore: db, auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'alice', displayName: 'A')));
    final c = await alice.create(NewChallenge(
        title: 'Al-Mulk in 3 days',
        type: ChallengeType.memorizeSurah,
        unit: ChallengeUnits.ayahs,
        target: 30,
        startAt: DateTime.now(),
        durationDays: 3,
        surah: 67));
    await alice.logProgress(c, items: [1, 2, 3]);
    await tester.pumpWidget(_app(Scaffold(body: ActiveChallengeCard(key: const ValueKey('alice'), service: alice)), const Locale('en'), ThemeMode.dark));
    await tester.pumpAndSettle();
    expect(find.text('Al-Mulk in 3 days'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
    expect(find.text(t.challengesDaysLeft(3)), findsOneWidget);
    await tester.tap(find.text('Al-Mulk in 3 days'));
    await tester.pumpAndSettle();
    // The ayah picker for Al-Mulk: 30 ayahs, the first three ticked.
    await tester.tap(find.widgetWithText(FilledButton, t.challengesLogProgress));
    await tester.pumpAndSettle();
    expect(find.text(t.challengesPickAyahs), findsOneWidget);
    expect(find.descendant(of: find.byType(GridView), matching: find.byIcon(Icons.check)), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}

