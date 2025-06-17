import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';

class RestaurantMenuScreen extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;

  const RestaurantMenuScreen({
    Key? key,
    required this.restaurantId,
    required this.restaurantName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(restaurantName)),
      body: StreamBuilder<QuerySnapshot>(
        // PERBAIKAN: Query untuk mengambil menu berdasarkan restaurantId
        stream:
            FirebaseFirestore.instance
                .collection('menus')
                .where('restaurantId', isEqualTo: restaurantId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Gagal memuat menu.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Restoran ini belum memiliki menu.'),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final menuItem = MenuItem.fromFirestore(
                snapshot.data!.docs[index],
              );
              return _buildMenuCard(context, menuItem);
            },
          );
        },
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, MenuItem menu) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: menu.imageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.grey[200]),
            errorWidget:
                (context, url, error) => const Icon(Icons.fastfood, size: 40),
          ),
        ),
        title: Text(
          menu.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rp ${menu.price.toStringAsFixed(0)}'),
            if (menu.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  menu.description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_shopping_cart, color: Colors.orange),
          onPressed: () {
            cart.addItem(
              menu.id,
              menu.price,
              menu.name,
              menu.imageUrl,
              menu.restaurantId,
              menu.restaurantName ?? restaurantName,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${menu.name} ditambahkan ke keranjang'),
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
      ),
    );
  }
}
