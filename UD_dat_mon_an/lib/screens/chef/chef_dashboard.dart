import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order.dart';

class ChefDashboard extends StatefulWidget {
  const ChefDashboard({super.key});

  @override
  State<ChefDashboard> createState() => _ChefDashboardState();
}

class _ChefDashboardState extends State<ChefDashboard> {
  // Nhóm các món giống nhau từ top 3 bàn
  List<Map<String, dynamic>> _processQueue(List<OrderModel> orders) {
    if (orders.isEmpty) return [];

    // Lấy danh sách tối đa 3 bàn đầu tiên trong hàng đợi (sắp xếp theo thời gian cũ nhất)
    final top3Orders = orders.take(3).toList();
    
    // Gom nhóm các món
    final Map<String, Map<String, dynamic>> groupedItems = {};

    for (var order in top3Orders) {
      if (order.orderItems == null) continue;
      
      // Vì array trong Firestore không dễ update từng item độc lập, ta cần biết index
      for (int i = 0; i < order.orderItems!.length; i++) {
        final item = order.orderItems![i];
        
        // Bỏ qua món đã làm xong
        if (item.status == 'done') continue;

        if (groupedItems.containsKey(item.name)) {
          groupedItems[item.name]!['totalQuantity'] += item.quantity;
          groupedItems[item.name]!['orderRefs'].add({
            'orderId': order.id,
            'itemIndex': i,
            'tableInfo': order.tableInfo,
            'status': item.status,
          });
        } else {
          groupedItems[item.name] = {
            'name': item.name,
            'tfp': item.tfp,
            'totalQuantity': item.quantity,
            'status': item.status, // pending or cooking
            'orderRefs': [
              {
                'orderId': order.id,
                'itemIndex': i,
                'tableInfo': order.tableInfo,
                'status': item.status,
              }
            ],
          };
        }
      }
    }

    final result = groupedItems.values.toList();
    // SJF Algorithm: Sắp xếp theo TFP thấp nhất lên đầu
    result.sort((a, b) => (a['tfp'] as int).compareTo(b['tfp'] as int));

    return result;
  }

  Future<void> _updateItemStatus(List<dynamic> orderRefs, String newStatus, List<OrderModel> allOrders) async {
    final batch = FirebaseFirestore.instance.batch();

    // Group orderRefs by orderId to avoid multiple updates to same doc in one batch
    final Map<String, List<int>> orderIdToIndices = {};
    for (var ref in orderRefs) {
      final orderId = ref['orderId'] as String;
      final idx = ref['itemIndex'] as int;
      if (!orderIdToIndices.containsKey(orderId)) {
        orderIdToIndices[orderId] = [];
      }
      orderIdToIndices[orderId]!.add(idx);
    }

    for (var entry in orderIdToIndices.entries) {
      final orderId = entry.key;
      final indices = entry.value;

      final docRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
      final order = allOrders.firstWhere((o) => o.id == orderId);
      
      // Update specific indices
      final updatedItems = order.toMap()['items'] as List<dynamic>;
      for (var idx in indices) {
        updatedItems[idx]['status'] = newStatus;
      }
      
      batch.update(docRef, {'items': updatedItems});
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bếp - Xếp hàng (Top 3 Bàn)', style: TextStyle(fontFamily: 'Playfair Display', fontWeight: FontWeight.bold)),
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
      body: StreamBuilder<QuerySnapshot>(
        // Lấy tất cả các order pending (đang làm) sắp xếp cũ nhất lên đầu
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Không có đơn hàng nào cần làm.', style: TextStyle(fontSize: 20, color: Colors.grey)),
                ],
              ),
            );
          }

          final allOrders = snapshot.data!.docs.map((doc) => OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();
          allOrders.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Sắp xếp cũ nhất lên đầu
          
          final queueItems = _processQueue(allOrders);

          if (queueItems.isEmpty) {
            return const Center(child: Text('Tất cả các món của 3 bàn đầu đã hoàn thành. Chờ thu ngân xử lý hoặc khách gọi thêm.', style: TextStyle(fontSize: 18)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: queueItems.length,
            itemBuilder: (context, index) {
              final item = queueItems[index];
              final orderRefs = item['orderRefs'] as List<dynamic>;
              
              // Determine overall status based on refs. If any is cooking, it's cooking.
              bool isCooking = orderRefs.any((ref) => ref['status'] == 'cooking');

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Status Indicator
                      Container(
                        width: 16,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isCooking ? Colors.orange : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Item Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Số lượng: ${item['totalQuantity']}  |  TFP: ${item['tfp']} phút',
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Từ bàn: ${orderRefs.map((r) => r['tableInfo']).toSet().join(', ')}',
                              style: const TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      // Actions
                      if (!isCooking)
                        ElevatedButton.icon(
                          onPressed: () => _updateItemStatus(orderRefs, 'cooking', allOrders),
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Nhận làm'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => _updateItemStatus(orderRefs, 'done', allOrders),
                          icon: const Icon(Icons.check),
                          label: const Text('Đã xong'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
