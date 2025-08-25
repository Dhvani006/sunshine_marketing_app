import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart';
import 'ecommerce/screens/cart/payment_success_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sunshine Marketing',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginScreen(),
      // Add deep link handling for payment completion
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('/payment_complete') == true) {
          final uri = Uri.parse(settings.name!);
          final orderId = uri.queryParameters['order_id'];
          final status = uri.queryParameters['status'];
          
          if (orderId != null) {
            return MaterialPageRoute(
              builder: (context) => PaymentSuccessScreen(
                orderId: orderId,
                paymentStatus: status ?? 'Success',
              ),
            );
          }
        }
        return null;
      },
    );
  }
}
