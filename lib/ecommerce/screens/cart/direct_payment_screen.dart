import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'payment_success_screen.dart';
import '../../../api_config.dart';

class DirectPaymentScreen extends StatefulWidget {
  final String orderId;
  final int userId;
  final dynamic amount;
  final int localOrderId;
  final List<Map<String, dynamic>> cartItems;

  const DirectPaymentScreen({
    Key? key,
    required this.orderId,
    required this.userId,
    required this.amount,
    required this.localOrderId,
    required this.cartItems,
  }) : super(key: key);

  @override
  _DirectPaymentScreenState createState() => _DirectPaymentScreenState();
}

class _DirectPaymentScreenState extends State<DirectPaymentScreen> {
  bool _isLoading = false;
  String? _selectedPaymentMethod;
  final _formKey = GlobalKey<FormState>();
  
  // Payment form fields
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  final _upiController = TextEditingController();

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'card',
      'name': 'Credit/Debit Card',
      'icon': Icons.credit_card,
      'color': Colors.green,
      'description': 'Visa, Mastercard, RuPay, American Express'
    },
    {
      'id': 'upi',
      'name': 'UPI',
      'icon': Icons.account_balance_wallet,
      'color': Colors.blue,
      'description': 'Pay using UPI ID or QR Code'
    },
    {
      'id': 'netbanking',
      'name': 'Net Banking',
      'icon': Icons.account_balance,
      'color': Colors.orange,
      'description': 'All major banks supported'
    },
  ];

  @override
  void initState() {
    super.initState();
    _nameController.text = 'Test User'; // Pre-fill for testing
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Direct Payment'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary
            _buildOrderSummaryCard(),
            SizedBox(height: 20),
            
            // Payment Methods Selection
            _buildPaymentMethodsCard(),
            SizedBox(height: 20),
            
            // Payment Form
            if (_selectedPaymentMethod != null) _buildPaymentForm(),
            
            // Proceed Button
            if (_selectedPaymentMethod != null) _buildProceedButton(),
            
            // Instructions
            _buildInstructions(),
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
                  '₹${_formatAmount(widget.amount)}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ],
            ),
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
    );
  }

  Widget _buildPaymentForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Payment Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 16),
              
              if (_selectedPaymentMethod == 'card') ...[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Cardholder Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Please enter cardholder name' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _cardNumberController,
                  decoration: InputDecoration(
                    labelText: 'Card Number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.credit_card),
                    hintText: '1234 5678 9012 3456',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.isEmpty == true ? 'Please enter card number' : null,
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiryController,
                        decoration: InputDecoration(
                          labelText: 'Expiry (MM/YY)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: Icon(Icons.calendar_today),
                          hintText: '12/25',
                        ),
                        validator: (value) => value?.isEmpty == true ? 'Please enter expiry' : null,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        decoration: InputDecoration(
                          labelText: 'CVV',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          prefixIcon: Icon(Icons.security),
                          hintText: '123',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value?.isEmpty == true ? 'Please enter CVV' : null,
                      ),
                    ),
                  ],
                ),
              ] else if (_selectedPaymentMethod == 'upi') ...[
                TextFormField(
                  controller: _upiController,
                  decoration: InputDecoration(
                    labelText: 'UPI ID',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    prefixIcon: Icon(Icons.account_balance_wallet),
                    hintText: 'username@upi',
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Please enter UPI ID' : null,
                ),
              ] else if (_selectedPaymentMethod == 'netbanking') ...[
                Text(
                  'Net Banking will be handled by your bank\'s secure gateway.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProceedButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: !_isLoading ? _processPayment : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
                'Process Payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildInstructions() {
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
                  'About This Approach:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'This is a custom payment form that bypasses Cashfree\'s problematic endpoints. '
              'For testing purposes, you can enter any valid-looking data. '
              'In production, this would integrate with a real payment gateway.',
              style: TextStyle(fontSize: 14, color: Colors.blue[700], height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate payment processing
      await Future.delayed(Duration(seconds: 2));
      
      // For testing, always succeed
      // In production, this would call a real payment gateway
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment processed successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to success screen
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

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: $e'),
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

  String _formatAmount(dynamic amount) {
    if (amount is String) {
      return amount;
    } else if (amount is double) {
      return amount.toStringAsFixed(2);
    }
    return '0.00';
  }
}
