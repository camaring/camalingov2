import 'package:flutter/material.dart';

/// Application color palette constants.
/// 
/// Defines the primary and neutral colors used throughout the app.
class AppColors {
  /// Primary accent color (light green) used for buttons and highlights.
  static const primaryGreen = Color(0xFF4CAF50);
  /// Standard black color for primary text and icons.
  static const black = Color(0xFF000000);
  /// Pure white color for backgrounds and text contrast.
  static const white = Color(0xFFFFFFFF);
  /// Light grey background color for scaffold and cards.
  static const backgroundGrey = Color(0xFFF5F5F5);
}

/// Predefined text styles used throughout the application.
/// 
/// Ensures consistent typography for headings, labels, and body text.
class AppTextStyles {
  /// Heading1 style: large, bold text for primary titles.
  static const heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );
  
  /// Heading2 style: slightly smaller bold text for section titles.
  static const heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );
  
  /// Heading3 style: medium bold text for subheadings.
  static const heading3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );
  
  /// Label style: smaller grey text for field labels and hints.
  static const label = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );
  
  /// Body text style: standard size and color for paragraph content.
  static const body = TextStyle(
    fontSize: 14,
    color: AppColors.black,
  );
}
