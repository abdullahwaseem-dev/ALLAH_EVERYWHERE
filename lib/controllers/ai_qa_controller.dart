import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:allah_everywhere/services/ai_fatwa_service.dart';
import 'package:allah_everywhere/utils/utils/local_storage/storage.dart';
import 'package:allah_everywhere/utils/utils/logging/logger.dart';

/// Drives the Ask AI screen: sends questions to [AiFatwaService.instance]
/// and keeps a history of past Q&A (Firestore for signed-in users, local
/// storage for guests) so users have something like "saved questions"
/// without a separate screen.
class AiQaController extends GetxController {
  static const _guestStorageKey = 'guest_ai_questions';

  final RxList<AiAnswer> history = <AiAnswer>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  User? get _user => FirebaseAuth.instance.currentUser;

  CollectionReference<Map<String, dynamic>>? get _userCollection {
    final user = _user;
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('ai_questions');
  }

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final collection = _userCollection;
      if (collection != null) {
        final snapshot =
            await collection.orderBy('createdAt', descending: true).get();
        history.value =
            snapshot.docs.map((doc) => AiAnswer.fromMap(doc.data())).toList();
      } else {
        final stored =
            VoidStorage().readData<List<dynamic>>(_guestStorageKey) ?? [];
        history.value = stored
            .map((e) => AiAnswer.fromMap(Map<String, dynamic>.from(e as Map)))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      VoidLogger.error('Failed to load AI Q&A history', e);
    }
  }

  Future<void> askQuestion(String question, {String? category}) async {
    if (question.trim().isEmpty) return;

    isLoading.value = true;
    errorMessage.value = '';
    try {
      final answer =
          await AiFatwaService.instance.ask(question.trim(), category: category);
      history.insert(0, answer);
      await _persist(answer);
    } catch (e) {
      VoidLogger.error('AI Q&A request failed', e);
      errorMessage.value = 'Something went wrong. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _persist(AiAnswer answer) async {
    final collection = _userCollection;
    if (collection != null) {
      await collection.add(answer.toMap());
    } else {
      final stored =
          VoidStorage().readData<List<dynamic>>(_guestStorageKey) ?? [];
      stored.insert(0, answer.toMap());
      await VoidStorage().saveData(_guestStorageKey, stored);
    }
  }
}
