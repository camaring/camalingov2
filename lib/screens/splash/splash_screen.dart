import 'package:flutter/material.dart';
import '../../constants.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.3, 0.8, curve: Curves.elasticOut),
      ),
    );

    _controller.forward().then((_) {
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
        }
      });
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
      backgroundColor: AppColors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.savings_outlined,
                      size: 100,
                      color: AppColors.primaryGreen,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Savemeleon',
                      style: AppTextStyles.heading1.copyWith(
                        fontSize: 32,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Adaptate,ahorra, evoluciona y  cuida tu dinero',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.black,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
