import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_colors.dart';
import 'screens/welcome/welcome_screen.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. Import thư viện Firebase
import 'firebase_options.dart'; // 2. Import file cấu hình thủ công bạn vừa tạo

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


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