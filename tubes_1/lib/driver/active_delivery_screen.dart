import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:location/location.dart';
import '../models/order.dart' as model;

class ActiveDeliveryScreen extends StatefulWidget {
  final String orderId;
  const ActiveDeliveryScreen({Key? key, required this.orderId})
    : super(key: key);

  @override
  _ActiveDeliveryScreenState createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  PolylinePoints polylinePoints = PolylinePoints();

  Location location = Location();
  StreamSubscription<LocationData>? _locationSubscription;

  // PENTING: GANTI DENGAN GOOGLE MAPS API KEY ANDA YANG VALID
  final String _googleApiKey = "GANTI_DENGAN_API_KEY_ANDA";

  @override
  void initState() {
    super.initState();
    _startLiveLocationUpdates();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _startLiveLocationUpdates() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    _locationSubscription = location.onLocationChanged.listen((
      LocationData currentLocation,
    ) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .update({
              'driverCurrentLocation': GeoPoint(
                currentLocation.latitude!,
                currentLocation.longitude!,
              ),
            });
      }
    });
  }

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

  Future<void> _updateMapWithOrderData(model.Order order) async {
    final restaurantDoc =
        await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(order.restaurantId)
            .get();
    final restaurantData = restaurantDoc.data();

    final orderSnapshotData =
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(order.id)
            .get();
    final orderData = orderSnapshotData.data();

    if (restaurantData == null ||
        restaurantData['location'] is! GeoPoint ||
        orderData == null ||
        orderData['deliveryLocation'] is! GeoPoint) {
      print("Lokasi restoran atau pelanggan tidak valid atau tidak ditemukan.");
      return;
    }

    final GeoPoint restaurantGeoPoint = restaurantData['location'];
    final GeoPoint customerGeoPoint = orderData['deliveryLocation'];

    final LatLng restaurantLocation = LatLng(
      restaurantGeoPoint.latitude,
      restaurantGeoPoint.longitude,
    );
    final LatLng customerLocation = LatLng(
      customerGeoPoint.latitude,
      customerGeoPoint.longitude,
    );

    _addMarkers(
      restaurantLocation,
      customerLocation,
      restaurantData['name'] ?? 'Restoran',
    );
    _drawPolylines(restaurantLocation, customerLocation);
  }

  void _addMarkers(
    LatLng restaurantLocation,
    LatLng customerLocation,
    String restaurantName,
  ) {
    if (!mounted) return;
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('restaurant'),
          position: restaurantLocation,
          infoWindow: InfoWindow(
            title: restaurantName,
            snippet: 'Ambil pesanan di sini',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
      _markers.add(
        Marker(
          markerId: const MarkerId('customer'),
          position: customerLocation,
          infoWindow: const InfoWindow(title: 'Alamat Pelanggan'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    });
  }

  Future<void> _drawPolylines(LatLng start, LatLng end) async {
    if (_googleApiKey == "GANTI_DENGAN_API_KEY_ANDA") {
      print("API Key belum diganti.");
      return;
    }
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
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = model.Order.fromFirestore(snapshot.data!);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateMapWithOrderData(order);
          });

          return Stack(
            children: [
              GoogleMap(
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_markers.isNotEmpty) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngBounds(
                        _createBounds(_markers.map((m) => m.position).toList()),
                        100.0,
                      ),
                    );
                  }
                },
                initialCameraPosition: const CameraPosition(
                  target: LatLng(-6.9175, 107.6191),
                  zoom: 12,
                ),
                markers: _markers,
                polylines: _polylines,
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildDeliveryCard(
                  order,
                  snapshot.data!.data() as Map<String, dynamic>,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDeliveryCard(model.Order order, Map<String, dynamic> orderData) {
    final bool isDelivering = order.status == 'Diantar';
    final String customerName =
        (orderData['customerName'] ?? 'Pelanggan').toString();
    final String restaurantName =
        (orderData['restaurantName'] ?? 'Restoran').toString();

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  () =>
                      _updateOrderStatus(isDelivering ? 'Selesai' : 'Diantar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isDelivering ? Colors.green : Colors.blue,
                foregroundColor: Colors.white,
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

  LatLngBounds _createBounds(List<LatLng> positions) {
    if (positions.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }
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
}
