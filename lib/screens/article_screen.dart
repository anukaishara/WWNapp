import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import '../services/scraping.dart';
import '../services/bookmark_provider.dart';
import '../services/history_provider.dart';
import '../services/user_data_service.dart'; // Import the UserDataService
import 'article_screen.dart'; // Import the ArticleScreen

class ArticleListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> articles;

  const ArticleListScreen({super.key, required this.articles});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Articles'),
        backgroundColor: Colors.red,
      ),
      body: ListView.builder(
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          return ListTile(
            title: Text(article['title'] ?? ''),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArticleScreen(article: article),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ArticleScreen extends StatefulWidget {
  final Map<String, dynamic> article;

  const ArticleScreen({
    super.key,
    required this.article,
  });

  @override
  _ArticleScreenState createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  String _fullContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final articleId = widget.article['docId'];
      final mainCategory = widget.article['mainCategory'];
      final subCategory = widget.article['subCategory'];
      if (articleId != null && mainCategory != null && subCategory != null) {
        context.read<HistoryProvider>().addToHistory(widget.article);
      }
    });
    _fetchFullContent();
  }

  Future<void> _fetchFullContent() async {
    try {
      String? fullContentFromRss = widget.article['fullContent'];
      final content = await fetchFullArticleContent(
        widget.article['url'],
        category: widget.article['category'],
        fullContent: fullContentFromRss,
      );
      setState(() {
        _fullContent = content.trim();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _fullContent = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load full content: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onBookmarkPressed() async {
    final articleId = widget.article['docId'];
    final mainCategory = widget.article['mainCategory'];
    final subCategory = widget.article['subCategory'];
    final email = FirebaseAuth.instance.currentUser?.email;

    print('Bookmarking: $articleId, $mainCategory, $subCategory');

    if (email != null && articleId != null && mainCategory != null && subCategory != null) {
      await context.read<BookmarkProvider>().toggleBookmark(widget.article);
      setState(() {}); // <-- This will rebuild the widget and update the icon
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article bookmarked!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot bookmark: missing article info.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final isBookmarked = bookmarkProvider.isBookmarked(widget.article);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.red,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
            ),
            tooltip: isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
            onPressed: () async {
              // Toggle bookmark state
              context.read<BookmarkProvider>().toggleBookmark(widget.article);
              setState(() {}); // <-- This will rebuild the widget and update the icon

              // Get the current user's email
              final email = FirebaseAuth.instance.currentUser?.email;
              final articleId = widget.article['docId'];
              final mainCategory = widget.article['mainCategory'];
              final subCategory = widget.article['subCategory'];

              // Add or remove bookmark in the database
              if (isBookmarked) {
                // If already bookmarked, remove the bookmark
                if (email != null) {
                  UserDataService.removeBookmark(email, articleId, subCategory);
                }
              } else {
                // If not bookmarked, add the bookmark
                if (email != null) {
                  print('Bookmarking: $articleId, $mainCategory, $subCategory');
                  try {
                    await UserDataService.addBookmark(email, articleId, mainCategory, subCategory);
                    print('Bookmark saved to Firestore');
                  } catch (e) {
                    print('Error saving bookmark: $e');
                  }
                }
              }

              // Optionally, show a snackbar or toast message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isBookmarked ? 'Bookmark removed' : 'Article bookmarked'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Article image with rounded corners and shadow
            if (widget.article['urlToImage'] != null && widget.article['urlToImage'].isNotEmpty)
              Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        widget.article['urlToImage'],
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 220,
                            color: Colors.grey[300],
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 220,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error, color: Colors.red, size: 48),
                          );
                        },
                      ),
                    ),
                  ),
                  // Optional: Floating bookmark button over image
                  Positioned(
                    top: 28,
                    right: 32,
                    child: Material(
                      color: Colors.transparent,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 24,
                        child: IconButton(
                          icon: Icon(
                            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            color: Colors.red,
                            size: 28,
                          ),
                          tooltip: isBookmarked ? 'Remove Bookmark' : 'Add Bookmark',
                          onPressed: () async {
                            // Toggle bookmark state
                            context.read<BookmarkProvider>().toggleBookmark(widget.article);
                            setState(() {}); // <-- This will rebuild the widget and update the icon

                            // Get the current user's email
                            final email = FirebaseAuth.instance.currentUser?.email;
                            final articleId = widget.article['docId'];
                            final mainCategory = widget.article['mainCategory'];
                            final subCategory = widget.article['subCategory'];

                            // Add or remove bookmark in the database
                            if (isBookmarked) {
                              // If already bookmarked, remove the bookmark
                              if (email != null) {
                                UserDataService.removeBookmark(email, articleId, subCategory);
                              }
                            } else {
                              // If not bookmarked, add the bookmark
                              if (email != null) {
                                print('Bookmarking: $articleId, $mainCategory, $subCategory');
                                try {
                                  await UserDataService.addBookmark(email, articleId, mainCategory, subCategory);
                                  print('Bookmark saved to Firestore');
                                } catch (e) {
                                  print('Error saving bookmark: $e');
                                }
                              }
                            }

                            // Optionally, show a snackbar or toast message
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isBookmarked ? 'Bookmark removed' : 'Article bookmarked'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.article['title'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (widget.article['publishedAt'] != null)
                        Text(
                          'Published on: ${_formatDate(widget.article['publishedAt'])}',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      const SizedBox(height: 18),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : (_fullContent.isNotEmpty
                              ? Text(
                                  _fullContent,
                                  style: const TextStyle(fontSize: 18, height: 1.7, color: Colors.black87),
                                )
                              : const Text(
                                  'Full article not available.',
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.red,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.video_library), label: 'Videos'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.tryParse(dateString);
    if (date != null) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return '';
  }
}
