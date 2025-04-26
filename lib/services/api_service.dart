import 'package:http/http.dart' as http;
import 'dart:convert';
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