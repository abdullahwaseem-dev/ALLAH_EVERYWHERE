import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:allah_everywhere/models/bookmark.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

/// Same dual-mode pattern as AiQaController: Firestore for signed-in users,
/// local storage for guests, so bookmarking works either way.
class BookmarkService {
  static const _guestStorageKey = 'guest_bookmarks';

  User? get _user => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>>? get _collection {
    final user = _user;
    if (user == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.uid).collection('bookmarks');
  }

  Future<List<Bookmark>> list() async {
    try {
      final collection = _collection;
      if (collection != null) {
        final snapshot = await collection.orderBy('createdAt', descending: true).get();
        return snapshot.docs.map((d) => Bookmark.fromMap(d.id, d.data())).toList();
      }
      final stored = VoidStorage().readData<List<dynamic>>(_guestStorageKey) ?? [];
      final bookmarks = stored
          .map((e) {
            final map = Map<String, dynamic>.from(e as Map);
            return Bookmark.fromMap(map['id'] as String, map);
          })
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return bookmarks;
    } catch (e) {
      VoidLogger.error('Failed to load bookmarks', e);
      return [];
    }
  }

  Future<bool> isBookmarked(BookmarkType type, String refId) async {
    final all = await list();
    return all.any((b) => b.type == type && b.refId == refId);
  }

  Future<void> add(BookmarkType type, String refId, String title, String subtitle) async {
    final id = '${type.name}_${refId.hashCode}';
    final bookmark = Bookmark(id: id, type: type, refId: refId, title: title, subtitle: subtitle);

    final collection = _collection;
    if (collection != null) {
      await collection.doc(id).set(bookmark.toMap());
    } else {
      final stored = VoidStorage().readData<List<dynamic>>(_guestStorageKey) ?? [];
      stored.removeWhere((e) => (e as Map)['id'] == id);
      stored.insert(0, {'id': id, ...bookmark.toMap()});
      await VoidStorage().saveData(_guestStorageKey, stored);
    }
  }

  Future<void> remove(String id) async {
    final collection = _collection;
    if (collection != null) {
      await collection.doc(id).delete();
    } else {
      final stored = VoidStorage().readData<List<dynamic>>(_guestStorageKey) ?? [];
      stored.removeWhere((e) => (e as Map)['id'] == id);
      await VoidStorage().saveData(_guestStorageKey, stored);
    }
  }

  Future<void> toggle(BookmarkType type, String refId, String title, String subtitle) async {
    final id = '${type.name}_${refId.hashCode}';
    if (await isBookmarked(type, refId)) {
      await remove(id);
    } else {
      await add(type, refId, title, subtitle);
    }
  }
}
