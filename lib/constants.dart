import 'package:flutter/material.dart';

class AppColors {
  static const primaryGreen = Color(0xFF4CAF50);  // Light green
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
  static const backgroundGrey = Color(0xFFF5F5F5);
}

class AppTextStyles {
  static const heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );
  
  static const heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );
  
  static const heading3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.black,
  );
  
  static const label = TextStyle(
    fontSize: 14,
    color: Colors.grey,
  );
  
  static const body = TextStyle(
    fontSize: 14,
    color: AppColors.black,
  );
}
