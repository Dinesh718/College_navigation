import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import this
import 'package:loginui/SplashScreen.dart';
import 'loginpage.dart'; // Import your login page

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
      debugShowCheckedModeBanner: false, // Optional: remove the debug banner
      home: SplashScreen(), // Set your login page as the home page
    );
  }
}
