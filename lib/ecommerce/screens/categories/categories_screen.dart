import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../api_config.dart';
import '../../models/subcategory.dart';
import '../../constants/colors.dart';
import '../product/product_list_screen.dart';

import '../cart/cart_screen.dart';
import '../profile/profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/modern_bottom_navigation.dart';

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

class CategoriesScreen extends StatefulWidget {
  final int? initialCategoryId;

  const CategoriesScreen({super.key, this.initialCategoryId});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<Subcategory> subcategories = [];
  List<Category> masterCategories = [];
  bool isLoadingSubcategories = false;
  bool isLoadingMasterCategories = true;
  int? selectedMasterCategoryId;
  String? selectedMasterCategoryName;
  int? _userId;

  @override
  void initState() {
    super.initState();
    fetchMasterCategories();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getInt('user_id');
    });
  }

  Future<void> fetchMasterCategories() async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/get_master_categories.php'));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          final List data = jsonData['data'];
          setState(() {
            masterCategories =
                data.map((item) => Category.fromJson(item)).toList();
            isLoadingMasterCategories = false;
            if (masterCategories.isNotEmpty) {
              // If initial category ID is provided, find and select it
              if (widget.initialCategoryId != null) {
                final initialCategory = masterCategories.firstWhere(
                  (cat) => int.parse(cat.id) == widget.initialCategoryId,
                  orElse: () => masterCategories[0],
                );
                selectedMasterCategoryId = int.parse(initialCategory.id);
                selectedMasterCategoryName = initialCategory.name;
              } else {
                // Default to first category
                selectedMasterCategoryId = int.parse(masterCategories[0].id);
                selectedMasterCategoryName = masterCategories[0].name;
              }
              fetchSubcategories(selectedMasterCategoryId!);
            }
          });
        } else {
          throw Exception('Failed to load master categories');
        }
      } else {
        throw Exception('Server error');
      }
    } catch (e) {
      setState(() {
        isLoadingMasterCategories = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading master categories: $e')),
      );
    }
  }

  Future<void> fetchSubcategories(int masterCatId) async {
    setState(() {
      isLoadingSubcategories = true;
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_subcategories.php?master_cat_id=$masterCatId'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          final List data = jsonData['data'];
          setState(() {
            subcategories =
                data.map((item) => Subcategory.fromJson(item)).toList();
            isLoadingSubcategories = false;
          });
        } else {
          throw Exception('Failed to load subcategories');
        }
      } else {
        throw Exception('Server error');
      }
    } catch (e) {
      setState(() {
        isLoadingSubcategories = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading subcategories: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [Color(0xFFCC9900), Color(0xFFFFD700)], // Darker to lighter yellow
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: const Text(
            'Categories',
            style: TextStyle(
              color: Colors.white, // Color is masked by gradient
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
      body: Row(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.35,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                right: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: isLoadingMasterCategories
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children:
                                List.generate(masterCategories.length, (index) {
                              final category = masterCategories[index];
                              final isSelected = selectedMasterCategoryId ==
                                  int.parse(category.id);

                              final imagePath = category.image;
                              String finalImagePath;

                              if (imagePath.startsWith('http')) {
                                final uri = Uri.parse(imagePath);
                                finalImagePath = uri.pathSegments.last;
                              } else {
                                finalImagePath = imagePath;
                                if (finalImagePath.startsWith('uploads/')) {
                                  finalImagePath = finalImagePath
                                      .substring('uploads/'.length);
                                }
                              }
                              final imageUrl = '$uploadsUrl$finalImagePath';

                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedMasterCategoryId =
                                        int.parse(category.id);
                                    selectedMasterCategoryName = category.name;
                                  });
                                  fetchSubcategories(selectedMasterCategoryId!);
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFF37E15)
                                            .withOpacity(0.1)
                                        : Colors.transparent,
                                    border: Border(
                                      left: BorderSide(
                                        color: isSelected
                                            ? const Color(0xFFF37E15)
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.category,
                                                    size: 25,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Flexible(
                                        child: Text(
                                          category.name,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSelected
                                                ? const Color(0xFFF37E15)
                                                : Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          Expanded(
            child: isLoadingSubcategories
                ? const Center(child: CircularProgressIndicator())
                : subcategories.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.category, size: 32, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'Select a category to view subcategories',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio:
                                0.75, // important for rectangle card layout
                          ),
                          itemCount: subcategories.length,
                          itemBuilder: (context, index) {
                            final subcategory = subcategories[index];

                            final imagePath = subcategory.image ?? '';
                            String finalImagePath;

                            if (imagePath.startsWith('http')) {
                              final uri = Uri.parse(imagePath);
                              finalImagePath = uri.pathSegments.last;
                            } else {
                              finalImagePath = imagePath;
                              if (finalImagePath.startsWith('uploads/')) {
                                finalImagePath =
                                    finalImagePath.substring('uploads/'.length);
                              }
                            }
                            final imageUrl = '$uploadsUrl$finalImagePath';

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductListScreen(
                                      subCatId: subcategory.id,
                                      subCatName: subcategory.name,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      flex: 6,
                                      child: ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                                top: Radius.circular(8)),
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: Icon(Icons.broken_image,
                                                    color: Colors.grey),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 6),
                                          child: Text(
                                            subcategory.name,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          )
        ],
      ),
      // Bottom Navigation
      bottomNavigationBar: ModernBottomNavigation(
        currentIndex: 1,
        userId: _userId,
      ),
    );
  }
}
