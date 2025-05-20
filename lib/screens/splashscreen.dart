// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'dart:math'; // Import the math library to use 'pi' // Import the home screen
import 'package:monocle_chat/screens/onboarding_screen.dart'; // Import the onboarding screen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    // Navigate to the onboarding screen after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        // Ensure the widget is still mounted
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preload and cache the image here
    precacheImage(const AssetImage('assets/logo.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFF4E6), // Updated to match other screens
              Color(0xFFFFE8CC),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _floatController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 4 * sin(_floatController.value * 2 * pi)),
                    child: Opacity(
                      opacity: _floatController.value,
                      child: ClipOval(
                        // Make the logo circular
                        child: Image.asset(
                          'assets/logo.png',
                          height: 200,
                          cacheWidth: 800, // Matches pre-scaled 800x800px
                          cacheHeight: 800,
                          filterQuality: FilterQuality.high,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Messaging, Refined.',
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 18,
                  color: Color(
                    0xFF5C4033,
                  ), // Adjusted text color for better contrast
                ),
              ),
              const SizedBox(height: 50),
              const CircularProgressIndicator(
                color: Color(0xFFD4AF37),
                strokeWidth: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }
}
