import 'package:flutter/material.dart';

class AppColors {
  // Primary gradient colors from website
  static const Color gradientStart = Color(0xFFFF6B35); // Orange
  static const Color gradientEnd = Color(0xFF9B59B6);   // Purple
  
  // Primary colors
  static const Color primary = Color(0xFF9B59B6);       // Purple
  static const Color accent = Color(0xFFFF6B35);        // Orange
  static const Color background = Color(0xFFF8F9FA);    // Light gray
  
  // Text colors
  static const Color textPrimary = Color(0xFF2D3436);   // Dark gray
  static const Color textSecondary = Color(0xFF636E72); // Medium gray
  static const Color textWhite = Colors.white;
  
  // Card and surface colors
  static const Color cardBackground = Colors.white;
  static const Color surfaceColor = Color(0xFFF1F2F6);
  
  // Status colors
  static const Color error = Color(0xFFE74C3C);
  static const Color success = Color(0xFF00B894);
  static const Color warning = Color(0xFFF39C12);
  
  // Button colors
  static const Color buttonPrimary = Color(0xFF9B59B6);
  static const Color buttonSecondary = Color(0xFFFF6B35);
  
  // Shimmer colors
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  
  // Gradient definitions
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient headerGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}