import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bookmark_screen.dart';
import 'set_preferences_screen.dart';
import '../Services/api_service.dart';
import 'dart:async';  // Add this line

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _name = 'Guest';
  int _bookmarkCount = 0;
  DateTime? _lastBookmarkDate;
  List<String> _preferences = [];
  StreamSubscription? _userDataSubscription;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _setupUserDataListener();
  }

  @override
  void dispose() {
    _userDataSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('username') ?? 'Guest';
    });
  }

  void _setupUserDataListener() {
    final user = _auth.currentUser;
    if (user != null) {
      _userDataSubscription = _firestore
          .collection('userData')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (mounted && snapshot.exists) {
          setState(() {
            _bookmarkCount = snapshot.data()?['bookmarkCount'] ?? 0;
            _lastBookmarkDate = snapshot.data()?['lastBookmarkSaved']?.toDate();
            _preferences = List<String>.from(snapshot.data()?['preferences'] ?? []);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: Text(
                      _name.isNotEmpty ? _name[0].toUpperCase() : 'G',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _auth.currentUser?.email ?? 'No email',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Bookmarks', _bookmarkCount.toString()),
                  _buildStatItem(
                      'Last Saved',
                      _lastBookmarkDate != null
                          ? '${_lastBookmarkDate!.day}/${_lastBookmarkDate!.month}/${_lastBookmarkDate!.year}'
                          : 'Never'
                  ),
                  _buildStatItem('Categories', _preferences.length.toString()),
                ],
              ),
              const SizedBox(height: 32),

              // Actions Section
              Column(
                children: [
                  _buildActionTile(
                    icon: Icons.bookmark,
                    title: 'My Bookmarks',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BookmarkScreen()),
                    ),
                  ),
                  _buildActionTile(
                    icon: Icons.category,
                    title: 'My Preferences',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PreferencesScreen()),
                    ).then((_) => _setupUserDataListener()),
                  ),
                  _buildActionTile(
                    icon: Icons.security,
                    title: 'Privacy Settings',
                    onTap: () {}, // Add your privacy screen navigation
                  ),
                  _buildActionTile(
                    icon: Icons.lock_reset,
                    title: 'Reset Password',
                    onTap: () {}, // Add password reset functionality
                  ),
                  _buildActionTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    isDestructive: true,
                    onTap: () => _showLogoutConfirmation(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : Colors.black,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Future<void> _showLogoutConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      if (mounted) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }
}