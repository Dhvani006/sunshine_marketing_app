import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_config.dart';

// Platform-aware Cashfree service
class CashfreeService {
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;
  
  // Create order with Cashfree
  static Future<Map<String, dynamic>> createOrder({
    required String orderAmount,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String orderNote,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cashfree_order.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_amount': orderAmount,
          'customer_name': customerName,
          'customer_email': customerEmail,
          'customer_phone': customerPhone,
          'order_note': orderNote,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to create order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating order: $e');
    }
  }

  // Verify order status
  static Future<Map<String, dynamic>> verifyOrder(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cashfree_verify_order.php?order_id=$orderId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to verify order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error verifying order: $e');
    }
  }

  // Get order details
  static Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cashfree_verify_order.php?order_id=$orderId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get order details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting order details: $e');
    }
  }

  // Platform-aware payment method
  static Future<bool> processPayment({
    required String orderId,
    required String paymentSessionId,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    // For now, we'll use web-based approach for all platforms
    // This will open Cashfree payment page in external browser
    debugPrint('Using Cashfree Web Checkout for payment');
    return await _processWebCheckout(
      orderId: orderId,
      paymentSessionId: paymentSessionId,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  // Web checkout payment processing
  static Future<bool> _processWebCheckout({
    required String orderId,
    required String paymentSessionId,
    required Function(String) onSuccess,
    required Function(String) onError,
  }) async {
    try {
      // Cashfree expects: https://test.cashfree.com/pg/checkout/payment_session_id
      // NOT: https://test.cashfree.com/pg/checkout/order_id/payment_session_id
      final checkoutUrl = 'https://test.cashfree.com/pg/checkout/$paymentSessionId';
      
      debugPrint('Opening Cashfree Web Checkout: $checkoutUrl');
      
      // For now, we'll simulate the web checkout process
      // In production, this should open the URL in a browser
      
      // Simulate opening web checkout (remove this in production)
      await Future.delayed(Duration(seconds: 2));
      
      // TODO: Replace this simulation with real web checkout
      // The user should see the actual Cashfree payment page
      // where they can enter card details, UPI, etc.
      
      // For testing purposes only - remove in production
      debugPrint('SIMULATION: User completed payment on Cashfree page');
      onSuccess(orderId);
      return true;
      
    } catch (e) {
      onError('Web checkout error: $e');
      return false;
    }
  }
}
