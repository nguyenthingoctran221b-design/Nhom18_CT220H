import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../e-menu/emenu_screen.dart';

/// Màn hình Chào mừng (WelcomeScreen)
/// Phục vụ như giao diện chờ chính của thiết bị E-Menu đặt tại mỗi bàn ăn.
/// Người dùng (khách hàng hoặc nhân viên phục vụ) có thể nhấn nút "KHỞI ĐỘNG E-MENU" để chọn số bàn
/// và bắt đầu phiên gọi món ăn.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  
  /// Hộp thoại chọn Bàn & Khu vực
  /// Cho phép thiết lập số bàn của thiết bị (ví dụ: A-01, B-05, C-12)
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Thiết Lập Số Bàn Thiết Bị',
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
                    Navigator.pop(context); // Đóng dialog
                    // Chuyển sang màn hình E-Menu gọi món dành cho khách hàng với số bàn tương ứng
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          // Màu nền Indochine thanh lịch
          Container(color: AppColors.background),

          // Nút cài đặt / đăng nhập nhân viên
          Positioned(
            top: 20,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.settings, color: AppColors.primary, size: 28),
              tooltip: 'Đăng nhập nhân viên',
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 // LOGO nhà hàng
                 Hero(
                   tag: 'logo',
                   child: Container(
                     width: 180,
                     height: 180,
                     decoration: BoxDecoration(
                       color: Colors.white,
                       shape: BoxShape.circle,
                       boxShadow: [
                         BoxShadow(
                           color: Colors.black.withValues(alpha: 0.1),
                           blurRadius: 20,
                           offset: const Offset(0, 10),
                         )
                       ],
                     ),
                     child: const Icon(Icons.restaurant_menu, size: 80, color: AppColors.primary),
                   ),
                 ),
                 const SizedBox(height: 30),

                // Tên nhà hàng
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

                // Slogan chào mừng
                const Text(
                  "Chào mừng bạn đến với không gian ẩm thực truyền thống",
                  style: TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 60),

                // Nút bắt đầu gọi món
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
                      "KHỞI ĐỘNG E-MENU GỌI MÓN",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Thông tin phiên bản hệ thống dưới chân trang
          const Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Hệ Thống Phục Vụ & Gọi Món Thông Minh E-Menu - v1.0.0",
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          )
        ],
      ),
    );
  }
}
