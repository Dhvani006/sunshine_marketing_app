import 'package:flutter/material.dart';
import 'package:flutter_cashfree_pg_sdk/flutter_cashfree_pg_sdk.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cashfree Integration Test',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  @override
  _TestScreenState createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  late CFPaymentGatewayService _cfPaymentGatewayService;
  String _status = 'Ready to test';

  @override
  void initState() {
    super.initState();
    _cfPaymentGatewayService = CFPaymentGatewayService();
    _cfPaymentGatewayService.setCallback(_onPaymentSuccess, _onPaymentError);
  }

  void _onPaymentSuccess(String orderId) {
    setState(() {
      _status = 'Payment successful! Order ID: $orderId';
    });
    print("Payment successful for order: $orderId");
  }

  void _onPaymentError(CFErrorResponse errorResponse, String orderId) {
    setState(() {
      _status = 'Payment failed: ${errorResponse.getMessage()}';
    });
    print("Payment failed: ${errorResponse.getMessage()}");
  }

  void _testCashfreeSDK() {
    setState(() {
      _status = 'Testing Cashfree SDK...';
    });

    try {
      // Test creating a session (this will fail without proper order details, but tests the SDK)
      final session = CFSessionBuilder()
          .setEnvironment(CFEnvironment.TEST)
          .setOrderId('test_order_${DateTime.now().millisecondsSinceEpoch}')
          .setPaymentSessionId('test_session_${DateTime.now().millisecondsSinceEpoch}')
          .build();

      setState(() {
        _status = 'SDK test successful! Session created.';
      });
      print("SDK test successful - session created");
    } catch (e) {
      setState(() {
        _status = 'SDK test failed: $e';
      });
      print("SDK test failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cashfree Integration Test'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment,
              size: 100,
              color: Colors.orange,
            ),
            SizedBox(height: 32),
            Text(
              'Cashfree SDK Test',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'This screen tests if the Cashfree Flutter SDK is properly integrated.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: _testCashfreeSDK,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text('Test Cashfree SDK'),
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
                    'Status:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Text(
              'If the test is successful, you can proceed with the full integration.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}





