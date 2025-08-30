import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/scraping.dart';
import '../services/bookmark_provider.dart';
import '../services/history_provider.dart';
import '../services/user_data_service.dart';

class ArticleScreen extends StatefulWidget {
  final Map<String, dynamic> article;

  const ArticleScreen({super.key, required this.article});

  @override
  _ArticleScreenState createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  String _fullContent = '';
  bool _isLoading = true;
  double _fontSize = 18; // Accessible adjustable font size
  double _scrollProgress = 0; // Reading progress 0..1

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use a fallback for docId if it's missing
      final articleId = widget.article['docId'] ?? widget.article['url'];
      final mainCategory = widget.article['mainCategory'];
      final subCategory = widget.article['subCategory'];
      debugPrint('ArticleScreen opened with: docId=$articleId, mainCategory=$mainCategory, subCategory=$subCategory');
      if (articleId != null && mainCategory != null && subCategory != null) {
        // Ensure the article map has a docId for history
        final articleForHistory = Map<String, dynamic>.from(widget.article);
        articleForHistory['docId'] = articleId;
        context.read<HistoryProvider>().addToHistory(articleForHistory);
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

  // Split content into readable paragraphs. If there are no blank lines, fall back to sentence grouping.
  List<String> _paragraphs() {
    if (_fullContent.isEmpty) return const [];
    // Normalize line endings
    final normalized = _fullContent.replaceAll('\r\n', '\n');
    final rawParagraphs = normalized
        .split(RegExp(r'\n{2,}'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (rawParagraphs.length > 1) return rawParagraphs;

    // Fallback: create paragraphs by grouping sentences if original text had no blank lines
    final sentences = normalized.split(RegExp(r'(?<=[.!?])\s+'));
    final List<String> grouped = [];
    final buffer = StringBuffer();
    int count = 0;
    for (final s in sentences) {
      if (s.trim().isEmpty) continue;
      buffer.write(s.trim());
      buffer.write(' ');
      count++;
      if (count >= 3) {
        // group 3 sentences per paragraph
        grouped.add(buffer.toString().trim());
        buffer.clear();
        count = 0;
      }
    }
    if (buffer.isNotEmpty) grouped.add(buffer.toString().trim());
    return grouped.isEmpty ? [normalized] : grouped;
  }

  void _changeFontSize(double delta) {
    setState(() {
      _fontSize = (_fontSize + delta).clamp(14, 26);
    });
  }

  Future<void> _handleBookmarkTap() async {
    final bookmarkProvider = context.read<BookmarkProvider>();
    final currentlyBookmarked = bookmarkProvider.isBookmarked(widget.article);

    // pick an id that UserDataService can use (fallbacks)
    final articleId =
        widget.article['docId'] ?? widget.article['id'] ?? widget.article['url'];

    // debug: log article and id
    debugPrint('[_handleBookmarkTap] article: ${widget.article}');
    debugPrint('[_handleBookmarkTap] resolved articleId: $articleId');
    debugPrint('[_handleBookmarkTap] currentlyBookmarked: $currentlyBookmarked');

    if (articleId == null ||
        (articleId is String && articleId.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot bookmark this article (missing id).')),
      );
      return;
    }

    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to bookmark articles.')),
      );
      return;
    }

    final mainCategory = widget.article['mainCategory'] ?? 'Unknown';
    final subCategory = widget.article['subCategory'];
    debugPrint('mainCategory: $mainCategory, subCategory: $subCategory');

    try {
      if (!currentlyBookmarked) {
        // remote add first
        await UserDataService.addBookmark(email, articleId, mainCategory, subCategory);
        // only update provider when remote succeeded
        bookmarkProvider.toggleBookmark(widget.article);

        // if you implemented _updateBookmarkCount(...) call it here:
        // await _updateBookmarkCount(true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article bookmarked')),
        );
      } else {
        // remote remove first
        debugPrint('Removing bookmark: email=$email, articleId=$articleId, mainCategory=$mainCategory, subCategory=$subCategory');
        await UserDataService.removeBookmark(email, articleId, mainCategory, subCategory);
        bookmarkProvider.toggleBookmark(widget.article);

        // await _updateBookmarkCount(false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bookmark removed')),
        );
      }
    } catch (e, st) {
      debugPrint('[_handleBookmarkTap] error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update bookmark. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = context.watch<BookmarkProvider>();
    if (!bookmarkProvider.isLoaded) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }
    final isBookmarked = bookmarkProvider.isBookmarked(widget.article);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.maxScrollExtent > 0) {
                setState(() {
                  _scrollProgress = (notification.metrics.pixels /
                          notification.metrics.maxScrollExtent)
                      .clamp(0, 1);
                });
              }
              return false;
            },
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.red,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  pinned: true,
                  expandedHeight: 260,
                  elevation: 0,
                  // Removed font size actions from app bar (moved below image)
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (widget.article['urlToImage'] != null &&
                            widget.article['urlToImage'].isNotEmpty)
                          Image.network(
                            widget.article['urlToImage'],
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Container(color: Colors.grey[300]);
                            },
                            errorBuilder: (c, e, s) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image,
                                  size: 72, color: Colors.red),
                            ),
                          ),
                        // Gradient overlay for readability
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.center,
                              colors: [Colors.black54, Colors.transparent],
                            ),
                          ),
                        ),
                        // Title at bottom
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              widget.article['title'] ?? 'No Title',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.15,
                                shadows: [
                                  Shadow(
                                      color: Colors.black54,
                                      blurRadius: 8,
                                      offset: Offset(0, 2)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Bookmark icon overlay moved to bottom-right to avoid overlapping with AppBar action icons
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 24,
                            child: IconButton(
                              icon: Icon(
                                isBookmarked
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                                color: isBookmarked
                                    ? Colors.yellow[700]
                                    : Colors.red,
                                size: 28,
                              ),
                              tooltip: isBookmarked
                                  ? 'Remove Bookmark'
                                  : 'Add Bookmark',
                              onPressed: _handleBookmarkTap,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Font size controls bar (moved below header image for visibility)
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.text_fields, color: Colors.red),
                        const SizedBox(width: 12),
                        const Text('Font size',
                            style:
                                TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        _FontSizeButton(
                            icon: Icons.remove,
                            onTap: () => _changeFontSize(-1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(_fontSize.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 16)),
                        ),
                        _FontSizeButton(
                            icon: Icons.add, onTap: () => _changeFontSize(1)),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 28, 22, 34),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _isLoading
                              ? const Center(
                                  key: ValueKey('loader'),
                                  child: Padding(
                                    padding: EdgeInsets.all(24.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : (_fullContent.isEmpty
                                  ? const Text(
                                      'Full article not available.',
                                      key: ValueKey('empty'),
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.grey),
                                    )
                                  : _ArticleBody(
                                      fontSize: _fontSize,
                                      publishedAt:
                                          widget.article['publishedAt'],
                                      paragraphs: _paragraphs(),
                                    )),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Thin reading progress indicator just below status bar / app bar
          Positioned(
            top: MediaQuery.of(context).padding.top + kToolbarHeight - 2,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              value:
                  _scrollProgress == 0 && _isLoading ? null : _scrollProgress,
              minHeight: 3,
              backgroundColor: Colors.black26,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.yellow),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.red,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.video_library), label: 'Videos'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        ],
      ),
    );
  }
}

// Extracted body widget for readability & separation of concerns.
class _ArticleBody extends StatelessWidget {
  final List<String> paragraphs;
  final String? publishedAt;
  final double fontSize;
  const _ArticleBody(
      {required this.paragraphs,
      required this.publishedAt,
      required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final dateText =
        (publishedAt != null) ? _formatDateStatic(publishedAt!) : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (dateText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              'Published: $dateText',
              style: const TextStyle(
                  fontSize: 14, color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
        ...paragraphs.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: SelectableText(
              p,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontSize: fontSize,
                height: 1.65,
                letterSpacing: 0.15,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatDateStatic(String dateString) {
    final date = DateTime.tryParse(dateString);
    if (date != null) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return '';
  }
}

class _FontSizeButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _FontSizeButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 20, color: Colors.red),
      ),
    );
  }
}
