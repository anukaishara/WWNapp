import 'dart:async';
import 'dart:convert';
import 'package:algolia_client_search/algolia_client_search.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;


class AdvancedSearchService {
  // Algolia Configuration
  static const String _applicationId = 'IUI9P7QUBL';
  static const String _searchApiKey = '0fc9f3b716842e155364ac93bf4b6ccc';
  static const String _adminApiKey = 'ad2b49b4f6112b45d1c9c0921f709490';
  
  // Index Configuration
  static const String _articlesIndexName = 'articles';
  static const String _suggestionsIndexName = 'suggestions';
  
  // Algolia Client
  static SearchClient? _client;
  
  // Search State Management
  static Timer? _debounceTimer;
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  static final List<StreamSubscription> _subscriptions = [];
  
  // Cache Management
  static const int _maxCacheSize = 1000;
  static const Duration _cacheExpiry = Duration(hours: 24);
  static final Map<String, CachedSearchResult> _searchCache = {};
  static bool _isOnline = true;
  
  /// Initialize Algolia Search Service
  static Future<void> initialize() async {
    try {
      // Initialize Algolia client
      _client = SearchClient(
        appId: _applicationId,
        apiKey: _searchApiKey,
      );
      
      // Setup connectivity monitoring
      _monitorConnectivity();
      
      // Load cached data
      await _loadCachedData();
      
    } catch (e) {
      await _initializeOfflineMode();
    }
  }
  
  /// Advanced article search with comprehensive filtering
  static Future<SearchResults> searchArticles({
    required String query,
    Map<String, List<String>>? filters,
    Map<String, String>? numericFilters,
    List<String>? facets,
    int page = 0,
    int hitsPerPage = 20,
    String? userToken,
    bool enablePersonalization = true,
    SortBy sortBy = SortBy.relevance,
  }) async {
    final cacheKey = _generateCacheKey(query, filters, numericFilters, page, sortBy);
    
    // Check cache first
    final cached = _searchCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.results;
    }
    
    // Fallback to offline search if not connected
    if (!_isOnline) {
      return await _searchOffline(query, filters);
    }
    
    try {
      // Build facet filters
      List<List<String>>? facetFilters;
      if (filters != null && filters.isNotEmpty) {
        facetFilters = _buildFacetFilters(filters);
      }
      
      // Build numeric filters
      List<String>? numericFiltersList;
      if (numericFilters != null && numericFilters.isNotEmpty) {
        numericFiltersList = numericFilters.entries
            .map((e) => '${e.key}${e.value}')
            .toList();
      }
      
      // Create search parameters
      final searchParams = SearchParamsObject(
        query: query,
        page: page,
        hitsPerPage: hitsPerPage,
        attributesToRetrieve: [
          'title',
          'description',
          'content',
          'url',
          'urlToImage',
          'publishedAt',
          'source',
          'mainCategory',
          'subCategory',
          'docId',
          'tags',
          'viewCount',
          'shareCount',
          'readingTime',
        ],
        attributesToHighlight: ['title', 'description', 'content'],
        attributesToSnippet: ['description:50', 'content:100'],
        facets: facets ?? ['mainCategory', 'subCategory', 'source'],
        facetFilters: facetFilters,
        numericFilters: numericFiltersList,
        typoTolerance: true,
        getRankingInfo: true,
        clickAnalytics: true,
        analytics: true,
        analyticsTags: ['mobile', 'search'],
        enablePersonalization: enablePersonalization,
        userToken: userToken,
      );
      
      // Execute search
      final response = await _client!.searchSingleIndex(
        indexName: _articlesIndexName,
        searchParams: searchParams,
      );
      
      // Parse results
      final results = SearchResults(
        hits: response.hits.map((hit) => _parseHit(hit)).toList(),
        totalHits: response.nbHits ?? 0,
        totalPages: response.nbPages ?? 0,
        currentPage: response.page ?? 0,
        facets: response.facets ?? {},
        processingTime: response.processingTimeMS ?? 0,
        query: query,
        queryID: response.queryID,
        userToken: userToken,
      );
      
      // Cache results
      _cacheResults(cacheKey, results);
      
      // Track analytics
      await _trackSearchAnalytics(query, results.totalHits, userToken);
      

      return results;
      
    } catch (e) {
      return await _searchOffline(query, filters);
    }
  }
  
  /// Real-time search with debouncing
  static void searchRealTime({
    required String query,
    required Function(SearchResults) onResults,
    required Function(String) onError,
    Map<String, List<String>>? filters,
    String? userToken,
    int hitsPerPage = 10,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDelay, () async {
      try {
        final results = await searchArticles(
          query: query,
          filters: filters,
          userToken: userToken,
          hitsPerPage: hitsPerPage,
        );
        onResults(results);
      } catch (e) {
        onError('Search failed: $e');
      }
    });
  }
  
  /// Get advanced search suggestions
  static Future<List<SearchSuggestion>> getAdvancedSuggestions({
    required String query,
    int maxSuggestions = 10,
    List<String>? categories,
    String? userToken,
  }) async {
    if (query.length < 2) return [];
    
    try {
      final suggestions = <SearchSuggestion>[];
      
      // Get query suggestions from articles
      final searchParams = SearchParamsObject(
        query: query,
        hitsPerPage: 5,
        attributesToRetrieve: ['title', 'mainCategory', 'subCategory'],
        typoTolerance: true,
      );
      
      final response = await _client!.searchSingleIndex(
        indexName: _articlesIndexName,
        searchParams: searchParams,
      );
      
      // Extract suggestions from titles
      for (final hit in response.hits) {
        final title = hit['title']?.toString() ?? '';
        
        if (title.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(SearchSuggestion(
            text: title,
            type: SuggestionType.query,
            category: hit['mainCategory']?.toString(),
          ));
        }
      }
      
      // Add category suggestions
      suggestions.addAll(await _getCategorySuggestions(query));
      
      // Add trending suggestions
      suggestions.addAll(await _getTrendingSuggestions(query));
      
      // Add recent search suggestions
      suggestions.addAll(await _getRecentSearchSuggestions(query));
      
      // Remove duplicates and limit results
      final uniqueSuggestions = suggestions.toSet().take(maxSuggestions).toList();
      
      return uniqueSuggestions;
      
    } catch (e) {
      return await _getOfflineSuggestions(query);
    }
  }
  
  /// Index articles for search (Note: This requires admin API key and should be done server-side)
  /// Index articles for search (requires proper objectID and admin access)
