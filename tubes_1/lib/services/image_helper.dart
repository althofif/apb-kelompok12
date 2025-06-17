import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  // Show dialog untuk memilih sumber gambar - DIPERBAIKI
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    return showDialog<File?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Sumber Gambar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () async {
                  Navigator.pop(context); // Tutup dialog
                  File? image = await pickImageFromCamera();
                  // Kembalikan hasil langsung tanpa Navigator.pop kedua
                  if (context.mounted) {
                    Navigator.pop(context, image);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () async {
                  Navigator.pop(context); // Tutup dialog
                  File? image = await pickImageFromGallery();
                  // Kembalikan hasil langsung tanpa Navigator.pop kedua
                  if (context.mounted) {
                    Navigator.pop(context, image);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  // Alternatif yang lebih sederhana - METODE BARU
  static Future<File?> showImageSourceDialogSimple(BuildContext context) async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Sumber Gambar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeri'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );

    if (source == null) return null;

    if (source == ImageSource.camera) {
      return await pickImageFromCamera();
    } else {
      return await pickImageFromGallery();
    }
  }

  // Pick image dari kamera - DIPERBAIKI
  static Future<File?> pickImageFromCamera() async {
    try {
      // Check camera permission
      PermissionStatus cameraStatus = await Permission.camera.request();
      if (cameraStatus != PermissionStatus.granted) {
        print('Camera permission denied');
        return null;
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  // Pick image dari galeri - DIPERBAIKI
  static Future<File?> pickImageFromGallery() async {
    try {
      // Untuk Android 13+ gunakan permission yang berbeda
      PermissionStatus photoStatus;
      if (Platform.isAndroid) {
        // Coba permission yang lebih spesifik dulu
        photoStatus = await Permission.storage.request();
        if (photoStatus != PermissionStatus.granted) {
          // Jika gagal, coba photos permission
          photoStatus = await Permission.photos.request();
        }
      } else {
        photoStatus = await Permission.photos.request();
      }

      // Jika permission ditolak, tetap lanjutkan karena mungkin tidak diperlukan
      if (photoStatus == PermissionStatus.denied) {
        print('Photo permission denied, but continuing...');
      }

      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  // Pick multiple images dari galeri
  static Future<List<File>> pickMultipleImages({int maxImages = 5}) async {
    try {
      // Permission handling yang lebih flexible
      if (Platform.isAndroid) {
        await Permission.storage.request();
      } else {
        await Permission.photos.request();
      }

      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (images.length > maxImages) {
        // Ambil hanya sesuai limit
        return images.take(maxImages).map((xFile) => File(xFile.path)).toList();
      }

      return images.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }

  // Validate image file
  static bool isValidImageFile(File file) {
    String path = file.path.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.gif') ||
        path.endsWith('.webp');
  }

  // Get file size in MB
  static double getFileSizeInMB(File file) {
    int bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  // Check if file size is within limit
  static bool isFileSizeValid(File file, {double maxSizeInMB = 5.0}) {
    double sizeInMB = getFileSizeInMB(file);
    return sizeInMB <= maxSizeInMB;
  }

  // Validate image before upload
  static String? validateImage(File file, {double maxSizeInMB = 5.0}) {
    if (!isValidImageFile(file)) {
      return 'Format file tidak didukung. Gunakan JPG, PNG, atau GIF.';
    }

    if (!isFileSizeValid(file, maxSizeInMB: maxSizeInMB)) {
      return 'Ukuran file terlalu besar. Maksimal ${maxSizeInMB}MB.';
    }

    return null; // Valid
  }
}

// Widget untuk menampilkan gambar dengan loading state
class NetworkImageWithLoading extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const NetworkImageWithLoading({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(8),
      child: Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildLoadingWidget();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return placeholder ??
        Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        );
  }

  Widget _buildErrorWidget() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: Icon(
            Icons.image_not_supported,
            color: Colors.grey[400],
            size: 32,
          ),
        );
  }
}

// Widget untuk upload gambar dengan preview - DIPERBAIKI
class ImageUploadWidget extends StatefulWidget {
  final String? initialImageUrl;
  final Function(File) onImageSelected;
  final String? title;
  final double width;
  final double height;
  final bool isRequired;

  const ImageUploadWidget({
    Key? key,
    this.initialImageUrl,
    required this.onImageSelected,
    this.title,
    this.width = 150,
    this.height = 150,
    this.isRequired = false,
  }) : super(key: key);

  @override
  _ImageUploadWidgetState createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  File? _selectedImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.title!,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
          ),
        GestureDetector(
          onTap: () => _selectImage(),
          child: Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildImageContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent() {
    if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.file(_selectedImage!, fit: BoxFit.cover),
      );
    } else if (widget.initialImageUrl != null &&
        widget.initialImageUrl!.isNotEmpty) {
      return NetworkImageWithLoading(
        imageUrl: widget.initialImageUrl,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(6),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 32, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Pilih Gambar',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      );
    }
  }

  void _selectImage() async {
    try {
      // Gunakan method yang lebih sederhana
      File? image = await ImageHelper.showImageSourceDialogSimple(context);
      if (image != null) {
        String? validationError = ImageHelper.validateImage(image);
        if (validationError != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(validationError),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedImage = image;
        });
        widget.onImageSelected(image);
      }
    } catch (e) {
      print('Error selecting image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error memilih gambar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
