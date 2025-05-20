// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monocle_chat/providers/auth_provider.dart';
import 'package:monocle_chat/screens/login_screen.dart';
import 'package:monocle_chat/screens/home_screen.dart';
import 'package:monocle_chat/widgets/themed_loading_spinner.dart'; // Import themed spinner
import 'package:monocle_chat/widgets/themed_toast.dart'; // Import themed toast

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildLoadingSpinner() {
    return const ThemedLoadingSpinner(); // Use themed spinner
  }

  void _showErrorToast(BuildContext context, String message) {
    showThemedToast(context, message); // Use themed toast
  }

  Future<void> _signup() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(authNotifierProvider.notifier)
          .signUp(
            _emailController.text.trim(),
            _passwordController.text,
            _nameController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      final currentContext = context;
      if (!mounted) return; // Ensure widget is still in the tree

      if (next.status == AuthStatus.unauthenticated &&
          next.errorMessage != null) {
        _showErrorToast(currentContext, next.errorMessage!);
      }
      if (next.status == AuthStatus.authenticated && next.user != null) {
        // This case implies email is verified due to AuthNotifier logic
        Navigator.of(currentContext).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (Route<dynamic> route) => false,
        );
      }
      // Handle requiresVerification state specifically if you want to show a different UI or message
      // For now, it will show the message from AuthNotifier and then navigate to LoginScreen
      else if (next.status == AuthStatus.requiresVerification &&
          next.errorMessage != null) {
        _showErrorToast(currentContext, next.errorMessage!);
        // Optionally, navigate to a dedicated email verification screen or back to login
        // For simplicity, navigating to login after showing the message.
        Navigator.pushReplacement(
          currentContext,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });

    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body:
          authState.status == AuthStatus.loading
              ? _buildLoadingSpinner()
              : SingleChildScrollView(
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuint,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xDDF5F1E6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFC5A258),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            offset: const Offset(0, 4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 20),
                            _buildNameField(),
                            const SizedBox(height: 20),
                            _buildEmailField(),
                            const SizedBox(height: 20),
                            _buildPasswordField(),
                            const SizedBox(height: 30),
                            _buildSignupButton(),
                            const SizedBox(height: 20),
                            _buildUtilityLinks(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Petition for Membership',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'CormorantGaramond',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF5C4033),
      ),
    );
  }

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Name',
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
            hintText: 'Your esteemed name',
            hintStyle: TextStyle(
              fontFamily: 'Lora',
              fontSize: 14,
              color: Color(0xFF7A6A5C),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFC5A258)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFC5A258), width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Pray, share your esteemed name.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Courriel',
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
          decoration: const InputDecoration(
            hintText: 'your.estate@domain.com',
            hintStyle: TextStyle(
              fontFamily: 'Lora',
              fontSize: 14,
              color: Color(0xFF7A6A5C),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFC5A258)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFC5A258), width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty || !value.contains('@')) {
              return 'A valid correspondence address is required.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Passphrase',
          style: TextStyle(
            fontFamily: 'CormorantGaramond',
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: Color(0xFF3A1F1D),
          ),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Your cipher',
            hintStyle: TextStyle(
              fontFamily: 'Lora',
              fontSize: 14,
              color: Color(0xFF7A6A5C),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFC5A258)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFC5A258), width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'A cipher is required for entry.';
            }
            if (value.length < 8) {
              return 'A gentleman’s cipher requires more fortitude (min 8 chars).';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSignupButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFC5A258),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: _signup,
      child: const Text(
        'Seal the Pact',
        style: TextStyle(
          fontFamily: 'Trajan Pro',
          fontSize: 18,
          color: Color(0xFF1A1A1A),
        ),
      ),
    );
  }

  Widget _buildUtilityLinks(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      },
      child: const Text(
        'Already a member? Gain Entry',
        style: TextStyle(
          fontFamily: 'Lora',
          fontSize: 12,
          color: Color(0xFF7A6A5C),
        ),
      ),
    );
  }
}
