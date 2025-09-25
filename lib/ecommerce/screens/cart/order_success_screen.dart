import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../api_config.dart' as ApiConfig;

class OrderSuccessScreen extends StatefulWidget {
  final String orderId;
  final String? paymentSessionId;
  final Map<String, dynamic>? paymentData;

  const OrderSuccessScreen({
    Key? key,
    required this.orderId,
    this.paymentSessionId,
    this.paymentData,
  }) : super(key: key);

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  bool _isLoading = true;
  bool _paymentVerified = false;
  Map<String, dynamic>? _orderDetails;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _verifyPaymentStatus();
  }

  Future<void> _verifyPaymentStatus() async {
    try {
      print('=== VERIFYING PAYMENT STATUS ===');
      print('Order ID: ${widget.orderId}');
      
      // Wait a bit for Cashfree to process
      await Future.delayed(Duration(seconds: 3));
      
      // Verify payment with backend
      final response = await http.get(
        Uri.parse('${ApiConfig.verifyOrderUrl}?order_id=${widget.orderId}'),
      );
      
      print('✅ Verify API Response: ${response.statusCode}');
      print('✅ Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          setState(() {
            _orderDetails = data['data'];
            _paymentVerified = data['data']['is_paid'] ?? false;
            _isLoading = false;
          });
          
          // If payment is successful, save payment details
          if (_paymentVerified) {
            await _savePaymentDetails();
            // Also call return URL to ensure payment data is stored in database
            await _callReturnUrl();
          }
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Payment verification failed';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'HTTP Error: ${response.statusCode}';
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print('❌ Verification error: $e');
      setState(() {
        _errorMessage = 'Verification error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _savePaymentDetails() async {
    try {
      print('=== SAVING PAYMENT DETAILS ===');
      
      if (_orderDetails == null) {
        throw Exception('No payment data available');
      }
      
      final paymentData = {
        'order_id': widget.orderId,
        'payment_session_id': widget.paymentSessionId,
        'payment_status': _orderDetails!['payment_status'] ?? 'UNKNOWN',
        'order_status': _orderDetails!['order_status'] ?? 'UNKNOWN',
        'transaction_id': _orderDetails!['transaction_id'],
        'amount': _orderDetails!['order_amount'],
        'customer_details': _orderDetails!['customer_details'],
        'raw_response': _orderDetails
      };
      
      // Save payment details using backend
      final response = await http.post(
        Uri.parse(ApiConfig.savePaymentUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(paymentData),
      );
      
      print('✅ Save Payment Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('✅ Payment details saved successfully!');
      } else {
        print('❌ Failed to save payment details: ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ Save payment error: $e');
    }
  }

  Future<void> _callReturnUrl() async {
    try {
      print('=== CALLING RETURN URL TO STORE PAYMENT DATA ===');
      print('Order ID: ${widget.orderId}');
      
      // Call the return URL to ensure payment data is stored in database
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/cashfree_return_url.php?order_id=${widget.orderId}'),
      );
      
      print('✅ Return URL Response: ${response.statusCode}');
      print('✅ Return URL Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'SUCCESS') {
          print('✅ Payment data stored successfully in database');
        } else {
          print('❌ Return URL error: ${data['message']}');
        }
      } else {
        print('❌ Return URL HTTP Error: ${response.statusCode}');
      }
      
    } catch (e) {
      print('❌ Return URL call error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Status'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'Verifying payment status...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _buildSuccessState(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Payment Verification Failed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.red[600],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _verifyPaymentStatus,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text('Retry Verification'),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: Text('Return to Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    final isPaid = _orderDetails?['is_paid'] ?? false;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          // Success Header
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isPaid ? Colors.green[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isPaid ? Colors.green[200]! : Colors.orange[200]!,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  isPaid ? Icons.check_circle : Icons.schedule,
                  size: 80,
                  color: isPaid ? Colors.green[600] : Colors.orange[600],
                ),
                SizedBox(height: 16),
                Text(
                  isPaid ? 'Payment Successful!' : 'Payment Pending',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isPaid ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  isPaid 
                      ? 'Your order has been confirmed and payment is complete.'
                      : 'Your payment is being processed. Please wait for confirmation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isPaid ? Colors.green[600] : Colors.orange[600],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Order Details
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                _buildDetailRow('Order ID', widget.orderId),
                if (widget.paymentSessionId != null)
                  _buildDetailRow('Session ID', widget.paymentSessionId!.substring(0, 20) + '...'),
                _buildDetailRow('Status', _orderDetails?['order_status'] ?? 'Unknown'),
                _buildDetailRow('Payment Status', _orderDetails?['payment_status'] ?? 'Unknown'),
                _buildDetailRow('Amount', '₹${_orderDetails?['order_amount']?.toStringAsFixed(2) ?? '0.00'}'),
                if (_orderDetails?['customer_details'] != null)
                  _buildDetailRow('Customer', _orderDetails!['customer_details']['customer_name'] ?? 'Unknown'),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Action Buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Continue Shopping',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _verifyPaymentStatus,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: BorderSide(color: Colors.orange),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    'Refresh Status',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
