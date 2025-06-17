import 'package:flutter/material.dart';
import 'customer_home_screen.dart'; // Import home screen

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 24),
              const Text(
                'Pesanan Berhasil!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Pesanan Anda telah diterima dan sedang disiapkan. Silakan cek status pesanan Anda secara berkala.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // Kembali ke halaman utama
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const CustomerHomeScreen(),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('KEMBALI KE BERANDA'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  // Hapus semua halaman, buka home, lalu langsung buka history
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const CustomerHomeScreen(),
                    ),
                    (route) => false,
                  );
                  // Navigasi ini akan error jika CustomerHomeScreen tidak ada di stack
                  // Cara di atas lebih aman
                  // Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const OrderHistoryScreen()));
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('LIHAT RIWAYAT PESANAN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
