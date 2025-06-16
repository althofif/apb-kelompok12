import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:tubes_1/main.dart' show CartScreen;
import '../providers/cart_provider.dart';

class RestaurantMenuScreen extends StatefulWidget {
  final String restaurantId;
  final String? restaurantName;

  const RestaurantMenuScreen({
    Key? key,
    required this.restaurantId,
    this.restaurantName,
  }) : super(key: key);

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantName ?? 'Menu Restoran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: MenuSearchDelegate());
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('restaurants')
                .doc(widget.restaurantId)
                .collection('menu')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading menu'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final menuItems = snapshot.data!.docs;

          return ListView.builder(
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final menuItem = menuItems[index];
              final data = menuItem.data() as Map<String, dynamic>;

              return MenuItemCard(
                id: menuItem.id,
                name: data['name'] ?? 'No name',
                price: (data['price'] ?? 0).toDouble(),
                imageUrl: data['imageUrl'] ?? '',
                restaurantId: widget.restaurantId,
                restaurantName: widget.restaurantName ?? 'Restoran',
              );
            },
          );
        },
      ),
    );
  }
}

class MenuItemCard extends StatelessWidget {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final String restaurantId;
  final String restaurantName;

  const MenuItemCard({
    Key? key,
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.restaurantId,
    required this.restaurantName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading:
            imageUrl.isNotEmpty
                ? Image.network(
                  imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                )
                : const Icon(Icons.fastfood, size: 40),
        title: Text(name),
        subtitle: Text('Rp ${price.toStringAsFixed(0)}'),
        trailing: IconButton(
          icon: const Icon(Icons.add_shopping_cart),
          onPressed: () {
            cart.addItem(
              id,
              price,
              name,
              imageUrl,
              restaurantId,
              restaurantName,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$name ditambahkan ke keranjang')),
            );
          },
        ),
      ),
    );
  }
}

class MenuSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container(); // Implement search results
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(); // Implement search suggestions
  }
}
