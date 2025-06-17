import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // <-- PASTIKAN IMPORT INI ADA
import 'active_delivery_screen.dart';

class DriverHistoryScreen extends StatelessWidget {
  const DriverHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pengantaran'),
        automaticallyImplyLeading: false,
      ),
      body:
          user == null
              ? const Center(child: Text('Silakan login untuk melihat riwayat'))
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('orders')
                        .where('driverId', isEqualTo: user.uid)
                        .where('status', whereIn: ['Selesai', 'Dibatalkan'])
                        .orderBy('deliveryTime', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text('Terjadi kesalahan memuat data.'),
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('Belum ada riwayat pengantaran'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final order = doc.data() as Map<String, dynamic>;

                      final Timestamp? deliveryTime =
                          order['deliveryTime'] as Timestamp?;
                      // PERBAIKAN: Menggunakan DateFormat untuk format tanggal yang aman
                      final String formattedDate =
                          deliveryTime != null
                              ? DateFormat(
                                'd MMM yyyy, HH:mm',
                                'id_ID',
                              ).format(deliveryTime.toDate())
                              : 'N/A';

                      final bool isCancelled = order['status'] == 'Dibatalkan';

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: ListTile(
                          leading: Icon(
                            isCancelled ? Icons.cancel : Icons.check_circle,
                            color: isCancelled ? Colors.red : Colors.green,
                          ),
                          title: Text('Pesanan #${doc.id.substring(0, 6)}'),
                          subtitle: Text(
                            'Total: Rp ${order['totalAmount']?.toStringAsFixed(0) ?? '0'}\nStatus: ${order['status']}',
                          ),
                          trailing: Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        ActiveDeliveryScreen(orderId: doc.id),
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
