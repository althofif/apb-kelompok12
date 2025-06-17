// (Kode yang sama persis dengan jawaban saya sebelumnya, yang sudah benar)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cloudinary_service.dart';
import '../services/image_helper.dart';

class SellerAddMenuScreen extends StatefulWidget {
  const SellerAddMenuScreen({Key? key}) : super(key: key);

  @override
  _SellerAddMenuScreenState createState() => _SellerAddMenuScreenState();
}

class _SellerAddMenuScreenState extends State<SellerAddMenuScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  File? _imageFile;
  String? _category;
  bool _isLoading = false;
  bool _isAvailable = true;

  final CloudinaryService _cloudinaryService = CloudinaryService();
  final List<String> _categories = ['Makanan', 'Minuman', 'Cemilan', 'Lainnya'];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImageHelper.showImageSourceDialog(context);
      if (file != null) setState(() => _imageFile = file);
    } catch (e) {
      if (mounted) _showSnackBar('Gagal memilih gambar: $e', Colors.red);
    }
  }

  List<String> _generateKeywords(String text) {
    if (text.isEmpty) return [];
    final String lowercasedText = text.toLowerCase();
    final List<String> keywords = [];
    final List<String> words =
        lowercasedText.split(' ').where((s) => s.isNotEmpty).toList();

    for (final word in words) {
      for (int i = 0; i < word.length; i++) {
        keywords.add(word.substring(0, i + 1));
      }
    }
    if (!keywords.contains(lowercasedText)) {
      keywords.add(lowercasedText);
    }
    return keywords;
  }

  Future<void> _addMenuItem() async {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null || _imageFile == null) {
      _showSnackBar('Harap lengkapi foto dan kategori menu.', Colors.orange);
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Anda harus login untuk menambahkan menu.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final restaurantId = user.uid;
      final menuDocRef = FirebaseFirestore.instance.collection('menus').doc();
      final menuName = _nameController.text.trim();

      final restaurantDoc =
          await FirebaseFirestore.instance
              .collection('restaurants')
              .doc(restaurantId)
              .get();
      final restaurantName =
          restaurantDoc.data()?['name'] ?? 'Restoran Tanpa Nama';

      final imageUrl = await _cloudinaryService.uploadImageSimple(
        imageFile: _imageFile!,
        folder: 'menus/$restaurantId',
      );
      if (imageUrl == null) throw Exception('Gagal mengunggah gambar');

      final Map<String, dynamic> menuData = {
        'id': menuDocRef.id,
        'restaurantId': restaurantId,
        'name': menuName,
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'imageUrl': imageUrl,
        'category': _category!,
        'available': _isAvailable,
        'popularity': 0,
        'restaurantName': restaurantName,
        'keywords': _generateKeywords(menuName),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await menuDocRef.set(menuData);

      if (mounted) {
        _showSnackBar('Menu berhasil ditambahkan!', Colors.green);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Gagal menambahkan menu: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Menu Baru'),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _addMenuItem,
              tooltip: 'Simpan Menu',
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Menyimpan menu...'),
                  ],
                ),
              )
              : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildImageUploadSection(),
                      const SizedBox(height: 24),
                      _buildMenuDetailsSection(),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _addMenuItem,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('SIMPAN MENU'),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildImageUploadSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Foto Menu *',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _pickImage,
        child: Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child:
              _imageFile != null
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_imageFile!, fit: BoxFit.cover),
                  )
                  : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Ketuk untuk memilih foto'),
                      ],
                    ),
                  ),
        ),
      ),
    ],
  );

  Widget _buildMenuDetailsSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Detail Menu',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _nameController,
        decoration: const InputDecoration(
          labelText: 'Nama Menu *',
          border: OutlineInputBorder(),
        ),
        validator:
            (v) => (v == null || v.isEmpty) ? 'Nama menu wajib diisi' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _priceController,
        decoration: const InputDecoration(
          labelText: 'Harga *',
          border: OutlineInputBorder(),
          prefixText: 'Rp ',
        ),
        keyboardType: TextInputType.number,
        validator: (v) {
          if (v == null || v.isEmpty) return 'Harga wajib diisi';
          if (double.tryParse(v) == null) return 'Harga tidak valid';
          return null;
        },
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _category,
        decoration: const InputDecoration(
          labelText: 'Kategori *',
          border: OutlineInputBorder(),
        ),
        items:
            _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
        onChanged: (val) => setState(() => _category = val),
        validator: (v) => v == null ? 'Kategori wajib dipilih' : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _descriptionController,
        decoration: const InputDecoration(
          labelText: 'Deskripsi',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      const SizedBox(height: 16),
      SwitchListTile(
        title: const Text('Status Tersedia'),
        value: _isAvailable,
        onChanged: (val) => setState(() => _isAvailable = val),
        secondary: Icon(
          _isAvailable ? Icons.check_circle : Icons.cancel,
          color: _isAvailable ? Colors.green : Colors.red,
        ),
      ),
    ],
  );
}
