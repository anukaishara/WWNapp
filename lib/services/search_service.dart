import 'package:cloud_firestore/cloud_firestore.dart';
//import "package:algolia_client_search";
import "advanced_search_service.dart";


class SearchService {
  static bool _isInitialized = false;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize the search service
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Initialize any search-related services here
      _isInitialized = true;
      print('🔍 SearchService initialized successfully');
    } catch (e) {
      print('❌ SearchService initialization failed: $e');
    }
  }

  /// Search articles in Firestore with multiple strategies
  static Future<List<Map<String, dynamic>>> searchArticles(String query) async {
    if (query.trim().isEmpty) return [];
    
    try {
      print('🔍 Searching for: "$query"');
      
      final lowercaseQuery = query.toLowerCase();
      final Set<String> uniqueArticleIds = {};
      final List<Map<String, dynamic>> results = [];

      // Strategy 1: Search by title (exact match first, then contains)
      await _searchByField('title', query, results, uniqueArticleIds, exact: true);
      await _searchByField('title', query, results, uniqueArticleIds, exact: false);

      // Strategy 2: Search by description
      await _searchByField('description', query, results, uniqueArticleIds, exact: false);

      // Strategy 3: Search by source
      await _searchByField('source', query, results, uniqueArticleIds, exact: false);

      // Strategy 4: Search by category
      await _searchByCategory(query, results, uniqueArticleIds);

      // Strategy 5: Full-text search simulation (search for individual words)
      if (results.length < 10) {
        await _searchByWords(query, results, uniqueArticleIds);
      }

      // Sort results by relevance (exact matches first, then by recency)
      results.sort((a, b) {
        // Prioritize exact title matches
        final aTitle = (a['title'] ?? '').toString().toLowerCase();
        final bTitle = (b['title'] ?? '').toString().toLowerCase();
        
        if (aTitle.contains(lowercaseQuery) && !bTitle.contains(lowercaseQuery)) {
          return -1;
        } else if (!aTitle.contains(lowercaseQuery) && bTitle.contains(lowercaseQuery)) {
          return 1;
        }

        // Then sort by published date (most recent first)
        final aDate = a['publishedAt'] as String?;
        final bDate = b['publishedAt'] as String?;
        
        if (aDate != null && bDate != null) {
          return bDate.compareTo(aDate);
        }
        
        return 0;
      });

      print('✅ Found ${results.length} search results for "$query"');
      return results.take(50).toList(); // Limit to 50 results
      
    } catch (e) {
      print('❌ Search error: $e');
      return [];
    }
  }

  /// Search by a specific field
  static Future<void> _searchByField(
    String field, 
    String query, 
    List<Map<String, dynamic>> results, 
    Set<String> uniqueIds, {
    bool exact = false
  }) async {
    try {
      Query<Map<String, dynamic>> firestoreQuery = _firestore.collection('articles');
      
      if (exact) {
        // Exact match search
        firestoreQuery = firestoreQuery
            .where(field, isEqualTo: query)
            .limit(10);
      } else {
        // Range query for "contains" functionality
        firestoreQuery = firestoreQuery
            .where(field, isGreaterThanOrEqualTo: query)
            .where(field, isLessThan: query + '\uf8ff')
            .limit(20);
      }

      final snapshot = await firestoreQuery.get();
      
      for (final doc in snapshot.docs) {
        final docId = doc.id;
        if (!uniqueIds.contains(docId)) {
          final data = doc.data();
          
          // Additional filtering for case-insensitive contains
          final fieldValue = (data[field] ?? '').toString().toLowerCase();
          if (fieldValue.contains(query.toLowerCase())) {
            uniqueIds.add(docId);
            results.add({
              ...data,
              'docId': docId,
            });
          }
        }
      }
    } catch (e) {
      print('❌ Error searching by $field: $e');
    }
  }

  /// Search by category (mainCategory and subCategory)
  static Future<void> _searchByCategory(
    String query, 
    List<Map<String, dynamic>> results, 
    Set<String> uniqueIds
  ) async {
    try {
      final lowercaseQuery = query.toLowerCase();
      
      // Search main categories
      final mainCategoryQuery = _firestore.collection('articles')
          .where('mainCategory', isGreaterThanOrEqualTo: query)
          .where('mainCategory', isLessThan: query + '\uf8ff')
          .limit(15);

      final mainSnapshot = await mainCategoryQuery.get();
      
      for (final doc in mainSnapshot.docs) {
        final docId = doc.id;
        if (!uniqueIds.contains(docId)) {
          final data = doc.data();
          final mainCat = (data['mainCategory'] ?? '').toString().toLowerCase();
          
          if (mainCat.contains(lowercaseQuery)) {
            uniqueIds.add(docId);
            results.add({
              ...data,
              'docId': docId,
            });
          }
        }
      }

      // Search sub categories
      final subCategoryQuery = _firestore.collection('articles')
          .where('subCategory', isGreaterThanOrEqualTo: query)
          .where('subCategory', isLessThan: query + '\uf8ff')
          .limit(15);

      final subSnapshot = await subCategoryQuery.get();
      
      for (final doc in subSnapshot.docs) {
        final docId = doc.id;
        if (!uniqueIds.contains(docId)) {
          final data = doc.data();
          final subCat = (data['subCategory'] ?? '').toString().toLowerCase();
          
          if (subCat.contains(lowercaseQuery)) {
            uniqueIds.add(docId);
            results.add({
              ...data,
              'docId': docId,
            });
          }
        }
      }
    } catch (e) {
      print('❌ Error searching by category: $e');
    }
  }

  /// Search by individual words in the query
  static Future<void> _searchByWords(
    String query, 
    List<Map<String, dynamic>> results, 
    Set<String> uniqueIds
  ) async {
    try {
      final words = query.toLowerCase().split(' ')
          .where((word) => word.length > 2)
          .take(3) // Limit to first 3 words
          .toList();

      for (final word in words) {
        if (results.length >= 30) break; // Stop if we have enough results
        
        await _searchByField('title', word, results, uniqueIds);
        await _searchByField('description', word, results, uniqueIds);
      }
    } catch (e) {
      print('❌ Error in word search: $e');
    }
  }

  /// Get search suggestions based on existing articles and popular searches
  static Future<List<String>> getSearchSuggestions(String query) async {
    if (query.length < 2) return [];
    
    try {
      final lowercaseQuery = query.toLowerCase();
      final Set<String> suggestions = {};
      
      // Get recent articles to extract suggestions from
      final snapshot = await _firestore.collection('articles')
          .orderBy('savedAt', descending: true)
          .limit(100)
          .get();
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        
        // Extract suggestions from title
        final title = (data['title'] ?? '').toString();
        _extractSuggestionsFromText(title, lowercaseQuery, suggestions);
        
        // Add source suggestions
        final source = (data['source'] ?? '').toString();
        if (source.toLowerCase().startsWith(lowercaseQuery)) {
          suggestions.add(source);
        }
        
        // Add category suggestions
        final mainCategory = (data['mainCategory'] ?? '').toString();
        final subCategory = (data['subCategory'] ?? '').toString();
        
        if (mainCategory.toLowerCase().startsWith(lowercaseQuery)) {
          suggestions.add(mainCategory);
        }
        
        if (subCategory.toLowerCase().startsWith(lowercaseQuery)) {
          suggestions.add(subCategory);
        }
        
        // Stop if we have enough suggestions
        if (suggestions.length >= 10) break;
      }
      
      // Add some common search terms
      final commonTerms = [
        'news', 'sports', 'business', 'technology', 'politics', 
        'entertainment', 'health', 'science', 'weather', 'local'
      ];
      
      for (final term in commonTerms) {
        if (term.startsWith(lowercaseQuery)) {
          suggestions.add(term);
        }
      }
      
      return suggestions.take(8).toList();
      
    } catch (e) {
      print('❌ Suggestions error: $e');
      return [];
    }
  }

  /// Extract word suggestions from text
  static void _extractSuggestionsFromText(
    String text, 
    String query, 
    Set<String> suggestions
  ) {
    final words = text.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2 && word.startsWith(query))
        .toSet();
    
    suggestions.addAll(words);
  }

  /// Index articles for search (called when new articles are saved)
  /// Index articles for search (called when new articles are saved)
