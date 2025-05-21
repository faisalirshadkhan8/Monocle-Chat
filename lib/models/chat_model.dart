import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monocle_chat/models/user_model.dart'; // Import UserModel

class ChatModel {
  final String chatRoomId;
  final UserModel otherUser; // Changed to UserModel
  final String lastMessage;
  final Timestamp? lastMessageTimestamp;
  final String? lastMessageSenderId; // Added to know who sent the last message
  final bool isLastMessageSeenByMe; // Added to show unread status

  ChatModel({
    required this.chatRoomId,
    required this.otherUser, // Changed to UserModel
    required this.lastMessage,
    this.lastMessageTimestamp,
    this.lastMessageSenderId,
    this.isLastMessageSeenByMe = false, // Default to false
  });

  factory ChatModel.fromFirestore(
    DocumentSnapshot chatRoomDoc,
    UserModel otherUserModel, // Changed to UserModel
    String
    currentUserId, // Needed to determine if last message is seen by current user
  ) {
    Map<String, dynamic> chatRoomData =
        chatRoomDoc.data() as Map<String, dynamic>;

    bool seenByMe = true; // Assume seen unless proven otherwise
    final lastSender = chatRoomData['lastMessageSenderId'] as String?;
    final lastMsg = chatRoomData['lastMessage'] as String?;

    // If there is a last message AND it was NOT sent by the current user,
    // then we need to check if the current user has seen it.
    // For simplicity, we'll assume if a `lastMessageSeenBy` field exists and contains the current user's ID, it's seen.
    // A more robust solution would involve a map of participants to their seen status for the last message.
    // Or, check the `isSeen` status of the actual last message document if performance allows.
    // For now, we'll simplify: if the lastMessageSenderId is NOT me, it implies I haven't seen it yet
    // unless a more specific field is added to chat_rooms like `lastMessageSeenByParticipants`
    if (lastSender != null &&
        lastSender != currentUserId &&
        lastMsg != null &&
        lastMsg.isNotEmpty) {
      // This is a placeholder. A proper unread indicator would require more specific fields in Firestore
      // e.g., a map `lastMessageReadBy: {userId1: true, userId2: false}` in the chat_room document,
      // or by querying the last message in the messages subcollection.
      // For now, if the other user sent the last message, we mark it as potentially unread for the UI.
      seenByMe =
          false; // Simplified: if other user sent it, assume I haven't seen it for UI purposes
    }

    return ChatModel(
      chatRoomId: chatRoomDoc.id,
      otherUser: otherUserModel,
      lastMessage: chatRoomData['lastMessage'] ?? '',
      lastMessageTimestamp: chatRoomData['lastMessageTimestamp'] as Timestamp?,
      lastMessageSenderId: chatRoomData['lastMessageSenderId'] as String?,
      isLastMessageSeenByMe: seenByMe, // Use the determined seen status
    );
  }
}
