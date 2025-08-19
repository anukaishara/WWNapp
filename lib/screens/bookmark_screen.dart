import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/bookmark_provider.dart';
import 'article_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookmarkScreen extends StatelessWidget {
  const BookmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = context.watch<BookmarkProvider>();
    final bookmarkedArticles = bookmarkProvider.bookmarkedArticles;

    // Get current user's email
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) {
      // await UserDataService.setPreferences(email, preferences);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          "Bookmarks",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 1,
      ),
      body: bookmarkedArticles.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: bookmarkedArticles.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final article = bookmarkedArticles[index];
                final isBookmarked = bookmarkProvider.isBookmarked(article);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArticleScreen(article: article),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        // Center image and text vertically within the card
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                              // Reduced vertical padding to help centering
                              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                  const SizedBox(height: 12),
                                  // Prepare source name before the Row widget
                                  Builder(
                                    builder: (context) {
                                      final rawSource = article['source'];
                                      final sourceName = rawSource is Map
                                          ? (rawSource['name'] ?? 'Unknown')
                                          : (rawSource is String
                                              ? rawSource
                                              : 'Unknown');
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              isBookmarked
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: isBookmarked
                                                  ? Colors.yellow[700]
                                                  : Colors.grey,
                                              size: 28,
                                            ),
                                            onPressed: () => context
                                                .read<BookmarkProvider>()
                                                .toggleBookmark(article),
                                            tooltip: isBookmarked
                                                ? 'Remove Bookmark'
                                                : 'Add Bookmark',
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            sourceName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
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
            Icon(Icons.bookmark_border, size: 72, color: Colors.red[200]),
            const SizedBox(height: 24),
            const Text(
              "No bookmarks yet",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Tap the star icon on any article to save it here for quick access.",
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
