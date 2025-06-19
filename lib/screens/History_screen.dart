import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/history_provider.dart';
import 'article_screen.dart' hide IconButton;
import 'package:firebase_auth/firebase_auth.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final historyArticles = historyProvider.historyArticles;

    // Get current user's email
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) {
      // await UserDataService.setPreferences(email, preferences);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 244, 67, 54),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'History',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 1,
        actions: [
          if (historyArticles.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              tooltip: "Clear History",
              onPressed: () => historyProvider.clearHistory(),
            ),
        ],
      ),
      body: historyArticles.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: historyArticles.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final article = historyArticles[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArticleScreen(article: article),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Article image with rounded corners
                          if (article['urlToImage'] != null &&
                              article['urlToImage'].isNotEmpty)
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(16)),
                              child: Image.network(
                                article['urlToImage'],
                                height: 110,
                                width: 110,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  height: 110,
                                  width: 110,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.red, size: 40),
                                ),
                              ),
                            )
                          else
                            Container(
                              height: 110,
                              width: 110,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(16)),
                              ),
                              child: const Icon(Icons.image, size: 40),
                            ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    article['title'] ?? 'No Title',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (article['publishedAt'] != null)
                                    Text(
                                      _formatDate(article['publishedAt']),
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.grey),
                                    ),
                                ],
                              ),
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 72, color: Colors.red[200]),
            const SizedBox(height: 24),
            const Text(
              "No history yet",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Articles you read will appear here for quick access.",
              style: TextStyle(fontSize: 16, color: Colors.black45),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
