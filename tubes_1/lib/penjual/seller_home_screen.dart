import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart' as model;
import '../models/menu_item.dart' as menu_model;
import 'manage_menu_screen.dart';
import 'seller_order_detail_screen.dart';
import 'seller_profile_screen.dart';
import 'seller_analytic_screen.dart';
import '../services/auth_service.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({Key? key}) : super(key: key);

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = [
    const DashboardPenjual(),
    const PesananMasukScreen(),
    const ManageMenuScreen(),
    const SellerProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Pesanan'),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Menu',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// --- WIDGET YANG DIUBAH DIMULAI DI SINI ---
class DashboardPenjual extends StatelessWidget {
  const DashboardPenjual({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan login terlebih dahulu')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Penjual'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            _buildSummarySection(user.uid),
            const SizedBox(height: 24),

            // UBAH: Judul bagian
            const Text(
              'Menu Anda',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // UBAH: Memanggil fungsi yang sudah diganti logikanya
            _buildMenuListSection(user.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(String userId) {
    // ... (Fungsi ini tidak ada perubahan)
    return Column(
      children: [
        // Today's Orders
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('orders')
                  .where('restaurantId', isEqualTo: userId)
                  .where(
                    'orderTime',
                    isGreaterThanOrEqualTo: DateTime.now().subtract(
                      const Duration(days: 1),
                    ),
                  )
                  .snapshots(),
          builder: (context, snapshot) {
            int todayOrders = 0;
            double todayRevenue = 0;

            if (snapshot.hasData) {
              todayOrders = snapshot.data!.docs.length;
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                todayRevenue += (data['totalAmount'] as num?)?.toDouble() ?? 0;
              }
            }

            return Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Pesanan Hari Ini',
                    todayOrders.toString(),
                    Icons.shopping_cart,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Pendapatan Hari Ini',
                    'Rp ${todayRevenue.toStringAsFixed(0)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),

        // Total Menu Count
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('menus')
                  .where('restaurantId', isEqualTo: userId)
                  .snapshots(),
          builder: (context, snapshot) {
            int totalMenus = 0;
            int availableMenus = 0;

            if (snapshot.hasData) {
              totalMenus = snapshot.data!.docs.length;
              availableMenus =
                  snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['available'] == true;
                  }).length;
            }

            return Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Menu',
                    totalMenus.toString(),
                    Icons.restaurant_menu,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Menu Tersedia',
                    availableMenus.toString(),
                    Icons.check_circle,
                    Colors.teal,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    // ... (Fungsi ini tidak ada perubahan)
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // UBAH: Fungsi ini diganti dari _buildPopularMenuSection menjadi _buildMenuListSection
  Widget _buildMenuListSection(String userId) {
    return StreamBuilder<QuerySnapshot>(
      // UBAH: Query diubah untuk mengambil semua menu dan diurutkan berdasarkan nama
      stream:
          FirebaseFirestore.instance
              .collection('menus')
              .where('restaurantId', isEqualTo: userId)
              .orderBy('name') // Mengurutkan berdasarkan nama menu
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            color: Colors.red[50],
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Gagal memuat data menu. Pastikan index sudah dibuat.',
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada menu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tambahkan menu pertama Anda melalui tab Menu',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children:
              snapshot.data!.docs.map((doc) {
                try {
                  final data = doc.data() as Map<String, dynamic>;
                  // UBAH: Mengambil status ketersediaan menu
                  final bool isAvailable = data['available'] ?? false;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            data['imageUrl'] != null
                                ? Image.network(
                                  data['imageUrl'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 50,
                                      height: 50,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.error),
                                    );
                                  },
                                )
                                : Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.restaurant),
                                ),
                      ),
                      title: Text(
                        data['name'] ?? 'Menu Tidak Dikenal',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Rp ${(data['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                      ),
                      // UBAH: Trailing diubah untuk menunjukkan status ketersediaan
                      trailing: Text(
                        isAvailable ? 'Tersedia' : 'Habis',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              isAvailable ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ),
                  );
                } catch (e) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.error, color: Colors.red),
                      title: const Text('Error memuat item menu'),
                      subtitle: Text('Error: $e'),
                    ),
                  );
                }
              }).toList(),
        );
      },
    );
  }
}
// --- WIDGET YANG DIUBAH SELESAI DI SINI ---

class PesananMasukScreen extends StatelessWidget {
  // ... (Tidak ada perubahan pada widget ini)
  const PesananMasukScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        appBar: null,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Silakan login terlebih dahulu'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Masuk'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('orders')
                .where('restaurantId', isEqualTo: user.uid)
                .where(
                  'status',
                  whereIn: [
                    'Menunggu Konfirmasi',
                    'Disiapkan',
                    'Sedang Disiapkan',
                  ],
                )
                .orderBy('orderTime', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memuat pesanan...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Gagal memuat pesanan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Force rebuild to retry
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Tidak ada pesanan masuk',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pesanan baru akan muncul di sini',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Force refresh
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (ctx, i) {
                try {
                  final doc = snapshot.data!.docs[i];
                  final data = doc.data() as Map<String, dynamic>;

                  // Safely extract data
                  final orderId = doc.id;
                  final status = data['status'] ?? 'Unknown';
                  final totalAmount =
                      (data['totalAmount'] as num?)?.toDouble() ?? 0;
                  final items = data['items'] as List? ?? [];
                  final orderTime = data['orderTime'] as Timestamp?;

                  final isNew = status == 'Menunggu Konfirmasi';

                  return Card(
                    color: isNew ? Colors.orange[50] : null,
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isNew ? Colors.orange : Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isNew ? Icons.new_releases : Icons.restaurant,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Pesanan #${orderId.substring(0, 6)}...',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${items.length} item - Rp ${totalAmount.toStringAsFixed(0)}',
                          ),
                          if (orderTime != null)
                            Text(
                              _formatTime(orderTime.toDate()),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isNew ? Colors.red : Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    SellerOrderDetailScreen(orderId: orderId),
                          ),
                        );
                      },
                    ),
                  );
                } catch (e) {
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 8,
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.error, color: Colors.red),
                      title: const Text('Error loading order'),
                      subtitle: Text('Error: $e'),
                    ),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
