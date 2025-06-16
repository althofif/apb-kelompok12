// driver/vehicle_information_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // PERBAIKAN: Import ditambahkan
import '../services/database_service.dart';

class VehicleInformationScreen extends StatefulWidget {
  const VehicleInformationScreen({Key? key}) : super(key: key);

  @override
  _VehicleInformationScreenState createState() =>
      _VehicleInformationScreenState();
}

class _VehicleInformationScreenState extends State<VehicleInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  final _plateController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchVehicleData();
  }

  Future<void> _fetchVehicleData() async {
    if (_currentUser != null) {
      final driverDoc =
          await DatabaseService(uid: _currentUser.uid).getUserData();
      if (mounted && driverDoc.exists) {
        final data = driverDoc.data() as Map<String, dynamic>;
        final vehicleData = data['vehicle'] as Map<String, dynamic>?;
        if (vehicleData != null) {
          setState(() {
            _plateController.text = vehicleData['plate'] ?? '';
            _brandController.text = vehicleData['brand'] ?? '';
            _modelController.text = vehicleData['model'] ?? '';
            _colorController.text = vehicleData['color'] ?? '';
          });
        }
      }
    }
  }

  Future<void> _saveVehicleInfo() async {
    if (_formKey.currentState!.validate() && _currentUser != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final vehicleData = {
          'plate': _plateController.text,
          'brand': _brandController.text,
          'model': _modelController.text,
          'color': _colorController.text,
        };
        // Menggunakan set dengan merge:true untuk membuat atau memperbarui field 'vehicle'
        await DatabaseService(uid: _currentUser.uid).userCollection
            .doc(_currentUser.uid)
            .set({'vehicle': vehicleData}, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Informasi kendaraan diperbarui!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _plateController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informasi Kendaraan'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _plateController,
              decoration: const InputDecoration(
                labelText: 'Nomor Polisi',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Merek Kendaraan (Cth: Honda)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Model Kendaraan (Cth: Vario 125)',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _colorController,
              decoration: const InputDecoration(
                labelText: 'Warna',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 40),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _saveVehicleInfo,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
                child: const Text(
                  'SIMPAN',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
