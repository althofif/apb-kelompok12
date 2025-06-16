import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_address_screen.dart';

class AddressScreen extends StatelessWidget {
  final bool isSelectionMode;
  const AddressScreen({Key? key, this.isSelectionMode = false})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSelectionMode ? 'Pilih Alamat' : 'Alamat Tersimpan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body:
          user == null
              ? _buildNotLoggedInUI()
              : StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .collection('addresses')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return _buildErrorUI();
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyAddressUI(context);
                  }

                  return _buildAddressList(context, snapshot.data!.docs);
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => const AddAddressScreen()),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildNotLoggedInUI() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red),
          SizedBox(height: 16),
          Text('Silakan login untuk melihat alamat.'),
        ],
      ),
    );
  }

  Widget _buildErrorUI() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red),
          SizedBox(height: 16),
          Text('Terjadi kesalahan saat memuat alamat.'),
        ],
      ),
    );
  }

  Widget _buildEmptyAddressUI(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_outlined, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Anda belum memiliki alamat tersimpan',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const AddAddressScreen()),
              );
            },
            child: const Text('Tambah Alamat'),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressList(
    BuildContext context,
    List<QueryDocumentSnapshot> addresses,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: addresses.length,
      itemBuilder: (ctx, index) {
        final addressDoc = addresses[index];
        final address = addressDoc.data() as Map<String, dynamic>;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            leading: Icon(
              Icons.location_on_outlined,
              color: Theme.of(context).primaryColor,
            ),
            title: Text(
              address['label'] ?? 'Tanpa Label',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(address['address'] ?? 'Tanpa Alamat'),
                if (address['notes'] != null &&
                    address['notes'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Catatan: ${address['notes']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
            trailing:
                isSelectionMode
                    ? const Icon(Icons.check)
                    : IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed:
                          () => _confirmDeleteAddress(context, addressDoc),
                    ),
            onTap: () {
              if (isSelectionMode) {
                Navigator.of(context).pop(address);
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteAddress(
    BuildContext context,
    QueryDocumentSnapshot addressDoc,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Hapus Alamat'),
            content: const Text(
              'Apakah Anda yakin ingin menghapus alamat ini?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await addressDoc.reference.delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Alamat berhasil dihapus')));
    }
  }
}
