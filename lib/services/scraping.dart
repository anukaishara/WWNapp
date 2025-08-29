import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rss_dart/dart_rss.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'search_service.dart';


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

/// Normalize Unicode punctuation to ASCII, remove zero-width/control chars.
String normalizePlainText(String input) {
  if (input.isEmpty) return input;
  var s = input;
  // Replace common typographic punctuation with ASCII
  const map = {
    '’': "'",
    '‘': "'",
    'ʼ': "'", // U+02BC modifier letter apostrophe
    '‛': "'", // U+201B single high-reversed-9 quotation mark
    '′': "'", // U+2032 prime
    '‵': "'", // U+2035 reversed prime
    '＇': "'", // U+FF07 fullwidth apostrophe
    '´': "'",
    '`': "'",
    '“': '"',
    '”': '"',
    '‟': '"', // U+201F double high-reversed-9 quotation mark
    '″': '"', // U+2033 double prime
    '‶': '"', // U+2036 reversed double prime
    '…': '...',
    '–': '-',
    '—': '-',
    '\u00A0': ' ', // non-breaking space
    '\u202F': ' ', // narrow no-break space
    '\u00AD': '', // soft hyphen
  };
  map.forEach((k, v) => s = s.replaceAll(k, v));
  // Remove zero-width/BOM/directional marks and variation selectors
  s = s.replaceAll(
      RegExp('[\u200B-\u200F\uFEFF\u202A-\u202E\u2060-\u2069\uFE00-\uFE0F]'),
      '');
  // Remove combining diacritical marks
  s = s.replaceAll(RegExp('[\u0300-\u036F]'), '');
  // Remove control chars except \n, \r, \t
  s = s.replaceAll(
      RegExp('[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]'), '');
  // Collapse spaces and trim
  s = s.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  return s;
}

void _debugLogWeird(String label, String value) {
  // Log only if non-ASCII characters present
  final hasNonAscii = value.contains(RegExp('[^\x09\x0A\x0D\x20-\x7E]'));
  if (!hasNonAscii) return;
  final codes = value.runes
      .map((r) => 'U+${r.toRadixString(16).toUpperCase()}')
      .join(' ');
  // ignore: avoid_print
  print('🔎 Non-ASCII in $label: "$value" -> $codes');
}

