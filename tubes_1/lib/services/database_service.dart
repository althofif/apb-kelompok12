// services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // Referensi ke koleksi users
  final CollectionReference userCollection = FirebaseFirestore.instance
      .collection('users');

  // Fungsi untuk membuat atau memperbarui data pengguna
  Future<void> updateUserData(String name, String email, String role) async {
    return await userCollection.doc(uid).set({
      'name': name,
      'email': email,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Fungsi untuk mendapatkan data pengguna dari Firestore
  Future<DocumentSnapshot> getUserData() async {
    return await userCollection.doc(uid).get();
  }
}
