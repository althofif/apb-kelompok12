import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_detail_screen.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Riwayat Pesanan'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          bottom: const TabBar(
            tabs: [Tab(text: 'Sedang Berlangsung'), Tab(text: 'Selesai')],
            labelColor: Colors.black,
            indicatorColor: Colors.blue,
          ),
        ),
        body:
            userId == null
                ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 60),
                      SizedBox(height: 16),
                      Text('Silakan login untuk melihat riwayat.'),
                    ],
                  ),
                )
                : TabBarView(
                  children: [
                    _buildOrderList(context, userId, ['Disiapkan', 'Diantar']),
                    _buildOrderList(context, userId, ['Selesai', 'Dibatalkan']),
                  ],
                ),
      ),
    );
  }

  Widget _buildOrderList(
    BuildContext context,
    String userId,
    List<String> statuses,
  ) {
    final Stream<QuerySnapshot> orderStream =
        FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: userId)
            .where('status', whereIn: statuses)
            .orderBy('createdAt', descending: true)
            .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: orderStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 60),
                SizedBox(height: 16),
                Text('Terjadi kesalahan saat memuat pesanan.'),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 80,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tidak ada pesanan di kategori ini',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(12),
          children:
              snapshot.data!.docs.map((DocumentSnapshot document) {
                Map<String, dynamic> order =
                    document.data()! as Map<String, dynamic>;
                final isCompleted = order['status'] == 'Selesai';
                final isCancelled = order['status'] == 'Dibatalkan';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    title: Text(
                      order['restaurantName'] ?? 'Nama Restoran',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'ID: ${document.id.substring(0, 6)}...\nTanggal: ${order['date'] ?? 'Tidak diketahui'}',
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Rp ${order['total']?.toStringAsFixed(0) ?? '0'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isCompleted
                                    ? Colors.green[100]
                                    : (isCancelled
                                        ? Colors.red[100]
                                        : Colors.blue[100]),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            order['status'],
                            style: TextStyle(
                              color:
                                  isCompleted
                                      ? Colors.green[800]
                                      : (isCancelled
                                          ? Colors.red[800]
                                          : Colors.blue[800]),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  OrderDetailScreen(orderId: document.id),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}
