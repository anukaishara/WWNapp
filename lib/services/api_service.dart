import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Abstract provider for any news API
abstract class NewsApiProvider {
  Future<List<Map<String, dynamic>>> fetchArticles({String query});
  String get sourceName;
}

/// Implementation for NewsAPI.org
class NewsApiOrgProvider implements NewsApiProvider {
  static const String apiKey = '0d2ecc02247c42369c263622a1d38ca7';

  @override
  String get sourceName => "NewsAPI.org";

  @override
  Future<List<Map<String, dynamic>>> fetchArticles({String query = 'news'}) async {
    final url = Uri.parse(
      'https://newsapi.org/v2/everything?q=$query&apiKey=$apiKey&sortBy=publishedAt',
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final articles = data['articles'] as List<dynamic>;
      return articles.map((article) => {
        'title': article['title'],
        'description': article['description'],
        'url': article['url'],
        'urlToImage': article['urlToImage'],
        'publishedAt': article['publishedAt'],
        'content': article['content'],
        'source': article['source']['name'],
      }).toList();
    } else {
      throw Exception('Failed to fetch news from NewsAPI: ${response.statusCode}');
    }
  }
}

/// Aggregator for multiple providers
class NewsAggregator {
  final List<NewsApiProvider> providers;
  NewsAggregator(this.providers);

  Future<List<Map<String, dynamic>>> fetchAllArticles({String query = 'news'}) async {
    List<Map<String, dynamic>> allArticles = [];
    for (final provider in providers) {
      try {
        final articles = await provider.fetchArticles(query: query);
        allArticles.addAll(articles.map((a) => {...a, 'apiSource': provider.sourceName}));
      } catch (e) {
        print("❌ Error fetching from ${provider.sourceName}: $e");
      }
    }
    return allArticles;
  }
}

/// Main service for fetching and saving articles
class ApiService {
  static final NewsAggregator aggregator = NewsAggregator([
    NewsApiOrgProvider(),
    // Add more providers here
  ]);

  /// Fetch articles from all APIs, show instantly, save to Firestore in background
  static Future<List<Map<String, dynamic>>> fetchAndDisplayArticles({String query = 'news'}) async {
    final articles = await aggregator.fetchAllArticles(query: query);

    // Save to Firestore in background (do not await)
    saveArticlesToFirestore(articles, query);

    // Return articles instantly for UI display
    return articles;
  }

  /// Save articles to Firestore, avoid duplicates by URL
  static Future<void> saveArticlesToFirestore(List<Map<String, dynamic>> articles, String query) async {
    final firestore = FirebaseFirestore.instance;
    final collection = firestore.collection('articles');

    WriteBatch batch = firestore.batch();

    for (final article in articles) {
      if (article['url'] != null) {
        final existing = await collection.where('url', isEqualTo: article['url']).limit(1).get();
        if (existing.docs.isEmpty) {
          final docRef = collection.doc();
          batch.set(docRef, {
            ...article,
            'category': query,
            'savedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }

    await batch.commit();
    print("✅ Articles saved to Firestore.");
  }
}
