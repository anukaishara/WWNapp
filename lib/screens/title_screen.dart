import 'package:flutter/material.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background image, taking up half the screen
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: MediaQuery.of(context).size.height / 2, // 50% of screen height
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/Title1.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Bottom container, starting from the middle of the image
          Positioned(
            top: MediaQuery.of(context).size.height / 4, // Start from the middle of the image
            left: MediaQuery.of(context).size.width * 0.075, // 5% padding on the left
            right: MediaQuery.of(context).size.width * 0.075, // 5% padding on the right
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App logo
                  const SizedBox(height: 30),
                  const Text(
                    'WWN',
                    style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 202, 27, 14),
                      height: 0.9,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'W',
                          style: TextStyle(
                            color: Color.fromARGB(255, 202, 27, 14),
                          ),
                        ),
                        TextSpan(
                          text: 'orld ',
                          style: TextStyle(
                            color: Color.fromARGB(255, 175, 175, 175),
                          ),
                        ),
                        TextSpan(
                          text: 'W',
                          style: TextStyle(
                            color: Color.fromARGB(255, 202, 27, 14),
                          ),
                        ),
                        TextSpan(
                          text: 'ide ',
                          style: TextStyle(
                            color: Color.fromARGB(255, 175, 175, 175),
                          ),
                        ),
                        TextSpan(
                          text: 'N',
                          style: TextStyle(
                            color: Color.fromARGB(255, 202, 27, 14),
                          ),
                        ),
                        TextSpan(
                          text: 'ews',
                          style: TextStyle(
                            color: Color.fromARGB(255, 175, 175, 175),
                          ),
                        ),
                      ],
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Unlock a world of',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color.fromARGB(134, 55, 55, 55),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'news insights',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color.fromARGB(134, 55, 55, 55),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'tailored just for you!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color.fromARGB(134, 55, 55, 55),
                    ),
                  ),
                  const SizedBox(height: 60),
                  const Text(
                    'Login or create an account to begin!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 216, 59, 48),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Buttons
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 203, 55, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      minimumSize: const Size(200, 50),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignInScreen()),
                      );
                    },
                    child: const Text(
                      'SIGN IN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      minimumSize: const Size(200, 50),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpScreen()),
                      );
                    },
                    child: const Text(
                      'SIGN UP',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
