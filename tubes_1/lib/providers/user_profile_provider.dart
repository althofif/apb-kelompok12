// providers/user_profile_provider.dart
import 'package:flutter/material.dart';
import 'dart:io';
import '../services/storage_service.dart';

class UserProfileProvider with ChangeNotifier {
  String? _profileImageUrl;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  String? get profileImageUrl => _profileImageUrl;
  bool get isUploading => _isUploading;
  double get uploadProgress => _uploadProgress;

  // Set profile image URL
  void setProfileImageUrl(String? url) {
    _profileImageUrl = url;
    notifyListeners();
  }

  // Upload profile image
  Future<bool> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      _isUploading = true;
      _uploadProgress = 0.0;
      notifyListeners();

      // Upload with progress tracking
      String? downloadUrl = await FirebaseStorageService.uploadWithProgress(
        path: 'users/profiles/profile_$userId.jpg',
        file: imageFile,
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );

      if (downloadUrl != null) {
        _profileImageUrl = downloadUrl;
        _isUploading = false;
        notifyListeners();
        return true;
      }

      _isUploading = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Error uploading profile image: $e');
      _isUploading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete profile image
  Future<bool> deleteProfileImage() async {
    if (_profileImageUrl == null) return true;

    try {
      bool success = await FirebaseStorageService.deleteFile(_profileImageUrl!);
      if (success) {
        _profileImageUrl = null;
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error deleting profile image: $e');
      return false;
    }
  }

  // Reset upload state
  void resetUploadState() {
    _isUploading = false;
    _uploadProgress = 0.0;
    notifyListeners();
  }
}
