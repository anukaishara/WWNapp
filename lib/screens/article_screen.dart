import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html; // For parsing HTML

class ArticleScreen extends StatefulWidget {
  final dynamic article;

  const ArticleScreen({Key? key, required this.article}) : super(key: key);

  @override
  _ArticleScreenState createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  String _fullContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFullContent();
  }

  Future<void> _fetchFullContent() async {
    try {
      // Fetch the full article content from the URL
      final response = await http.get(Uri.parse(widget.article['url']));
      if (response.statusCode == 200) {
        // Parse the HTML content
        final document = html.parse(response.body);
        // Extract the article content (customize this based on the website structure)
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
      appBar: AppBar(
        title: Text(widget.article['title'] ?? 'Article'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article image (if available)
            if (widget.article['urlToImage'] != null && widget.article['urlToImage'].isNotEmpty)
              Image.network(
                widget.article['urlToImage'],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child; // Return the image when fully loaded
                  }
                  return Container(
                    height: 200, // Set a fixed height for the placeholder
                    color: Colors.grey[300], // Show a grey placeholder
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200, // Set a fixed height for the error widget
                    color: Colors.grey[300], // Show a grey box for errors
                    child: const Icon(Icons.error, color: Colors.red),
                  );
                },
              ),
            const SizedBox(height: 16),
            // Article title
            Text(
              widget.article['title'] ?? 'No Title',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Article published date
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
            // Article description
            Text(
              widget.article['description'] ?? 'No Description',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            // Full article content
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
    );
  }

  // Helper function to format the date
  String _formatDate(String dateString) {
    final date = DateTime.tryParse(dateString);
    if (date != null) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return '';
  }
}