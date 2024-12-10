import 'package:flutter/material.dart';
import 'sign_in_screen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Red background, taking up half the screen
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height / 2, // 50% of screen height
              color: const Color.fromARGB(255, 187, 51, 41), // Solid red color
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 50), // Space from the top of the screen
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'New to Here?',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'By signing up, you agree to our',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'privacy policy and Terms of Service.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Text container starting from the middle of the red background
          Positioned(
            top: MediaQuery.of(context).size.height / 4, // Start from the middle of the background
            left: MediaQuery.of(context).size.width * 0.05, // 5% padding on the left
            right: MediaQuery.of(context).size.width * 0.05, // 5% padding on the right
            bottom: 0,
            child: SingleChildScrollView( // Enable scrolling
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16), // Add space before email area
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'E-mail',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.visibility_off),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 10),
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.visibility_off),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Checkbox(value: false, onChanged: (value) {}),
                        const Text('Remember me')
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 203, 55, 45),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () {},
                      child: const Text(
                        'SIGN UP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            // Handle Google sign up
                          },
                          icon: Image.asset('assets/google_icon.png', height: 24), // Replace with your Google icon asset
                          label: const Text('Sign up with Google'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 216, 215, 215),
                            side: const BorderSide(color: Color.fromARGB(255, 216, 215, 215)),
                            foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                            minimumSize: const Size(double.infinity, 50), // Set width to double.infinity
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Handle Facebook sign up
                          },
                          icon: Image.asset('assets/facebook_icon.png', height: 24), // Replace with your Facebook icon asset
                          label: const Text('Sign up with Facebook'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 216, 215, 215),
                            side: const BorderSide(color: Color.fromARGB(255, 216, 215, 215)),
                            foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                            minimumSize: const Size(double.infinity, 50), // Set width to double.infinity
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            // Handle Apple sign up
                          },
                          icon: Image.asset('assets/apple_icon.png', height: 24), // Replace with your Apple icon asset
                          label: const Text('Sign up with Apple ID'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 216, 215, 215),
                            side: const BorderSide(color: Color.fromARGB(255, 216, 215, 215)),
                            foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                            minimumSize: const Size(double.infinity, 50), // Set width to double.infinity
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20), // Add space before the footer text
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignInScreen()),
                        );
                      },
                      child: const Text(
                        'Already Have an Account?',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
