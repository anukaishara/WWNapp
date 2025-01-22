import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Services/firebase_service.dart';
import 'screens/title_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: 'Your App Title',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const TitleScreen(), // Start with the TitleScreen

    );
  }
}


