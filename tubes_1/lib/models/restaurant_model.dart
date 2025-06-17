import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart'; // Import storage service

class RestaurantModel {
  final String id;
  final String name;
  final String address;
  final String? imageUrl;
  final String? logoUrl;
  final String? bannerUrl;
  final List<String> galleryUrls;
  final String description;
  final bool isOpen;
  final double rating;
  final int reviews;
  final String category;
  final GeoPoint? location;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.address,
    this.imageUrl,
    this.logoUrl,
    this.bannerUrl,
    this.galleryUrls = const [],
    required this.description,
    required this.isOpen,
    required this.rating,
    required this.reviews,
    required this.category,
    this.location,
  });

  factory RestaurantModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RestaurantModel(
      id: doc.id,
      name: data['name'] ?? 'Nama Tidak Ada',
      address: data['address'] ?? 'Alamat Tidak Ada',
      imageUrl: data['imageUrl'],
      logoUrl: data['logoUrl'],
      bannerUrl: data['bannerUrl'],
      galleryUrls: List<String>.from(data['galleryUrls'] ?? []),
      description: data['description'] ?? '',
      isOpen: data['isOpen'] ?? false,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviews: data['reviews'] ?? 0,
      category: data['category'] ?? 'Lainnya',
      location: data['location'] as GeoPoint?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'address': address,
      'imageUrl': imageUrl,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'galleryUrls': galleryUrls,
      'description': description,
      'isOpen': isOpen,
      'rating': rating,
      'reviews': reviews,
      'category': category,
      'location': location,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  // Upload logo restoran
  Future<RestaurantModel?> updateLogo(File imageFile) async {
    try {
      // Delete old logo if exists
      if (logoUrl != null && logoUrl!.isNotEmpty) {
        await FirebaseStorageService.deleteFile(logoUrl!);
      }

      String? downloadUrl = await FirebaseStorageService.uploadRestaurantImage(
        restaurantId: id,
        imageFile: imageFile,
        imageType: 'logo',
      );

      if (downloadUrl != null) {
        return copyWith(logoUrl: downloadUrl);
      }
      return null;
    } catch (e) {
      print('Error updating restaurant logo: $e');
      return null;
    }
  }

  // Upload banner restoran
  Future<RestaurantModel?> updateBanner(File imageFile) async {
    try {
      // Delete old banner if exists
      if (bannerUrl != null && bannerUrl!.isNotEmpty) {
        await FirebaseStorageService.deleteFile(bannerUrl!);
      }

      String? downloadUrl = await FirebaseStorageService.uploadRestaurantImage(
        restaurantId: id,
        imageFile: imageFile,
        imageType: 'banner',
      );

      if (downloadUrl != null) {
        return copyWith(bannerUrl: downloadUrl);
      }
      return null;
    } catch (e) {
      print('Error updating restaurant banner: $e');
      return null;
    }
  }

  // Upload main image restoran
  Future<RestaurantModel?> updateMainImage(File imageFile) async {
    try {
      // Delete old image if exists
      if (imageUrl != null && imageUrl!.isNotEmpty) {
        await FirebaseStorageService.deleteFile(imageUrl!);
      }

      String? downloadUrl = await FirebaseStorageService.uploadRestaurantImage(
        restaurantId: id,
        imageFile: imageFile,
      );

      if (downloadUrl != null) {
        return copyWith(imageUrl: downloadUrl);
      }
      return null;
    } catch (e) {
      print('Error updating restaurant main image: $e');
      return null;
    }
  }

  // Upload multiple images untuk gallery
  Future<RestaurantModel?> updateGallery(List<File> imageFiles) async {
    try {
      // Delete old gallery images
      for (String url in galleryUrls) {
        await FirebaseStorageService.deleteFile(url);
      }

      List<String> newGalleryUrls =
          await FirebaseStorageService.uploadRestaurantGallery(
            restaurantId: id,
            imageFiles: imageFiles,
          );

      return copyWith(galleryUrls: newGalleryUrls);
    } catch (e) {
      print('Error updating restaurant gallery: $e');
      return null;
    }
  }

  // Add single image to gallery
  Future<RestaurantModel?> addToGallery(File imageFile) async {
    try {
      String? downloadUrl = await FirebaseStorageService.uploadRestaurantImage(
        restaurantId: id,
        imageFile: imageFile,
        imageType: 'gallery',
      );

      if (downloadUrl != null) {
        List<String> newGalleryUrls = [...galleryUrls, downloadUrl];
        return copyWith(galleryUrls: newGalleryUrls);
      }
      return null;
    } catch (e) {
      print('Error adding image to gallery: $e');
      return null;
    }
  }

  // Remove image from gallery
  Future<RestaurantModel?> removeFromGallery(String imageUrl) async {
    try {
      bool deleted = await FirebaseStorageService.deleteFile(imageUrl);
      if (deleted) {
        List<String> newGalleryUrls =
            galleryUrls.where((url) => url != imageUrl).toList();
        return copyWith(galleryUrls: newGalleryUrls);
      }
      return null;
    } catch (e) {
      print('Error removing image from gallery: $e');
      return null;
    }
  }

  // Delete all restaurant images
  Future<bool> deleteAllImages() async {
    try {
      bool success = true;

      // Delete main image
      if (imageUrl != null && imageUrl!.isNotEmpty) {
        success &= await FirebaseStorageService.deleteFile(imageUrl!);
      }

      // Delete logo
      if (logoUrl != null && logoUrl!.isNotEmpty) {
        success &= await FirebaseStorageService.deleteFile(logoUrl!);
      }

      // Delete banner
      if (bannerUrl != null && bannerUrl!.isNotEmpty) {
        success &= await FirebaseStorageService.deleteFile(bannerUrl!);
      }

      // Delete gallery images
      for (String url in galleryUrls) {
        success &= await FirebaseStorageService.deleteFile(url);
      }

      return success;
    } catch (e) {
      print('Error deleting all restaurant images: $e');
      return false;
    }
  }

  // Copy with method
  RestaurantModel copyWith({
    String? id,
    String? name,
    String? address,
    String? imageUrl,
    String? logoUrl,
    String? bannerUrl,
    List<String>? galleryUrls,
    String? description,
    bool? isOpen,
    double? rating,
    int? reviews,
    String? category,
    GeoPoint? location,
  }) {
    return RestaurantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      galleryUrls: galleryUrls ?? this.galleryUrls,
      description: description ?? this.description,
      isOpen: isOpen ?? this.isOpen,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      category: category ?? this.category,
      location: location ?? this.location,
    );
  }
}
