import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'article_screen.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});
  

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
  
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  List<Map<String, dynamic>> _bookmarkedArticles = [];
  bool _bookmarkedArticlesChanged = false; // Tracks changes for syncing

  @override
  void initState() {
    super.initState();
    loadBookmarks();
  }

  Future<void> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('bookmarked_articles') ?? [];
    setState(() {
      _bookmarkedArticles = data
          .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
          .toList();
    });
  }

  Future<void> _toggleBookmark(Map<String, dynamic> article) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _bookmarkedArticlesChanged = true; // Mark as changed
      final isAlreadyBookmarked = _bookmarkedArticles
          .any((item) => item['title'] == article['title']);

      if (isAlreadyBookmarked) {
        _bookmarkedArticles
            .removeWhere((item) => item['title'] == article['title']);
      } else {
        _bookmarkedArticles.add(article);
      }
    });

    final updatedData =
        _bookmarkedArticles.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('bookmarked_articles', updatedData);
  }

  bool _isBookmarked(Map<String, dynamic> article) {
    return _bookmarkedArticles
        .any((item) => item['title'] == article['title']);
  }

  Future<void> removeBookmark(Map<String, dynamic> article) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bookmarkedArticlesChanged = true; // Mark as changed
      _bookmarkedArticles
          .removeWhere((item) => item['title'] == article['title']);
    });
    final updatedData =
        _bookmarkedArticles.map((a) => json.encode(a)).toList();
    await prefs.setStringList('bookmarked_articles', updatedData);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _bookmarkedArticlesChanged);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red,
          title: const Text("Bookmarks", style: TextStyle(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context, _bookmarkedArticlesChanged);
            },
          ),
        ),
        body: _bookmarkedArticles.isEmpty
            ? const Center(child: Text("No bookmarks yet"))
            : ListView.builder(
                itemCount: _bookmarkedArticles.length,
                itemBuilder: (context, index) {
                  final article = _bookmarkedArticles[index];
                  final isBookmarked = _isBookmarked(article);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ArticleScreen(article: article)),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (article['urlToImage'] != null &&
                              article['urlToImage'].isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(12)),
                              child: Image.network(article['urlToImage'],
                                  height: 100,
                                  width: 100,
                                  fit: BoxFit.cover),
                            )
                          else
                            Container(
                              height: 100,
                              width: 100,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image),
                            ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article['title'] ?? 'No Title',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.bottomRight,
                                    child: IconButton(
                                      icon: Icon(
                                        isBookmarked
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: isBookmarked
                                            ? Colors.yellow[700]
                                            : Colors.grey,
                                      ),
                                      onPressed: () =>
                                          _toggleBookmark(article),
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
      ),
    );
  }
}
