import 'package:flutter/material.dart';
import '../../constants.dart';
import '../auth/login_screen.dart';

/// Splash screen displaying the app logo and name with animations.
///
/// Shows a fade and scale animation before navigating to the login screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// State for [SplashScreen], handling animation controllers and navigation.
class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Controls the timing of the fade and scale animations.
  late AnimationController _controller;
  /// Animation controlling the opacity transition of the splash content.
  late Animation<double> _fadeAnimation;
  /// Animation controlling the scale (size) transition of the splash content.
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller and define fade and scale tweens.
    // Create controller with 2-second duration.
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Define fade-in animation from transparent to opaque.
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Define scale animation from half-size to full size with elastic effect.
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.3, 0.8, curve: Curves.elasticOut),
      ),
    );

    _controller.forward().then((_) {
      Future.delayed(Duration(milliseconds: 500), () {
        // After animation and 500ms delay, navigate to the login screen.
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
    // Dispose of the animation controller to free resources.
    _controller.dispose();
    super.dispose();
  }

  /// Builds the splash screen UI with animated logo and texts.
  @override
  Widget build(BuildContext context) {
    // Use white background and center animated content.
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Center(
        // Rebuild UI on each animation tick.
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Apply fade animation to the child widget.
            return FadeTransition(
              opacity: _fadeAnimation,
              // Apply scale animation to the child widget.
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App logo icon.
                    Icon(
                      Icons.savings_outlined,
                      size: 100,
                      color: AppColors.primaryGreen,
                    ),
                    SizedBox(height: 20),
                    // App title text.
                    Text(
                      'Savemeleon',
                      style: AppTextStyles.heading1.copyWith(
                        fontSize: 32,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    SizedBox(height: 10),
                    // App tagline text.
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
