import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_data_service.dart';

class SignupPreferenceScreen extends StatefulWidget {
  const SignupPreferenceScreen({super.key});

  @override
  State<SignupPreferenceScreen> createState() => _SignupPreferenceScreenState();
}

class _SignupPreferenceScreenState extends State<SignupPreferenceScreen> {
  // Updated categories
  final Map<String, List<String>> categories = {
    "Local": ["Top", "Business", "Sports", "Entertainment", "Technology"],
    "Foreign": ["Top", "Sports", "Business", "Technology", "Politics", "Entertainment"],
  };

  Set<String> selectedPreferences = {};

  void _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('userPreferences', selectedPreferences.toList());
  }

  void _onChipTap(String category, String subcategory) {
    final key = "$category-$subcategory";
    setState(() {
      if (selectedPreferences.contains(key)) {
        selectedPreferences.remove(key);
      } else {
        selectedPreferences.add(key);
      }
    });
    _savePreferences();
  }

  void _onContinue() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email != null) {
      await UserDataService.setPreferences(email, selectedPreferences.toList());
      // Navigate to home or next screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F0), // Soft white with a reddish tint
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.tune, color: Colors.red, size: 60),
              const SizedBox(height: 12),
              const Text(
                'Select your news preferences',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  letterSpacing: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Choose the topics you care about. You can always change these later in your profile.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ...categories.entries.map((entry) {
                final mainCat = entry.key;
                final subs = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        mainCat,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: mainCat == "Local"
                              ? Colors.orange[800]
                              : Colors.blue[800],
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: subs.map((sub) {
                        final key = "$mainCat-$sub";
                        final isSelected = selectedPreferences.contains(key);
                        return ChoiceChip(
                          label: Text(
                            sub,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: mainCat == "Local"
                              ? Colors.orange[800]
                              : Colors.blue[800],
                          backgroundColor: Colors.grey[200],
                          onSelected: (_) => _onChipTap(mainCat, sub),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: isSelected ? 2 : 0,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                  ],
                );
              }).toList(),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedPreferences.isNotEmpty
                      ? _onContinue
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
