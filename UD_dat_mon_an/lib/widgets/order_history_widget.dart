import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/order_repository.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/pdf_invoice_helper.dart';
import 'package:intl/intl.dart';

class OrderHistoryWidget extends StatelessWidget {
  final String tableInfo;

  const OrderHistoryWidget({super.key, required this.tableInfo});

  @override
  Widget build(BuildContext context) {
    final repo = OrderRepository();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.history, color: AppColors.primary, size: 32),
              const SizedBox(width: 12),
              const Text(
                'Lịch sử gọi món',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Bàn: $tableInfo',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),

          // Orders Stream
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: repo.watchOrders(tableInfo),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (snapshot.hasError) {
                  return const Center(child: Text('Có lỗi xảy ra khi tải dữ liệu'));
                }

                final orders = snapshot.data ?? [];

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Bàn này chưa gọi món nào',
                          style: TextStyle(color: Colors.grey[500], fontSize: 20),
                        ),
                      ],
                    ),
                  );
                }

                // Tính tổng tất cả các đơn
                double grandTotal = 0;
                for (var o in orders) {
                  grandTotal += o.totalAmount;
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: orders.length,
                        itemBuilder: (context, index) {
                          final order = orders[index];
                          final dateFormat = DateFormat('HH:mm - dd/MM/yyyy');
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ExpansionTile(
                              title: Text(
                                'Đơn hàng lúc ${dateFormat.format(order.createdAt)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              subtitle: Text(
                                'Tổng tiền: ${_formatPrice(order.totalAmount.toInt())}',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              ),
                              children: order.orderItems?.map((item) {
                                return ListTile(
                                  title: Text('${item.quantity} x ${item.name}'),
                                  trailing: Text(
                                    _formatPrice(item.total.toInt()),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                );
                              }).toList() ?? [],
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TỔNG HOÁ ĐƠN TẠM TÍNH:',
                          style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatPrice(grandTotal.toInt()),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: () => PdfInvoiceHelper.generateAndPrintInvoice(orders, tableInfo),
                        icon: const Icon(Icons.print, size: 28),
                        label: const Text(
                          'In hoá đơn tạm tính',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
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
