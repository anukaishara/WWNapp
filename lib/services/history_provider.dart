import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/user_data_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _historyArticles = [];
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  // Most recent first
  List<Map<String, dynamic>> get historyArticles => _historyArticles.reversed.toList();

  HistoryProvider() {
    _loadHistory();
  }

  // Load history from local storage
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('history_articles') ?? [];
    _historyArticles = data
        .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
        .toList();
    _isLoaded = true;
    notifyListeners();
  }

  // Add to history (local + Firestore)
  Future<void> addToHistory(Map<String, dynamic> article) async {
    final prefs = await SharedPreferences.getInstance();
    final articleId = article['docId'];
    final mainCategory = article['mainCategory'];
    final subCategory = article['subCategory'];
    final email = FirebaseAuth.instance.currentUser?.email;

    if (articleId == null || mainCategory == null || subCategory == null || email == null) return;

    // Remove duplicates by docId
    _historyArticles.removeWhere((item) => item['docId'] == articleId);
    _historyArticles.add(article);

    final updatedData = _historyArticles.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('history_articles', updatedData);

    // Firestore sync
    await UserDataService.addHistory(email, articleId, mainCategory, subCategory);

    notifyListeners();
  }

  // Remove a single article from history (local + Firestore)
  Future<void> removeFromHistory(Map<String, dynamic> article) async {
    final prefs = await SharedPreferences.getInstance();
    final articleId = article['docId'];
    final mainCategory = article['mainCategory'];
    final email = FirebaseAuth.instance.currentUser?.email;

    if (articleId == null || mainCategory == null || email == null) return;

    _historyArticles.removeWhere((item) => item['docId'] == articleId);

    final updatedData = _historyArticles.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('history_articles', updatedData);

    // Firestore sync
    await UserDataService.removeHistory(email, articleId, mainCategory);

    notifyListeners();
  }

  // Clear all history (local + Firestore)
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final email = FirebaseAuth.instance.currentUser?.email;
    _historyArticles.clear();
    await prefs.remove('history_articles');

    // Firestore sync
    if (email != null) {
      await UserDataService.clearHistory(email);
    }

    notifyListeners();
  }

  // (Optional) Set user preferences
  Future<void> setUserPreferences(Map<String, dynamic> preferences) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) {
      await UserDataService.setPreferences(email, preferences.values.map((e) => e.toString()).toList());
    }
  }
}
