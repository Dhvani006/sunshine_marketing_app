import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'otp_registration_screen.dart';
import 'ecommerce/screens/home/home_screen.dart';
import 'services/auth_service.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );

      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        // Save authentication data using AuthService
        await AuthService.saveAuthData(
          userId: int.parse(data['user_id'].toString()),
          email: _emailController.text,
          username: data['username'],
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Login Heading
                      Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700), // Darker yellow shade
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      // Welcome message
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                          children: [
                            const TextSpan(text: 'Welcome back to '),
                            TextSpan(
                              text: 'BoliBazaar!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFD700),
                              ),
                            ),
                            const TextSpan(text: ' Please login to continue.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Color(0xFFFFD700), width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+')
                              .hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Color(0xFFFFD700), width: 2),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                   
                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            backgroundColor: null,
                          ).copyWith(
                            backgroundColor:
                                MaterialStateProperty.resolveWith<Color?>(
                                    (states) => null),
                            foregroundColor:
                                MaterialStateProperty.all(Colors.white),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFFFA500), Color(0xFFFFD700)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              constraints: BoxConstraints(minHeight: 48),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'LOGIN',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Forgot Password Link
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const OTPRegistrationScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFFD700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
