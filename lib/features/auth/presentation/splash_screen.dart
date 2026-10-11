import 'package:flutter/material.dart';

/// Shown while the app checks stored auth state on startup.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_print
    print('>>> SplashScreen.build called');
    final primaryColor = Colors.blue.shade700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / Icon Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.campaign_rounded,
                  size: 64,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              
              // App Name
              Text(
                'Solvara',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              
              // Tagline
              Text(
                'Laporkan masalah di sekitar Anda',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 48),
              
              // Loading Indicator
              SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}