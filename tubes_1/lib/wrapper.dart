import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/welcome_screen.dart';
import 'pelanggan/customer_home_screen.dart';
import 'penjual/seller_home_screen.dart';
import 'driver/driver_home_screen.dart';
// user_model bisa digunakan di sini untuk parsing yang lebih aman
import 'models/user_model.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            // Pengguna tidak login, arahkan ke WelcomeScreen
            return const WelcomeScreen();
          } else {
            // Pengguna login, cek perannya dan arahkan
            return RoleBasedRedirect(uid: user.uid);
          }
        }
        // Menunggu koneksi
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

class RoleBasedRedirect extends StatelessWidget {
  final String uid;
  const RoleBasedRedirect({Key? key, required this.uid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data!.exists) {
            // Menggunakan AppUser model untuk parsing yang lebih aman
            final appUser = AppUser.fromFirestore(snapshot.data!);

            switch (appUser.role) {
              case 'Pelanggan':
                return const CustomerHomeScreen();
              case 'Penjual':
                return const SellerHomeScreen();
              case 'Driver':
                return const DriverHomeScreen();
              default:
                // Jika peran tidak dikenali, kembali ke welcome screen
                return const WelcomeScreen();
            }
          }
          // Jika data user tidak ada di Firestore, default ke welcome
          return const WelcomeScreen();
        }
        // Tampilkan loading indicator selagi menunggu data user
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
