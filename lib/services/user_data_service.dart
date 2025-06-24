import 'package:cloud_firestore/cloud_firestore.dart';

class UserDataService {
  static final _firestore = FirebaseFirestore.instance;

  static String _docIdFromEmail(String email) => email.replaceAll('.', ',');

  // Set or update preferences (initial or from profile)
  static Future<void> setPreferences(
      String email, List<String> preferences) async {
    final docId = _docIdFromEmail(email);
    await _firestore.collection('userdata').doc(docId).set({
      'email': email,
      'preferences': preferences,
    }, SetOptions(merge: true));
  }

  // Add bookmark and increment counters
  static Future<void> addBookmark(String email, String articleId,
      String mainCategory, String subCategory) async {
    final docId = _docIdFromEmail(email);
    final userDoc = _firestore.collection('userdata').doc(docId);

    // Save only articleId, mainCategory, subCategory
    await userDoc.collection('bookmarks').doc(articleId).set({
      'articleId': articleId,
      'mainCategory': mainCategory,
      'subCategory': subCategory,
    });

    // Increment counters
    await userDoc.set({
      'bookmarkCount': FieldValue.increment(1),
      'bookmarkCategoryCounts.$mainCategory': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // Remove bookmark and decrement counters (never below zero)
  static Future<void> removeBookmark(
      String email, String articleId, String mainCategory) async {
    final docId = _docIdFromEmail(email);
    final userDoc = _firestore.collection('userdata').doc(docId);

    await userDoc.collection('bookmarks').doc(articleId).delete();

    // Use transaction to prevent negative values
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      final currentCount = (snapshot.data()?['bookmarkCount'] ?? 0) as int;
      final categoryCounts = (snapshot.data()?['bookmarkCategoryCounts'] ?? {})
          as Map<String, dynamic>;
      final currentCategoryCount = (categoryCounts[mainCategory] ?? 0) as int;

      final newCount = currentCount > 0 ? currentCount - 1 : 0;
      final newCategoryCount =
          currentCategoryCount > 0 ? currentCategoryCount - 1 : 0;

      transaction.update(userDoc, {
        'bookmarkCount': newCount,
        'bookmarkCategoryCounts.$mainCategory': newCategoryCount,
      });
    });
  }

  // Add to history and increment counters
  static Future<void> addHistory(String email, String articleId,
      String mainCategory, String subCategory) async {
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

  // Remove from history and decrement counters (never below zero)
  static Future<void> removeHistory(
      String email, String articleId, String mainCategory) async {
    final docId = _docIdFromEmail(email);
    final userDoc = _firestore.collection('userdata').doc(docId);

    await userDoc.collection('history').doc(articleId).delete();

    // Use transaction to prevent negative values
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      final currentCount = (snapshot.data()?['historyCount'] ?? 0) as int;
      final categoryCounts = (snapshot.data()?['historyCategoryCounts'] ?? {})
          as Map<String, dynamic>;
      final currentCategoryCount = (categoryCounts[mainCategory] ?? 0) as int;

      final newCount = currentCount > 0 ? currentCount - 1 : 0;
      final newCategoryCount =
          currentCategoryCount > 0 ? currentCategoryCount - 1 : 0;

      transaction.update(userDoc, {
        'historyCount': newCount,
        'historyCategoryCounts.$mainCategory': newCategoryCount,
      });
    });
  }

  // Clear all history
  static Future<void> clearHistory(String email) async {
    final docId = _docIdFromEmail(email);
    final userDoc = _firestore.collection('userdata').doc(docId);
    final historyCollection = userDoc.collection('history');
    final snapshot = await historyCollection.get();
    final batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Optionally reset counters to zero
    await userDoc.set({
      'historyCount': 0,
      'historyCategoryCounts': {},
    }, SetOptions(merge: true));
  }
}
