import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String senderId;
  final String receiverId;
  final String text;
  final Timestamp timestamp;
  final String messageId;
  bool isSeen; // Added isSeen field
  final String? mediaUrl; // Added for image/video URLs
  final String
  messageType; // Added to distinguish message types (text, image, video)

  MessageModel({
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    required this.messageId,
    this.isSeen = false, // Default isSeen to false
    this.mediaUrl,
    this.messageType = 'text', // Default message type to 'text'
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
      mediaUrl: data['mediaUrl'], // Initialize mediaUrl from Firestore
      messageType:
          data['messageType'] ??
          'text', // Initialize messageType from Firestore
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
      'isSeen': isSeen, // Add isSeen to Firestore map
      'mediaUrl': mediaUrl, // Add mediaUrl to Firestore map
      'messageType': messageType, // Add messageType to Firestore map
    };
  }
}
