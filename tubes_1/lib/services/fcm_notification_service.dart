import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class FcmNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    await _firebaseMessaging.requestPermission();

    // Mengambil dan menyimpan FCM token
    final String? fcmToken = await _firebaseMessaging.getToken();
    print("FCM Token: $fcmToken");
    _saveTokenToDatabase(fcmToken); // Panggil fungsi simpan token (private)

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    _initLocalNotifications();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        _showLocalNotification(notification);
      }
    });
  }

  void _initLocalNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );
    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _showLocalNotification(RemoteNotification notification) {
    _flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'dapoer_kita_channel',
          'Dapoer Kita Channel',
          channelDescription: 'Channel untuk notifikasi Dapoer Kita',
          icon: '@mipmap/ic_launcher',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  // Private method untuk menyimpan token secara internal
  void _saveTokenToDatabase(String? token) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || token == null) return;

    FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'fcmToken': token,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Public method yang bisa dipanggil dari luar class
  Future<void> saveTokenToDatabase(String token, String uid) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': token,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("FCM Token saved for user: $uid");
    } catch (e) {
      print("Error saving FCM token: $e");
    }
  }

  // Method untuk mendapatkan token FCM
  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print("Error getting FCM token: $e");
      return null;
    }
  }
}
