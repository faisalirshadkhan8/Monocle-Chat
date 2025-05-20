// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5E6D3), // Faded parchment texture
        ),
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPage(
                    title: 'Est. 1920',
                    content: 'MonocleChat',
                    animation:
                        Icons.keyboard, // Placeholder for typewriter animation
                  ),
                  _buildPage(
                    title: 'Sealed with Elegance',
                    content:
                        'A wax-sealed letter transforming into a chat bubble.',
                    animation:
                        Icons
                            .mail, // Placeholder for wax-sealed letter animation
                  ),
                  _buildPage(
                    title: 'Join the Society',
                    content: 'Become part of the MonocleChat legacy.',
                    cta: true,
                  ),
                ],
              ),
            ),
            _buildDots(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String content,
    IconData? animation,
    bool cta = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (animation != null)
            Icon(
              animation,
              size: 100,
              color: Colors.brown,
            ), // Placeholder for animations
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5C4033),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 18,
              color: Color(0xFF5C4033),
            ),
          ),
          if (cta) const SizedBox(height: 30),
          if (cta)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFD4AF37), // Brass button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text(
                'Join the Society',
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          height: 10,
          width: _currentPage == index ? 12 : 8,
          decoration: BoxDecoration(
            color:
                _currentPage == index
                    ? Color(0xFFD4AF37)
                    : Color(0xFF5C4033), // Gold cufflink style
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
