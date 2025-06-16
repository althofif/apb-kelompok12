import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/menu_item.dart' as model;
import '../services/image_helper.dart';
import '../services/storage_service.dart';

class ManageMenuScreen extends StatefulWidget {
  const ManageMenuScreen({Key? key}) : super(key: key);

  @override
  _ManageMenuScreenState createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends State<ManageMenuScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _showAddEditMenuDialog({model.MenuItem? menuItem}) async {
    final formKey = GlobalKey<FormState>();
    File? imageFile;
    String? imageUrl = menuItem?.imageUrl;

    final nameController = TextEditingController(text: menuItem?.name);
    final priceController = TextEditingController(
      text: menuItem?.price.toStringAsFixed(0),
    );
    final descriptionController = TextEditingController(
      text: menuItem?.description,
    );
    final categoryController = TextEditingController(text: menuItem?.category);
    bool isUploading = false;

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
                      // Image Picker
                      GestureDetector(
                        onTap: () async {
                          final file = await ImageHelper.pickImageFromGallery();
                          if (file != null) {
                            setDialogState(() {
                              imageFile = file;
                              imageUrl =
                                  null; // Clear existing image url if new one is picked
                            });
                          }
                        },
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                            image:
                                imageFile != null
                                    ? DecorationImage(
                                      image: FileImage(imageFile!),
                                      fit: BoxFit.cover,
                                    )
                                    : (imageUrl != null
                                        ? DecorationImage(
                                          image: NetworkImage(imageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                        : null),
                          ),
                          child:
                              (imageFile == null && imageUrl == null)
                                  ? const Center(
                                    child: Icon(
                                      Icons.add_a_photo,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  )
                                  : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Menu',
                        ),
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'Harga',
                          prefixText: 'Rp ',
                        ),
                        keyboardType: TextInputType.number,
                        validator:
                            (v) =>
                                (v!.isEmpty || double.tryParse(v) == null)
                                    ? 'Harga tidak valid'
                                    : null,
                      ),
                      TextFormField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Kategori (e.g. Makanan, Minuman)',
                        ),
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed:
                      isUploading
                          ? null
                          : () async {
                            if (formKey.currentState!.validate()) {
                              if (imageFile == null && imageUrl == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Gambar wajib dipilih'),
                                  ),
                                );
                                return;
                              }

                              setDialogState(() => isUploading = true);
                              try {
                                String? finalImageUrl = imageUrl;
                                if (imageFile != null) {
                                  final newMenuId =
                                      menuItem?.id ??
                                      FirebaseFirestore.instance
                                          .collection('menus')
                                          .doc()
                                          .id;
                                  finalImageUrl =
                                      await FirebaseStorageService.uploadMenuImage(
                                        restaurantId: _currentUser!.uid,
                                        menuId: newMenuId,
                                        imageFile: imageFile!,
                                      );
                                }

                                final newMenuItem = model.MenuItem(
                                  id:
                                      menuItem?.id ??
                                      '', // ID akan di-set oleh Firestore jika baru
                                  restaurantId: _currentUser!.uid,
                                  name: nameController.text,
                                  description: descriptionController.text,
                                  price: double.parse(priceController.text),
                                  imageUrl: finalImageUrl!,
                                  category: categoryController.text,
                                  available: menuItem?.available ?? true,
                                  popularity: menuItem?.popularity ?? 0,
                                );

                                if (menuItem == null) {
                                  // Tambah baru
                                  await FirebaseFirestore.instance
                                      .collection('menus')
                                      .add(newMenuItem.toFirestore());
                                } else {
                                  // Update
                                  await FirebaseFirestore.instance
                                      .collection('menus')
                                      .doc(menuItem.id)
                                      .update(newMenuItem.toFirestore());
                                }

                                if (mounted) Navigator.of(context).pop();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              } finally {
                                setDialogState(() => isUploading = false);
                              }
                            }
                          },
                  child:
                      isUploading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null)
      return const Scaffold(body: Center(child: Text('Silakan login.')));

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Menu Anda')),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('menus')
                .where('restaurantId', isEqualTo: _currentUser.uid)
                .orderBy('name')
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty)
            return const Center(
              child: Text('Belum ada menu. Tekan + untuk menambah.'),
            );

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final menuItem = model.MenuItem.fromFirestore(
                snapshot.data!.docs[index],
              );
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(menuItem.imageUrl),
                  ),
                  title: Text(menuItem.name),
                  subtitle: Text('Rp ${menuItem.price.toStringAsFixed(0)}'),
                  trailing: Switch(
                    value: menuItem.available,
                    onChanged: (value) async {
                      await FirebaseFirestore.instance
                          .collection('menus')
                          .doc(menuItem.id)
                          .update({'available': value});
                    },
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
        child: const Icon(Icons.add),
      ),
    );
  }
}
