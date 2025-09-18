import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';
import 'ecommerce/constants/colors.dart';
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
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isSmallScreen = screenWidth < 360;
    final isLargeScreen = screenWidth > 600;

    // Responsive dimensions
    final containerWidth =
        isLargeScreen ? screenWidth * 0.4 : screenWidth * 0.9;
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;
    final verticalPadding = isSmallScreen ? 16.0 : 24.0;
    final titleFontSize = isSmallScreen ? 20.0 : 24.0;
    final buttonHeight = isSmallScreen ? 44.0 : 48.0;
    final spacingSmall = isSmallScreen ? 8.0 : 12.0;
    final spacingMedium = isSmallScreen ? 16.0 : 20.0;
    final spacingLarge = isSmallScreen ? 20.0 : 28.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: containerWidth,
                minHeight: screenHeight * 0.6,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(
                        255,
                        249,
                        220,
                        124,
                      ).withOpacity(0.8),
                      blurRadius: 50,
                      spreadRadius: 5,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: verticalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Login Heading
                        Text(
                          'Login to Your Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: spacingSmall),
                        // Welcome message
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14.0 : 16.0,
                              color: Colors.grey[800],
                            ),
                            children: [
                              const TextSpan(text: 'Welcome back to '),
                              const TextSpan(
                                text: 'Sunshine Marketing!',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.purple,
                                ),
                              ),
                              const TextSpan(
                                text: ' Please login to continue.',
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: spacingLarge),
                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+',
                            ).hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: spacingMedium),
                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
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
                        SizedBox(height: spacingSmall),

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
                            ).copyWith(
                              backgroundColor:
                                  MaterialStateProperty.resolveWith<Color?>(
                                    (states) => Colors.transparent,
                                  ),
                              foregroundColor: MaterialStateProperty.all(
                                Colors.white,
                              ),
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF7A00),
                                    Color(0xFFFF8C00),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                constraints: BoxConstraints(
                                  minHeight: buttonHeight,
                                ),
                                child:
                                    _isLoading
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                        : const Text(
                                          'Login',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: spacingMedium),

                        // Forgot Password Link
                        Center(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppColors.purple,
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 14.0 : 16.0,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: spacingSmall),

                        // Register Link
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: isSmallScreen ? 14.0 : 16.0,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) =>
                                            const OTPRegistrationScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Sign up here',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.purple,
                                  fontSize: isSmallScreen ? 14.0 : 16.0,
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
