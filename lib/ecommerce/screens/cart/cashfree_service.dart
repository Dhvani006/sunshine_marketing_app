import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../api_config.dart' as config;

class CashfreeService {
  static const String baseUrl = config.baseUrl;

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
}
