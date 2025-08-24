import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDataService {
  static final _firestore = FirebaseFirestore.instance;

  static String _docIdFromEmail(String email) => email.replaceAll('.', ',');

  // Make a safe document id for article identifiers (avoid '/' etc.)
  static String _safeDocId(String id) {
    // Use base64-url so the id contains only safe characters
    return base64Url.encode(utf8.encode(id));
  }

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
    // Save only articleId, mainCategory, subCategory using a safe doc id
    final safeId = _safeDocId(articleId);
    await userDoc.collection('bookmarks').doc(safeId).set({
      'articleId': articleId, // keep the original id in the doc payload
      'mainCategory': mainCategory,
      'subCategory': subCategory,
    });
    // Increment counters
    await userDoc.set({
      'bookmarkCount': FieldValue.increment(1),
      //'bookmarkCategoryCounts.$mainCategory': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // Remove bookmark and decrement counters (never below zero)
  static Future<void> removeBookmark(
      String email, String articleId, String mainCategory, String subCategory) async {
    final docId = _docIdFromEmail(email);
    final userDoc = _firestore.collection('userdata').doc(docId);
    final safeId = _safeDocId(articleId);

    // Remove the bookmark document
    await userDoc.collection('bookmarks').doc(safeId).delete();
    // Use transaction to prevent negative values for counters
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      final currentCount = (snapshot.data()?['bookmarkCount'] ?? 0) as int;
      final rawCategoryCounts = snapshot.data()?['bookmarkCategoryCounts'] ?? {};
      final categoryCounts = <String, int>{};
      (rawCategoryCounts as Map).forEach((key, value) {
        categoryCounts[key.toString()] = value;
      });
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
  // Add to history - ALWAYS INCREMENT (for repeated visits)
static Future<void> addHistory(String email, String articleId,
    String mainCategory, String subCategory) async {
  final docId = _docIdFromEmail(email);
  final userDoc = _firestore.collection('userdata').doc(docId);
  
  // Create a unique document for each visit using timestamp
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final uniqueId = '${_safeDocId(articleId)}_$timestamp';
  
  await userDoc.collection('history').doc(uniqueId).set({
    'articleId': articleId,
    'mainCategory': mainCategory,
    'subCategory': subCategory,
    'visitedAt': FieldValue.serverTimestamp(),
  });
  
  // Increment counters for every visit
  await userDoc.set({
    'historyCount': FieldValue.increment(1),
    //'historyCategoryCounts.$mainCategory': FieldValue.increment(1),
  }, SetOptions(merge: true));
}


  // Remove from history and decrement counters (never below zero)
  static Future<void> removeHistory(
      String email, String articleId, String mainCategory) async {
    final docId = _docIdFromEmail(email);
    final userDoc = _firestore.collection('userdata').doc(docId);
    final safeId = _safeDocId(articleId);
    await userDoc.collection('history').doc(safeId).delete();
    // Use transaction to prevent negative values
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDoc);
      final currentCount = (snapshot.data()?['historyCount'] ?? 0) as int;
      final categoryCounts = (snapshot.data()?['historyCategoryCounts'] ?? {})
          as Map;
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

  // NEW METHODS FOR SYNCING COUNTS

  // Sync bookmark counts to Firebase
  static Future<void> syncBookmarkCounts(
    String email,
    int totalCount,
    Map<String, int> mainCategoryCounts,
    Map<String, Map<String, int>> subCategoryCounts,
  ) async {
    final docId = _docIdFromEmail(email);
    await _firestore.collection('userdata').doc(docId).set({
      'email': email,
      'bookmarkCount': totalCount,
      'bookmarkCategoryCounts': mainCategoryCounts,
      'bookmarkSubCategoryCounts': subCategoryCounts,
      'lastBookmarkSync': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Sync history counts to Firebase
  static Future<void> syncHistoryCounts(
    String email,
    int totalCount,
    Map<String, int> mainCategoryCounts,
    Map<String, Map<String, int>> subCategoryCounts,
  ) async {
    final docId = _docIdFromEmail(email);
    await _firestore.collection('userdata').doc(docId).set({
      'email': email,
      'historyCount': totalCount,
      'historyCategoryCounts': mainCategoryCounts,
      'historySubCategoryCounts': subCategoryCounts,
      'lastHistorySync': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Clear all bookmarks (you might need this)
  static Future<void> clearAllBookmarks(String email) async {
    final docId = _docIdFromEmail(email);
    final userDoc = _firestore.collection('userdata').doc(docId);
    final bookmarksCollection = userDoc.collection('bookmarks');
    
    final snapshot = await bookmarksCollection.get();
    final batch = _firestore.batch();
    
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    
    // Reset counters to zero
    await userDoc.set({
      'bookmarkCount': 0,
      'bookmarkCategoryCounts': {},
      'bookmarkSubCategoryCounts': {},
    }, SetOptions(merge: true));
  }

  // Get user data (optional - for reading counts from Firebase)
  static Future<Map<String, dynamic>?> getUserData(String email) async {
    final docId = _docIdFromEmail(email);
    final doc = await _firestore.collection('userdata').doc(docId).get();
    return doc.data();
  }
}
