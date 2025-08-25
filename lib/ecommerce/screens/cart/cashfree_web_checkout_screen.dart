import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../api_config.dart';
import 'package:http/http.dart' as http;
import 'payment_success_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class CashfreeWebCheckoutScreen extends StatefulWidget {
  final String orderId;
  final String paymentSessionId;
  final int userId;
  final double amount;
  final int localOrderId;

  const CashfreeWebCheckoutScreen({
    Key? key,
    required this.orderId,
    required this.paymentSessionId,
    required this.userId,
    required this.amount,
    required this.localOrderId,
  }) : super(key: key);

  @override
  _CashfreeWebCheckoutScreenState createState() => _CashfreeWebCheckoutScreenState();
}

class _CashfreeWebCheckoutScreenState extends State<CashfreeWebCheckoutScreen> {
  bool _isLoading = false;
  bool _paymentCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkPaymentStatus();
  }

  Future<void> _checkPaymentStatus() async {
    try {
      // Call Cashfree API to verify payment status
      final response = await http.get(
        Uri.parse('$baseUrl/cashfree_verify_order.php?order_id=${widget.orderId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Payment verification response: $data');
        
        if (data['status'] == 'SUCCESS' && data['payment_status'] == 'SUCCESS') {
          _handlePaymentSuccess();
        }
      }
    } catch (e) {
      print('Error checking payment status: $e');
    }
  }

  Future<void> _verifyPaymentStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Call Cashfree API to verify payment status
      final response = await http.get(
        Uri.parse('$baseUrl/cashfree_verify_order.php?order_id=${widget.orderId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Payment verification response: $data');
        
        if (data['status'] == 'SUCCESS') {
          // Check if payment was actually successful
          final paymentStatus = data['payment_status'];
          final isPaid = data['is_paid'] ?? false;
          
          print('Payment status: $paymentStatus, Is paid: $isPaid');
          
          if (isPaid || paymentStatus == 'SUCCESS') {
            _handlePaymentSuccess();
          } else if (paymentStatus == 'PENDING') {
            // Payment is still pending, show message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment is still pending. Please wait or try again later.')),
            );
          } else {
            _handlePaymentFailure('Payment verification failed: $paymentStatus');
          }
        } else {
          _handlePaymentFailure(data['message'] ?? 'Payment verification failed');
        }
      } else {
        _handlePaymentFailure('Failed to verify payment status');
      }
    } catch (e) {
      print('Error verifying payment: $e');
      _handlePaymentFailure('Error verifying payment: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handlePaymentSuccess() async {
    print('Payment successful! Saving payment details...');
    
    try {
      // Get actual payment details from Cashfree
      final verifyResponse = await http.get(
        Uri.parse('$baseUrl/cashfree_verify_order.php?order_id=${widget.orderId}'),
      );

      String transactionId = 'CF_${widget.orderId}'; // Default fallback
      String paymentMethod = 'UPI'; // Default fallback
      
      if (verifyResponse.statusCode == 200) {
        final verifyData = json.decode(verifyResponse.body);
        print('Payment verification data: $verifyData');
        
        if (verifyData['status'] == 'SUCCESS') {
          // Use actual transaction ID if available
          transactionId = verifyData['transaction_id'] ?? transactionId;
          paymentMethod = verifyData['payment_method'] ?? paymentMethod;
          
          // If we have raw response, try to extract more details
          if (verifyData['raw_response'] != null) {
            final rawResponse = verifyData['raw_response'];
            print('Raw Cashfree response: $rawResponse');
            
            // Try to get more payment details from raw response
            if (rawResponse['payment_method'] != null) {
              paymentMethod = rawResponse['payment_method'];
            }
            if (rawResponse['cf_payment_id'] != null) {
              transactionId = rawResponse['cf_payment_id'];
            }
          }
          
          print('Using actual transaction ID: $transactionId');
          print('Using actual payment method: $paymentMethod');
        }
      }
      
      // Save payment details to database
      final response = await http.post(
        Uri.parse('$baseUrl/save_payment.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'order_id': widget.localOrderId,
          'payment_method': paymentMethod, // Use actual payment method
          'amount': widget.amount,
          'payment_status': 'Success',
          'transaction_id': transactionId, // Use actual transaction ID
        }),
      );

      if (response.statusCode == 200) {
        print('Payment details saved successfully');
        
        // Navigate to success screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentSuccessScreen(orderId: widget.localOrderId.toString()),
          ),
        );
      } else {
        print('Failed to save payment details: ${response.statusCode}');
        _handlePaymentFailure('Failed to save payment details');
      }
    } catch (e) {
      print('Error saving payment details: $e');
      _handlePaymentFailure('Error saving payment details: $e');
    }
  }

  void _handlePaymentFailure(String error) {
    print('Payment failed: $error');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: $error')),
    );
    
    // Navigate back to checkout
    Navigator.pop(context);
  }

  // The correct way to handle Cashfree web checkout
  Future<void> _startCashfreeWebCheckout() async {
    print('=== STARTING CASHFREE WEB CHECKOUT ===');
    print('Order ID: ${widget.orderId}');
    print('Payment Session ID: ${widget.paymentSessionId}');
    print('Amount: ${widget.amount}');
    print('=====================================');
    
    try {
      // Step 1: Create a proper web checkout session
      final checkoutResponse = await http.post(
        Uri.parse('$baseUrl/cashfree_web_checkout.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_id': widget.orderId,
          'payment_session_id': widget.paymentSessionId,
          'amount': widget.amount,
          'return_url': '$baseUrl/cashfree_return_url.php?order_id=${widget.orderId}',
        }),
      );

      if (checkoutResponse.statusCode == 200) {
        final checkoutData = json.decode(checkoutResponse.body);
        print('Web checkout response: $checkoutData');
        
        if (checkoutData['status'] == 'SUCCESS') {
          // Step 2: Open the checkout URL provided by Cashfree
          final checkoutUrl = checkoutData['checkout_url'];
          if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
            print('Opening Cashfree checkout URL: $checkoutUrl');
            
            if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
              await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);
            } else {
              _handlePaymentFailure('Could not open checkout URL');
            }
          } else {
            _handlePaymentFailure('No checkout URL received from Cashfree');
          }
        } else {
          _handlePaymentFailure(checkoutData['message'] ?? 'Failed to create checkout session');
        }
      } else {
        _handlePaymentFailure('Failed to create checkout session: ${checkoutResponse.statusCode}');
      }
    } catch (e) {
      print('Error starting web checkout: $e');
      _handlePaymentFailure('Error starting web checkout: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Payment'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            // Ask user if they want to cancel payment
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Cancel Payment?'),
                content: Text('Are you sure you want to cancel this payment?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('No'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back to checkout
                    },
                    child: Text('Yes, Cancel'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 
                      MediaQuery.of(context).padding.top - 
                      MediaQuery.of(context).padding.bottom - 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              
              // Cashfree Logo Placeholder
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.payment,
                  size: 50,
                  color: Colors.orange,
                ),
              ),
              
              SizedBox(height: 20),
              
              Text(
                'Complete Your Payment',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              SizedBox(height: 12),
              
              Text(
                'Order ID: ${widget.orderId}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              
              SizedBox(height: 6),
              
              Text(
                'Amount: ₹${widget.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              
              SizedBox(height: 20),
              
              Text(
                'Click the button below to start the Cashfree web checkout process. This will open the secure payment page where you can complete your payment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                ),
              ),
              
              SizedBox(height: 16),
              
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  children: [
                    Text(
                      'How it works:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '1. Click "Start Cashfree Web Checkout"\n'
                      '2. Complete payment on Cashfree\'s secure page\n'
                      '3. You\'ll be redirected back to this app\n'
                      '4. Payment will be automatically verified\n'
                      '5. Order will be marked as completed',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _startCashfreeWebCheckout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Start Cashfree Web Checkout',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyPaymentStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Text(
                          'Check Payment Status',
                          style: TextStyle(fontSize: 15),
                        ),
                ),
              ),
              
              SizedBox(height: 16),
              
              Text(
                'After completing payment on Cashfree, you will be automatically redirected back to this app. The payment will be verified and your order will be completed automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
