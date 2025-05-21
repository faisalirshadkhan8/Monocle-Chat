// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final String timestamp;
  final bool isSeen;
  final bool isSent;

  const ChatBubble({
    super.key,
    required this.message,
    required this.timestamp,
    required this.isSeen, // Made isSeen required
    required this.isSent, // Made isSent required
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor =
        isSent
            ? const Color(0xFFE1F5FE)
            : const Color(
              0xFFF0F0F0,
            ); // Light blue for sent, light grey for received
    final textColor = isSent ? Colors.black87 : Colors.black87;
    final alignment =
        isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final tickColor =
        isSeen
            ? Colors.blueAccent
            : Colors.grey; // Blue if seen, grey otherwise

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft:
              isSent ? const Radius.circular(16) : const Radius.circular(0),
          bottomRight:
              isSent ? const Radius.circular(0) : const Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1), // changes position of shadow
          ),
        ],
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      child: Column(
        crossAxisAlignment:
            alignment, // Align text and timestamp based on sender
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: TextStyle(color: textColor, fontSize: 16)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timestamp,
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              if (isSent) ...[
                const SizedBox(width: 5),
                Icon(
                  Icons.done_all,
                  size: 16,
                  color: tickColor, // Use dynamic tickColor
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
