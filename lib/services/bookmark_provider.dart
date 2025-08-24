import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_data_service.dart';
import 'dart:convert';

class BookmarkProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _bookmarkedArticles = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<Map<String, dynamic>> get bookmarkedArticles => _bookmarkedArticles;

  // Count variables for local access (optional)
  Map<String, int> bookmarkMainCategoryCounts = {};
  Map<String, Map<String, int>> bookmarkSubCategoryCounts = {};
  int bookmarkTotalCount = 0;

  BookmarkProvider() {
    _loadBookmarks();
  }

  // Pick a unique ID (prefer docId, fallback to url, fallback to title)
  String? _getArticleId(Map<String, dynamic> article) {
    return article['docId'] ?? article['url'] ?? article['title'];
  }

  // Load bookmarks from local storage
  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('bookmarked_articles') ?? [];
    _bookmarkedArticles = data
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .toList();
    _isLoaded = true;
    await _syncCountsToFirebase(); // Sync counts when loading
    notifyListeners();
  }

  // Toggle bookmark (add/remove)
  Future<void> toggleBookmark(Map<String, dynamic> article) async {
    final articleId = _getArticleId(article);
    if (articleId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final email = FirebaseAuth.instance.currentUser?.email;
    final mainCategory = article['mainCategory'] as String?;
    final subCategory = article['subCategory'] as String?;

    final isBookmarked = _bookmarkedArticles.any((item) => _getArticleId(item) == articleId);

    if (isBookmarked) {
      _bookmarkedArticles.removeWhere((item) => _getArticleId(item) == articleId);
      // Remove from Firebase
      if (email != null && mainCategory != null && subCategory != null) {
        await UserDataService.removeBookmark(email, articleId, mainCategory, subCategory);
      }
    } else {
      _bookmarkedArticles.add(article);
      // Add to Firebase
      if (email != null && mainCategory != null && subCategory != null) {
        await UserDataService.addBookmark(email, articleId, mainCategory, subCategory);
      }
    }

    final updatedData = _bookmarkedArticles.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('bookmarked_articles', updatedData);
    
    await _syncCountsToFirebase(); // Sync counts after change
    notifyListeners();
  }

  // Check if an article is bookmarked
  bool isBookmarked(Map<String, dynamic> article) {
    final articleId = _getArticleId(article);
    return _bookmarkedArticles.any((item) => _getArticleId(item) == articleId);
  }

  // Remove a bookmark
  Future<void> removeBookmark(Map<String, dynamic> article) async {
    final articleId = _getArticleId(article);
    if (articleId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final email = FirebaseAuth.instance.currentUser?.email;
    final mainCategory = article['mainCategory'] as String?;
    final subCategory = article['subCategory'] as String?;

    _bookmarkedArticles.removeWhere((item) => _getArticleId(item) == articleId);

    // Remove from Firebase
    if (email != null && mainCategory != null && subCategory != null) {
      await UserDataService.removeBookmark(email, articleId, mainCategory, subCategory);
    }

    final updatedData = _bookmarkedArticles.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('bookmarked_articles', updatedData);
    
    await _syncCountsToFirebase(); // Sync counts after change
    notifyListeners();
  }

  // Clear all bookmarks
  Future<void> clearBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final email = FirebaseAuth.instance.currentUser?.email;

    _bookmarkedArticles.clear();
    await prefs.remove('bookmarked_articles');
    
    // Clear all bookmarks from Firebase
    if (email != null) {
      await UserDataService.clearAllBookmarks(email);
    }
    
    await _syncCountsToFirebase(); // Sync counts after clearing
    notifyListeners();
  }

  // Update local counts and sync to Firebase
  void updateBookmarkCounts(List<Map<String, dynamic>> bookmarks) {
    bookmarkMainCategoryCounts.clear();
    bookmarkSubCategoryCounts.clear();
    bookmarkTotalCount = bookmarks.length;

    for (var article in bookmarks) {
      final main = article['mainCategory'] ?? 'Unknown';
      final sub = article['subCategory'] ?? 'Unknown';
      
      // Main category count
      bookmarkMainCategoryCounts[main] = (bookmarkMainCategoryCounts[main] ?? 0) + 1;
      
      // Subcategory count
      bookmarkSubCategoryCounts[main] ??= {};
      bookmarkSubCategoryCounts[main]![sub] = (bookmarkSubCategoryCounts[main]![sub] ?? 0) + 1;
    }
  }

  // Sync local counts to Firebase
  Future<void> _syncCountsToFirebase() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    // Calculate counts
    updateBookmarkCounts(_bookmarkedArticles);

    // Sync to Firebase
    await UserDataService.syncBookmarkCounts(
      email, 
      bookmarkTotalCount, 
      bookmarkMainCategoryCounts, 
      bookmarkSubCategoryCounts
    );
  }
}
