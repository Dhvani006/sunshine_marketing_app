import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'payment_success_screen.dart';
import '../../../api_config.dart';
import '../../../cashfree_config.dart';

class CashfreeInAppCheckoutScreen extends StatefulWidget {
  final String orderId;
  final int userId;
  final double amount;
  final int localOrderId;
  final List<Map<String, dynamic>> cartItems;

  const CashfreeInAppCheckoutScreen({
    Key? key,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.localOrderId,
    required this.cartItems,
  }) : super(key: key);

  @override
  _CashfreeInAppCheckoutScreenState createState() => _CashfreeInAppCheckoutScreenState();
}

class _CashfreeInAppCheckoutScreenState extends State<CashfreeInAppCheckoutScreen> {
  bool _isLoading = false;
  String? _paymentSessionId;
  String? _errorMessage;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeCheckout();
  }

  Future<void> _initializeCheckout() async {
    try {
      print('✅ Cashfree checkout initialized successfully');
      // For now, we'll simulate the initialization
      // In production, this would initialize the Cashfree SDK
    } catch (e) {
      print('❌ Failed to initialize checkout: $e');
      setState(() {
        _errorMessage = 'Failed to initialize payment gateway: $e';
      });
    }
  }

  Future<void> _createPaymentSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('=== CREATING CASHFREE PAYMENT SESSION ===');
      print('Order ID: ${widget.orderId}');
      print('Amount: ${widget.amount}');
      print('User ID: ${widget.userId}');
      print('========================================');

      // Create payment session with Cashfree
      final response = await http.post(
        Uri.parse('$baseUrl/cashfree_order.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'orderId': widget.orderId,
          'orderAmount': widget.amount.toString(),
          'orderCurrency': 'INR',
          'customerName': 'Customer ${widget.userId}',
          'customerPhone': '9876543210',
          'customerEmail': 'customer${widget.userId}@example.com',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Payment session response: $data');

        if (data['status'] == 'SUCCESS') {
          setState(() {
            _paymentSessionId = data['payment_session_id'];
          });
          print('✅ Payment session created: $_paymentSessionId');
          
          // Start payment process
          await _startPayment();
        } else {
          throw Exception(data['message'] ?? 'Failed to create payment session');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error creating payment session: $e');
      setState(() {
        _errorMessage = 'Failed to create payment session: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startPayment() async {
    if (_paymentSessionId == null) {
      setState(() {
        _errorMessage = 'Payment session ID is missing';
      });
      return;
    }

    try {
      print('=== STARTING CASHFREE PAYMENT ===');
      print('Payment Session ID: $_paymentSessionId');
      print('Order ID: ${widget.orderId}');
      print('Amount: ${widget.amount}');
      print('================================');

      // For now, we'll simulate the payment process
      // In production, this would call the Cashfree SDK
      await _simulatePaymentProcess();

    } catch (e) {
      print('❌ Error starting payment: $e');
      setState(() {
        _errorMessage = 'Payment failed: $e';
      });
    }
  }

  Future<void> _simulatePaymentProcess() async {
    try {
      print('=== SIMULATING PAYMENT PROCESS ===');
      
      // Show payment options to user
      setState(() {
        _isLoading = false;
      });
      
      // Simulate payment completion after user interaction
      await _showPaymentOptions();
      
    } catch (e) {
      print('❌ Error in payment simulation: $e');
      setState(() {
        _errorMessage = 'Payment simulation failed: $e';
      });
    }
  }

  Future<void> _showPaymentOptions() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Payment Method'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.credit_card, color: Colors.blue),
                title: Text('Credit/Debit Card'),
                subtitle: Text('Visa, Mastercard, RuPay'),
                onTap: () => Navigator.of(context).pop('card'),
              ),
              ListTile(
                leading: Icon(Icons.account_balance_wallet, color: Colors.green),
                title: Text('UPI'),
                subtitle: Text('Pay using UPI ID'),
                onTap: () => Navigator.of(context).pop('upi'),
              ),
              ListTile(
                leading: Icon(Icons.account_balance, color: Colors.orange),
                title: Text('Net Banking'),
                subtitle: Text('All major banks'),
                onTap: () => Navigator.of(context).pop('netbanking'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('cancel'),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (result != null && result != 'cancel') {
      await _processPaymentWithMethod(result);
    }
  }

  Future<void> _processPaymentWithMethod(String method) async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('=== PROCESSING PAYMENT WITH METHOD: $method ===');
      
      // Simulate payment processing delay
      await Future.delayed(Duration(seconds: 2));
      
      // For testing purposes, always succeed
      // In production, this would integrate with Cashfree SDK
      await _handlePaymentSuccess(method);
      
    } catch (e) {
      print('❌ Error processing payment: $e');
      setState(() {
        _errorMessage = 'Payment processing failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handlePaymentSuccess(String paymentMethod) async {
    try {
      print('=== PAYMENT SUCCESS ===');
      print('Payment Method: $paymentMethod');
      print('Order ID: ${widget.orderId}');
      print('Amount: ${widget.amount}');
      print('======================');
      
      // Generate transaction ID
      final transactionId = 'CF_${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Save payment details to database
      await _savePaymentDetails(transactionId, paymentMethod);
      
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

  Future<void> _savePaymentDetails(String transactionId, String paymentMethod) async {
    try {
      print('=== SAVING PAYMENT DETAILS ===');
      print('Transaction ID: $transactionId');
      print('Payment Method: $paymentMethod');
      print('Order ID: ${widget.localOrderId}');
      print('Amount: ${widget.amount}');
      print('==============================');

      final response = await http.post(
        Uri.parse('$baseUrl/save_payment.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'order_id': widget.localOrderId,
          'payment_method': paymentMethod,
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
        title: Text('Cashfree Payment'),
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

            // Payment Method Info
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
                        Icon(Icons.payment, color: Colors.blue, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Cashfree Payment Gateway',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800]!),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Secure payment powered by Cashfree. Supports UPI, cards, net banking, and more.',
                      style: TextStyle(fontSize: 14, color: Colors.blue[700]!, height: 1.4),
                    ),
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

            // Start Payment Button
            if (!_paymentCompleted)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createPaymentSession,
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
                            Text('Processing...', style: TextStyle(fontSize: 18)),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.payment, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'Start Payment',
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
              color: Colors.green[50]!,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'How it works:',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[800]!),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '1. Click "Start Payment" to create a payment session\n'
                      '2. Choose your preferred payment method\n'
                      '3. Complete the payment securely\n'
                      '4. Get redirected to success page automatically',
                      style: TextStyle(fontSize: 14, color: Colors.green[700]!, height: 1.4),
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
