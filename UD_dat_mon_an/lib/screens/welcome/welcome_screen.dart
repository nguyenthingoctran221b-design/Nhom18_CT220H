import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../auth/login_screen.dart';
import '../menu/main_menu_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background trang trí nhẹ (có thể thêm hoa văn Indochine ở đây)
          Container(color: AppColors.background),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO + NÚT ẨN
                GestureDetector(
                  onDoubleTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: Hero(
                    tag: 'logo',
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: const Icon(Icons.restaurant_menu, size: 80, color: AppColors.primary),
                      // Thay Icon bằng Image.asset('assets/logo.png') khi bạn có logo
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // TÊN NHÀ HÀNG
                const Text(
                  "SEN VÀNG INDOCHINE",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 10),

                // DÒNG CHÀO MỪNG
                const Text(
                  "Chào mừng bạn đến với không gian ẩm thực truyền thống",
                  style: TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 60),

                // NÚT BẮT ĐẦU ĐẶT MÓN
                SizedBox(
                  width: 300,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainMenuScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      "BẮT ĐẦU ĐẶT MÓN",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Version info hoặc Footer ẩn
          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text("v1.0.0 - Smart E-Menu System", style: TextStyle(color: Colors.grey)),
            ),
          )
        ],
      ),
    );
  }
}