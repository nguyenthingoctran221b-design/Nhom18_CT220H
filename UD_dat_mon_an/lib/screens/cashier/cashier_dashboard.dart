import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../models/table_model.dart';
import 'table_detail_screen.dart';
import 'cashier_history_screen.dart';

/// Bảng điều khiển Thu ngân (CashierDashboard)
/// Phục vụ cho nhân viên thu ngân tại quầy thanh toán.
/// Cung cấp giao diện làm việc chia đôi (Sidebar trái và Vùng làm việc chính bên phải):
/// - Quản lý Bàn: Xem trạng thái các bàn (Trống, Có khách, Đã đặt) thời gian thực và dẫn sang chi tiết bàn để tính tiền.
/// - Quản lý Hóa đơn: Tìm kiếm và tra cứu lịch sử hóa đơn giao dịch.
class CashierDashboard extends StatefulWidget {
  const CashierDashboard({super.key});

  @override
  State<CashierDashboard> createState() => _CashierDashboardState();
}

class _CashierDashboardState extends State<CashierDashboard> {
  int _selectedIndex = 0; // Trạng thái tab đang chọn (0: Quản lý Bàn, 1: Quản lý Hóa đơn)

  /// Xây dựng lưới danh sách bàn ăn theo từng phân khu
  Widget _buildTableGridSection(List<TableModel> tables, Set<String> occupiedTableIds) {
    final areaA = tables.where((t) => t.area == 'A').toList();
    final areaB = tables.where((t) => t.area == 'B').toList();
    final areaC = tables.where((t) => t.area == 'C').toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildAreaSection('Khu vực A', areaA, occupiedTableIds),
        const SizedBox(height: 32),
        _buildAreaSection('Khu vực B', areaB, occupiedTableIds),
        const SizedBox(height: 32),
        _buildAreaSection('Khu vực C', areaC, occupiedTableIds),
      ],
    );
  }

  /// Xây dựng tiêu đề khu vực kèm Grid lưới bàn tương ứng
  Widget _buildAreaSection(String title, List<TableModel> tables, Set<String> occupiedTableIds) {
    if (tables.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
          ),
          itemCount: tables.length,
          itemBuilder: (context, index) {
            final table = tables[index];
            return _buildTableCard(table, occupiedTableIds);
          },
        ),
      ],
    );
  }

  /// Thiết kế thẻ (Card) hiển thị thông tin bàn ăn động theo trạng thái hoạt động
  Widget _buildTableCard(TableModel table, Set<String> occupiedTableIds) {
    Color bgColor;
    Color textColor = Colors.white;
    String statusText;

    // Determine status: if there are unpaid orders, mark as occupied
    final bool hasPendingOrders = occupiedTableIds.contains(table.id.replaceAll('-', ''));
    final String currentStatus = hasPendingOrders ? 'occupied' : table.status;

    // Phân loại màu sắc thẻ bàn theo trạng thái:
    // - Trống (empty): Màu xanh lá cây
    // - Đang ăn (occupied): Màu đỏ
    // - Được đặt trước (booked): Màu cam
    // - Khóa/Sửa chữa (locked): Màu vàng
    switch (currentStatus) {
      case 'occupied':
        bgColor = Colors.red.shade400;
        statusText = 'Có khách';
        break;
      case 'booked':
        bgColor = Colors.orange.shade400;
        statusText = 'Đã đặt';
        break;
      case 'locked':
        bgColor = Colors.amber.shade700;
        statusText = 'Khóa/Sửa chữa';
        break;
      default:
        bgColor = Colors.green.shade400;
        statusText = 'Trống';
        break;
    }

    return GestureDetector(
      onTap: () {
        // Chuyển hướng sang màn hình chi tiết gọi món của bàn ăn để kiểm tra hóa đơn và tiến hành thanh toán
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TableDetailScreen(table: table)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              table.id,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              statusText,
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            // Nếu bàn có khách, hiển thị thêm thông tin giờ khách bắt đầu vào bàn
            if (currentStatus == 'occupied' && table.entryTime != null)
              Text(
                'Vào: ${table.entryTime!.hour}:${table.entryTime!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.8)),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sử dụng StreamBuilder để lắng nghe liên tục danh sách bàn từ Firestore (real-time sync)
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tables').snapshots(),
      builder: (context, tablesSnapshot) {
        final List<TableModel> tables = [];
        if (tablesSnapshot.hasData) {
          for (var doc in tablesSnapshot.data!.docs) {
            tables.add(TableModel.fromMap(doc.id, doc.data() as Map<String, dynamic>));
          }
          tables.sort((a, b) => a.id.compareTo(b.id));
        }

        // Lắng nghe thêm danh sách các order chưa thanh toán (status == 'pending')
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, ordersSnapshot) {
            final Set<String> occupiedTableIds = {};
            if (ordersSnapshot.hasData) {
              for (var doc in ordersSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final tableInfo = data['tableInfo'] as String?;
                if (tableInfo != null) {
                  occupiedTableIds.add(tableInfo.replaceAll('-', ''));
                }
              }
            }

            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: const Text('Quầy Thu Ngân & Điều Phối Bàn Ăn', style: TextStyle(fontFamily: 'Playfair Display', fontWeight: FontWeight.bold)),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                actions: [
                  // Nút làm mới dữ liệu để cập nhật/vẽ lại giao diện tức thì
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Làm mới dữ liệu',
                    onPressed: () {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã cập nhật dữ liệu bàn mới nhất.'), duration: Duration(milliseconds: 850)),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Đăng xuất',
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/'); 
                    },
                  ),
                ],
              ),
              body: Row(
                children: [
                  // 1. Sidebar điều hướng bên trái (Navigation Sidebar)
                  Container(
                    width: 250,
                    color: Colors.white,
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        const Icon(Icons.point_of_sale, size: 80, color: AppColors.primary),
                        const SizedBox(height: 16),
                        const Text('Quầy Thu Ngân', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 32),
                        
                        ListTile(
                          leading: const Icon(Icons.table_restaurant),
                          title: const Text('Quản lý Bàn'),
                          selected: _selectedIndex == 0,
                          selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                          selectedColor: AppColors.primary,
                          onTap: () => setState(() => _selectedIndex = 0),
                        ),
                        ListTile(
                          leading: const Icon(Icons.receipt_long),
                          title: const Text('Quản lý Hóa đơn'),
                          selected: _selectedIndex == 1,
                          selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                          selectedColor: AppColors.primary,
                          onTap: () => setState(() => _selectedIndex = 1),
                        ),
                      ],
                    ),
                  ),
                  
                  // 2. Vùng hiển thị nội dung bên phải (Right Content Workspace)
                  Expanded(
                    child: _selectedIndex == 1
                        ? const CashierHistoryScreen(embedMode: true) // Nhúng màn hình lịch sử hóa đơn ở chế độ không appBar
                        : tablesSnapshot.connectionState == ConnectionState.waiting
                            ? const Center(child: CircularProgressIndicator())
                            : tables.isEmpty
                                ? const Center(child: Text('Chưa có dữ liệu bàn.'))
                                : _buildTableGridSection(tables, occupiedTableIds),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
