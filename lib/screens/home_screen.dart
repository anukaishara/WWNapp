import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/bookmark_provider.dart';
import 'profile_screen.dart';
import 'article_screen.dart';
import 'menu_screen.dart';
import 'search_screen.dart';
import 'package:flutter/services.dart';
import '../services/scraping.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/search_service.dart';


// cached_network_image no longer used after simplification

class HomeScreen extends StatefulWidget {
  final String? initialMainCategory;
  final String? initialSubCategory;
  const HomeScreen(
      {super.key, this.initialMainCategory, this.initialSubCategory});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedMainCategory = 'For you';
  String? _selectedSubCategory;
  List<Map<String, dynamic>> newsArticles = [];
  final Map<String, List<Map<String, dynamic>>> cachedNews = {};
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();
  final Map<String, double> _scrollPositions = {};

  final Map<String, List<String>> mainToSubCategories = {
    'Local': ['Top', 'Business', 'Sports', 'Entertainment', 'Technology'],
    'Foreign': [
      'Top',
      'Sports',
      'Business',
      'Technology',
      'Politics',
      'Entertainment'
    ],
  };
  final Map<String, String> categoryToQuery = {
    'Top': 'news',
    'Sports': 'sports',
    'Business': 'business',
    'Technology': 'technology',
    'Politics': 'politics',
    'Entertainment': 'entertainment',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialMainCategory != null &&
        (widget.initialMainCategory == 'Local' ||
            widget.initialMainCategory == 'Foreign')) {
      _selectedMainCategory = widget.initialMainCategory!;
      _selectedSubCategory = widget.initialSubCategory ??
          mainToSubCategories[_selectedMainCategory]!.first;
      _fetchNews(_selectedSubCategory!);
    } else if (widget.initialMainCategory == 'For you') {
      _selectedMainCategory = 'For you';
    }
    
  }


  Future<void> _fetchNews(String category, {bool forceRefresh = false}) async {
    setState(() => isLoading = true);
    if (_selectedMainCategory == 'Local') {
      // Scrape first (includes image URLs) and show immediately
      final scraped = await scrapeLocalCategory(category);
      if (mounted) {
        setState(() {
          newsArticles = scraped;
          cachedNews[category] = scraped;
        });
        _debugPrintFirstImages();
        if (scraped.isNotEmpty) {
        try {
          SearchService.indexArticles(scraped);
        } catch (e) {
          print('❌ Failed to index cached articles: $e');
        }
      }
    
      }
      // Firestore saving happens inside scrapeLocalCategory; we can optionally refresh later
      setState(() => isLoading = false);
      return;
    }
    try {
      if (_selectedMainCategory == 'Foreign') {
        if (!forceRefresh && cachedNews.containsKey(category)) {
          final cached = cachedNews[category]!;
          newsArticles = cached;
        
        // 🆕 ADD THIS: Index cached articles if needed
        if (cached.isNotEmpty) {
          try {
            SearchService.indexArticles(cached);
          } catch (e) {
            print('❌ Failed to index cached articles: $e');
          }
        }
        }
        
        final query = categoryToQuery[category] ?? 'news';
        final fresh = await ApiService.fetchAndDisplayArticles(
            query: query,
            mainCategory: _selectedMainCategory,
            subCategory: category);
        if (mounted) {
          setState(() {
            // Show fresh API results immediately (they contain image URLs)
            newsArticles = fresh;
            cachedNews[category] = fresh;
          });
          _debugPrintFirstImages();
        }
        // (Optional) Later we could reconcile with Firestore if needed
      } else if (_selectedMainCategory == 'For you') {
        setState(() => newsArticles = []);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to fetch news: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final key = _selectedSubCategory ?? 'For you';
          _scrollController.jumpTo(_scrollPositions[key] ?? 0);
        });
      }
    }
  }

  // Helper to print first few image URLs for debugging
  void _debugPrintFirstImages() {
    if (newsArticles.isEmpty) return;
    // Avoid spamming console
    final sample =
        newsArticles.take(5).map((a) => _extractImageUrl(a) ?? '-').toList();
    // ignore: avoid_print
    print('🖼️ Sample image URLs: $sample');
  }

  // Extract & normalize possible image keys, fallback order
  String? _extractImageUrl(Map<String, dynamic> article) {
    final candidates = [
      article['urlToImage'],
      article['image'],
      article['thumbnail'],
      article['img'],
    ].whereType<String>().map((s) => s.trim()).where((s) => s.isNotEmpty);
    for (final c in candidates) {
      final normalized = _normalizeUrl(c);
      if (normalized != null) return normalized;
    }
    return null;
  }

  String? _normalizeUrl(String raw) {
    var u = raw.trim();
    if (u.isEmpty) return null;
    if (u.startsWith('data:')) return null; // ignore data URIs
    if (u.startsWith('http://')) {
      // Upgrade to https if possible
      u = u.replaceFirst('http://', 'https://');
    }
    if (u.startsWith('//')) u = 'https:$u';
    if (!u.startsWith('http')) {
      // Treat as relative to AdaDerana domain (most local sources)
      if (!u.startsWith('/')) u = '/$u';
      u = 'https://www.adaderana.lk$u';
    }
    return u;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_scrollController.hasClients && _scrollController.offset > 0) {
          _scrollController.animateTo(0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut);
          return false;
        }
        SystemNavigator.pop();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: const Text('WWN',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const MenuScreen())),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                if (updated == true) setState(() {});
              },
            )
          ],
          elevation: 2,
          shadowColor: Colors.black54,
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildCategoryFilters(),
              Expanded(child: _buildNewsContent(context)),
            ],
          ),
        ),
        bottomNavigationBar: _buildCustomFooter(),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final mainCategories = ['For you', 'Local', 'Foreign'];
    final subCategories = mainToSubCategories[_selectedMainCategory] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: mainCategories.length,
            itemBuilder: (context, i) {
              final mainCat = mainCategories[i];
              final selected = _selectedMainCategory == mainCat;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedMainCategory = mainCat;
                      _selectedSubCategory = null;
                      if (mainCat == 'For you') {
                        newsArticles = [];
                      } else {
                        final first = mainToSubCategories[mainCat]!.first;
                        _selectedSubCategory = first;
                        _fetchNews(first);
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selected ? Colors.white : Colors.red,
                    foregroundColor: selected ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22)),
                    elevation: selected ? 4 : 0,
                    shadowColor: Colors.black26,
                  ),
                  child: Text(mainCat,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              );
            },
          ),
        ),
        if (_selectedMainCategory != 'For you')
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 8),
            child: SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: subCategories.length,
                itemBuilder: (context, i) {
                  final subCat = subCategories[i];
                  final selected = _selectedSubCategory == subCat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ElevatedButton(
                      onPressed: () {
                        if (!selected) {
                          setState(() => _selectedSubCategory = subCat);
                          _fetchNews(subCat);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selected ? Colors.white : Colors.red,
                        foregroundColor: selected ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22)),
                        elevation: selected ? 4 : 0,
                        shadowColor: Colors.black26,
                      ),
                      child: Text(subCat,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  );
                },
              ),
            ),
          )
      ],
    );
  }

  Widget _buildNewsContent(BuildContext context) {
    final bookmarkProvider = context.watch<BookmarkProvider>();
    if (!bookmarkProvider.isLoaded || isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }
    if (newsArticles.isEmpty) {
      return const Center(
          child: Text('No news available',
              style: TextStyle(fontSize: 18, color: Colors.grey)));
    }
    return RefreshIndicator(
      onRefresh: () async =>
          await _fetchNews(_selectedSubCategory ?? 'Top', forceRefresh: true),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            sliver: SliverToBoxAdapter(
              child: _FeaturedArticle(
                article: newsArticles.first,
                isBookmarked: bookmarkProvider.isBookmarked(newsArticles.first),
                onBookmarkToggle: () async {
                  final was = bookmarkProvider.isBookmarked(newsArticles.first);
                  await bookmarkProvider.toggleBookmark(newsArticles.first);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            was ? 'Bookmark removed' : 'Article bookmarked'),
                        duration: const Duration(seconds: 1)));
                  }
                },
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ArticleScreen(
                            article: {
                              ...newsArticles.first,
                              'mainCategory':
                                  newsArticles.first['mainCategory'] ?? 'Foreign',
                              'subCategory':
                                  newsArticles.first['subCategory'] ?? 'Top',
                            },
                          )),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childCount: newsArticles.length - 1,
              itemBuilder: (ctx, i) {
                final article = newsArticles[i + 1];
                final bookmarked = bookmarkProvider.isBookmarked(article);
                return _ArticleTile(
                  article: article,
                  bookmarked: bookmarked,
                  onBookmark: () async {
                    final was = bookmarkProvider.isBookmarked(article);
                    await bookmarkProvider.toggleBookmark(article);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              was ? 'Bookmark removed' : 'Article bookmarked'),
                          duration: const Duration(seconds: 1)));
                    }
                  },
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ArticleScreen(
                              article: {
                                ...article,
                                'mainCategory':
                                    article['mainCategory'] ?? 'Foreign',
                                'subCategory': article['subCategory'] ??
                                    'Top', // or another default
                              },
                            )),
                ));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomFooter() {
    return BottomNavigationBar(
      backgroundColor: Colors.red,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.video_library), label: 'Videos'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
      ],
      currentIndex: 0,
      onTap: (i) {
        if (i == 2) {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const SearchScreen()));
        }
      },
    );
  }
}

