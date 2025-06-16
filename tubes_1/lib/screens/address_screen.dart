import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddressScreen extends StatefulWidget {
  final bool isSelectionMode;
  const AddressScreen({Key? key, this.isSelectionMode = false})
    : super(key: key);

  @override
  _AddressScreenState createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot> _getAddressStream() {
    if (_currentUser == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('addresses')
        .snapshots();
  }

  Future<void> _showAddEditAddressDialog({DocumentSnapshot? addressDoc}) async {
    final formKey = GlobalKey<FormState>();
    final labelController = TextEditingController(text: addressDoc?['label']);
    final addressController = TextEditingController(
      text: addressDoc?['address'],
    );
    final notesController = TextEditingController(text: addressDoc?['notes']);

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            addressDoc == null ? 'Tambah Alamat Baru' : 'Edit Alamat',
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: labelController,
                    decoration: const InputDecoration(
                      labelText: 'Label Alamat (Contoh: Rumah, Kantor)',
                    ),
                    validator:
                        (v) => v!.isEmpty ? 'Label tidak boleh kosong' : null,
                  ),
                  TextFormField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Alamat Lengkap',
                    ),
                    maxLines: 3,
                    validator:
                        (v) => v!.isEmpty ? 'Alamat tidak boleh kosong' : null,
                  ),
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Catatan untuk Driver (Opsional)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final addressData = {
                    'label': labelController.text,
                    'address': addressController.text,
                    'notes': notesController.text,
                  };
                  if (addressDoc == null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(_currentUser!.uid)
                        .collection('addresses')
                        .add(addressData);
                  } else {
                    await addressDoc.reference.update(addressData);
                  }
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelectionMode ? 'Pilih Alamat' : 'Alamat Saya'),
      ),
      body:
          _currentUser == null
              ? const Center(child: Text("Silakan login untuk melihat alamat."))
              : StreamBuilder<QuerySnapshot>(
                stream: _getAddressStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("Anda belum memiliki alamat tersimpan."),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final addressDoc = snapshot.data!.docs[index];
                      final data = addressDoc.data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(
                            data['label'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(data['address']),
                          trailing:
                              widget.isSelectionMode
                                  ? null
                                  : PopupMenuButton(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showAddEditAddressDialog(
                                          addressDoc: addressDoc,
                                        );
                                      } else if (value == 'delete') {
                                        addressDoc.reference.delete();
                                      }
                                    },
                                    itemBuilder:
                                        (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Text('Edit'),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Hapus'),
                                          ),
                                        ],
                                  ),
                          onTap:
                              widget.isSelectionMode
                                  ? () {
                                    // Kirim kembali data alamat yang dipilih
                                    Navigator.of(context).pop(data);
                                  }
                                  : null,
                        ),
                      );
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditAddressDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
