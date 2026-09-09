import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

class AppNotification {
  final String id;
  final String title;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.isRead,
  });

  factory AppNotification.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return AppNotification(
      id: doc.id,
      title: data['title'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }
}

/// Reads real notifications from `users/{uid}/notifications`. This replaces
/// the previous screen, which showed entirely hardcoded mock entries
/// (including un-filled template text like "[specific Fiqh issue]") for
/// every user regardless of what actually happened in their account.
class NotificationsController extends GetxController {
  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  final RxBool isLoading = true.obs;

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  CollectionReference<Map<String, dynamic>>? get _collection {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.uid).collection('notifications');
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      final collection = _collection;
      if (collection == null) {
        notifications.value = [];
        return;
      }
      final snapshot = await collection.orderBy('createdAt', descending: true).get();
      notifications.value = snapshot.docs.map(AppNotification.fromDoc).toList();
    } catch (e) {
      VoidLogger.error('Failed to load notifications', e);
    } finally {
      isLoading.value = false;
    }
  }

  List<AppNotification> search(String query) {
    if (query.isEmpty) return notifications;
    return notifications.where((n) => n.title.toLowerCase().contains(query.toLowerCase())).toList();
  }
}
