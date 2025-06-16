import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class DriverMapScreen extends StatefulWidget {
  const DriverMapScreen({Key? key}) : super(key: key);

  @override
  _DriverMapScreenState createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  GoogleMapController? mapController;
  Location location = Location();
  LatLng? _currentPosition;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Check if location service is enabled
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() {
            _error = 'Layanan lokasi tidak aktif';
            _isLoading = false;
          });
          return;
        }
      }

      // Check location permission
      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() {
            _error = 'Izin lokasi tidak diberikan';
            _isLoading = false;
          });
          return;
        }
      }

      // Get current location with timeout
      final locData = await location.getLocation().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout getting location');
        },
      );

      if (locData.latitude != null && locData.longitude != null) {
        setState(() {
          _currentPosition = LatLng(locData.latitude!, locData.longitude!);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Tidak dapat mendapatkan koordinat lokasi';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Gagal mendapatkan lokasi: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    if (mounted) {
      setState(() {
        mapController = controller;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light background
      appBar: AppBar(
        title: const Text('Peta'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _getLocation),
        ],
      ),
      body:
          _isLoading
              ? Container(
                color: Colors.white,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        'Mendapatkan lokasi...',
                        style: TextStyle(color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              )
              : _error != null
              ? Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _getLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        child: const Text(
                          'Coba Lagi',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : _currentPosition == null
              ? Container(
                color: Colors.white,
                child: const Center(
                  child: Text(
                    'Lokasi tidak tersedia',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              )
              : GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _currentPosition!,
                  zoom: 15.0,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                mapToolbarEnabled: true,
                compassEnabled: true,
                trafficEnabled: false,
                buildingsEnabled: true,
                mapType: MapType.normal,
                onCameraMove: (CameraPosition position) {
                  // Handle camera movement if needed
                },
              ),
    );
  }
}
