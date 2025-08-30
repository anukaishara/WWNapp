import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_data_service.dart';
import 'dart:convert';
import '../services/recommendation_service.dart';


class HistoryProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _historyArticles = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  
  // UI DISPLAY - Show unique articles only (most recent first)
  List<Map<String, dynamic>> get historyArticles {
    final seen = <String>{};
    return _historyArticles.reversed.where((article) {
      final docId = article['docId'];
      if (docId != null && !seen.contains(docId)) {
        seen.add(docId);
        return true;
      }
      return false;
    }).toList();
  }

  // INTERNAL - All visits including duplicates (for counting)
  List<Map<String, dynamic>> get _allHistoryVisits => _historyArticles;

  // Count variables for local access
  Map<String, int> historyMainCategoryCounts = {};
  Map<String, Map<String, int>> historySubCategoryCounts = {};
  int historyTotalCount = 0;

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
    await _syncCountsToFirebase(); // Sync counts when loading
    notifyListeners();
  }

  // Add to history - COUNT EVERY VISIT, but display unique only
  Future<void> addToHistory(Map<String, dynamic> article) async {
    final prefs = await SharedPreferences.getInstance();
    final articleId = article['docId'];
    final mainCategory = article['mainCategory'];
    final subCategory = article['subCategory'];
    final email = FirebaseAuth.instance.currentUser?.email;

    debugPrint('addToHistory called: docId=$articleId, mainCategory=$mainCategory, subCategory=$subCategory, email=$email');

    if (articleId == null || mainCategory == null || subCategory == null || email == null) {
      debugPrint('addToHistory aborted: missing required fields');
      return;
    }

    // ADD TIMESTAMP TO DISTINGUISH MULTIPLE VISITS
    final articleWithTimestamp = {
      ...article,
      'visitedAt': DateTime.now().millisecondsSinceEpoch,
    };

    // ALWAYS ADD - DON'T REMOVE DUPLICATES! (for counting)
    _historyArticles.add(articleWithTimestamp);
    
    final updatedData = _historyArticles.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('history_articles', updatedData);
    
    // Add to Firebase - this will increment counts for every visit
    await UserDataService.addHistory(email, articleId, mainCategory, subCategory);
    await _syncCountsToFirebase();
    // ******
    await RecommendationService.updateUserRecommendations(email);
  
    notifyListeners();
  }

  // Remove a specific article visit from history
  Future<void> removeFromHistory(Map<String, dynamic> article) async {
    final prefs = await SharedPreferences.getInstance();
    final articleId = article['docId'];
    final mainCategory = article['mainCategory'];
    final email = FirebaseAuth.instance.currentUser?.email;

    if (articleId == null || mainCategory == null || email == null) return;

    // Remove the specific entry (by timestamp if available)
    final visitedAt = article['visitedAt'];
    if (visitedAt != null) {
      _historyArticles.removeWhere((item) => 
          item['docId'] == articleId && item['visitedAt'] == visitedAt);
    } else {
      // Fallback: remove the first matching article
      final index = _historyArticles.indexWhere((item) => item['docId'] == articleId);
      if (index != -1) {
        _historyArticles.removeAt(index);
      }
    }
    
    final updatedData = _historyArticles.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('history_articles', updatedData);
    
    await UserDataService.removeHistory(email, articleId, mainCategory);
    await _syncCountsToFirebase();
    // *****
    await RecommendationService.updateUserRecommendations(email);
  
    notifyListeners();
  }

  // Remove ALL visits of a specific article
  Future<void> removeAllVisitsOfArticle(String articleId) async {
    final prefs = await SharedPreferences.getInstance();
    final email = FirebaseAuth.instance.currentUser?.email;

    if (email == null) return;

    // Count how many times this article was visited (for Firebase decrement)
    final visitsCount = _historyArticles.where((item) => item['docId'] == articleId).length;
    final firstVisit = _historyArticles.firstWhere((item) => item['docId'] == articleId);
    final mainCategory = firstVisit['mainCategory'];

    // Remove all visits of this article
    _historyArticles.removeWhere((item) => item['docId'] == articleId);
    
    final updatedData = _historyArticles.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('history_articles', updatedData);
    
    // Remove from Firebase (this should be called once for each visit)
    for (int i = 0; i < visitsCount; i++) {
      await UserDataService.removeHistory(email, articleId, mainCategory);
    }
    
    await _syncCountsToFirebase();
    // *****
    await RecommendationService.updateUserRecommendations(email);
  
    notifyListeners();
  }

  // Clear all history
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final email = FirebaseAuth.instance.currentUser?.email;

    _historyArticles.clear();
    await prefs.remove('history_articles');

    if (email != null) {
      await UserDataService.clearHistory(email);
    }

    await _syncCountsToFirebase();
    // ******
    if (email != null) {
      await RecommendationService.updateUserRecommendations(email);
    }


    notifyListeners();
  }

  // Update local counts - COUNT ALL ENTRIES INCLUDING DUPLICATES
  void updateHistoryCounts(List<Map<String, dynamic>> historyArticles) {
    historyMainCategoryCounts.clear();
    historySubCategoryCounts.clear();
    historyTotalCount = historyArticles.length; // This includes all visits

    // Count every entry, including multiple visits to same article
    for (var article in historyArticles) {
      final main = article['mainCategory'] ?? 'Unknown';
      final sub = article['subCategory'] ?? 'Unknown';
      
      // Main category count
      historyMainCategoryCounts[main] = (historyMainCategoryCounts[main] ?? 0) + 1;
      
      // Subcategory count
      historySubCategoryCounts[main] ??= {};
      historySubCategoryCounts[main]![sub] = (historySubCategoryCounts[main]![sub] ?? 0) + 1;
    }
  }

  // Sync local counts to Firebase
  Future<void> _syncCountsToFirebase() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    // Calculate counts using ALL visits (including duplicates)
    updateHistoryCounts(_allHistoryVisits);

    // Sync to Firebase
    await UserDataService.syncHistoryCounts(
      email, 
      historyTotalCount, 
      historyMainCategoryCounts, 
      historySubCategoryCounts
    );
  }

  // Get visit count for a specific article
  int getArticleVisitCount(String articleId) {
    return _historyArticles.where((item) => item['docId'] == articleId).length;
  }

  // Get last visit time for a specific article
  DateTime? getLastVisitTime(String articleId) {
    final visits = _historyArticles.where((item) => item['docId'] == articleId);
    if (visits.isEmpty) return null;
    
    final lastVisit = visits.reduce((a, b) => 
        (a['visitedAt'] ?? 0) > (b['visitedAt'] ?? 0) ? a : b);
    
    final timestamp = lastVisit['visitedAt'];
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  // (Optional) Set user preferences
  Future<void> setUserPreferences(Map<String, dynamic> preferences) async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) {
      await UserDataService.setPreferences(email, preferences.values.map((e) => e.toString()).toList());
    }
  }
}