static Future<void> indexArticlesBatch(
  List<Map<String, dynamic>> articles,
) async {
  if (articles.isEmpty) return;
  
  try {
    final adminClient = SearchClient(
      appId: _applicationId,
      apiKey: _adminApiKey,
    );
    
    // FIXED: Truncate large content to fit within 10KB limit
    final objectsToIndex = articles.map((article) {
      String content = article['content']?.toString() ?? '';
      String description = article['description']?.toString() ?? '';
      
      // Truncate content if too large (keep under 8KB to allow for other fields)
      if (content.length > 6000) {
        content = '${content.substring(0, 6000)}...';
      }
      if (description.length > 500) {
        description = '${description.substring(0, 500)}...';
      }
      
      return {
        'objectID': article['docId'] ?? article['url'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'title': article['title'] ?? '',
        'description': description,
        'content': content,
        'url': article['url'] ?? '',
        'urlToImage': article['urlToImage'],
        'publishedAt': article['publishedAt'],
        'source': article['source'] ?? '',
        'mainCategory': article['mainCategory'] ?? '',
        'subCategory': article['subCategory'] ?? '',
        'tags': article['tags'] ?? [],
        'readingTime': article['readingTime'] ?? 0,
      };
    }).toList();
    
    
    const batchSize = 100;
    for (int i = 0; i < objectsToIndex.length; i += batchSize) {
      final batch = objectsToIndex.sublist(
        i, 
        math.min(i + batchSize, objectsToIndex.length)
      );
      
      final batchRequests = batch.map((obj) => 
        BatchRequest(
          action: Action.addObject,
          body: obj,
        )
      ).toList();
      
      final batchWriteParams = BatchWriteParams(
        requests: batchRequests,
      );
      
      final response = await adminClient.batch(
        indexName: _articlesIndexName,
        batchWriteParams: batchWriteParams,
      );
      
    }
    
    
  } catch (e) {
    rethrow;
  }
}


/// Test function to upload sample data
static Future<void> uploadTestData() async {
  final testArticles = [
    {
      'docId': 'test-1',
      'title': 'Test Article About Technology',
      'description': 'This is a test article for searching',
      'content': 'Sample content for testing Algolia search functionality',
      'source': 'Test Source',
      'mainCategory': 'Technology',
      'subCategory': 'Mobile',
      'publishedAt': DateTime.now().toIso8601String(),
      'readingTime': 2,
    },
    {
      'docId': 'test-2',
      'title': 'Sample News Article',
      'description': 'Another test article',
      'content': 'More sample content for Algolia testing',
      'source': 'Sample News',
      'mainCategory': 'Local',
      'subCategory': 'Top',
      'publishedAt': DateTime.now().toIso8601String(),
      'readingTime': 3,
    }
  ];
  
  await indexArticlesBatch(testArticles);
}


  /// Get search analytics and insights
  static Future<Map<String, dynamic>> getSearchAnalytics({
    String? userToken,
    int days = 7,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searchHistory = prefs.getStringList('search_history') ?? [];
      
      final analytics = <String, dynamic>{
        'totalSearches': searchHistory.length,
        'recentSearches': searchHistory.take(10).map((entry) {
          try {
            final data = jsonDecode(entry) as Map<String, dynamic>;
            return data['query'];
          } catch (e) {
            return entry;
          }
        }).toList(),
        'topQueries': _getTopQueries(searchHistory),
        'searchTrends': _getSearchTrends(searchHistory, days),
      };
      
      return analytics;
    } catch (e) {
      return {};
    }
  }
  
  /// Clear search cache
  static void clearCache() {
    _searchCache.clear();
  }
  
  /// Dispose resources
  static void dispose() {
    _debounceTimer?.cancel();
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _searchCache.clear();
    _client?.dispose();
  }
  
  // PRIVATE HELPER METHODS
  
  static Future<SearchResults> _searchOffline(
    String query,
    Map<String, List<String>>? filters,
  ) async {
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedArticlesJson = prefs.getStringList('cached_articles') ?? [];
      
      final articles = cachedArticlesJson
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .toList();
      
      final filteredResults = articles.where((article) {
        final searchText = query.toLowerCase();
        final title = (article['title'] ?? '').toString().toLowerCase();
        final description = (article['description'] ?? '').toString().toLowerCase();
        final content = (article['content'] ?? '').toString().toLowerCase();
        
        bool matches = title.contains(searchText) || 
                      description.contains(searchText) || 
                      content.contains(searchText);
        
        if (filters != null && matches) {
          matches = _applyOfflineFilters(article, filters);
        }
        
        return matches;
      }).toList();
      
      return SearchResults(
        hits: filteredResults,
        totalHits: filteredResults.length,
        totalPages: (filteredResults.length / 20).ceil(),
        currentPage: 0,
        facets: {},
        processingTime: 0,
        query: query,
        isOffline: true,
      );
      
    } catch (e) {
      return SearchResults.empty(query);
    }
  }
  
  static Map<String, dynamic> _parseHit(Map<String, dynamic> hit) {
    return {
      'docId': hit['objectID'],
      'title': hit['title'],
      'description': hit['description'],
      'content': hit['content'],
      'url': hit['url'],
      'urlToImage': hit['urlToImage'],
      'publishedAt': hit['publishedAt'],
      'source': hit['source'],
      'mainCategory': hit['mainCategory'],
      'subCategory': hit['subCategory'],
      'tags': hit['tags'],
      'readingTime': hit['readingTime'],
      'viewCount': hit['viewCount'],
      'shareCount': hit['shareCount'],
      '_highlightResult': hit['_highlightResult'],
      '_snippetResult': hit['_snippetResult'],
      '_rankingInfo': hit['_rankingInfo'],
    };
  }
  
  static String _generateCacheKey(
    String query,
    Map<String, List<String>>? filters,
    Map<String, String>? numericFilters,
    int page,
    SortBy sortBy,
  ) {
    return '$query-${filters.hashCode}-${numericFilters.hashCode}-$page-${sortBy.name}';
  }
  
  static List<List<String>> _buildFacetFilters(Map<String, List<String>> filters) {
    return filters.entries
        .where((entry) => entry.value.isNotEmpty)
        .map((entry) => entry.value.map((value) => '${entry.key}:$value').toList())
        .toList();
  }
  
  static void _cacheResults(String key, SearchResults results) {
    if (_searchCache.length >= _maxCacheSize) {
      final oldestKey = _searchCache.keys.first;
      _searchCache.remove(oldestKey);
    }
    
    _searchCache[key] = CachedSearchResult(
      results: results,
      cachedAt: DateTime.now(),
    );
  }
  
  static Future<void> _trackSearchAnalytics(
    String query,
    int totalHits,
    String? userToken,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searchHistory = prefs.getStringList('search_history') ?? [];
      
      final searchEntry = jsonEncode({
        'query': query,
        'totalHits': totalHits,
        'timestamp': DateTime.now().toIso8601String(),
        'userToken': userToken,
      });
      
      searchHistory.insert(0, searchEntry);
      
      // Limit history size
      if (searchHistory.length > 1000) {
        searchHistory.removeRange(1000, searchHistory.length);
      }
      
      await prefs.setStringList('search_history', searchHistory);
    } catch (e) {
    }
  }
  
  static void _monitorConnectivity() {
    _subscriptions.add(
      Connectivity().onConnectivityChanged.listen((result) {
        _isOnline = result != ConnectivityResult.none;
      }),
    );
  }
  
  static Future<void> _loadCachedData() async {
  }
  
  static Future<void> _initializeOfflineMode() async {
    _isOnline = false;
  }
  
  static Future<List<SearchSuggestion>> _getCategorySuggestions(String query) async {
    final suggestions = <SearchSuggestion>[];
    final categories = ['Local', 'Foreign', 'Sports', 'Business', 'Technology', 'Politics', 'Entertainment'];
    
    for (final category in categories) {
      if (category.toLowerCase().startsWith(query.toLowerCase())) {
        suggestions.add(SearchSuggestion(
          text: category,
          type: SuggestionType.category,
          category: category,
        ));
      }
    }
    
    return suggestions;
  }
  
  static Future<List<SearchSuggestion>> _getTrendingSuggestions(String query) async {
    return [];
  }
  
  static Future<List<SearchSuggestion>> _getRecentSearchSuggestions(String query) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searchHistory = prefs.getStringList('search_history') ?? [];
      
      final suggestions = <SearchSuggestion>[];
      
      for (final entry in searchHistory.take(20)) {
        try {
          final data = jsonDecode(entry) as Map<String, dynamic>;
          final historyQuery = data['query'] as String;
          
          if (historyQuery.toLowerCase().startsWith(query.toLowerCase()) && 
              historyQuery.toLowerCase() != query.toLowerCase()) {
            suggestions.add(SearchSuggestion(
              text: historyQuery,
              type: SuggestionType.recent,
            ));
          }
        } catch (e) {
          // Skip invalid entries
        }
      }
      
      return suggestions.take(5).toList();
    } catch (e) {
      return [];
    }
  }
  
  static Future<List<SearchSuggestion>> _getOfflineSuggestions(String query) async {
    return [];
  }
  
  static bool _applyOfflineFilters(
    Map<String, dynamic> article,
    Map<String, List<String>> filters,
  ) {
    for (final entry in filters.entries) {
      final fieldValue = article[entry.key]?.toString() ?? '';
      if (!entry.value.contains(fieldValue)) {
        return false;
      }
    }
    return true;
  }
  
  static List<String> _getTopQueries(List<String> searchHistory) {
    final queryCount = <String, int>{};
    
    for (final entry in searchHistory) {
      try {
        final data = jsonDecode(entry) as Map<String, dynamic>;
        final query = data['query'] as String;
        queryCount[query] = (queryCount[query] ?? 0) + 1;
      } catch (e) {
        // Skip invalid entries
      }
    }
    
    final sortedQueries = queryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedQueries.take(10).map((e) => e.key).toList();
  }
  
  static Map<String, int> _getSearchTrends(List<String> searchHistory, int days) {
    final trends = <String, int>{};
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    
    for (final entry in searchHistory) {
      try {
        final data = jsonDecode(entry) as Map<String, dynamic>;
        final timestamp = DateTime.parse(data['timestamp'] as String);
        
        if (timestamp.isAfter(cutoffDate)) {
          final query = data['query'] as String;
          trends[query] = (trends[query] ?? 0) + 1;
        }
      } catch (e) {
        // Skip invalid entries
      }
    }
    
    return trends;
  }
}

