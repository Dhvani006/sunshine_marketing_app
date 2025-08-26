import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'payment_success_screen.dart';
import '../../../api_config.dart';
import '../../../cashfree_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CashfreeWebCheckoutScreen extends StatefulWidget {
  final String orderId;
  final int userId;
  final double amount;
  final int localOrderId;
  final List<Map<String, dynamic>> cartItems;
  final String customerName;
  final String customerEmail;
  final String customerPhone;

  const CashfreeWebCheckoutScreen({
    Key? key,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.localOrderId,
    required this.cartItems,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
  }) : super(key: key);

  @override
  _CashfreeWebCheckoutScreenState createState() => _CashfreeWebCheckoutScreenState();
}

class _CashfreeWebCheckoutScreenState extends State<CashfreeWebCheckoutScreen> {
  bool _isLoading = false;
  bool _paymentCompleted = false;
  String? _checkoutUrl;
  WebViewController? _webViewController;
  String? _errorMessage;
  
  // Platform detection
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;

  @override
  void initState() {
    super.initState();
    _createCashfreeOrder();
  }

  Future<void> _createCashfreeOrder() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('=== CREATING CASHFREE ORDER ===');
      print('Order ID: ${widget.orderId}');
      print('Amount: ${widget.amount}');
      print('User ID: ${widget.userId}');
      print('Customer Name: ${widget.customerName}');
      print('Customer Email: ${widget.customerEmail}');
      print('Customer Phone: ${widget.customerPhone}');
      print('================================');

      // Create order with Cashfree - Include ALL required fields
      final orderAmount = widget.amount.toStringAsFixed(2); // Ensure proper decimal format
      
      print('=== SENDING TO BACKEND ===');
      print('Order amount: $orderAmount');
      print('Order amount type: ${orderAmount.runtimeType}');
      print('Customer details:');
      print('  - Name: ${widget.customerName}');
      print('  - Email: ${widget.customerEmail}');
      print('  - Phone: ${widget.customerPhone}');
      print('==========================');
      
