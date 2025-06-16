// penjual/seller_payment_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellerPaymentSettingsScreen extends StatefulWidget {
  const SellerPaymentSettingsScreen({Key? key}) : super(key: key);

  @override
  _SellerPaymentSettingsScreenState createState() =>
      _SellerPaymentSettingsScreenState();
}

class _SellerPaymentSettingsScreenState
    extends State<SellerPaymentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  final _bankNameController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _accountNumberController = TextEditingController();

  bool _isLoading = false;
  bool _isFetching = true;

  @override
  void initState() {
    super.initState();
    _fetchPaymentData();
  }

  Future<void> _fetchPaymentData() async {
    if (_currentUser != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('restaurants')
              .doc(_currentUser.uid)
              .get();
      if (mounted && doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final paymentData = data['paymentInfo'] as Map<String, dynamic>?;
        if (paymentData != null) {
          setState(() {
            _bankNameController.text = paymentData['bankName'] ?? '';
            _accountHolderController.text = paymentData['accountHolder'] ?? '';
            _accountNumberController.text = paymentData['accountNumber'] ?? '';
          });
        }
      }
    }
    setState(() => _isFetching = false);
  }

  Future<void> _savePaymentInfo() async {
    if (_formKey.currentState!.validate() && _currentUser != null) {
      setState(() => _isLoading = true);
      try {
        final paymentData = {
          'bankName': _bankNameController.text,
          'accountHolder': _accountHolderController.text,
          'accountNumber': _accountNumberController.text,
        };

        await FirebaseFirestore.instance
            .collection('restaurants')
            .doc(_currentUser.uid)
            .set({'paymentInfo': paymentData}, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Informasi pembayaran diperbarui!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menyimpan data: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Pembayaran'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body:
          _isFetching
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    TextFormField(
                      controller: _bankNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Bank',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _accountHolderController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Pemilik Rekening',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _accountNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Rekening',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Wajib diisi';
                        if (v.length < 8) return 'Minimal 8 digit';
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      ElevatedButton(
                        onPressed: _savePaymentInfo,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('SIMPAN INFORMASI'),
                      ),
                  ],
                ),
              ),
    );
  }
}
