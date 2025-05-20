// ignore_for_file: library_private_types_in_public_api, deprecated_member_use, avoid_print
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monocle_chat/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  // Changed to ConsumerStatefulWidget
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState
    extends
        ConsumerState<ProfileScreen> // Changed to ConsumerState
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  // Profile data
  String? _profileImage; // Can be a URL from Firebase Storage or null
  String _selectedTitle = 'Baron';
  bool _isLoading = false; // To manage loading state for async operations
  final List<String> _titles = ['Baron', 'Viscount', 'Dame', 'Count', 'Earl'];

  // Animation controllers
  late AnimationController _saveAnimationController;

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Call your data fetching method here

    // Initialize animation controller
    _saveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });
    final user = ref.read(authUserProvider);
    if (user != null) {
      try {
        final userDataSnapshot =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (userDataSnapshot.exists) {
          final userData = userDataSnapshot.data()!;
          setState(() {
            _nameController.text = userData['name'] ?? '';
            _emailController.text = userData['email'] ?? '';
            _bioController.text =
                userData['bio'] ??
                'A distinguished gentleman of letters with a fondness for the finer things in life.';
            _profileImage = userData['profilePictureUrl'];
            _selectedTitle = userData['title'] ?? 'Baron';
          });
        }
      } catch (e) {
        // Handle error, e.g., show a snackbar
        if (mounted) {
          // Check if the widget is still in the tree
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching user data: $e')),
          );
        }
      } finally {
        if (mounted) {
          // Check if the widget is still in the tree
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      if (mounted) {
        // Check if the widget is still in the tree
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final user = ref.read(authUserProvider);
    print('DEBUG: Entered _pickImage');
    if (user == null) {
      _showErrorToast("You must be logged in to change your portrait.");
      print('DEBUG: No user found');
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      print('DEBUG: Image picked: ${image?.path}');

      if (image != null) {
        if (!mounted) {
          print('DEBUG: Widget not mounted after picking image');
          return;
        }
        setState(() {
          _isLoading = true;
        });
        print('DEBUG: Loading set to true');
        final File imageFile = File(image.path);
        final String fileName = 'avatar.${image.path.split('.').last}';
        final Reference storageRef = FirebaseStorage.instance.ref().child(
          'profile_pictures/${user.uid}/$fileName',
        );

        final UploadTask uploadTask = storageRef.putFile(imageFile);
        print('DEBUG: Upload started');
        final TaskSnapshot snapshot = await uploadTask;
        print('DEBUG: Upload complete');
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        print('DEBUG: Download URL: $downloadUrl');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'profilePictureUrl': downloadUrl});
        print('DEBUG: Firestore updated');

        if (!mounted) {
          print('DEBUG: Widget not mounted after Firestore update');
          return;
        }
        setState(() {
          _profileImage = downloadUrl;
        });
        print('DEBUG: Profile image set');
        _showSuccessToast("Portrait updated");
      }
    } catch (e, stack) {
      print('DEBUG: Exception: ${e.toString()}');
      print('DEBUG: StackTrace: ${stack.toString()}');
      _showErrorToast("Tut-tut! Unworthy portrait. ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print('DEBUG: Loading set to false');
      } else {
        print('DEBUG: Widget not mounted in finally');
      }
    }
  }

  void _showSuccessToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFFD4AF37)),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF2B1A0F),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.watch_later, color: Color(0xFF8B0000)),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: Colors.black87,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveProfile() async {
    // Made async
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      _saveAnimationController.forward().then((_) {
        _saveAnimationController.reset();
        // _showSuccessToast("Profile Preserved"); // Moved to after successful save
      });

      final user = ref.read(authUserProvider);
      if (user != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'name': _nameController.text,
            // 'email': _emailController.text, // Email is usually not updated here directly
            'title': _selectedTitle, // Save selected title
            'bio': _bioController.text,
            'societyTier':
                _selectedTitle, // Assuming title maps to societyTier or vice-versa
          });
          _showSuccessToast("Profile Preserved");
        } catch (e) {
          _showErrorToast("Failed to preserve profile: ${e.toString()}");
        }
      } else {
        _showErrorToast("No authenticated user found.");
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _saveAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF4E6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2B1A0F),
        title: const Text(
          "Gentleman's Profile",
          style: TextStyle(
            fontFamily: 'EngraversGothic',
            fontSize: 20,
            color: Color(0xFFD4AF37),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFD4AF37)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text(
              "Seal It",
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 16,
                color: Color(0xFFD4AF37),
              ),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildProfilePicture(),
                      const SizedBox(height: 30),
                      _buildProfileCard(),
                      const SizedBox(height: 40),
                      _buildLogoutButton(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildProfilePicture() {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37), width: 5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child:
                  _profileImage != null && _profileImage!.isNotEmpty
                      ? Image.network(
                        _profileImage!,
                        key: ValueKey(_profileImage!), // Add this key
                        fit: BoxFit.cover,
                        loadingBuilder: (
                          BuildContext context,
                          Widget child,
                          ImageChunkEvent? loadingProgress,
                        ) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                              color: const Color(0xFFD4AF37),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                      : Container(
                        // Placeholder when _profileImage is null or empty
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
            ),
          ),
          Positioned(
            bottom: 5,
            right: 5,
            child: GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.edit, size: 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5E6D3),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNameField(),
          const SizedBox(height: 25),
          _buildTitleDropdown(),
          const SizedBox(height: 25),
          _buildEmailField(),
          const SizedBox(height: 25),
          _buildBioField(),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Appellation",
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: Color(0xFF3A1F1D),
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.account_balance, color: Color(0xFF5C4033)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFC5A258)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD4AF37), width: 2),
            ),
          ),
          style: const TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 18,
            color: Color(0xFF3A1F1D),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "A name is required for proper introduction";
            } else if (value.length < 2) {
              return "Your appellation is too brief";
            } else if (value.length > 30) {
              return "Your appellation is excessively lengthy";
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTitleDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Station",
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: Color(0xFF3A1F1D),
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: const Color(0xFFC5A258))),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedTitle,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF5C4033)),
              style: const TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 18,
                color: Color(0xFF3A1F1D),
              ),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedTitle = newValue!;
                });
              },
              items:
                  _titles.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Courier Address",
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: Color(0xFF3A1F1D),
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: _emailController,
          readOnly: true, // Make email field read-only
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.edit, color: Color(0xFF5C4033)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFC5A258)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD4AF37), width: 2),
            ),
          ),
          style: const TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 18,
            color: Color(0xFF3A1F1D),
          ),
        ),
      ],
    );
  }

  Widget _buildBioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Lineage & Lore",
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: Color(0xFF3A1F1D),
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: _bioController,
          maxLines: 5,
          maxLength: 250,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.menu_book, color: Color(0xFF5C4033)),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFC5A258)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD4AF37), width: 2),
            ),
            counterText:
                "Whispers remaining: ${250 - _bioController.text.length}",
            counterStyle: const TextStyle(
              fontFamily: 'Lora',
              fontSize: 12,
              color: Color(0xFFD4AF37),
            ),
          ),
          style: const TextStyle(
            fontFamily: 'Lora',
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: Color(0xFF7A6A5C),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return TextButton(
      onPressed: () async {
        setState(() {
          _isLoading = true;
        });
        try {
          await ref.read(authNotifierProvider.notifier).signOut();
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        } catch (e) {
          if (mounted) {
            _showErrorToast("Failed to depart: ${e.toString()}");
          }
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
      ),
      child: const Text(
        "Depart the Salon",
        style: TextStyle(
          fontFamily: 'CormorantGaramond',
          fontSize: 18,
          color: Color(0xFF8B0000),
        ),
      ),
    );
  }
}
