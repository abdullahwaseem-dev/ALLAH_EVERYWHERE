import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:allah_everywhere/challenges.dart';
import 'package:allah_everywhere/controllers/theme_controller.dart';
import 'package:allah_everywhere/data/garden_hadith_data.dart';
import 'package:allah_everywhere/data/rewards_data.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/models/challenge.dart';
import 'package:allah_everywhere/rewards.dart';
import 'package:allah_everywhere/services/challenge_service.dart';
import 'package:allah_everywhere/services/rewards_service.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/theme/theme.dart';

/// My Rewards, the certificate, the Jannah Garden, the new-badge moment,
/// accent themes and the Dua Wall, on a small phone at a large text size,
/// in LTR and RTL, light and dark. Fails on any overflow or exception.
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
  await tester.drag(list, const Offset(0, 3000));
  await tester.pumpAndSettle();
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.drag(list, const Offset(0, -200));
    await tester.pump();
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 690) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<FakeFirebaseFirestore> _seedRewards() async {
  final db = FakeFirebaseFirestore();
  final rewards = db.collection('users').doc('u1').collection('rewards');
  await rewards.doc('badge_first_challenge').set({'type': 'badge', 'badgeId': 'first_challenge', 'earnedAt': Timestamp.now()});
  await rewards.doc('badge_steadfast').set({'type': 'badge', 'badgeId': 'steadfast', 'earnedAt': Timestamp.now()});
  await rewards.doc('cert_ch1').set({
    'type': 'certificate',
    'challengeId': 'ch1',
    'title': 'Ramadan Khatam with my family',
    'challengeType': 'khatam',
    'startAt': Timestamp.fromDate(DateTime(2026, 10, 1)),
    'endAt': Timestamp.fromDate(DateTime(2026, 10, 11)),
    'completedAt': Timestamp.fromDate(DateTime(2026, 10, 9)),
    'result': 'perfect',
    'name': 'Bilal Ahmed',
    'dedication': 'For my late grandmother',
  });
  await rewards.doc('garden_tree_ch1').set({'type': 'garden', 'kind': 'tree', 'label': 'Ramadan Khatam'});
  await rewards.doc('garden_fountain_ch1').set({'type': 'garden', 'kind': 'fountain', 'label': 'Ramadan Khatam'});
  return db;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDir;

  setUpAll(() async {
    storageDir = await Directory.systemTemp.createTemp('rewards_screens_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => storageDir.path,
    );
    await GetStorage.init();
  });

  setUp(() {
    ChallengeService.logEvent = (_, __) {};
    VoidColors.useAccent(accentColors['classic_gold']!.$1, accentColors['classic_gold']!.$2);
    return GetStorage().erase();
  });

  tearDownAll(() => storageDir.delete(recursive: true));

  for (final locale in const [Locale('en'), Locale('ur'), Locale('ar')]) {
    for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
      final tag = '${locale.languageCode} / ${mode.name}';

      testWidgets('guest: device badges, locked unlocks ($tag)', (tester) async {
        _phone(tester);
        final t = await AppLocalizations.delegate.load(locale);
        final svc = RewardsService(auth: MockFirebaseAuth(), dhikrTotal: () => 2500, hifzProgress: () => {});
        await tester.pumpWidget(_app(RewardsScreen(service: svc), locale, mode));
        await tester.pumpAndSettle();
        expect(find.text(t.rewardsGuestNote), findsOneWidget);
        // 2,500 dhikr: the 1,000 badge and two palms.
        await _scrollTo(tester, find.text(t.rewardsPlants(2)));
        await _scrollTo(tester, find.text(t.badgeDhikr1000));
        expect(find.text(t.badgeDhikr10000How), findsOneWidget);

        // The pearl bead is unlocked by 1,000 dhikr; Madinah Green is not.
        await _scrollTo(tester, find.text(t.cosmeticBeadPearl));
        await tester.tap(find.text(t.cosmeticBeadPearl));
        await tester.pumpAndSettle();
        expect(RewardsService.selected(CosmeticKind.bead), 'bead_pearl');
        await _scrollTo(tester, find.text(t.cosmeticMadinahGreen));
        await tester.tap(find.text(t.cosmeticMadinahGreen));
        await tester.pumpAndSettle();
        expect(find.text(t.rewardsUnlockWith(t.badgeFirstChallenge)), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('signed in: badges, certificate, garden ($tag)', (tester) async {
        _phone(tester);
        final t = await AppLocalizations.delegate.load(locale);
        final db = await _seedRewards();
        final svc = RewardsService(
          firestore: db,
          auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1')),
          dhikrTotal: () => 0,
          hifzProgress: () => {},
        );
        await tester.pumpWidget(_app(RewardsScreen(service: svc), locale, mode));
        await tester.pumpAndSettle();
        expect(find.text(t.rewardsShowBadges), findsOneWidget);
        await _scrollTo(tester, find.text(t.rewardsPlants(2)));

        await _scrollTo(tester, find.text('Ramadan Khatam with my family'));
        await tester.tap(find.text('Ramadan Khatam with my family'));
        await tester.pumpAndSettle();
        expect(find.byType(CertificateCard), findsOneWidget);
        expect(find.text('Bilal Ahmed'), findsOneWidget);
        expect(find.text(t.certResultPerfect), findsOneWidget);
        expect(find.text(t.certDedicated('For my late grandmother')), findsOneWidget);
        expect(find.text(t.certSharePdf), findsOneWidget);
        expect(tester.takeException(), isNull);
        Navigator.of(tester.element(find.byType(CertificateCard))).pop();
        await tester.pumpAndSettle();

        await _scrollTo(tester, find.text(t.rewardsPlants(2)));
        await tester.tap(find.text(t.rewardsPlants(2)));
        await tester.pumpAndSettle();
        expect(find.byType(JannahGardenScreen), findsOneWidget);
        expect(find.text(t.gardenReminder), findsOneWidget);
        await _scrollTo(tester, find.text(gardenHadith.reference));
        expect(find.text(gardenHadith.arabic), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('the new-badge moment ($tag)', (tester) async {
        _phone(tester);
        final t = await AppLocalizations.delegate.load(locale);
        await tester.pumpWidget(_app(const Scaffold(body: SizedBox()), locale, mode));
        await tester.pumpAndSettle();
        showBadgeUnlocked(tester.element(find.byType(SizedBox).first), 'family_builder');
        await tester.pumpAndSettle();
        expect(find.text(t.badgeFamilyBuilder), findsOneWidget);
        expect(find.text(t.rewardsRealReward), findsOneWidget);
        await tester.tap(find.text(t.rewardsClose));
        await tester.pumpAndSettle();
        expect(find.text(t.badgeFamilyBuilder), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Dua Wall: one dua each, and one back for everyone ($tag)', (tester) async {
        _phone(tester);
        final t = await AppLocalizations.delegate.load(locale);
        final db = FakeFirebaseFirestore();
        final now = DateTime.now();
        await db.collection('challenges').doc('ch1').set({
          'title': 'Al-Mulk in 3 days',
          'type': 'memorizeSurah',
          'unit': 'ayahs',
          'target': 30,
          'surah': 67,
          'startAt': Timestamp.fromDate(now.subtract(const Duration(days: 4))),
          'endAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
          'creatorUid': 'alice',
          'creatorName': 'Amina',
          'inviteCode': 'ABC234',
          'memberUids': ['alice', 'bob', 'carol'],
          'memberCount': 3,
        });
        final parts = db.collection('challenges').doc('ch1').collection('participants');
        await parts.doc('alice').set({'displayName': 'Amina', 'percent': 60});
        await parts.doc('bob').set({'displayName': 'Bilal', 'percent': 100, 'completedAt': Timestamp.now()});
        await parts.doc('carol').set({'displayName': 'Carol', 'percent': 100, 'completedAt': Timestamp.now()});
        final c = Challenge.fromDoc(await db.collection('challenges').doc('ch1').get());
        ChallengeService user(String uid, String name) => ChallengeService(
            firestore: db, auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: uid, displayName: name)));

        // Amina writes for Bilal.
        await tester.pumpWidget(_app(DuaWallScreen(key: const ValueKey('alice'), challenge: c, service: user('alice', 'Amina')), locale, mode));
        await tester.pumpAndSettle();
        expect(find.text(t.duaWallFor('Bilal')), findsOneWidget);
        expect(find.text(t.duaWallFor('Carol')), findsOneWidget);
        expect(find.text(t.duaWallWriteEveryone), findsNothing);
        await tester.tap(find.widgetWithText(FilledButton, t.duaWallWrite).first);
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'May Allah accept it from you');
        await tester.tap(find.text(t.challengesSend));
        await tester.pumpAndSettle();
        expect(find.text('May Allah accept it from you'), findsOneWidget);
        expect(find.text(t.duaWallWritten), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Bilal sees it, and writes one back for everyone.
        await tester.pumpWidget(_app(DuaWallScreen(key: const ValueKey('bob'), challenge: c, service: user('bob', 'Bilal')), locale, mode));
        await tester.pumpAndSettle();
        expect(find.text(t.duaWallForYou), findsOneWidget);
        expect(find.text('May Allah accept it from you'), findsOneWidget);
        await _scrollTo(tester, find.widgetWithText(FilledButton, t.duaWallWriteEveryone));
        await tester.tap(find.widgetWithText(FilledButton, t.duaWallWriteEveryone));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'Jazakum Allahu khayran');
        await tester.tap(find.text(t.challengesSend));
        await tester.pumpAndSettle();
        final everyone = await db.collection('challenges').doc('ch1').collection('duas').doc('bob_all').get();
        expect(everyone.data()!['text'], 'Jazakum Allahu khayran');
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('an unlocked accent theme recolours the app', (tester) async {
    _phone(tester);
    final t = await AppLocalizations.delegate.load(const Locale('en'));
    Get.put(ThemeController());
    addTearDown(Get.reset);
    final db = await _seedRewards();
    final svc = RewardsService(
      firestore: db,
      auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'u1')),
      dhikrTotal: () => 0,
      hifzProgress: () => {},
    );
    await tester.pumpWidget(_app(RewardsScreen(service: svc), const Locale('en'), ThemeMode.light));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text(t.cosmeticNightOfQadr));
    await tester.tap(find.text(t.cosmeticNightOfQadr));
    await tester.pumpAndSettle();
    expect(VoidColors.gold, accentColors['night_of_qadr']!.$1);
    expect(Get.find<ThemeController>().accent.value, 'night_of_qadr');
    expect(GetStorage().read('accent_theme'), 'night_of_qadr');
  });

  test('a dedication and a family promise are saved with the challenge', () async {
    final db = FakeFirebaseFirestore();
    final svc = ChallengeService(
        firestore: db, auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'alice', displayName: 'Amina')));
    final c = await svc.create(NewChallenge(
      title: 'Khatam',
      type: ChallengeType.khatam,
      unit: ChallengeUnits.juz,
      target: 30,
      startAt: DateTime.now(),
      durationDays: 30,
      dedication: '  For my late grandmother  ',
      familyPromise: 'Winner chooses Friday dinner',
    ));
    final doc = (await db.collection('challenges').doc(c.id).get()).data()!;
    expect(doc['dedication'], 'For my late grandmother');
    expect(doc['familyPromise'], 'Winner chooses Friday dinner');
    expect(Challenge.fromDoc(await db.collection('challenges').doc(c.id).get()).dedication, 'For my late grandmother');
  });
}
