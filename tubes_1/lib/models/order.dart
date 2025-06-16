import 'package:cloud_firestore/cloud_firestore.dart';

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
      imageUrl: data['imageUrl'],
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
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      restaurantId: data['restaurantId'] ?? '',
      driverId: data['driverId'],
      items:
          (data['items'] as List)
              .map((item) => OrderItem.fromMap(item))
              .toList(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      deliveryLocation: data['deliveryLocation'],
      orderTime: data['orderTime'] as Timestamp,
      deliveryTime: data['deliveryTime'] as Timestamp?,
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
      'timestamp': FieldValue.serverTimestamp(), // For general sorting
    };
  }
}
