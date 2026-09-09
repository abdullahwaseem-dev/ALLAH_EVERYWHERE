import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

/// Account deletion: reauthenticate, remove the Firestore user document,
/// then delete the Firebase Auth account itself. Firestore's own
/// `ai_questions` subcollection under the user doc is left for the user
/// to also clear via a Cloud Function later if needed - Firestore does not
/// cascade-delete subcollections automatically.
class AccountService {
  Future<void> deleteAccount({required String currentPassword}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No signed-in user to delete.');
    }

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
    } catch (e) {
      VoidLogger.error('Failed to delete Firestore user document', e);
    }

    await user.delete();
  }
}
