import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/user_data_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _historyArticles = [];

  List<Map<String, dynamic>> get historyArticles => _historyArticles.reversed.toList();

  HistoryProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('history_articles') ?? [];
    _historyArticles = data
        .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
        .toList();
    notifyListeners();
  }

  Future<void> addToHistory(Map<String, dynamic> article) async {
    final prefs = await SharedPreferences.getInstance();
    // Remove duplicates (by title or better by url/id)
    _historyArticles.removeWhere((item) => item['title'] == article['title']);
    _historyArticles.add(article);
    final updatedData =
        _historyArticles.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('history_articles', updatedData);
    
    // Assuming these values are available in the context
    String email = article['email'];
    String articleId = article['docId']; // Firestore document ID
    String mainCategory = article['mainCategory'];
    String subCategory = article['subCategory'];
    
    await UserDataService.addHistory(email, articleId, mainCategory, subCategory);
    
    notifyListeners();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _historyArticles.clear();
    await prefs.remove('history_articles');
    notifyListeners();
  }

  Future<void> removeFromHistory(String articleId, String mainCategory, String email) async {
    await UserDataService.removeHistory(email, articleId, mainCategory);
    notifyListeners();
  }

  // Method to set user preferences
  Future<void> setUserPreferences(Map<String, dynamic> preferences) async {
    // Get current user's email
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) {
      // Convert preferences Map to a List<String> if required by setPreferences
      await UserDataService.setPreferences(email, preferences.values.map((e) => e.toString()).toList());
    }
  }
}
