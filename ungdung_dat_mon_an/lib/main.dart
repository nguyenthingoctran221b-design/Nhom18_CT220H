import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart'; // Thư viện lõi Firebase
import 'firebase_options.dart'; // File cấu hình bạn vừa generate
import 'core/constants/app_colors.dart';
import 'screens/welcome/welcome_screen.dart';

// Bắt buộc phải thêm từ khóa 'async' vào hàm main
void main() async {
  // Đảm bảo Flutter đã sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase ngay khi mở app
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Khóa màn hình ngang cho Tablet (Code của bạn - Rất chuẩn!)
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