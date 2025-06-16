import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String name;
  final double price;
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

  double get totalPrice => price * quantity;
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};
  String? _restaurantId;
  String? _restaurantName;

  Map<String, CartItem> get items => {..._items};
  String? get restaurantId => _restaurantId;
  String? get restaurantName => _restaurantName;
  int get itemCount => _items.length;
  double get totalAmount {
    return _items.values.fold(0, (sum, item) => sum + item.totalPrice);
  }

  bool addItem(
    String menuId,
    double price,
    String name,
    String imageUrl,
    String restaurantId,
    String restaurantName,
  ) {
    // Jika keranjang tidak kosong dan bukan dari restoran yang sama
    if (_items.isNotEmpty && _restaurantId != restaurantId) {
      return false;
    }

    // Set restoran info jika keranjang kosong
    if (_items.isEmpty) {
      _restaurantId = restaurantId;
      _restaurantName = restaurantName;
    }

    if (_items.containsKey(menuId)) {
      _items.update(
        menuId,
        (existingItem) => CartItem(
          id: existingItem.id,
          name: existingItem.name,
          price: existingItem.price,
          quantity: existingItem.quantity + 1,
          imageUrl: existingItem.imageUrl,
          restaurantId: existingItem.restaurantId,
          restaurantName: existingItem.restaurantName,
        ),
      );
    } else {
      _items.putIfAbsent(
        menuId,
        () => CartItem(
          id: menuId,
          name: name,
          price: price,
          quantity: 1,
          imageUrl: imageUrl,
          restaurantId: restaurantId,
          restaurantName: restaurantName,
        ),
      );
    }
    notifyListeners();
    return true;
  }

  void removeItem(String menuId) {
    _items.remove(menuId);
    if (_items.isEmpty) {
      _restaurantId = null;
      _restaurantName = null;
    }
    notifyListeners();
  }

  void removeSingleItem(String menuId) {
    if (!_items.containsKey(menuId)) return;

    if (_items[menuId]!.quantity > 1) {
      _items.update(
        menuId,
        (existingItem) => CartItem(
          id: existingItem.id,
          name: existingItem.name,
          price: existingItem.price,
          quantity: existingItem.quantity - 1,
          imageUrl: existingItem.imageUrl,
          restaurantId: existingItem.restaurantId,
          restaurantName: existingItem.restaurantName,
        ),
      );
    } else {
      _items.remove(menuId);
    }

    if (_items.isEmpty) {
      _restaurantId = null;
      _restaurantName = null;
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _restaurantId = null;
    _restaurantName = null;
    notifyListeners();
  }
}
