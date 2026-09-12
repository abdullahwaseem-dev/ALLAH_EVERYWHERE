import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

/// Push notification plumbing: requests permission, stores the device's
/// FCM token on the user's Firestore doc, and writes incoming messages into
/// `users/{uid}/notifications` so they show up in the in-app notification
/// center. Actually *sending* a push still requires a backend (e.g. a
/// Cloud Function calling the FCM API) - that part isn't built here.
class PushNotificationService {
  static bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      final token = await messaging.getToken();
      await _saveToken(token);
      messaging.onTokenRefresh.listen(_saveToken);

      FirebaseMessaging.onMessage.listen(_storeIncomingMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_storeIncomingMessage);
    } catch (e) {
      VoidLogger.error('Failed to initialize push notifications', e);
    }
  }

  Future<void> _saveToken(String? token) async {
    if (token == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        {'fcmToken': token},
        SetOptions(merge: true),
      );
    } catch (e) {
      VoidLogger.error('Failed to save FCM token', e);
    }
  }

  Future<void> _storeIncomingMessage(RemoteMessage message) async {
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
