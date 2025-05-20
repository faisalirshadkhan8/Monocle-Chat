// ignore_for_file: library_private_types_in_public_api, unnecessary_string_escapes

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monocle_chat/providers/auth_provider.dart'; // Corrected import path
import 'package:monocle_chat/screens/chat_detail_screen.dart'; // Corrected import path

// Provider for the search query
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider to fetch users based on search query
final usersStreamProvider =
    StreamProvider.autoDispose<List<QueryDocumentSnapshot>>((ref) {
      final searchQuery = ref.watch(searchQueryProvider).toLowerCase();
      final currentUser =
          ref.watch(authNotifierProvider).user; // Get current user

      if (searchQuery.isEmpty) {
        return Stream.value([]);
      }

      return FirebaseFirestore.instance
          .collection('users')
          .where('email', isGreaterThanOrEqualTo: searchQuery)
          .where('email', isLessThanOrEqualTo: '$searchQuery\uf8ff')
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .where(
                      (doc) => doc.id != currentUser?.uid,
                    ) // Exclude current user
                    .toList(),
          );
    });

class SearchUsersScreen extends ConsumerStatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  _SearchUsersScreenState createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends ConsumerState<SearchUsersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Function to create or get a chat room ID
  String getChatRoomId(String userId1, String userId2) {
    if (userId1.hashCode <= userId2.hashCode) {
      return '$userId1\_$userId2';
    } else {
      return '$userId2\_$userId1';
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsyncValue = ref.watch(usersStreamProvider);
    final currentUser = ref.watch(authNotifierProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
        backgroundColor: const Color(0xFF2B1A0F),
        titleTextStyle: const TextStyle(
          fontFamily: 'EngraversGothic',
          fontSize: 20,
          color: Color(0xFFD4AF37),
        ),
        iconTheme: const IconThemeData(color: Color(0xFFD4AF37)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              // onChanged handled by listener
            ),
          ),
          Expanded(
            child: usersAsyncValue.when(
              data: (users) {
                if (_searchController.text.isEmpty) {
                  return const Center(
                    child: Text(
                      'Enter an email to search for users.',
                      style: TextStyle(fontFamily: 'Lora', color: Colors.grey),
                    ),
                  );
                }
                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      'No users found.',
                      style: TextStyle(fontFamily: 'Lora', color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    final userData = userDoc.data() as Map<String, dynamic>;
                    final profilePictureUrl =
                        userData['profilePictureUrl'] as String?;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFD4AF37),
                        backgroundImage:
                            profilePictureUrl != null &&
                                    profilePictureUrl.isNotEmpty
                                ? NetworkImage(profilePictureUrl)
                                : const AssetImage(
                                      'assets/profile_pictures/dummy.jpg',
                                    )
                                    as ImageProvider, // Fallback placeholder
                        child:
                            profilePictureUrl == null ||
                                    profilePictureUrl.isEmpty
                                ? const Icon(
                                  Icons.person,
                                  color: Color(0xFF2B1A0F),
                                )
                                : null,
                      ),
                      title: Text(
                        userData['name'] ?? 'N/A',
                        style: const TextStyle(
                          fontFamily: 'CormorantGaramond',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        userData['email'] ?? 'N/A',
                        style: const TextStyle(fontFamily: 'Lora'),
                      ),
                      onTap: () {
                        if (currentUser?.uid != null) {
                          final chatRoomId = getChatRoomId(
                            currentUser!.uid,
                            userDoc.id,
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => ChatDetailScreen(
                                    name: userData['name'] ?? 'N/A',
                                    profilePicture: profilePictureUrl,
                                    receiverId: userDoc.id,
                                    chatRoomId: chatRoomId,
                                  ),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
              loading:
                  () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                  ),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
