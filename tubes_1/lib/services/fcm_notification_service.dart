// services/fcm_notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Fungsi ini harus berada di luar kelas (top-level) untuk menangani notifikasi background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Anda bisa melakukan inisialisasi Firebase di sini jika perlu
  print("Handling a background message: ${message.messageId}");
}

class FcmNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Meminta izin notifikasi dari pengguna (penting untuk iOS)
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Mengambil dan menyimpan FCM token
    // Token ini unik untuk setiap instalasi aplikasi di perangkat
    // Anda akan menggunakan token ini di backend untuk menargetkan notifikasi
    final String? fcmToken = await _firebaseMessaging.getToken();
    print("FCM Token: $fcmToken");
    // Anda bisa menyimpan token ini ke Firestore untuk pengguna yang login
    // _saveTokenToDatabase(fcmToken);

    // Mengatur handler untuk notifikasi background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Mengatur notifikasi lokal untuk menampilkan pesan saat aplikasi di foreground
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon'); // Pastikan ikon ada
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );
    _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Listener untuk notifikasi yang masuk saat aplikasi terbuka (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        _flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'dapoer_kita_channel',
              'Dapoer Kita Channel',
              channelDescription: 'Channel untuk notifikasi Dapoer Kita',
              icon: 'app_icon',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  // Fungsi opsional untuk menyimpan token ke Firestore
  void saveTokenToDatabase(String? token, String userId) {
    if (token == null) return;
    FirebaseFirestore.instance.collection('users').doc(userId).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }
}
