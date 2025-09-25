import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_screen.dart';
import 'ecommerce/screens/cart/payment_success_screen.dart';
import 'ecommerce/screens/cart/payment_pending_screen.dart';
import 'ecommerce/screens/cart/payment_failed_screen.dart';
import 'api_config.dart' as ApiConfig;

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
        print('=== DEEP LINK ROUTE GENERATION ===');
        print('Route name: ${settings.name}');
        print('Route arguments: ${settings.arguments}');
        
        if (settings.name?.startsWith('/payment_complete') == true) {
          print('Processing payment completion deep link');
          final uri = Uri.parse(settings.name!);
          final orderId = uri.queryParameters['order_id'];
          final status = uri.queryParameters['status'];
          
          print('Order ID: $orderId');
          print('Status: $status');
          
          if (orderId != null) {
            print('Creating PaymentSuccessScreenWithData route');
            return MaterialPageRoute(
              builder: (context) => PaymentSuccessScreenWithData(
                orderId: orderId,
                status: status ?? 'UNKNOWN',
              ),
            );
          } else {
            print('ERROR: Order ID is null');
          }
        }
        
        print('No matching route found, returning null');
        return null;
      },
    );
  }
}

class PaymentSuccessScreenWithData extends StatefulWidget {
  final String orderId;
  final String status;

  const PaymentSuccessScreenWithData({
    Key? key,
    required this.orderId,
    required this.status,
  }) : super(key: key);

  @override
  State<PaymentSuccessScreenWithData> createState() => _PaymentSuccessScreenWithDataState();
}

class _PaymentSuccessScreenWithDataState extends State<PaymentSuccessScreenWithData> {
  bool _isLoading = true;
  Map<String, dynamic>? _orderDetails;
  Map<String, dynamic>? _paymentDetails;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('=== PaymentSuccessScreenWithData INIT ===');
    print('Order ID: ${widget.orderId}');
    print('Status: ${widget.status}');
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      print('=== FETCHING ORDER DETAILS FOR DEEP LINK ===');
      print('Order ID: ${widget.orderId}');
      print('Status: ${widget.status}');
      
      // Fetch order details from backend
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/get_order_details.php?order_id=${widget.orderId}'),
      );
      
      print('✅ Order Details Response: ${response.statusCode}');
      print('✅ Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          setState(() {
            _orderDetails = data['order'];
            _paymentDetails = data['payment'];
            _isLoading = false;
          });
          
          print('✅ Order details loaded successfully');
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to load order details';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'HTTP Error: ${response.statusCode}';
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print('❌ Error fetching order details: $e');
      setState(() {
        _errorMessage = 'Error loading order details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading...'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Loading order details...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Error'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 20),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }

    // Show appropriate screen based on payment status
    if (widget.status == 'SUCCESS') {
      return PaymentSuccessScreen(
        orderId: widget.orderId,
        amount: _orderDetails?['Total_amount'] ?? 0.0,
        userId: _orderDetails?['User_id'] ?? 0,
        onComplete: () {
          // Navigate to home page after payment success
          print('Payment success completed, navigating to home');
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        },
      );
    } else if (widget.status == 'PENDING') {
      return PaymentPendingScreen(
        orderId: widget.orderId,
        amount: _orderDetails?['Total_amount'] ?? 0.0,
        userId: _orderDetails?['User_id'] ?? 0,
        onComplete: () {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        },
      );
    } else {
      return PaymentFailedScreen(
        orderId: widget.orderId,
        amount: _orderDetails?['Total_amount'] ?? 0.0,
        userId: _orderDetails?['User_id'] ?? 0,
        errorMessage: widget.status == 'ERROR' ? 'Payment processing error' : 'Payment failed',
        onComplete: () {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        },
      );
    }
  }
}
