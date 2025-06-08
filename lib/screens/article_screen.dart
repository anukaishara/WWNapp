import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Services/api_service.dart'; // This contains UserDataService


class ArticleScreen extends StatefulWidget {
  final dynamic article;
  final Function(String)? onBookmark;


  const ArticleScreen({
    Key? key,
    required this.article,
    this.onBookmark,
  }) : super(key: key);

  @override
  _ArticleScreenState createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _fullContent = '';
  bool _isLoading = true;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _fetchFullContent();
    _checkBookmarkStatus();
    _isBookmarked = widget.article['isBookmarked'] ?? false;

  }

  Future<void> _checkBookmarkStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final bookmarks = await UserDataService.getUserBookmarks(user.uid);
      setState(() {
        _isBookmarked = bookmarks.contains(widget.article['url']);
      });
    }
  }
  Future<void> _toggleBookmark() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (_isBookmarked) {
        await UserDataService.removeBookmark(user.uid, widget.article['url']);
      } else {
        await UserDataService.saveBookmark(user.uid, widget.article['url']);
      }
      setState(() {
        _isBookmarked = !_isBookmarked;
      });
      if (widget.onBookmark != null && widget.article['url'] != null) {
        widget.onBookmark!(widget.article['url']);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //  red AppBar 
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
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.article['publishedAt'] != null
                  ? 'Published on: ${_formatDate(widget.article['publishedAt'])}'
                  : '',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.article['description'] ?? 'No Description',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Text(
                    _fullContent,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
          ],
        ),
      ),

      // Bottom Navigation Bar 
      bottomNavigationBar: BottomNavigationBar(
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