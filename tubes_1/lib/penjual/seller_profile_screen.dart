// penjual/seller_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'edit_seller_profile_screen.dart';
import 'seller_payment_setting_screen.dart';
import 'seller_analytic_screen.dart';
import '../screens/welcome_screen.dart'; // <-- IMPORT BARU

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({Key? key}) : super(key: key);

  @override
  _SellerProfileScreenState createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // --- FUNGSI UNTUK PROSES LOGOUT ---
  Future<void> _handleLogout() async {
    // Tampilkan dialog konfirmasi sebelum logout
    final bool? confirmLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop(false); // Mengembalikan false
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop(true); // Mengembalikan true
              },
            ),
          ],
        );
      },
    );

    // Jika user menekan "Logout" (dialog mengembalikan true)
    if (confirmLogout == true) {
      try {
        await AuthService().signOut();

        // Navigasi ke WelcomeScreen dan hapus semua rute sebelumnya
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (Route<dynamic> route) =>
                false, // Predikat ini menghapus semua rute
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal logout: $e')));
        }
      }
    }
  }

  Widget _buildInfoColumn(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildOptionTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Card(
        elevation: 2,
        child: ListTile(
          onTap: onTap,
          leading: Icon(
            icon,
            color: isLogout ? Colors.red : Theme.of(context).primaryColor,
          ),
          title: Text(
            title,
            style: TextStyle(color: isLogout ? Colors.red : Colors.black),
          ),
          trailing:
              isLogout ? null : const Icon(Icons.arrow_forward_ios, size: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Silakan login untuk melihat profil.")),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('restaurants')
              .doc(_currentUser.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text("Terjadi kesalahan.")),
          );
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          // ... (kode ini tidak berubah)
          return Scaffold(
            appBar: AppBar(
              title: const Text('Profil Restoran'),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Profil restoran belum dibuat."),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (ctx) => const EditSellerProfileScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Buat Profil Sekarang'),
                  ),
                ],
              ),
            ),
          );
        }

        final restaurantProfile = snapshot.data!.data() as Map<String, dynamic>;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text('Profil Restoran'),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => const EditSellerProfileScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // ... (bagian atas tidak berubah)
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                            restaurantProfile['imageUrl'] ??
                                'https://placehold.co/600x400',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -60,
                      child: Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                restaurantProfile['name'] ?? 'Nama Restoran',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                restaurantProfile['address'] ?? 'Alamat',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 80),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoColumn(
                        (restaurantProfile['rating'] ?? 0.0).toString(),
                        'Rating',
                        Icons.star,
                        Colors.amber,
                      ),
                      _buildInfoColumn(
                        (restaurantProfile['reviews'] ?? 0).toString(),
                        'Ulasan',
                        Icons.reviews,
                        Colors.blue,
                      ),
                      _buildInfoColumn(
                        (restaurantProfile['isOpen'] ?? false)
                            ? 'Buka'
                            : 'Tutup',
                        'Status',
                        Icons.circle,
                        (restaurantProfile['isOpen'] ?? false)
                            ? Colors.green
                            : Colors.red,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 40),
                _buildOptionTile(
                  context,
                  'Analitik & Laporan',
                  Icons.bar_chart,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SellerAnalyticsScreen(),
                      ),
                    );
                  },
                ),
                _buildOptionTile(
                  context,
                  'Pengaturan Pembayaran',
                  Icons.account_balance_wallet_outlined,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => const SellerPaymentSettingsScreen(),
                      ),
                    );
                  },
                ),
                // --- UBAH CARA PEMANGGILAN FUNGSI LOGOUT ---
                _buildOptionTile(
                  context,
                  'Logout',
                  Icons.logout,
                  _handleLogout, // Panggil fungsi _handleLogout
                  isLogout: true,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
