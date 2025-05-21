// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:monocle_chat/models/message_model.dart';
import 'package:monocle_chat/widgets/chat_bubble.dart';
import 'package:intl/intl.dart';

final currentUserProvider = Provider<User?>((ref) {
  return FirebaseAuth.instance.currentUser;
});

final messagesStreamProvider = StreamProvider.autoDispose
    .family<List<MessageModel>, String>((ref, chatRoomId) {
      final firestore = FirebaseFirestore.instance;
      return firestore
          .collection('chat_rooms')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => MessageModel.fromFirestore(doc))
                    .toList(),
          );
    });

class ChatDetailScreen extends ConsumerStatefulWidget {
  static const String routeName = '/chat_detail'; // Add this line

  final String name;
  final String? profilePicture;
  final String receiverId;
  final String chatRoomId;

  const ChatDetailScreen({
    super.key,
    required this.name,
    this.profilePicture,
    required this.receiverId,
    required this.chatRoomId,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _sendMessage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (_messageController.text.trim().isEmpty || currentUser == null) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      // Create message document
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add({
            'senderId': currentUser.uid,
            'receiverId': widget.receiverId,
            'text': messageText,
            'timestamp': FieldValue.serverTimestamp(),
            'isSeen': false,
          });

      // Update chat room metadata
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .update({
            'lastMessage': messageText,
            'lastMessageTimestamp': FieldValue.serverTimestamp(),
            'lastMessageSenderId': currentUser.uid,
          });

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsyncValue = ref.watch(
      messagesStreamProvider(widget.chatRoomId),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B1A0F),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage:
                  widget.profilePicture != null &&
                          widget.profilePicture!.isNotEmpty
                      ? NetworkImage(widget.profilePicture!)
                      : const AssetImage('assets/profile_pictures/dummy.jpg')
                          as ImageProvider,
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
      ),
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFFFF4E6)),
        child: Column(
          children: [
            Expanded(
              child: messagesAsyncValue.when(
                data: (messages) {
                  if (messages.isEmpty) {
                    return const Center(
                      child: Text(
                        'No messages yet. Say hello!',
                        style: TextStyle(fontFamily: 'CormorantGaramond'),
                      ),
                    );
                  }
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _scrollToBottom(),
                  );
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final currentUserId =
                          FirebaseAuth.instance.currentUser?.uid;
                      final isSentByCurrentUser =
                          message.senderId == currentUserId;

                      // Mark messages as seen
                      if (!isSentByCurrentUser &&
                          !message.isSeen &&
                          message.messageId.isNotEmpty) {
                        FirebaseFirestore.instance
                            .collection('chat_rooms')
                            .doc(widget.chatRoomId)
                            .collection('messages')
                            .doc(message.messageId)
                            .update({'isSeen': true})
                            .catchError((error) {
                              print("Error updating isSeen: $error");
                            });
                      }

                      // Timestamp formatting
                      String formattedTimestamp;
                      final messageDateTime = message.timestamp.toDate();
                      final now = DateTime.now();
                      if (now.year == messageDateTime.year &&
                          now.month == messageDateTime.month &&
                          now.day == messageDateTime.day) {
                        formattedTimestamp = DateFormat.jm().format(
                          messageDateTime,
                        );
                      } else if (now.year == messageDateTime.year &&
                          now.month == messageDateTime.month &&
                          now.day - messageDateTime.day == 1) {
                        formattedTimestamp =
                            'Yesterday ${DateFormat.jm().format(messageDateTime)}';
                      } else {
                        formattedTimestamp = DateFormat.yMd().add_jm().format(
                          messageDateTime,
                        );
                      }

                      return ChatBubble(
                        message: message.text,
                        timestamp: formattedTimestamp,
                        isSent: isSentByCurrentUser,
                        isSeen: message.isSeen,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, _) =>
                        Center(child: Text('Error: ${error.toString()}')),
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Compose your message...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 10),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF2B1A0F)),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
