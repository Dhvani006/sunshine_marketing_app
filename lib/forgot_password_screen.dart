import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_config.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  bool _isLoading = false;
  String _selectedType = 'email'; // 'email' or 'phone'

  Future<void> _sendResetRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      print('🔵 DEBUG: Sending forgot password request...');
      print('🔵 DEBUG: Type: $_selectedType');
      print('🔵 DEBUG: Identifier: ${_identifierController.text}');

      final response = await http.post(
        Uri.parse('$baseUrl/forgot_password.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'identifier': _identifierController.text.trim(),
          'type': _selectedType,
        }),
      );

      print('🔵 DEBUG: Response status: ${response.statusCode}');
      print('🔵 DEBUG: Response body: ${response.body}');

      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        _showSuccessDialog(data['message'], data['type'], data['email']);
      } else {
        _showSnackBar(data['message'] ?? 'Failed to send reset request', isError: true);
      }
    } catch (e) {
      print('💥 DEBUG: Exception during forgot password: $e');
      _showSnackBar('Network error. Please try again.', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String message, String type, String? email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Text('Reset Link Sent!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message),
              if (type == 'phone' && email != null) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[600], size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reset link sent to: $email',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 16),
              Text(
                'Please check your email and click the reset link to change your password.',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to login
              },
              child: Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFFB266FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validateInput(String? value) {
    if (value == null || value.trim().isEmpty) {
      return _selectedType == 'email' 
          ? 'Please enter your email address'
          : 'Please enter your phone number';
    }

    if (_selectedType == 'email') {
      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(value.trim())) {
        return 'Please enter a valid email address';
      }
    } else {
      // Basic phone validation - you can make this more specific
      String cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
      if (cleanPhone.length < 10) {
        return 'Please enter a valid phone number';
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        title: Text(
          'Forgot Password',
          style: TextStyle(
            color: Color(0xFFB266FF),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Icon(
                        Icons.lock_reset,
                        size: 64,
                        color: Color(0xFFB266FF),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFB266FF),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Enter your email or phone number to receive a password reset link',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32),

                      // Type Selection
                      Text(
                        'Reset using:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('Email'),
                              value: 'email',
                              groupValue: _selectedType,
                              activeColor: Color(0xFFB266FF),
                              onChanged: (value) {
                                setState(() {
                                  _selectedType = value!;
                                  _identifierController.clear();
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('Phone'),
                              value: 'phone',
                              groupValue: _selectedType,
                              activeColor: Color(0xFFB266FF),
                              onChanged: (value) {
                                setState(() {
                                  _selectedType = value!;
                                  _identifierController.clear();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Input Field
                      TextFormField(
                        controller: _identifierController,
                        keyboardType: _selectedType == 'email' 
                            ? TextInputType.emailAddress 
                            : TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: _selectedType == 'email' 
                              ? 'Email Address' 
                              : 'Phone Number',
                          hintText: _selectedType == 'email' 
                              ? 'Enter your email address'
                              : 'Enter your phone number',
                          prefixIcon: Icon(
                            _selectedType == 'email' ? Icons.email : Icons.phone,
                            color: Color(0xFFB266FF),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Color(0xFFB266FF), width: 2),
                          ),
                        ),
                        validator: _validateInput,
                      ),
                      SizedBox(height: 32),

                      // Send Reset Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _sendResetRequest,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          backgroundColor: null,
                        ).copyWith(
                          backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                              (states) => null),
                          foregroundColor: MaterialStateProperty.all(Colors.white),
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
                                ? SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'SEND RESET LINK',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Back to Login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Remember your password? ",
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Login',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB266FF),
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
    _identifierController.dispose();
    super.dispose();
  }
}
