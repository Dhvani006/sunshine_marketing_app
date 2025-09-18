import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../widgets/custom_app_bar.dart';
import '../../../api_config.dart';
import 'address_entry_screen.dart';

import '../categories/categories_screen.dart';
import '../profile/profile_screen.dart';

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
    final response = await http.get(
      Uri.parse('$baseUrl/get_cart.php?user_id=${widget.userId}'),
    );
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
      body: {'cart_id': cartId.toString(), 'quantity': quantity.toString()},
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
      body: {'cart_id': cartId.toString()},
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
        title: const Text(
          'Shopping Cart',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFF37E15)),
      ),
      body:
          isLoading
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
                        final price =
                            double.tryParse(
                              item['Ecomm_product_price'].toString(),
                            ) ??
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
                            finalImagePath = finalImagePath.substring(
                              'uploads/'.length,
                            );
                          }
                        }
                        final imageUrl = '$uploadsUrl$finalImagePath';
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          elevation: 4,
                          shadowColor: Colors.grey.withOpacity(0.3),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.network(
                                  imageUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.shopping_bag,
                                        size: 30,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['Ecomm_product_name'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Unit Price: ₹${price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF007B8F),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Quantity: $quantity',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Item Total: ₹${itemTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFFF37E15),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF37E15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.remove,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                              padding: EdgeInsets.zero,
                                              onPressed:
                                                  quantity > 1
                                                      ? () async {
                                                        print(
                                                          'Minus button pressed',
                                                        );
                                                        await updateCartQuantity(
                                                          item['Cart_id'],
                                                          quantity - 1,
                                                          index,
                                                        );
                                                      }
                                                      : null,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$quantity',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF37E15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.add,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                              padding: EdgeInsets.zero,
                                              onPressed: () async {
                                                print('Plus button pressed');
                                                await updateCartQuantity(
                                                  item['Cart_id'],
                                                  quantity + 1,
                                                  index,
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () async {
                                    print('Delete button pressed');
                                    await deleteCartItem(
                                      item['Cart_id'],
                                      index,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '₹${grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          height: 55,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.red, // Red
                                Color(0xFFD32F2F), // Darker Red
                              ],
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
                            onPressed:
                                cartItems.isEmpty
                                    ? null
                                    : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => AddressEntryScreen(
                                                userId: widget.userId,
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
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.flash_on,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'ADD TO CART',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2, // Cart is selected
        selectedItemColor: const Color(0xFFF37E15),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
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
              // Already on cart screen, do nothing
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              break;
          }
        },
      ),
    );
  }
}
