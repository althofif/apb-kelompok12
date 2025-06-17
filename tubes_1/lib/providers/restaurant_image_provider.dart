// providers/restaurant_image_provider.dart
import 'package:flutter/material.dart';
import 'dart:io';
import '../services/storage_service.dart';

class RestaurantImageProvider with ChangeNotifier {
  Map<String, String?> _restaurantLogos = {};
  Map<String, String?> _restaurantBanners = {};
  Map<String, List<String>> _restaurantGalleries = {};
  Map<String, List<String>> _menuImages = {};

  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _currentUploadType;

  // Getters
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;
  String? get currentUploadType => _currentUploadType;

  // Get restaurant logo
  String? getRestaurantLogo(String restaurantId) {
    return _restaurantLogos[restaurantId];
  }

  // Get restaurant banner
  String? getRestaurantBanner(String restaurantId) {
    return _restaurantBanners[restaurantId];
  }

  // Get restaurant gallery
  List<String> getRestaurantGallery(String restaurantId) {
    return _restaurantGalleries[restaurantId] ?? [];
  }

  // Get menu images
  List<String> getMenuImages(String restaurantId) {
    return _menuImages[restaurantId] ?? [];
  }

  // Set restaurant logo
  void setRestaurantLogo(String restaurantId, String? logoUrl) {
    _restaurantLogos[restaurantId] = logoUrl;
    notifyListeners();
  }

  // Set restaurant banner
  void setRestaurantBanner(String restaurantId, String? bannerUrl) {
    _restaurantBanners[restaurantId] = bannerUrl;
    notifyListeners();
  }

  // Set restaurant gallery
  void setRestaurantGallery(String restaurantId, List<String> galleryUrls) {
    _restaurantGalleries[restaurantId] = galleryUrls;
    notifyListeners();
  }

  // Add to restaurant gallery
  void addToRestaurantGallery(String restaurantId, List<String> newUrls) {
    if (_restaurantGalleries[restaurantId] == null) {
      _restaurantGalleries[restaurantId] = [];
    }
    _restaurantGalleries[restaurantId]!.addAll(newUrls);
    notifyListeners();
  }

  // Upload restaurant logo
  Future<bool> uploadRestaurantLogo({
    required String restaurantId,
    required File imageFile,
  }) async {
    try {
      _isUploading = true;
      _currentUploadType = 'logo';
      _uploadProgress = 0.0;
      notifyListeners();

      String? downloadUrl = await FirebaseStorageService.uploadWithProgress(
        path: 'restaurants/$restaurantId/images/logo_$restaurantId.jpg',
        file: imageFile,
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );

      if (downloadUrl != null) {
        _restaurantLogos[restaurantId] = downloadUrl;
        _isUploading = false;
        _currentUploadType = null;
        notifyListeners();
        return true;
      }

      _isUploading = false;
      _currentUploadType = null;
      notifyListeners();
      return false;
    } catch (e) {
      print('Error uploading restaurant logo: $e');
      _isUploading = false;
      _currentUploadType = null;
      notifyListeners();
      return false;
    }
  }

  // Upload restaurant banner
  Future<bool> uploadRestaurantBanner({
    required String restaurantId,
    required File imageFile,
  }) async {
    try {
      _isUploading = true;
      _currentUploadType = 'banner';
      _uploadProgress = 0.0;
      notifyListeners();

      String? downloadUrl = await FirebaseStorageService.uploadWithProgress(
        path: 'restaurants/$restaurantId/images/banner_$restaurantId.jpg',
        file: imageFile,
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );

      if (downloadUrl != null) {
        _restaurantBanners[restaurantId] = downloadUrl;
        _isUploading = false;
        _currentUploadType = null;
        notifyListeners();
        return true;
      }

      _isUploading = false;
      _currentUploadType = null;
      notifyListeners();
      return false;
    } catch (e) {
      print('Error uploading restaurant banner: $e');
      _isUploading = false;
      _currentUploadType = null;
      notifyListeners();
      return false;
    }
  }

  // Upload restaurant gallery
  Future<bool> uploadRestaurantGallery({
    required String restaurantId,
    required List<File> imageFiles,
  }) async {
    try {
      _isUploading = true;
      _currentUploadType = 'gallery';
      _uploadProgress = 0.0;
      notifyListeners();

      List<String> downloadUrls =
          await FirebaseStorageService.uploadRestaurantGallery(
            restaurantId: restaurantId,
            imageFiles: imageFiles,
          );

      if (downloadUrls.isNotEmpty) {
        addToRestaurantGallery(restaurantId, downloadUrls);
        _isUploading = false;
        _currentUploadType = null;
        notifyListeners();
        return true;
      }

      _isUploading = false;
      _currentUploadType = null;
      notifyListeners();
      return false;
    } catch (e) {
      print('Error uploading restaurant gallery: $e');
      _isUploading = false;
      _currentUploadType = null;
      notifyListeners();
      return false;
    }
  }

  // Upload menu image
  Future<String?> uploadMenuImage({
    required String restaurantId,
    required String menuId,
    required File imageFile,
  }) async {
    try {
      _isUploading = true;
      _currentUploadType = 'menu';
      _uploadProgress = 0.0;
      notifyListeners();

      String? downloadUrl = await FirebaseStorageService.uploadWithProgress(
        path: 'restaurants/$restaurantId/menu/menu_$menuId.jpg',
        file: imageFile,
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );

      _isUploading = false;
      _currentUploadType = null;
      notifyListeners();

      return downloadUrl;
    } catch (e) {
      print('Error uploading menu image: $e');
      _isUploading = false;
      _currentUploadType = null;
      notifyListeners();
      return null;
    }
  }

  // Delete restaurant image
  Future<bool> deleteRestaurantImage(String imageUrl) async {
    try {
      bool success = await FirebaseStorageService.deleteFile(imageUrl);
      if (success) {
        // Remove from local cache
        _restaurantLogos.removeWhere((key, value) => value == imageUrl);
        _restaurantBanners.removeWhere((key, value) => value == imageUrl);

        // Remove from galleries
        _restaurantGalleries.forEach((key, value) {
          value.removeWhere((url) => url == imageUrl);
        });

        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error deleting restaurant image: $e');
      return false;
    }
  }

  // Clear all images for a restaurant
  Future<bool> clearRestaurantImages(String restaurantId) async {
    try {
      bool success = await FirebaseStorageService.deleteFolder(
        'restaurants/$restaurantId',
      );
      if (success) {
        _restaurantLogos.remove(restaurantId);
        _restaurantBanners.remove(restaurantId);
        _restaurantGalleries.remove(restaurantId);
        _menuImages.remove(restaurantId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error clearing restaurant images: $e');
      return false;
    }
  }

  // Reset upload state
  void resetUploadState() {
    _isUploading = false;
    _uploadProgress = 0.0;
    _currentUploadType = null;
    notifyListeners();
  }
}
