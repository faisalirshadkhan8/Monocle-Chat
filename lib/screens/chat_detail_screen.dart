// ignore_for_file: avoid_print

import 'dart:io'; // Import for File

import 'package:flutter/cupertino.dart'; // Import for Cupertino icons
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import for Firebase Storage
import 'package:image_picker/image_picker.dart'; // Import for image_picker
import 'package:monocle_chat/models/message_model.dart';
import 'package:monocle_chat/widgets/chat_bubble.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart'; // Import for generating unique IDs

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
  static const String routeName = '/chat_detail';

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
  XFile? _pickedMedia; // To store the selected image/video file
  bool _isUploading = false; // To track upload state

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

  Future<void> _pickMedia(String type, ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    XFile? file;

    if (type == 'image') {
      file = await picker.pickImage(source: source);
    } else if (type == 'video') {
      file = await picker.pickVideo(source: source);
    }

    if (file != null) {
      setState(() {
        _pickedMedia = file;
      });
    }
  }

  Future<String?> _uploadMedia(
    XFile file,
    String chatRoomId,
    String messageType,
  ) async {
    setState(() {
      _isUploading = true;
    });
    try {
      final fileName = '${messageType}_${const Uuid().v4()}_${file.name}';
      final Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('chat_media')
          .child(chatRoomId)
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(File(file.path));
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      setState(() {
        _isUploading = false;
      });
      return downloadUrl;
    } catch (e) {
      print("Error uploading media: $e");
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload media. Please check your connection and try again.')),
        );
      }
      return null;
    }
  }

  Future<void> _sendMessage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if ((_messageController.text.trim().isEmpty && _pickedMedia == null) ||
        currentUser == null) {
      return;
    }

    final messageText = _messageController.text.trim();
    _messageController.clear();
    XFile? mediaFileToSend = _pickedMedia;
    setState(() {
      _pickedMedia = null;
    });

    try {
      String? mediaUrl;
      String messageType = 'text';

      if (mediaFileToSend != null) {
        messageType =
            mediaFileToSend.path.endsWith('.mp4') ||
                    mediaFileToSend.path.endsWith('.mov')
                ? 'video'
                : 'image';
        mediaUrl = await _uploadMedia(
          mediaFileToSend,
          widget.chatRoomId,
          messageType,
        );
        if (mediaUrl == null) {
          // Upload failed, do not proceed with sending message
          return;
        }
      }

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
            'mediaUrl': mediaUrl,
            'messageType': messageType,
          });

      // Update chat room metadata
      String lastMessageContent = messageText;
      if (messageType == 'image') {
        lastMessageContent =
            '[Image]${messageText.isNotEmpty ? ": $messageText" : ""}';
      } else if (messageType == 'video') {
        lastMessageContent =
            '[Video]${messageText.isNotEmpty ? ": $messageText" : ""}';
      }

      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .update({
            'lastMessage': lastMessageContent,
            'lastMessageTimestamp': FieldValue.serverTimestamp(),
            'lastMessageSenderId': currentUser.uid,
          });

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn\'t send message. Please try again.')),
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
                        mediaUrl: message.mediaUrl,
                        messageType: message.messageType,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CupertinoActivityIndicator()),
                error:
                    (error, _) =>
                        const Center(child: Text('Failed to load messages. Please try again later.')),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_pickedMedia != null &&
              !_isUploading) // Show a preview if media is picked and not uploading
            Container(
              padding: const EdgeInsets.only(bottom: 8),
              height: 100,
              child: Row(
                children: [
                  Expanded(
                    child:
                        _pickedMedia!.path.endsWith('.mp4') ||
                                _pickedMedia!.path.endsWith('.mov')
                            ? const Icon(
                              CupertinoIcons.video_camera_solid,
                              size: 50,
                            )
                            : Image.file(
                              File(_pickedMedia!.path),
                              fit: BoxFit.cover,
                            ),
                  ),
                  IconButton(
                    icon: const Icon(
                      CupertinoIcons.clear_circled_solid,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      setState(() {
                        _pickedMedia = null;
                      });
                    },
                  ),
                ],
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  CupertinoIcons.paperclip,
                  color: Color(0xFF2B1A0F),
                ),
                onPressed: _isUploading ? null : _showMediaPickerOptions, // Disable if uploading
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  enabled: !_isUploading, // Disable if uploading
                  decoration: const InputDecoration(
                    hintText: 'Compose your message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: _isUploading ? null : (_) => _sendMessage(), // Disable if uploading
                ),
              ),
              _isUploading
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CupertinoActivityIndicator(), // Use CupertinoActivityIndicator
                    )
                  : IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFF2B1A0F)),
                      onPressed: _sendMessage,
                    ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMediaPickerOptions() {
    showCupertinoModalPopup(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: const Text('Select Media'),
            actions: <CupertinoActionSheetAction>[
              CupertinoActionSheetAction(
                child: const Text('Pick Image from Gallery'),
                onPressed: () {
                  Navigator.pop(context);
                  _pickMedia('image', ImageSource.gallery);
                },
              ),
              CupertinoActionSheetAction(
                child: const Text('Take Photo with Camera'),
                onPressed: () {
                  Navigator.pop(context);
                  _pickMedia('image', ImageSource.camera);
                },
              ),
              CupertinoActionSheetAction(
                child: const Text('Pick Video from Gallery'),
                onPressed: () {
                  Navigator.pop(context);
                  _pickMedia('video', ImageSource.gallery);
                },
              ),
              CupertinoActionSheetAction(
                child: const Text('Record Video with Camera'),
                onPressed: () {
                  Navigator.pop(context);
                  _pickMedia('video', ImageSource.camera);
                },
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
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
