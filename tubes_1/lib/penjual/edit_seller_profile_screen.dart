import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/image_helper.dart';
import '../services/storage_service.dart';
import '../models/restaurant_model.dart';

class EditSellerProfileScreen extends StatefulWidget {
  const EditSellerProfileScreen({Key? key}) : super(key: key);

  @override
  _EditSellerProfileScreenState createState() =>
      _EditSellerProfileScreenState();
}

class _EditSellerProfileScreenState extends State<EditSellerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isOpen = true;
  String? _currentImageUrl;

  File? _imageFile;
  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _fetchRestaurantData();
  }

  Future<void> _fetchRestaurantData() async {
    if (_currentUser == null) {
      setState(() => _isFetching = false);
      return;
    }
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('restaurants')
              .doc(_currentUser!.uid)
              .get();
      if (mounted && doc.exists) {
        final restaurant = RestaurantModel.fromFirestore(doc);
        _nameController.text = restaurant.name;
        _addressController.text = restaurant.address;
        _descriptionController.text = restaurant.description;
        _isOpen = restaurant.isOpen;
        _currentImageUrl = restaurant.imageUrl;
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isFetching = false);
    }
  }

  Future<void> _pickImage() async {
    final file = await ImageHelper.pickImageFromGallery();
    if (file != null) {
      setState(() => _imageFile = file);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      String? finalImageUrl = _currentImageUrl;
      if (_imageFile != null) {
        // Menggunakan FirebaseStorageService yang konsisten
        finalImageUrl = await FirebaseStorageService.uploadRestaurantImage(
          restaurantId: _currentUser!.uid,
          imageFile: _imageFile!,
          imageType: 'banner',
        );
      }

      final restaurantData = {
        'name': _nameController.text,
        'address': _addressController.text,
        'description': _descriptionController.text,
        'isOpen': _isOpen,
        'imageUrl': finalImageUrl,
        'ownerId': _currentUser!.uid,
      };

      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(_currentUser!.uid)
          .set(restaurantData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil restoran berhasil diperbarui!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memperbarui profil: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil Restoran')),
      body:
          _isFetching
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                          image:
                              _imageFile != null
                                  ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover,
                                  )
                                  : (_currentImageUrl != null
                                      ? DecorationImage(
                                        image: NetworkImage(_currentImageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                      : null),
                        ),
                        alignment: Alignment.center,
                        child:
                            (_imageFile == null && _currentImageUrl == null)
                                ? const Icon(
                                  Icons.camera_alt,
                                  size: 50,
                                  color: Colors.grey,
                                )
                                : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Restoran',
                      ),
                      validator:
                          (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Restoran',
                      ),
                      validator:
                          (v) =>
                              v!.isEmpty ? 'Alamat tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Singkat',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Status Buka'),
                      value: _isOpen,
                      onChanged: (value) => setState(() => _isOpen = value),
                      secondary: const Icon(Icons.storefront),
                    ),

                    const SizedBox(height: 30),

                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                          onPressed: _saveChanges,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('SIMPAN PERUBAHAN'),
                        ),
                  ],
                ),
              ),
    );
  }
}
