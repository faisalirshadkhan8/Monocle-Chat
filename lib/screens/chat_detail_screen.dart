import 'package:flutter/material.dart';
import 'package:monocle_chat/widgets/chat_bubble.dart';

class ChatDetailScreen extends StatefulWidget {
  final String name;
  final String? profilePicture; // Changed to nullable String
  final String receiverId; // Added receiverId
  final String chatRoomId; // Added chatRoomId

  const ChatDetailScreen({
    super.key,
    required this.name,
    this.profilePicture, // Changed to nullable
    required this.receiverId, // Added receiverId
    required this.chatRoomId, // Added chatRoomId
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    // Add some dummy messages for testing
    _messages.addAll([
      {
        'text': 'Good day to you, my friend.',
        'timestamp': '10:30 AM',
        'isSent': false,
      },
      {
        'text': 'Indeed, a splendid morning.',
        'timestamp': '10:32 AM',
        'isSent': true,
      },
      {
        'text': 'Shall we meet for tea later?',
        'timestamp': '10:33 AM',
        'isSent': false,
      },
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B1A0F),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  widget.profilePicture != null &&
                          widget.profilePicture!.isNotEmpty
                      ? NetworkImage(
                        widget.profilePicture!,
                      ) // Use NetworkImage if URL exists
                      : const AssetImage(
                            'assets/profile_pictures/dummy.jpg', // Fallback local asset
                          )
                          as ImageProvider,
              child:
                  widget.profilePicture == null ||
                          widget.profilePicture!.isEmpty
                      ? const Icon(
                        Icons.person,
                        color: Color(0xFF2B1A0F),
                      ) // Fallback icon
                      : null,
            ),
            const SizedBox(width: 10),
            Text(
              widget.name,
              style: const TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 20,
                color: Color(0xFFD4AF37),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFFD4AF37)),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFFFF4E6)),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return Align(
                    alignment:
                        message['isSent']
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                    child: ChatBubble(
                      message: message['text'],
                      timestamp: message['timestamp'],
                      isSent: message['isSent'],
                      isSeen: message['isSent'],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              height: 70,
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () {},
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Compose your message...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      if (_messageController.text.isNotEmpty) {
                        setState(() {
                          _messages.add({
                            'text': _messageController.text,
                            'timestamp':
                                '${DateTime.now().hour}:${DateTime.now().minute}',
                            'isSent': true,
                            'isSeen': false,
                          });
                          _messageController.clear();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
