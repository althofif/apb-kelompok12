// providers/favorite_provider.dart
import 'package:flutter/material.dart';

class FavoriteProvider with ChangeNotifier {
  final List<String> _favoriteRestaurantIds = [];

  List<String> get favoriteRestaurantIds => _favoriteRestaurantIds;

  bool isFavorite(String restaurantId) {
    return _favoriteRestaurantIds.contains(restaurantId);
  }

  void toggleFavorite(String restaurantId) {
    if (isFavorite(restaurantId)) {
      _favoriteRestaurantIds.remove(restaurantId);
    } else {
      _favoriteRestaurantIds.add(restaurantId);
    }
    notifyListeners();
  }
}
