import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as model;

class SellerOrderDetailScreen extends StatefulWidget {
  final String orderId;
  const SellerOrderDetailScreen({Key? key, required this.orderId})
    : super(key: key);

  @override
  _SellerOrderDetailScreenState createState() =>
      _SellerOrderDetailScreenState();
}

class _SellerOrderDetailScreenState extends State<SellerOrderDetailScreen> {
  bool _isLoading = false;

  Future<void> _updateOrderStatus(
    String newStatus,
    List<model.OrderItem> items,
  ) async {
    setState(() => _isLoading = true);
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 1. Update order status
      final orderRef = FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId);
      batch.update(orderRef, {'status': newStatus});

      // 2. If order is being prepared, update sold count for each menu item
      if (newStatus == 'Disiapkan') {
        for (var item in items) {
          final menuRef = FirebaseFirestore.instance
              .collection('menus')
              .doc(item.menuItemId);
          batch.update(menuRef, {
            'popularity': FieldValue.increment(item.quantity),
          });
        }
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status pesanan diperbarui menjadi "$newStatus"'),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memperbarui status: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('orders')
              .doc(widget.orderId)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        if (!snapshot.data!.exists)
          return const Scaffold(
            body: Center(child: Text('Pesanan tidak ditemukan.')),
          );

        final order = model.Order.fromFirestore(snapshot.data!);

        return Scaffold(
          appBar: AppBar(
            title: Text('Detail Pesanan #${order.id.substring(0, 6)}'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Section
                Text(
                  "Status: ${order.status}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Items Section
                const Text(
                  "Item Pesanan",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Divider(),
                ...order.items
                    .map(
                      (item) => ListTile(
                        title: Text(item.name),
                        leading: Text('${item.quantity}x'),
                        trailing: Text('Rp ${item.price.toStringAsFixed(0)}'),
                      ),
                    )
                    .toList(),

                const Divider(),
                // Total Section
                ListTile(
                  title: const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    'Rp ${order.totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildActionButtons(order),
        );
      },
    );
  }

  Widget _buildActionButtons(model.Order order) {
    if (_isLoading)
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );

    Widget button;
    switch (order.status) {
      case 'Menunggu Konfirmasi':
        button = ElevatedButton(
          onPressed: () => _updateOrderStatus('Disiapkan', order.items),
          child: const Text('Terima & Siapkan Pesanan'),
        );
        break;
      case 'Disiapkan':
        button = ElevatedButton(
          onPressed: () => _updateOrderStatus('Siap Diambil', order.items),
          child: const Text('Pesanan Siap Diambil'),
        );
        break;
      default:
        button = Text(
          'Status: ${order.status}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(width: double.infinity, child: button),
    );
  }
}
