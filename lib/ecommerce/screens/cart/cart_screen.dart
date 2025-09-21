import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../widgets/custom_app_bar.dart';
import '../../../api_config.dart';
import 'checkout_screen.dart';

import '../categories/categories_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/modern_bottom_navigation.dart';

class CartScreen extends StatefulWidget {
  final int userId;
  const CartScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<dynamic> cartItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  Future<void> fetchCartItems() async {
    setState(() {
      isLoading = true;
    });
    final response = await http
        .get(Uri.parse('$baseUrl/get_cart.php?user_id=${widget.userId}'));
    final data = json.decode(response.body);
    if (data['status'] == 'success') {
      setState(() {
        cartItems = data['cart'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Failed to load cart')),
      );
    }
  }

  Future<void> updateCartQuantity(int cartId, int quantity, int index) async {
    print('Sending update: cartId=$cartId, quantity=$quantity');
    final response = await http.post(
      Uri.parse('$baseUrl/update_cart_quantity.php'),
      body: {
        'cart_id': cartId.toString(),
        'quantity': quantity.toString(),
      },
    );
    print('Update response: ${response.body}');
    final data = json.decode(response.body);
    if (data['status'] == 'success') {
      setState(() {
        cartItems[index]['Quantity'] = quantity;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Failed to update quantity')),
      );
    }
  }

  Future<void> deleteCartItem(int cartId, int index) async {
    print('Sending delete: cartId=$cartId');
    final response = await http.post(
      Uri.parse('$baseUrl/delete_cart_item.php'),
      body: {
        'cart_id': cartId.toString(),
      },
    );
    print('Delete response: ${response.body}');
    final data = json.decode(response.body);
    if (data['status'] == 'success') {
      setState(() {
        cartItems.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Failed to remove item')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = 0.0;
    for (final item in cartItems) {
      final price =
          double.tryParse(item['Ecomm_product_price'].toString()) ?? 0.0;
      final quantity = int.tryParse(item['Quantity'].toString()) ?? 0;
      final itemSubtotal = price * quantity;
      subtotal += itemSubtotal;
    }
    final grandTotal = subtotal;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Shopping Cart',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? Center(child: Text('Your cart is empty.'))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          final price = double.tryParse(
                                  item['Ecomm_product_price'].toString()) ??
                              0.0;
                          final quantity =
                              int.tryParse(item['Quantity'].toString()) ?? 0;
                          final subtotal = price * quantity;
                          final itemTotal = subtotal;
                          final imagePath =
                              item['Ecomm_product_image']?.toString() ?? '';
                          String finalImagePath;

                          if (imagePath.startsWith('http')) {
                            // If it's a full URL, extract just the filename
                            final uri = Uri.parse(imagePath);
                            finalImagePath = uri.pathSegments.last;
                          } else {
                            // If it's a relative path, remove uploads/ prefix if present
                            finalImagePath = imagePath;
                            if (finalImagePath.startsWith('uploads/')) {
                              finalImagePath =
                                  finalImagePath.substring('uploads/'.length);
                            }
                          }
                          final imageUrl = '$uploadsUrl$finalImagePath';
                          return Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Product Image
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[100],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.image,
                                              size: 30,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Product Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['Ecomm_product_name'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₹${price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Quantity Controls
                                        Row(
                                          children: [
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: IconButton(
                                                icon: const Icon(Icons.remove, size: 16),
                                                onPressed: quantity > 1
                                                    ? () async {
                                                        await updateCartQuantity(
                                                            item['Cart_id'],
                                                            quantity - 1,
                                                            index);
                                                      }
                                                    : null,
                                                padding: EdgeInsets.zero,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '$quantity',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: Colors.yellow[600],
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: IconButton(
                                                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                                                onPressed: () async {
                                                  await updateCartQuantity(
                                                      item['Cart_id'],
                                                      quantity + 1,
                                                      index);
                                                },
                                                padding: EdgeInsets.zero,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Delete Button and Total
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () async {
                                          await deleteCartItem(item['Cart_id'], index);
                                        },
                                      ),
                                      Text(
                                        '₹${itemTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total:',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                '₹${grandTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.yellow[600],
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: cartItems.isEmpty
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CheckoutScreen(
                                                userId: widget.userId,
                                                cartItems: cartItems.cast<Map<String, dynamic>>(),
                                                subtotal: subtotal,
                                                totalGst: 0.0,
                                                grandTotal: grandTotal,
                                              ),
                                        ),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.shopping_cart,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'PROCEED TO CHECKOUT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
      // Bottom Navigation
      bottomNavigationBar: ModernBottomNavigation(
        currentIndex: 2,
        userId: widget.userId,
      ),
    );
  }
}
