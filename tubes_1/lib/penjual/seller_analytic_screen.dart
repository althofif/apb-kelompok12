// penjual/seller_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerAnalyticsScreen extends StatelessWidget {
  const SellerAnalyticsScreen({Key? key}) : super(key: key);

  Future<String> _getBestSellingMenu(List<QueryDocumentSnapshot> orders) async {
    if (orders.isEmpty) return 'N/A';

    final Map<String, int> menuSales = {};

    for (var doc in orders) {
      final data = doc.data() as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];

      for (var item in items) {
        final itemData = item as Map<String, dynamic>;
        final menuId = itemData['menuId'] as String?;
        final quantity = (itemData['quantity'] ?? 0) as int;

        if (menuId != null) {
          menuSales.update(
            menuId,
            (value) => value + quantity,
            ifAbsent: () => quantity,
          );
        }
      }
    }

    if (menuSales.isEmpty) return 'N/A';

    String bestSellingMenuId = '';
    int maxSales = 0;
    menuSales.forEach((key, value) {
      if (value > maxSales) {
        maxSales = value;
        bestSellingMenuId = key;
      }
    });

    if (bestSellingMenuId.isNotEmpty) {
      try {
        final menuDoc =
            await FirebaseFirestore.instance
                .collection('menus')
                .doc(bestSellingMenuId)
                .get();
        if (menuDoc.exists) {
          final menuData = menuDoc.data() as Map<String, dynamic>;
          return menuData['name'] ??
              'ID: ${bestSellingMenuId.substring(0, 5)}...';
        }
      } catch (e) {
        return 'Error';
      }
    }

    return 'N/A';
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            const Spacer(),
            Text(title, style: TextStyle(color: Colors.grey[600])),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analitik')),
        body: const Center(child: Text('Harap login untuk melihat analitik.')),
      );
    }

    final ordersQuery = FirebaseFirestore.instance
        .collection('orders')
        .where('restaurantId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'Selesai');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analitik & Laporan'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: ordersQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Gagal memuat data.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada data pesanan selesai.'));
          }

          final completedOrders = snapshot.data!.docs;
          final double totalRevenue = completedOrders.fold(0.0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return sum + (data['total'] ?? 0.0);
          });
          final int totalOrders = completedOrders.length;
          final double averageOrderValue =
              totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                'Ringkasan Performa',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _buildMetricCard(
                    'Total Pendapatan',
                    'Rp ${totalRevenue.toStringAsFixed(0)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                  _buildMetricCard(
                    'Total Pesanan Selesai',
                    totalOrders.toString(),
                    Icons.check_circle_outline,
                    Colors.blue,
                  ),
                  _buildMetricCard(
                    'Rata-rata per Pesanan',
                    'Rp ${averageOrderValue.toStringAsFixed(0)}',
                    Icons.pie_chart_outline,
                    Colors.purple,
                  ),
                  FutureBuilder<String>(
                    future: _getBestSellingMenu(completedOrders),
                    builder: (context, bestSellerSnapshot) {
                      if (bestSellerSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return _buildMetricCard(
                          'Menu Terlaris',
                          '...',
                          Icons.star_outline,
                          Colors.red,
                        );
                      }
                      return _buildMetricCard(
                        'Menu Terlaris',
                        bestSellerSnapshot.data ?? 'N/A',
                        Icons.star_outline,
                        Colors.red,
                      );
                    },
                  ),
                ],
              ),
              const Divider(height: 40),
              Text(
                'Pesanan Terakhir Selesai',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...completedOrders.take(5).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Card(
                  child: ListTile(
                    title: Text('Pesanan #${doc.id.substring(0, 6)}...'),
                    subtitle: Text('Pelanggan: ${data['customerName']}'),
                    trailing: Text('Rp ${data['total']?.toStringAsFixed(0)}'),
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}
