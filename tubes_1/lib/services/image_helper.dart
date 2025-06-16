import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  // Show dialog untuk memilih sumber gambar
  static Future<File?> showImageSourceDialog(BuildContext context) async {
    return showDialog<File?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pilih Sumber Gambar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Kamera'),
                onTap: () async {
                  Navigator.pop(context);
                  File? image = await pickImageFromCamera();
                  Navigator.pop(context, image);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Galeri'),
                onTap: () async {
                  Navigator.pop(context);
                  File? image = await pickImageFromGallery();
                  Navigator.pop(context, image);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Pick image dari kamera
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

  // Pick image dari galeri
  static Future<File?> pickImageFromGallery() async {
    try {
      // Check photo permission
      PermissionStatus photoStatus = await Permission.photos.request();
      if (photoStatus != PermissionStatus.granted) {
        print('Photo permission denied');
        return null;
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
      PermissionStatus photoStatus = await Permission.photos.request();
      if (photoStatus != PermissionStatus.granted) {
        print('Photo permission denied');
        return [];
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
          child: Center(child: CircularProgressIndicator()),
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

// Widget untuk upload gambar dengan preview
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
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              widget.title!,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
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
          SizedBox(height: 8),
          Text(
            'Pilih Gambar',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      );
    }
  }

  void _selectImage() async {
    File? image = await ImageHelper.showImageSourceDialog(context);
    if (image != null) {
      String? validationError = ImageHelper.validateImage(image);
      if (validationError != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(validationError)));
        return;
      }

      setState(() {
        _selectedImage = image;
      });
      widget.onImageSelected(image);
    }
  }
}
