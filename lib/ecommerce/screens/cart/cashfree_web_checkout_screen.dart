import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../../api_config.dart' as ApiConfig;

class CashfreeWebCheckoutScreen extends StatefulWidget {
  final String orderId;
  final String paymentSessionId;

  const CashfreeWebCheckoutScreen({
    Key? key,
    required this.orderId,
    required this.paymentSessionId,
  }) : super(key: key);

  @override
  State<CashfreeWebCheckoutScreen> createState() => _CashfreeWebCheckoutScreenState();
}

class _CashfreeWebCheckoutScreenState extends State<CashfreeWebCheckoutScreen> {
  bool _isLoading = false;
  bool _paymentCompleted = false;
  String? _errorMessage;
  String? _paymentSessionId;
  Map<String, dynamic>? _cashfreeData;

  @override
  void initState() {
    super.initState();
    _paymentSessionId = widget.paymentSessionId;
    print('=== CASHFREE WEB CHECKOUT INITIALIZED ===');
    print('Order ID: ${widget.orderId}');
    print('Payment Session ID: ${widget.paymentSessionId}');
    print('==============================');
  }

  /// Start payment using Custom Checkout Page with JavaScript SDK
  Future<void> _startCashfreePayment(String orderId, String paymentSessionId) async {
    try {
      print('=== STARTING CASHFREE PAYMENT WITH CUSTOM CHECKOUT ===');
      print('Order ID: $orderId');
      print('Payment Session ID: $paymentSessionId');
      
      // Store session ID for tracking
      _paymentSessionId = paymentSessionId;
      
      // ✅ Use your custom checkout page with JavaScript SDK
      final checkoutUrl = 'http://192.168.56.69/sunshine_marketing_app_backend/cashfree_checkout.html?order_id=$orderId&payment_session_id=$paymentSessionId';

      
      print('✅ Custom Checkout URL: $checkoutUrl');
      print('✅ Opening custom payment page with JavaScript SDK...');
      
      // ✅ Use LaunchMode.externalApplication to open in external browser
      final Uri uri = Uri.parse(checkoutUrl);
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        print('✅ Custom payment page opened successfully');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment page opened! Complete payment and return to app.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
        
        // Add a button to return to order success screen
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('After completing payment, tap "Return to App" below'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 8),
                action: SnackBarAction(
                  label: 'Return to App',
                  textColor: Colors.white,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            );
          }
        });
        
        // Set payment as in progress
        setState(() {
          _isLoading = false;
        });
        
      } else {
        throw Exception('Could not open custom payment page');
      }
      
    } catch (e) {
      print('❌ Payment error: $e');
      setState(() {
        _errorMessage = 'Payment failed: $e';
      });
    }
  }

  /// Verify payment with Cashfree using backend (same as website)
  Future<void> _verifyPaymentWithCashfree() async {
    try {
      print('=== VERIFYING PAYMENT WITH BACKEND ===');
      print('Order ID: ${widget.orderId}');
      
      // ✅ Use query parameter API call (same as website)
      final response = await http.get(
        Uri.parse('${ApiConfig.verifyOrderUrl}?order_id=${widget.orderId}'),
      );
      
      print('✅ Verify API Response: ${response.statusCode}');
      print('✅ Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          print('✅ Payment verified successfully!');
          setState(() {
            _cashfreeData = data['data'];
            _paymentCompleted = true;
            _errorMessage = null;
          });
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment verified successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
        } else {
          print('❌ Payment verification failed: ${data['message']}');
          setState(() {
            _errorMessage = 'Payment verification failed: ${data['message']}';
          });
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        setState(() {
          _errorMessage = 'HTTP Error: ${response.statusCode}';
        });
      }
      
    } catch (e) {
      print('❌ Verification error: $e');
      setState(() {
        _errorMessage = 'Verification error: $e';
      });
    }
  }

  /// Check payment status (same as website)
  Future<void> _checkPaymentStatus() async {
    try {
      print('=== CHECKING PAYMENT STATUS ===');
      
      // Wait a bit for Cashfree to process (same as website)
      await Future.delayed(Duration(seconds: 3));
      
      await _verifyPaymentWithCashfree();
      
    } catch (e) {
      print('❌ Status check error: $e');
      setState(() {
        _errorMessage = 'Status check error: $e';
      });
    }
  }

  /// Save payment details using backend (same as website)
  Future<void> _savePaymentDetailsWithCashfreeData() async {
    try {
      print('=== SAVING PAYMENT DETAILS ===');
      
      if (_cashfreeData == null) {
        throw Exception('No payment data available');
      }
      
      final paymentData = {
        'order_id': widget.orderId,
        'payment_session_id': _paymentSessionId,
        'payment_status': _cashfreeData!['payment_status'] ?? 'UNKNOWN',
        'order_status': _cashfreeData!['order_status'] ?? 'UNKNOWN',
        'transaction_id': _cashfreeData!['transaction_id'],
        'amount': _cashfreeData!['order_amount'],
        'customer_details': _cashfreeData!['customer_details'],
        'raw_response': _cashfreeData
      };
      
      // ✅ Use backend endpoint (same as website)
      final response = await http.post(
        Uri.parse(ApiConfig.savePaymentUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(paymentData),
      );
      
      print('✅ Save Payment Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ Payment details saved successfully!');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment details saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
      } else {
        print('❌ Failed to save payment details: ${response.statusCode}');
        setState(() {
          _errorMessage = 'Failed to save payment details';
        });
      }
      
    } catch (e) {
      print('❌ Save payment error: $e');
      setState(() {
        _errorMessage = 'Save payment error: $e';
      });
    }
  }

  /// Sync with Cashfree dashboard (same as website)
  Future<void> _syncWithCashfreeDashboard() async {
    try {
      print('=== SYNCING WITH CASHFREE DASHBOARD ===');
      print('Order ID: ${widget.orderId}');
      print('Transaction ID: ${_cashfreeData?['transaction_id']}');
      print('==============================');
      
      // ✅ Use backend endpoint (same as website)
      final response = await http.post(
        Uri.parse(ApiConfig.cashfreeUpdateOrderStatusUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_id': widget.orderId,
          'payment_session_id': _paymentSessionId,
          'action': 'sync_status'
        }),
      );
      
      print('✅ Sync Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ Order status synced successfully!');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status synced successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
      } else {
        print('❌ Failed to sync order status: ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ Sync error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cashfree Payment'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.payment,
                    size: 48,
                    color: Colors.orange[700],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Cashfree Payment Gateway',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Complete your payment securely through Cashfree',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.orange[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Order Details
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order ID:'),
                      Text(
                        widget.orderId,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Session ID:'),
                      Text(
                        widget.paymentSessionId.substring(0, 20) + '...',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Error Display
            if (_errorMessage != null)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50]!,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            
            SizedBox(height: 24),
            
            // How it works
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How it works:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('1. Click "Start Payment" to open custom checkout page'),
                  Text('2. Complete payment using Cashfree JavaScript SDK'),
                  Text('3. Return to app to verify payment status'),
                  Text('4. Payment details will be automatically saved'),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Payment Status Display
            if (!_paymentCompleted)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.payment,
                      size: 48,
                      color: Colors.blue[700],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Payment Gateway Ready',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Click the button below to open Cashfree hosted checkout',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ),
            
            // Start Payment Button
            if (!_paymentCompleted)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    // Re-trigger payment if needed
                    if (_paymentSessionId != null) {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      
                      await _startCashfreePayment(widget.orderId, _paymentSessionId!);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Start Custom Payment',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            
            // Manual Payment Status Check
            if (!_paymentCompleted)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _checkPaymentStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Check Payment Status',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            
            // Return to App Button
            if (!_paymentCompleted)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: BorderSide(color: Colors.orange),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Return to App',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            
            // Payment Completed Section
            if (_paymentCompleted)
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 64,
                      color: Colors.green[600],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Payment Completed!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _savePaymentDetailsWithCashfreeData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Save Payment Details',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _syncWithCashfreeDashboard,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Sync with Dashboard',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}


