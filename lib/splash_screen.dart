import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'login_screen.dart';
import 'ecommerce/screens/home/home_screen.dart';
import 'services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000), // 3 seconds for slower effect
    );

    // Opacity: slow fade-in, starts from 0.0 to 1.0 over 0.0–0.7
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    // Scale: slow zoom, from 1.0 to 2.0 over 0.2–1.0
    _scaleAnimation = Tween<double>(begin: 1.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Play the animation
    _controller.forward();

    // Optional: Add fade-out before navigating
    Future.delayed(const Duration(milliseconds: 2700), () {
      _controller.reverse();
    });

    // Check authentication and navigate accordingly
    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        final isLoggedIn = await AuthService.isLoggedIn();
        if (isLoggedIn) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Image.asset(
                'assets/images/logo.png',
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 32),

            // App Name
            Animate(
              effects: [
                FadeEffect(duration: 800.ms),
                ScaleEffect(duration: 800.ms),
              ],
        
            ),
            const SizedBox(height: 16),

            // Tagline
            Animate(
              effects: [
                FadeEffect(delay: 400.ms, duration: 700.ms),
                SlideEffect(begin: const Offset(0, 0.3), duration: 700.ms),
              ],
               child: Text(
                'Your One-Stop Shopping Platform',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
