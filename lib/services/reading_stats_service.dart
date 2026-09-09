import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

/// Tracks real reading activity so Profile can show a genuine "Hadith Read"
/// count instead of the old hardcoded "47".
class ReadingStatsService {
  static const _hadithReadKey = 'hadith_read_count';

  int get hadithReadCount => VoidStorage().readData<int>(_hadithReadKey) ?? 0;

  Future<void> incrementHadithRead() async {
    final newCount = hadithReadCount + 1;
    await VoidStorage().saveData(_hadithReadKey, newCount);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
          {'hadithReadCount': FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      } catch (e) {
        VoidLogger.error('Failed to sync hadith read count to Firestore', e);
      }
    }
  }
}
