import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../wrapper.dart';
import '../providers/cart_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/order_provider.dart';
import '../providers/restaurant_image_provider.dart';
import '../providers/user_profile_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize theme provider
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      await themeProvider.initializeTheme();

      // Initialize cart provider
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.initializeCart();

      // Reset upload states for image providers
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.resetUploadState();

      final restaurantImageProvider = Provider.of<RestaurantImageProvider>(
        context,
        listen: false,
      );
      restaurantImageProvider.resetUploadState();

      final userProfileProvider = Provider.of<UserProfileProvider>(
        context,
        listen: false,
      );
      userProfileProvider.resetUploadState();

      // Wait for minimum splash duration (3 seconds)
      await Future.delayed(const Duration(seconds: 3));

      // Navigate to main app after initialization
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Wrapper()),
        );
      }
    } catch (e) {
      print('Error initializing app: $e');

      // Still navigate after delay even if there's an error
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Wrapper()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF38B6FF), Color(0xFF00A9FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.restaurant_menu,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),

            // App Name
            const Text(
              'Dapoer Kita',
              style: TextStyle(
                fontFamily: 'Pacifico',
                fontSize: 48,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(2, 2),
                    blurRadius: 4,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Tagline
            Text(
              'Connecting You to Great Food',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 60),

            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),

            // Loading Text
            Text(
              'Initializing...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
