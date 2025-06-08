import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'article_screen.dart';
import '../Services/api_service.dart'; // for UserDataService

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  _BookmarkScreenState createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  List<Map<String, dynamic>> _bookmarkedArticles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBookmarks();
  }

  Future<void> _fetchBookmarks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final bookmarkUrls = await UserDataService.getUserBookmarks(user.uid);
      final firestore = FirebaseFirestore.instance;
      final articles = <Map<String, dynamic>>[];

      for (final url in bookmarkUrls) {
        final query = await firestore
            .collection('articles')
            .where('url', isEqualTo: url)
            .get();
        if (query.docs.isNotEmpty) {
          articles.add(query.docs.first.data());
        }
      }

      setState(() {
        _bookmarkedArticles = articles;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarkedArticles.isEmpty
          ? const Center(child: Text('No bookmarks yet'))
          : ListView.builder(
        itemCount: _bookmarkedArticles.length,
        itemBuilder: (context, index) {
          final article = _bookmarkedArticles[index];
          return ListTile(
            title: Text(article['title'] ?? 'No Title'),
            subtitle: Text(article['source'] ?? 'Unknown Source'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ArticleScreen(article: article),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
