import 'package:flutter/material.dart';
import '../../../services/cashfree_service.dart';
import '../../../api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'payment_success_screen.dart';
import 'cashfree_web_checkout_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final int userId;
  final List<Map<String, dynamic>> cartItems;
  final double subtotal;
  final double totalGst;
  final double grandTotal;

  const CheckoutScreen({
    Key? key,
    required this.userId,
    required this.cartItems,
    required this.subtotal,
    required this.totalGst,
    required this.grandTotal,
  }) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  
  bool _isLoading = false;
  String? _orderId;
  String? _paymentSessionId;
  int? _localOrderId;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _createOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // First, create order in Cashfree
      final cashfreeOrderResponse = await CashfreeService.createOrder(
        orderAmount: widget.grandTotal.toString(),
        customerName: _nameController.text,
        customerEmail: _emailController.text,
        customerPhone: _phoneController.text,
        orderNote: 'Order from Sunshine Marketing App',
      );

      if (cashfreeOrderResponse['status'] == 'SUCCESS') {
        setState(() {
          _orderId = cashfreeOrderResponse['order_id'];
          _paymentSessionId = cashfreeOrderResponse['payment_session_id'];
        });

        // Now create order in local database with Cashfree order ID
        final localOrderResponse = await http.post(
          Uri.parse('$baseUrl/create_order.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'user_id': widget.userId,
            'cart_items': widget.cartItems,
            'total_amount': widget.grandTotal,
            'cashfree_order_id': _orderId,
            'address': _addressController.text,
            'city': _cityController.text,
            'state': _stateController.text,
            'pincode': _pincodeController.text,
          }),
        );

        if (localOrderResponse.statusCode != 200) {
          throw Exception('Failed to create local order with Cashfree ID');
        }

        final localOrderData = json.decode(localOrderResponse.body);
        print('Local order response: $localOrderData');
        print('Response type: ${localOrderData.runtimeType}');
        
        final localOrderIds = localOrderData['order_ids'] as List;
        print('Local order IDs: $localOrderIds');
        print('Order IDs type: ${localOrderIds.runtimeType}');
        print('First order ID: ${localOrderIds.first} (type: ${localOrderIds.first.runtimeType})');
        
        // Store the first local order ID for payment processing
        if (localOrderIds.isNotEmpty) {
          // Ensure proper type casting - the response might be coming as dynamic
          final firstOrderId = localOrderIds.first;
          if (firstOrderId is int) {
            _localOrderId = firstOrderId;
          } else {
            _localOrderId = int.tryParse(firstOrderId.toString()) ?? 0;
          }
          print('Set local order ID to: $_localOrderId (type: ${_localOrderId.runtimeType})');
          
          // Verify we have a valid local order ID before proceeding
          if (_localOrderId != null && _localOrderId! > 0) {
            // Process payment
            await _processPayment();
          } else {
            throw Exception('Failed to get valid local order ID');
          }
        } else {
          print('No order IDs returned from create_order.php');
          throw Exception('No order IDs returned from create_order.php');
        }
      } else {
        throw Exception('Failed to create Cashfree order: ${cashfreeOrderResponse['message']}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating order: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processPayment() async {
    if (_orderId == null || _paymentSessionId == null || _localOrderId == null) {
      print('Missing required data for payment processing');
      return;
    }

    try {
      print('Processing payment with:');
      print('- Cashfree Order ID: $_orderId');
      print('- Payment Session ID: $_paymentSessionId');
      print('- Local Order ID: $_localOrderId');
      
      // Navigate to Cashfree web checkout for real payment
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CashfreeWebCheckoutScreen(
            orderId: _orderId!,
            paymentSessionId: _paymentSessionId!,
            userId: widget.userId,
            amount: widget.grandTotal,
            localOrderId: _localOrderId!,
          ),
        ),
      );
      
    } catch (e) {
      print('Exception in _processPayment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment error: $e')),
      );
    }
  }

  Future<void> _savePaymentDetails(int orderId, {String? transactionId}) async {
    try {
      if (orderId == 0) {
        print('Invalid order ID: $orderId');
        return;
      }

      final paymentData = {
        'user_id': widget.userId,
        'order_id': orderId, // Use the passed orderId parameter
        'payment_method': 'UPI', // Map to your database enum
        'amount': widget.grandTotal,
        'payment_status': 'Success', // Match your database enum exactly
        'transaction_id': transactionId ?? 'CF_${DateTime.now().millisecondsSinceEpoch}',
      };
      
      print('Sending payment data: $paymentData');
      print('Data types: user_id(${widget.userId.runtimeType}), order_id(${orderId.runtimeType}), amount(${widget.grandTotal.runtimeType})');

      final response = await http.post(
        Uri.parse('$baseUrl/save_payment.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(paymentData),
      );

      if (response.statusCode != 200) {
        print('Failed to save payment details: ${response.statusCode}');
        final responseBody = response.body;
        print('Response body: $responseBody');
      } else {
        print('Payment details saved successfully');
        final responseBody = response.body;
        print('Success response: $responseBody');
      }
    } catch (e) {
      print('Error saving payment details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  if (value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your city';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: InputDecoration(
                        labelText: 'State',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your state';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _pincodeController,
                decoration: InputDecoration(
                  labelText: 'Pincode',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your pincode';
                  }
                  if (value.length != 6) {
                    return 'Please enter a valid 6-digit pincode';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              
              Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal:'),
                          Text('₹${widget.subtotal.toStringAsFixed(2)}'),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('GST:'),
                          Text('₹${widget.totalGst.toStringAsFixed(2)}'),
                        ],
                      ),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₹${widget.grandTotal.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Proceed to Payment',
                          style: TextStyle(fontSize: 18),
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
