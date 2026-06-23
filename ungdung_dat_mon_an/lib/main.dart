import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_colors.dart';
import 'screens/welcome/welcome_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Khóa màn hình ngang cho Tablet
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const SmartEMenuApp());
}

class SmartEMenuApp extends StatelessWidget {
  const SmartEMenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart E-Menu Indochine',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Playfair Display', // Font chữ sang trọng Indochine
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: AppColors.text),
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}