import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order.dart';

class ChefDashboard extends StatefulWidget {
  final String chefId;
  const ChefDashboard({super.key, this.chefId = 'chef1'});

  @override
  State<ChefDashboard> createState() => _ChefDashboardState();
}

class _ChefDashboardState extends State<ChefDashboard> {
  String? _selectedArea; // 'food' hoặc 'beverage'
  Map<String, String> _itemCategories = {};
  bool _loadingMenu = true;

  @override
  void initState() {
    super.initState();
    _loadMenuCategories();
  }

  Future<void> _loadMenuCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('menu').get();
      final Map<String, String> itemCategories = {};
      for (var doc in snapshot.docs) {
        final name = doc['name'] as String?;
        final cat = doc['category'] as String?;
        if (name != null && cat != null) {
          itemCategories[name] = cat;
        }
      }
      setState(() {
        _itemCategories = itemCategories;
        _loadingMenu = false;
      });
    } catch (e) {
      print('Error loading menu categories: $e');
      setState(() => _loadingMenu = false);
    }
  }

  bool _matchesSelectedArea(String itemName) {
    final category = _itemCategories[itemName] ?? '';
    final catLower = category.toLowerCase();

    // Xác định món thuộc khu nước uống/tráng miệng
    final isBeverage = catLower.contains('uống') || 
                       catLower.contains('tráng miệng') || 
                       catLower.contains('sinh tố') || 
                       catLower.contains('cà phê') || 
                       catLower.contains('nước ép') || 
                       catLower.contains('chè') || 
                       catLower.contains('kem') ||
                       (catLower.contains('nước') && !catLower.contains('lẩu'));

    if (_selectedArea == 'food') {
      // Khu Món Ăn: tất cả món KHÔNG thuộc khu nước uống (lẩu, khai vị, nhúng, cuốn, món chính,...)
      return !isBeverage;
    } else if (_selectedArea == 'beverage') {
      // Khu Nước Uống: tráng miệng, đồ uống giải nhiệt, sinh tố,...
      return isBeverage;
    }
    return true; // Mặc định hiển thị nếu không chọn phân khu
  }

  // Nhóm các món giống nhau từ các order
  List<Map<String, dynamic>> _processQueue(
    List<OrderModel> orders, {
    required String filterStatus,
    String? filterChefId,
  }) {
    if (orders.isEmpty) return [];

    // 1. Lọc các order có chứa ít nhất 1 món thuộc khu vực này và trùng trạng thái cần tìm
    final List<OrderModel> matchingOrders = [];
    for (var order in orders) {
      if (order.orderItems == null) continue;
      bool hasMatchingItem = false;
      for (var item in order.orderItems!) {
        if (item.status != filterStatus) continue;
        if (filterStatus == 'cooking' && filterChefId != null && item.chefId != filterChefId) {
          continue;
        }
        if (_matchesSelectedArea(item.name)) {
          hasMatchingItem = true;
          break;
        }
      }
      if (hasMatchingItem) {
        matchingOrders.add(order);
      }
    }

    // 2. Tab hàng đợi món (chờ làm) chỉ lấy 3 bàn đầu tiên trong hàng đợi có món thuộc khu vực này
    final ordersToProcess = filterStatus == 'pending' ? matchingOrders.take(3).toList() : matchingOrders;
    
    // 3. Gom nhóm các món
    final Map<String, Map<String, dynamic>> groupedItems = {};

    for (var order in ordersToProcess) {
      for (int i = 0; i < order.orderItems!.length; i++) {
        final item = order.orderItems![i];
        
        // Chỉ xử lý món có status trùng khớp (pending hoặc cooking)
        if (item.status != filterStatus) continue;

        // Nếu là tab đang nấu, chỉ hiện các món được nhận bởi đúng đầu bếp này
        if (filterStatus == 'cooking' && filterChefId != null && item.chefId != filterChefId) {
          continue;
        }

        // Lọc theo phân khu làm việc
        if (!_matchesSelectedArea(item.name)) continue;

        if (groupedItems.containsKey(item.name)) {
          groupedItems[item.name]!['totalQuantity'] += item.quantity;
          groupedItems[item.name]!['orderRefs'].add({
            'orderId': order.id,
            'itemIndex': i,
            'tableInfo': order.tableInfo,
            'status': item.status,
            'acceptedAt': item.acceptedAt,
            'chefId': item.chefId,
          });
        } else {
          groupedItems[item.name] = {
            'name': item.name,
            'tfp': item.tfp,
            'totalQuantity': item.quantity,
            'status': item.status,
            'orderRefs': [
              {
                'orderId': order.id,
                'itemIndex': i,
                'tableInfo': order.tableInfo,
                'status': item.status,
                'acceptedAt': item.acceptedAt,
                'chefId': item.chefId,
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
        if (newStatus == 'cooking') {
          updatedItems[idx]['acceptedAt'] = Timestamp.now();
          updatedItems[idx]['chefId'] = widget.chefId;
        }
      }
      
      batch.update(docRef, {'items': updatedItems});
    }

    await batch.commit();
  }

  String _getDurationText(DateTime? acceptedAt) {
    if (acceptedAt == null) return '';
    final diff = DateTime.now().difference(acceptedAt);
    if (diff.inMinutes == 0) return 'Mới nhận làm';
    return 'Đã nấu được ${diff.inMinutes} phút';
  }

  // ═══════════════════════════════════════════════
  //  UI AREA SELECTION SCREEN
  // ═══════════════════════════════════════════════
  Widget _buildAreaSelectionView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.soup_kitchen, size: 80, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'CHỌN KHU VỰC CHẾ BIẾN',
              style: TextStyle(
                fontFamily: 'Playfair Display',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng chọn phân khu làm việc của bạn để quản lý hàng đợi món ăn tương ứng',
              style: TextStyle(fontSize: 15, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAreaCard(
                  title: 'Khu Món Ăn',
                  subtitle: 'Lẩu, Khai vị, Đồ nhúng & Cuốn',
                  icon: Icons.restaurant,
                  color: Colors.orange.shade50,
                  borderColor: Colors.orange.shade300,
                  iconColor: Colors.orange.shade700,
                  onTap: () => setState(() => _selectedArea = 'food'),
                ),
                const SizedBox(width: 32),
                _buildAreaCard(
                  title: 'Khu Nước Uống',
                  subtitle: 'Tráng miệng, Nước ép & Đồ uống',
                  icon: Icons.local_cafe,
                  color: Colors.blue.shade50,
                  borderColor: Colors.blue.shade300,
                  iconColor: Colors.blue.shade700,
                  onTap: () => setState(() => _selectedArea = 'beverage'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color borderColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(icon, size: 120, color: color),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      child: Icon(icon, size: 36, color: iconColor),
                    ),
                    const Spacer(),
                    Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    const SizedBox(height: 6),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  MAIN BUILD METHOD
  // ═══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_loadingMenu) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_selectedArea == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Hệ Thống Phân Khu Chế Biến', style: TextStyle(fontFamily: 'Playfair Display', fontWeight: FontWeight.bold)),
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
        body: _buildAreaSelectionView(),
      );
    }

    final areaTitle = _selectedArea == 'food' ? 'Khu Món Ăn' : 'Khu Nước Uống';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Row(
            children: [
              Text('Hệ Thống Phân Khu Chế Biến (${widget.chefId})', style: const TextStyle(fontFamily: 'Playfair Display', fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  areaTitle,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.queue_play_next), text: 'Hàng đợi món (Top 3 Bàn)'),
              Tab(icon: Icon(Icons.restaurant), text: 'Món tôi đang nấu'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Đổi khu vực làm việc',
              onPressed: () {
                setState(() => _selectedArea = null);
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/'); 
              },
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('status', isEqualTo: 'pending')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allOrders = snapshot.data?.docs
                    .map((doc) => OrderModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
                    .toList() ?? [];
            allOrders.sort((a, b) => a.createdAt.compareTo(b.createdAt)); // Sắp xếp cũ nhất lên đầu

            return TabBarView(
              children: [
                // Tab 1: Hàng đợi món (chờ làm)
                _buildQueueTab(allOrders),

                // Tab 2: Món đang nấu (của đầu bếp hiện tại)
                _buildCookingTab(allOrders),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQueueTab(List<OrderModel> allOrders) {
    final queueItems = _processQueue(allOrders, filterStatus: 'pending');

    if (queueItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Không có món mới nào đang chờ làm.', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: queueItems.length,
      itemBuilder: (context, index) {
        final item = queueItems[index];
        final orderRefs = item['orderRefs'] as List<dynamic>;

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
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red,
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

                // Button Nhận làm
                ElevatedButton.icon(
                  onPressed: () => _updateItemStatus(orderRefs, 'cooking', allOrders),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Nhận làm'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCookingTab(List<OrderModel> allOrders) {
    final cookingItems = _processQueue(allOrders, filterStatus: 'cooking', filterChefId: widget.chefId);

    if (cookingItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.soup_kitchen_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Bạn chưa nhận nấu món nào.', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: cookingItems.length,
      itemBuilder: (context, index) {
        final item = cookingItems[index];
        final orderRefs = item['orderRefs'] as List<dynamic>;

        // Lấy thời gian nhận làm từ orderRefs
        DateTime? acceptedAt;
        if (orderRefs.isNotEmpty && orderRefs[0]['acceptedAt'] != null) {
          acceptedAt = orderRefs[0]['acceptedAt'] as DateTime;
        }

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
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.orange,
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
                        'Số lượng: ${item['totalQuantity']}  |  ${_getDurationText(acceptedAt)}',
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

                // Button Đã xong
                ElevatedButton.icon(
                  onPressed: () => _updateItemStatus(orderRefs, 'done', allOrders),
                  icon: const Icon(Icons.check),
                  label: const Text('Đã xong'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
