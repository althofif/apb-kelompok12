// penjual/edit_seller_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cloudinary_service.dart';

class EditSellerProfileScreen extends StatefulWidget {
  const EditSellerProfileScreen({Key? key}) : super(key: key);

  @override
  _EditSellerProfileScreenState createState() =>
      _EditSellerProfileScreenState();
}

class _EditSellerProfileScreenState extends State<EditSellerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _descriptionController;
  bool _isOpen = true;
  String? _currentImageUrl;

  File? _restaurantImage;
  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _descriptionController = TextEditingController();
    _fetchRestaurantData();
  }

  Future<void> _fetchRestaurantData() async {
    if (_currentUser != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('restaurants')
              .doc(_currentUser.uid)
              .get();
      if (mounted && doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _addressController.text = data['address'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _isOpen = data['isOpen'] ?? true;
          _currentImageUrl = data['imageUrl'];
          _isFetching = false;
        });
      } else {
        setState(() => _isFetching = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() => _restaurantImage = File(pickedFile.path));
    }
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate() && _currentUser != null) {
      setState(() => _isLoading = true);
      try {
        String? finalImageUrl = _currentImageUrl;
        if (_restaurantImage != null) {
          final response = await _cloudinaryService.uploadImage(
            imageFile: _restaurantImage!,
          );
          if (response != null) {
            finalImageUrl = response.secureUrl;
          }
        }

        final restaurantData = {
          'name': _nameController.text,
          'address': _addressController.text,
          'description': _descriptionController.text,
          'isOpen': _isOpen,
          'imageUrl': finalImageUrl,
        };

        await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(_currentUser.uid)
            .set(restaurantData, SetOptions(merge: true));

        if (_currentUser.displayName != _nameController.text) {
          await _currentUser.updateDisplayName(_nameController.text);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil restoran berhasil diperbarui!'),
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal memperbarui profil: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
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
      appBar: AppBar(
        title: const Text('Edit Profil Restoran'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body:
          _isFetching
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    InkWell(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                          image:
                              _restaurantImage != null
                                  ? DecorationImage(
                                    image: FileImage(_restaurantImage!),
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
                            _restaurantImage == null && _currentImageUrl == null
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
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Restoran',
                        border: OutlineInputBorder(),
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
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Status Buka'),
                      value: _isOpen,
                      onChanged: (value) {
                        setState(() => _isOpen = value);
                      },
                      secondary: const Icon(Icons.storefront),
                    ),
                    const SizedBox(height: 30),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('SIMPAN PERUBAHAN'),
                      ),
                  ],
                ),
              ),
    );
  }
}
