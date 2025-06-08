import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Services/api_service.dart'; // This contains UserDataService


class SignupPrefernceScreen extends StatefulWidget {
  const SignupPrefernceScreen({super.key});

  @override
  State<SignupPrefernceScreen> createState() => _SignupPrefernceScreenState();
}

class _SignupPrefernceScreenState extends State<SignupPrefernceScreen> {
  final List<String> preferences = ['Sports', 'Business', 'History', 'Technology'];
  Set<String> selectedPreferences = {};
  void _savePreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await UserDataService.saveUserPreferences(user.uid, selectedPreferences.toList());
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('userPreferences', selectedPreferences.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 209, 62, 51),
      
      body: Center(
         child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Select your preferences',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: preferences.map((preference) {
                  bool isSelected = selectedPreferences.contains(preference);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedPreferences.remove(preference);
                        } else {
                          selectedPreferences.add(preference);
                        }
                      });
                      _savePreferences();
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.grey[400] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: Text(
                        preference,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
  


        