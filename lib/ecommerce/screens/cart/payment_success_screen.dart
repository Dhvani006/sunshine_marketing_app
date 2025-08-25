import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String orderId;
  final String paymentStatus;

  const PaymentSuccessScreen({
    Key? key,
    required this.orderId,
    this.paymentStatus = 'Success',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment ${paymentStatus == 'Success' ? 'Successful' : 'Status'}'),
        backgroundColor: paymentStatus == 'Success' ? Colors.green : Colors.orange,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 50),
            
            // Success Animation
            Container(
              width: 200,
              height: 200,
              child: paymentStatus == 'Success' 
                ? Lottie.asset(
                    'assets/animations/payment_success.json',
                    fit: BoxFit.contain,
                  )
                : Icon(
                    Icons.pending,
                    size: 200,
                    color: Colors.orange,
                  ),
            ),
            
            SizedBox(height: 30),
            
            Text(
              paymentStatus == 'Success' 
                ? 'Payment Successful! 🎉'
                : 'Payment Status: $paymentStatus',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: paymentStatus == 'Success' ? Colors.green : Colors.orange,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 16),
            
            Text(
              paymentStatus == 'Success'
                ? 'Your order has been placed successfully and payment has been received.'
                : 'Your payment is being processed. Please wait for confirmation.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 24),
            
            // Order Details Card
            Card(
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Order Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order ID:'),
                        Text(
                          orderId,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Status:'),
                        Text(
                          paymentStatus == 'Success' ? 'Paid' : 'Pending',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: paymentStatus == 'Success' ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 30),
            
            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate back to home or order history
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Continue Shopping',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  // Navigate to order history or track order
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: BorderSide(color: Colors.orange),
                ),
                child: Text(
                  'View Order History',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
