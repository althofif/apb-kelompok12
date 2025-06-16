import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/cart_provider.dart';
import 'order_success_screen.dart';
import 'address_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const CheckoutScreen({
    Key? key,
    required this.restaurantId,
    required this.restaurantName,
  }) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedPaymentMethod = 1;
  bool _isLoading = false;
  Map<String, dynamic>? _selectedAddress;

  Future<void> _createOrder(CartProvider cart) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus login untuk membuat pesanan')),
      );
      return;
    }

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih alamat pengiriman')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final restaurantDoc =
          await FirebaseFirestore.instance
              .collection('restaurants')
              .doc(widget.restaurantId)
              .get();

      final restaurantData = restaurantDoc.data();
      final restaurantAddress =
          restaurantData?['address'] ?? 'Alamat tidak tersedia';

      final orderData = {
        'userId': user.uid,
        'customerName': user.displayName ?? 'Pelanggan',
        'restaurantId': widget.restaurantId,
        'restaurantName': widget.restaurantName,
        'deliveryAddress': _selectedAddress!['address'],
        'deliveryAddressLabel': _selectedAddress!['label'],
        'deliveryNotes': _selectedAddress!['notes'] ?? '',
        'items':
            cart.items.values
                .map(
                  (item) => {
                    'menuId': item.id,
                    'name': item.name,
                    'quantity': item.quantity,
                    'price': item.price,
                    'imageUrl': item.imageUrl,
                  },
                )
                .toList(),
        'subtotal': cart.totalAmount,
        'delivery_fee': 10000.0,
        'total': cart.totalAmount + 10000.0,
        'status': 'Menunggu Konfirmasi',
        'paymentMethod': _selectedPaymentMethod == 1 ? 'COD' : 'E-Wallet',
        'createdAt': FieldValue.serverTimestamp(),
        'review_given': false,
        'restaurantAddress': restaurantAddress,
        'date': DateTime.now().toString(),
      };

      await FirebaseFirestore.instance.collection('orders').add(orderData);
      cart.clearCart();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const OrderSuccessScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat pesanan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showOrderConfirmationDialog(CartProvider cart) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Konfirmasi Pesanan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Apakah Anda yakin ingin membuat pesanan ini?'),
                const SizedBox(height: 16),
                Text(
                  'Total: Rp ${(cart.totalAmount + 10000).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _createOrder(cart);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Ya, Buat Pesanan'),
              ),
            ],
          ),
    );
  }

  Future<void> _selectAddress() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (ctx) => const AddressScreen(isSelectionMode: true),
      ),
    );

    if (result != null) {
      setState(() => _selectedAddress = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final total = cart.totalAmount + 10000.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Alamat Pengiriman'),
              _buildAddressCard(),
              const SizedBox(height: 24),
              _buildSectionTitle('Ringkasan Pesanan'),
              ...cart.items.values.map((item) => _buildOrderItem(item)),
              const Divider(),
              _buildOrderSummaryItem(
                'Subtotal',
                'Rp ${cart.totalAmount.toStringAsFixed(0)}',
              ),
              _buildOrderSummaryItem('Biaya Pengiriman', 'Rp 10,000'),
              const Divider(),
              _buildOrderSummaryItem(
                'Total Pembayaran',
                'Rp ${total.toStringAsFixed(0)}',
                isTotal: true,
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Metode Pembayaran'),
              _buildPaymentMethodTile('Bayar di Tempat (COD)', Icons.money, 1),
              _buildPaymentMethodTile(
                'GoPay / E-Wallet',
                Icons.account_balance_wallet,
                2,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomCheckoutBar(cart, total),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        onTap: _selectAddress,
        leading: Icon(
          _selectedAddress == null
              ? Icons.add_location_alt_outlined
              : Icons.location_on,
          color: Colors.green,
        ),
        title: Text(
          _selectedAddress == null
              ? 'Pilih Alamat Pengiriman'
              : _selectedAddress!['label'],
          style: TextStyle(
            fontWeight: _selectedAddress == null ? null : FontWeight.bold,
          ),
        ),
        subtitle:
            _selectedAddress == null
                ? null
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedAddress!['address']),
                    if (_selectedAddress!['notes'] != null &&
                        _selectedAddress!['notes'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Catatan: ${_selectedAddress!['notes']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
        trailing: Icon(
          _selectedAddress == null
              ? Icons.arrow_forward_ios
              : Icons.edit_outlined,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildOrderItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl:
                  item.imageUrl.isNotEmpty
                      ? item.imageUrl
                      : 'https://via.placeholder.com/150',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[200]),
              errorWidget:
                  (context, url, error) => Icon(Icons.fastfood, size: 40),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('${item.quantity}x Rp ${item.price}'),
              ],
            ),
          ),
          Text('Rp ${(item.price * item.quantity).toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryItem(
    String name,
    String price, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            price,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodTile(String name, IconData icon, int value) {
    bool isSelected = _selectedPaymentMethod == value;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? Colors.green : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: () => setState(() => _selectedPaymentMethod = value),
        leading: Icon(icon, color: isSelected ? Colors.green : Colors.grey),
        title: Text(name),
        trailing:
            isSelected
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
      ),
    );
  }

  Widget _buildBottomCheckoutBar(CartProvider cart, double total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(color: Colors.grey),
              ),
              Text(
                'Rp ${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          if (_isLoading)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              onPressed:
                  cart.items.isEmpty || _selectedAddress == null
                      ? null
                      : () => _showOrderConfirmationDialog(cart),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Buat Pesanan'),
            ),
        ],
      ),
    );
  }
}
