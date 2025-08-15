import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_profile_screen.dart';
import 'order_history_screen.dart';
import '../../../api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../categories/categories_screen.dart';
import '../cart/cart_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _userId;
  String _username = '';
  String _email = '';
  String _phone = '';
  String _address = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId != null) {
        setState(() {
          _userId = userId;
        });

        // Fetch user data from API
        final response = await http.post(
          Uri.parse('$baseUrl/get_user_by_id.php'),
          body: {
            'user_id': userId.toString(),
          },
        );

        final data = json.decode(response.body);

        if (data['status'] == true && data['user'] != null) {
          final user = data['user'];
          setState(() {
            _username = user['Username'] ?? '';
            _email = user['Email'] ?? '';
            _phone = user['Phone_number'] ?? '';
            _address = user['Address'] ?? '';
            _isLoading = false;
          });
        } else {
          // Fallback to SharedPreferences if API fails
          setState(() {
            _username = prefs.getString('username') ?? '';
            _email = prefs.getString('email') ?? '';
            _phone = prefs.getString('phone_number') ?? '';
            _address = prefs.getString('address') ?? '';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Fallback to SharedPreferences on error
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _username = prefs.getString('username') ?? '';
        _email = prefs.getString('email') ?? '';
        _phone = prefs.getString('phone_number') ?? '';
        _address = prefs.getString('address') ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _openEditProfile(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = {
      'U_id': prefs.getInt('user_id')?.toString() ?? '',
      'Username': _username,
      'Email': _email,
      'Address': _address,
      'Phone_number': _phone,
    };
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userData: userData),
      ),
    );
    // Reload user data after returning from edit profile
    _loadUserData();
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id')?.toString() ?? '';
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout.php'),
        body: {'user_id': userId},
      );
      print('Logout response: ' + response.body);
    } catch (e) {
      print('Logout error: $e');
    }
    await prefs.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully')),
    );
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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
            'Profile',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFCC9900), Color(0xFFFFD700)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          child: Text(
                            _username.isNotEmpty
                                ? _username[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF37E15),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _username.isNotEmpty ? _username : 'User',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _email.isNotEmpty ? _email : 'user@example.com',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        if (_phone.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _phone,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                        if (_address.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _address,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white60,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Profile Options
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Edit Profile
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: Color(0xFFFFD700),
                              size: 24,
                            ),
                          ),
                          title: const Text(
                            'Edit Profile',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle:
                              const Text('Update your personal information'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey,
                            size: 16,
                          ),
                          onTap: () => _openEditProfile(context),
                        ),
                        const Divider(height: 1, indent: 56, endIndent: 16),



                        // Order History
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.green,
                              size: 24,
                            ),
                          ),
                          title: const Text(
                            'Order History',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: const Text('View your purchase history'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const OrderHistoryScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logout Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.logout,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      onTap: () => _logout(context),
                    ),
                  ),
                ],
              ),
            ),
      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0, // Home is selected (profile is part of home)
        selectedItemColor: const Color(0xFFF37E15),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
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
              if (_userId != null) {
                Navigator.pushReplacement(
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
              // Already on profile screen, do nothing
              break;
          }
        },
      ),
    );
  }
}
