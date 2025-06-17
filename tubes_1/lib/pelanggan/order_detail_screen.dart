import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'add_review_screen.dart';
import '../models/order.dart' as model;

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  void _updateDriverMarker(GeoPoint driverLocation) {
    if (!mounted) return;
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'driver');
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(driverLocation.latitude, driverLocation.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Posisi Driver'),
        ),
      );
    });
    // Animate camera to follow the driver
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(driverLocation.latitude, driverLocation.longitude),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Pesanan #${widget.orderId.substring(0, 6)}'),
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
          if (!snapshot.data!.exists)
            return const Center(child: Text("Pesanan tidak ditemukan."));

          final order = model.Order.fromFirestore(snapshot.data!);
          final orderData = snapshot.data!.data() as Map<String, dynamic>;

          final bool showMap = order.status == 'Diantar';
          final GeoPoint? driverLocation =
              orderData['driverCurrentLocation'] as GeoPoint?;

          if (showMap && driverLocation != null) {
            _updateDriverMarker(driverLocation);
          }

          return ListView(
            children: [
              if (showMap)
                SizedBox(
                  height: 300,
                  child: GoogleMap(
                    onMapCreated: (controller) => _mapController = controller,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(
                        driverLocation?.latitude ?? -6.9175,
                        driverLocation?.longitude ?? 107.6191,
                      ),
                      zoom: 15,
                    ),
                    markers: _markers,
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Status: ${order.status}",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Divider(height: 30),
                    // ... (Sisa detail order seperti item, total, dll.)
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