Future<List<Map<String, dynamic>>> scrapeLocalCategory(String category,
    {bool saveToFirestore = true}) async {
  final url = localCategoryUrls[category];
  if (url == null) return [];

  List<Map<String, dynamic>> scrapedArticles = [];

  if (category == "Business") {
    // Use BizEnglish AdaDerana RSS feed for business news
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return [];
    final rssFeed = RssFeed.parse(_decodeResponseText(response));

    scrapedArticles = rssFeed.items
        .map((item) {
          // Try to extract image from enclosure or media:content
          String? imageUrl;
          if (item.enclosure?.url != null) {
            imageUrl = item.enclosure!.url;
          } else if (item.media?.contents.isNotEmpty == true) {
            imageUrl = item.media!.contents.first.url;
          }
          final title = normalizePlainText(item.title ?? '');
          final desc =
              normalizePlainText(htmlToPlainText(item.description ?? ''));
          _debugLogWeird('RSS title', title);
          _debugLogWeird('RSS desc', desc);
          return {
            'title': title,
            'description': desc,
            'url': item.link ?? '',
            'urlToImage': imageUrl,
            'publishedAt': item.pubDate,
            'content':
                normalizePlainText(htmlToPlainText(item.content?.value ?? '')),
            'source': 'BizEnglish AdaDerana',
            'mainCategory': "Local",
            'subCategory': category,
            // 'savedAt' will be added in Firestore
          };
        })
        .where((a) => a['url'] != null && a['url'] != '')
        .toList();
  } else {
    // Ada Derana structure (Sports, Entertainment, Top, Technology)
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return [];
    final document = html_parser.parse(_decodeResponseText(response));

    final articles = <Map<String, dynamic>>[];
    final newsItems = document.querySelectorAll(
        '.news-story, .news-item, .news-box, .news-content, .news-title, .news-image');

    // You may need to adjust selectors based on actual HTML structure
    for (final element in newsItems) {
      final titleElement =
          element.querySelector('.news-title') ?? element.querySelector('h2');
      final linkElement = titleElement?.querySelector('a');
      final imageElement = element.querySelector('img');
      final descElement =
          element.querySelector('.news-summary') ?? element.querySelector('p');

      final url = linkElement?.attributes['href'] ?? '';
      if (url.isEmpty) continue;

      // Image extraction: prefer data-src / data-original / src
      String? rawImg = imageElement?.attributes['data-src'] ??
          imageElement?.attributes['data-original'] ??
          imageElement?.attributes['src'];
      final normalizedImg = _normalizeAdaDeranaImage(rawImg);

      final t = normalizePlainText(titleElement?.text ?? '');
      final d = normalizePlainText(descElement?.text ?? '');
      _debugLogWeird('HTML title', t);
      _debugLogWeird('HTML desc', d);
      articles.add({
        'title': t,
        'description': d,
        'url': url.startsWith('http') ? url : 'https://www.adaderana.lk$url',
        'urlToImage': normalizedImg,
        'publishedAt': null, // You can try to extract date if available
        'content': null, // You can fetch full content if needed
        'source': 'AdaDerana',
        'mainCategory': "Local",
        'subCategory': category,
      });
    }
    scrapedArticles =
        articles.where((a) => a['url'] != null && a['url'] != '').toList();
  }

  if (saveToFirestore) {
    // Save to Firestore in the background
    saveLocalArticlesToFirestore(scrapedArticles,
        mainCategory: "Local", subCategory: category);
  }

 if (scrapedArticles.isNotEmpty) {
    try {
      SearchService.indexArticles(scrapedArticles);
      print('✅ Local articles indexed in Algolia: ${scrapedArticles.length}');
    } catch (e) {
      print('❌ Failed to index local articles in Algolia: $e');
    }
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
      final existing = await collection
          .where('url', isEqualTo: article['url'])
          .limit(1)
          .get();
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
Future<String> fetchFullArticleContent(String url,
    {String? category, String? fullContent}) async {
  if (category == "Business" && fullContent != null && fullContent.isNotEmpty) {
    return normalizePlainText(htmlToPlainText(fullContent));
  }

  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) return '';
  final document = html_parser.parse(response.body);

  // Ada Derana (Sports, Entertainment, Top, Technology): full article in .news-content
  final contentElement = document.querySelector('.news-content');
  if (contentElement != null) {
    return normalizePlainText(htmlToPlainText(contentElement.innerHtml));
  }
  return '';
}

/// Normalize potentially relative / protocol-relative AdaDerana image URLs to absolute https URLs.
String? _normalizeAdaDeranaImage(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  String url = raw.trim();
  if (url.startsWith('data:'))
    return null; // ignore data URIs (often tracking pixels)
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  if (url.startsWith('//')) return 'https:$url';
  if (url.startsWith('/')) return 'https://www.adaderana.lk$url';
  // If it's a relative path without leading slash
  return 'https://www.adaderana.lk/$url';
}

/// Decode HTTP response text using declared charset; fallback to UTF-8 guess and fix cp1252 punctuation.
String _decodeResponseText(http.Response response) {
  // Try header-declared encoding
  final contentType = response.headers['content-type'] ?? '';
  final charsetMatch =
      RegExp(r'charset=([^;]+)', caseSensitive: false).firstMatch(contentType);
  String decoded;
  if (charsetMatch != null) {
    final charset = charsetMatch.group(1)!.toLowerCase().trim();
    try {
      decoded = Encoding.getByName(charset)?.decode(response.bodyBytes) ??
          utf8.decode(response.bodyBytes, allowMalformed: true);
    } catch (_) {
      decoded = utf8.decode(response.bodyBytes, allowMalformed: true);
    }
  } else {
    decoded = utf8.decode(response.bodyBytes, allowMalformed: true);
  }
  // Fix common cp1252 “smart punctuation” if mis-decoded
  decoded = decoded
          .replaceAll('\u0091', "'") // ‘
          .replaceAll('\u0092', "'") // ’
          .replaceAll('\u0093', '"') // “
          .replaceAll('\u0094', '"') // ”
          .replaceAll('\u0085', '...') // …
          .replaceAll('\u0096', '-') // –
          .replaceAll('\u0097', '-') // —
      ;
  return decoded;
}
