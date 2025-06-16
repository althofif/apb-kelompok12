// models/cart_item_model.dart

class CartItem {
  final String id; // ID dari menu item
  final String name;
  final int price;
  int quantity;
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
