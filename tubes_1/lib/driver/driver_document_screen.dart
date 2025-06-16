import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/image_helper.dart';
import '../services/storage_service.dart';

class DriverDocumentScreen extends StatefulWidget {
  const DriverDocumentScreen({Key? key}) : super(key: key);

  @override
  _DriverDocumentScreenState createState() => _DriverDocumentScreenState();
}

class _DriverDocumentScreenState extends State<DriverDocumentScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  // Untuk menyimpan file yang akan diupload
  File? _ktpImage;
  File? _simImage;
  File? _stnkImage;

  // Untuk menyimpan URL gambar yang sudah ada
  String? _ktpUrl;
  String? _simUrl;
  String? _stnkUrl;

  @override
  void initState() {
    super.initState();
    _fetchDocumentUrls();
  }

  Future<void> _fetchDocumentUrls() async {
    if (_currentUser == null) return;
    final docRef = FirebaseFirestore.instance
        .collection('drivers')
        .doc(_currentUser!.uid);
    final docSnapshot = await docRef.get();
    if (mounted && docSnapshot.exists) {
      final data = docSnapshot.data() as Map<String, dynamic>;
      setState(() {
        _ktpUrl = data['ktpUrl'];
        _simUrl = data['simUrl'];
        _stnkUrl = data['stnkUrl'];
      });
    }
  }

  Future<void> _uploadDocuments() async {
    if (_ktpImage == null && _simImage == null && _stnkImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih setidaknya satu gambar untuk diunggah.'),
        ),
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> updateData = {};

      if (_ktpImage != null) {
        final url = await FirebaseStorageService.uploadDriverDocument(
          driverId: _currentUser!.uid,
          documentFile: _ktpImage!,
          documentType: 'ktp',
        );
        if (url != null) updateData['ktpUrl'] = url;
      }
      if (_simImage != null) {
        final url = await FirebaseStorageService.uploadDriverDocument(
          driverId: _currentUser!.uid,
          documentFile: _simImage!,
          documentType: 'sim',
        );
        if (url != null) updateData['simUrl'] = url;
      }
      if (_stnkImage != null) {
        final url = await FirebaseStorageService.uploadDriverDocument(
          driverId: _currentUser!.uid,
          documentFile: _stnkImage!,
          documentType: 'stnk',
        );
        if (url != null) updateData['stnkUrl'] = url;
      }

      if (updateData.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('drivers')
            .doc(_currentUser!.uid)
            .set(updateData, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dokumen berhasil diunggah!'),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchDocumentUrls(); // Refresh URLs
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah: $e'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dokumen Verifikasi')),
      body:
          _currentUser == null
              ? const Center(child: Text("Harap login."))
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    "Unggah dokumen Anda untuk proses verifikasi. Pastikan gambar terlihat jelas dan tidak buram.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildDocumentUploader(
                    'Foto KTP',
                    _ktpUrl,
                    _ktpImage,
                    (file) => setState(() => _ktpImage = file),
                  ),
                  const SizedBox(height: 16),
                  _buildDocumentUploader(
                    'Foto SIM C',
                    _simUrl,
                    _simImage,
                    (file) => setState(() => _simImage = file),
                  ),
                  const SizedBox(height: 16),
                  _buildDocumentUploader(
                    'Foto STNK',
                    _stnkUrl,
                    _stnkImage,
                    (file) => setState(() => _stnkImage = file),
                  ),
                  const SizedBox(height: 32),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                        onPressed: _uploadDocuments,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('UNGGAH DOKUMEN'),
                      ),
                ],
              ),
    );
  }

  Widget _buildDocumentUploader(
    String title,
    String? imageUrl,
    File? imageFile,
    Function(File) onImageSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final file = await ImageHelper.pickImageFromGallery();
            if (file != null) {
              final error = ImageHelper.validateImage(file, maxSizeInMB: 2);
              if (error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(error), backgroundColor: Colors.red),
                );
                return;
              }
              onImageSelected(file);
            }
          },
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child:
                imageFile != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.file(imageFile, fit: BoxFit.cover),
                    )
                    : (imageUrl != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                          ),
                        )
                        : const Center(
                          child: Icon(
                            Icons.add_a_photo,
                            size: 50,
                            color: Colors.grey,
                          ),
                        )),
          ),
        ),
      ],
    );
  }
}