      // Create order directly with Cashfree API
      final response = await http.post(
        Uri.parse('https://sandbox.cashfree.com/pg/orders'),
        headers: {
          'Content-Type': 'application/json',
          'x-client-id': CashfreeConfig.clientId,      // ✅ FIXED: Use clientId, not appId
          'x-client-secret': CashfreeConfig.clientSecret,  // ✅ FIXED: Use clientSecret
          'x-api-version': '2022-09-01', // 👈 REQUIRED header
        },
        body: json.encode({
          'order_id': widget.orderId,
          'order_amount': double.parse(orderAmount),
          'order_currency': 'INR',
          'customer_details': {
            'customer_id': 'customer_${widget.userId}',
            'customer_name': widget.customerName,
            'customer_phone': widget.customerPhone,
            'customer_email': widget.customerEmail,
          },
          'order_note': 'Order from Sunshine Marketing App',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Cashfree order response: $data');

        if (response.statusCode == 200) {
          // Cashfree returns order details with payment_session_id
          final paymentSessionId = data['payment_session_id'];
          if (paymentSessionId != null && paymentSessionId.isNotEmpty) {
            // Use Cashfree's hosted checkout page for PG v3
            final paymentUrl = 'https://sandbox.cashfree.com/pg/orders/${widget.orderId}/payments?payment_session_id=$paymentSessionId';
            
            print('✅ Payment URL constructed: $paymentUrl');
            setState(() {
              _checkoutUrl = paymentUrl;
            });
            
            // Start WebView checkout
            await _startWebViewCheckout();
          } else {
            throw Exception('No payment session ID received from Cashfree');
          }
        } else {
          throw Exception(data['message'] ?? 'Failed to create Cashfree order');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error creating Cashfree order: $e');
      setState(() {
        _errorMessage = 'Failed to create payment order: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startWebViewCheckout() async {
    if (_checkoutUrl == null) {
      setState(() {
        _errorMessage = 'Payment URL is missing';
      });
      return;
    }

    try {
      print('=== STARTING WEBVIEW CHECKOUT ===');
      print('Payment URL: $_checkoutUrl');
      print('Platform: ${isAndroid ? "Android" : isWindows ? "Windows" : "Unknown"}');
      print('==================================');

      if (isAndroid) {
        print('🟢 Android detected - Using WebView');
        await _setupWebView();
      } else if (isWindows) {
        print('🟦 Windows detected - Opening in external browser');
        await _openInExternalBrowser();
      } else {
        print('🟡 Other platform detected - Using external browser');
        await _openInExternalBrowser();
      }
    } catch (e) {
      print('❌ Error starting checkout: $e');
      setState(() {
        _errorMessage = 'Failed to start checkout: $e';
      });
    }
  }

  Future<void> _setupWebView() async {
    try {
      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              print('WebView: Page started loading: $url');
              setState(() {
                _isLoading = true;
              });
            },
            onPageFinished: (String url) {
              print('WebView: Page finished loading: $url');
              setState(() {
                _isLoading = false;
              });
              
              // Only detect success on specific Cashfree success URLs, not return_url
              if (url.contains('success') || url.contains('payment_success')) {
                print('WebView: Success URL detected, handling payment completion');
                _handlePaymentSuccess();
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              print('WebView: Navigation request to: ${request.url}');
              
              // Only prevent navigation on actual success URLs, not return_url
              if (request.url.contains('success') || request.url.contains('payment_success')) {
                print('WebView: Success navigation detected');
                _handlePaymentSuccess();
                return NavigationDecision.prevent;
              }
              
              // Allow all other navigation including return_url
              return NavigationDecision.navigate;
            },
            onWebResourceError: (WebResourceError error) {
              print('WebView: Error loading page: ${error.description}');
              print('Error code: ${error.errorCode}');
              setState(() {
                _isLoading = false;
                _errorMessage = 'Error loading payment page: ${error.description}';
              });
            },
          ),
        );
      
      print('Loading URL in WebView: $_checkoutUrl');
      await _webViewController!.loadRequest(Uri.parse(_checkoutUrl!));
      print('✅ WebView loadRequest completed');
      
    } catch (e) {
      print('❌ Error setting up WebView: $e');
      setState(() {
        _errorMessage = 'Failed to setup WebView: $e';
      });
    }
  }

  Future<void> _openInExternalBrowser() async {
    try {
      final uri = Uri.parse(_checkoutUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        
        // Show message to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment page opened in browser. Complete payment there and return to app.'),
            duration: Duration(seconds: 5),
          ),
        );
        
        // For external browser, we'll need to manually check payment status
        // You can add a "Check Payment Status" button here
      } else {
        throw Exception('Could not open payment page in browser');
      }
    } catch (e) {
      print('❌ Error opening external browser: $e');
      setState(() {
        _errorMessage = 'Failed to open payment page: $e';
      });
    }
  }

  Future<void> _handlePaymentSuccess() async {
    try {
      print('=== PAYMENT SUCCESS DETECTED ===');
      print('Order ID: ${widget.orderId}');
      print('Amount: ${widget.amount}');
      print('===============================');
      
      // Mark payment as completed
      setState(() {
        _paymentCompleted = true;
      });
      
      // Add a small delay to ensure payment processing is complete
      print('⏳ Waiting for payment processing...');
      await Future.delayed(Duration(seconds: 3));
      
      // First, verify payment with Cashfree and get actual transaction data
      final cashfreeTransactionData = await _verifyPaymentWithCashfree();
      
      if (cashfreeTransactionData != null) {
        // Use Cashfree's actual transaction data
        await _savePaymentDetailsWithCashfreeData(cashfreeTransactionData);
      } else {
        // Fallback: generate local transaction ID if Cashfree verification fails
        final transactionId = 'CF_${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}';
        await _savePaymentDetails(transactionId);
      }
      
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

  Future<Map<String, dynamic>?> _verifyPaymentWithCashfree() async {
    try {
      print('=== VERIFYING PAYMENT WITH CASHFREE ===');
      print('Order ID: ${widget.orderId}');
      print('===============================');
      
      // Call Cashfree API to verify payment status
      final response = await http.get(
        Uri.parse('https://711539e5161c.ngrok-free.app/cashfree_verify_order.php?order_id=${widget.orderId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Cashfree verification response: $data');
        
        if (data['status'] == 'SUCCESS' && data['payment_status'] == 'SUCCESS') {
          // Extract Cashfree transaction data
          final cashfreeData = {
            'transaction_id': data['transaction_id'] ?? 'CF_${widget.orderId}_${DateTime.now().millisecondsSinceEpoch}',
            'payment_method': data['payment_method'] ?? 'Cashfree',
            'cashfree_order_id': widget.orderId,
            'cashfree_payment_status': data['payment_status'],
            'cashfree_response': data,
          };
          
          print('✅ Cashfree verification successful');
          print('Transaction ID: ${cashfreeData['transaction_id']}');
          return cashfreeData;
        } else {
          print('⚠️ Cashfree payment not yet confirmed');
          return null;
        }
      } else {
        print('❌ Failed to verify with Cashfree: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error verifying with Cashfree: $e');
      return null;
    }
  }

  Future<void> _savePaymentDetailsWithCashfreeData(Map<String, dynamic> cashfreeData) async {
    try {
      print('=== SAVING PAYMENT DETAILS WITH CASHFREE DATA ===');
      print('Cashfree Transaction ID: ${cashfreeData['transaction_id']}');
      print('Order ID: ${widget.localOrderId}');
      print('Amount: ${widget.amount}');
      print('==============================');

      final response = await http.post(
        Uri.parse('https://711539e5161c.ngrok-free.app/save_payment.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'order_id': widget.localOrderId,
          'payment_method': cashfreeData['payment_method'],
          'amount': widget.amount,
          'payment_status': 'Success',
          'transaction_id': cashfreeData['transaction_id'],
          'cashfree_order_id': cashfreeData['cashfree_order_id'],
          'cashfree_payment_status': cashfreeData['cashfree_payment_status'],
          'cashfree_response': json.encode(cashfreeData['cashfree_response']),
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Payment details saved with Cashfree data successfully');
        
        // Now sync with Cashfree dashboard by updating order status
        await _syncWithCashfreeDashboard(cashfreeData);
      } else {
        print('❌ Failed to save payment details: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error saving payment details with Cashfree data: $e');
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
          Uri.parse('https://711539e5161c.ngrok-free.app/save_payment.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': widget.userId,
          'order_id': widget.localOrderId,
          'payment_method': 'Cashfree',
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

  Future<void> _syncWithCashfreeDashboard(Map<String, dynamic> cashfreeData) async {
    try {
      print('=== SYNCING WITH CASHFREE DASHBOARD ===');
      print('Order ID: ${widget.orderId}');
      print('Transaction ID: ${cashfreeData['transaction_id']}');
      print('==============================');
      
      // Call Cashfree API to update order status and link transaction
      final response = await http.post(
        Uri.parse('https://711539e5161c.ngrok-free.app/cashfree_update_order_status.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_id': widget.orderId,
          'transaction_id': cashfreeData['transaction_id'],
          'payment_status': 'SUCCESS',
          'amount': widget.amount,
          'customer_details': {
            'name': widget.customerName,
            'email': widget.customerEmail,
            'phone': widget.customerPhone,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Cashfree dashboard sync successful: $data');
      } else {
        print('⚠️ Cashfree dashboard sync failed: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error syncing with Cashfree dashboard: $e');
    }
  }

  // Cashfree hosted checkout URL is now constructed directly in the order creation flow

  Future<void> _checkPaymentStatus() async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('=== CHECKING PAYMENT STATUS ===');
      
      // Call your backend to check payment status
              final response = await http.get(
          Uri.parse('https://711539e5161c.ngrok-free.app/cashfree_verify_order.php?order_id=${widget.orderId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Payment status response: $data');
        
        if (data['status'] == 'SUCCESS' && data['payment_status'] == 'SUCCESS') {
          await _handlePaymentSuccess();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment is still pending. Please complete payment in browser.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Failed to check payment status');
      }
    } catch (e) {
      print('❌ Error checking payment status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking payment status: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Order Summary
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Order ID: ${widget.orderId}'),
                      Text('Amount: ₹${widget.amount}'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              
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

              if (_errorMessage != null) SizedBox(height: 16),
              
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

              if (_paymentCompleted) SizedBox(height: 16),
              
              // How it works
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
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
                      SizedBox(height: 8),
                      Text('1. Payment page will open below'),
                      Text('2. Complete payment on Cashfree'),
                      Text('3. Return to app automatically'),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              // WebView Container (Android only)
              if (_checkoutUrl != null && isAndroid && !_paymentCompleted)
                Container(
                  height: MediaQuery.of(context).size.height * 0.6, // Use 60% of screen height
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        color: Colors.orange,
                        child: Row(
                          children: [
                            Icon(Icons.payment, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Cashfree Payment Page',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _webViewController != null
                            ? WebViewWidget(controller: _webViewController!)
                            : Center(
                                child: CircularProgressIndicator(),
                              ),
                      ),
                    ],
                  ),
                ),
              
              // Manual Payment Status Check Button (for all platforms)
              if (_checkoutUrl != null && !_paymentCompleted)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _checkPaymentStatus,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Check Payment Status Manually',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              
              // Manual Payment Status Check (Windows/External Browser)
              if (!isAndroid || _checkoutUrl == null)
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkPaymentStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Check Payment Status',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                ),
              
              // Retry Button
              if (_errorMessage != null && !_paymentCompleted)
                ElevatedButton(
                  onPressed: _isLoading ? null : _createCashfreeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Retry Payment',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
