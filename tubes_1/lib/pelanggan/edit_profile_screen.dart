import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../services/image_helper.dart';

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
  late final DatabaseService _databaseService;

  File? _imageFile;
  String? _profileImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService(uid: _auth.currentUser?.uid);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Load from Firestore first for more complete data
    final doc = await _databaseService.getUserData();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      _nameController.text = data['name'] ?? user.displayName ?? '';
      _phoneController.text = data['phone'] ?? '';
      if (mounted) {
        setState(() {
          _profileImageUrl = data['profileImageUrl'] ?? user.photoURL;
        });
      }
    } else {
      _nameController.text = user.displayName ?? '';
      if (mounted) {
        setState(() {
          _profileImageUrl = user.photoURL;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final file =
        await ImageHelper.pickImageFromGallery(); // Or use showImageSourceDialog
    if (file != null) {
      final error = ImageHelper.validateImage(file, maxSizeInMB: 2);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        return;
      }
      setState(() {
        _imageFile = file;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User not logged in.");

      String? newImageUrl = _profileImageUrl;

      // 1. Upload new image if selected
      if (_imageFile != null) {
        newImageUrl = await FirebaseStorageService.uploadUserProfile(
          userId: user.uid,
          imageFile: _imageFile!,
        );
        if (newImageUrl == null) throw Exception("Image upload failed.");
      }

      // 2. Update Firebase Auth profile
      await user.updateDisplayName(_nameController.text);
      if (newImageUrl != null) {
        await user.updatePhotoURL(newImageUrl);
      }

      // 3. Update Firestore document
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'profileImageUrl': newImageUrl,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui profil: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
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
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              _imageFile != null
                                  ? FileImage(_imageFile!)
                                  : (_profileImageUrl != null
                                          ? NetworkImage(_profileImageUrl!)
                                          : null)
                                      as ImageProvider?,
                          child:
                              _imageFile == null && _profileImageUrl == null
                                  ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey[400],
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Ketuk untuk mengubah gambar'),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Lengkap',
                        ),
                        validator:
                            (v) =>
                                v!.isEmpty ? 'Nama tidak boleh kosong' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Telepon',
                        ),
                        keyboardType: TextInputType.phone,
                        validator:
                            (v) =>
                                v!.isEmpty
                                    ? 'Nomor telepon tidak boleh kosong'
                                    : null,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updateProfile,
                          child: const Text('Simpan Perubahan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
