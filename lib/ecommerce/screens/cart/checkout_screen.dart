import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../api_config.dart';

import '../categories/categories_screen.dart';
import '../cart/cart_screen.dart';
import '../profile/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutScreen extends StatefulWidget {
  final int userId;
  const CheckoutScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false;
  List<dynamic> cartItems = [];
  double subtotal = 0.0;
  double totalGst = 0.0;
  double grandTotal = 0.0;
  String address = '';

  @override
  void initState() {
    super.initState();
    fetchCartAndAddress();
  }

  Future<void> fetchCartAndAddress() async {
    setState(() => _isLoading = true);
    try {
      final cartRes = await http
          .get(Uri.parse('$baseUrl/get_cart.php?user_id=${widget.userId}'));
      final cartData = json.decode(cartRes.body);
      if (cartData['status'] == 'success') {
        cartItems = cartData['cart'];
        subtotal = 0.0;
        totalGst = 0.0;
        for (final item in cartItems) {
          final price =
              double.tryParse(item['Ecomm_product_price'].toString()) ?? 0.0;
          final quantity = int.tryParse(item['Quantity'].toString()) ?? 0;
          final itemSubtotal = price * quantity;
          subtotal += itemSubtotal;
          totalGst += itemSubtotal * 0.18;
        }
        grandTotal = subtotal + totalGst;
      }
      final userRes = await http
          .get(Uri.parse('$baseUrl/get_user.php?user_id=${widget.userId}'));
      final userData = json.decode(userRes.body);
      if (userData['status'] == 'success') {
        address = userData['user']['Address'] ?? '';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> placeOrder() async {
    setState(() => _isLoading = true);
    try {
      for (final item in cartItems) {
        final response = await http.post(
          Uri.parse('$baseUrl/create_order.php'),
          body: {
            'user_id': widget.userId.toString(),
            'ecomm_product_id': item['Ecomm_product_id'].toString(),
            'quantity': item['Quantity'].toString(),
            'total_amount': grandTotal.toString(),
          },
        );
        final data = json.decode(response.body);
        if (data['status'] != 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Order failed')),
          );
          setState(() => _isLoading = false);
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFFCC9900), Color(0xFFFFD700)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: const Text(
            'Checkout',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 232, 236, 236),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFD700)),
        leading: IconButton(
          icon: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFCC9900), Color(0xFFFFD700)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Delivery Address:',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(address),
                  const SizedBox(height: 16),
                  const Text('Order Summary:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        return ListTile(
                          title: Text(item['Ecomm_product_name'] ?? ''),
                          subtitle: Text('Qty: ${item['Quantity']}'),
                          trailing: Text('₹${item['Ecomm_product_price']}'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Subtotal: ₹${subtotal.toStringAsFixed(2)}'),
                  Text('GST (18%): ₹${totalGst.toStringAsFixed(2)}'),
                  Text('Total: ₹${grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFA500), Color(0xFFFFD700)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(51),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : placeOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Place Order',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 3, // Cart is selected
        selectedItemColor: const Color(0xFFF37E15),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.popUntil(context, (route) => route.isFirst);
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoriesScreen(),
                ),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => CartScreen(userId: widget.userId),
                ),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
              break;
          }
        },
      ),
    );
  }
}
