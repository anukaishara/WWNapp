import 'package:cloud_firestore/cloud_firestore.dart';

class UserDataService {
  static final _firestore = FirebaseFirestore.instance;

  static String _docIdFromEmail(String email) => email.replaceAll('.', ',');

  // Set or update preferences (initial or from profile)
  static Future<void> setPreferences(String email, List<String> preferences) async {
    final docId = _docIdFromEmail(email);
    await _firestore.collection('userdata').doc(docId).set({
      'email': email,
      'preferences': preferences,
    }, SetOptions(merge: true));
  }

  // Add bookmark
  static Future<void> addBookmark(String email, String articleId, String mainCategory, String subCategory) async {
    final docId = _docIdFromEmail(email);
    final userDoc = _firestore.collection('userdata').doc(docId);

    // Save only articleId, mainCategory, subCategory
    await userDoc.collection('bookmarks').doc(articleId).set({
      'articleId': articleId,
      'mainCategory': mainCategory,
      'subCategory': subCategory,
    });
  }

  // Remove bookmark
  static Future<void> removeBookmark(String email, String articleId, String mainCategory) async {
    final docId = _docIdFromEmail(email);
    final userDoc = _firestore.collection('userdata').doc(docId);

    await userDoc.collection('bookmarks').doc(articleId).delete();

    await userDoc.set({
      'bookmarkCount': FieldValue.increment(-1),
      'bookmarkCategoryCounts.$mainCategory': FieldValue.increment(-1),
    }, SetOptions(merge: true));
  }

  // Add to history
  static Future<void> addHistory(String email, String articleId, String mainCategory, String subCategory) async {
    final docId = _docIdFromEmail(email);
    final userDoc = _firestore.collection('userdata').doc(docId);

    await userDoc.collection('history').doc(articleId).set({
      'articleId': articleId,
      'mainCategory': mainCategory,
      'subCategory': subCategory,
    });

    await userDoc.set({
      'historyCount': FieldValue.increment(1),
      'historyCategoryCounts.$mainCategory': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // Remove from history
  static Future<void> removeHistory(String email, String articleId, String mainCategory) async {
    final docId = _docIdFromEmail(email);
    final userDoc = _firestore.collection('userdata').doc(docId);

    await userDoc.collection('history').doc(articleId).delete();

    await userDoc.set({
      'historyCount': FieldValue.increment(-1),
      'historyCategoryCounts.$mainCategory': FieldValue.increment(-1),
    }, SetOptions(merge: true));
  }
}