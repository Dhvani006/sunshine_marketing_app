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
      print('=== CASHFREE SERVICE DEBUG ===');
      print('Creating order with:');
      print('  orderAmount: $orderAmount');
      print('  customerName: $customerName');
      print('  customerEmail: $customerEmail');
      print('  customerPhone: $customerPhone');
      print('  orderNote: $orderNote');
      
      final requestData = {
        'order_amount': orderAmount,
        'order_currency': 'INR',
        'customer_details': {
          'customer_id': 'customer_${DateTime.now().millisecondsSinceEpoch}',
          'customer_name': customerName,
          'customer_email': customerEmail,
          'customer_phone': customerPhone,
        },
        'order_note': orderNote,
      };
      
      print('Request data: ${json.encode(requestData)}');
      print('URL: $baseUrl/cashfree_order.php');
      print('About to make HTTP POST request...');
      print('===============================');
      
      final response = await http.post(
        Uri.parse('$baseUrl/cashfree_order.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );

      print('=== CASHFREE API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response Body: ${response.body}');
      print('Response Body Length: ${response.body.length}');
      print('Response Body Type: ${response.body.runtimeType}');
      print('=============================');

      if (response.statusCode == 200) {
        print('✅ HTTP 200 received, parsing JSON response...');
        try {
          final responseData = json.decode(response.body);
          print('✅ JSON parsed successfully');
          print('Parsed response type: ${responseData.runtimeType}');
          print('Parsed response keys: ${responseData.keys.toList()}');
          print('✅ Cashfree order created successfully: $responseData');
          return responseData;
        } catch (jsonError) {
          print('❌ JSON parsing failed: $jsonError');
          print('Raw response body: ${response.body}');
          throw Exception('Failed to parse JSON response: $jsonError');
        }
      } else {
        print('❌ Cashfree API failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');
        
        // Try to parse error response
        try {
          final errorData = json.decode(response.body);
          print('Error response parsed: $errorData');
          throw Exception('Cashfree API Error: ${errorData['message'] ?? 'Unknown error'}');
        } catch (parseError) {
          print('Could not parse error response: $parseError');
          throw Exception('Failed to create order: HTTP ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      print('❌ Exception in CashfreeService: $e');
      print('Exception type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');
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
      // ✅ Cashfree expects: https://sandbox.cashfree.com/pg/view/payment/payment_session_id
      // NOT: https://sandbox.cashfree.com/pg/checkout/payment_session_id
      final checkoutUrl = 'https://sandbox.cashfree.com/pg/view/payment/$paymentSessionId';
      
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
