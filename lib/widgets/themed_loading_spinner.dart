import 'package:flutter/material.dart';

class ThemedLoadingSpinner extends StatefulWidget {
  const ThemedLoadingSpinner({super.key});

  @override
  State<ThemedLoadingSpinner> createState() => _ThemedLoadingSpinnerState();
}

class _ThemedLoadingSpinnerState extends State<ThemedLoadingSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: RotationTransition(
        turns: _controller,
        child: SizedBox(
          width: 50,
          height: 50,
          // Placeholder for Old Money themed brass pocket watch spinner
          // Replace 'assets/logo.png' with your actual pocket watch image
          // e.g., 'assets/images/pocket_watch.png'
          // Ensure the image is added to pubspec.yaml assets.
          child: Image.asset(
            'assets/logo.png', // 
            color: const Color(
              0xFFC5A258,
            ), // Brass accent tint for the placeholder
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
    // 
    // For a more complex animation (e.g., spinning hands, ticking),
    // you might need a more complex widget structure or a custom painter.
  }
}
