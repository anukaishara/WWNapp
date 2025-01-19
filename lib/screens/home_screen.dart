import 'package:flutter/material.dart';
import 'profile_screen.dart'; // Ensure this path is correct based on your project structure

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Track the selected category
  String _selectedCategory = "For you";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red, // Red background
        title: const Text(
          'WWN',
          style: TextStyle(
            color: Colors.white, // White title color
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true, // Center the title
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white), // Menu icon
          onPressed: () {
            // Handle menu action
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white), // Profile icon
            onPressed: () {
              // Navigate to ProfileScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 10, // White ribbon height
              color: Colors.white, // White ribbon color
            ),
            const SizedBox(height: 8),
            _buildCategoryFilters(), // Horizontal category filters
            Expanded(
              child: _buildPlaceholderContent(), // Use Expanded for flexible space
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildCustomFooter(), // Replace BottomAppBar
    );
  }

  // Horizontal Category Filters
  Widget _buildCategoryFilters() {
    final categories = [
      "For you",
      "All",
      "News",
      "Sports",
      "Business",
      "History",
      "Technology",
      "Others"
    ];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 40.0, // Set a fixed height for the slider
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    // Update the selected category when a button is pressed
                    _selectedCategory = category;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedCategory == category
                      ? Colors.white
                      : Colors.red, // White for selected, red for others
                  foregroundColor: _selectedCategory == category
                      ? Colors.black
                      : Colors.white, // Black text for selected, white for others
                  side: BorderSide(
                    color: _selectedCategory == category
                        ? Colors.black
                        : Colors.red,
                    width: 1.0,
                  ), // Black border for selected
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                ),
                child: Text(category),
              ),
            );
          },
        ),
      ),
    );
  }

  // Placeholder Content
  Widget _buildPlaceholderContent() {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 60), // Ensure padding avoids overlap with BottomNavigationBar
      itemCount: 5, // Number of placeholder cards
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Placeholder for image
                Container(
                  height: 80, // Height for the image
                  width: 80, // Width for the image
                  color: Colors.grey[300], // Blank grey space
                ),
                const SizedBox(width: 16), // Space between image and text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Placeholder for title
                      Container(
                        height: 20,
                        width: double.infinity,
                        color: Colors.grey[300], // Blank grey space
                      ),
                      const SizedBox(height: 8),
                      // Placeholder for description
                      Container(
                        height: 16,
                        width: 150,
                        color: Colors.grey[300], // Blank grey space
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Custom Footer Navigation
  Widget _buildCustomFooter() {
    return BottomNavigationBar(
      backgroundColor: Colors.red, // Red background color
      selectedItemColor: Colors.white, // White for selected item
      unselectedItemColor: Colors.white70, // Light white for unselected items
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.video_library),
          label: 'Videos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
      ],
      currentIndex: 0, // Set the active item
      onTap: (index) {
        // Handle navigation based on index
        switch (index) {
          case 0:
            // Stay on Home
            break;
          case 1:
            // Navigate to Videos
            break;
          case 2:
            // Navigate to Search
            break;
        }
      },
    );
  }
}
