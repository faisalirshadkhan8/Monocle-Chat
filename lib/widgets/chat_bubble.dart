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
    this.isSeen = true,
    this.isSent = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSent ? const Color(0xFFD3D3D3) : const Color(0xFFE6E6E6),
        borderRadius: BorderRadius.circular(12),
      ),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: TextStyle(
              color: isSent ? Colors.white : const Color(0xFF3A1F1D),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timestamp,
                style: TextStyle(
                  color: isSent ? Colors.white70 : Colors.black54,
                  fontSize: 12,
                ),
              ),
              if (isSent) ...[
                const SizedBox(width: 5),
                Icon(
                  Icons.done_all,
                  size: 16,
                  color: isSeen ? Colors.blue : Colors.white70,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
