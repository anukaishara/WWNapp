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
  notifyListeners();
}

  // Toggle bookmark (add/remove)
  Future<void> toggleBookmark(Map<String, dynamic> article) async {
    final articleId = _getArticleId(article);
    if (articleId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final isBookmarked =
        _bookmarkedArticles.any((item) => _getArticleId(item) == articleId);

    if (isBookmarked) {
      _bookmarkedArticles.removeWhere((item) => _getArticleId(item) == articleId);
    } else {
      _bookmarkedArticles.add(article);
    }

    final updatedData =
        _bookmarkedArticles.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('bookmarked_articles', updatedData);
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
    _bookmarkedArticles.removeWhere((item) => _getArticleId(item) == articleId);

    final updatedData =
        _bookmarkedArticles.map((item) => jsonEncode(item)).toList();
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
