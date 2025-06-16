import 'package:flutter/material.dart';
import '/auth/auth_screen.dart';
import '/models/user_role.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  void _navigateToAuth(BuildContext context, UserRole role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AuthScreen(role: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF38B6FF), Color(0xFF00A9FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.restaurant_menu,
                  color: Color(0xFF00A9FF),
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Selamat Datang di',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
              const Text(
                'Dapoer Kita',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pacifico',
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Pilih cara Anda ingin menggunakan aplikasi',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const Spacer(flex: 1),
              _buildRoleButton(
                context,
                icon: Icons.person_outline,
                title: 'Saya Pelanggan',
                subtitle: 'Pesan makanan favorit Anda',
                onTap: () => _navigateToAuth(context, UserRole.Pelanggan),
              ),
              _buildRoleButton(
                context,
                icon: Icons.storefront_outlined,
                title: 'Saya Pemilik Restoran',
                subtitle: 'Kelola menu dan pesanan',
                onTap: () => _navigateToAuth(context, UserRole.Penjual),
              ),
              _buildRoleButton(
                context,
                icon: Icons.delivery_dining_outlined,
                title: 'Saya Driver',
                subtitle: 'Antar pesanan dan dapatkan penghasilan',
                onTap: () => _navigateToAuth(context, UserRole.Driver),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF38B6FF), size: 30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
