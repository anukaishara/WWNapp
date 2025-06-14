import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:shared_preferences/shared_preferences.dart';

class ArticleScreen extends StatefulWidget {
  
  final Map<String, dynamic> article;
  final bool isBookmarked; 
  final VoidCallback? onBookmarkToggle;

  
  const ArticleScreen({
    super.key,
    required this.article,
    this.isBookmarked = false, 
    this.onBookmarkToggle,     
  });

  
  @override
  _ArticleScreenState createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  String _fullContent = '';
  bool _isLoading = true;
  bool _isBookmarked = false;
  List<Map<String, dynamic>> _bookmarkedArticles = [];

  @override
  void initState() {
    super.initState();
    _fetchFullContent();
    _loadBookmarks();
  }

  Future<void> _fetchFullContent() async {
    try {
      final response = await http.get(Uri.parse(widget.article['url']));
      if (response.statusCode == 200) {
        final document = html.parse(response.body);
        final content = document.querySelector('article')?.text ?? 'No content available';
        setState(() {
          _fullContent = content;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load full content');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load full content: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedData = prefs.getStringList('bookmarked_articles') ?? [];

    setState(() {
      _bookmarkedArticles = bookmarkedData
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .toList();

      _isBookmarked = _bookmarkedArticles.any((item) => item['title'] == widget.article['title']);
    });
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _isBookmarked = !_isBookmarked;
      if (_isBookmarked) {
        _bookmarkedArticles.add(widget.article);
      } else {
        _bookmarkedArticles.removeWhere((item) => item['title'] == widget.article['title']);
      }
    });

    final bookmarkedData = _bookmarkedArticles.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('bookmarked_articles', bookmarkedData);
    await prefs.setStringList('bookmarks', bookmarkedData); // Also update the 'bookmarks' key used in HomeScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: Colors.white,
            ),
            onPressed: _toggleBookmark,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(10),
          child: Divider(color: Colors.white, height: 10, thickness: 10),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.article['urlToImage'] != null && widget.article['urlToImage'].isNotEmpty)
              Image.network(
                widget.article['urlToImage'],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.error, color: Colors.red),
                  );
                },
              ),
            const SizedBox(height: 16),
            Text(
              widget.article['title'] ?? 'No Title',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.article['publishedAt'] != null
                  ? 'Published on: ${_formatDate(widget.article['publishedAt'])}'
                  : '',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Text(
              widget.article['description'] ?? 'No Description',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Text(
                    _fullContent,
                    style: const TextStyle(fontSize: 16),
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
