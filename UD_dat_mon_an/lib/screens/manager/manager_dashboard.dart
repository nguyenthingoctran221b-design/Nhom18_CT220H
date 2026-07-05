import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_colors.dart';
import 'menu_management_screen.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  double _calculateTotalRevenue(List<QueryDocumentSnapshot> invoices) {
    double total = 0;
    for (var doc in invoices) {
      total += (doc['grandTotal'] as num).toDouble();
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản lý - Bảng điều khiển', style: TextStyle(fontFamily: 'Playfair Display', fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/'); 
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Sidebar Navigation
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              children: [
                const SizedBox(height: 32),
                const Icon(Icons.admin_panel_settings, size: 80, color: AppColors.primary),
                const SizedBox(height: 16),
                const Text('Quản lý chung', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                ListTile(
                  leading: const Icon(Icons.dashboard, color: AppColors.primary),
                  title: const Text('Doanh thu', style: TextStyle(fontWeight: FontWeight.bold)),
                  selected: true,
                  selectedTileColor: AppColors.primary.withOpacity(0.1),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.restaurant_menu),
                  title: const Text('Quản lý Thực đơn'),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MenuManagementScreen()));
                  },
                ),
              ],
            ),
          ),
          
          // Right Content Area (Revenue Dashboard)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('invoices').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final invoices = snapshot.data?.docs ?? [];
                final totalRevenue = _calculateTotalRevenue(invoices);

                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tổng quan doanh thu', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      const SizedBox(height: 32),
                      
                      // KPI Cards
                      Row(
                        children: [
                          _buildKpiCard('Tổng doanh thu', _formatPrice(totalRevenue.toInt()), Icons.attach_money, Colors.green),
                          const SizedBox(width: 24),
                          _buildKpiCard('Tổng số đơn', '${invoices.length} đơn', Icons.receipt_long, Colors.blue),
                        ],
                      ),
                      const SizedBox(height: 48),

                      // Chart Area (Simplified Demo)
                      const Text('Biểu đồ doanh thu gần đây (Demo)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                            ],
                          ),
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: totalRevenue > 0 ? totalRevenue * 1.2 : 1000000,
                              titlesData: const FlTitlesData(
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                  ),
                                ),
                              ),
                              barGroups: [
                                BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: totalRevenue * 0.2, color: AppColors.primary, width: 20)]),
                                BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: totalRevenue * 0.5, color: AppColors.primary, width: 20)]),
                                BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: totalRevenue * 0.8, color: AppColors.primary, width: 20)]),
                                BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: totalRevenue, color: AppColors.secondary, width: 20)]),
                              ],
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ],
            )
          ],
        ),
      ),
    );
  }

  String _formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$formatted ₫';
  }
}
