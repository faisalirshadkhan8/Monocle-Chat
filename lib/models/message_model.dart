import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String receiverId;
  final String text;
  final Timestamp timestamp;
  final String messageId;
  bool isSeen; // Added isSeen field

  MessageModel({
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    required this.messageId,
    this.isSeen = false, // Default isSeen to false
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      messageId: doc.id,
      isSeen: data['isSeen'] ?? false, // Initialize isSeen from Firestore
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
      'isSeen': isSeen, // Add isSeen to Firestore map
    };
  }
}
