import 'package:flutter/material.dart';

/// Centralized text styles for the Camalingo app to ensure
/// consistent typography across all UI components.
class AppTextStyles {
  /// Large heading style (24px, bold), used for primary titles.
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
  /// Secondary heading style (20px, bold), used for section titles.
  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  /// Label style (16px, medium), used for form labels and small headings.
  static const TextStyle label = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  /// Body text style (14px, normal), used for general content and descriptions.
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );
}
