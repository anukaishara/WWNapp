import 'package:flutter/material.dart';
// Import Home Screen

class VideoScreen extends StatelessWidget {
  const VideoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos'),
        backgroundColor: Colors.red, // Match the theme color
      ),
      body: const Center(
        child: Text(
          'Welcome to the Video Screen!',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
