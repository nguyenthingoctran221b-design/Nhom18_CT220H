import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../models/table_model.dart';
import 'table_detail_screen.dart';

class CashierDashboard extends StatelessWidget {
  const CashierDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thu Ngân - Quản lý Bàn', style: TextStyle(fontFamily: 'Playfair Display', fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: Log out logic
              Navigator.pushReplacementNamed(context, '/'); // Assumes we can restart app or go to login
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tables').orderBy('id').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có dữ liệu bàn.'));
          }

          final tables = snapshot.data!.docs.map((doc) => TableModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();

          // Group by Area
          final areaA = tables.where((t) => t.area == 'A').toList();
          final areaB = tables.where((t) => t.area == 'B').toList();
          final areaC = tables.where((t) => t.area == 'C').toList();

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildAreaSection('Khu vực A', areaA, context),
              const SizedBox(height: 32),
              _buildAreaSection('Khu vực B', areaB, context),
              const SizedBox(height: 32),
              _buildAreaSection('Khu vực C', areaC, context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAreaSection(String title, List<TableModel> tables, BuildContext context) {
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
            return _buildTableCard(table, context);
          },
        ),
      ],
    );
  }

  Widget _buildTableCard(TableModel table, BuildContext context) {
    Color bgColor;
    Color textColor = Colors.white;
    String statusText;

    switch (table.status) {
      case 'occupied':
        bgColor = Colors.red.shade400;
        statusText = 'Có khách';
        break;
      case 'booked':
        bgColor = Colors.orange.shade400;
        statusText = 'Đã đặt';
        break;
      default:
        bgColor = Colors.green.shade400;
        statusText = 'Trống';
        break;
    }

    return GestureDetector(
      onTap: () {
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
              color: Colors.black.withOpacity(0.1),
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
            if (table.status == 'occupied' && table.entryTime != null)
              Text(
                'Vào: ${table.entryTime!.hour}:${table.entryTime!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.8)),
              ),
          ],
        ),
      ),
    );
  }
}
