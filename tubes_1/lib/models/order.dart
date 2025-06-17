import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/storage_service.dart'; // Import storage service

class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String imageUrl;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      menuItemId: data['menuItemId'],
      name: data['name'],
      price: (data['price'] ?? 0.0).toDouble(),
      quantity: data['quantity'],
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    };
  }
}

class Order {
  final String id;
  final String customerId;
  final String restaurantId;
  final String? driverId;
  final List<OrderItem> items;
  final double totalAmount;
  final String
  status; // 'pending', 'preparing', 'on_delivery', 'delivered', 'cancelled'
  final GeoPoint? deliveryLocation;
  final Timestamp orderTime;
  final Timestamp? deliveryTime;
  final String? paymentProofUrl; // URL gambar bukti pembayaran
  final List<String> reviewImageUrls; // URLs gambar review

  Order({
    required this.id,
    required this.customerId,
    required this.restaurantId,
    this.driverId,
    required this.items,
    required this.totalAmount,
    required this.status,
    this.deliveryLocation,
    required this.orderTime,
    this.deliveryTime,
    this.paymentProofUrl,
    this.reviewImageUrls = const [],
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      driverId: data['driverId'],
      items:
          (data['items'] as List? ?? [])
              .map((item) => OrderItem.fromMap(item))
              .toList(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      deliveryLocation: data['deliveryLocation'],
      orderTime: data['orderTime'] as Timestamp? ?? Timestamp.now(),
      deliveryTime: data['deliveryTime'] as Timestamp?,
      paymentProofUrl: data['paymentProofUrl'],
      reviewImageUrls: List<String>.from(data['reviewImageUrls'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'restaurantId': restaurantId,
      'driverId': driverId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'deliveryLocation': deliveryLocation,
      'orderTime': orderTime,
      'deliveryTime': deliveryTime,
      'paymentProofUrl': paymentProofUrl,
      'reviewImageUrls': reviewImageUrls,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  // Upload bukti pembayaran
  Future<Order?> uploadPaymentProof(File imageFile) async {
    try {
      // Delete old payment proof if exists
      if (paymentProofUrl != null && paymentProofUrl!.isNotEmpty) {
        await FirebaseStorageService.deleteFile(paymentProofUrl!);
      }

      String? downloadUrl = await FirebaseStorageService.uploadPaymentProof(
        orderId: id,
        imageFile: imageFile,
      );

      if (downloadUrl != null) {
        return copyWith(paymentProofUrl: downloadUrl);
      }
      return null;
    } catch (e) {
      print('Error uploading payment proof: $e');
      return null;
    }
  }

  // Upload gambar review
  Future<Order?> uploadReviewImages(List<File> imageFiles) async {
    try {
      // Delete old review images if exist
      for (String url in reviewImageUrls) {
        await FirebaseStorageService.deleteFile(url);
      }

      List<String> downloadUrls =
          await FirebaseStorageService.uploadReviewImages(
            reviewId: '${id}_review',
            imageFiles: imageFiles,
          );

      return copyWith(reviewImageUrls: downloadUrls);
    } catch (e) {
      print('Error uploading review images: $e');
      return null;
    }
  }

  // Add single review image
  Future<Order?> addReviewImage(File imageFile) async {
    try {
      String? downloadUrl = await FirebaseStorageService.uploadWithProgress(
        path:
            'reviews/images/review_${id}_${reviewImageUrls.length}.${imageFile.path.split('.').last}',
        file: imageFile,
        onProgress: (progress) {
          print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
        },
      );

      if (downloadUrl != null) {
        List<String> newReviewUrls = [...reviewImageUrls, downloadUrl];
        return copyWith(reviewImageUrls: newReviewUrls);
      }
      return null;
    } catch (e) {
      print('Error adding review image: $e');
      return null;
    }
  }

  // Remove review image
  Future<Order?> removeReviewImage(String imageUrl) async {
    try {
      bool deleted = await FirebaseStorageService.deleteFile(imageUrl);
      if (deleted) {
        List<String> newReviewUrls =
            reviewImageUrls.where((url) => url != imageUrl).toList();
        return copyWith(reviewImageUrls: newReviewUrls);
      }
      return null;
    } catch (e) {
      print('Error removing review image: $e');
      return null;
    }
  }

  // Delete payment proof
  Future<Order?> deletePaymentProof() async {
    if (paymentProofUrl == null || paymentProofUrl!.isEmpty) return this;

    try {
      bool deleted = await FirebaseStorageService.deleteFile(paymentProofUrl!);
      if (deleted) {
        return copyWith(paymentProofUrl: null);
      }
      return null;
    } catch (e) {
      print('Error deleting payment proof: $e');
      return null;
    }
  }

  // Delete all order-related images
  Future<bool> deleteAllImages() async {
    try {
      bool success = true;

      // Delete payment proof
      if (paymentProofUrl != null && paymentProofUrl!.isNotEmpty) {
        success &= await FirebaseStorageService.deleteFile(paymentProofUrl!);
      }

      // Delete review images
      for (String url in reviewImageUrls) {
        success &= await FirebaseStorageService.deleteFile(url);
      }

      return success;
    } catch (e) {
      print('Error deleting all order images: $e');
      return false;
    }
  }

  // Copy with method
  Order copyWith({
    String? id,
    String? customerId,
    String? restaurantId,
    String? driverId,
    List<OrderItem>? items,
    double? totalAmount,
    String? status,
    GeoPoint? deliveryLocation,
    Timestamp? orderTime,
    Timestamp? deliveryTime,
    String? paymentProofUrl,
    List<String>? reviewImageUrls,
  }) {
    return Order(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      restaurantId: restaurantId ?? this.restaurantId,
      driverId: driverId ?? this.driverId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      deliveryLocation: deliveryLocation ?? this.deliveryLocation,
      orderTime: orderTime ?? this.orderTime,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      reviewImageUrls: reviewImageUrls ?? this.reviewImageUrls,
    );
  }

  // Helper methods
  bool get isPending => status == 'pending';
  bool get isPreparing => status == 'preparing';
  bool get isOnDelivery => status == 'on_delivery';
  bool get isDelivered => status == 'delivered';
  bool get isCancelled => status == 'cancelled';
  bool get hasPaymentProof =>
      paymentProofUrl != null && paymentProofUrl!.isNotEmpty;
  bool get hasReviewImages => reviewImageUrls.isNotEmpty;
}
