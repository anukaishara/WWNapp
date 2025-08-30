import 'package:cloud_firestore/cloud_firestore.dart';
import 'api_service.dart';
import 'scraping.dart';

class ForYouService {
  /// Fetches recommended news articles for the user based on Firestore recommendation percentages.
  /// [userEmail] - user's email
  /// [totalArticles] - total number of articles to fetch
  /// Returns a list of articles, each as a Map<String, dynamic>.
  static Future<List<Map<String, dynamic>>> fetchRecommendedNews(
    String userEmail, {
    int totalArticles = 30,
  }) async {
    if (userEmail.trim().isEmpty) {
      // ignore: avoid_print
      print('[ForYouService] Empty userEmail; cannot fetch recommendations.');
      return [];
    }
    final firestore = FirebaseFirestore.instance;
    final docId = userEmail.replaceAll('.', ',');
    // ignore: avoid_print
    print('[ForYouService] Loading recommendations for docId="$docId"');
    final userDoc = await firestore.collection('userdata').doc(docId).get();
    if (!userDoc.exists) {
      // ignore: avoid_print
      print('[ForYouService] No userdata doc for "$docId".');
      return [];
    }
    final recommendations = Map<String, dynamic>.from(
      (userDoc.data()?['recommendations'] as Map<String, dynamic>?) ?? {},
    );
    // ignore: avoid_print
    print(
        '[ForYouService] Found ${recommendations.length} recommendation categories');
    List<Map<String, dynamic>> allArticles = [];

    // Allocate counts via floor + largest remainder to hit totalArticles exactly
    final allocations = <String, int>{};
    final remainders = <String, double>{};
    int assigned = 0;
    recommendations.forEach((category, data) {
      final percent =
          ((data as Map<String, dynamic>)['percentage'] as num?) ?? 0;
      final exact = (percent.toDouble() / 100.0) * totalArticles;
      final base = exact.floor();
      allocations[category] = base;
      remainders[category] = exact - base;
      assigned += base;
    });
    int remaining = totalArticles - assigned;
    final sorted = remainders.keys.toList()
      ..sort((a, b) => remainders[b]!.compareTo(remainders[a]!));
    for (var i = 0; i < remaining && i < sorted.length; i++) {
      allocations[sorted[i]] = (allocations[sorted[i]] ?? 0) + 1;
    }
    // ignore: avoid_print
    print('[ForYouService] Allocations: ${allocations.entries.map((e) => '${e.key}=${e.value}').join(', ')}');

    final seenIds = <String>{};
    final seenUrls = <String>{};
    for (final entry in allocations.entries) {
      final category = entry.key; // e.g., "Local-Top"
      final count = entry.value;
      if (count <= 0) continue;
      final parts = category.split('-');
      if (parts.length != 2) continue;
      final mainCat = parts[0];
      final subCat = parts[1];

      final articles = await _fetchArticlesFromFirestore(
        mainCategory: mainCat,
        subCategory: subCat,
        limit: count,
      );
      // ignore: avoid_print
      print(
          '[ForYouService] Query $mainCat-$subCat -> got ${articles.length} docs');
      var addedThisCategory = 0;
      for (final a in articles) {
        final id = (a['docId'] as String?) ?? '';
        final url = (a['url'] as String?) ?? '';
        final isDup = (id.isNotEmpty && seenIds.contains(id)) ||
            (url.isNotEmpty && seenUrls.contains(url));
        if (!isDup) {
          allArticles.add(a);
          if (id.isNotEmpty) seenIds.add(id);
          if (url.isNotEmpty) seenUrls.add(url);
          addedThisCategory++;
        }
        if (allArticles.length >= totalArticles || addedThisCategory >= count) {
          break;
        }
      }

      // If Firestore has no/insufficient docs for this category, try to hydrate from source
      if (addedThisCategory < count) {
        final needed = count - addedThisCategory;
        // ignore: avoid_print
        print(
            '[ForYouService] Need $needed more for $mainCat-$subCat; hydrating from source');
        List<Map<String, dynamic>> fresh = [];
        if (mainCat == 'Foreign') {
          final query = _foreignCategoryToQuery[subCat] ?? 'news';
          fresh = await ApiService.fetchAndDisplayArticles(
            query: query,
            mainCategory: mainCat,
            subCategory: subCat,
          );
        } else if (mainCat == 'Local') {
          fresh = await scrapeLocalCategory(subCat);
        }
        // Take up to needed
        for (final a in fresh) {
          final id = (a['docId'] as String?) ?? '';
          final url = (a['url'] as String?) ?? '';
          final isDup = (id.isNotEmpty && seenIds.contains(id)) ||
              (url.isNotEmpty && seenUrls.contains(url));
          if (!isDup) {
            allArticles.add(a);
            if (id.isNotEmpty) seenIds.add(id);
            if (url.isNotEmpty) seenUrls.add(url);
            addedThisCategory++;
          }
          if (allArticles.length >= totalArticles || addedThisCategory >= count) {
            break;
          }
        }
      }
    }

    // Optionally shuffle for variety
    allArticles.shuffle();
    // ignore: avoid_print
    print('[ForYouService] Total selected articles: ${allArticles.length}');
    return allArticles.take(totalArticles).toList();
  }

  /// Helper to fetch articles from Firestore for a given category
  static Future<List<Map<String, dynamic>>> _fetchArticlesFromFirestore({
    required String mainCategory,
    required String subCategory,
    int? limit,
  }) async {
    Query query = FirebaseFirestore.instance
        .collection('articles')
        .where('mainCategory', isEqualTo: mainCategory)
        .where('subCategory', isEqualTo: subCategory);
    try {
      query = query.orderBy('publishedAt', descending: true);
    } catch (_) {
      // ignore
    }
    if (limit != null && limit > 0) query = query.limit(limit);
    QuerySnapshot snapshot;
    try {
      snapshot = await query.get();
    } on FirebaseException catch (e) {
      // Likely missing index or mixed field types; retry without orderBy
      // ignore: avoid_print
      print(
          '[ForYouService] Query failed with orderBy (code=${e.code}). Retrying without orderBy.');
      Query fallback = FirebaseFirestore.instance
          .collection('articles')
          .where('mainCategory', isEqualTo: mainCategory)
          .where('subCategory', isEqualTo: subCategory);
      if (limit != null && limit > 0) fallback = fallback.limit(limit);
      snapshot = await fallback.get();
    }
    return snapshot.docs
        .map((doc) => {...doc.data() as Map<String, dynamic>, 'docId': doc.id})
        .toList();
  }
}

// Simple mapping for foreign categories to API query topics
const Map<String, String> _foreignCategoryToQuery = {
  'Top': 'news',
  'Sports': 'sports',
  'Business': 'business',
  'Technology': 'technology',
  'Politics': 'politics',
  'Entertainment': 'entertainment',
};
