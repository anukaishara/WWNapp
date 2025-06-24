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

class HomeScreen extends StatefulWidget {
  final String? initialMainCategory;
  final String? initialSubCategory;


  const HomeScreen({
    super.key,
    this.initialMainCategory,
    this.initialSubCategory,
  });

  

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedMainCategory = "For you";
  String? _selectedSubCategory;
  List<Map<String, dynamic>> newsArticles = [];
  final Map<String, List<Map<String, dynamic>>> cachedNews = {};
  bool isLoading = false;

  final ScrollController _scrollController = ScrollController();
  final Map<String, double> _scrollPositions = {};

  final Map<String, List<String>> mainToSubCategories = {
    "Local": ["Top", "Business", "Sports", "Entertainment", "Technology"],
    "Foreign": [
      "Top",
      "Sports",
      "Business",
      "Technology",
      "Politics",
      "Entertainment"
    ],
  };

  final Map<String, String> categoryToQuery = {
    "Top": "news",
    "Sports": "sports",
    "Business": "business",
    "Technology": "technology",
    "Politics": "politics",
    "Entertainment": "entertainment",
  };

  @override
  void initState() {
    super.initState();

    // Use initialMainCategory and initialSubCategory if provided
    if (widget.initialMainCategory != null &&
        (widget.initialMainCategory == "Local" ||
            widget.initialMainCategory == "Foreign")) {
      _selectedMainCategory = widget.initialMainCategory!;
      _selectedSubCategory = widget.initialSubCategory ??
          (mainToSubCategories[_selectedMainCategory]?.first ?? "Top");
      _fetchNews(_selectedSubCategory!);
    } else if (widget.initialMainCategory != null &&
        widget.initialMainCategory == "For you") {
      _selectedMainCategory = "For you";
      _selectedSubCategory = null;
      setState(() => newsArticles = []);
    }
  }

