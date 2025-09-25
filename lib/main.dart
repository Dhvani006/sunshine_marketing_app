import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'login_screen.dart';
import 'ecommerce/screens/cart/payment_success_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set WebView platform for Android only
  if (WebViewPlatform.instance == null) {
    WebViewPlatform.instance = AndroidWebViewPlatform();
  }

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
                amount: 0.0, // Default amount, you can modify this later
                userId: 0, // Default user ID, you can modify this later
              ),
            );
          }
        }
        return null;
      },
    );
  }
}
