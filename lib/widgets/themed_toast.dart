// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

void showThemedToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: const TextStyle(
          color: Colors.white, // White text for contrast
          fontFamily: 'Lora', // Consistent Old Money font
          fontSize: 15,
        ),
        textAlign: TextAlign.center,
      ),
      backgroundColor: const Color(0xFF8B0000), // Crimson for errors/alerts
      behavior: SnackBarBehavior.floating, // Scroll-style (floating)
      elevation: 4.0, // Subtle shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0), // Slightly rounded edges
        side: BorderSide(
          color: const Color(0xFFC5A258).withOpacity(0.5),
          width: 1,
        ), // Brass accent border
      ),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      duration: const Duration(seconds: 4), // How long the toast is visible
    ),
  );
  // 
}
