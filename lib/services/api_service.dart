import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // Replace with your API key
  static const String apiKey = '0d2ecc02247c42369c263622a1d38ca7';

  // Fetch news from NewsAPI.org using the /v2/everything endpoint
  static Future<List<dynamic>> fetchEverythingFromNewsAPI({String query = 'news'}) async {
    final url = Uri.parse(
      'https://newsapi.org/v2/everything?q=$query&apiKey=$apiKey&sortBy=publishedAt',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['articles']; // Returns a list of news articles
    } else {
      throw Exception('Failed to load news from NewsAPI: ${response.statusCode}');
    }
  }
}