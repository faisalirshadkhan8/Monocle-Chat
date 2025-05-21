// ignore_for_file: avoid_print, prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import ProviderScope
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // Add this import
import 'firebase_options.dart';
import 'screens/splashscreen.dart';
import 'screens/home_screen.dart';
import 'package:monocle_chat/screens/onboarding_screen.dart';
import 'package:monocle_chat/screens/login_screen.dart';
import 'package:monocle_chat/screens/signup_screen.dart';
import 'package:monocle_chat/screens/profile_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:monocle_chat/screens/chat_detail_screen.dart'; // Add this import

// Initialize FlutterLocalNotificationsPlugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// NavigatorKey for navigating from background/terminated state
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ); // Ensure options are passed
  // Handle background message
  // If you're going to show a notification here, make sure to initialize flutterLocalNotificationsPlugin
  // and use it similarly to the foreground message handling.
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Print the FCM registration token for testing
  print(
    "FCM registration token: " +
        (await FirebaseMessaging.instance.getToken()).toString(),
  );

  // Initialize local notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      ); // Ensure you have this icon

  // For iOS, request permission first
  DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: (
          int? id,
          String? title,
          String? body,
          String? payload,
        ) async {
          // Handle notification when app is in foreground
          print('Received local notification: $title');
        },
      );

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (
      NotificationResponse notificationResponse,
    ) async {
      // Handle notification tap when app is in foreground or background (not terminated)
      final String? payload = notificationResponse.payload;
      if (payload != null) {
        debugPrint(
          'notification payload from onDidReceiveNotificationResponse: $payload',
        );
        if (navigatorKey.currentState != null) {
          // Try to parse payload as JSON for more complex data
          try {
            final Map<String, dynamic> payloadData = Map<String, dynamic>.from(
              payload as dynamic,
            ); // Adjust if payload is not directly a map
            final String? screen = payloadData['screen'];
            final String? chatId = payloadData['chatId'];
            final String? chatRoomId =
                payloadData['chatRoomId']; // Assuming chatRoomId is also sent
            final String? name = payloadData['name'];
            final String? profilePicture = payloadData['profilePicture'];
            final String? receiverId = payloadData['receiverId'];

            if (screen == ChatDetailScreen.routeName &&
                (chatId != null || chatRoomId != null)) {
              navigatorKey.currentState!.pushNamed(
                screen!,
                arguments: {
                  'chatRoomId':
                      chatRoomId ??
                      chatId, // Use chatRoomId if available, else fallback to chatId
                  'name':
                      name ??
                      'Chat', // Provide a default or ensure name is always sent
                  'profilePicture': profilePicture,
                  'receiverId': receiverId, // Ensure receiverId is sent
                },
              );
            } else if (screen != null && screen.startsWith('/')) {
              navigatorKey.currentState!.pushNamed(screen);
            }
          } catch (e) {
            // Fallback for simple string payload (e.g., just route name or just chatId)
            if (payload.startsWith('/')) {
              // navigatorKey.currentState!.pushNamed(payload);
              print("Navigating to route: $payload (simple payload)");
            } else {
              // Assuming the payload might be a chatId directly if not a route
              // This is a fallback, ideally send structured data
              // navigatorKey.currentState!.pushNamed(ChatDetailScreen.routeName, arguments: {'chatRoomId': payload, 'name': 'Chat'});
              print(
                "Attempting to navigate to chat with ID: $payload (simple payload as ID)",
              );
            }
          }
        }
      }
    },
  );

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    announcement: false,
    badge: true,
    carPlay: false,
    criticalAlert: false,
    provisional: false,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Got a message whilst in the foreground!');
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification}');

    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    AppleNotification? apple = message.notification?.apple;

    if (notification != null && (android != null || apple != null)) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'your_channel_id',
            'your_channel_name',
            channelDescription: 'your_channel_description',
            icon: android?.smallIcon,
          ),
          iOS: const DarwinNotificationDetails(
            presentSound: true,
            presentBadge: true,
            presentAlert: true,
          ),
        ),
        // Send structured data in payload
        payload:
            {
              "screen":
                  ChatDetailScreen.routeName, // Or derive from message.data
              "chatRoomId":
                  message.data['chatRoomId'] ?? message.data['chatId'],
              "name":
                  message.data['senderName'] ??
                  notification.title, // Assuming senderName might be in data
              "profilePicture": message.data['senderProfilePicture'],
              "receiverId":
                  message
                      .data['receiverId'], // This would be the current user if they are receiving
            }.toString(), // Convert map to string for payload; consider JSON string
      );
    }
  });

  // Listener for when a notification opens the app from terminated or background state
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('A new onMessageOpenedApp event was published!');
    print('Message data: ${message.data}');
    print('Message notification: ${message.notification}');

    final String? screen = message.data['screen'];
    final String? chatId =
        message.data['chatId']; // Kept for compatibility if old payloads exist
    final String? chatRoomId = message.data['chatRoomId'];
    final String? name =
        message.data['senderName'] ?? message.notification?.title;
    final String? profilePicture = message.data['senderProfilePicture'];
    final String? receiverId =
        message
            .data['receiverId']; // This is likely the ID of the other user in the chat

    if (navigatorKey.currentState != null) {
      if (screen == ChatDetailScreen.routeName &&
          (chatRoomId != null || chatId != null)) {
        navigatorKey.currentState!.pushNamed(
          screen!,
          arguments: {
            'chatRoomId': chatRoomId ?? chatId,
            'name': name ?? 'Chat',
            'profilePicture': profilePicture,
            'receiverId':
                receiverId, // This should be the ID of the user who sent the message
            // or the other participant if navigating to an existing chat.
            // The logic for receiverId might need adjustment based on how you structure chat partners.
          },
        );
      } else if (screen != null && screen.startsWith('/')) {
        navigatorKey.currentState!.pushNamed(screen);
      }
      // Fallback if only chatId is present (less ideal)
      else if (chatId != null && screen == null) {
        navigatorKey.currentState!.pushNamed(
          ChatDetailScreen.routeName,
          arguments: {
            'chatRoomId': chatId,
            'name': name ?? 'Chat',
            'profilePicture': profilePicture,
            'receiverId': receiverId,
          },
        );
      }
    }
  });

  // Check if the app was opened from a terminated state by a notification
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      print('App opened from terminated state by message:');
      print('Message data: ${message.data}');
      print('Message notification: ${message.notification}');

      // Similar navigation logic as onMessageOpenedApp
      final String? screen = message.data['screen'];
      final String? chatRoomId =
          message.data['chatRoomId'] ?? message.data['chatId'];
      final String? name =
          message.data['senderName'] ?? message.notification?.title;
      final String? profilePicture = message.data['senderProfilePicture'];
      final String? receiverId = message.data['receiverId'];

      // Ensure navigatorKey.currentState is available.
      // Might need a slight delay or to ensure the first frame is built.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorKey.currentState != null) {
          if (screen == ChatDetailScreen.routeName && chatRoomId != null) {
            navigatorKey.currentState!.pushNamed(
              screen!,
              arguments: {
                'chatRoomId': chatRoomId,
                'name': name ?? 'Chat',
                'profilePicture': profilePicture,
                'receiverId': receiverId,
              },
            );
          } else if (screen != null && screen.startsWith('/')) {
            navigatorKey.currentState!.pushNamed(screen);
          }
        }
      });
    }
  });

  runApp(
    const ProviderScope(
      // Wrap your app with ProviderScope
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // Set the navigatorKey
      title: 'Monocle Chat',
      theme: ThemeData(primarySwatch: Colors.brown),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/profile': (context) => const ProfileScreen(),
        ChatDetailScreen.routeName: (context) {
          // Add this route
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>?;
          // It's crucial that your ChatDetailScreen can handle null arguments or has defaults
          // if some data isn't passed (though for chat, chatRoomId and receiverId are usually essential)
          return ChatDetailScreen(
            chatRoomId:
                args?['chatRoomId'] ?? '', // Provide a fallback or handle error
            name: args?['name'] ?? 'Chat',
            profilePicture: args?['profilePicture'],
            receiverId:
                args?['receiverId'] ?? '', // Provide a fallback or handle error
          );
        },
      },
    );
  }
}
