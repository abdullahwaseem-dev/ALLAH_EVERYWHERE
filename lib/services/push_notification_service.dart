import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/challenges.dart';
import 'package:allah_everywhere/utils/utils/constraints/colors.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

/// Push notification plumbing: requests permission, stores the device's
/// FCM token on the user's Firestore doc (with the app language, time zone
/// and the Challenges notification switch, which the Cloud Functions in
/// functions/ use to pick the text and timing), and opens the right screen
/// when a push is tapped.
///
/// Challenge pushes are written to the in-app notification center by the
/// server; other pushes are stored here when Settings "Updates" is on.
class PushNotificationService {
  static bool _initialized = false;

  static const challengeNotificationsKey = 'challenge_notifications_enabled';
  static const _languageKey = 'app_language_code';

  /// Settings "Challenge notifications" (on by default).
  static bool get challengeNotificationsEnabled => VoidStorage().readData<bool>(challengeNotificationsKey) ?? true;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      final token = await messaging.getToken();
      await _saveToken(token);
      messaging.onTokenRefresh.listen(_saveToken);
      // Signing in later (or switching accounts) also needs the token.
      FirebaseAuth.instance.authStateChanges().skip(1).listen((user) async {
        if (user != null) await _saveToken(await messaging.getToken());
      });

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        _storeIncomingMessage(message);
        _open(message);
      });
      // A tap on a push that started the app.
      final initial = await messaging.getInitialMessage();
      if (initial != null) _open(initial);
    } catch (e) {
      VoidLogger.error('Failed to initialize push notifications', e);
    }
  }

  Future<void> _saveToken(String? token) async {
    if (token == null) return;
    await syncProfile(token: token);
  }

  /// Writes what the server needs to the user's doc: the token (if given),
  /// language, time zone and the Challenges switch. Best effort.
  Future<void> syncProfile({String? token}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String? timeZone;
    try {
      timeZone = await FlutterTimezone.getLocalTimezone();
    } catch (_) {}
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {
          if (token != null) 'fcmToken': token,
          'language': VoidStorage().readData<String>(_languageKey) ?? 'en',
          if (timeZone != null) 'timeZone': timeZone,
          'challengeNotifications': challengeNotificationsEnabled,
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      VoidLogger.error('Failed to save FCM token', e);
    }
  }

  /// Settings "Challenge notifications": saved here and on the user's doc,
  /// so the server stops (or resumes) challenge pushes and reminders.
  Future<void> setChallengeNotifications(bool enabled) async {
    await VoidStorage().saveData(challengeNotificationsKey, enabled);
    await syncProfile();
  }

  static bool _isChallenge(RemoteMessage message) =>
      message.data['type'] == 'challenge' && (message.data['challengeId'] as String?)?.isNotEmpty == true;

  void _open(RemoteMessage message) {
    if (_isChallenge(message)) openChallenge(message.data['challengeId'] as String);
  }

  /// FCM shows nothing while the app is open, so a challenge push becomes
  /// a small banner (tap to open), unless that challenge is on screen.
  void _onForegroundMessage(RemoteMessage message) {
    if (!_isChallenge(message)) {
      _storeIncomingMessage(message);
      return;
    }
    final id = message.data['challengeId'] as String;
    if (isChallengeOpen(id)) return;
    final dark = Get.isDarkMode;
    Get.snackbar(
      message.notification?.title ?? '',
      message.notification?.body ?? '',
      onTap: (_) => openChallenge(id),
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(12),
      backgroundColor: dark ? VoidColors.cardDark : VoidColors.cardLight,
      colorText: dark ? VoidColors.textDarkPrimary : VoidColors.oliveDeep,
    );
  }

  Future<void> _storeIncomingMessage(RemoteMessage message) async {
    // The server already adds challenge pushes to the notification center.
    if (_isChallenge(message)) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Respect the Settings "Updates" toggle - content/app-update pushes are
    // opt-in, separate from the local prayer/reminder notifications.
    final updatesEnabled = VoidStorage().readData<bool>('updates_enabled') ?? false;
    if (!updatesEnabled) return;
    final title = message.notification?.title ?? message.data['title'] as String? ?? 'Notification';
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': title,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      VoidLogger.error('Failed to store incoming push notification', e);
    }
  }
}
