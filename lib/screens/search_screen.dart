import 'package:flutter/material.dart';
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> recentSearches = []; // Stores recent searches

  void _performSearch(String query) {
    if (query.isNotEmpty && !recentSearches.contains(query)) {
      setState(() {
        recentSearches.insert(0, query); // Add latest search to the top
        if (recentSearches.length > 5) {
          recentSearches.removeLast(); // Keep only the latest 5 searches
        }
      });
    }
    _searchController.clear(); // Clear input after searching
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 187, 51, 41), // Match the theme color
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back to HomeScreen
          },
        ),
        title: const Text(
          'WWN',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
     body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for news category....',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[300],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _performSearch,
            ),
            const SizedBox(height: 20),

            // Recent Searches Section
            const Text(
              "Recent Searches",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Display either "No recent searches" or a list of past searches
            recentSearches.isEmpty
                ? const Text("No recent searches",
                    style: TextStyle(color: Colors.grey))
                : Column(
                    children: recentSearches
                        .map(
                          (search) => ListTile(
                            title: Text(search),
                            leading: const Icon(Icons.history, color: Colors.grey),
                            onTap: () {
                              _searchController.text = search;
                              _performSearch(search);
                            },
                          ),
                        )
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }
}