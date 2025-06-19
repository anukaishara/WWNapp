import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'bookmark_screen.dart';
import 'history_screen.dart';
// import 'set_preferences_screen.dart'; // Ensure this file exports the correct class
import 'set_preferences_screen.dart'; // Make sure the class name matches the one defined in this file
import 'reset_password_screen.dart';
import 'manage_privacy_screen.dart';
import '../services/user_data_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _name = prefs.getString('username') ?? 'Guest';
    });
  }

  Future<void> _updatePreferences(String email, List<String> updatedPreferences) async {
    await UserDataService.setPreferences(email, updatedPreferences);
    // ...show success message or update UI...
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 1,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile picture and user name
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person, size: 60, color: Colors.red),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _buildProfileTile(
                      context,
                      icon: Icons.lock_reset,
                      label: 'Reset Password',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
                        );
                      },
                    ),
                    _buildProfileTile(
                      context,
                      icon: Icons.tune,
                      label: 'Set Preferences',
                      onTap: () async {
                        final updatedPreferences = await Navigator.push<List<String>>(
                          context,
                          MaterialPageRoute(builder: (context) => const PreferencesScreen()), // <-- FIXED
                        );
                        if (updatedPreferences != null && updatedPreferences.isNotEmpty) {
                          final email = FirebaseAuth.instance.currentUser?.email;
                          if (email != null) {
                            await _updatePreferences(email, updatedPreferences);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Preferences updated!')),
                            );
                          }
                        }
                      },
                    ),
                    _buildProfileTile(
                      context,
                      icon: Icons.privacy_tip,
                      label: 'Manage Privacy',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ManagePrivacyScreen()),
                        );
                      },
                    ),
                    _buildProfileTile(
                      context,
                      icon: Icons.bookmark,
                      label: 'Bookmarks',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const BookmarkScreen()),
                        );
                      },
                    ),
                    _buildProfileTile(
                      context,
                      icon: Icons.history,
                      label: 'History',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HistoryScreen()),
                        );
                      },
                    ),
                    _buildProfileTile(
                      context,
                      icon: Icons.logout,
                      label: 'Logout',
                      onTap: () => _showLogoutConfirmation(context),
                      color: Colors.red,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTile(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.red, size: 28),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 20,
          color: color ?? Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
      onTap: onTap,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.logout, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Log Out?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Are you sure you want to log out?',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('isLoggedIn', false);
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
