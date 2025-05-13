import 'package:flutter/material.dart';
import 'screens/splash/splash_screen.dart';
import 'constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Savemeleon',
      theme: ThemeData(
        primaryColor: AppColors.primaryGreen,
        scaffoldBackgroundColor: AppColors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.black),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
