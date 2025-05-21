// ignore_for_file: library_private_types_in_public_api, unnecessary_string_escapes, avoid_print, use_build_context_synchronously

import 'dart:math' as math; // Import dart:math

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
                      onTap: () async {
                        print(
                          'SearchUsersScreen: onTap triggered for user: ${userData['email'] ?? 'N/A'}',
                        );

                        // It's better to read the auth state directly inside the async function
                        // to ensure it's the most current when the tap occurs.
                        final authUser = ref.read(authNotifierProvider).user;

                        if (authUser == null) {
                          // Check if authUser itself is null first
                          print(
                            'SearchUsersScreen: Current user is null (not authenticated). Cannot proceed.',
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Error: Not authenticated. Please log in again.',
                                ),
                              ),
                            );
                          }
                          return;
                        }
                        // Since authUser is not null here, we can safely access uid.
                        print(
                          'SearchUsersScreen: Current User ID: ${authUser.uid}',
                        );

                        final currentUserId = authUser.uid;
                        final otherUserId = userDoc.id;
                        final chatRoomId = getChatRoomId(
                          currentUserId,
                          otherUserId,
                        );
                        print(
                          'SearchUsersScreen: ChatRoomID: $chatRoomId, OtherUserID: $otherUserId',
                        );

                        try {
                          final chatRoomRef = FirebaseFirestore.instance
                              .collection('chat_rooms')
                              .doc(chatRoomId);

                          print(
                            'SearchUsersScreen: Attempting to get chat room snapshot...',
                          );
                          final chatRoomSnap = await chatRoomRef.get();
                          print(
                            'SearchUsersScreen: Chat room snapshot exists: ${chatRoomSnap.exists}',
                          );

                          if (!chatRoomSnap.exists) {
                            print(
                              'SearchUsersScreen: Chat room does not exist. Attempting to create...',
                            );
                            await chatRoomRef.set({
                              'chatRoomId': chatRoomId,
                              'participants': [currentUserId, otherUserId],
                              'lastMessage': '',
                              'lastMessageTimestamp':
                                  FieldValue.serverTimestamp(),
                              'lastMessageSenderId': '',
                              'createdAt': FieldValue.serverTimestamp(),
                              'participantNames': {
                                currentUserId:
                                    authUser.displayName ??
                                    'User ${currentUserId.substring(0, math.min(5, currentUserId.length))}', // Used math.min
                                otherUserId:
                                    userData['name'] ??
                                    'User ${otherUserId.substring(0, math.min(5, otherUserId.length))}', // Used math.min
                              },
                              'participantProfilePictures': {
                                currentUserId: authUser.photoURL, // Can be null
                                otherUserId: profilePictureUrl, // Can be null
                              },
                            });
                            print(
                              'SearchUsersScreen: Chat room created successfully.',
                            );
                          } else {
                            print(
                              'SearchUsersScreen: Chat room already exists.',
                            );
                          }

                          if (mounted) {
                            print(
                              'SearchUsersScreen: Navigating to ChatDetailScreen...',
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
                          } else {
                            print(
                              'SearchUsersScreen: Widget not mounted. Cannot navigate.',
                            );
                          }
                        } catch (e, s) {
                          print(
                            'SearchUsersScreen: Error during Firestore operation or navigation: $e',
                          );
                          print('SearchUsersScreen: Stacktrace: $s');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('An error occurred: $e')),
                            );
                          }
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
