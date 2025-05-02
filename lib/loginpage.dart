import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:loginui/HomePage.dart';

class Loginpage extends StatelessWidget {
  const Loginpage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
        backgroundColor: Colors.purpleAccent,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            signInWithGoogle(context);
          },
          child: const Text('Login with Google'),
        ),
      ),
    );
  }

  signInWithGoogle(BuildContext context) async {
    try {
      GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      GoogleSignInAuthentication? googleAuth = await googleUser?.authentication;

      AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      User? user = userCredential.user;
      String? email = user?.email;

      print("Logged in user email: $email");

      if (email != null && email.endsWith('@student.tce.edu')) {
        // Email is allowed
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        // Email not allowed
        await GoogleSignIn().signOut();
        await FirebaseAuth.instance.signOut();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only student.tce.edu accounts are allowed!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Error during Google Sign-In: $e");
    }
  }
}
