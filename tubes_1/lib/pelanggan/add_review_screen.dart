import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddReviewScreen extends StatefulWidget {
  final String orderId;
  const AddReviewScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _AddReviewScreenState createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  double _rating = 0;
  final _reviewController = TextEditingController();
  bool _isLoading = false;
  String _restaurantName = 'Memuat...';
  String? _restaurantImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchOrderData();
  }

  Future<void> _fetchOrderData() async {
    try {
      final orderDoc =
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(widget.orderId)
              .get();

      if (mounted && orderDoc.exists) {
        setState(() {
          _restaurantName = orderDoc.data()?['restaurantName'] ?? 'Restoran';
          final restaurantId = orderDoc.data()?['restaurantId'];
          if (restaurantId != null) {
            _fetchRestaurantImage(restaurantId);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _restaurantName = 'Gagal memuat';
        });
      }
    }
  }

  Future<void> _fetchRestaurantImage(String restaurantId) async {
    try {
      final restaurantDoc =
          await FirebaseFirestore.instance
              .collection('restaurants')
              .doc(restaurantId)
              .get();

      if (mounted && restaurantDoc.exists) {
        setState(() {
          _restaurantImageUrl = restaurantDoc.data()?['imageUrl'];
        });
      }
    } catch (e) {
      print('Error fetching restaurant image: $e');
    }
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap berikan rating bintang.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final orderRef = FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId);

      final orderSnapshot = await orderRef.get();
      final orderData = orderSnapshot.data();

      if (orderData != null && user != null) {
        final restaurantId = orderData['restaurantId'];

        await FirebaseFirestore.instance.collection('reviews').add({
          'orderId': widget.orderId,
          'restaurantId': restaurantId,
          'userId': user.uid,
          'userName': user.displayName ?? 'Anonim',
          'rating': _rating,
          'reviewText': _reviewController.text,
          'createdAt': FieldValue.serverTimestamp(),
          'restaurantName': _restaurantName,
        });

        await orderRef.update({'review_given': true});

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Terima kasih atas ulasan Anda!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim ulasan. Coba lagi.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Beri Ulasan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_restaurantImageUrl != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(_restaurantImageUrl!),
              ),
            const SizedBox(height: 16),
            Text(
              _restaurantName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Bagaimana pengalaman Anda?',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = (index + 1).toDouble();
                    });
                  },
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 40,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _reviewController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Tulis ulasan Anda di sini...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 30),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitReview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'KIRIM ULASAN',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }
}
