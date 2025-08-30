import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/advanced_search_service.dart';
import 'dart:async';

class AdvancedSearchWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onArticleSelected;
  final String? initialQuery;
  
  const AdvancedSearchWidget({
    super.key,
    required this.onArticleSelected,
    this.initialQuery,
  });
  
  @override
  _AdvancedSearchWidgetState createState() => _AdvancedSearchWidgetState();
}

class _AdvancedSearchWidgetState extends State<AdvancedSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  SearchResults? _currentResults;
  List<SearchSuggestion> _suggestions = [];
  bool _isLoading = false;
  bool _showFilters = false;
  
  // Filters
  final Map<String, List<String>> _selectedFilters = {
    'mainCategory': [],
    'subCategory': [],
    'source': [],
  };
  
  // Advanced features
  Timer? _searchTimer;
  String _lastQuery = '';
  int _currentPage = 0;
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _performSearch(widget.initialQuery!);
    }
    
    // Setup scroll listener for pagination
    _scrollController.addListener(_onScroll);
    
    // Setup search input listener
    _searchController.addListener(_onSearchTextChanged);
    
    // Setup focus listener
    _searchFocusNode.addListener(_onFocusChanged);
  }
  
  void _onSearchTextChanged() {
    final query = _searchController.text;
    
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _currentResults = null;
      });
      return;
    }
    
    // Get suggestions with debouncing
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      _getSuggestions(query);
    });
    
    // Perform search if query is different and long enough
    if (query != _lastQuery && query.length >= 2) {
      _lastQuery = query;
      _currentPage = 0;
      _performSearch(query, isNewSearch: true);
    }
  }
  
  void _onFocusChanged() {
    if (_searchFocusNode.hasFocus && _searchController.text.isNotEmpty) {
      _getSuggestions(_searchController.text);
    } else {
      setState(() => _suggestions = []);
    }
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }
  
  Future<void> _getSuggestions(String query) async {
    if (query.length < 2) return;
    
    try {
      final suggestions = await AdvancedSearchService.getAdvancedSuggestions(
        query: query,
        maxSuggestions: 8,
        userToken: 'user_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      if (mounted) {
        setState(() => _suggestions = suggestions);
      }
    } catch (e) {
      print('Error getting suggestions: $e');
    }
  }
  
  Future<void> _performSearch(String query, {bool isNewSearch = false}) async {
    if (query.trim().isEmpty) return;
    
    setState(() => _isLoading = true);
    
    try {
      final results = await AdvancedSearchService.searchArticles(
        query: query,
        filters: _selectedFilters.isNotEmpty ? _selectedFilters : null,
        page: _currentPage,
        hitsPerPage: 20,
        userToken: 'user_${DateTime.now().millisecondsSinceEpoch}',
        enablePersonalization: true,
        sortBy: SortBy.relevance,
      );
      
      if (mounted) {
        setState(() {
          if (isNewSearch) {
            _currentResults = results;
          } else {
            // Append results for pagination
            if (_currentResults != null) {
              _currentResults = SearchResults(
                hits: [..._currentResults!.hits, ...results.hits],
                totalHits: results.totalHits,
                totalPages: results.totalPages,
                currentPage: results.currentPage,
                facets: results.facets,
                processingTime: results.processingTime,
                query: results.query,
              );
            } else {
              _currentResults = results;
            }
          }
          _isLoading = false;
          _suggestions = [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Search failed: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _performSearch(query, isNewSearch: isNewSearch),
            ),
          ),
        );
      }
    }
  }
  
  void _loadMore() {
    if (_isLoading || _currentResults == null) return;
    if (_currentPage >= _currentResults!.totalPages - 1) return;
    
    _currentPage++;
    _performSearch(_searchController.text);
  }
  
  void _toggleFilter(String filterKey, String value) {
    setState(() {
      if (_selectedFilters[filterKey]!.contains(value)) {
        _selectedFilters[filterKey]!.remove(value);
      } else {
        _selectedFilters[filterKey]!.add(value);
      }
    });
    
    // Re-search with new filters
    _currentPage = 0;
    _performSearch(_searchController.text, isNewSearch: true);
  }
  
  void _clearFilters() {
    setState(() {
      _selectedFilters.forEach((key, value) => value.clear());
    });
    _currentPage = 0;
    _performSearch(_searchController.text, isNewSearch: true);
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        if (_suggestions.isNotEmpty) _buildSuggestions(),
        if (_showFilters) _buildFilters(),
        Expanded(child: _buildResults()),
      ],
    );
  }
  
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search articles, topics, sources...',
                    prefixIcon: Icon(Icons.search, color: Colors.red[600]),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _currentResults = null;
                                _suggestions = [];
                              });
                            },
                          ),
                        IconButton(
                          icon: Icon(
                            Icons.tune,
                            color: _showFilters ? Colors.red : Colors.grey,
                          ),
                          onPressed: () {
                            setState(() => _showFilters = !_showFilters);
                            HapticFeedback.lightImpact();
                          },
                        ),
                      ],
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red[600]!, width: 2),
                    ),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (query) {
                    _currentPage = 0;
                    _performSearch(query, isNewSearch: true);
                    _searchFocusNode.unfocus();
                  },
                ),
              ),
            ],
          ),
          if (_currentResults != null) _buildResultsInfo(),
        ],
      ),
    );
  }
  
  Widget _buildResultsInfo() {
    final results = _currentResults!;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Text(
            '${results.totalHits} results in ${results.processingTime}ms',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          if (results.isOffline) ...[
            const SizedBox(width: 8),
            Icon(Icons.offline_bolt, color: Colors.orange[600], size: 16),
            Text(
              'Offline',
              style: TextStyle(color: Colors.orange[600], fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSuggestions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _suggestions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final suggestion = _suggestions[index];
          return ListTile(
            dense: true,
            leading: _getSuggestionIcon(suggestion.type),
            title: Text(suggestion.text),
            subtitle: suggestion.category != null 
                ? Text(suggestion.category!, style: const TextStyle(fontSize: 12))
                : null,
            onTap: () {
              _searchController.text = suggestion.text;
              _currentPage = 0;
              _performSearch(suggestion.text, isNewSearch: true);
              _searchFocusNode.unfocus();
            },
          );
        },
      ),
    );
  }
  
  Widget _buildFilters() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearFilters,
                child: Text(
                  'Clear All',
                  style: TextStyle(color: Colors.red[600]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildFilterChips('Categories', 'mainCategory', 
              ['Local', 'Foreign', 'Sports', 'Business', 'Technology']),
          const SizedBox(height: 8),
          _buildFilterChips('Sources', 'source', 
              ['NewsAPI', 'GNews', 'AdaDerana', 'BBC', 'CNN']),
        ],
      ),
    );
  }
  
  Widget _buildFilterChips(String title, String filterKey, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = _selectedFilters[filterKey]!.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => _toggleFilter(filterKey, option),
              selectedColor: Colors.red[100],
              checkmarkColor: Colors.red[600],
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildResults() {
    if (_isLoading && _currentResults == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.red),
            SizedBox(height: 16),
            Text('Searching...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    if (_currentResults == null) {
      return _buildEmptyState();
    }
    
    if (_currentResults!.hits.isEmpty) {
      return _buildNoResults();
    }
    
    return RefreshIndicator(
      onRefresh: () => _performSearch(_searchController.text, isNewSearch: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _currentResults!.hits.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= _currentResults!.hits.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(color: Colors.red),
              ),
            );
          }
          
          final article = _currentResults!.hits[index];
          return _buildArticleCard(article, index);
        },
      ),
    );
  }
  
  Widget _buildArticleCard(Map<String, dynamic> article, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          widget.onArticleSelected(article);
          HapticFeedback.lightImpact();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Article image
                  if (article['urlToImage'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        article['urlToImage'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.article, color: Colors.grey),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  // Article content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (article['description'] != null)
                          Text(
                            article['description'],
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Article metadata
              Row(
                children: [
                  if (article['source'] != null) ...[
                    Icon(Icons.source, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      article['source'],
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                  if (article['readingTime'] != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${article['readingTime']} min',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                  const Spacer(),
                  if (article['mainCategory'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(article['mainCategory']),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        article['mainCategory'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Start searching for articles',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the search bar above to find news articles',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No articles found',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try different keywords or remove filters',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _clearFilters,
            child: const Text('Clear Filters'),
          ),
        ],
      ),
    );
  }
  
  Icon _getSuggestionIcon(SuggestionType type) {
    switch (type) {
      case SuggestionType.query:
        return const Icon(Icons.search, size: 18, color: Colors.grey);
      case SuggestionType.category:
        return const Icon(Icons.category, size: 18, color: Colors.blue);
      case SuggestionType.recent:
        return const Icon(Icons.history, size: 18, color: Colors.orange);
      case SuggestionType.trending:
        return const Icon(Icons.trending_up, size: 18, color: Colors.green);
    }
  }
  
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'local':
        return Colors.orange[600]!;
      case 'foreign':
        return Colors.blue[600]!;
      case 'sports':
        return Colors.green[600]!;
      case 'business':
        return Colors.purple[600]!;
      case 'technology':
        return Colors.teal[600]!;
      default:
        return Colors.grey[600]!;
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }
}
