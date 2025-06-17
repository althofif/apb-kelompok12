import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart'; // Import storage service

enum UserRole { customer, seller, admin }

class AppUser {
  final String uid;
  final String username;
  final String email;
  final String? profileImageUrl;
  final String? phone;
  final UserRole role;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.username,
    required this.email,
    this.profileImageUrl,
    this.phone,
    required this.role,
    required this.createdAt,
  });

  // Convert AppUser to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'phone': phone,
      'role': role.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create AppUser from Firestore DocumentSnapshot
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AppUser(
      uid: doc.id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      phone: data['phone'],
      role: _parseUserRole(data['role']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create AppUser from Map
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      phone: map['phone'],
      role: _parseUserRole(map['role']),
      createdAt:
          map['createdAt'] is Timestamp
              ? (map['createdAt'] as Timestamp).toDate()
              : map['createdAt'] is DateTime
              ? map['createdAt']
              : DateTime.now(),
    );
  }

  // Helper method to parse UserRole from string
  static UserRole _parseUserRole(dynamic roleData) {
    if (roleData == null) return UserRole.customer;

    final roleString = roleData.toString().toLowerCase();
    switch (roleString) {
      case 'seller':
        return UserRole.seller;
      case 'admin':
        return UserRole.admin;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }

  // Upload profile image dan update user
  Future<AppUser?> updateProfileImage(File imageFile) async {
    try {
      String? downloadUrl = await FirebaseStorageService.uploadUserProfile(
        userId: uid,
        imageFile: imageFile,
      );

      if (downloadUrl != null) {
        return copyWith(profileImageUrl: downloadUrl);
      }
      return null;
    } catch (e) {
      print('Error updating profile image: $e');
      return null;
    }
  }

  // Delete profile image
  Future<bool> deleteProfileImage() async {
    if (profileImageUrl == null) return true;

    try {
      return await FirebaseStorageService.deleteFile(profileImageUrl!);
    } catch (e) {
      print('Error deleting profile image: $e');
      return false;
    }
  }

  // Create a copy of AppUser with updated fields
  AppUser copyWith({
    String? uid,
    String? username,
    String? email,
    String? profileImageUrl,
    String? phone,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'AppUser(uid: $uid, username: $username, email: $email, phone: $phone, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

// Extension for UserRole to get display names
extension UserRoleExtension on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.seller:
        return 'Seller';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get value {
    return toString().split('.').last;
  }
}
