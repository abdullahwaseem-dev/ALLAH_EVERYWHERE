import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:allah_everywhere/challenges.dart';
import 'package:allah_everywhere/controllers/notifications_controller.dart';
import 'package:allah_everywhere/l10n/generated/app_localizations.dart';
import 'package:allah_everywhere/models/challenge.dart';
import 'package:allah_everywhere/services/challenge_service.dart';
import 'package:allah_everywhere/services/local_notifications_service.dart';

/// Challenge reminders use local notification ids 700-799 only, one per
/// challenge, and server-written challenge notifications open their
/// challenge from the notification center.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storageDir;
  final calls = <MethodCall>[];

  setUpAll(() async {
    storageDir = await Directory.systemTemp.createTemp('challenge_notifications_test');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => storageDir.path,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (call) async {
        calls.add(call);
        return null;
      },
    );
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    await GetStorage.init();
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
  });

  setUp(() async {
    calls.clear();
    await GetStorage().erase();
  });

  tearDownAll(() => storageDir.delete(recursive: true));

  Iterable<int> idsOf(String method) =>
      calls.where((c) => c.method == method).map((c) => ((c.arguments as Map)['id'] as int?) ?? -1);

  test('each challenge gets its own id in 700-799, reused when freed', () async {
    final service = LocalNotificationsService();
    final end = DateTime.now().add(const Duration(days: 10));
    await service.setChallengeReminder('a', title: 'Khatam', endAt: end, time: const TimeOfDay(hour: 20, minute: 0));
    await service.setChallengeReminder('b', title: 'Mulk', endAt: end, time: const TimeOfDay(hour: 6, minute: 30));
    expect(idsOf('zonedSchedule').toSet(), {700, 701});
    expect(service.challengeReminderTime('b'), const TimeOfDay(hour: 6, minute: 30));
    final body = calls.lastWhere((c) => c.method == 'zonedSchedule').arguments as Map;
    expect(body['body'], contains('Mulk'));
    expect(body['payload'], 'challenge:b');

    calls.clear();
    await service.setChallengeReminder('a', title: 'Khatam', endAt: end);
    expect(idsOf('cancel'), contains(700));
    expect(service.challengeReminderTime('a'), isNull);

    calls.clear();
    await service.setChallengeReminder('c', title: 'Durood', endAt: end, time: const TimeOfDay(hour: 21, minute: 0));
    expect(idsOf('zonedSchedule').toSet(), {700, 701});
  });

  test('reminders for ended challenges are dropped on the next launch', () async {
    final service = LocalNotificationsService();
    await service.setChallengeReminder('old',
        title: 'Old', endAt: DateTime.now().add(const Duration(seconds: 1)), time: const TimeOfDay(hour: 20, minute: 0));
    await Future<void>.delayed(const Duration(seconds: 2));
    calls.clear();
    await service.scheduleChallengeReminders();
    expect(idsOf('cancel'), [700]);
    expect(idsOf('zonedSchedule'), isEmpty);
    expect(service.challengeReminderTime('old'), isNull);
  });

  test('turning notifications off cancels the whole 700-799 range', () async {
    await LocalNotificationsService().cancelAll();
    final cancelled = idsOf('cancel').toSet();
    expect(cancelled.containsAll(List.generate(100, (i) => 700 + i)), isTrue);
    expect(cancelled.where((id) => id >= 600 && id < 700), isEmpty);
    expect(cancelled.where((id) => id >= 800), isEmpty);
  });

  test('challenge notifications from the server carry their challenge', () async {
    final db = FakeFirebaseFirestore();
    final inbox = db.collection('users').doc('u').collection('notifications');
    await inbox.add({
      'title': 'Ramadan Khatam',
      'body': 'Amina finished Juz 12 · 40%',
      'type': 'challenge',
      'challengeId': 'ch1',
      'isRead': false,
      'createdAt': DateTime(2026, 10, 9),
    });
    await inbox.add({'title': 'App update', 'isRead': true, 'createdAt': DateTime(2026, 10, 8)});
    final docs = (await inbox.orderBy('createdAt', descending: true).get()).docs.map(AppNotification.fromDoc).toList();
    expect(docs.first.challengeId, 'ch1');
    expect(docs.first.body, 'Amina finished Juz 12 · 40%');
    expect(docs.last.challengeId, isNull);
    expect(docs.last.body, '');
  });

  testWidgets('a daily reminder is set from the challenge screen', (tester) async {
    tester.view.physicalSize = const Size(360, 690) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    ChallengeService.logEvent = (_, __) {};
    final t = await AppLocalizations.delegate.load(const Locale('en'));
    final svc = ChallengeService(
        firestore: FakeFirebaseFirestore(),
        auth: MockFirebaseAuth(signedIn: true, mockUser: MockUser(uid: 'alice', displayName: 'Amina')));
    final c = await svc.create(NewChallenge(
        title: 'Durood',
        type: ChallengeType.dhikr,
        unit: ChallengeUnits.count,
        target: 1000,
        startAt: DateTime.now(),
        durationDays: 7));
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(360, 690),
      builder: (context, _) => GetMaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChallengeDetailScreen(challengeId: c.id, service: svc),
      ),
    ));
    await tester.pumpAndSettle();
    expect(isChallengeOpen(c.id), isTrue);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.challengesReminder));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(LocalNotificationsService().challengeReminderTime(c.id), const TimeOfDay(hour: 20, minute: 0));
    expect(find.text(t.challengesReminderSet('8:00 PM')), findsOneWidget);
    expect(idsOf('zonedSchedule'), [700]);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('${t.challengesReminder}: 8:00 PM'), findsOneWidget);
    await tester.tap(find.text(t.challengesReminderTurnOff));
    await tester.pumpAndSettle();
    expect(LocalNotificationsService().challengeReminderTime(c.id), isNull);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    expect(isChallengeOpen(c.id), isFalse);
  });
}
