// penjual/seller_order_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SellerOrderDetailScreen extends StatefulWidget {
  final String orderId;
  const SellerOrderDetailScreen({Key? key, required this.orderId})
    : super(key: key);

  @override
  _SellerOrderDetailScreenState createState() =>
      _SellerOrderDetailScreenState();
}

class _SellerOrderDetailScreenState extends State<SellerOrderDetailScreen> {
  late Stream<DocumentSnapshot> _orderStream;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _orderStream =
        FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .snapshots();
  }

  Future<void> _updateOrderStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({'status': newStatus});

      // Update sold count for each menu item
      final orderDoc =
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(widget.orderId)
              .get();

      if (orderDoc.exists) {
        final orderData = orderDoc.data() as Map<String, dynamic>;
        final items = orderData['items'] as List<dynamic>? ?? [];

        for (var item in items) {
          final itemData = item as Map<String, dynamic>;
          final menuId = itemData['menuId'] as String?;
          final quantity = (itemData['quantity'] ?? 1) as int;

          if (menuId != null) {
            await FirebaseFirestore.instance
                .collection('menus')
                .doc(menuId)
                .update({
                  'soldCount': FieldValue.increment(quantity),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status pesanan diperbarui menjadi "$newStatus"'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memperbarui status: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildCustomerInfo(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Info Pelanggan'),
        const SizedBox(height: 8),
        Text(
          'Nama: ${data['customerName'] ?? 'Tanpa Nama'}',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          'Waktu Pesan: ${data['createdAt']?.toDate().toString() ?? 'N/A'}',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          'Status: ${data['status'] ?? 'N/A'}',
          style: TextStyle(
            fontSize: 16,
            color: _getStatusColor(data['status']),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Baru':
        return Colors.red;
      case 'Disiapkan':
        return Colors.blue;
      case 'Siap Diambil':
        return Colors.green;
      case 'Diantar':
        return Colors.orange;
      case 'Selesai':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrderItemsList(Map<String, dynamic> data) {
    final items = data['items'] as List<dynamic>? ?? [];
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i] as Map<String, dynamic>;
        final bool hasNotes = item['notes'] != null && item['notes'].isNotEmpty;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['quantity'] ?? 0}x ${item['name'] ?? 'Tanpa Nama'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Rp ${item['price']?.toStringAsFixed(0) ?? '0'}',
                  style: const TextStyle(color: Colors.grey),
                ),
                if (hasNotes)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Catatan: ${item['notes']}',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalSection(Map<String, dynamic> data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(fontSize: 16)),
                Text(
                  'Rp ${data['subtotal']?.toStringAsFixed(0) ?? 0}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Biaya Pengiriman', style: TextStyle(fontSize: 16)),
                Text(
                  'Rp ${data['deliveryFee']?.toStringAsFixed(0) ?? 0}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Rp ${data['total']?.toStringAsFixed(0) ?? 0}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> data) {
    final status = data['status'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status == 'Baru')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _updateOrderStatus('Disiapkan'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Terima Pesanan'),
                      ),
                    ),
                  if (status == 'Disiapkan')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _updateOrderStatus('Siap Diambil'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Pesanan Siap Diambil'),
                      ),
                    ),
                  if (status == 'Siap Diambil')
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Menunggu driver mengambil pesanan...',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  if (status == 'Diantar' || status == 'Selesai')
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Pesanan sedang diantar oleh driver.',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                ],
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _orderStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Gagal memuat detail pesanan.')),
          );
        }

        final orderDetails = snapshot.data!.data() as Map<String, dynamic>;

        return Scaffold(
          appBar: AppBar(
            title: Text('Pesanan #${widget.orderId.substring(0, 6)}...'),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCustomerInfo(orderDetails),
                const Divider(height: 32),
                _buildSectionTitle('Rincian Pesanan'),
                const SizedBox(height: 8),
                _buildOrderItemsList(orderDetails),
                const Divider(height: 32),
                _buildSectionTitle('Total Pembayaran'),
                const SizedBox(height: 8),
                _buildTotalSection(orderDetails),
              ],
            ),
          ),
          bottomNavigationBar: _buildActionButtons(context, orderDetails),
        );
      },
    );
  }
}
