import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class DashboardPenjual extends StatelessWidget {
  const DashboardPenjual({Key? key}) : super(key: key);

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: Colors.white, size: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard Penjual',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SellerAnalyticsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.analytics),
          ),
          IconButton(
            onPressed: () async => await AuthService().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body:
          user == null
              ? const Center(
                child: Text('Silakan login untuk melihat dashboard.'),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ringkasan Hari Ini',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('orders')
                              .where('restaurantId', isEqualTo: user.uid)
                              .where('status', isEqualTo: 'Selesai')
                              .where(
                                'createdAt',
                                isGreaterThan: DateTime.now().subtract(
                                  const Duration(days: 1),
                                ),
                              )
                              .snapshots(),
                      builder: (context, completedOrdersSnapshot) {
                        double totalRevenue = 0;
                        int completedOrders = 0;

                        if (completedOrdersSnapshot.hasData) {
                          completedOrders =
                              completedOrdersSnapshot.data!.docs.length;
                          totalRevenue = completedOrdersSnapshot.data!.docs
                              .fold(0.0, (sum, doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return sum + (data['total'] ?? 0.0);
                              });
                        }

                        return GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          children: [
                            _buildSummaryCard(
                              'Total Pendapatan',
                              'Rp ${totalRevenue.toStringAsFixed(0)}',
                              Icons.attach_money,
                              Colors.green,
                            ),
                            _buildSummaryCard(
                              'Pesanan Selesai',
                              completedOrders.toString(),
                              Icons.check_circle,
                              Colors.blue,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('menus')
                                    .where('restaurantId', isEqualTo: user.uid)
                                    .where('available', isEqualTo: true)
                                    .snapshots(),
                            builder: (context, menuSnapshot) {
                              int activeMenus = 0;
                              if (menuSnapshot.hasData) {
                                activeMenus = menuSnapshot.data!.docs.length;
                              }
                              return _buildSummaryCard(
                                'Menu Aktif',
                                activeMenus.toString(),
                                Icons.restaurant_menu,
                                Colors.orange,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('orders')
                                    .where('restaurantId', isEqualTo: user.uid)
                                    .where(
                                      'status',
                                      whereIn: ['Baru', 'Disiapkan'],
                                    )
                                    .snapshots(),
                            builder: (context, pendingOrdersSnapshot) {
                              int pendingOrders = 0;
                              if (pendingOrdersSnapshot.hasData) {
                                pendingOrders =
                                    pendingOrdersSnapshot.data!.docs.length;
                              }
                              return _buildSummaryCard(
                                'Pesanan Pending',
                                pendingOrders.toString(),
                                Icons.pending,
                                Colors.red,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Menu Populer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('menus')
                              .where('restaurantId', isEqualTo: user.uid)
                              .where('available', isEqualTo: true)
                              .orderBy('soldCount', descending: true)
                              .limit(3)
                              .snapshots(),
                      builder: (context, menuSnapshot) {
                        if (menuSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!menuSnapshot.hasData ||
                            menuSnapshot.data!.docs.isEmpty) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Text('Belum ada menu yang populer'),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const ManageMenuScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Tambah Menu'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return Column(
                          children:
                              menuSnapshot.data!.docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        data['imageUrl'] ??
                                            'https://placehold.co/50',
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            width: 50,
                                            height: 50,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.restaurant),
                                          );
                                        },
                                      ),
                                    ),
                                    title: Text(data['name'] ?? 'Tanpa Nama'),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Rp ${data['price'] ?? 0}'),
                                        Text(
                                          'Terjual: ${data['soldCount'] ?? 0}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    trailing: const Icon(
                                      Icons.trending_up,
                                      color: Colors.green,
                                    ),
                                  ),
                                );
                              }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
    );
  }
}

class PesananMasukScreen extends StatefulWidget {
  const PesananMasukScreen({Key? key}) : super(key: key);

  @override
  State<PesananMasukScreen> createState() => _PesananMasukScreenState();
}

class _PesananMasukScreenState extends State<PesananMasukScreen> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Masuk'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body:
          user == null
              ? const Center(
                child: Text('Silakan login untuk melihat pesanan.'),
              )
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('orders')
                        .where('restaurantId', isEqualTo: user.uid)
                        .where('status', whereIn: ['Baru', 'Disiapkan'])
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.wifi_off,
                            size: 50,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Gagal terhubung ke server',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pastikan koneksi internet Anda stabil',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Muat Ulang'),
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
                          const Icon(
                            Icons.list_alt,
                            size: 50,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tidak ada pesanan masuk saat ini',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pesanan baru akan muncul di sini',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  final orders = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: orders.length,
                    itemBuilder: (ctx, i) {
                      final order = orders[i];
                      final data = order.data() as Map<String, dynamic>;
                      final status = data['status'] ?? 'Baru';
                      final isNewOrder = status == 'Baru';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        color: isNewOrder ? Colors.orange[50] : null,
                        child: ListTile(
                          title: Text(
                            'Pesanan #${order.id.substring(0, 6)}...',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Dari: ${data['customerName'] ?? 'Tanpa Nama'}\n'
                            '${(data['items'] as List).length} item - '
                            'Rp ${data['total']?.toStringAsFixed(0) ?? '0'}',
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isNewOrder ? Colors.red : Colors.blue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => SellerOrderDetailScreen(
                                      orderId: order.id,
                                    ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
