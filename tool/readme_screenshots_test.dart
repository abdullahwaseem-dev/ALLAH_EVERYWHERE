// Renders README screenshots of the Challenges and Rewards screens with
// demo data, the app's real fonts and icons, at iPhone size:
//
//   flutter test tool/readme_screenshots_test.dart
//
// Writes PNGs to build/readme_shots/ (resize them into docs/screenshots/).
// Not part of the normal test suite.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:allah_everywhere/challenges.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/models/challenge.dart';
import 'package:allah_everywhere/rewards.dart';
import 'package:allah_everywhere/services/challenge_service.dart';
import 'package:allah_everywhere/services/rewards_service.dart';
import 'package:allah_everywhere/utils/utils/theme/theme.dart';

const _size = Size(402, 874);
final _shot = GlobalKey();

Future<void> _loadFonts() async {
  final manifest = jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
  for (final family in manifest) {
    final loader = FontLoader(family['family'] as String);
    for (final font in family['fonts'] as List) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
  // The Material icon font isn't in the test bundle; load it from the SDK.
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/opt/homebrew/share/flutter';
  final icons = File('$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)))).load();
  }
  // Text with no font family uses the phone's system font (SF Pro on
  // iPhone, Roboto on Android); stand in with the Mac's SF font.
  final sf = File('/System/Library/Fonts/SFNS.ttf');
  if (sf.existsSync()) {
    for (final family in [
      'FlutterTest', // the test renderer's default for text with no family
      'Roboto', '.SF UI Display', '.SF UI Text', 'CupertinoSystemDisplay', 'CupertinoSystemText',
    ]) {
      await (FontLoader(family)..addFont(Future.value(ByteData.view(sf.readAsBytesSync().buffer)))).load();
    }
  }
}

/// The app bar and outlined-button styles name no font, so a phone draws
/// them in its system font; point them at the SF stand-in loaded above.
ThemeData _systemFont(ThemeData base) => base.copyWith(
      appBarTheme: base.appBarTheme.copyWith(
        titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(fontFamily: 'Roboto'),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: (base.outlinedButtonTheme.style ?? const ButtonStyle()).copyWith(
          textStyle: WidgetStatePropertyAll(
            base.outlinedButtonTheme.style?.textStyle?.resolve({})?.copyWith(fontFamily: 'Roboto') ??
                const TextStyle(fontFamily: 'Roboto'),
          ),
        ),
      ),
    );

Widget _app(Widget home, {ThemeMode mode = ThemeMode.light}) => RepaintBoundary(
      key: _shot,
      child: ScreenUtilInit(
        designSize: const Size(360, 690),
        minTextAdapt: true,
        builder: (context, _) => GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _systemFont(VoidAppTheme.lightTheme),
          darkTheme: _systemFont(VoidAppTheme.darkTheme),
          themeMode: mode,
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );

Future<void> _capture(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  // Let asset images decode.
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await precacheImage(image.image, element);
    }
  });
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary = _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('build/readme_shots/$name.png')..createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = _size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// A family Khatam, a dhikr challenge and a finished Al-Mulk challenge.
Future<(FakeFirebaseFirestore, ChallengeService, Challenge)> _seed() async {
  final db = FakeFirebaseFirestore();
  ChallengeService user(String uid, String name) => ChallengeService(
      firestore: db, auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: uid, displayName: name)));
  final amina = user('amina', 'Amina');
  final now = DateTime.now();
  final khatam = await amina.create(NewChallenge(
    title: 'Ramadan Khatam with the family',
    type: ChallengeType.khatam,
    unit: ChallengeUnits.juz,
    target: 30,
    startAt: now.subtract(const Duration(days: 9)),
    durationDays: 30,
    intention: 'To grow closer to the Quran this Ramadan',
    familyPromise: 'Winner chooses Eid dinner',
  ));
  final family = [('bilal', 'Bilal'), ('fatima', 'Fatima'), ('yusuf', 'Yusuf'), ('maryam', 'Maryam')];
  for (final (uid, name) in family) {
    final s = user(uid, name);
    await s.join(await s.lookup(khatam.inviteCode));
  }
  await amina.logProgress(khatam, items: List.generate(11, (i) => i + 1));
  await user('bilal', 'Bilal').logProgress(khatam, items: List.generate(8, (i) => i + 1));
  await user('fatima', 'Fatima').logProgress(khatam, items: List.generate(14, (i) => i + 1));
  await user('yusuf', 'Yusuf').logProgress(khatam, items: List.generate(5, (i) => i + 1));
  await user('fatima', 'Fatima').sendMessage(khatam, 'Alhamdulillah, Juz 14 done before Taraweeh!');
  await user('bilal', 'Bilal').sendMessage(khatam, 'MashaAllah Fatima, you are flying');
  final feed = await db.collection('challenges').doc(khatam.id).collection('feed').get();
  for (final doc in feed.docs) {
    if (doc.data()['kind'] == 'message' && (doc.data()['text'] as String).startsWith('Alhamdulillah')) {
      await doc.reference.update({
        'reactions': {
          'amina': ['mashaallah'],
          'bilal': ['mashaallah', 'barakallah'],
          'yusuf': ['ameen'],
        },
      });
    }
  }
  await amina.create(NewChallenge(
    title: '10,000 Durood this week',
    type: ChallengeType.dhikr,
    unit: ChallengeUnits.count,
    target: 10000,
    startAt: now.subtract(const Duration(days: 2)),
    durationDays: 7,
  ));
  final latest = await db.collection('challenges').doc(khatam.id).get();
  return (db, amina, Challenge.fromDoc(latest));
}

