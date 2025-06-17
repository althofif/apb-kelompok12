import 'package:flutter/material.dart';

// Kelas ini berisi semua nilai konstan yang digunakan di seluruh aplikasi.
class AppConstants {
  // Palet Warna Utama
  static const Color primaryColor = Color(0xFF2E7D32); // Green 800
  static const Color primaryLightColor = Color(0xFF66BB6A); // Green 400
  static const Color accentColor = Color(0xFFFF9800); // Orange
  static const Color textColor = Color(0xFF333333);
  static const Color subtextColor = Color(0xFF757575);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;

  // Padding & Spacing
  static const double kPaddingS = 8.0;
  static const double kPaddingM = 16.0;
  static const double kPaddingL = 24.0;
  static const double kPaddingXL = 32.0;

  // Border Radius
  static const double kRadiusS = 4.0;
  static const double kRadiusM = 8.0;
  static const double kRadiusL = 16.0;

  // Text Styles
  static const TextStyle kHeadline1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle kHeadline2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle kBodyText = TextStyle(fontSize: 16, color: textColor);

  static const TextStyle kSubtext = TextStyle(
    fontSize: 14,
    color: subtextColor,
  );
}
