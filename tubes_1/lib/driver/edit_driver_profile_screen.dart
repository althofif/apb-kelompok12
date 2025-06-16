import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/image_helper.dart';
import '../services/storage_service.dart';

class EditDriverProfileScreen extends StatefulWidget {
  const EditDriverProfileScreen({Key? key}) : super(key: key);

  @override
  _EditDriverProfileScreenState createState() =>
      _EditDriverProfileScreenState();
}

class _EditDriverProfileScreenState extends State<EditDriverProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  final User? _currentUser = FirebaseAuth.instance.currentUser;
  File? _imageFile;
  String? _currentImageUrl;
  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (_currentUser == null) {
      setState(() => _isFetching = false);
      return;
    }
    // Load from Firestore first
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .get();
    if (mounted) {
      setState(() {
        _nameController.text =
            doc.data()?['name'] ?? _currentUser!.displayName ?? '';
        _phoneController.text = doc.data()?['phone'] ?? '';
        _currentImageUrl =
            doc.data()?['profileImageUrl'] ?? _currentUser!.photoURL;
        _isFetching = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final file = await ImageHelper.pickImageFromGallery();
    if (file != null) {
      setState(() => _imageFile = file);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      String? finalImageUrl = _currentImageUrl;
      if (_imageFile != null) {
        finalImageUrl = await FirebaseStorageService.uploadDriverProfile(
          driverId: _currentUser!.uid,
          imageFile: _imageFile!,
        );
      }

      // Update Auth
      await _currentUser!.updateDisplayName(_nameController.text);
      if (finalImageUrl != null) {
        await _currentUser!.updatePhotoURL(finalImageUrl);
      }

      // Update Firestore in 'users' and 'drivers' collections for consistency
      final userData = {
        'name': _nameController.text,
        'phone': _phoneController.text,
        'profileImageUrl': finalImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      WriteBatch batch = FirebaseFirestore.instance.batch();
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid);
      final driverRef = FirebaseFirestore.instance
          .collection('drivers')
          .doc(_currentUser!.uid);
      batch.set(userRef, userData, SetOptions(merge: true));
      batch.set(driverRef, userData, SetOptions(merge: true));
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to signal success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil Driver')),
      body:
          _isFetching
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Center(
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage:
                              _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : (_currentImageUrl != null
                                          ? NetworkImage(_currentImageUrl!)
                                          : null)
                                      as ImageProvider?,
                          child:
                              _imageFile == null && _currentImageUrl == null
                                  ? const Icon(Icons.camera_alt, size: 40)
                                  : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator:
                          (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Telepon',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator:
                          (v) =>
                              v!.isEmpty
                                  ? 'Nomor telepon tidak boleh kosong'
                                  : null,
                    ),
                    const SizedBox(height: 32),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                          onPressed: _saveProfile,
                          child: const Text('SIMPAN PERUBAHAN'),
                        ),
                  ],
                ),
              ),
    );
  }
}
