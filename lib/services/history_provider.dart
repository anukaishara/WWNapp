import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
    notifyListeners();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    _historyArticles.clear();
    await prefs.remove('history_articles');
    notifyListeners();
  }
}
