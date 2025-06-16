import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/fcm_notification_service.dart';
import '../pelanggan/customer_home_screen.dart';
import '../penjual/seller_home_screen.dart';
import '../driver/driver_home_screen.dart';
import '../models/user_role.dart';

enum AuthMode { Login, Register }

class AuthScreen extends StatefulWidget {
  final UserRole role;
  const AuthScreen({Key? key, required this.role}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _authService = AuthService();
  final _fcmService = FcmNotificationService();

  AuthMode _authMode = AuthMode.Login;
  bool _isLoading = false;
  String? _errorMessage;

  String _getRoleText() {
    return widget.role.toString().split('.').last;
  }

  Widget _getHomeScreen() {
    switch (widget.role) {
      case UserRole.Pelanggan:
        return const CustomerHomeScreen();
      case UserRole.Penjual:
        return const SellerHomeScreen();
      case UserRole.Driver:
        return const DriverHomeScreen();
    }
  }

  Future<void> _saveUserToken(User user) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        _fcmService.saveTokenToDatabase(token, user.uid);
      }
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      User? user;
      if (_authMode == AuthMode.Login) {
        final userCredential = await _authService.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
        user = userCredential?.user;
      } else {
        final userCredential = await _authService.registerWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
        user = userCredential?.user;

        if (user != null) {
          await DatabaseService(uid: user.uid).updateUserData(
            _nameController.text,
            _emailController.text,
            _getRoleText(),
          );
        }
      }

      if (user != null) {
        await _saveUserToken(user);
        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => _getHomeScreen()),
          (route) => false,
        );
      } else {
        setState(() {
          _errorMessage = 'Autentikasi gagal. Silakan coba lagi.';
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan. Silakan coba lagi.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Email tidak valid';
      case 'user-disabled':
        return 'Akun dinonaktifkan';
      case 'user-not-found':
        return 'Akun tidak ditemukan';
      case 'wrong-password':
        return 'Password salah';
      case 'email-already-in-use':
        return 'Email sudah terdaftar';
      case 'weak-password':
        return 'Password terlalu lemah';
      default:
        return 'Terjadi kesalahan: ${e.message}';
    }
  }

  void _switchAuthMode() {
    setState(() {
      _authMode =
          _authMode == AuthMode.Login ? AuthMode.Register : AuthMode.Login;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF38B6FF), Color(0xFF00A9FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_authMode == AuthMode.Login ? 'Login' : 'Daftar'} sebagai ${_getRoleText()}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (_authMode == AuthMode.Register)
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Lengkap',
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator:
                                (value) =>
                                    value!.isEmpty
                                        ? 'Harap isi nama lengkap'
                                        : null,
                          ),

                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator:
                              (value) =>
                                  value!.isEmpty || !value.contains('@')
                                      ? 'Masukkan email yang valid'
                                      : null,
                        ),

                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                          validator:
                              (value) =>
                                  value!.length < 6
                                      ? 'Password minimal 6 karakter'
                                      : null,
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 15),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],

                        const SizedBox(height: 25),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                _authMode == AuthMode.Login
                                    ? 'LOGIN'
                                    : 'DAFTAR',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),

                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: _switchAuthMode,
                          child: Text(
                            _authMode == AuthMode.Login
                                ? 'Belum punya akun? Daftar disini'
                                : 'Sudah punya akun? Login disini',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
