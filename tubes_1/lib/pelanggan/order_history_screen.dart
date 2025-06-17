import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_detail_screen.dart';
import 'package:intl/intl.dart'; // Import intl package

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
          automaticallyImplyLeading: false, // Hapus tombol kembali
          bottom: const TabBar(
            tabs: [Tab(text: 'Sedang Berlangsung'), Tab(text: 'Selesai')],
          ),
        ),
        body:
            userId == null
                ? const Center(
                  child: Text('Silakan login untuk melihat riwayat.'),
                )
                : TabBarView(
                  children: [
                    _buildOrderList(context, userId, [
                      'Menunggu Konfirmasi',
                      'Disiapkan',
                      'Diantar',
                    ]),
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
    // PERBAIKAN KRITIS: Menggunakan 'customerId' sesuai dengan data yang disimpan
    final Stream<QuerySnapshot> orderStream =
        FirebaseFirestore.instance
            .collection('orders')
            .where('customerId', isEqualTo: userId) // DIUBAH DARI 'userId'
            .where('status', whereIn: statuses)
            .orderBy('orderTime', descending: true)
            .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: orderStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError)
          return const Center(child: Text('Terjadi kesalahan.'));
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty)
          return const Center(child: Text('Tidak ada pesanan di kategori ini'));

        return ListView(
          padding: const EdgeInsets.all(12),
          children:
              snapshot.data!.docs.map((DocumentSnapshot document) {
                Map<String, dynamic> order =
                    document.data()! as Map<String, dynamic>;
                final Timestamp? orderTime = order['orderTime'] as Timestamp?;
                final String formattedDate =
                    orderTime != null
                        ? DateFormat(
                          'd MMM yyyy, HH:mm',
                        ).format(orderTime.toDate())
                        : 'Tidak diketahui';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      order['restaurantName'] ?? 'Nama Restoran',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'ID: ${document.id.substring(0, 6)}...\n$formattedDate',
                    ),
                    trailing: Text(
                      'Rp ${order['totalAmount']?.toStringAsFixed(0) ?? '0'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    OrderDetailScreen(orderId: document.id),
                          ),
                        ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}
