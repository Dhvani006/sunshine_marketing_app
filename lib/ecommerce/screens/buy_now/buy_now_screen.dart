import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../api_config.dart';

class BuyNowScreen extends StatefulWidget {
  final int productId;
  final String productName;
  final double productPrice;
  final int quantity;
  final int userId;
  const BuyNowScreen({
    Key? key,
    required this.productId,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    required this.userId,
  }) : super(key: key);

  @override
  State<BuyNowScreen> createState() => _BuyNowScreenState();
}

class _BuyNowScreenState extends State<BuyNowScreen> {
  int quantity = 1;
  static const double gstRate = 0.18;
  bool isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    quantity = widget.quantity;
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.productPrice;
    final subtotal = price * quantity;
    final gst = subtotal * gstRate;
    final total = subtotal + gst;

    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Color(0xFFCC9900), Color(0xFFFFD700)], // Darker to lighter yellow
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: const Text(
            'Buy Now',
            style: TextStyle(
              color: Colors.white, // Color is masked by gradient
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.productName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text('Unit Price: ₹${price.toStringAsFixed(2)}'),
            Row(
              children: [
                const Text('Quantity:'),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                ),
                Text('$quantity'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => quantity++),
                ),
              ],
            ),
            Text('Subtotal: ₹${subtotal.toStringAsFixed(2)}'),
            Text('GST (18%): ₹${gst.toStringAsFixed(2)}'),
            Text('Total: ₹${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const Spacer(),
            isPlacingOrder
                ? const Center(child: CircularProgressIndicator())
                : Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFFA500), Color(0xFFFFD700)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() { isPlacingOrder = true; });
                        final response = await http.post(
                          Uri.parse('$baseUrl/create_order.php'),
                          body: {
                            'user_id': widget.userId.toString(),
                            'ecomm_product_id': widget.productId.toString(),
                            'quantity': quantity.toString(),
                            'total_amount': total.toStringAsFixed(2),
                          },
                        );
                        setState(() { isPlacingOrder = false; });
                        final data = json.decode(response.body);
                        if (data['status'] == 'success') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Order placed successfully!')),
                          );
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(data['message'] ?? 'Order failed')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Place Order',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
} 