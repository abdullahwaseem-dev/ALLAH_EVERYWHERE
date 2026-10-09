import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:allah_everywhere/models/bookmark.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

/// Bookmarks are stored on the device first and mirrored to Firestore for
/// signed-in users.
///
/// Previously signed-in users wrote only to Firestore, so any Firestore
/// failure (security rules rejecting the `bookmarks` subcollection, being
/// offline, a timeout) surfaced as an "Exception: Could not save bookmark"
/// snackbar and an empty Bookmarks screen. Now the local copy is the source
/// of truth for the UI - saving always succeeds and is instant - and the
/// Firestore mirror is best-effort, retried on the next [list] call.
class BookmarkService {
  static const _guestStorageKey = 'guest_bookmarks';
  static const _remoteTimeout = Duration(seconds: 8);

  /// Null for guests, and when Firebase is unavailable (then bookmarks stay
  /// on the device, as for a guest).
  User? get _user {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Guests keep the original key (so existing guest bookmarks survive);
  /// each signed-in account gets its own, so two accounts on one device
  /// don't see each other's bookmarks.
  String get _storageKey {
    final user = _user;
    return user == null ? _guestStorageKey : 'bookmarks_${user.uid}';
  }

  /// Ids deleted locally whose Firestore delete hasn't gone through yet -
  /// without these, the next sync would pull the deleted bookmark back.
  String get _pendingDeleteKey => '${_storageKey}_pending_deletes';

  /// Ids saved locally whose Firestore write hasn't gone through yet. Only
  /// these are uploaded on sync, so a bookmark deleted on another device
  /// isn't resurrected from this device's copy.
  String get _pendingUploadKey => '${_storageKey}_pending_uploads';

  /// Accounts whose Firestore bookmarks have been pulled this session.
  static final Set<String> _syncedThisSession = {};

  CollectionReference<Map<String, dynamic>>? get _collection {
    final user = _user;
    if (user == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.uid).collection('bookmarks');
  }

  static String idFor(BookmarkType type, String refId) => '${type.name}_${refId.hashCode}';

  // ---------------------------------------------------------------------------
  // Local storage
  // ---------------------------------------------------------------------------

  List<Bookmark> _readLocal() {
    try {
      final stored = VoidStorage().readData<List<dynamic>>(_storageKey) ?? const [];
      return stored.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        return Bookmark.fromMap(map['id'] as String, map);
      }).toList();
    } catch (e) {
      VoidLogger.error('Stored bookmarks were unreadable; starting fresh', e);
      return [];
    }
  }

  Future<void> _writeLocal(List<Bookmark> bookmarks) {
    return VoidStorage().saveData(
      _storageKey,
      [for (final b in bookmarks) {'id': b.id, ...b.toMap()}],
    );
  }

  Set<String> _readIds(String key) =>
      (VoidStorage().readData<List<dynamic>>(key) ?? const []).cast<String>().toSet();

  Future<void> _writeIds(String key, Set<String> ids) => VoidStorage().saveData(key, ids.toList());

  Future<void> _updateIds(String key, void Function(Set<String>) change) {
    final ids = _readIds(key);
    change(ids);
    return _writeIds(key, ids);
  }

  List<Bookmark> _sorted(Iterable<Bookmark> bookmarks) =>
      bookmarks.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Local bookmarks, merged with Firestore when signed in. Never throws: if
  /// Firestore can't be reached the local list is returned as-is.
  Future<List<Bookmark>> list() async {
    final local = {for (final b in _readLocal()) b.id: b};
    final collection = _collection;
    if (collection == null) return _sorted(local.values);

    try {
      // Replay writes that failed earlier, deletes first so a deleted
      // bookmark can't come back in the merge below.
      for (final id in _readIds(_pendingDeleteKey)) {
        await collection.doc(id).delete().timeout(_remoteTimeout);
        await _updateIds(_pendingDeleteKey, (ids) => ids.remove(id));
      }
      for (final id in _readIds(_pendingUploadKey)) {
        final b = local[id];
        if (b != null) await collection.doc(id).set(b.toMap()).timeout(_remoteTimeout);
        await _updateIds(_pendingUploadKey, (ids) => ids.remove(id));
      }

      // Firestore is now authoritative: take its list as-is.
      final snapshot = await collection.get().timeout(_remoteTimeout);
      final merged = _sorted(snapshot.docs.map((d) => Bookmark.fromMap(d.id, d.data())));
      await _writeLocal(merged);
      _syncedThisSession.add(_storageKey);
      return merged;
    } catch (e) {
      VoidLogger.warning('Bookmark sync with Firestore failed, using device copy: $e');
      return _sorted(local.values);
    }
  }

  /// Answered from the device copy, so screens don't wait on the network
  /// just to draw the bookmark icon.
  Future<bool> isBookmarked(BookmarkType type, String refId) async {
    // First check for this account this session: pull from Firestore so
    // bookmarks made before this device kept a copy (or on another device)
    // show as bookmarked. list() never throws and falls back to local.
    if (_user != null && !_syncedThisSession.contains(_storageKey)) await list();
    final id = idFor(type, refId);
    return _readLocal().any((b) => b.id == id);
  }

  Future<void> add(BookmarkType type, String refId, String title, String subtitle) async {
    final bookmark = Bookmark(id: idFor(type, refId), type: type, refId: refId, title: title, subtitle: subtitle);
    final local = _readLocal()..removeWhere((b) => b.id == bookmark.id);
    await _writeLocal([bookmark, ...local]);

    final collection = _collection;
    if (collection == null) return;
    await _updateIds(_pendingDeleteKey, (ids) => ids.remove(bookmark.id));
    await _updateIds(_pendingUploadKey, (ids) => ids.add(bookmark.id));
    unawaited(_mirror(() async {
      await collection.doc(bookmark.id).set(bookmark.toMap());
      await _updateIds(_pendingUploadKey, (ids) => ids.remove(bookmark.id));
    }, 'save'));
  }

  Future<void> remove(String id) async {
    final local = _readLocal()..removeWhere((b) => b.id == id);
    await _writeLocal(local);

    final collection = _collection;
    if (collection == null) return;
    await _updateIds(_pendingUploadKey, (ids) => ids.remove(id));
    await _updateIds(_pendingDeleteKey, (ids) => ids.add(id));
    unawaited(_mirror(() async {
      await collection.doc(id).delete();
      await _updateIds(_pendingDeleteKey, (ids) => ids.remove(id));
    }, 'delete'));
  }

  /// Toggles the bookmark and returns the new bookmarked state.
  Future<bool> toggle(BookmarkType type, String refId, String title, String subtitle) async {
    if (await isBookmarked(type, refId)) {
      await remove(idFor(type, refId));
      return false;
    }
    await add(type, refId, title, subtitle);
    return true;
  }

  /// Runs a Firestore write in the background; a failure is only logged,
  /// since the next [list] call re-syncs from the device copy.
  Future<void> _mirror(Future<void> Function() write, String action) async {
    try {
      await write().timeout(_remoteTimeout);
    } catch (e) {
      VoidLogger.warning('Could not $action bookmark in Firestore (kept on device, will retry): $e');
    }
  }
}
