import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/cart_provider.dart';
import '../models/order.dart' as ord;
import 'order_success_screen.dart';
import '/screens/address_screen.dart'; // Import layar alamat yang baru

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
  final double _deliveryFee = 10000.0;

  Future<void> _createOrder(CartProvider cart) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Anda harus login.')));
      return;
    }
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap pilih alamat pengiriman.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final orderItems =
          cart.items.values
              .map(
                (cartItem) => ord.OrderItem(
                  menuItemId: cartItem.id,
                  name: cartItem.name,
                  price: cartItem.price,
                  quantity: cartItem.quantity,
                  imageUrl: cartItem.imageUrl,
                ),
              )
              .toList();

      final newOrder =
          ord.Order(
              id: '', // Akan digenerate oleh Firestore
              customerId: user.uid,
              restaurantId: widget.restaurantId,
              items: orderItems,
              totalAmount: cart.totalAmount + _deliveryFee,
              status: 'Menunggu Konfirmasi',
              orderTime: Timestamp.now(),
              // Menyimpan detail alamat langsung di pesanan
              deliveryLocation:
                  null, // Anda bisa menambahkan GeoPoint di sini jika perlu
            ).toFirestore()
            ..addAll({
              'customerName': user.displayName ?? 'Pelanggan',
              'deliveryAddress': _selectedAddress!['address'],
              'deliveryAddressLabel': _selectedAddress!['label'],
              'deliveryNotes': _selectedAddress!['notes'] ?? '',
              'restaurantName': widget.restaurantName,
              'paymentMethod': _selectedPaymentMethod == 1 ? 'COD' : 'E-Wallet',
              'delivery_fee': _deliveryFee,
              'subtotal': cart.totalAmount,
            });

      await FirebaseFirestore.instance.collection('orders').add(newOrder);
      cart.clearCart();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const OrderSuccessScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat pesanan: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- PERUBAHAN DI SINI ---
  Future<void> _selectAddress() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (ctx) => const AddressScreen(isSelectionMode: true),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedAddress = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final total = cart.totalAmount + _deliveryFee;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Alamat Pengiriman'),
            _buildAddressCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('Ringkasan Pesanan'),
            // ... (Sisa UI sama seperti sebelumnya) ...
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomCheckoutBar(cart),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Widget _buildAddressCard diperbarui untuk menampilkan alamat yang dipilih
  Widget _buildAddressCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: _selectAddress,
        leading: Icon(
          Icons.location_on_outlined,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(
          _selectedAddress?['label'] ?? 'Pilih Alamat',
          style: TextStyle(
            fontWeight:
                _selectedAddress != null ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          _selectedAddress?['address'] ??
              'Ketuk untuk memilih alamat pengiriman Anda',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  // Widget _buildBottomCheckoutBar diperbarui
  Widget _buildBottomCheckoutBar(CartProvider cart) {
    final total = cart.totalAmount + _deliveryFee;
    return Padding(
      padding: const EdgeInsets.all(16),
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                onPressed:
                    cart.items.isEmpty || _selectedAddress == null
                        ? null
                        : () => _createOrder(cart),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('BUAT PESANAN (Rp ${total.toStringAsFixed(0)})'),
              ),
    );
  }
}
