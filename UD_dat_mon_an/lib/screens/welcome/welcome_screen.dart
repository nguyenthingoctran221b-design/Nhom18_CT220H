import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../e-menu/emenu_screen.dart';
// import '../auth/login_screen.dart';
// import '../menu/main_menu_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  void _showTableSelectionDialog() {
    String selectedArea = 'A';
    String selectedTable = '01';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Chọn Bàn',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('Khu vực: ', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: selectedArea,
                        items: ['A', 'B', 'C'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontSize: 18)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedArea = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Số bàn: ', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: selectedTable,
                        items: List.generate(20, (index) => (index + 1).toString().padLeft(2, '0')).map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontSize: 18)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            selectedTable = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EMenuScreen(tableInfo: '$selectedArea-$selectedTable'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Xác nhận'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background trang trí nhẹ
          Container(color: AppColors.background),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO + NÚT ẨN
                GestureDetector(
                  onDoubleTap: () {
                    // Chuyển sang trang E-Menu với bàn mặc định
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const EMenuScreen(tableInfo: 'A-01')),
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
                    onPressed: _showTableSelectionDialog,
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

          // Version info
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

