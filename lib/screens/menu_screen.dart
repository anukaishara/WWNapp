import 'package:flutter/material.dart';
import 'article_screen.dart'; // Import ArticleScreen for navigation

class MenuScreen extends StatefulWidget {
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
        backgroundColor: Colors.red, // Match the theme color
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
            title: Text("Home"),
            onTap: () {
              // Handle home navigation
            },
          ),
          ExpansionTile(
            title: Text("Categories"),
            onExpansionChanged: (expanded) {
              setState(() {
                isCategoriesExpanded = expanded;
              });
            },
            children: [
              ListTile(title: Text("All"), onTap: () {}),
              ListTile(title: Text("Top"), onTap: () {}),
              ListTile(title: Text("Sports"), onTap: () {}),
              ListTile(title: Text("Business"), onTap: () {}),
              ListTile(title: Text("History"), onTap: () {}),
              ListTile(title: Text("Technology"), onTap: () {}),
              ListTile(title: Text("Others"), onTap: () {}),
            ],
          ),
          ListTile(
            title: Text("Saved Items"),
            onTap: () {
              // Handle saved items navigation
            },
          ),
          SwitchListTile(
            title: Text("Notification"),
            value: isNotificationEnabled,
            onChanged: (bool value) {
              setState(() {
                isNotificationEnabled = value;
              });
            },
          ),
          ListTile(
            title: Text("Logout"),
            onTap: () {
              // Handle logout
            },
          ),
        ],
      ),
    );
  }
}