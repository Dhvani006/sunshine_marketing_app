import 'package:flutter/material.dart';
import '../screens/cart/cart_screen.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/home/home_screen.dart';

class ModernBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final int? userId;

  const ModernBottomNavigation({
    super.key,
    required this.currentIndex,
    this.userId,
  });

  Widget _buildNavItem(IconData outlineIcon, IconData filledIcon, String label, int index, bool isSelected, BuildContext context) {
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0:
            if (currentIndex != 0) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            }
            break;
          case 1:
            if (currentIndex != 1) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const CategoriesScreen()),
                (route) => false,
              );
            }
            break;
          case 2:
            if (userId != null) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => CartScreen(userId: userId!)),
                (route) => false,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User not logged in.')),
              );
            }
            break;
          case 3:
            if (userId != null) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
                (route) => false,
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User not logged in.')),
              );
            }
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? filledIcon : outlineIcon,
            color: isSelected ? Colors.black : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0, currentIndex == 0, context),
              _buildNavItem(Icons.storefront_outlined, Icons.storefront, 'Shop', 1, currentIndex == 1, context),
              _buildNavItem(Icons.shopping_cart_outlined, Icons.shopping_cart, 'Chart', 2, currentIndex == 2, context),
              _buildNavItem(Icons.person_outline, Icons.person, 'Profile', 3, currentIndex == 3, context),
            ],
          ),
        ),
      ),
    );
  }
}