// SUPPORTING CLASSES

class SearchResults {
  final List<Map<String, dynamic>> hits;
  final int totalHits;
  final int totalPages;
  final int currentPage;
  final Map<String, dynamic> facets;
  final int processingTime;
  final String query;
  final String? queryID;
  final String? userToken;
  final bool isOffline;

  SearchResults({
    required this.hits,
    required this.totalHits,
    required this.totalPages,
    required this.currentPage,
    required this.facets,
    required this.processingTime,
    required this.query,
    this.queryID,
    this.userToken,
    this.isOffline = false,
  });

  static SearchResults empty(String query) => SearchResults(
        hits: [],
        totalHits: 0,
        totalPages: 0,
        currentPage: 0,
        facets: {},
        processingTime: 0,
        query: query,
      );
      
  bool get isEmpty => hits.isEmpty;
  bool get isNotEmpty => hits.isNotEmpty;
}

class CachedSearchResult {
  final SearchResults results;
  final DateTime cachedAt;

  CachedSearchResult({
    required this.results,
    required this.cachedAt,
  });

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > AdvancedSearchService._cacheExpiry;
}

class SearchSuggestion {
  final String text;
  final SuggestionType type;
  final String? category;

  SearchSuggestion({
    required this.text,
    required this.type,
    this.category,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchSuggestion &&
          runtimeType == other.runtimeType &&
          text == other.text;

  @override
  int get hashCode => text.hashCode;
}

enum SuggestionType { query, category, recent, trending }

enum SortBy { relevance, date, popularity }
