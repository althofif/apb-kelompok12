// providers/order_provider.dart
import 'package:flutter/material.dart';
import 'dart:io';
import '../services/storage_service.dart';

class OrderProvider with ChangeNotifier {
  Map<String, String?> _paymentProofs = {};
  bool _isUploadingProof = false;
  double _uploadProgress = 0.0;

  // Getters
  bool get isUploadingProof => _isUploadingProof;
  double get uploadProgress => _uploadProgress;

  // Get payment proof URL
  String? getPaymentProof(String orderId) {
    return _paymentProofs[orderId];
  }

  // Set payment proof URL
  void setPaymentProof(String orderId, String? proofUrl) {
    _paymentProofs[orderId] = proofUrl;
    notifyListeners();
  }

  // Upload payment proof
  Future<bool> uploadPaymentProof({
    required String orderId,
    required File imageFile,
  }) async {
    try {
      _isUploadingProof = true;
      _uploadProgress = 0.0;
      notifyListeners();

      String? downloadUrl = await FirebaseStorageService.uploadWithProgress(
        path: 'payments/proofs/payment_proof_$orderId.jpg',
        file: imageFile,
        onProgress: (progress) {
          _uploadProgress = progress;
          notifyListeners();
        },
      );

      if (downloadUrl != null) {
        _paymentProofs[orderId] = downloadUrl;
        _isUploadingProof = false;
        notifyListeners();
        return true;
      }

      _isUploadingProof = false;
      notifyListeners();
      return false;
    } catch (e) {
      print('Error uploading payment proof: $e');
      _isUploadingProof = false;
      notifyListeners();
      return false;
    }
  }

  // Delete payment proof
  Future<bool> deletePaymentProof(String orderId) async {
    String? proofUrl = _paymentProofs[orderId];
    if (proofUrl == null) return true;

    try {
      bool success = await FirebaseStorageService.deleteFile(proofUrl);
      if (success) {
        _paymentProofs.remove(orderId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error deleting payment proof: $e');
      return false;
    }
  }

  // Reset upload state
  void resetUploadState() {
    _isUploadingProof = false;
    _uploadProgress = 0.0;
    notifyListeners();
  }
}
