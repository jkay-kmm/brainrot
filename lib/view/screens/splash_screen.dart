import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../core/routes/app_routes.dart';
import '../../widgets/loading_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed( Duration(milliseconds: 2500));
    if (mounted) {
      context.go(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4B5),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/splash1.json',
                width: 860,
                height: 560,
                fit: BoxFit.contain,
              ),
              // const SizedBox(height: 24),
              // Text(
              //   'Brainrot',
              //   style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              //     color: Colors.white,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              // const SizedBox(height: 16),
              Text(
                'Đợi chút nhé...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 32),
              const SpinKitFadingCircle(
                color: Colors.orange,
                size: 48,
              ),

            ],
          ),
        ),
      ),
    );
  }
}
