import 'package:flutter/foundation.dart';
import '../models/cart_item.dart'; // Import model dari file terpisah

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};
  String? _restaurantId;
  String? _restaurantName;

  Map<String, CartItem> get items => {..._items};
  String? get restaurantId => _restaurantId;
  String? get restaurantName => _restaurantName;
  int get itemCount =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount {
    return _items.values.fold(
      0.0,
      (sum, item) => sum + item.price * item.quantity,
    );
  }

  bool addItem(
    String menuId,
    double price,
    String name,
    String imageUrl,
    String restaurantId,
    String restaurantName,
  ) {
    if (_items.isNotEmpty && _restaurantId != restaurantId) {
      return false; // Gagal karena item dari restoran lain
    }

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
    return true; // Berhasil
  }

  void removeItem(String menuId) {
    _items.remove(menuId);
    if (_items.isEmpty) {
      _clearRestaurantInfo();
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
      _clearRestaurantInfo();
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _clearRestaurantInfo();
    notifyListeners();
  }

  void _clearRestaurantInfo() {
    _restaurantId = null;
    _restaurantName = null;
  }
}
