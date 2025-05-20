// ignore_for_file: library_private_types_in_public_api, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:monocle_chat/providers/auth_provider.dart';
import 'package:monocle_chat/screens/home_screen.dart';
import 'package:monocle_chat/screens/signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildLoadingSpinner() {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFFC5A258)),
    );
  }

  void _showErrorToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontFamily: 'Lora'),
        ),
        backgroundColor: const Color(0xFF8B0000),
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(authNotifierProvider.notifier)
          .login(_emailController.text.trim(), _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      final currentContext = context;
      if (next.status == AuthStatus.unauthenticated &&
          next.errorMessage != null) {
        if (mounted && currentContext.mounted) {
          _showErrorToast(currentContext, next.errorMessage!);
        }
      }
      if (next.status == AuthStatus.authenticated && next.user != null) {
        if (mounted && currentContext.mounted) {
          if (next.user!.emailVerified) {
            Navigator.of(currentContext).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (Route<dynamic> route) => false,
            );
          }
        }
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
                            _buildEmailField(),
                            const SizedBox(height: 20),
                            _buildPasswordField(),
                            const SizedBox(height: 30),
                            _buildLoginButton(),
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
      'Gain Entry to the Society',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'CormorantGaramond',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Color(0xFF5C4033),
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Correspondence Address',
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
          'Secret Cipher',
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
            hintText: 'Your confidential key',
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
              return 'Your cipher, if you please.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFC5A258),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: _login,
      child: const Text(
        'Cross the Threshold',
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
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SignupScreen()),
        );
      },
      child: const Text(
        'Not yet a member? Seek Enlistment.',
        style: TextStyle(
          fontFamily: 'Lora',
          fontSize: 12,
          color: Color(0xFF7A6A5C),
        ),
      ),
    );
  }
}
