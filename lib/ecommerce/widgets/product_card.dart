import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/colors.dart';

class ProductCard extends StatefulWidget {
  final String imageUrl;
  final String name;
  final double price;
  final int discount;
  final VoidCallback onAddToCart;
  final VoidCallback onToggleWishlist;

  const ProductCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.price,
    required this.discount,
    required this.onAddToCart,
    required this.onToggleWishlist,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isWishlisted = false;
  bool _isAddingToCart = false;

  void _handleAddToCart() {
    setState(() => _isAddingToCart = true);
    Future.delayed(300.milliseconds, () {
      setState(() => _isAddingToCart = false);
      widget.onAddToCart();
    });
  }

  void _handleToggleWishlist() {
    setState(() => _isWishlisted = !_isWishlisted);
    widget.onToggleWishlist();
  }

  @override
  Widget build(BuildContext context) {
    final discountedPrice = widget.price * (1 - widget.discount / 100);

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image and Wishlist Button
          SizedBox(
            height: 140, // Fixed height for image
            child: Stack(
              children: [
                Positioned.fill(
                  child: widget.imageUrl.toLowerCase().endsWith('.svg') && !widget.imageUrl.startsWith('http')
                    ? SvgPicture.asset(widget.imageUrl, fit: BoxFit.cover)
                    : Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.broken_image, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Image not found', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton.filled(
                    onPressed: _handleToggleWishlist,
                    icon: Icon(
                      _isWishlisted ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: _isWishlisted ? Colors.red : Colors.grey,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.all(4),
                      minimumSize: const Size(24, 24),
                      fixedSize: const Size(28, 28),
                    ),
                  )
                  .animate(target: _isWishlisted ? 1 : 0)
                  .scaleXY(begin: 1.0, end: 1.2)
                  .then()
                  .scaleXY(begin: 1.2, end: 1.0),
                ),
                if (widget.discount > 0)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${widget.discount}% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Product Details
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '\$${discountedPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (widget.discount > 0)
                          Text(
                            '\$${widget.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: ElevatedButton(
                        onPressed: _isAddingToCart ? null : _handleAddToCart,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: _isAddingToCart
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Add to Cart',
                                style: TextStyle(fontSize: 11),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 