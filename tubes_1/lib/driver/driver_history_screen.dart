import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart' as model; // Import Order model

class DriverHistoryScreen extends StatelessWidget {
  const DriverHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pengantaran')),
      body:
          user == null
              ? const Center(child: Text('Silakan login untuk melihat riwayat'))
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('orders')
                        .where('driverId', isEqualTo: user.uid)
                        .where(
                          'status',
                          isEqualTo: 'Selesai',
                        ) // Status konsisten
                        .orderBy('deliveryTime', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());
                  if (snapshot.data!.docs.isEmpty)
                    return const Center(
                      child: Text('Belum ada riwayat pengantaran'),
                    );

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final order = model.Order.fromFirestore(
                        snapshot.data!.docs[index],
                      );
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          leading: const Icon(
                            Icons.delivery_dining,
                            color: Colors.green,
                          ),
                          title: Text('Pesanan #${order.id.substring(0, 6)}'),
                          subtitle: Text(
                            'Total: Rp ${order.totalAmount.toStringAsFixed(0)}',
                          ),
                          trailing: Text(
                            // Anda bisa format tanggal ini dengan 'intl' package
                            order.deliveryTime?.toDate().toString() ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
