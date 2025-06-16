import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart'; // PERBAIKAN: Import yang benar
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as model;

class ActiveDeliveryScreen extends StatefulWidget {
  final String orderId;

  const ActiveDeliveryScreen({Key? key, required this.orderId})
    : super(key: key);

  @override
  _ActiveDeliveryScreenState createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  Future<void> _updateOrderStatus(String newStatus) async {
    try {
      final updateData = {
        'status': newStatus,
        if (newStatus == 'Selesai')
          'deliveryTime': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status pesanan diperbarui menjadi: $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
        if (newStatus == 'Selesai') {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addMarkers(model.Order order) {
    // PENTING: Anda harus menyimpan data GeoPoint di dokumen pesanan atau restoran
    // untuk mendapatkan lokasi dinamis. Ini hanyalah contoh dengan data statis.
    final restaurantLocation = const LatLng(
      -6.229728,
      106.689431,
    ); // Contoh: Lokasi Resto
    final customerLocation = const LatLng(
      -6.260820,
      106.657265,
    ); // Contoh: Lokasi Customer

    final restaurantMarker = Marker(
      markerId: const MarkerId('restaurant'),
      position: restaurantLocation,
      infoWindow: InfoWindow(
        title: (order.toFirestore()['restaurantName'] ?? 'Restoran').toString(),
        snippet: 'Ambil pesanan di sini',
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    );

    final customerMarker = Marker(
      markerId: const MarkerId('customer'),
      position: customerLocation,
      infoWindow: const InfoWindow(title: 'Alamat Pelanggan'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
    );

    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.add(restaurantMarker);
        _markers.add(customerMarker);
      });
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        _createBounds([restaurantLocation, customerLocation]),
        100.0, // Padding
      ),
    );
  }

  LatLngBounds _createBounds(List<LatLng> positions) {
    final southwestLat = positions
        .map((p) => p.latitude)
        .reduce((a, b) => a < b ? a : b);
    final southwestLon = positions
        .map((p) => p.longitude)
        .reduce((a, b) => a < b ? a : b);
    final northeastLat = positions
        .map((p) => p.latitude)
        .reduce((a, b) => a > b ? a : b);
    final northeastLon = positions
        .map((p) => p.longitude)
        .reduce((a, b) => a > b ? a : b);
    return LatLngBounds(
      southwest: LatLng(southwestLat, southwestLon),
      northeast: LatLng(northeastLat, northeastLon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pengantaran #${widget.orderId.substring(0, 6)}'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('orders')
                .doc(widget.orderId)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final order = model.Order.fromFirestore(snapshot.data!);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _addMarkers(order);
          });

          return Stack(
            children: [
              GoogleMap(
                onMapCreated: (controller) => _mapController = controller,
                initialCameraPosition: const CameraPosition(
                  target: LatLng(-6.24, 106.67),
                  zoom: 12,
                ),
                markers: _markers,
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildDeliveryCard(order),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeliveryCard(model.Order order) {
    final bool isDelivering = order.status == 'Diantar';
    final String customerName =
        (order.toFirestore()['customerName'] ?? 'Pelanggan').toString();
    final String restaurantName =
        (order.toFirestore()['restaurantName'] ?? 'Restoran').toString();

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isDelivering
                  ? 'Mengantar ke $customerName'
                  : 'Menuju $restaurantName',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  () =>
                      _updateOrderStatus(isDelivering ? 'Selesai' : 'Diantar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                isDelivering
                    ? 'SELESAIKAN PENGANTARAN'
                    : 'SAYA SUDAH AMBIL PESANAN',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
