import 'package:flutter/material.dart';
import 'package:all_in_one_downloader_video/services/auth_service.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        centerTitle: true,
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.login), // Replace with a Google icon asset later
          label: const Text('Sign in with Google'),
          onPressed: () async {
            await authService.signInWithGoogle();
            // The landing page will automatically rebuild and navigate
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
