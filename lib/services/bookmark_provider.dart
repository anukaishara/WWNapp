import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BookmarkProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _bookmarkedArticles = [];

  List<Map<String, dynamic>> get bookmarkedArticles => _bookmarkedArticles;

  BookmarkProvider() {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('bookmarked_articles') ?? [];
    _bookmarkedArticles = data
        .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
        .toList();
    notifyListeners();
  }

  Future<void> toggleBookmark(Map<String, dynamic> article) async {
    final prefs = await SharedPreferences.getInstance();
    final isBookmarked = _bookmarkedArticles
        .any((item) => item['title'] == article['title']);
    if (isBookmarked) {
      _bookmarkedArticles
          .removeWhere((item) => item['title'] == article['title']);
    } else {
      _bookmarkedArticles.add(article);
    }
    final updatedData =
        _bookmarkedArticles.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('bookmarked_articles', updatedData);
    notifyListeners();
  }

  bool isBookmarked(Map<String, dynamic> article) {
    return _bookmarkedArticles
        .any((item) => item['title'] == article['title']);
  }

  Future<void> removeBookmark(Map<String, dynamic> article) async {
    final prefs = await SharedPreferences.getInstance();
    _bookmarkedArticles
        .removeWhere((item) => item['title'] == article['title']);
    final updatedData =
        _bookmarkedArticles.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('bookmarked_articles', updatedData);
    notifyListeners();
  }

  Future<void> clearBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    _bookmarkedArticles.clear();
    await prefs.remove('bookmarked_articles');
    notifyListeners();
  }
}
