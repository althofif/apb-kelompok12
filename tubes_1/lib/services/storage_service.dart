import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload gambar profil user
  static Future<String?> uploadUserProfile({
    required String userId,
    required File imageFile,
  }) async {
    try {
      String fileName = 'profile_$userId.${path.extension(imageFile.path)}';
      Reference ref = _storage.ref().child('users/profiles/$fileName');

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading user profile: $e');
      return null;
    }
  }

  // Upload gambar profil driver
  static Future<String?> uploadDriverProfile({
    required String driverId,
    required File imageFile,
  }) async {
    try {
      String fileName = 'profile_$driverId.${path.extension(imageFile.path)}';
      Reference ref = _storage.ref().child('drivers/profiles/$fileName');

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading driver profile: $e');
      return null;
    }
  }

  // Upload dokumen driver (KTP, SIM, STNK)
  static Future<String?> uploadDriverDocument({
    required String driverId,
    required File documentFile,
    required String documentType, // 'ktp', 'sim', 'stnk'
  }) async {
    try {
      String fileName =
          '${documentType}_$driverId.${path.extension(documentFile.path)}';
      Reference ref = _storage.ref().child('drivers/documents/$fileName');

      UploadTask uploadTask = ref.putFile(documentFile);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading driver document: $e');
      return null;
    }
  }

  // Upload gambar menu restoran
  static Future<String?> uploadMenuImage({
    required String restaurantId,
    required String menuId,
    required File imageFile,
  }) async {
    try {
      String fileName = 'menu_${menuId}.${path.extension(imageFile.path)}';
      Reference ref = _storage.ref().child(
        'restaurants/$restaurantId/menu/$fileName',
      );

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading menu image: $e');
      return null;
    }
  }

  // Upload gambar restoran
  static Future<String?> uploadRestaurantImage({
    required String restaurantId,
    required File imageFile,
    String? imageType, // 'logo', 'banner', 'gallery'
  }) async {
    try {
      String fileName =
          imageType != null
              ? '${imageType}_$restaurantId.${path.extension(imageFile.path)}'
              : 'restaurant_$restaurantId.${path.extension(imageFile.path)}';
      Reference ref = _storage.ref().child(
        'restaurants/$restaurantId/images/$fileName',
      );

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading restaurant image: $e');
      return null;
    }
  }

  // Upload multiple gambar untuk galeri restoran
  static Future<List<String>> uploadRestaurantGallery({
    required String restaurantId,
    required List<File> imageFiles,
  }) async {
    List<String> downloadUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        String fileName =
            'gallery_${restaurantId}_$i.${path.extension(imageFiles[i].path)}';
        Reference ref = _storage.ref().child(
          'restaurants/$restaurantId/gallery/$fileName',
        );

        UploadTask uploadTask = ref.putFile(imageFiles[i]);
        TaskSnapshot snapshot = await uploadTask;

        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      } catch (e) {
        print('Error uploading gallery image $i: $e');
      }
    }

    return downloadUrls;
  }

  // Upload gambar bukti pembayaran
  static Future<String?> uploadPaymentProof({
    required String orderId,
    required File imageFile,
  }) async {
    try {
      String fileName =
          'payment_proof_$orderId.${path.extension(imageFile.path)}';
      Reference ref = _storage.ref().child('payments/proofs/$fileName');

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading payment proof: $e');
      return null;
    }
  }

  // Upload gambar review
  static Future<List<String>> uploadReviewImages({
    required String reviewId,
    required List<File> imageFiles,
  }) async {
    List<String> downloadUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        String fileName =
            'review_${reviewId}_$i.${path.extension(imageFiles[i].path)}';
        Reference ref = _storage.ref().child('reviews/images/$fileName');

        UploadTask uploadTask = ref.putFile(imageFiles[i]);
        TaskSnapshot snapshot = await uploadTask;

        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      } catch (e) {
        print('Error uploading review image $i: $e');
      }
    }

    return downloadUrls;
  }

  // Upload dengan progress tracking
  static Future<String?> uploadWithProgress({
    required String path,
    required File file,
    required Function(double) onProgress,
  }) async {
    try {
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putFile(file);

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file with progress: $e');
      return null;
    }
  }

  // Delete file dari storage
  static Future<bool> deleteFile(String downloadUrl) async {
    try {
      Reference ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // Delete folder dan semua contents
  static Future<bool> deleteFolder(String folderPath) async {
    try {
      Reference ref = _storage.ref().child(folderPath);
      ListResult result = await ref.listAll();

      for (Reference fileRef in result.items) {
        await fileRef.delete();
      }

      for (Reference folderRef in result.prefixes) {
        await deleteFolder(folderRef.fullPath);
      }

      return true;
    } catch (e) {
      print('Error deleting folder: $e');
      return false;
    }
  }

  // Compress dan upload gambar
  static Future<String?> compressAndUpload({
    required String path,
    required File imageFile,
    int quality = 80,
  }) async {
    try {
      // Untuk compress image, Anda bisa menggunakan package flutter_image_compress
      // Di sini hanya contoh basic upload
      Reference ref = _storage.ref().child(path);
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error compressing and uploading: $e');
      return null;
    }
  }

  // Get file metadata
  static Future<FullMetadata?> getFileMetadata(String downloadUrl) async {
    try {
      Reference ref = _storage.refFromURL(downloadUrl);
      FullMetadata metadata = await ref.getMetadata();
      return metadata;
    } catch (e) {
      print('Error getting metadata: $e');
      return null;
    }
  }

  // List files in folder
  static Future<List<String>> listFiles(String folderPath) async {
    try {
      Reference ref = _storage.ref().child(folderPath);
      ListResult result = await ref.listAll();

      List<String> downloadUrls = [];
      for (Reference fileRef in result.items) {
        String downloadUrl = await fileRef.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }

      return downloadUrls;
    } catch (e) {
      print('Error listing files: $e');
      return [];
    }
  }
}
