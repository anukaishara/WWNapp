import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Abstract provider for any news API
abstract class NewsApiProvider {
  Future<List<Map<String, dynamic>>> fetchArticles({String query});
  String get sourceName;
}

/// NewsAPI.org
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

/// World News API
class WorldNewsApiProvider implements NewsApiProvider {
  static const String apiKey = 'c380091d738941968aeaeea942d64e18';

  @override
  String get sourceName => "WorldNewsAPI";

  @override
  Future<List<Map<String, dynamic>>> fetchArticles({String query = 'news'}) async {
    final categoryMap = {
      'sports': 'sports',
      'business': 'business',
      'technology': 'technology',
      'politics': 'politics',
      'entertainment': 'entertainment',
      'world': 'world',
      'news': '',
    };
    final worldNewsCategory = categoryMap[query.toLowerCase()] ?? '';

    final params = {
      'api-key': apiKey,
      'number': '30',
      'language': 'en',
      if (worldNewsCategory.isNotEmpty) 'categories': worldNewsCategory,
      if (query.isNotEmpty && worldNewsCategory.isEmpty) 'text': query,
      'sort': 'publish-time',
      'sort-direction': 'desc',
    };
    final uri = Uri.https('api.worldnewsapi.com', '/api/v1/news', params);

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final articles = data['news'] as List<dynamic>? ?? [];
      return articles.map((article) => {
        'title': article['title'],
        'description': article['text'],
        'url': article['url'],
        'urlToImage': article['image'],
        'publishedAt': article['publish_date'],
        'content': article['text'],
        'source': article['source']['title'],
      }).toList();
    } else {
      throw Exception('Failed to fetch news from WorldNewsAPI: ${response.statusCode}');
    }
  }
}

/// TheNewsAPI
class TheNewsApiProvider implements NewsApiProvider {
  static const String apiKey = '9zbNyzlS8WyT8JRanPHp8WLjbbQKPBxRila4d5gm';

  @override
  String get sourceName => "TheNewsAPI";

  @override
  Future<List<Map<String, dynamic>>> fetchArticles({String query = 'news'}) async {
    final categoryMap = {
      'sports': 'sports',
      'business': 'business',
      'technology': 'technology',
      'politics': 'politics',
      'entertainment': 'entertainment',
      'world': 'world',
      'news': '',
    };
    final theNewsApiCategory = categoryMap[query.toLowerCase()] ?? '';

    final params = {
      'api_token': apiKey,
      'language': 'en',
      'search': query,
      'limit': '30',
      if (theNewsApiCategory.isNotEmpty) 'category': theNewsApiCategory,
    };
    final uri = Uri.https('api.thenewsapi.com', '/v1/news/all', params);

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final articles = data['data'] as List<dynamic>? ?? [];
      return articles.map((article) => {
        'title': article['title'],
        'description': article['description'],
        'url': article['url'],
        'urlToImage': article['image_url'],
        'publishedAt': article['published_at'],
        'content': article['snippet'],
        'source': article['source'],
      }).toList();
    } else {
      throw Exception('Failed to fetch news from TheNewsAPI: ${response.statusCode}');
    }
  }
}

/// NewsData.io
class NewsDataIoProvider implements NewsApiProvider {
  static const String apiKey = 'pub_6580414afc87d4733c4607b8a544a03698fbd';

  @override
  String get sourceName => "NewsData.io";

  @override
  Future<List<Map<String, dynamic>>> fetchArticles({String query = 'news'}) async {
    final categoryMap = {
      'sports': 'sports',
      'business': 'business',
      'technology': 'technology',
      'politics': 'politics',
      'entertainment': 'entertainment',
      'world': 'world',
      'news': '',
    };
    final newsDataCategory = categoryMap[query.toLowerCase()] ?? '';

    final params = {
      'apikey': apiKey,
      'language': 'en',
      'q': query,
      'country': 'us',
      if (newsDataCategory.isNotEmpty) 'category': newsDataCategory,
      'page': '0',
      'size': '30',
    };
    final uri = Uri.https('newsdata.io', '/api/1/news', params);

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final articles = data['results'] as List<dynamic>? ?? [];
      return articles.map((article) => {
        'title': article['title'],
        'description': article['description'],
        'url': article['link'],
        'urlToImage': article['image_url'],
        'publishedAt': article['pubDate'],
        'content': article['content'],
        'source': article['source_id'],
      }).toList();
    } else {
      throw Exception('Failed to fetch news from NewsData.io: ${response.statusCode}');
    }
  }
}

/// GNews.io
class GNewsProvider implements NewsApiProvider {
  static const String apiKey = '66042106e5a13686fe3136698ea2e8c2';

  @override
  String get sourceName => "GNews.io";

  @override
  Future<List<Map<String, dynamic>>> fetchArticles({String query = 'news'}) async {
    final categoryMap = {
      'sports': 'sports',
      'business': 'business',
      'technology': 'technology',
      'politics': 'politics',
      'entertainment': 'entertainment',
      'world': 'world',
      'news': '',
    };
    final gnewsCategory = categoryMap[query.toLowerCase()] ?? '';

    final params = {
      'token': apiKey,
      'lang': 'en',
      'max': '30',
      if (gnewsCategory.isNotEmpty) 'topic': gnewsCategory,
      'q': query,
    };
    final uri = Uri.https('gnews.io', '/api/v4/search', params);

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final articles = data['articles'] as List<dynamic>? ?? [];
      return articles.map((article) => {
        'title': article['title'],
        'description': article['description'],
        'url': article['url'],
        'urlToImage': article['image'],
        'publishedAt': article['publishedAt'],
        'content': article['content'],
        'source': article['source']['name'],
      }).toList();
    } else {
      throw Exception('Failed to fetch news from GNews.io: ${response.statusCode}');
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
    WorldNewsApiProvider(),
    TheNewsApiProvider(),
    NewsDataIoProvider(),
    GNewsProvider(),
  ]);

  /// Fetch articles from all APIs, deduplicate, show instantly, save to Firestore in background
  static Future<List<Map<String, dynamic>>> fetchAndDisplayArticles({String query = 'news'}) async {
    final articles = await aggregator.fetchAllArticles(query: query);

    // Remove duplicates by URL before returning to UI
    final uniqueArticles = <String, Map<String, dynamic>>{};
    for (final article in articles) {
      if (article['url'] != null && !uniqueArticles.containsKey(article['url'])) {
        uniqueArticles[article['url']] = article;
      }
    }

    // Save to Firestore in background (do not await)
    saveArticlesToFirestore(uniqueArticles.values.toList(), query);

    // Return unique articles instantly for UI display
    return uniqueArticles.values.toList();
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
