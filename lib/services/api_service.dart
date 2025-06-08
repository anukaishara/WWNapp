import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ApiService {
  static const String apiKey = '0d2ecc02247c42369c263622a1d38ca7';

  static Future<void> fetchAndSaveArticles({String query = 'news'}) async {
    final url = Uri.parse(
      'https://newsapi.org/v2/everything?q=$query&apiKey=$apiKey&sortBy=publishedAt',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final articles = data['articles'] as List<dynamic>;

      final firestore = FirebaseFirestore.instance;
      final collection = firestore.collection('articles');

      for (final article in articles) {
        // Optional: Avoid duplicates using the article URL or title
        if (article['url'] != null) {
          final existing = await collection.where('url', isEqualTo: article['url']).get();
          if (existing.docs.isEmpty) {
            await collection.add({
              'title': article['title'],
              'description': article['description'],
              'url': article['url'],
              'urlToImage': article['urlToImage'],
              'publishedAt': article['publishedAt'],
              'content': article['content'],
              'source': article['source']['name'],
              'category': query,
              'savedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      print("✅ Articles saved to Firestore.");
    } else {
      throw Exception('Failed to fetch news from NewsAPI: ${response.statusCode}');
    }
  }
}

// Add this new class to handle user-specific data
class UserDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save user preferences
  static Future<void> saveUserPreferences(String userId, List<String> preferences) async {
    await _firestore.collection('userData').doc(userId).set({
      'preferences': preferences,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> saveBookmark(String userId, String articleId) async {
    await _firestore
        .collection('userData')
        .doc(userId)
        .collection('bookmarks')
        .doc(articleId)
        .set({
      'savedAt': FieldValue.serverTimestamp(),
    });
  }


  // Remove bookmark for a user
  static Future<void> removeBookmark(String userId, String articleUrl) async {
    await _firestore
        .collection('userData')
        .doc(userId)
        .collection('bookmarks')
        .doc(articleUrl)
        .delete();
  }

  // Get user preferences
  static Future<List<String>> getUserPreferences(String userId) async {
    final doc = await _firestore.collection('userData').doc(userId).get();


    return List<String>.from(doc.data()?['preferences'] ?? []);
  }

  static Future<List<String>> getUserBookmarks(String userId) async {
    final query = await _firestore
        .collection('userData')
        .doc(userId)
        .collection('bookmarks')
        .get();
    return query.docs.map((doc) => doc.id).toList();
  }
}