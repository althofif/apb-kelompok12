import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/restaurant_model.dart';
import '../models/menu_item.dart';
import 'restaurant_menu_screen.dart';

class SearchResultScreen extends StatefulWidget {
  final String query;
  const SearchResultScreen({Key? key, required this.query}) : super(key: key);

  @override
  _SearchResultScreenState createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  late Future<List<dynamic>> _searchFuture;

  @override
  void initState() {
    super.initState();
    _searchFuture = _performSearch();
  }

  Future<List<dynamic>> _performSearch() async {
    final String queryLower = widget.query.toLowerCase();

    // Search for restaurants
    final restaurantQuery = FirebaseFirestore.instance
        .collection('restaurants')
        .where('keywords', arrayContains: queryLower);

    // Search for menus
    final menuQuery = FirebaseFirestore.instance
        .collection('menus')
        .where('keywords', arrayContains: queryLower);

    final restaurantResults = await restaurantQuery.get();
    final menuResults = await menuQuery.get();

    final List<RestaurantModel> restaurants =
        restaurantResults.docs
            .map((doc) => RestaurantModel.fromFirestore(doc))
            .toList();
    final List<MenuItem> menus =
        menuResults.docs.map((doc) => MenuItem.fromFirestore(doc)).toList();

    return [restaurants, menus];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hasil untuk "${widget.query}"')),
      body: FutureBuilder<List<dynamic>>(
        future: _searchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Terjadi kesalahan saat mencari.'));
          }
          if (!snapshot.hasData ||
              (snapshot.data![0].isEmpty && snapshot.data![1].isEmpty)) {
            return const Center(child: Text('Tidak ada hasil yang ditemukan.'));
          }

          final List<RestaurantModel> restaurants = snapshot.data![0];
          final List<MenuItem> menus = snapshot.data![1];

          return ListView(
            children: [
              if (restaurants.isNotEmpty) ...[
                _buildSectionHeader('Restoran Ditemukan'),
                ...restaurants
                    .map((resto) => _buildRestaurantTile(context, resto))
                    .toList(),
              ],
              if (menus.isNotEmpty) ...[
                _buildSectionHeader('Menu Ditemukan'),
                ...menus.map((menu) => _buildMenuTile(context, menu)).toList(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRestaurantTile(
    BuildContext context,
    RestaurantModel restaurant,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            restaurant.imageUrl != null
                ? CachedNetworkImageProvider(restaurant.imageUrl!)
                : null,
      ),
      title: Text(restaurant.name),
      subtitle: Text(restaurant.category),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => RestaurantMenuScreen(
                  restaurantId: restaurant.id,
                  restaurantName: restaurant.name,
                ),
          ),
        );
      },
    );
  }

  Widget _buildMenuTile(BuildContext context, MenuItem menu) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(menu.imageUrl),
      ),
      title: Text(menu.name),
      subtitle: Text('Rp ${menu.price.toStringAsFixed(0)}'),
      onTap: () {
        // Navigasi ke halaman restoran dari menu yang ditemukan
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => RestaurantMenuScreen(
                  restaurantId: menu.restaurantId,
                  restaurantName:
                      "Nama Restoran", // Anda perlu mengambil nama resto dari ID
                ),
          ),
        );
      },
    );
  }
}
