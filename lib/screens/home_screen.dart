import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart'; // Make sure the path/case matches your project
import 'profile_screen.dart';
import 'article_screen.dart';
import 'menu_screen.dart';
import 'search_screen.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = "For you";
  List<Map<String, dynamic>> newsArticles = [];
  final Map<String, List<Map<String, dynamic>>> cachedNews = {};
  bool isLoading = false;

  final ScrollController _scrollController = ScrollController();
  final Map<String, double> _scrollPositions = {};

  final List<String> preloadCategories = [
    "Top",
    "Sports",
    "Business",
    "Technology",
    "Politics",
    "Entertainment",
    "Others"
  ];

  final Map<String, String> categoryToQuery = {
    "For you": "",
    "Top": "news",
    "Sports": "sports",
    "Business": "business",
    "Technology": "technology",
    "Politics": "politics",
    "Entertainment": "entertainment",
    "Others": "world",
  };

  @override
  void initState() {
    super.initState();
    _preloadAllCategories();
  }

  Future<void> _preloadAllCategories() async {
    setState(() {
      isLoading = true;
    });
    for (final category in preloadCategories) {
      final query = categoryToQuery[category] ?? 'news';
      try {
        final freshArticles = await ApiService.fetchAndDisplayArticles(query: query);
        cachedNews[category] = freshArticles;
      } catch (e) {
        print('Error preloading $category: $e');
      }
    }
    // Show "All" or initial category if needed
    if (_selectedCategory == "All") {
      _showAllTabArticles();
    } else if (preloadCategories.contains(_selectedCategory)) {
      setState(() {
        newsArticles = cachedNews[_selectedCategory] ?? [];
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  void _showAllTabArticles() {
    final allArticles = <Map<String, dynamic>>[];
    for (final cat in preloadCategories) {
      allArticles.addAll(cachedNews[cat] ?? []);
    }
    setState(() {
      newsArticles = allArticles;
    });
  }

  Future<void> _fetchNews(String category, {bool forceRefresh = false}) async {
    if (_scrollController.hasClients) {
      _scrollPositions[_selectedCategory] = _scrollController.position.pixels;
    }

    setState(() {
      isLoading = true;
      _selectedCategory = category;
    });

    try {
      if (category == "All") {
        _showAllTabArticles();
      } else if (category == "For you") {
        setState(() {
          newsArticles = [];
        });
      } else {
        // Show cached articles instantly unless forceRefresh
        if (!forceRefresh && cachedNews.containsKey(category)) {
          setState(() {
            newsArticles = cachedNews[category] ?? [];
          });
        }

        // Always fetch latest articles in background and update cache/UI
        final query = categoryToQuery[category] ?? 'news';
        final freshArticles = await ApiService.fetchAndDisplayArticles(query: query);
        setState(() {
          newsArticles = freshArticles;
          cachedNews[category] = freshArticles;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch news: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollPositions.containsKey(category)) {
          _scrollController.jumpTo(_scrollPositions[category]!);
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
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          return false;
        } else {
          SystemNavigator.pop();
          return true;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: const Text(
            'WWN',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MenuScreen(),
                ),
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 10,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              _buildCategoryFilters(),
              Expanded(
                child: _buildNewsContent(),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _buildCustomFooter(),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.red,
          child: const Icon(Icons.cloud_upload, color: Colors.white),
          onPressed: () async {
            try {
              await ApiService.fetchAndDisplayArticles(query: 'technology');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Articles fetched and saved!')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error fetching articles: $e')),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = [
      "For you",
      "All",
      "Top",
      "Sports",
      "Business",
      "Technology",
      "Politics",
      "Entertainment",
      "Others"
    ];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 40.0,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedCategory != category) {
                    _fetchNews(category);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedCategory == category
                      ? Colors.white
                      : Colors.red,
                  foregroundColor: _selectedCategory == category
                      ? Colors.black
                      : Colors.white,
                  side: BorderSide(
                    color: _selectedCategory == category
                        ? Colors.black
                        : Colors.red,
                    width: 1.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                ),
                child: Text(category),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNewsContent() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Colors.red,
              strokeWidth: 4,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading $_selectedCategory news...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    if (newsArticles.isEmpty) {
      return const Center(
        child: Text('No news available'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchNews(_selectedCategory, forceRefresh: true);
        _scrollController.jumpTo(0);
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.only(bottom: 60),
        itemCount: newsArticles.length,
        itemBuilder: (context, index) {
          final article = newsArticles[index];

          if (index == 0) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ArticleScreen(article: article),
                  ),
                );
              },
              child: Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (article['urlToImage'] != null &&
                        article['urlToImage'].isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12.0)),
                        child: Image.network(
                          article['urlToImage'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: const Center(
                                  child: CircularProgressIndicator()),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: const Icon(Icons.error, color: Colors.red),
                            );
                          },
                        ),
                      )
                    else
                      Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, color: Colors.white),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article['title'] ?? 'No Title',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleScreen(article: article),
                ),
              );
            },
            child: Card(
              margin:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 4,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article['urlToImage'] != null &&
                      article['urlToImage'].isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(12.0)),
                      child: Image.network(
                        article['urlToImage'],
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 100,
                            width: 100,
                            color: Colors.grey[300],
                            child: const Center(
                                child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 100,
                            width: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error, color: Colors.red),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      height: 100,
                      width: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.white),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article['title'] ?? 'No Title',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.video_library),
          label: 'Videos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
      ],
      currentIndex: 0,
      onTap: (index) {
        switch (index) {
          case 0:
            // Stay on Home
            break;
          case 1:
            // Navigate to Videos
            break;
          case 2:
            // Navigate to Search
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
            break;
        }
      },
    );
  }
}
