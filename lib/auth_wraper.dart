// lib/auth_wrapper.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loginui/HomePage.dart';
import 'package:loginui/SplashScreen.dart';
import 'package:loginui/loginpage.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // Track whether minimum splash duration has passed
  bool _minimumSplashTimePassed = false;
  User? _user;

  @override
  void initState() {
    super.initState();
    
    // 1. Start minimum splash duration timer
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _minimumSplashTimePassed = true);
      }
    });
    
    // 2. Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() => _user = user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen until both conditions are met:
    // 1. Minimum splash time has passed (2 seconds)
    // 2. We've received auth state information
    if (!_minimumSplashTimePassed || _user == null && FirebaseAuth.instance.currentUser == null) {
      return const SplashScreen();
    }
    
    // User is logged in
    if (_user != null || FirebaseAuth.instance.currentUser != null) {
      return const HomePage();
    }
    
    // User is not logged in
    return  LoginPage();
  }
}