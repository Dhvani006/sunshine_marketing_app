import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'payment_success_screen.dart';
import '../../../api_config.dart';

class SimpleCheckoutScreen extends StatefulWidget {
  final String orderId;
  final int userId;
  final double amount;
  final int localOrderId;
  final List<Map<String, dynamic>> cartItems;

  const SimpleCheckoutScreen({
    Key? key,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.localOrderId,
    required this.cartItems,
  }) : super(key: key);

  @override
  _SimpleCheckoutScreenState createState() => _SimpleCheckoutScreenState();
}

class _SimpleCheckoutScreenState extends State<SimpleCheckoutScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  bool _paymentCompleted = false;
  String? _selectedPaymentMethod;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'upi',
      'name': 'UPI Payment',
      'icon': Icons.account_balance_wallet,
      'color': Colors.green,
      'description': 'Pay using UPI ID or QR Code'
    },
    {
      'id': 'card',
      'name': 'Card Payment',
      'icon': Icons.credit_card,
      'color': Colors.blue,
      'description': 'Credit/Debit Card'
    },
    {
      'id': 'netbanking',
      'name': 'Net Banking',
      'icon': Icons.account_balance,
      'color': Colors.orange,
      'description': 'Internet Banking'
    },
  ];

  @override
  void initState() {
    super.initState();
    print('✅ Simple checkout initialized successfully');
  }

  Future<void> _processPayment() async {
    if (_selectedPaymentMethod == null) {
      setState(() {
        _errorMessage = 'Please select a payment method';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('=== PROCESSING PAYMENT ===');
      print('Payment Method: $_selectedPaymentMethod');
      print('Order ID: ${widget.orderId}');
      print('Amount: ${widget.amount}');
      print('==========================');

      // Simulate payment processing delay
      await Future.delayed(Duration(seconds: 3));
      
      // For testing purposes, always succeed
      // In production, this would integrate with your payment gateway
      await _handlePaymentSuccess();
      
    } catch (e) {
      print('❌ Error processing payment: $e');
      setState(() {
        _errorMessage = 'Payment failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePaymentSuccess() async {
    try {
      print('=== PAYMENT SUCCESS ===');
      print('Order ID: ${widget.orderId}');
      print('Amount: ${widget.amount}');
      print('======================');
      
      // Generate transaction ID
      final transactionId = 'TXN_${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Save payment details to database
      await _savePaymentDetails(transactionId);
      
      // Mark payment as completed
      setState(() {
        _paymentCompleted = true;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment successful! Redirecting to success page...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Navigate to success screen after delay
      await Future.delayed(Duration(seconds: 2));
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(
            orderId: widget.localOrderId.toString(),
            amount: widget.amount,
            userId: widget.userId,
          ),
        ),
      );
      
    } catch (e) {
      print('❌ Error handling payment success: $e');
      setState(() {
        _errorMessage = 'Error processing successful payment: $e';
      });
    }
  }

  Future<void> _savePaymentDetails(String transactionId) async {
    try {
      print('=== SAVING PAYMENT DETAILS ===');
      print('Transaction ID: $transactionId');
      print('Order ID: ${widget.localOrderId}');
      print('Amount: ${widget.amount}');
      print('==============================');

      final response = await http.post(
        Uri.parse('$baseUrl/save_payment.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'order_id': widget.localOrderId,
          'payment_method': _selectedPaymentMethod,
          'amount': widget.amount,
          'payment_status': 'Success',
          'transaction_id': transactionId,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Payment details saved successfully');
      } else {
        print('❌ Failed to save payment details: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error saving payment details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Payment'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order Summary Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.orange, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Order Summary',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order ID:', style: TextStyle(fontSize: 16)),
                        Text(widget.orderId, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Amount:', style: TextStyle(fontSize: 16)),
                        Text(
                          '₹${widget.amount.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Payment Methods Selection
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payment, color: Colors.green, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Choose Payment Method',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ..._paymentMethods.map((method) {
                      final isSelected = _selectedPaymentMethod == method['id'];
                      return RadioListTile<String>(
                        value: method['id'],
                        groupValue: _selectedPaymentMethod,
                        onChanged: (value) {
                          setState(() {
                            _selectedPaymentMethod = value;
                          });
                        },
                        title: Row(
                          children: [
                            Icon(method['icon'], color: method['color'], size: 24),
                            SizedBox(width: 12),
                            Text(method['name'], style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        subtitle: Text(method['description']),
                        secondary: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? method['color'] : Colors.grey[300],
                          ),
                          child: isSelected ? Icon(Icons.check, color: Colors.white, size: 14) : null,
                        ),
                        tileColor: isSelected ? method['color'].withOpacity(0.1) : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Error Message
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
                        style: TextStyle(color: Colors.red[800]!),
                      ),
                    ),
                  ],
                ),
              ),

            if (_errorMessage != null) SizedBox(height: 20),

            // Success Message
            if (_paymentCompleted)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50]!,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Payment completed successfully! Redirecting...',
                        style: TextStyle(color: Colors.green[800]!),
                      ),
                    ),
                  ],
                ),
              ),

            if (_paymentCompleted) SizedBox(height: 20),

            // Proceed Button
            if (!_paymentCompleted)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_selectedPaymentMethod != null && !_isLoading) ? _processPayment : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Processing Payment...', style: TextStyle(fontSize: 18)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Pay ₹${widget.amount.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),

            SizedBox(height: 20),

            // Instructions
            Card(
              elevation: 2,
              color: Colors.blue[50]!,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'How it works:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800]!),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '1. Select your preferred payment method\n'
                      '2. Click "Pay" to process the payment\n'
                      '3. Complete the payment securely\n'
                      '4. Get redirected to success page automatically',
                      style: TextStyle(fontSize: 14, color: Colors.blue[700]!, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
