import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'edit_driver_profile_screen.dart';
import 'vehicle_information_screen.dart';
import 'driver_document_screen.dart'; // Import layar baru

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Silakan login kembali.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Driver'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Data profil tidak ditemukan."));
          }

          final appUser = AppUser.fromFirestore(snapshot.data!);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildProfileHeader(appUser),
              const SizedBox(height: 24),
              _buildProfileMenu(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(AppUser user) {
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey.shade200,
          backgroundImage:
              user.profileImageUrl != null
                  ? CachedNetworkImageProvider(user.profileImageUrl!)
                  : null,
          child:
              user.profileImageUrl == null
                  ? const Icon(Icons.person, size: 60)
                  : null,
        ),
        const SizedBox(height: 16),
        Text(
          user.username,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          user.email,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildProfileMenu(BuildContext context) {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Edit Profil Akun'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditDriverProfileScreen(),
                  ),
                ),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.motorcycle_outlined),
            title: const Text('Informasi Kendaraan'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VehicleInformationScreen(),
                  ),
                ),
          ),
        ),
        // --- MENU BARU DITAMBAHKAN DI SINI ---
        Card(
          child: ListTile(
            leading: const Icon(
              Icons.document_scanner_outlined,
              color: Colors.blue,
            ),
            title: const Text('Dokumen Verifikasi'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DriverDocumentScreen(),
                  ),
                ),
          ),
        ),
      ],
    );
  }
}
