import 'package:flutter/material.dart';
import 'sign_in_screen.dart';

class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SignInScreen()),
            );
          },
          child: const Text('Go to Sign In'),
        ),
      ),
    );
  }
}
