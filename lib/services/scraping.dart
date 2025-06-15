import 'package:http/http.dart' as http;
import 'package:rss_dart/dart_rss.dart';
import 'package:html/parser.dart' as html_parser;

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
  // Remove 'MORE', 'MORE.', 'MORE..', 'MORE...' (case-insensitive, any number of dots or spaces)
  String cleaned = text.replaceAll(
    RegExp(r'\bMORE\s*\.{0,}\b', caseSensitive: false),
    '',
  );
  // Remove dots that appear after a space and before a line break or string end
  cleaned = cleaned.replaceAll(RegExp(r'\s+\.{1,}(\s|$)'), ' ');
  // Replace multiple spaces with a single space
  cleaned = cleaned.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  return cleaned;
}

Future<List<Map<String, dynamic>>> scrapeLocalCategory(String category) async {
  final url = localCategoryUrls[category];
  if (url == null) return [];

  if (category == "Business") {
    // Use BizEnglish AdaDerana RSS feed for business news
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return [];
    final rssFeed = RssFeed.parse(response.body);

    return rssFeed.items.map((item) {
      String rawContent = item.content?.value ?? item.description ?? '';
      String cleanContent = htmlToPlainText(rawContent);
      // Try to get image from enclosure or media:content
      String? imageUrl;
      if (item.enclosure?.url != null && item.enclosure!.url!.isNotEmpty) {
        imageUrl = item.enclosure!.url;
      } else if (item.media?.thumbnails.isNotEmpty == true) {
        imageUrl = item.media!.thumbnails.first.url;
      } else {
        imageUrl = '';
      }
      return {
        'title': item.title ?? '',
        'url': item.link ?? '',
        'description': htmlToPlainText(item.description ?? ''),
        'urlToImage': imageUrl,
        'category': 'Business',
        'fullContent': cleanContent,
      };
    }).toList();
  } else {
    // Ada Derana structure (Sports, Entertainment, Top, Technology)
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return [];
    final document = html_parser.parse(response.body);
    final List<Map<String, dynamic>> articles = [];

    final newsItems = document.querySelectorAll('.news-story');
    for (final item in newsItems) {
      final titleElement = item.querySelector('h2 a');
      final link = titleElement?.attributes['href'] ?? '';
      final title = titleElement?.text.trim() ?? '';
      final descElement = item.querySelector('p');
      final description = removeMoreMarkers(descElement?.text.trim() ?? '');
      final imageElement = item.querySelector('img');
      final imageUrl = imageElement?.attributes['src'] ?? '';

      if (title.isNotEmpty && link.isNotEmpty) {
        articles.add({
          'title': title,
          'url': link.startsWith('http') ? link : 'http://www.adaderana.lk$link',
          'description': description,
          'urlToImage': imageUrl,
          'category': category,
        });
      }
    }
    return articles;
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
    contentElement.querySelectorAll('script,style').forEach((e) => e.remove());
    return removeMoreMarkers(htmlToPlainText(contentElement.innerHtml));
  }
  return '';
}
