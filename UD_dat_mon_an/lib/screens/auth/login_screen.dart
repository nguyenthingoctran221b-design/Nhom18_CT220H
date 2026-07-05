import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../e-menu/emenu_screen.dart';
import '../cashier/cashier_dashboard.dart';
import '../chef/chef_dashboard.dart';
import '../manager/manager_dashboard.dart';

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
        _errorMessage = 'Vui lòng nhập ID và Mật khẩu';
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(id).get();

      if (!doc.exists) {
        setState(() {
          _errorMessage = 'Tài khoản không tồn tại';
          _isLoading = false;
        });
        return;
      }

      final data = doc.data()!;
      if (data['password'] != password) {
        setState(() {
          _errorMessage = 'Sai mật khẩu';
          _isLoading = false;
        });
        return;
      }

      // Đăng nhập thành công, phân luồng theo role
      final role = data['role'] as String;
      
      if (!mounted) return;

      Widget targetScreen;
      switch (role) {
        case 'customer':
          targetScreen = EMenuScreen(tableInfo: id); // id là số bàn ví dụ A01
          break;
        case 'cashier':
          targetScreen = const CashierDashboard();
          break;
        case 'chef':
          targetScreen = const ChefDashboard();
          break;
        case 'manager':
          targetScreen = const ManagerDashboard();
          break;
        default:
          setState(() {
            _errorMessage = 'Role không hợp lệ';
            _isLoading = false;
          });
          return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetScreen),
      );

    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi kết nối mạng: $e';
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
                color: Colors.black.withOpacity(0.1),
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
                'SEN VÀNG INDOCHINE',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              if (_errorMessage.isNotEmpty) ...[
                Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: 'ID Đăng nhập (VD: A01, cashier1)',
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