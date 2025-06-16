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

// ... (SellerHomeScreen State class remains the same)
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

// Refactored DashboardPenjual
class DashboardPenjual extends StatelessWidget {
  const DashboardPenjual({Key? key}) : super(key: key);

  // ... (Widget _buildSummaryCard remains the same)

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text('Silakan login.')));

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard Penjual')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Populer',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('menus')
                      .where('restaurantId', isEqualTo: user.uid)
                      .orderBy('popularity', descending: true)
                      .limit(3)
                      .snapshots(),
              builder: (context, menuSnapshot) {
                if (!menuSnapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                if (menuSnapshot.data!.docs.isEmpty)
                  return const Text('Belum ada menu populer.');

                return Column(
                  children:
                      menuSnapshot.data!.docs.map((doc) {
                        final menuItem = menu_model.MenuItem.fromFirestore(doc);
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(menuItem.imageUrl),
                            ),
                            title: Text(menuItem.name),
                            trailing: Text("Dilihat: ${menuItem.popularity}"),
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

// Refactored PesananMasukScreen
class PesananMasukScreen extends StatelessWidget {
  const PesananMasukScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null)
      return const Scaffold(
        appBar: null,
        body: Center(child: Text('Silakan login.')),
      );

    return Scaffold(
      appBar: AppBar(title: const Text('Pesanan Masuk')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('orders')
                .where('restaurantId', isEqualTo: user.uid)
                .where('status', whereIn: ['Menunggu Konfirmasi', 'Disiapkan'])
                .orderBy('orderTime', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty)
            return const Center(
              child: Text('Tidak ada pesanan masuk saat ini.'),
            );

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (ctx, i) {
              final order = model.Order.fromFirestore(snapshot.data!.docs[i]);
              final isNew = order.status == 'Menunggu Konfirmasi';
              return Card(
                color: isNew ? Colors.orange[50] : null,
                child: ListTile(
                  title: Text('Pesanan #${order.id.substring(0, 6)}...'),
                  subtitle: Text(
                    '${order.items.length} item - Rp ${order.totalAmount.toStringAsFixed(0)}',
                  ),
                  trailing: Text(
                    order.status,
                    style: TextStyle(
                      color: isNew ? Colors.red : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                SellerOrderDetailScreen(orderId: order.id),
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
