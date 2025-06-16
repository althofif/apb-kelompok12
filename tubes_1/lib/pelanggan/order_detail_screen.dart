import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'add_review_screen.dart';
import 'cart_screen.dart' as cart;
import 'package:tubes_1/main.dart' show CartScreen;

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({Key? key, required this.orderId}) : super(key: key);

  void _orderAgain(BuildContext context, Map<String, dynamic> orderDetails) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final items = orderDetails['items'] as List<dynamic>? ?? [];
    final restaurantId = orderDetails['restaurantId'] as String?;
    final restaurantName = orderDetails['restaurantName'] as String?;

    if (items.isEmpty || restaurantId == null || restaurantName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat memesan ulang, data tidak lengkap.'),
        ),
      );
      return;
    }

    void addItemsToCart() {
      for (var item in items) {
        final itemData = item as Map<String, dynamic>;
        cart.addItem(
          itemData['menuId'] ?? itemData['name'],
          itemData['price'],
          itemData['name'],
          itemData['imageUrl'] ?? '',
          restaurantId,
          restaurantName,
        );
      }
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (ctx) => const CartScreen()));
    }

    if (cart.items.isNotEmpty && cart.restaurantId != restaurantId) {
      showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: const Text('Ganti Pesanan?'),
              content: const Text(
                'Keranjang Anda berisi item dari restoran lain. Apakah Anda ingin mengosongkan keranjang dan memesan ulang item ini?',
              ),
              actions: [
                TextButton(
                  child: const Text('Tidak'),
                  onPressed: () => Navigator.of(ctx).pop(),
                ),
                ElevatedButton(
                  child: const Text('Ya'),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    cart.clearCart();
                    addItemsToCart();
                  },
                ),
              ],
            ),
      );
    } else {
      addItemsToCart();
    }
  }

  @override
  Widget build(BuildContext context) {
    final DocumentReference orderRef = FirebaseFirestore.instance
        .collection('orders')
        .doc(orderId);

    return FutureBuilder<DocumentSnapshot>(
      future: orderRef.get(),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 60),
                  SizedBox(height: 16),
                  Text("Terjadi kesalahan memuat detail pesanan"),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.done) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 60),
                    SizedBox(height: 16),
                    Text("Pesanan tidak ditemukan"),
                  ],
                ),
              ),
            );
          }

          Map<String, dynamic> orderDetails =
              snapshot.data!.data() as Map<String, dynamic>;
          bool isOrderCompleted = orderDetails['status'] == 'Selesai';

          return Scaffold(
            appBar: AppBar(
              title: Text('Detail Pesanan #${orderId.substring(0, 6)}...'),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 1,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusSection(context, orderDetails),
                  const Divider(height: 32),
                  _buildRestaurantInfo(orderDetails),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Rincian Pesanan'),
                  _buildOrderItemsList(orderDetails),
                  const Divider(height: 24),
                  _buildSectionTitle('Rincian Pembayaran'),
                  _buildPaymentDetails(orderDetails),
                  if (isOrderCompleted) ...[
                    const Divider(height: 32),
                    _buildReviewSection(context, orderDetails, orderId),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomBar(context, orderDetails),
          );
        }

        return Scaffold(
          appBar: AppBar(),
          body: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildStatusSection(
    BuildContext context,
    Map<String, dynamic> orderDetails,
  ) {
    final status = orderDetails['status'] ?? 'N/A';
    final isCompleted = status == 'Selesai';
    final isCancelled = status == 'Dibatalkan';
    final color =
        isCompleted
            ? Colors.green[800]
            : (isCancelled ? Colors.red[800] : Colors.blue[800]);
    final icon =
        isCompleted
            ? Icons.check_circle
            : (isCancelled ? Icons.cancel : Icons.delivery_dining);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: color!.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status', style: TextStyle(color: Colors.grey[700])),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            Icon(icon, color: color, size: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantInfo(Map<String, dynamic> orderDetails) {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Colors.grey[200],
          child: const Icon(Icons.store, color: Colors.grey),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dipesan dari:', style: TextStyle(color: Colors.grey)),
            Text(
              orderDetails['restaurantName'] ?? 'Nama Restoran',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderItemsList(Map<String, dynamic> orderDetails) {
    final items = orderDetails['items'] as List<dynamic>? ?? [];
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (ctx, index) {
        final item = items[index] as Map<String, dynamic>;
        final price = item['price'] ?? 0;
        final quantity = item['quantity'] ?? 0;
        final totalItemPrice = price * quantity;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Text(
                '${item['quantity'] ?? 0}x',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(item['name'] ?? 'Nama Item')),
              Text('Rp ${totalItemPrice.toStringAsFixed(0)}'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentDetails(Map<String, dynamic> orderDetails) {
    return Column(
      children: [
        _buildPaymentRow('Subtotal', orderDetails['subtotal'] ?? 0),
        _buildPaymentRow(
          'Biaya Pengiriman',
          orderDetails['delivery_fee']?.toInt() ?? 0,
        ),
        const Divider(),
        _buildPaymentRow(
          'Total',
          orderDetails['total']?.toInt() ?? 0,
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildPaymentRow(String title, int amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'Rp ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(
    BuildContext context,
    Map<String, dynamic> orderDetails,
    String orderId,
  ) {
    bool reviewGiven = orderDetails['review_given'] ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Ulasan'),
        const SizedBox(height: 8),
        reviewGiven
            ? const Text('Anda sudah memberikan ulasan untuk pesanan ini.')
            : SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (ctx) => AddReviewScreen(orderId: orderId),
                    ),
                  );
                },
                child: const Text('Beri Ulasan'),
              ),
            ),
      ],
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    Map<String, dynamic> orderDetails,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                // Help action
              },
              icon: const Icon(Icons.help_outline),
              label: const Text('Bantuan'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _orderAgain(context, orderDetails),
              icon: const Icon(Icons.replay),
              label: const Text('Pesan Lagi'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
