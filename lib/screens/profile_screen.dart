import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red, // Red background for ProfileScreen
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold, // Bold the title
            fontSize: 24, // Increased font size for the title
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // Go back to HomeScreen
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile picture and user name
              Row(
                children: [
                  // Profile picture placeholder
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300], // Placeholder color
                  ),
                  const SizedBox(width: 16),
                  // Blank space for the user's name
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        hintStyle: TextStyle(color: Colors.grey[600]),
                      ),
                      style: const TextStyle(
                        fontSize: 24, // Increased font size for name
                        fontWeight: FontWeight.bold, // Bold text
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Profile options
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Reset Password
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 20, // Font size for box text
                        color: Colors.black,
                      ),
                    ),
                  ),
                  // Set Preferences
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Set Preferences',
                      style: TextStyle(
                        fontSize: 20, // Font size for box text
                        color: Colors.black,
                      ),
                    ),
                  ),
                  // Manage Privacy
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Manage Privacy',
                      style: TextStyle(
                        fontSize: 20, // Font size for box text
                        color: Colors.black,
                      ),
                    ),
                  ),
                  // Logout
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 20, // Font size for box text
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