Future<FakeFirebaseFirestore> _seedRewards() async {
  final db = FakeFirebaseFirestore();
  final rewards = db.collection('users').doc('amina').collection('rewards');
  final days = [40, 30, 21, 12, 5];
  for (final (i, id) in ['first_challenge', 'khatam_finisher', 'steadfast', 'encourager', 'family_builder'].indexed) {
    await rewards.doc('badge_$id').set({
      'type': 'badge',
      'badgeId': id,
      'earnedAt': Timestamp.fromDate(DateTime.now().subtract(Duration(days: days[i]))),
    });
  }
  await rewards.doc('cert_1').set({
    'type': 'certificate',
    'challengeId': 'ch1',
    'title': 'Ramadan Khatam with the family',
    'challengeType': 'khatam',
    'startAt': Timestamp.fromDate(DateTime(2026, 2, 18)),
    'endAt': Timestamp.fromDate(DateTime(2026, 3, 19)),
    'completedAt': Timestamp.fromDate(DateTime(2026, 3, 16)),
    'result': 'perfect',
    'name': 'Amina Waseem',
    'dedication': 'For my late grandmother',
  });
  for (final (i, label) in ['Ramadan Khatam', 'Al-Mulk in 3 days', '10,000 Durood', 'Fajr on time', 'Dhul Hijjah fasts']
      .indexed) {
    await rewards.doc('garden_tree_$i').set({'type': 'garden', 'kind': 'tree', 'label': label});
  }
  await rewards.doc('garden_fountain_0').set({'type': 'garden', 'kind': 'fountain', 'label': 'Ramadan Khatam'});
  return db;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDir;

  setUpAll(() async {
    storageDir = await Directory.systemTemp.createTemp('readme_shots');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => storageDir.path,
    );
    await GetStorage.init();
    await _loadFonts();
    ChallengeService.logEvent = (_, __) {};
  });

  setUp(() => GetStorage().erase());

  testWidgets('challenges hub', (tester) async {
    _phone(tester);
    final (_, amina, _) = await _seed();
    await tester.pumpWidget(_app(ChallengesScreen(service: amina)));
    await _capture(tester, 'light_challenges');
  });

  testWidgets('challenge screen', (tester) async {
    _phone(tester);
    final (_, amina, khatam) = await _seed();
    await tester.pumpWidget(_app(ChallengeDetailScreen(challengeId: khatam.id, initial: khatam, service: amina)));
    await _capture(tester, 'light_challenge_detail');
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -560));
    await _capture(tester, 'light_challenge_feed');
  });

  testWidgets('create a challenge', (tester) async {
    _phone(tester);
    final (_, amina, _) = await _seed();
    await tester.pumpWidget(_app(CreateChallengeScreen(service: amina)));
    await _capture(tester, 'light_challenge_create');
  });

  testWidgets('celebration', (tester) async {
    _phone(tester);
    final (_, amina, khatam) = await _seed();
    await tester.pumpWidget(_app(ChallengeCelebrationScreen(challenge: khatam, service: amina)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 1700)); // text in, sparkles still out
    await tester.runAsync(() async {
      final boundary = _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('build/readme_shots/light_celebration.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    await tester.pumpAndSettle();
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    testWidgets('rewards and garden (${mode.name})', (tester) async {
      _phone(tester);
      final db = await _seedRewards();
      final svc = RewardsService(
        firestore: db,
        auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'amina')),
        dhikrTotal: () => 4300,
        hifzProgress: () => {},
      );
      await tester.pumpWidget(_app(RewardsScreen(service: svc), mode: mode));
      await _capture(tester, '${mode.name}_rewards');
      await tester.pumpWidget(_app(JannahGardenScreen(service: svc), mode: mode));
      await _capture(tester, '${mode.name}_garden');
    });
  }

  testWidgets('certificate', (tester) async {
    _phone(tester);
    final db = await _seedRewards();
    final svc = RewardsService(
      firestore: db,
      auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'amina')),
      dhikrTotal: () => 0,
      hifzProgress: () => {},
    );
    final state = await svc.watch().firstWhere((s) => s.certificates.isNotEmpty);
    await tester.pumpWidget(_app(CertificateScreen(certificate: state.certificates.single)));
    await _capture(tester, 'light_certificate');
  });

  testWidgets('dua wall', (tester) async {
    _phone(tester);
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
      'creatorUid': 'amina',
      'creatorName': 'Amina',
      'inviteCode': 'ABC234',
      'memberUids': ['amina', 'bilal', 'fatima', 'yusuf'],
      'memberCount': 4,
    });
    final parts = db.collection('challenges').doc('ch1').collection('participants');
    await parts.doc('amina').set({'displayName': 'Amina', 'percent': 100, 'completedAt': Timestamp.now()});
    await parts.doc('bilal').set({'displayName': 'Bilal', 'percent': 70});
    await parts.doc('fatima').set({'displayName': 'Fatima', 'percent': 100, 'completedAt': Timestamp.now()});
    await parts.doc('yusuf').set({'displayName': 'Yusuf', 'percent': 45});
    final duas = db.collection('challenges').doc('ch1').collection('duas');
    Future<void> dua(String from, String name, String to, String text, int minutes) => duas.doc('${from}_$to').set({
          'fromUid': from,
          'fromName': name,
          'toUid': to,
          'text': text,
          'createdAt': Timestamp.fromDate(now.subtract(Duration(minutes: minutes))),
        });
    await dua('bilal', 'Bilal', 'amina', 'May Allah accept it from you and make the Quran your companion.', 50);
    await dua('fatima', 'Fatima', 'amina', 'Ameen! May He make it light in your grave and heavy on your scale.', 40);
    await dua('yusuf', 'Yusuf', 'amina', 'BarakAllahu feeki, Ammi. Pray for me too!', 30);
    await dua('amina', 'Amina', 'fatima', 'May Allah keep you close to His Book always.', 20);
    final svc = ChallengeService(
        firestore: db, auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'amina', displayName: 'Amina')));
    final c = Challenge.fromDoc(await db.collection('challenges').doc('ch1').get());
    await tester.pumpWidget(_app(DuaWallScreen(challenge: c, service: svc)));
    await _capture(tester, 'light_dua_wall');
  });
}
