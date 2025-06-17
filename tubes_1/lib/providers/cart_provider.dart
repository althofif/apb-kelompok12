// providers/cart_provider.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/cart_item.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};
  String? _restaurantId;
  String? _restaurantName;

  static const String _cartKey = 'cart_items';
  static const String _restaurantIdKey = 'restaurant_id';
  static const String _restaurantNameKey = 'restaurant_name';

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

  // Initialize cart from local storage
  Future<void> initializeCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load restaurant info
      _restaurantId = prefs.getString(_restaurantIdKey);
      _restaurantName = prefs.getString(_restaurantNameKey);

      // Load cart items
      final cartData = prefs.getString(_cartKey);
      if (cartData != null) {
        final Map<String, dynamic> cartMap = jsonDecode(cartData);
        _items = cartMap.map(
          (key, value) => MapEntry(key, CartItem.fromJson(value)),
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  // Save cart to local storage
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save restaurant info
      if (_restaurantId != null) {
        await prefs.setString(_restaurantIdKey, _restaurantId!);
      } else {
        await prefs.remove(_restaurantIdKey);
      }

      if (_restaurantName != null) {
        await prefs.setString(_restaurantNameKey, _restaurantName!);
      } else {
        await prefs.remove(_restaurantNameKey);
      }

      // Save cart items
      if (_items.isNotEmpty) {
        final cartMap = _items.map(
          (key, value) => MapEntry(key, value.toJson()),
        );
        await prefs.setString(_cartKey, jsonEncode(cartMap));
      } else {
        await prefs.remove(_cartKey);
      }
    } catch (e) {
      print('Error saving cart: $e');
    }
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

    _saveCart();
    notifyListeners();
    return true; // Berhasil
  }

  void removeItem(String menuId) {
    _items.remove(menuId);
    if (_items.isEmpty) {
      _clearRestaurantInfo();
    }
    _saveCart();
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

    _saveCart();
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _clearRestaurantInfo();
    _saveCart();
    notifyListeners();
  }

  void _clearRestaurantInfo() {
    _restaurantId = null;
    _restaurantName = null;
  }
}
