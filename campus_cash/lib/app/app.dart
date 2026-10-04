import 'package:flutter/material.dart';
import '../core/constants/app_strings.dart';
import '../features/auth/screens/splash_screen.dart';
import 'theme.dart';

class CampusCashApp extends StatelessWidget {
  const CampusCashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
