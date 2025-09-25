import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../cart/cart_screen.dart';
import '../product/product_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../categories/categories_screen.dart';
import '../profile/profile_screen.dart';

class Category {
  final String id;
  final String name;
  final String image;

  Category({required this.id, required this.name, required this.image});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'].toString(),
      name: json['name'],
      image: json['image'],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<String>> _carouselImagesFuture;
  late Future<List<Category>> _masterCategoriesFuture;
  late Future<List<dynamic>> _trendingProductsFuture;
  int _currentCarouselIndex = 0;
  int? _userId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _carouselImagesFuture = _fetchCarouselImages();
    _masterCategoriesFuture = _fetchMasterCategories();
    _trendingProductsFuture = _fetchTrendingProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('user_id');
    });
  }

  void _handleSearch(String value) {
    // Search functionality can be implemented here
  }

  Future<List<String>> _fetchCarouselImages() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_carousel_images.php'),
      );
      final data = json.decode(response.body);
      if (data['success'] == true) {
        return List<String>.from(data['images']);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> _fetchTrendingProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_trending_products.php'),
    );
    final data = json.decode(response.body);
    if (data['status'] == 'success') {
      return data['products'];
    } else {
      throw Exception(data['message'] ?? 'Failed to load trending products');
    }
  }

  Future<List<Category>> _fetchMasterCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_master_categories.php'),
    );

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        final List data = jsonData['data'];
        return data.map((item) => Category.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } else {
      throw Exception('Server error');
    }
  }

  double safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    final str = value.toString().replaceAll('%', '');
    return double.tryParse(str) ?? 0.0;
  }

  Future<void> addToCart(
    int productId,
    String productName,
    double price,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to add items to cart')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/add_to_cart.php'),
        body: {
          'user_id': userId.toString(),
          'ecomm_product_id': productId.toString(),
          'quantity': '1',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${productName} added to cart!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to add to cart')),
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to add to cart')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final isMediumScreen = screenSize.height >= 700 && screenSize.height < 800;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: isSmallScreen ? 50 : (isMediumScreen ? 60 : 70),
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [],
            flexibleSpace: FlexibleSpaceBar(
              expandedTitleScale: 1.0,
              titlePadding: EdgeInsets.zero,
              title: Container(
                width: screenSize.width,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Logo and App Name
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: 32,
                            width: 32,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'SunShine Marketing',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),

          // Search Bar Section
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey[300]!, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(26),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _handleSearch,
                  decoration: InputDecoration(
                    hintText: 'Search for products...',
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                    prefixIcon: Icon(
                      Icons.search,
                      color: const Color(0xFF007B8F),
                      size: 24,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Carousel Banner
          SliverToBoxAdapter(
            child: Container(
              color: const Color.fromARGB(255, 249, 220, 124),
              child: Column(
                children: [
                  // Background above carousel
                  Container(
                    height: 20,
                    color: const Color.fromARGB(255, 249, 220, 124),
                  ),
                  FutureBuilder<List<String>>(
                    future: _carouselImagesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          height: isSmallScreen ? 160 : 180,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Container(
                          height: isSmallScreen ? 160 : 180,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Error loading carousel',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Container(
                          height: isSmallScreen ? 160 : 180,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image, size: 40, color: Colors.grey),
                                SizedBox(height: 8),
                                Text(
                                  'No carousel images',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final images = snapshot.data!;
                      return Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            child: CarouselSlider(
                              options: CarouselOptions(
                                height: isSmallScreen ? 160 : 180,
                                viewportFraction: 0.9,
                                enlargeCenterPage: true,
                                autoPlay: true,
                                onPageChanged: (index, reason) {
                                  setState(() {
                                    _currentCarouselIndex = index;
                                  });
                                },
                              ),
                              items: List.generate(images.length, (index) {
                                final imageUrl = images[index];
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child:
                                        imageUrl.toLowerCase().endsWith('.svg')
                                            ? SvgPicture.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              placeholderBuilder:
                                                  (context) => Container(
                                                    color: Colors.white,
                                                    child: const Center(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons.image,
                                                            size: 40,
                                                            color: Colors.grey,
                                                          ),
                                                          SizedBox(height: 8),
                                                          Text(
                                                            'Loading...',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                            )
                                            : Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Container(
                                                    color: Colors.white,
                                                    child: const Center(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons.broken_image,
                                                            size: 40,
                                                            color: Colors.grey,
                                                          ),
                                                          SizedBox(height: 8),
                                                          Text(
                                                            'Image not available',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                            ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(images.length, (index) {
                              return Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFF37E15).withValues(
                                    alpha:
                                        _currentCarouselIndex == index
                                            ? 1
                                            : 0.4,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      );
                    },
                  ),
                  // Background below carousel
                  Container(
                    height: 20,
                    color: const Color.fromARGB(255, 249, 220, 124),
                  ),
                ],
              ),
            ),
          ),

          // Shop by Category Section (like website)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shop by Category',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FutureBuilder<List<Category>>(
                      future: _masterCategoriesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Text('No categories found.');
                        }

                        final categories = snapshot.data!;
                        final displayCategories = categories.take(4).toList();

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 1.3,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 12,
                              ),
                          itemCount: displayCategories.length,
                          itemBuilder: (context, index) {
                            final cat = displayCategories[index];
                            // Apply same image logic as trending products - handle both full URLs and relative paths
                            final imagePath = cat.image;
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

                            return InkWell(
                              onTap: () {
                                // Navigate to categories page
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => CategoriesScreen(
                                          initialCategoryId: int.parse(cat.id),
                                        ),
                                  ),
                                );
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          index % 2 == 0
                                              ? Colors.pink
                                              : Colors.grey[800],
                                    ),
                                    child: ClipOval(
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Container(
                                            color:
                                                index % 2 == 0
                                                    ? Colors.pink
                                                    : Colors.grey[800],
                                            child: Icon(
                                              Icons.category,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    child: Text(
                                      cat.name,
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Featured Products Section (like website)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Featured Products',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FutureBuilder<List<dynamic>>(
                      future: _trendingProductsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Text('No trending items.');
                        }

                        final products = snapshot.data!;
                        // Show all trending products regardless of selected category

                        if (products.isEmpty) {
                          return const Text('No trending items.');
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.75,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                          itemCount:
                              products.length > 4
                                  ? 4
                                  : products
                                      .length, // Show max 4 featured products
                          itemBuilder: (context, index) {
                            final product = products[index];
                            final imagePath =
                                product['Ecomm_product_image']?.toString() ??
                                '';
                            String finalImagePath = imagePath;
                            if (finalImagePath.startsWith('uploads/')) {
                              finalImagePath = finalImagePath.substring(
                                'uploads/'.length,
                              );
                            }
                            final imageUrl = '$uploadsUrl$finalImagePath';

                            final price = safeParseDouble(
                              product['Ecomm_product_price'],
                            );

                            return Card(
                              elevation: 8,
                              shadowColor: Colors.black.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () {
                                  // Navigate to product detail page
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => ProductDetailScreen(
                                            id: int.parse(
                                              product['Ecomm_product_id']
                                                  .toString(),
                                            ),
                                            imageUrl: imageUrl,
                                            name:
                                                product['Ecomm_product_name']
                                                    ?.toString() ??
                                                '',
                                            price: price,
                                            discount:
                                                0, // You can add discount logic if needed
                                            category:
                                                'General', // You can get category from product data if available
                                          ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product Image
                                    Expanded(
                                      flex: 4,
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(12),
                                                  ),
                                              color: Colors.white,
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                    top: Radius.circular(12),
                                                  ),
                                              child: Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder: (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) {
                                                  return Container(
                                                    color: Colors.white,
                                                    child: const Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.shopping_bag,
                                                          size: 30,
                                                          color: Colors.grey,
                                                        ),
                                                        Text(
                                                          'No Image',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          // In Stock Badge
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Text(
                                                'In Stock',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Product Details
                                    Expanded(
                                      flex: 3,
                                      child: Padding(
                                        padding: const EdgeInsets.all(6.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Text(
                                              product['Ecomm_product_name']
                                                      ?.toString() ??
                                                  '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Rs. ${price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Color(0xFFF37E15),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                // Cart Button
                                                GestureDetector(
                                                  onTap: () {
                                                    addToCart(
                                                      int.parse(
                                                        product['Ecomm_product_id']
                                                            .toString(),
                                                      ),
                                                      product['Ecomm_product_name']
                                                              ?.toString() ??
                                                          '',
                                                      price,
                                                    );
                                                  },
                                                  child: Container(
                                                    width: 28,
                                                    height: 28,
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                        0xFFF37E15,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.shopping_cart,
                                                      color: Colors.white,
                                                      size: 14,
                                                    ),
                                                  ),
                                                ),
                                                // Eye Button (View Details)
                                                GestureDetector(
                                                  onTap: () {
                                                    // Navigate to product detail page
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder:
                                                            (
                                                              context,
                                                            ) => ProductDetailScreen(
                                                              id: int.parse(
                                                                product['Ecomm_product_id']
                                                                    .toString(),
                                                              ),
                                                              imageUrl:
                                                                  imageUrl,
                                                              name:
                                                                  product['Ecomm_product_name']
                                                                      ?.toString() ??
                                                                  '',
                                                              price: price,
                                                              discount: 0,
                                                              category:
                                                                  'General',
                                                            ),
                                                      ),
                                                    );
                                                  },
                                                  child: Container(
                                                    width: 28,
                                                    height: 28,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      border: Border.all(
                                                        color: const Color(
                                                          0xFFF37E15,
                                                        ),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.visibility,
                                                      color: Color(0xFFF37E15),
                                                      size: 14,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0, // Home is selected
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
              // Already on home screen, do nothing
              break;
            case 1:
              // Navigate to categories screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoriesScreen(),
                ),
              );
              break;
            case 2:
              if (_userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartScreen(userId: _userId!),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User not logged in.')),
                );
              }
              break;
            case 3:
              if (_userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User not logged in.')),
                );
              }
              break;
          }
        },
      ),
    );
  }
}
