import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';
import 'article_screen.dart';
import 'menu_screen.dart';
import 'search_screen.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedMainCategory = "For you";
  String? _selectedSubCategory;
  List<Map<String, dynamic>> newsArticles = [];
  final Map<String, List<Map<String, dynamic>>> cachedNews = {};
  List<Map<String, dynamic>> _bookmarkedArticles = [];
  bool isLoading = false;

  final ScrollController _scrollController = ScrollController();
  final Map<String, double> _scrollPositions = {};

  final Map<String, List<String>> mainToSubCategories = {
    "Local": ["Top", "Business", "Sports", "Entertainment", "Technology"],
    "Foreign": ["Top", "Sports", "Business", "Technology", "Politics", "Entertainment"],
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
    loadBookmarkedArticles();
  }

  Future<void> loadBookmarkedArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('bookmarked_articles') ?? [];
    setState(() {
      _bookmarkedArticles =
          data.map((json) => jsonDecode(json) as Map<String, dynamic>).toList();
    });
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonBookmarks =
        _bookmarkedArticles.map((item) => json.encode(item)).toList();
    await prefs.setStringList('bookmarked_articles', jsonBookmarks);
  }

  Future<void> _fetchNews(String category, {bool forceRefresh = false}) async {
    if (_scrollController.hasClients) {
      _scrollPositions[_selectedSubCategory ?? "For you"] =
          _scrollController.position.pixels;
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (_selectedMainCategory == "For you") {
        setState(() => newsArticles = []);
      } else {
        if (!forceRefresh && cachedNews.containsKey(category)) {
          setState(() {
            newsArticles = cachedNews[category] ?? [];
          });
        }
        final query = categoryToQuery[category] ?? 'news';
        final freshArticles =
            await ApiService.fetchAndDisplayArticles(query: query);
        setState(() {
          newsArticles = freshArticles;
          cachedNews[category] = freshArticles;
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

  bool isBookmarked(Map<String, dynamic> article) {
    return _bookmarkedArticles
        .any((item) => item['title'] == article['title']);
  }

  Future<void> toggleBookmark(Map<String, dynamic> article) async {
    setState(() {
      if (isBookmarked(article)) {
        _bookmarkedArticles
            .removeWhere((item) => item['title'] == article['title']);
      } else {
        _bookmarkedArticles.add(article);
      }
    });
    await _saveBookmarks();
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
                  await loadBookmarkedArticles();
                  setState(() {});
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              _buildCategoryFilters(),
              Expanded(child: _buildNewsContent()),
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
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: mainCategories.length,
            itemBuilder: (context, index) {
              final mainCat = mainCategories[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
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
                    backgroundColor: _selectedMainCategory == mainCat
                        ? Colors.white
                        : Colors.red,
                    foregroundColor: _selectedMainCategory == mainCat
                        ? Colors.black
                        : Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(mainCat),
                ),
              );
            },
          ),
        ),
        if (_selectedMainCategory != "For you")
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: subCategories.length,
                itemBuilder: (context, index) {
                  final subCat = subCategories[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton(
                      onPressed: () {
                        if (_selectedSubCategory != subCat) {
                          setState(() {
                            _selectedSubCategory = subCat;
                          });
                          _fetchNews(subCat);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedSubCategory == subCat
                            ? Colors.white
                            : Colors.red,
                        foregroundColor: _selectedSubCategory == subCat
                            ? Colors.black
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(subCat),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNewsContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }
    if (newsArticles.isEmpty) {
      return const Center(child: Text('No news available'));
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
          final bookmarked = isBookmarked(article);

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
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: IconButton(
                              icon: Icon(
                                bookmarked
                                    ? Icons.star
                                    : Icons.star_border,
                                color: bookmarked
                                    ? Colors.yellow[700]
                                    : Colors.grey,
                              ),
                              onPressed: () => toggleBookmark(article),
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
        BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Videos'),
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
