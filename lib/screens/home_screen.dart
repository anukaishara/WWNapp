import 'package:flutter/material.dart';
import '../Services/api_service.dart'; // Import the ApiService
import 'profile_screen.dart'; // Import the ProfileScreen
import 'article_screen.dart'; // Import the ArticleScreen

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Track the selected category
  String _selectedCategory = "For you";

  // Store fetched news articles
  List<dynamic> newsArticles = [];

  // Cache news articles for each category
  final Map<String, List<dynamic>> cachedNews = {};

  // Track loading state
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Fetch news when the screen is first loaded
    _fetchNews(_selectedCategory);
  }

  // Fetch news from the API based on the selected category
  Future<void> _fetchNews(String category) async {
    setState(() {
      isLoading = true;
    });

    // Map categories to relevant queries
    final categoryToQuery = {
      "For you": "", // Empty query for "For you"
      "Top": "news", // General news for "Top"
      "Sports": "sports",
      "Business": "business",
      "History": "history",
      "Technology": "technology",
      "Others": "world",
    };

    try {
      if (category == "All") {
        // Combine news from all categories except "For you" and "All"
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
        // Keep "For you" tab empty
        setState(() {
          newsArticles = [];
        });
      } else {
        // Fetch news for the selected category
        final query = categoryToQuery[category] ?? 'news';
        if (cachedNews.containsKey(category)) {
          // Use cached news if available
          setState(() {
            newsArticles = cachedNews[category]!;
          });
        } else {
          // Fetch news from the API
          final articles = await ApiService.fetchEverythingFromNewsAPI(query: query);
          cachedNews[category] = articles; // Cache the results
          setState(() {
            newsArticles = articles;
          });
        }
      }
    } catch (e) {
      // Show error message to the user
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red, // Red background
        title: const Text(
          'WWN',
          style: TextStyle(
            color: Colors.white, // White title color
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true, // Center the title
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white), // Menu icon
          onPressed: () {
            // Handle menu action
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white), // Profile icon
            onPressed: () {
              // Navigate to ProfileScreen
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
              height: 10, // White ribbon height
              color: Colors.white, // White ribbon color
            ),
            const SizedBox(height: 8),
            _buildCategoryFilters(), // Horizontal category filters
            Expanded(
              child: _buildNewsContent(), // Show news for the selected category
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildCustomFooter(), // Replace BottomAppBar
    );
  }

  // Horizontal Category Filters
  Widget _buildCategoryFilters() {
    final categories = [
      "For you",
      "All",
      "Top", // Renamed from "News"
      "Sports",
      "Business",
      "History",
      "Technology",
      "Others"
    ];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 40.0, // Set a fixed height for the slider
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedCategory = category;
                  });

                  // Fetch news for the selected category
                  _fetchNews(category);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedCategory == category
                      ? Colors.white
                      : Colors.red, // White for selected, red for others
                  foregroundColor: _selectedCategory == category
                      ? Colors.black
                      : Colors.white, // Black text for selected, white for others
                  side: BorderSide(
                    color: _selectedCategory == category
                        ? Colors.black
                        : Colors.red,
                    width: 1.0,
                  ), // Black border for selected
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

  // Real News Content for the Selected Category
Widget _buildNewsContent() {
  if (isLoading) {
    return const Center(
      child: CircularProgressIndicator(), // Show loading indicator
    );
  }

  if (newsArticles.isEmpty) {
    return const Center(
      child: Text('No news available'), // Show a message if no articles are fetched
    );
  }

  return RefreshIndicator(
    onRefresh: () async {
      await _fetchNews(_selectedCategory); // Refresh news
    },
    child: ListView.builder(
      padding: const EdgeInsets.only(bottom: 60),
      itemCount: newsArticles.length,
      itemBuilder: (context, index) {
        final article = newsArticles[index];
        return GestureDetector(
          onTap: () {
            // Navigate to the ArticleScreen with the selected article
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArticleScreen(article: article),
              ),
            );
          },
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // News image (if available)
                  if (article['urlToImage'] != null && article['urlToImage'].isNotEmpty)
                    Image.network(
                      article['urlToImage'],
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child; // Return the image when fully loaded
                        }
                        return Container(
                          height: 80,
                          width: 80,
                          color: Colors.grey[300], // Show a grey placeholder
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 80,
                          width: 80,
                          color: Colors.grey[300], // Show a grey box for errors
                          child: const Icon(Icons.error, color: Colors.red),
                        );
                      },
                    )
                  else
                    Container(
                      height: 80,
                      width: 80,
                      color: Colors.grey[300], // Show a grey box as a fallback
                      child: const Icon(Icons.image, color: Colors.white),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // News title
                        Text(
                          article['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // News description
                        Text(
                          article['description'] ?? 'No Description',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

  // Custom Footer Navigation
  Widget _buildCustomFooter() {
    return BottomNavigationBar(
      backgroundColor: Colors.red, // Red background color
      selectedItemColor: Colors.white, // White for selected item
      unselectedItemColor: Colors.white70, // Light white for unselected items
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
      currentIndex: 0, // Set the active item
      onTap: (index) {
        // Handle navigation based on index
        switch (index) {
          case 0:
            // Stay on Home
            break;
          case 1:
            // Navigate to Videos
            break;
          case 2:
            // Navigate to Search
            break;
        }
      },
    );
  }
}