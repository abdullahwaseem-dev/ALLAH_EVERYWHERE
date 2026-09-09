import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

/// Persists the Tasbeeh counter so it survives app restarts (it used to
/// reset every time) and keeps a real lifetime total that Profile can show
/// instead of the old hardcoded "656".
class TasbeehService {
  static const _lifetimeKey = 'tasbeeh_lifetime_total';

  int get lifetimeTotal => VoidStorage().readData<int>(_lifetimeKey) ?? 0;

  Future<void> addToLifetimeTotal(int delta) async {
    if (delta <= 0) return;
    final newTotal = lifetimeTotal + delta;
    await VoidStorage().saveData(_lifetimeKey, newTotal);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {'tasbeehTotal': FieldValue.increment(delta)},
          SetOptions(merge: true),
        );
      } catch (e) {
        VoidLogger.error('Failed to sync Tasbeeh total to Firestore', e);
      }
    }
  }
}
