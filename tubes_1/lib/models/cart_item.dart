// models/cart_item.dart

class CartItem {
  final String id; // ID dari menu item
  final String name;
  final double price; // Menggunakan double untuk konsistensi
  final int quantity;
  final String imageUrl;
  final String restaurantId;
  final String restaurantName;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.restaurantId,
    required this.restaurantName,
  });
}
