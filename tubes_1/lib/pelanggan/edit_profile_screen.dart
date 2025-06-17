import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/image_helper.dart';
import '../services/cloudinary_service.dart'; // UBAH: Import CloudinaryService

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  final _auth = FirebaseAuth.instance;
  // TAMBAHAN: Inisialisasi CloudinaryService
  final CloudinaryService _cloudinaryService = CloudinaryService();

  File? _imageFile;
  String? _profileImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (mounted && doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _nameController.text = data['username'] ?? user.displayName ?? '';
        _phoneController.text = data['phone'] ?? '';
        if (mounted) {
          setState(() {
            _profileImageUrl = data['profileImageUrl'] ?? user.photoURL;
          });
        }
      } else {
        // Fallback ke data dari Auth jika dokumen Firestore tidak ada
        _nameController.text = user.displayName ?? '';
        if (mounted) {
          setState(() {
            _profileImageUrl = user.photoURL;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    // Fungsi ini sudah benar menggunakan ImageHelper
    try {
      final file = await ImageHelper.showImageSourceDialog(context);
      if (file != null) {
        final error = ImageHelper.validateImage(file, maxSizeInMB: 2);
        if (error != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: Colors.red),
            );
          }
          return;
        }
        setState(() {
          _imageFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // UBAH: Logika utama untuk update profil
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User tidak login.");

      String? newImageUrl = _profileImageUrl;

      // Upload gambar baru ke Cloudinary jika ada perubahan
      if (_imageFile != null) {
        newImageUrl = await _cloudinaryService.uploadImageSimple(
          imageFile: _imageFile!,
          folder: 'user_profiles', // Simpan di folder 'user_profiles'
        );

        if (newImageUrl == null) {
          throw Exception("Gagal mengunggah gambar ke Cloudinary.");
        }
      }

      // Update Firebase Auth profile
      await user.updateDisplayName(_nameController.text);
      if (newImageUrl != null && newImageUrl.isNotEmpty) {
        await user.updatePhotoURL(newImageUrl);
      }

      // Update Firestore dengan data baru
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'username': _nameController.text, // Gunakan 'username' agar konsisten
        'phone': _phoneController.text,
        'profileImageUrl': newImageUrl,
        'uid': user.uid,
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    // Tampilan UI tidak ada perubahan signifikan, hanya memanggil fungsi yang sudah diubah
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil'), elevation: 1),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: Colors.grey[200],
                              backgroundImage:
                                  _imageFile != null
                                      ? FileImage(_imageFile!)
                                      : (_profileImageUrl != null &&
                                          _profileImageUrl!.isNotEmpty)
                                      ? CachedNetworkImageProvider(
                                            _profileImageUrl!,
                                          )
                                          as ImageProvider
                                      : null,
                              child:
                                  _imageFile == null &&
                                          (_profileImageUrl == null ||
                                              _profileImageUrl!.isEmpty)
                                      ? Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey[400],
                                      )
                                      : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Ketuk untuk mengubah foto profil',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Nama tidak boleh kosong'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Telepon',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        validator:
                            (v) =>
                                v == null || v.isEmpty
                                    ? 'Nomor telepon tidak boleh kosong'
                                    : null,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateProfile,
                          child: const Text(
                            'Simpan Perubahan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
