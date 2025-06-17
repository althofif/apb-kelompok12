import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'active_delivery_screen.dart'; // INI ADALAH PERBAIKAN PATH
import '../models/order.dart' as model;
import 'driver_map_screen.dart';
import 'driver_profile_screen.dart';
import 'driver_history_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({Key? key}) : super(key: key);

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    const DriverDashboardScreen(),
    const DriverMapScreen(),
    const DriverHistoryScreen(),
    const DriverProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Peta'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  Future<void> _handleAcceptOrder(
    BuildContext context,
    String orderId,
    String driverId,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update(
        {'status': 'Diantar', 'driverId': driverId},
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveDeliveryScreen(orderId: orderId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil pesanan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Silakan login."));

    final startOfToday = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Beranda Driver')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('orders')
                .where('driverId', isEqualTo: user.uid)
                .where('status', isEqualTo: 'Selesai')
                .where('deliveryTime', isGreaterThanOrEqualTo: startOfToday)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final todaysOrders = snapshot.data?.docs ?? [];
          final double todaysRevenue = todaysOrders.fold(0.0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            final deliveryFee = data['delivery_fee'] ?? 0.0;
            return sum + (deliveryFee as num);
          });

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'Selamat datang, ${user.displayName ?? 'Driver'}!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                _buildActiveOrderCard(context, user.uid),
                const Divider(height: 40),
                const Text(
                  'Pesanan Tersedia Untuk Diambil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildAvailableOrders(context, user.uid),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveOrderCard(BuildContext context, String driverId) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('orders')
              .where('driverId', isEqualTo: driverId)
              .where('status', isEqualTo: 'Diantar')
              .limit(1)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final activeOrderDoc = snapshot.data!.docs.first;
        final activeOrder = model.Order.fromFirestore(activeOrderDoc);
        final orderData = activeOrderDoc.data() as Map<String, dynamic>;
        final restaurantName = orderData['restaurantName'] ?? 'Restoran';

        return Card(
          color: Colors.green[50],
          elevation: 4,
          child: ListTile(
            leading: const Icon(Icons.delivery_dining, color: Colors.green),
            title: const Text(
              "Anda memiliki 1 pengantaran aktif",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Antar pesanan dari $restaurantName."),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ActiveDeliveryScreen(orderId: activeOrder.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAvailableOrders(BuildContext context, String driverId) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('orders')
              .where('status', isEqualTo: 'Siap Diambil')
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: Text("Mencari pesanan..."));
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return const Card(
            child: ListTile(title: Text("Tidak ada pesanan tersedia.")),
          );

        return Column(
          children:
              snapshot.data!.docs.map((doc) {
                final orderData = doc.data() as Map<String, dynamic>;
                final restaurantName =
                    orderData['restaurantName'] ?? 'Restoran';
                final deliveryAddress =
                    orderData['deliveryAddressLabel'] ?? 'Alamat Tujuan';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text("Ambil di: $restaurantName"),
                    subtitle: Text("Tujuan: $deliveryAddress"),
                    trailing: ElevatedButton(
                      onPressed:
                          () => _handleAcceptOrder(context, doc.id, driverId),
                      child: const Text("Ambil"),
                    ),
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}
