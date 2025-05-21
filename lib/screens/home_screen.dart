// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, avoid_print, sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monocle_chat/models/user_model.dart';
import 'package:monocle_chat/providers/auth_provider.dart';
import 'package:monocle_chat/screens/chat_detail_screen.dart';
import 'package:monocle_chat/screens/profile_screen.dart';
import 'package:monocle_chat/screens/search_users_screen.dart';
import 'package:monocle_chat/models/chat_model.dart';
import 'package:intl/intl.dart';

final homeSearchQueryProvider = StateProvider<String>((ref) => '');

final chatRoomsStreamProvider = StreamProvider.autoDispose<List<ChatModel>>((
  ref,
) {
  final currentUser = ref.watch(authNotifierProvider).user;
  if (currentUser == null) {
    print("HomeScreenProvider: Current user is null. Returning empty stream.");
    return Stream.value([]);
  }
  print(
    "HomeScreenProvider: Current user: ${currentUser.uid}. Fetching chat rooms.",
  );

  return FirebaseFirestore.instance
      .collection('chat_rooms')
      .where('participants', arrayContains: currentUser.uid)
      .orderBy('lastMessageTimestamp', descending: true)
      .snapshots()
      .handleError((error, stackTrace) {
        print(
          "HomeScreenProvider: Error in Firestore snapshots stream: $error",
        );
        print("HomeScreenProvider: StackTrace: $stackTrace");
        throw error;
      })
      .asyncMap((snapshot) async {
        print(
          "HomeScreenProvider: Received ${snapshot.docs.length} chat room documents.",
        );
        List<ChatModel> chats = [];
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data();

          if (data['participants'] == null ||
              data['participants'] is! List ||
              (data['participants'] as List).isEmpty) {
            print(
              "HomeScreenProvider: Skipping chat room ${doc.id} due to missing, invalid, or empty 'participants' field. Data: $data",
            );
            continue;
          }
          List<dynamic> participants = data['participants'] as List<dynamic>;

          String otherUserId = participants.firstWhere(
            (id) => id != currentUser.uid,
            orElse: () {
              print(
                "HomeScreenProvider: Chat room ${doc.id} does not have another participant besides current user ${currentUser.uid}. Participants: $participants",
              );
              return '';
            },
          );

          if (otherUserId.isNotEmpty) {
            try {
              DocumentSnapshot userDoc =
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(otherUserId)
                      .get();
              if (userDoc.exists) {
                UserModel otherUser = UserModel.fromFirestore(userDoc);
                chats.add(
                  ChatModel.fromFirestore(doc, otherUser, currentUser.uid),
                );
              } else {
                print(
                  "HomeScreenProvider: User document not found for ID: $otherUserId (for chat room ${doc.id})",
                );
              }
            } catch (e, s) {
              print(
                "HomeScreenProvider: Error fetching user $otherUserId (for chat room ${doc.id}): $e\nStack trace: $s",
              );
            }
          } else {
            print(
              "HomeScreenProvider: Skipped chat room ${doc.id} as otherUserId could not be determined.",
            );
          }
        }
        print(
          "HomeScreenProvider: Processed ${chats.length} chats successfully.",
        );
        return chats;
      });
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final chatRoomsAsyncValue = ref.watch(chatRoomsStreamProvider);
    final searchQuery = ref.watch(homeSearchQueryProvider).toLowerCase();
    final currentUserID = ref.watch(authNotifierProvider).user?.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B1A0F),
        title: const Text(
          'Correspondence',
          style: TextStyle(
            fontFamily: 'EngraversGothic',
            fontSize: 20,
            color: Color(0xFFD4AF37),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  TextEditingController searchController =
                      TextEditingController(
                        text: ref.read(homeSearchQueryProvider),
                      );
                  return AlertDialog(
                    title: const Text('Search Chats'),
                    content: TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: "Enter name or message...",
                      ),
                      autofocus: true,
                      onChanged: (value) {},
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      TextButton(
                        child: const Text('Search'),
                        onPressed: () {
                          ref.read(homeSearchQueryProvider.notifier).state =
                              searchController.text;
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Color(0xFFD4AF37)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFFFF4E6)),
        child: chatRoomsAsyncValue.when(
          data: (chats) {
            final filteredChats =
                chats.where((chat) {
                  final query = searchQuery;
                  if (query.isEmpty) return true;
                  return chat.otherUser.name.toLowerCase().contains(query) ||
                      (chat.otherUser.email).toLowerCase().contains(query) ||
                      chat.lastMessage.toLowerCase().contains(query);
                }).toList();

            if (filteredChats.isEmpty) {
              if (searchQuery.isNotEmpty && chats.isNotEmpty) {
                return Center(
                  child: Text(
                    "No correspondence matches '$searchQuery'.",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return _buildEmptyState(context);
            }
            return ListView.builder(
              itemCount: filteredChats.length,
              itemBuilder: (context, index) {
                return _buildChatItem(filteredChats[index], currentUserID);
              },
            );
          },
          loading:
              () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF2B1A0F)),
              ),
          error: (error, stack) {
            print('HomeScreen: Error UI - $error');
            print('HomeScreen: StackTrace UI - $stack');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 50,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading correspondence',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'There was an issue fetching your chats. Please check your connection or try again.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Details: $error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      onPressed: () => ref.refresh(chatRoomsStreamProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2B1A0F),
                        foregroundColor: const Color(0xFFD4AF37),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchUsersScreen()),
          );
        },
        backgroundColor: const Color(0xFFD4AF37),
        child: const Icon(Icons.add_comment_outlined, color: Color(0xFF2B1A0F)),
        tooltip: 'Start new chat',
      ),
    );
  }

  Widget _buildChatItem(ChatModel chat, String? currentUserID) {
    bool isUnread =
        chat.lastMessageSenderId != currentUserID &&
        !chat.isLastMessageSeenByMe;

    String formattedTimestamp = 'No recent messages';
    if (chat.lastMessageTimestamp != null) {
      final messageDate = chat.lastMessageTimestamp!.toDate();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      final messageDay = DateTime(
        messageDate.year,
        messageDate.month,
        messageDate.day,
      );

      if (messageDay == today) {
        formattedTimestamp = DateFormat.jm().format(messageDate);
      } else if (messageDay == yesterday) {
        formattedTimestamp = 'Yesterday';
      } else {
        formattedTimestamp = DateFormat.yMd().format(messageDate);
      }
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatDetailScreen(
                  chatRoomId: chat.chatRoomId,
                  name: chat.otherUser.name,
                  receiverId: chat.otherUser.uid,
                ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  chat.otherUser.profilePictureUrl != null &&
                          chat.otherUser.profilePictureUrl!.isNotEmpty
                      ? NetworkImage(chat.otherUser.profilePictureUrl!)
                      : null,
              child:
                  chat.otherUser.profilePictureUrl == null ||
                          chat.otherUser.profilePictureUrl!.isEmpty
                      ? Text(
                        chat.otherUser.name.isNotEmpty
                            ? chat.otherUser.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          color: Color(0xFF2B1A0F),
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chat.otherUser.name,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight:
                          isUnread ? FontWeight.bold : FontWeight.normal,
                      color: const Color(0xFF2B1A0F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.lastMessage.isNotEmpty
                        ? chat.lastMessage
                        : 'No messages yet',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isUnread ? FontWeight.bold : FontWeight.normal,
                      color: isUnread ? Colors.black87 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  formattedTimestamp,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (isUnread) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD4AF37),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          const Text(
            'No Correspondence Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2B1A0F),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Tap the '+' button below to start a new chat.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
