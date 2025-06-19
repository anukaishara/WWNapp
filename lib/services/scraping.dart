import 'package:http/http.dart' as http;
import 'package:rss_dart/dart_rss.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:cloud_firestore/cloud_firestore.dart';

final Map<String, String> localCategoryUrls = {
  "Top": "https://www.adaderana.lk/hot-news/",
  "Business": "https://bizenglish.adaderana.lk/feed/", // RSS feed for Business
  "Sports": "http://www.adaderana.lk/sports-news/",
  "Entertainment": "http://www.adaderana.lk/entertainment-news/",
  "Technology": "https://www.adaderana.lk/technology-news/",
};

/// Utility to clean HTML tags from a string and remove "MORE.." markers
String htmlToPlainText(String htmlString) {
  final document = html_parser.parse(htmlString);
  String text = document.body?.text.trim() ?? '';
  return removeMoreMarkers(text);
}

/// Removes "MORE", "MORE.", "MORE..", "MORE..." (case-insensitive, any number of dots or spaces)
/// and also removes any leftover dots after a space.
String removeMoreMarkers(String text) {
  String cleaned = text.replaceAll(
    RegExp(r'\bMORE\s*\.{0,}\b', caseSensitive: false),
    '',
  );
  cleaned = cleaned.replaceAll(RegExp(r'\s+\.{1,}(\s|$)'), ' ');
  cleaned = cleaned.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  return cleaned;
}

Future<List<Map<String, dynamic>>> scrapeLocalCategory(String category, {bool saveToFirestore = true}) async {
  final url = localCategoryUrls[category];
  if (url == null) return [];

  List<Map<String, dynamic>> scrapedArticles = [];

  if (category == "Business") {
    // Use BizEnglish AdaDerana RSS feed for business news
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return [];
    final rssFeed = RssFeed.parse(response.body);

    scrapedArticles = rssFeed.items.map((item) {
      // Try to extract image from enclosure or media:content
      String? imageUrl;
      if (item.enclosure?.url != null) {
        imageUrl = item.enclosure!.url;
      } else if (item.media?.contents.isNotEmpty == true) {
        imageUrl = item.media!.contents.first.url;
      }
      return {
        'title': item.title ?? '',
        'description': htmlToPlainText(item.description ?? ''),
        'url': item.link ?? '',
        'urlToImage': imageUrl,
        'publishedAt': item.pubDate,
        'content': htmlToPlainText(item.content?.value ?? ''),
        'source': 'BizEnglish AdaDerana',
        'mainCategory': "Local",
        'subCategory': category,
        // 'savedAt' will be added in Firestore
      };
    }).where((a) => a['url'] != null && a['url'] != '').toList();
  } else {
    // Ada Derana structure (Sports, Entertainment, Top, Technology)
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return [];
    final document = html_parser.parse(response.body);

    final articles = <Map<String, dynamic>>[];
    final newsItems = document.querySelectorAll('.news-story, .news-item, .news-box, .news-content, .news-title, .news-image');

    // You may need to adjust selectors based on actual HTML structure
    for (final element in newsItems) {
      final titleElement = element.querySelector('.news-title') ?? element.querySelector('h2');
      final linkElement = titleElement?.querySelector('a');
      final imageElement = element.querySelector('img');
      final descElement = element.querySelector('.news-summary') ?? element.querySelector('p');

      final url = linkElement?.attributes['href'] ?? '';
      if (url.isEmpty) continue;

      articles.add({
        'title': titleElement?.text.trim() ?? '',
        'description': descElement?.text.trim() ?? '',
        'url': url.startsWith('http') ? url : 'https://www.adaderana.lk$url',
        'urlToImage': imageElement?.attributes['src'],
        'publishedAt': null, // You can try to extract date if available
        'content': null,     // You can fetch full content if needed
        'source': 'AdaDerana',
        'mainCategory': "Local",
        'subCategory': category,
      });
    }
    scrapedArticles = articles.where((a) => a['url'] != null && a['url'] != '').toList();
  }

  if (saveToFirestore) {
    // Save to Firestore in the background
    saveLocalArticlesToFirestore(scrapedArticles, mainCategory: "Local", subCategory: category);
  }

  // Return scraped articles immediately (no docId yet)
  return scrapedArticles;
}

Future<void> saveLocalArticlesToFirestore(
  List<Map<String, dynamic>> articles, {
  required String mainCategory,
  required String subCategory,
}) async {
  final firestore = FirebaseFirestore.instance;
  final collection = firestore.collection('articles');
  WriteBatch batch = firestore.batch();

  int savedCount = 0;
  for (final article in articles) {
    if (article['url'] != null && article['url'] != '') {
      final existing = await collection.where('url', isEqualTo: article['url']).limit(1).get();
      if (existing.docs.isEmpty) {
        final docRef = collection.doc();
        batch.set(docRef, {
          ...article,
          'mainCategory': mainCategory,
          'subCategory': subCategory,
          'savedAt': FieldValue.serverTimestamp(),
        });
        savedCount++;
      }
    }
  }

  try {
    await batch.commit();
    print("✅ Local articles saved to Firestore: $savedCount");
  } catch (e) {
    print("❌ Error saving local articles: $e");
  }
}

/// Fetches the full article content from the article's page or RSS.
/// For business, uses the RSS content if provided. For others, scrapes Ada Derana and cleans HTML and "MORE" markers.
Future<String> fetchFullArticleContent(String url, {String? category, String? fullContent}) async {
  if (category == "Business" && fullContent != null && fullContent.isNotEmpty) {
    return htmlToPlainText(fullContent);
  }

  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) return '';
  final document = html_parser.parse(response.body);

  // Ada Derana (Sports, Entertainment, Top, Technology): full article in .news-content
  final contentElement = document.querySelector('.news-content');
  if (contentElement != null) {
    return htmlToPlainText(contentElement.innerHtml);
  }
  return '';
}
