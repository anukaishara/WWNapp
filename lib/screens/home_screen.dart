import 'package:flutter/material.dart';
import '../Services/api_service.dart';
import 'profile_screen.dart';
import 'article_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = "For you";
  List<dynamic> newsArticles = [];
  final Map<String, List<dynamic>> cachedNews = {};
  bool isLoading = false;
  
  // Scroll position management
  final ScrollController _scrollController = ScrollController();
  final Map<String, double> _scrollPositions = {};

  @override
  void initState() {
    super.initState();
    _fetchNews(_selectedCategory);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchNews(String category) async {
    // Save current scroll position before switching
    if (_scrollController.hasClients) {
      _scrollPositions[_selectedCategory] = _scrollController.position.pixels;
    }

    setState(() {
      isLoading = true;
      _selectedCategory = category;
    });

    final categoryToQuery = {
      "For you": "",
      "Top": "news",
      "Sports": "sports",
      "Business": "business",
      "History": "history",
      "Technology": "technology",
      "Others": "world",
    };

    try {
      if (category == "All") {
        final allArticles = <dynamic>[];
        for (final cat in cachedNews.keys) {
          if (cat != "For you" && cat != "All") {
            allArticles.addAll(cachedNews[cat]!);
          }
        }
        setState(() {
          newsArticles = allArticles;
        });
      } else if (category == "For you") {
        setState(() {
          newsArticles = [];
        });
      } else {
        final query = categoryToQuery[category] ?? 'news';
        if (cachedNews.containsKey(category)) {
          setState(() {
            newsArticles = cachedNews[category]!;
          });
        } else {
          final articles = await ApiService.fetchEverythingFromNewsAPI(query: query);
          cachedNews[category] = articles;
          setState(() {
            newsArticles = articles;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch news: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error fetching news for category $category: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
      
      // Restore scroll position after build completes
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
    return Scaffold(
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
          onPressed: () {},
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
    );
  }

  Widget _buildCategoryFilters() {
    final categories = [
      "For you", "All", "Top", "Sports", 
      "Business", "History", "Technology", "Others"
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (newsArticles.isEmpty) {
      return const Center(
        child: Text('No news available'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchNews(_selectedCategory);
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
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (article['urlToImage'] != null && article['urlToImage'].isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
                        child: Image.network(
                          article['urlToImage'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              return child;
                            }
                            return Container(
                              height: 200,
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: const Center(child: CircularProgressIndicator()),
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
              margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 4,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article['urlToImage'] != null && article['urlToImage'].isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12.0)),
                      child: Image.network(
                        article['urlToImage'],
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return Container(
                            height: 100,
                            width: 100,
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
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
            break;
          case 1:
            break;
          case 2:
            break;
        }
      },
    );
  }
}