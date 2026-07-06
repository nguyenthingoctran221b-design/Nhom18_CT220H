import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../e-menu/emenu_screen.dart';
import '../cashier/cashier_dashboard.dart';
import '../chef/chef_dashboard.dart';
import '../manager/manager_dashboard.dart';

/// Màn hình Đăng nhập (LoginScreen)
/// Cung cấp cổng truy cập phân quyền cho mọi tác nhân vận hành trong nhà hàng bao gồm:
/// - Khách hàng (Đăng nhập theo Bàn để truy cập E-Menu)
/// - Thu ngân (Truy cập bảng thu ngân & thanh toán)
/// - Đầu bếp (Truy cập bảng điều phối & chế biến món ăn)
/// - Quản trị viên (Truy cập báo cáo doanh thu & quản lý bàn ăn/món ăn)
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  /// Xử lý xác thực người dùng dựa trên Firestore
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final id = _idController.text.trim();
    final password = _passwordController.text.trim();

    if (id.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Vui lòng nhập ID đăng nhập và Mật khẩu';
      });
      return;
    }

    try {
      // Truy xuất tài khoản người dùng từ collection 'users' bằng ID tài khoản làm key chính
      final doc = await FirebaseFirestore.instance.collection('users').doc(id).get();

      if (!doc.exists) {
        setState(() {
          _errorMessage = 'Mã tài khoản hoặc mật khẩu không chính xác';
          _isLoading = false;
        });
        return;
      }

      final data = doc.data()!;
      if (data['password'] != password) {
        setState(() {
          _errorMessage = 'Mã tài khoản hoặc mật khẩu không chính xác';
          _isLoading = false;
        });
        return;
      }

      // Lấy vai trò (role) từ tài khoản để chuyển hướng màn hình làm việc tương ứng
      final role = data['role'] as String;
      
      if (!mounted) return;

      Widget targetScreen;
      switch (role) {
        case 'customer':
          // Đối với tài khoản Khách hàng, ID tài khoản chính là mã số bàn (ví dụ: A01, B02)
          targetScreen = EMenuScreen(tableInfo: id);
          break;
        case 'cashier':
          // Bảng điều khiển thu ngân và quản lý hóa đơn
          targetScreen = const CashierDashboard();
          break;
        case 'chef':
          // Bảng điều phối món ăn dành cho nhà bếp
          targetScreen = ChefDashboard(chefId: id);
          break;
        case 'manager':
          // Bảng quản trị hệ thống, món ăn, bàn ăn và báo cáo kinh doanh
          targetScreen = const ManagerDashboard();
          break;
        default:
          setState(() {
            _errorMessage = 'Vai trò người dùng không hợp lệ trên hệ thống';
            _isLoading = false;
          });
          return;
      }

      // Tiến hành chuyển hướng, loại bỏ màn hình đăng nhập khỏi ngăn xếp điều hướng
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetScreen),
      );

    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể kết nối đến máy chủ Firestore: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.restaurant_menu, size: 80, color: AppColors.primary),
              const SizedBox(height: 16),
              const Text(
                'HỆ THỐNG VẬN HÀNH',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Chào mừng bạn đến với hệ thống vận hành',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              if (_errorMessage.isNotEmpty) ...[
                Text(_errorMessage, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: 'Tài khoản',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ĐĂNG NHẬP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}