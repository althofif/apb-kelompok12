import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool available;
  final int popularity;
  final String? restaurantName;
  final List<dynamic>? keywords; // Ganti menjadi List<dynamic> agar lebih aman
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.available,
    required this.popularity,
    this.restaurantName,
    this.keywords,
    this.createdAt,
    this.updatedAt,
  });

  factory MenuItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MenuItem(
      id: doc.id,
      restaurantId: data['restaurantId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? '',
      available: data['available'] ?? false,
      popularity: data['popularity'] ?? 0,
      restaurantName: data['restaurantName'] as String?,
      keywords: data['keywords'] as List<dynamic>?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'restaurantId': restaurantId,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'available': available,
      'popularity': popularity,
      'restaurantName': restaurantName,
      'keywords': keywords,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
