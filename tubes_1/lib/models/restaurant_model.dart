import 'package:cloud_firestore/cloud_firestore.dart';

class RestaurantModel {
  final String id;
  final String name;
  final String address;
  final String? imageUrl;
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
      description: data['description'] ?? '',
      isOpen: data['isOpen'] ?? false,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviews: data['reviews'] ?? 0,
      category: data['category'] ?? 'Lainnya',
      location: data['location'] as GeoPoint?,
    );
  }
}
