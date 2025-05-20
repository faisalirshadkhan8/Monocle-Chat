// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final String timestamp;
  final bool isSeen;

  const ChatBubble({
    super.key,
    required this.message,
    required this.timestamp,
    required this.isSeen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4E6),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Lora',
              fontSize: 14,
              color: Color(0xFF3A1F1D),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timestamp,
                style: const TextStyle(
                  fontFamily: 'Trajan Pro',
                  fontSize: 12,
                  color: Color(0xFF5A4A3C),
                ),
              ),
              if (isSeen)
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Color(0xFFD4AF37),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
