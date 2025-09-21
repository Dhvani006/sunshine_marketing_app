import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'api_config.dart';
import 'login_screen.dart';
import 'ecommerce/screens/home/home_screen.dart';
import 'services/auth_service.dart';

class OTPRegistrationScreen extends StatefulWidget {
  const OTPRegistrationScreen({Key? key}) : super(key: key);

  @override
  _OTPRegistrationScreenState createState() => _OTPRegistrationScreenState();
}

class _OTPRegistrationScreenState extends State<OTPRegistrationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  // Step 1: Email
  final _emailController = TextEditingController();
  bool _isEmailLoading = false;
  
  // Step 2: OTP
  final _otpController = TextEditingController();
  bool _isOtpLoading = false;
  Timer? _timer;
  int _countdown = 300; // 5 minutes
  String _verifiedEmail = '';
  
  // Step 3: Profile
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isRegistrationLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 300);
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String _formatCountdown() {
    int minutes = _countdown ~/ 60;
    int seconds = _countdown % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _sendOTP() async {
    print('🔵 DEBUG: _sendOTP() called');
    
    if (_emailController.text.isEmpty) {
      print('❌ DEBUG: Email is empty');
      _showSnackBar('Please enter your email address');
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(_emailController.text)) {
      print('❌ DEBUG: Invalid email format: ${_emailController.text}');
      _showSnackBar('Please enter a valid email address');
      return;
    }

    print('✅ DEBUG: Email validation passed: ${_emailController.text}');
    setState(() => _isEmailLoading = true);

    try {
      final url = '$baseUrl/send_registration_otp.php';
      final requestBody = jsonEncode({'email': _emailController.text});
      
      print('🌐 DEBUG: Making HTTP request to: $url');
      print('📤 DEBUG: Request body: $requestBody');
      print('📋 DEBUG: Base URL from config: $baseUrl');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: requestBody,
      );

      print('📥 DEBUG: Response status code: ${response.statusCode}');
      print('📥 DEBUG: Response headers: ${response.headers}');
      print('📥 DEBUG: Response body: ${response.body}');

      if (response.statusCode != 200) {
        print('❌ DEBUG: HTTP error - Status code: ${response.statusCode}');
        _showSnackBar('Server error (${response.statusCode}). Please try again.');
        return;
      }

      final data = json.decode(response.body);
      print('📊 DEBUG: Parsed response data: $data');

      if (data['status'] == 'success') {
        print('✅ DEBUG: OTP sent successfully');
        setState(() {
          _verifiedEmail = _emailController.text;
          _currentStep = 1;
        });
        _startCountdown();
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _showSnackBar('OTP sent successfully! Please check your email.', isSuccess: true);
      } else {
        print('❌ DEBUG: Server returned error: ${data['message']}');
        _showSnackBar(data['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      print('💥 DEBUG: Exception caught in _sendOTP(): $e');
      print('💥 DEBUG: Exception type: ${e.runtimeType}');
      if (e is http.ClientException) {
        print('💥 DEBUG: HTTP Client Exception: ${e.message}');
        _showSnackBar('Connection error: ${e.message}');
      } else if (e is FormatException) {
        print('💥 DEBUG: JSON Format Exception: ${e.message}');
        _showSnackBar('Invalid server response format');
      } else {
        print('💥 DEBUG: Unknown exception: $e');
        _showSnackBar('Network error: $e');
      }
    } finally {
      print('🔄 DEBUG: Setting loading state to false');
      setState(() => _isEmailLoading = false);
    }
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      _showSnackBar('Please enter the 6-digit OTP');
      return;
    }

    setState(() => _isOtpLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify_registration_otp.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _verifiedEmail,
          'otp': _otpController.text,
        }),
      );

      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        setState(() => _currentStep = 2);
        _timer?.cancel();
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _showSnackBar('OTP verified successfully!', isSuccess: true);
      } else {
        _showSnackBar(data['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      _showSnackBar('Network error. Please try again.');
    } finally {
      setState(() => _isOtpLoading = false);
    }
  }

  Future<void> _completeRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isRegistrationLoading = true);

    try {
      print('🔵 DEBUG: Starting registration completion...');
      print('🔵 DEBUG: Username: ${_usernameController.text}');
      print('🔵 DEBUG: Email: $_verifiedEmail');
      print('🔵 DEBUG: Address: ${_addressController.text}');
      print('🔵 DEBUG: Phone: ${_phoneController.text}');
      
      final response = await http.post(
        Uri.parse('$baseUrl/complete_registration.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': _usernameController.text,
          'email': _verifiedEmail,
          'password': _passwordController.text,
          'address': _addressController.text,
          'phone_number': _phoneController.text,
        }),
      );

      print('🔵 DEBUG: Response status: ${response.statusCode}');
      print('🔵 DEBUG: Response body: ${response.body}');

      final data = json.decode(response.body);
      print('🔵 DEBUG: Parsed data: $data');

      if (data['status'] == 'success') {
        print('🔵 DEBUG: Registration successful, user_id: ${data['user_id']}');
        
        // Save authentication data and navigate to home
        await AuthService.saveAuthData(
          userId: int.parse(data['user_id'].toString()),
          email: _verifiedEmail,
          username: _usernameController.text,
        );
        
        print('🔵 DEBUG: Auth data saved, navigating to home...');
        _showSnackBar('Registration completed successfully!', isSuccess: true);
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        print('🔵 DEBUG: Navigation completed');
      } else {
        print('❌ DEBUG: Registration failed: ${data['message']}');
        _showSnackBar(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      print('💥 DEBUG: Exception during registration: $e');
      _showSnackBar('Network error. Please try again.');
    } finally {
      setState(() => _isRegistrationLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress indicator
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Register',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFFD700),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your Sunshine Marketing account to start shopping!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Progress indicator
                  Row(
                    children: [
                      _buildStepIndicator(0, 'Enter Email', true),
                      Expanded(child: _buildStepConnector(_currentStep > 0)),
                      _buildStepIndicator(1, 'Verify OTP', _currentStep >= 1),
                      Expanded(child: _buildStepConnector(_currentStep > 1)),
                      _buildStepIndicator(2, 'Complete Profile', _currentStep >= 2),
                    ],
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildEmailStep(),
                  _buildOTPStep(),
                  _buildProfileStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFFFFD700) : Colors.grey[300],
          ),
          child: Center(
            child: isActive
                ? (_currentStep > step
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text(
                        '${step + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ))
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFFFFD700),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 24),
      color: isActive ? const Color(0xFFFFD700) : Colors.grey[300],
    );
  }

  Widget _buildEmailStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Text(
            'Step 1: Enter your email address',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email Address *',
              hintText: 'Enter your email',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFA500), Color(0xFFFFD700)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: _isEmailLoading ? null : _sendOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isEmailLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'SEND OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(color: Colors.grey[600]),
              ),
              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: const Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOTPStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Registration OTP sent successfully! Please check your email.',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Step 2: Verify your email',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'We\'ve sent a 6-digit OTP to $_verifiedEmail',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'OTP expires in: ${_formatCountdown()}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _countdown > 60 ? Colors.orange[600] : Colors.red[600],
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _otpController,
            decoration: InputDecoration(
              labelText: 'Enter OTP *',
              hintText: '6-digit OTP',
              prefixIcon: const Icon(Icons.security),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
              ),
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFA500), Color(0xFFFFD700)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: _isOtpLoading ? null : _verifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isOtpLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'VERIFY OTP',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _countdown == 0 ? () {
              _sendOTP();
              _otpController.clear();
            } : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                color: _countdown == 0 ? const Color(0xFFB266FF) : Colors.grey[300]!,
              ),
            ),
            child: Text(
              _countdown == 0 ? 'RESEND IN 4:57' : 'RESEND IN ${_formatCountdown()}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _countdown == 0 ? const Color(0xFFB266FF) : Colors.grey[500],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(color: Colors.grey[600]),
              ),
              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: const Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[600]),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'OTP verified successfully! Please set your password.',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Step 3: Complete your profile',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                  ),
            ),
            const SizedBox(height: 24),
            // Username
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username *',
                hintText: 'Choose a username',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Username is required';
                if (value.length < 3) return 'Username must be at least 3 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password *',
                hintText: 'Create a password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Password is required';
                if (value.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Confirm Password
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Confirm Password *',
                hintText: 'Confirm your password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please confirm your password';
                if (value != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Address
            TextFormField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address *',
                hintText: 'Enter your address',
                prefixIcon: const Icon(Icons.location_on_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                ),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Address is required';
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Phone Number
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number *',
                hintText: 'Enter your phone number',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
                ),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Phone number is required';
                if (value.length < 10) return 'Please enter a valid phone number';
                return null;
              },
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFA500), Color(0xFFFFD700)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: _isRegistrationLoading ? null : _completeRegistration,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isRegistrationLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'COMPLETE REGISTRATION',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      color: const Color(0xFFFFD700),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
