import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/user_data_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final articleId = article['docId'];
    final mainCategory = article['mainCategory'];
    final subCategory = article['subCategory'];
    final prefs = await SharedPreferences.getInstance();
    final isBookmarked = _bookmarkedArticles
        .any((item) => item['title'] == article['title']);
    final email = FirebaseAuth.instance.currentUser?.email;

    if (isBookmarked) {
      _bookmarkedArticles.removeWhere((item) => item['title'] == article['title']);
      if (email != null && articleId != null && mainCategory != null) {
        await removeBookmarkFromUserData(email, articleId, mainCategory);
      }
    } else {
      _bookmarkedArticles.add(article);
      if (email != null && articleId != null && mainCategory != null && subCategory != null) {
        print('Bookmark Firestore: $email, $articleId, $mainCategory, $subCategory');
        await addBookmarkToUserData(email, articleId, mainCategory, subCategory);
      }
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

  Future<void> addBookmarkToUserData(String email, String articleId, String mainCategory, String subCategory) async {
    await UserDataService.addBookmark(email, articleId, mainCategory, subCategory);
  }

  Future<void> setPreferences(String email, Map<String, dynamic> preferences) async {
    // Convert preferences map to a JSON string and wrap it in a list
    List<String> preferencesList = [jsonEncode(preferences)];
    // Assuming UserDataService is a service class that handles user data operations
    await UserDataService.setPreferences(email, preferencesList);
    // Update the UI or perform any other actions needed after setting the preferences
  }

  Future<void> removeBookmarkFromUserData(String email, String articleId, String mainCategory) async {
    await UserDataService.removeBookmark(email, articleId, mainCategory);
  }
}

// If you need to set preferences for the current user, create a function like this:
Future<void> setCurrentUserPreferences(Map<String, dynamic> preferences) async {
  final email = FirebaseAuth.instance.currentUser?.email;
  if (email != null) {
    List<String> preferencesList = [jsonEncode(preferences)];
    await UserDataService.setPreferences(email, preferencesList);
  }
}
