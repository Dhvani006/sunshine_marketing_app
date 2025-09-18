import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../screens/cart/cart_screen.dart';
import '../../../api_config.dart';
import '../../screens/buy_now/buy_now_screen.dart';
import '../../models/product_image.dart';

class ProductDetailScreen extends StatefulWidget {
  final int id;
  final String imageUrl;
  final String name;
  final double price;
  final int discount;
  final String category;

  const ProductDetailScreen({
    super.key,
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.price,
    required this.discount,
    required this.category,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  List<ProductImage> _productImages = [];
  bool _isLoadingImages = true;
  int _selectedImageIndex = 0;
  String _productDescription = '';

  @override
  void initState() {
    super.initState();
    _fetchProductImages();
    _fetchProductDescription();
  }

  void _handleQuantityChange(int delta) {
    setState(() {
      _quantity = (_quantity + delta).clamp(1, 10);
    });
  }

  Future<void> _fetchProductImages() async {
    print('🔍 DEBUG: Fetching images for product ID: ${widget.id}');
    try {
      final url = '$baseUrl/get_product_images.php?product_id=${widget.id}';
      print('🔍 DEBUG: API URL: $url');

      final response = await http.get(Uri.parse(url));
      print('🔍 DEBUG: Response status code: ${response.statusCode}');
      print('🔍 DEBUG: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 DEBUG: Parsed data: $data');

        if (data['status'] == 'success') {
          final images =
              (data['images'] as List)
                  .map((imageJson) => ProductImage.fromJson(imageJson))
                  .toList();
          print('🔍 DEBUG: Successfully loaded ${images.length} images');
          for (int i = 0; i < images.length; i++) {
            print('🔍 DEBUG: Image $i: ${images[i].imagePath}');
          }

          setState(() {
            _productImages = images;
            _isLoadingImages = false;
          });
        } else {
          print('🔍 DEBUG: API returned error status, using fallback image');
          print('🔍 DEBUG: Fallback image path: ${widget.imageUrl}');
          // Fallback to single image from widget
          setState(() {
            _productImages = [
              ProductImage(
                imageId: 0,
                imagePath: widget.imageUrl,
                isPrimary: true,
              ),
            ];
            _isLoadingImages = false;
          });
        }
      } else {
        print('🔍 DEBUG: HTTP error ${response.statusCode}, using fallback');
        setState(() {
          _productImages = [
            ProductImage(
              imageId: 0,
              imagePath: widget.imageUrl,
              isPrimary: true,
            ),
          ];
          _isLoadingImages = false;
        });
      }
    } catch (e) {
      print('🔍 DEBUG: Exception occurred: $e');
      print('🔍 DEBUG: Using fallback image: ${widget.imageUrl}');
      // Fallback to single image from widget
      setState(() {
        _productImages = [
          ProductImage(imageId: 0, imagePath: widget.imageUrl, isPrimary: true),
        ];
        _isLoadingImages = false;
      });
    }
  }

  Future<void> _fetchProductDescription() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_product_details.php?product_id=${widget.id}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['product'] != null) {
          setState(() {
            _productDescription =
                data['product']['Ecomm_product_description'] ??
                data['product']['description'] ??
                'No description available for this product.';
          });
        }
      }
    } catch (e) {
      print('Error fetching product description: $e');
      setState(() {
        _productDescription = 'No description available for this product.';
      });
    }
  }

  Future<int?> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  Widget _buildImageWidget(String imagePath, {bool isThumb = false}) {
    print(
      '🖼️ DEBUG: Building image widget for path: $imagePath (isThumb: $isThumb)',
    );

    // Extract image path and remove 'uploads/' prefix if present
    String finalImagePath = imagePath;
    if (finalImagePath.startsWith('uploads/')) {
      finalImagePath = finalImagePath.substring(8);
      print('🖼️ DEBUG: Removed uploads/ prefix, new path: $finalImagePath');
    }

    // Construct full URL using uploadsUrl from api_config
    final String imageUrl = '$uploadsUrl$finalImagePath';
    print('🖼️ DEBUG: Final image URL: $imageUrl');
    print('🖼️ DEBUG: uploadsUrl from config: $uploadsUrl');

    // Check if it's an SVG asset or network image
    if (imagePath.startsWith('assets/') || imagePath.endsWith('.svg')) {
      print('🖼️ DEBUG: Using SVG asset for: $imagePath');
      return SvgPicture.asset(
        imagePath,
        fit: BoxFit.cover,
        placeholderBuilder:
            (context) => Container(
              color: Colors.grey[200],
              child: Icon(
                Icons.image,
                color: Colors.grey[400],
                size: isThumb ? 24 : 48,
              ),
            ),
      );
    } else {
      print('🖼️ DEBUG: Using network image for URL: $imageUrl');
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            print('🖼️ DEBUG: Image loaded successfully: $imageUrl');
            return child;
          }
          print(
            '🖼️ DEBUG: Loading image: ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}',
          );
          return Container(
            color: Colors.grey[200],
            child: Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('🖼️ DEBUG: Image loading failed for URL: $imageUrl');
          print('🖼️ DEBUG: Error: $error');
          print('🖼️ DEBUG: Stack trace: $stackTrace');
          return Container(
            color: Colors.grey[200],
            child: Icon(
              Icons.broken_image,
              color: Colors.grey[400],
              size: isThumb ? 24 : 48,
            ),
          );
        },
      );
    }
  }

  Future<void> _addToCart() async {
    print('Add to Cart pressed');
    final userId = await _getUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to add to cart.')),
      );
      return;
    }
    final response = await http.post(
      Uri.parse('$baseUrl/add_to_cart.php'),
      body: {
        'user_id': userId.toString(),
        'ecomm_product_id': widget.id.toString(),
        'quantity': _quantity.toString(),
      },
    );
    print('Add to cart response: ${response.body}');
    final data = json.decode(response.body);
    if (data['status'] == 'success') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to cart!')));
      // Navigate to cart screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CartScreen(userId: userId)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Failed to add to cart')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final discountedPrice = widget.price * (1 - widget.discount / 100);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Product Details',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFF37E15)),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF37E15).withAlpha(26),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFF37E15)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Gallery
            _isLoadingImages
                ? Container(
                  height: 300,
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF37E15)),
                  ),
                )
                : Column(
                  children: [
                    // Main Image Display
                    AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(26),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _buildImageWidget(
                            _productImages.isNotEmpty
                                ? _productImages[_selectedImageIndex].imagePath
                                : widget.imageUrl,
                          ),
                        ),
                      ),
                    ),
                    // Thumbnail Gallery (only show if multiple images)
                    if (_productImages.length > 1) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _productImages.length,
                          itemBuilder: (context, index) {
                            final isSelected = index == _selectedImageIndex;
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImageIndex = index;
                                });
                              },
                              child: Container(
                                width: 80,
                                height: 80,
                                margin: EdgeInsets.only(
                                  left: index == 0 ? 16 : 8,
                                  right:
                                      index == _productImages.length - 1
                                          ? 16
                                          : 0,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? const Color(0xFFF37E15)
                                            : Colors.grey.shade300,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _buildImageWidget(
                                    _productImages[index].imagePath,
                                    isThumb: true,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),

            // Product Info Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(26),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Price and Discount
                  Row(
                    children: [
                      Text(
                        '₹${discountedPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF37E15),
                        ),
                      ),
                      if (widget.discount > 0) ...[
                        const SizedBox(width: 12),
                        Text(
                          '₹${widget.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF37E15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${widget.discount}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Quantity Selector
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Quantity:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFFF37E15),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Minus Button
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF37E15),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => _handleQuantityChange(-1),
                                icon: const Icon(
                                  Icons.remove,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Quantity Number
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFF37E15),
                                ),
                              ),
                              child: Text(
                                _quantity.toString(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF37E15),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Plus Button
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF37E15),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => _handleQuantityChange(1),
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Product Description
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _productDescription.isEmpty
                        ? 'Loading description...'
                        : _productDescription,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    '₹${(discountedPrice * _quantity).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF37E15),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF37E15),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF37E15).withAlpha(77),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _addToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Add to Cart',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withAlpha(77),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () async {
                    final userId = await _getUserId();
                    if (userId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You must be logged in to buy now.'),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => BuyNowScreen(
                              productId: widget.id,
                              productName: widget.name,
                              productPrice: discountedPrice,
                              quantity: _quantity,
                              userId: userId,
                            ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.flash_on, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Buy Now',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
