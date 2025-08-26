import 'package:flutter/material.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String orderId;
  final dynamic amount; // Changed from double to dynamic to handle both types
  final int userId;

  const PaymentSuccessScreen({
    Key? key,
    required this.orderId,
    required this.amount,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Debug logging
    print('=== PAYMENT SUCCESS SCREEN DEBUG ===');
    print('orderId: $orderId (type: ${orderId.runtimeType})');
    print('amount: $amount (type: ${amount.runtimeType})');
    print('userId: $userId (type: ${userId.runtimeType})');
    print('=====================================');
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Success'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  size: 80,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 32),
              
              // Success Message
              Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              
              Text(
                'Your order has been placed successfully.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              
              // Order Details
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order ID:', style: TextStyle(fontSize: 16)),
                        Text(
                          orderId,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Amount:', style: TextStyle(fontSize: 16)),
                        Text(
                          '₹${_formatAmount(amount)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate back to home/cart
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Continue Shopping',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // View order details (you can implement this later)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Order details feature coming soon!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'View Order',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
}
