// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monocle_chat/providers/auth_provider.dart';
import 'package:monocle_chat/screens/chat_detail_screen.dart';
import 'package:monocle_chat/screens/profile_screen.dart';
import 'package:monocle_chat/screens/search_users_screen.dart';
import 'package:monocle_chat/models/chat_model.dart';

final homeSearchQueryProvider = StateProvider<String>((ref) => '');

final chatRoomsStreamProvider = StreamProvider.autoDispose<List<ChatModel>>((
  ref,
) {
  final currentUser = ref.watch(authNotifierProvider).user;
  if (currentUser == null) {
    return Stream.value([]);
  }

  return FirebaseFirestore.instance
      .collection('chat_rooms')
      .where('participants', arrayContains: currentUser.uid)
      .orderBy('lastMessageTimestamp', descending: true)
      .snapshots()
      .asyncMap((snapshot) async {
        List<ChatModel> chats = [];
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data();
          List<dynamic> participants = data['participants'];
          String otherUserId = participants.firstWhere(
            (id) => id != currentUser.uid,
            orElse: () => '',
          );

          if (otherUserId.isNotEmpty) {
            DocumentSnapshot userDoc =
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get();
            if (userDoc.exists) {
              Map<String, dynamic> userData =
                  userDoc.data() as Map<String, dynamic>;
              chats.add(ChatModel.fromFirestore(doc, userData, otherUserId));
            }
          }
        }
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
                  TextEditingController controller = TextEditingController(
                    text: searchQuery,
                  );
                  return AlertDialog(
                    title: const Text('Search Chats'),
                    content: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "Enter name...",
                      ),
                      autofocus: true,
                      onChanged: (value) {},
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          ref.read(homeSearchQueryProvider.notifier).state =
                              controller.text;
                          Navigator.pop(context);
                        },
                        child: const Text('Search'),
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
                  return chat.otherUserName.toLowerCase().contains(searchQuery);
                }).toList();

            if (filteredChats.isEmpty && searchQuery.isNotEmpty) {
              return const Center(
                child: Text(
                  'No correspondence found matching your search.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              );
            }
            if (filteredChats.isEmpty) {
              return _buildEmptyState();
            }
            return ListView.builder(
              itemCount: filteredChats.length,
              itemBuilder: (context, index) {
                return _buildChatItem(filteredChats[index]);
              },
            );
          },
          loading:
              () => const Center(
                child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
              ),
          error: (error, stack) {
            print('Error fetching chats: $error');
            print(stack);
            return Center(
              child: Text(
                'Error loading correspondence.\nPlease try again later.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 16,
                  color: Colors.red[700],
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
        child: const Icon(Icons.search, color: Color(0xFF2B1A0F)),
      ),
    );
  }

  Widget _buildChatItem(ChatModel chat) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatDetailScreen(
                  name: chat.otherUserName,
                  profilePicture: chat.otherUserProfilePictureUrl,
                  receiverId: chat.otherUserId,
                  chatRoomId: chat.chatRoomId,
                ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF4E6),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, 4),
                blurRadius: 8,
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFD4AF37),
              backgroundImage:
                  chat.otherUserProfilePictureUrl != null &&
                          chat.otherUserProfilePictureUrl!.isNotEmpty
                      ? NetworkImage(chat.otherUserProfilePictureUrl!)
                      : const AssetImage('assets/profile_pictures/dummy.jpg')
                          as ImageProvider,
              child:
                  chat.otherUserProfilePictureUrl == null ||
                          chat.otherUserProfilePictureUrl!.isEmpty
                      ? const Icon(Icons.person, color: Color(0xFF2B1A0F))
                      : null,
            ),
            title: Text(
              chat.otherUserName,
              style: const TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3A1F1D),
              ),
            ),
            subtitle: Text(
              chat.lastMessage,
              style: const TextStyle(
                fontFamily: 'Lora',
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Color(0xFF7A6A5C),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  chat.lastMessageTimestamp != null
                      ? TimeOfDay.fromDateTime(
                        chat.lastMessageTimestamp!.toDate(),
                      ).format(context)
                      : 'N/A',
                  style: const TextStyle(
                    fontFamily: 'Trajan Pro',
                    fontSize: 12,
                    color: Color(0xFF5A4A3C),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.edit_note_sharp,
            size: 100,
            color: Color(0xFFD4AF37),
          ),
          const SizedBox(height: 20),
          const Text(
            'No missives in your ledger yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'CormorantGaramond',
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: Color(0xFF7A6A5C),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tap the quill below to find a fellow scholar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Lora',
              fontSize: 14,
              color: Color(0xFF7A6A5C),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF5E6D3),
              foregroundColor: const Color(0xFF3A1F1D),
              side: const BorderSide(color: Color(0xFFD4AF37)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SearchUsersScreen(),
                ),
              );
            },
            icon: const Icon(Icons.search, color: Color(0xFF2B1A0F)),
            label: const Text(
              'Find Scholars',
              style: TextStyle(fontFamily: 'CormorantGaramond', fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
