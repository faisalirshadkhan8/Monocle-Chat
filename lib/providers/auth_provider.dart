import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// This will be the type of state that our AuthNotifier will hold
enum AuthStatus {
  authenticated,
  unauthenticated,
  loading,
  requiresVerification,
}

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  AuthState({required this.status, this.user, this.errorMessage});

  factory AuthState.initial() => AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(User user) =>
      AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated({String? message}) =>
      AuthState(status: AuthStatus.unauthenticated, errorMessage: message);
  factory AuthState.loading() => AuthState(status: AuthStatus.loading);
  factory AuthState.requiresVerification({String? message, User? user}) =>
      AuthState(
        status: AuthStatus.requiresVerification,
        errorMessage: message,
        user: user,
      );
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  AuthNotifier() : super(AuthState.initial()) {
    _auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        state = AuthState.unauthenticated();
      } else {
        if (user.emailVerified) {
          state = AuthState.authenticated(user);
          await _saveFcmToken(user);
          _listenFcmTokenRefresh(user);
        } else {
          state = AuthState.requiresVerification(
            message: "Please verify your email to continue.",
            user: user,
          );
        }
      }
    });
  }

  Future<void> signUp(String email, String password, String name) async {
    state = AuthState.loading();
    UserCredential? userCredential;
    try {
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': name,
          'email': email,
          'createdAt': Timestamp.now(),
          'societyTier': 'Neophyte',
          'profilePictureUrl': null,
        });
        await userCredential.user!.sendEmailVerification();
        await _saveFcmToken(userCredential.user!);
        _listenFcmTokenRefresh(userCredential.user!);
        state = AuthState.requiresVerification(
          message:
              "A verification parchment has been dispatched. Please check your inbox.",
          user: userCredential.user,
        );
      } else {
        state = AuthState.unauthenticated(
          message: "Unable to complete enlistment. No user data returned.",
        );
      }
    } on FirebaseAuthException catch (e) {
      state = AuthState.unauthenticated(
        message: _translateFirebaseError(e.code),
      );
    } catch (e) {
      state = AuthState.unauthenticated(
        message: "An unexpected difficulty has arisen during entry.",
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthState.loading();
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (userCredential.user != null) {
        if (userCredential.user!.emailVerified) {
          state = AuthState.authenticated(userCredential.user!);
          await _saveFcmToken(userCredential.user!);
          _listenFcmTokenRefresh(userCredential.user!);
        } else {
          await userCredential.user!.sendEmailVerification();
          state = AuthState.requiresVerification(
            message:
                "Your membership awaits confirmation. A new verification parchment has been dispatched. Kindly check your email.",
            user: userCredential.user,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      state = AuthState.unauthenticated(
        message: _translateFirebaseError(e.code),
      );
    } catch (e) {
      state = AuthState.unauthenticated(
        message: "An unexpected difficulty has arisen during entry.",
      );
    }
  }

  Future<void> signOut() async {
    state = AuthState.loading();
    await _auth.signOut();
  }

  Future<void> sendVerificationEmail() async {
    state = AuthState.loading();
    User? currentUser = _auth.currentUser;
    User? userForVerification = state.user ?? currentUser;

    if (userForVerification != null && !userForVerification.emailVerified) {
      try {
        await userForVerification.sendEmailVerification();
        state = AuthState.requiresVerification(
          message:
              "A new verification parchment has been dispatched. Please check your inbox.",
          user: userForVerification,
        );
      } on FirebaseAuthException catch (e) {
        state = AuthState.requiresVerification(
          message:
              "Failed to send verification: ${_translateFirebaseError(e.code)}",
          user: userForVerification,
        );
      } catch (e) {
        state = AuthState.requiresVerification(
          message: "An unexpected error while sending verification.",
          user: userForVerification,
        );
      }
    } else if (userForVerification != null &&
        userForVerification.emailVerified) {
      state = AuthState.authenticated(userForVerification);
    } else {
      state = AuthState.unauthenticated(
        message: "No user session found to send verification.",
      );
    }
  }

  Future<void> checkCurrentUserVerificationStatus() async {
    state = AuthState.loading();
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      await currentUser.reload();
      currentUser = _auth.currentUser;
      if (currentUser!.emailVerified) {
        state = AuthState.authenticated(currentUser);
      } else {
        state = AuthState.requiresVerification(
          message: "Email still requires verification.",
          user: currentUser,
        );
      }
    } else {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> _saveFcmToken(User user) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
        });
      }
    } catch (e) {
      // Optionally log or handle error
    }
  }

  void _listenFcmTokenRefresh(User user) {
    _messaging.onTokenRefresh.listen((newToken) async {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': newToken,
        });
      } catch (e) {
        // Optionally log or handle error
      }
    });
  }

  String _translateFirebaseError(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'This correspondence address is already claimed by a peer.';
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-credential':
        return 'Tut-tut! The cipher doesn’t match our ledgers.';
      case 'invalid-email':
        return 'The correspondence address appears to be improperly formatted.';
      case 'weak-password':
        return 'A gentleman’s cipher requires more fortitude.';
      case 'user-disabled':
        return 'This account has been suspended from the society.';
      case 'too-many-requests':
        return 'Patience, dear associate. Too many attempts have been made.';
      default:
        return 'An unforeseen complication has arisen ($errorCode). Pray, try again.';
    }
  }
}

final authUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState.status == AuthStatus.authenticated ||
      authState.status == AuthStatus.requiresVerification) {
    return authState.user;
  }
  return null;
});

final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authNotifierProvider).status;
});
