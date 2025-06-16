import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String username;
  final String role; // 'customer', 'seller', 'driver'
  final String? profileImageUrl;

  AppUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.role,
    this.profileImageUrl,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      role: data['role'] ?? '',
      profileImageUrl: data['profileImageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'role': role,
      'profileImageUrl': profileImageUrl,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
