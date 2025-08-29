import 'package:all_in_one_downloader_video/screens/home_screen.dart';
import 'package:all_in_one_downloader_video/screens/sign_in_screen.dart';
import 'package:all_in_one_downloader_video/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasData) {
                    return HomeScreen();
        } else {
          return const SignInScreen();
        }
      },
    );
  }
}
