import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'providers/cart_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/order_provider.dart';
import 'providers/restaurant_image_provider.dart';
import 'providers/user_profile_provider.dart';
import 'providers/favorite_provider.dart';
import 'screens/splash_screen.dart';
import 'services/fcm_notification_service.dart';
import 'pelanggan/cart_screen.dart';
import 'utils/app_constants.dart';
import 'wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inisialisasi FCM dan Lokalisasi
  if (Firebase.apps.isNotEmpty) {
    await FcmNotificationService().initialize();
  }
  await initializeDateFormatting('id_ID', null);

  runApp(const DapoerKitaApp());
}

class DapoerKitaApp extends StatelessWidget {
  const DapoerKitaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => CartProvider()),
        ChangeNotifierProvider(create: (ctx) => ThemeProvider()),
        ChangeNotifierProvider(create: (ctx) => OrderProvider()),
        ChangeNotifierProvider(create: (ctx) => RestaurantImageProvider()),
        ChangeNotifierProvider(create: (ctx) => UserProfileProvider()),
        ChangeNotifierProvider(create: (ctx) => FavoriteProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Dapoer Kita',
            themeMode: themeProvider.themeMode,

            // Konfigurasi Lokalisasi
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('id', 'ID'), // Bahasa Indonesia
            ],
            locale: const Locale('id', 'ID'),

            theme: ThemeData(
              useMaterial3: true,
              fontFamily: 'Poppins',
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppConstants.primaryColor,
                primary: AppConstants.primaryColor,
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: AppConstants.backgroundColor,
              appBarTheme: const AppBarTheme(
                backgroundColor: AppConstants.cardColor,
                elevation: 1,
                iconTheme: IconThemeData(color: AppConstants.textColor),
                titleTextStyle: AppConstants.kHeadline2,
              ),
              cardTheme: CardTheme(
                elevation: 2,
                color: AppConstants.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.kRadiusL),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.kRadiusM),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 24,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              fontFamily: 'Poppins',
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppConstants.primaryLightColor,
                primary: AppConstants.primaryLightColor,
                brightness: Brightness.dark,
              ),
            ),
            debugShowCheckedModeBanner: false,
            home: const SplashScreen(),
            routes: {
              '/wrapper': (context) => const Wrapper(),
              '/cart': (context) => const CartScreen(),
            },
          );
        },
      ),
    );
  }
}
