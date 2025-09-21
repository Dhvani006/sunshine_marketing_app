import 'package:flutter/material.dart';

class AppColors {
  // Colors extracted from the provided website screenshots
  // Header badge/purple
  static const Color purple = Color(0xFF6C63FF);
  // CTA/orange
  static const Color orange = Color(0xFFFF7A00);
  // Banner pink background
  static const Color pink = Color(0xFFE55B8D);
  // Light yellow page background
  static const Color pageBackground = Color(0xFFFFF3CF);
  // Surfaces/cards
  static const Color surface = Colors.white;
  // Text
  static const Color textPrimary = Color(0xFF222222);
  static const Color textSecondary = Color(0xFF6B7280);

  // Gradients (banner and buttons)
  static const LinearGradient bannerGradient = LinearGradient(
    colors: [Color(0xFFEA5B8E), Color(0xFFCF4AB2)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient ctaGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFFFF7A00)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    )
  ];
}