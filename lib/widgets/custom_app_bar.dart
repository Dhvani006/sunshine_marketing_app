import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../ecommerce/providers/cart_provider.dart';
import '../ecommerce/screens/cart/cart_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showCart;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showCart = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    return AppBar(
      title: Text(title),
      actions: [
        if (actions != null) ...actions!,
        if (showCart)
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  final userId = prefs.getInt('user_id');
                  if (userId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CartScreen(userId: userId)),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('You must be logged in to view the cart.')),
                    );
                  }
                },
              ),
              if (cartProvider.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${cartProvider.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 