import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverHistoryScreen extends StatelessWidget {
  const DriverHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pengantaran'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body:
          user == null
              ? const Center(child: Text('Silakan login untuk melihat riwayat'))
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('orders')
                        .where('driverId', isEqualTo: user.uid)
                        .where('status', isEqualTo: 'completed')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('Belum ada riwayat pengantaran'),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          leading: const Icon(
                            Icons.delivery_dining,
                            color: Colors.green,
                          ),
                          title: Text('Pesanan #${doc.id.substring(0, 6)}'),
                          subtitle: Text(
                            'Dari: ${data['restaurantName'] ?? 'Restoran'}',
                          ),
                          trailing: Text('Rp ${data['deliveryFee'] ?? '0'}'),
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
