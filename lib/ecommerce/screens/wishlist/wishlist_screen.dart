import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/product_card.dart';
import '../../../widgets/custom_app_bar.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'My Wishlist',
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 16), // Add bottom padding
        child: GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.7,
          ),
          itemCount: 6, // Demo wishlist items count
          itemBuilder: (context, index) {
            return SizedBox(
              height: 280,
              child: ProductCard(
                imageUrl: 'assets/images/product${(index % 2) + 1}.svg',
                name: 'Product ${index + 1}',
                price: (19.99 + index * 10).toDouble(),
                discount: index % 2 == 0 ? 20 : 0,
                onAddToCart: () {
                  // TODO: Implement add to cart
                },
                onToggleWishlist: () {
                  // TODO: Implement remove from wishlist
                },
              )
              .animate()
              .fadeIn(delay: 100.milliseconds * index)
              .slideY(begin: 0.2),
            );
          },
        ),
      ),
    );
  }
} 