import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ManageMenuScreen extends StatefulWidget {
  const ManageMenuScreen({Key? key}) : super(key: key);

  @override
  _ManageMenuScreenState createState() => _ManageMenuScreenState();
}

class _ManageMenuScreenState extends State<ManageMenuScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _showAddMenuDialog({DocumentSnapshot? menuDoc}) async {
    final _formKey = GlobalKey<FormState>();
    File? _imageFile;
    String? _imageUrl = menuDoc?['imageUrl'];
    final nameController = TextEditingController(text: menuDoc?['name']);
    final priceController = TextEditingController(
      text: menuDoc?['price']?.toString(),
    );
    final descriptionController = TextEditingController(
      text: menuDoc?['description'],
    );
    bool _isUploading = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(menuDoc == null ? 'Tambah Menu Baru' : 'Edit Menu'),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      GestureDetector(
                        onTap: () async {
                          final pickedFile = await _picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                          );
                          if (pickedFile != null) {
                            setDialogState(() {
                              _imageFile = File(pickedFile.path);
                              _imageUrl = null;
                            });
                          }
                        },
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey),
                            image:
                                _imageFile != null
                                    ? DecorationImage(
                                      image: FileImage(_imageFile!),
                                      fit: BoxFit.cover,
                                    )
                                    : (_imageUrl != null
                                        ? DecorationImage(
                                          image: NetworkImage(_imageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                        : null),
                          ),
                          child:
                              _imageFile == null && _imageUrl == null
                                  ? const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo,
                                        color: Colors.grey,
                                      ),
                                      Text('Pilih Gambar'),
                                    ],
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
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Wajib diisi';
                          if (v.length < 3) return 'Minimal 3 karakter';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Harga'),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Wajib diisi';
                          if (int.tryParse(v) == null) return 'Harus angka';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Batal'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child:
                      _isUploading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text('Simpan'),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      setDialogState(() => _isUploading = true);

                      try {
                        String? finalImageUrl = _imageUrl;

                        if (_imageFile != null) {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;

                          final ref = FirebaseStorage.instance.ref().child(
                            'menu_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}.jpg',
                          );
                          await ref.putFile(_imageFile!);
                          finalImageUrl = await ref.getDownloadURL();
                        }

                        if (finalImageUrl == null && menuDoc == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Gambar wajib diisi!'),
                            ),
                          );
                          setDialogState(() => _isUploading = false);
                          return;
                        }

                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          final restaurantDoc =
                              await FirebaseFirestore.instance
                                  .collection('restaurants')
                                  .doc(user.uid)
                                  .get();

                          String restaurantName = 'Unknown Restaurant';
                          if (restaurantDoc.exists) {
                            restaurantName =
                                restaurantDoc.data()?['name'] ??
                                'Unknown Restaurant';
                          }

                          final data = {
                            'name': nameController.text,
                            'price': int.tryParse(priceController.text) ?? 0,
                            'description': descriptionController.text,
                            'imageUrl': finalImageUrl,
                            'restaurantId': user.uid,
                            'restaurantName': restaurantName,
                            'available': true,
                            'soldCount': menuDoc?['soldCount'] ?? 0,
                            'createdAt': FieldValue.serverTimestamp(),
                            'updatedAt': FieldValue.serverTimestamp(),
                          };

                          if (menuDoc == null) {
                            await FirebaseFirestore.instance
                                .collection('menus')
                                .add(data);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Menu berhasil ditambahkan!'),
                                ),
                              );
                            }
                          } else {
                            data['updatedAt'] = FieldValue.serverTimestamp();
                            await menuDoc.reference.update(data);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Menu berhasil diperbarui!'),
                                ),
                              );
                            }
                          }

                          if (mounted) Navigator.of(context).pop();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      } finally {
                        if (mounted) setDialogState(() => _isUploading = false);
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggleMenuAvailability(DocumentSnapshot menuDoc) async {
    try {
      final currentAvailability = menuDoc['available'] ?? true;
      await menuDoc.reference.update({
        'available': !currentAvailability,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              currentAvailability ? 'Menu dinonaktifkan' : 'Menu diaktifkan',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _confirmDeleteMenu(DocumentSnapshot menuDoc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Menu'),
            content: Text(
              'Apakah Anda yakin ingin menghapus "${menuDoc['name']}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        // Delete image from storage first if exists
        if (menuDoc['imageUrl'] != null) {
          try {
            final ref = FirebaseStorage.instance.refFromURL(
              menuDoc['imageUrl'],
            );
            await ref.delete();
          } catch (e) {
            print('Error deleting image: $e');
          }
        }

        await menuDoc.reference.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu berhasil dihapus!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Menu'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body:
          user == null
              ? const Center(child: Text('Silakan login untuk mengelola menu.'))
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('menus')
                        .where('restaurantId', isEqualTo: user.uid)
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, color: Colors.red, size: 50),
                          const SizedBox(height: 16),
                          const Text('Terjadi kesalahan saat memuat menu.'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.restaurant_menu,
                            size: 50,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text('Belum ada menu. Silakan tambahkan.'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _showAddMenuDialog(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Tambah Menu'),
                          ),
                        ],
                      ),
                    );
                  }

                  final menuItems = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: menuItems.length,
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      final isAvailable = item['available'] ?? true;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl:
                                  item['imageUrl'] ??
                                  'https://placehold.co/100',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder:
                                  (context, url) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.fastfood),
                                  ),
                              errorWidget:
                                  (context, url, error) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.fastfood),
                                  ),
                            ),
                          ),
                          title: Text(
                            item['name'] ?? 'Tanpa Nama',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isAvailable ? Colors.black : Colors.grey,
                              decoration:
                                  isAvailable
                                      ? TextDecoration.none
                                      : TextDecoration.lineThrough,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rp ${item['price'] ?? 0}'),
                              Text(
                                isAvailable ? 'Tersedia' : 'Tidak Tersedia',
                                style: TextStyle(
                                  color:
                                      isAvailable ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Terjual: ${item['soldCount'] ?? 0}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder:
                                (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: const Row(
                                      children: [
                                        Icon(Icons.edit, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: Row(
                                      children: [
                                        Icon(
                                          isAvailable
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: Colors.orange,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isAvailable
                                              ? 'Nonaktifkan'
                                              : 'Aktifkan',
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: const Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Hapus'),
                                      ],
                                    ),
                                  ),
                                ],
                            onSelected: (value) {
                              switch (value) {
                                case 'edit':
                                  _showAddMenuDialog(menuDoc: item);
                                  break;
                                case 'toggle':
                                  _toggleMenuAvailability(item);
                                  break;
                                case 'delete':
                                  _confirmDeleteMenu(item);
                                  break;
                              }
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenuDialog(),
        tooltip: 'Tambah Menu',
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}