  Future<void> _fetchNews(String category, {bool forceRefresh = false}) async {
    setState(() => isLoading = true);

    if (_selectedMainCategory == "Local") {
      // 1. Scrape and save to Firestore (already done in scraping.dart)
      await scrapeLocalCategory(category);

      // 2. Fetch from Firestore (with docId, mainCategory, subCategory)
      final snapshot = await FirebaseFirestore.instance
          .collection('articles')
          .where('mainCategory', isEqualTo: 'Local')
          .where('subCategory', isEqualTo: category)
          .get();

      final articles = snapshot.docs
          .map((doc) => {
                ...doc.data(),
                'docId': doc.id,
              })
          .toList();

      setState(() {
        newsArticles = articles;
        cachedNews[category] = articles;
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (_selectedMainCategory == "For you") {
        setState(() => newsArticles = []);
      } else if (_selectedMainCategory == "Foreign") {
        if (!forceRefresh && cachedNews.containsKey(category)) {
          setState(() {
            newsArticles = cachedNews[category] ?? [];
          });
        }
        final query = categoryToQuery[category] ?? 'news';
        final freshArticles = await ApiService.fetchAndDisplayArticles(
          query: query,
          mainCategory: _selectedMainCategory,
          subCategory: category,
        );

        // Now fetch from Firestore for display (with docId)
        final articles = await ApiService.fetchArticlesFromFirestore(
          mainCategory: _selectedMainCategory,
          subCategory: category,
        );

        // Display 'articles' in your UI
        setState(() {
          newsArticles = articles;
          cachedNews[category] = freshArticles;
        });
      } else if (_selectedMainCategory == "Local") {
        final scrapedArticles = await scrapeLocalCategory(category);
        setState(() {
          newsArticles = scrapedArticles;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to fetch news: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _selectedSubCategory ?? "For you";
        if (_scrollPositions.containsKey(key)) {
          _scrollController.jumpTo(_scrollPositions[key]!);
        } else {
          _scrollController.jumpTo(0);
        }
      });
    }
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
        } else {
          SystemNavigator.pop();
          return true;
        }
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
                if (updated == true) {
                  setState(() {});
                }
              },
            ),
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
    final mainCategories = ["For you", "Local", "Foreign"];
    final subCategories = mainToSubCategories[_selectedMainCategory] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: mainCategories.length,
            itemBuilder: (context, index) {
              final mainCat = mainCategories[index];
              final isSelected = _selectedMainCategory == mainCat;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedMainCategory = mainCat;
                      _selectedSubCategory = null;
                      if (mainCat == "For you") {
                        newsArticles = [];
                      } else {
                        final firstSub = mainToSubCategories[mainCat]!.first;
                        _selectedSubCategory = firstSub;
                        _fetchNews(firstSub);
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSelected ? Colors.white : Colors.red,
                    foregroundColor: isSelected ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22)),
                    elevation: isSelected ? 4 : 0,
                    shadowColor: Colors.black26,
                  ),
                  child: Text(
                    mainCat,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              );
            },
          ),
        ),
        if (_selectedMainCategory != "For you")
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 8),
            child: SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: subCategories.length,
                itemBuilder: (context, index) {
                  final subCat = subCategories[index];
                  final isSelected = _selectedSubCategory == subCat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ElevatedButton(
                      onPressed: () {
                        if (!isSelected) {
                          setState(() {
                            _selectedSubCategory = subCat;
                          });
                          _fetchNews(subCat);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected ? Colors.white : Colors.red,
                        foregroundColor:
                            isSelected ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22)),
                        elevation: isSelected ? 4 : 0,
                        shadowColor: Colors.black26,
                      ),
                      child: Text(
                        subCat,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

Widget _buildNewsContent(BuildContext context) {
  final bookmarkProvider = context.watch<BookmarkProvider>();
  if (!bookmarkProvider.isLoaded) {
    return const Center(child: CircularProgressIndicator(color: Colors.red));
  }
    if (newsArticles.isEmpty) {
      return const Center(
        child: Text(
          'No news available',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async =>
          await _fetchNews(_selectedSubCategory ?? "Top", forceRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 60),
        itemCount: newsArticles.length,
        itemBuilder: (context, index) {
          final article = newsArticles[index];
          final bookmarkProvider = context.watch<BookmarkProvider>();
          final bookmarked = bookmarkProvider.isBookmarked(article);
          return GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ArticleScreen(article: article))),
            child: Card(
              margin:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              elevation: 4,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article['urlToImage'] != null &&
                      article['urlToImage'].isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(12.0)),
                      child: Image.network(article['urlToImage'],
                          height: 100, width: 100, fit: BoxFit.cover),
                    )
                  else
                    Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(article['title'] ?? 'No Title',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: IconButton(
  icon: Icon(
    bookmarked ? Icons.star : Icons.star_border,
    color: bookmarked ? Colors.yellow[700] : Colors.grey,
  ),
  onPressed: () async {
    final bookmarkProvider = context.read<BookmarkProvider>();
    final wasBookmarked = bookmarkProvider.isBookmarked(article);
    await bookmarkProvider.toggleBookmark(article);

    // Optional: Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasBookmarked ? 'Bookmark removed' : 'Article bookmarked'
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  },
),

                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
      onTap: (index) {
        if (index == 2) {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const SearchScreen()));
        }
      },
    );
  }
}

// Example function to fetch articles from Firestore asynchronously
Future<List<Map<String, dynamic>>> fetchArticlesFromFirestore(
    {String? mainCategory, String? subCategory}) async {
  Query query = FirebaseFirestore.instance.collection('articles');
  if (mainCategory != null) {
    query = query.where('mainCategory', isEqualTo: mainCategory);
  }
  if (subCategory != null) {
    query = query.where('subCategory', isEqualTo: subCategory);
  }
  final snapshot = await query.get();
  return snapshot.docs.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    return {
      ...data,
      'docId': doc.id,
      'mainCategory': data['mainCategory'],
      'subCategory': data['subCategory'],
    };
  }).toList();
}
