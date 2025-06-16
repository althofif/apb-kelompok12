import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/welcome_screen.dart';
import '/pelanggan/customer_home_screen.dart';
import '/penjual/seller_home_screen.dart';
import '/driver/driver_home_screen.dart';
import '/models/user_role.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        if (snapshot.hasError) {
          return _buildErrorScreen(context, 'Error checking auth status');
        }

        if (snapshot.hasData) {
          return RoleBasedRedirect(uid: snapshot.data!.uid);
        }

        return const WelcomeScreen();
      },
    );
  }

  Widget _buildLoadingScreen() =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));

  Widget _buildErrorScreen(BuildContext context, String message) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                  ),
              child: const Text('Kembali ke Halaman Utama'),
            ),
          ],
        ),
      ),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const WelcomeScreen();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final role = data['role'] as String;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateBasedOnRole(context, role);
        });

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  void _navigateBasedOnRole(BuildContext context, String role) {
    Widget screen;
    switch (role) {
      case 'Pelanggan':
        screen = const CustomerHomeScreen();
        break;
      case 'Penjual':
        screen = const SellerHomeScreen();
        break;
      case 'Driver':
        screen = const DriverHomeScreen();
        break;
      default:
        screen = const WelcomeScreen();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }
}
