import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:staff_work_track/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('================================');
  print('BACKGROUND NOTIFICATION');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('================================');
}

class NotificationService {
  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );

    // Request notification permission
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print(
      'Notification permission: '
      '${settings.authorizationStatus}',
    );

    // Foreground notification
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        print('================================');
        print('FOREGROUND NOTIFICATION');
        print('Title: ${message.notification?.title}');
        print('Body: ${message.notification?.body}');
        print('================================');
      },
    );

    // Token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) {
        print('================================');
        print('NEW FCM TOKEN');
        print(newToken);
        print('================================');

        // We will send this to .NET.
      },
    );
  }

  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();

      print('================================');
      print('FCM TOKEN');
      print(token);
      print('================================');

      return token;
    } catch (e) {
      print('================================');
      print('FCM TOKEN ERROR');
      print(e);
      print('================================');

      return null;
    }
  }
}