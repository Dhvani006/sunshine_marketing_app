import 'package:flutter/material.dart';
import 'lib/ecommerce/screens/checkout_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checkout Navigation Test',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: TestNavigationScreen(),
    );
  }
}

class TestNavigationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Sample cart data
    final cartItems = [
      {
        'Ecomm_product_id': 1,
        'Ecomm_product_name': 'TestMobile',
        'Quantity': 2,
        'Ecomm_product_price': 12000.00,
      }
    ];
    
    final subtotal = 24000.0;
    final totalGst = 4320.0; // 18% GST
    final grandTotal = 28320.0;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Checkout Navigation'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Test Navigation to Checkout',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),
            Text('Cart Items: ${cartItems.length}'),
            Text('Subtotal: ₹${subtotal.toStringAsFixed(2)}'),
            Text('GST (18%): ₹${totalGst.toStringAsFixed(2)}'),
            Text('Total: ₹${grandTotal.toStringAsFixed(2)}'),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutScreen(
                      userId: 2, // Sample user ID
                      cartItems: cartItems,
                      subtotal: subtotal,
                      totalGst: totalGst,
                      grandTotal: grandTotal,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text('Go to Checkout'),
            ),
            SizedBox(height: 32),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  Text(
                    'Navigation Test Instructions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Click "Go to Checkout"\n'
                    '2. Fill in customer details\n'
                    '3. Click "Proceed to Payment"\n'
                    '4. Complete payment in Cashfree\n'
                    '5. Verify order is saved in database',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}





