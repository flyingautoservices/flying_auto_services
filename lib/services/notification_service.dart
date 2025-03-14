// import 'dart:io';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';

// class NotificationService {
//   final FirebaseMessaging _messaging = FirebaseMessaging.instance;
//   bool _isInitialized = false;

//   // Initialize notification service
//   Future<void> initialize() async {
//     // Prevent duplicate initialization
//     if (_isInitialized) return;
    
//     try {
//       // We don't need to request permission here as it's already done in main.dart
//       print('Setting up notification listeners');

//       // Get FCM token with error handling - just for logging purposes
//       try {
//         // For iOS, make sure presentation options are set
//         if (Platform.isIOS) {
//           await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
//             alert: true,
//             badge: true,
//             sound: true,
//           );
//         }
        
//         // Try to get the token - this might fail on iOS if APNS token isn't ready
//         // We're only logging it, not saving to Firestore
//         // String? token = await _messaging.getToken();
//         if (token != null) {
//           print('FCM Token retrieved: $token');
//         } else {
//           print('FCM Token is null, will try again later');
//         }
//       } catch (e) {
//         print('Error getting FCM token: $e');
//         // Not critical since we're not using the token
//       }

//       // Listen for token refresh - just for logging
//       _messaging.onTokenRefresh.listen((token) {
//         print('FCM Token refreshed: $token');
//       });

//       // Handle foreground messages
//       FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//         print('Got a message whilst in the foreground!');
//         print('Message data: ${message.data}');

//         if (message.notification != null) {
//           print('Message also contained a notification: ${message.notification}');
//           // Show local notification
//           _showLocalNotification(message);
//         }
//       });

//       // Handle message when app is in background but opened
//       FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//         print('A new onMessageOpenedApp event was published!');
//         // Navigate to relevant screen based on message data
//         _handleMessageOpenedApp(message);
//       });
      
//       _isInitialized = true;
//       print('Notification service initialization complete');
//     } catch (e) {
//       print('Error initializing notification service: $e');
//       // Continue with the app even if notifications fail
//     }
//   }

//   // Show local notification
//   void _showLocalNotification(RemoteMessage message) {
//     // Implement local notification display
//     // This would use flutter_local_notifications package
//     print('Local notification would show: ${message.notification?.title}');
//   }

//   // Handle message opened app
//   void _handleMessageOpenedApp(RemoteMessage message) {
//     // Navigate to relevant screen based on message data
//     print('Would navigate based on: ${message.data}');
//   }
// }

// // Provider for NotificationService
// final notificationServiceProvider = Provider<NotificationService>((ref) {
//   return NotificationService();
// });
