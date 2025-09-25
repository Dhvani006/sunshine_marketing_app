import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../api_config.dart' as ApiConfig;
import 'order_success_screen.dart';
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
    print('=== CHECKOUT PROCESS STARTED ===');
    print('Form validation: ${_formKey.currentState?.validate()}');
    print('Name controller text: "${_nameController.text}"');
    print('Email controller text: "${_emailController.text}"');
    print('Phone controller text: "${_phoneController.text}"');
    print('Address controller text: "${_addressController.text}"');
    print('City controller text: "${_cityController.text}"');
    print('State controller text: "${_stateController.text}"');
    print('Pincode controller text: "${_pincodeController.text}"');
    print('User ID: ${widget.userId}');
    print('Cart items count: ${widget.cartItems.length}');
    print('Cart items: ${widget.cartItems}');
    print('Grand total: ${widget.grandTotal}');
    print('=====================================');

    if (!_formKey.currentState!.validate()) {
      print('❌ FORM VALIDATION FAILED');
      return;
    }

    print('✅ FORM VALIDATION PASSED');

    setState(() {
      _isLoading = true;
    });

    try {
      print('=== CREATING LOCAL ORDER ===');
      
      // ✅ STEP 1: Create local order in database first
      final orderData = {
        'user_id': widget.userId,
        'items': widget.cartItems.map((item) => {
          'id': item['Ecomm_product_id'],
          'quantity': item['Quantity'],
          'price': item['Ecomm_product_price'],
        }).toList(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'payment_method': 'online',
        'total_amount': widget.grandTotal,
        'order_notes': 'Order from Sunshine Marketing App',
        'order_status': 'Pending',
        'payment_status': 'Pending',
      };
      
      print('Creating local order with data: $orderData');
      
      final orderResponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/create_order.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );
      
      print('Order creation response: ${orderResponse.statusCode}');
      print('Order creation body: ${orderResponse.body}');
      
      if (orderResponse.statusCode != 200) {
        throw Exception('Failed to create local order: ${orderResponse.body}');
      }
      
      final orderResult = json.decode(orderResponse.body);
      if (!orderResult['success']) {
        throw Exception('Order creation failed: ${orderResult['message']}');
      }
      
      final orderIds = orderResult['data']['order_ids'] as List;
      final localOrderId = int.parse(orderIds.first.toString()); // Convert to int
      
      setState(() {
        _localOrderId = localOrderId;
      });
      
      print('✅ LOCAL ORDER CREATED: ID=$localOrderId');
        
        // ✅ STEP 2: Create Cashfree session on backend
        final sessionResponse = await http.post(
          Uri.parse(ApiConfig.cashfreeOrderUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'order_amount': widget.grandTotal,
            'order_currency': 'INR',
            'customer_id': 'cust_${widget.userId}',
            'customer_name': _nameController.text.trim(),
            'customer_email': _emailController.text.trim(),
            'customer_phone': _phoneController.text.trim(),
            'order_note': 'Order from Sunshine Marketing App',
            'local_order_id': localOrderId, // Include local order ID
          }),
        );

        print('✅ Session creation response: ${sessionResponse.statusCode}');
        print('✅ Response body: ${sessionResponse.body}');

        if (sessionResponse.statusCode == 200) {
          final sessionData = json.decode(sessionResponse.body);
          print('✅ Parsed sessionData: $sessionData');
          print('✅ sessionData success: ${sessionData['success']}');
          print('✅ sessionData type: ${sessionData['success'].runtimeType}');
          
          if (sessionData['success'] == true) {
            final cashfreeOrderId = sessionData['data']['order_id'];
            final paymentSessionId = sessionData['data']['payment_session_id'];
            
            print('🔑 Cashfree Order ID: $cashfreeOrderId');
            print('🔑 Payment Session ID: $paymentSessionId');
            
            // ✅ STEP 2: Navigate to Cashfree checkout screen (same as website)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CashfreeWebCheckoutScreen(
                  orderId: cashfreeOrderId,
                  paymentSessionId: paymentSessionId,
                ),
              ),
            ).then((_) {
              // After returning from checkout, navigate to order success screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderSuccessScreen(
                    orderId: cashfreeOrderId,
                    paymentSessionId: paymentSessionId,
                  ),
                ),
              );
            });
            
          } else {
            // Handle configuration errors specifically
            String errorMessage = sessionData['message'] ?? 'Failed to create payment session';
            if (sessionData['message']?.contains('not configured') == true) {
              errorMessage = 'Payment gateway not configured. Please contact support.';
            }
            throw Exception(errorMessage);
          }
        } else {
          final errorBody = sessionResponse.body;
          print('❌ Session creation failed: $errorBody');
          
          // Try to parse error for better user experience
          try {
            final errorData = json.decode(errorBody);
            String errorMessage = errorData['message'] ?? 'Payment session creation failed';
            if (errorData['message']?.contains('not configured') == true) {
              errorMessage = 'Payment gateway not configured. Please contact support.';
            }
            throw Exception(errorMessage);
          } catch (e) {
            throw Exception('HTTP ${sessionResponse.statusCode}: Payment session creation failed');
          }
        }
    } catch (e) {
      print('=== EXCEPTION CAUGHT ===');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: ${StackTrace.current}');
      print('========================');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating order: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('=== CHECKOUT PROCESS ENDED ===');
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
        Uri.parse(ApiConfig.savePaymentUrl),
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
