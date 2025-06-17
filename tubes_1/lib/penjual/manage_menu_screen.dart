import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/menu_item.dart' as model;
import '../services/image_helper.dart';
import '../services/cloudinary_service.dart';

class ManageMenuScreen extends StatefulWidget {
  const ManageMenuScreen({Key? key}) : super(key: key);

  @override
  _ManageMenuScreenState createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends State<ManageMenuScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  // --- FUNGSI GENERATE KEYWORDS DITAMBAHKAN DI SINI ---
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

  Future<void> _showAddEditMenuDialog({model.MenuItem? menuItem}) async {
    final formKey = GlobalKey<FormState>();
    File? imageFile;
    String? imageUrl = menuItem?.imageUrl;

    final nameController = TextEditingController(text: menuItem?.name ?? '');
    final priceController = TextEditingController(
      text: menuItem?.price.toStringAsFixed(0) ?? '',
    );
    final descriptionController = TextEditingController(
      text: menuItem?.description ?? '',
    );
    final categoryController = TextEditingController(
      text: menuItem?.category ?? '',
    );
    bool isUploading = false;

    final cloudinaryService = CloudinaryService();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(menuItem == null ? 'Tambah Menu' : 'Edit Menu'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      GestureDetector(
                        onTap:
                            isUploading
                                ? null
                                : () async {
                                  final pickedFile =
                                      await ImageHelper.pickImageFromGallery();
                                  if (pickedFile != null) {
                                    setDialogState(() {
                                      imageFile = pickedFile;
                                      imageUrl = null;
                                    });
                                  }
                                },
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildImageWidget(imageFile, imageUrl),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Menu',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (v) =>
                                (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'Harga',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator:
                            (v) =>
                                (v == null ||
                                        v.isEmpty ||
                                        double.tryParse(v) == null)
                                    ? 'Harga tidak valid'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          hintText: 'e.g. Makanan, Minuman',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (v) =>
                                (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed:
                      isUploading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  // --- LOGIKA PENYIMPANAN DIROMBAK TOTAL ---
                  onPressed:
                      isUploading
                          ? null
                          : () async {
                            if (!formKey.currentState!.validate()) return;
                            if (imageFile == null &&
                                (imageUrl == null || imageUrl!.isEmpty)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Gambar wajib dipilih'),
                                ),
                              );
                              return;
                            }

                            setDialogState(() => isUploading = true);

                            try {
                              final menuName = nameController.text.trim();
                              String? finalImageUrl = imageUrl;

                              // 1. Upload gambar jika ada file baru
                              if (imageFile != null) {
                                final newImageUrl = await cloudinaryService
                                    .uploadImageSimple(
                                      imageFile: imageFile!,
                                      folder: 'menus/${_currentUser!.uid}',
                                    );
                                if (newImageUrl == null)
                                  throw Exception('Gagal mengupload gambar');
                                finalImageUrl = newImageUrl;
                              }

                              // 2. Ambil nama restoran
                              final restaurantDoc =
                                  await FirebaseFirestore.instance
                                      .collection('restaurants')
                                      .doc(_currentUser!.uid)
                                      .get();
                              final restaurantName =
                                  restaurantDoc.data()?['name'] ??
                                  'Restoran Tanpa Nama';

                              // 3. Siapkan data untuk disimpan
                              final dataToSave = {
                                'name': menuName,
                                'description':
                                    descriptionController.text.trim(),
                                'price': double.parse(priceController.text),
                                'imageUrl': finalImageUrl!,
                                'category': categoryController.text.trim(),
                                'restaurantId': _currentUser!.uid,
                                'restaurantName': restaurantName,
                                'keywords': _generateKeywords(menuName),
                                'available': menuItem?.available ?? true,
                                'popularity': menuItem?.popularity ?? 0,
                                'updatedAt': FieldValue.serverTimestamp(),
                              };

                              if (menuItem == null) {
                                // Tambah Menu Baru
                                dataToSave['createdAt'] =
                                    FieldValue.serverTimestamp();
                                await FirebaseFirestore.instance
                                    .collection('menus')
                                    .add(dataToSave);
                              } else {
                                // Update Menu yang Ada
                                await FirebaseFirestore.instance
                                    .collection('menus')
                                    .doc(menuItem.id)
                                    .update(dataToSave);
                              }

                              if (mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      menuItem == null
                                          ? 'Menu berhasil ditambahkan!'
                                          : 'Menu berhasil diupdate!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                            } finally {
                              if (mounted)
                                setDialogState(() => isUploading = false);
                            }
                          },
                  child:
                      isUploading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Text(menuItem == null ? 'Tambah' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Sisa kode di bawah ini tidak perlu diubah
  Widget _buildImageWidget(File? imageFile, String? imageUrl) {
    if (imageFile != null) {
      return Image.file(
        imageFile,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => const Center(child: Text('Error')),
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (c, u) => const Center(child: CircularProgressIndicator()),
        errorWidget: (c, u, e) => const Center(child: Text('Error')),
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, color: Colors.grey, size: 40),
            SizedBox(height: 8),
            Text('Pilih Gambar', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Silakan login terlebih dahulu.')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Menu Anda'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('menus')
                .where('restaurantId', isEqualTo: _currentUser!.uid)
                .orderBy('name')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Belum ada menu',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tekan tombol + untuk menambah menu',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final menuItem = model.MenuItem.fromFirestore(
                snapshot.data!.docs[index],
              );
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: menuItem.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder:
                          (c, u) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      errorWidget:
                          (c, u, e) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                            child: const Icon(Icons.error, color: Colors.red),
                          ),
                    ),
                  ),
                  title: Text(
                    menuItem.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rp ${menuItem.price.toStringAsFixed(0)}'),
                      Text(
                        menuItem.category,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Switch(
                    value: menuItem.available,
                    onChanged:
                        (value) async => await FirebaseFirestore.instance
                            .collection('menus')
                            .doc(menuItem.id)
                            .update({'available': value}),
                  ),
                  onTap: () => _showAddEditMenuDialog(menuItem: menuItem),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditMenuDialog(),
        tooltip: 'Tambah Menu',
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