static Future<void> indexArticles(List<Map<String, dynamic>> articles) async {
  try {
    // For Firestore-based search, articles are automatically indexed
    for (final article in articles) {
      await _createSearchKeywords(article);
    }
    
    // ALSO index in Algolia for advanced search
    try {
      await AdvancedSearchService.indexArticlesBatch(articles);
      print('✅ Articles also indexed in Algolia: ${articles.length}');
    } catch (e) {
      print('⚠️ Algolia indexing failed (continuing with Firestore): $e');
    }
    
    print('📝 Indexed ${articles.length} articles for search');
  } catch (e) {
    print('❌ Indexing error: $e');
  }
}


  /// Create search keywords for better searchability
  static Future<void> _createSearchKeywords(Map<String, dynamic> article) async {
    try {
      final title = (article['title'] ?? '').toString().toLowerCase();
      final description = (article['description'] ?? '').toString().toLowerCase();
      final source = (article['source'] ?? '').toString().toLowerCase();
      
      final Set<String> keywords = {};
      
      // Add words from title (most important)
      keywords.addAll(_extractKeywords(title, minLength: 3));
      
      // Add words from description
      keywords.addAll(_extractKeywords(description, minLength: 4));
      
      // Add source
      if (source.isNotEmpty) {
        keywords.add(source);
      }
      
      // Add categories
      final mainCat = article['mainCategory']?.toString().toLowerCase();
      final subCat = article['subCategory']?.toString().toLowerCase();
      
      if (mainCat != null) keywords.add(mainCat);
      if (subCat != null) keywords.add(subCat);
      
      // You could save these keywords back to the article document
      // if you want to implement more advanced search features
      
    } catch (e) {
      print('❌ Error creating keywords: $e');
    }
  }

  /// Extract keywords from text
  static Set<String> _extractKeywords(String text, {int minLength = 3}) {
    final stopWords = {
      'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with',
      'by', 'from', 'up', 'about', 'into', 'through', 'during', 'before',
      'after', 'above', 'below', 'between', 'among', 'this', 'that', 'these',
      'those', 'i', 'me', 'my', 'myself', 'we', 'our', 'ours', 'ourselves',
      'you', 'your', 'yours', 'yourself', 'he', 'him', 'his', 'himself',
      'she', 'her', 'hers', 'herself', 'it', 'its', 'itself', 'they', 'them',
      'their', 'theirs', 'themselves', 'what', 'which', 'who', 'whom', 'whose',
      'this', 'that', 'these', 'those', 'am', 'is', 'are', 'was', 'were',
      'be', 'been', 'being', 'have', 'has', 'had', 'having', 'do', 'does',
      'did', 'doing', 'will', 'would', 'could', 'should', 'may', 'might',
      'must', 'can', 'said', 'says', 'more'
    };
    
    return text
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => 
            word.length >= minLength && 
            !stopWords.contains(word.toLowerCase()) &&
            RegExp(r'^[a-zA-Z]+$').hasMatch(word))
        .map((word) => word.toLowerCase())
        .toSet();
  }

  /// Clear search cache/indexes (if needed)
  static Future<void> clearSearchCache() async {
    try {
      // Implement cache clearing logic if you add caching
      print('🧹 Search cache cleared');
    } catch (e) {
      print('❌ Error clearing search cache: $e');
    }
  }

  /// Get search statistics
  /// Get search statistics
static Future<Map<String, dynamic>> getSearchStats() async {
  try {
    final snapshot = await _firestore.collection('articles').get();
    
    final stats = {
      'totalArticles': snapshot.docs.length,
      'lastIndexed': DateTime.now().toIso8601String(),
      'categories': <String, int>{},
      'sources': <String, int>{},
    };
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      
      // Count categories - cast to proper Map type
      final mainCat = data['mainCategory']?.toString() ?? 'Unknown';
      final subCat = data['subCategory']?.toString() ?? 'Unknown';
      final categoryKey = '$mainCat-$subCat';
      
      final categoriesMap = stats['categories'] as Map<String, int>;
      categoriesMap[categoryKey] = (categoriesMap[categoryKey] ?? 0) + 1;
      
      // Count sources - cast to proper Map type
      final source = data['source']?.toString() ?? 'Unknown';
      final sourcesMap = stats['sources'] as Map<String, int>;
      sourcesMap[source] = (sourcesMap[source] ?? 0) + 1;
    }
    
    return stats;
  } catch (e) {
    print('❌ Error getting search stats: $e');
    return {};
  }
}
}
