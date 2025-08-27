import 'package:flutter/material.dart';
import '../widgets/advanced_search_widget.dart';
import 'article_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          'Advanced Search',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: AdvancedSearchWidget(
        onArticleSelected: (article) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleScreen(
                article: {
                  ...article,
                  'mainCategory': article['mainCategory'] ?? 'General',
                  'subCategory': article['subCategory'] ?? 'News',
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
