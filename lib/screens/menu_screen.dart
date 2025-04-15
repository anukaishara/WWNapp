import 'package:flutter/material.dart';
import 'home_screen.dart'; //Import Home screen
import 'title_screen.dart'; // Import Tilte screen

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool isCategoriesExpanded = false;
  bool isNotificationEnabled = false;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 226, 58, 46), // Match the theme color
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back to HomeScreen
          },
        ),
        title: const Text(
          'Menu',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Home"),
            onTap: () {
              // Handle home navigation
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              );
            },
          ),
          ExpansionTile(
            title: const Text("Categories"),
            onExpansionChanged: (expanded) {
              setState(() {
                isCategoriesExpanded = expanded;
              });
            },
            children: [
              ListTile(title: const Text("All"), onTap: () {}),
              ListTile(title: const Text("Top"), onTap: () {}),
              ListTile(title: const Text("Sports"), onTap: () {}),
              ListTile(title: const Text("Business"), onTap: () {}),
              ListTile(title: const Text("History"), onTap: () {}),
              ListTile(title: const Text("Technology"), onTap: () {}),
              ListTile(title: const Text("Others"), onTap: () {}),
            ],
          ),
          
          SwitchListTile(
            title: const Text("Notification"),
            value: isNotificationEnabled,
            onChanged: (bool value) {
              setState(() {
                isNotificationEnabled = value;
              });
            },
          ),
          ListTile(
            title: const Text("Logout"),
            onTap: () {
              // Handle logout
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TitleScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}