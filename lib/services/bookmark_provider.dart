import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BookmarkProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _bookmarkedArticles = [];
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  List<Map<String, dynamic>> get bookmarkedArticles => _bookmarkedArticles;

  BookmarkProvider() {
    _loadBookmarks();
  }

  // Load bookmarks from local storage
  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('bookmarked_articles') ?? [];
    _bookmarkedArticles = data
        .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
        .toList();
    _isLoaded = true;
    notifyListeners();
  }

  // Toggle bookmark (add/remove) locally
  Future<void> toggleBookmark(Map<String, dynamic> article) async {
    final articleId = article['docId'];
    if (articleId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final isBookmarked = _bookmarkedArticles.any((item) => item['docId'] == articleId);

    if (isBookmarked) {
      _bookmarkedArticles.removeWhere((item) => item['docId'] == articleId);
    } else {
      _bookmarkedArticles.add(article);
    }

    final updatedData = _bookmarkedArticles.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('bookmarked_articles', updatedData);
    notifyListeners();
  }

  // Check if an article is bookmarked
  bool isBookmarked(Map<String, dynamic> article) {
    final articleId = article['docId'];
    return _bookmarkedArticles.any((item) => item['docId'] == articleId);
  }

  // Remove a bookmark explicitly
  Future<void> removeBookmark(Map<String, dynamic> article) async {
    final articleId = article['docId'];
    final prefs = await SharedPreferences.getInstance();
    _bookmarkedArticles.removeWhere((item) => item['docId'] == articleId);
    final updatedData = _bookmarkedArticles.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('bookmarked_articles', updatedData);
    notifyListeners();
  }

  // Clear all bookmarks
  Future<void> clearBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    _bookmarkedArticles.clear();
    await prefs.remove('bookmarked_articles');
    notifyListeners();
  }
}
