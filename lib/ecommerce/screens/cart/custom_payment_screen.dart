import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'payment_success_screen.dart';
import '../../../api_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CustomPaymentScreen extends StatefulWidget {
  final String orderId;
  final String paymentSessionId;
  final int userId;
  final dynamic amount; // Changed from double to dynamic to handle both types
  final int localOrderId;
  final List<Map<String, dynamic>> cartItems;

  const CustomPaymentScreen({
    Key? key,
    required this.orderId,
    required this.paymentSessionId,
    required this.userId,
    required this.amount,
    required this.localOrderId,
    required this.cartItems,
  }) : super(key: key);

  @override
  _CustomPaymentScreenState createState() => _CustomPaymentScreenState();
}

class _CustomPaymentScreenState extends State<CustomPaymentScreen> {
  bool _isLoading = false;
  String? _selectedPaymentMethod;
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'upi',
      'name': 'UPI',
      'icon': Icons.account_balance_wallet,
      'color': Colors.blue,
      'description': 'Pay using UPI ID or QR Code'
    },
    {
      'id': 'card',
      'name': 'Credit/Debit Card',
      'icon': Icons.credit_card,
      'color': Colors.green,
      'description': 'Visa, Mastercard, RuPay, American Express'
    },
    {
      'id': 'netbanking',
      'name': 'Net Banking',
      'icon': Icons.account_balance,
      'color': Colors.orange,
      'description': 'All major banks supported'
    },
    {
      'id': 'wallet',
      'name': 'Digital Wallets',
      'icon': Icons.phone_android,
      'color': Colors.purple,
      'description': 'Paytm, PhonePe, Google Pay, Amazon Pay'
    },
  ];

  @override
  void initState() {
    super.initState();
    _debugDataTypes();
  }

  void _debugDataTypes() {
    print('=== CUSTOM PAYMENT SCREEN DEBUG ===');
    print('orderId: ${widget.orderId} (type: ${widget.orderId.runtimeType})');
    print('paymentSessionId: ${widget.paymentSessionId} (type: ${widget.paymentSessionId.runtimeType})');
    print('userId: ${widget.userId} (type: ${widget.userId.runtimeType})');
    print('amount: ${widget.amount} (type: ${widget.amount.runtimeType})');
    print('localOrderId: ${widget.localOrderId} (type: ${widget.localOrderId.runtimeType})');
    print('cartItems count: ${widget.cartItems.length}');
    if (widget.cartItems.isNotEmpty) {
      print('First cart item: ${widget.cartItems.first}');
      print('First cart item types:');
      final firstItem = widget.cartItems.first;
      firstItem.forEach((key, value) {
        print('  $key: $value (type: ${value.runtimeType})');
      });
    }
    print('=====================================');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Complete Payment'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            _buildOrderSummaryCard(),
            SizedBox(height: 20),
            
            // Cart Items Card
            _buildCartItemsCard(),
            SizedBox(height: 20),
            
            // Payment Methods Card
            _buildPaymentMethodsCard(),
            SizedBox(height: 20),
            
            // Proceed to Payment Button
            _buildProceedButton(),
            SizedBox(height: 20),
            
            // Payment Instructions
            _buildPaymentInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Card(
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order ID:', style: TextStyle(fontSize: 16)),
                Text(
                  widget.orderId,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Amount:', style: TextStyle(fontSize: 16)),
                Text(
                  '₹${_formatAmount(widget.amount)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemsCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shopping_cart, color: Colors.blue, size: 24),
                SizedBox(width: 12),
                Text(
                  'Cart Items (${widget.cartItems.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...widget.cartItems.map((item) {
              final productId = item['product_id'] ?? item['Ecomm_product_id'] ?? 'N/A';
              final quantity = _parseQuantity(item['quantity'] ?? item['Quantity'] ?? 1);
              final price = _parsePrice(item['price'] ?? item['Ecomm_product_price'] ?? 0.0);
              final total = _calculateTotal(price, quantity);
              
              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.inventory_2, color: Colors.grey[600]),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product ID: $productId',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Qty: $quantity × ₹${_formatPrice(price)}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${_formatPrice(total)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Card(
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
                    Icon(
                      method['icon'],
                      color: method['color'],
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      method['name'],
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
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
                  child: isSelected
                      ? Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
                tileColor: isSelected ? method['color'].withOpacity(0.1) : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProceedButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _selectedPaymentMethod != null && !_isLoading
            ? _proceedToPayment
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
                'Proceed to Payment',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    return Card(
      elevation: 2,
      color: Colors.blue[50],
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              '1. Select your preferred payment method above\n'
              '2. Click "Proceed to Payment"\n'
              '3. Complete payment on Cashfree\'s secure platform\n'
              '4. Return to app automatically after payment',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue[700],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _proceedToPayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('=== PROCEEDING TO PAYMENT ===');
      print('Selected method: $_selectedPaymentMethod');
      print('Order ID: ${widget.orderId}');
      print('Payment Session ID: ${widget.paymentSessionId}');
      print('Amount: ${widget.amount}');

      // Open Cashfree payment page using payment link (more reliable than session ID)
      // For now, we'll use a test payment link since the session ID approach has endpoint issues
      final paymentUrl = 'https://sandbox.cashfree.com/pg/view/payment?session_id=${widget.paymentSessionId}';
      
      // TODO: Replace with payment link approach when backend is updated
      // The payment link approach is more reliable and doesn't have endpoint errors
      
      print('Opening payment URL: $paymentUrl');
      
      // Check if URL can be launched
      final uri = Uri.parse(paymentUrl);
      print('Parsed URI: $uri');
      
      if (await canLaunchUrl(uri)) {
        print('✅ URL can be launched, opening now...');
        
        // Try external application first
        var launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        // If external fails, try in-app browser
        if (!launched) {
          print('⚠️ External browser failed, trying in-app browser...');
          launched = await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
          );
        }
        
        // If in-app browser fails, try platform default
        if (!launched) {
          print('⚠️ In-app browser failed, trying platform default...');
          launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
        }
        
        if (launched) {
          print('✅ URL launched successfully with mode: ${launched ? "SUCCESS" : "FAILED"}');
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment page opened. Complete payment and return to app.'),
              duration: Duration(seconds: 5),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to payment success screen after a delay
          Future.delayed(Duration(seconds: 3), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentSuccessScreen(
                  orderId: widget.orderId,
                  amount: widget.amount,
                  userId: widget.userId,
                ),
              ),
            );
          });
          
        } else {
          print('❌ URL cannot be launched');
          // Show manual copy option
          _showManualUrlCopy(paymentUrl);
          return;
        }
      } else {
        print('❌ URL cannot be launched');
        // Show manual copy option
        _showManualUrlCopy(paymentUrl);
        return;
      }
      
    } catch (e) {
      print('Error proceeding to payment: $e');
      print('Error type: ${e.runtimeType}');
      
      // Show detailed error message
      String errorMessage = 'Error opening payment page';
      if (e.toString().contains('Could not open payment URL')) {
        errorMessage = 'Unable to open payment page. Please try again or contact support.';
      } else if (e.toString().contains('URL cannot be launched')) {
        errorMessage = 'Payment URL is invalid. Please try again.';
      } else {
        errorMessage = 'Error: $e';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showManualUrlCopy(String url) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Payment URL'),
          content: Text('Please copy and paste the following URL into your browser:\n\n$url'),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount is String) {
      return amount;
    } else if (amount is double) {
      return amount.toStringAsFixed(2);
    }
    return '0.00';
  }

  String _formatPrice(dynamic price) {
    if (price is String) {
      return price;
    } else if (price is double) {
      return price.toStringAsFixed(2);
    }
    return '0.00';
  }

  int _parseQuantity(dynamic quantity) {
    if (quantity is String) {
      return int.tryParse(quantity) ?? 1;
    } else if (quantity is int) {
      return quantity;
    } else if (quantity is double) {
      return quantity.toInt();
    }
    return 1;
  }

  double _parsePrice(dynamic price) {
    if (price is String) {
      return double.tryParse(price) ?? 0.0;
    } else if (price is double) {
      return price;
    } else if (price is int) {
      return price.toDouble();
    }
    return 0.0;
  }

  double _calculateTotal(double price, int quantity) {
    return price * quantity;
  }
}
