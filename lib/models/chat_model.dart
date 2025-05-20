import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatRoomId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserProfilePictureUrl;
  final String lastMessage;
  final Timestamp? lastMessageTimestamp;
  // Add other relevant fields like unreadCount, senderOfLastMessage, etc.

  ChatModel({
    required this.chatRoomId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserProfilePictureUrl,
    required this.lastMessage,
    this.lastMessageTimestamp,
  });

  factory ChatModel.fromFirestore(
    DocumentSnapshot chatRoomDoc,
    Map<String, dynamic> otherUserData,
    String otherUserId,
  ) {
    Map<String, dynamic> chatRoomData =
        chatRoomDoc.data() as Map<String, dynamic>;
    return ChatModel(
      chatRoomId: chatRoomDoc.id,
      otherUserId: otherUserId,
      otherUserName: otherUserData['name'] ?? 'N/A',
      otherUserProfilePictureUrl: otherUserData['profilePictureUrl'] as String?,
      lastMessage: chatRoomData['lastMessage'] ?? '',
      lastMessageTimestamp: chatRoomData['lastMessageTimestamp'] as Timestamp?,
    );
  }

  get timestamp => null;
}