// Pick best image from common keys and normalize simple relative/protocol-less cases
String _pickImage(Map<String, dynamic> article) {
  final keys = ['urlToImage', 'image', 'thumbnail', 'img'];
  for (final k in keys) {
    final v = article[k];
    if (v is String && v.trim().isNotEmpty) {
      var u = v.trim();
      if (u.startsWith('//')) u = 'https:$u';
      if (u.startsWith('http://')) u = u.replaceFirst('http://', 'https://');
      if (!u.startsWith('http')) {
        if (!u.startsWith('/')) u = '/$u';
        u = 'https://www.adaderana.lk$u';
      }
      if (u.startsWith('data:')) continue; // skip data URIs
      return u;
    }
  }
  return '';
}

class _FeaturedArticle extends StatelessWidget {
  final Map<String, dynamic> article;
  final bool isBookmarked;
  final VoidCallback onBookmarkToggle;
  final VoidCallback onTap;
  const _FeaturedArticle({
    required this.article,
    required this.isBookmarked,
    required this.onBookmarkToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = _pickImage(article);
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.image),
                    ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Text(
                article['title'] ?? 'No Title',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: Icon(
                    isBookmarked ? Icons.star : Icons.star_border,
                    color: isBookmarked ? Colors.yellow[700] : Colors.white,
                  ),
                  onPressed: onBookmarkToggle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleTile extends StatelessWidget {
  final Map<String, dynamic> article;
  final bool bookmarked;
  final VoidCallback onBookmark;
  final VoidCallback onTap;
  const _ArticleTile({
    required this.article,
    required this.bookmarked,
    required this.onBookmark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = _pickImage(article);
    // Debug once per tile build when empty
    if (imageUrl.isEmpty) {
      // ignore: avoid_print
      print(
          '🔍 Missing image for article title="${article['title'] ?? ''}" keys: urlToImage=${article['urlToImage']} image=${article['image']}');
    }

    return GestureDetector(
      onTap: onTap,
      child: Material(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Text(
                article['title'] ?? 'No Title',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(
                    bookmarked ? Icons.star : Icons.star_border,
                    color: bookmarked ? Colors.yellow[700] : Colors.grey,
                  ),
                  onPressed: onBookmark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Example helper (if needed elsewhere)
  Future<List<Map<String, dynamic>>> fetchArticlesFromFirestore(
      {String? mainCategory, String? subCategory}) async {
    Query query = FirebaseFirestore.instance.collection('articles');
    if (mainCategory != null)
      query = query.where('mainCategory', isEqualTo: mainCategory);
    if (subCategory != null)
      query = query.where('subCategory', isEqualTo: subCategory);
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => {...doc.data() as Map<String, dynamic>, 'docId': doc.id})
        .toList();
  }
}
