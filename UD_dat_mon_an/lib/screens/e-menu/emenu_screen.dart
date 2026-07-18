import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/menu_data.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/cart_view_widget.dart';
import '../../widgets/order_history_widget.dart';

/// Màn hình Thực đơn Điện tử (EMenuScreen)
/// Phục vụ cho khách hàng trực tiếp tại bàn bằng máy tính bảng (iPad/Tablet).
/// Giao diện thiết kế theo tỷ lệ Landscape chuyên nghiệp, chia các phân khu trực quan:
/// - 1. Top Navigation Bar: Logo nhà hàng, số bàn hiện tại, chọn Tab làm việc, gọi phục vụ nhanh.
/// - 2. Left Category Sidebar: Bộ lọc phân loại thực đơn (Lẩu, đồ nhúng, khai vị, nước uống).
/// - 3. Center Food Grid: Lưới hiển thị danh sách món ăn sinh động có ảnh minh họa.
/// - 4. Right Detail Panel: Bảng chi tiết món ăn (thành phần, TFP chuẩn bị, tùy chỉnh số lượng) khi khách nhấp chọn.
class EMenuScreen extends StatefulWidget {
  final String tableInfo;

  const EMenuScreen({super.key, this.tableInfo = 'A-01'});

  @override
  State<EMenuScreen> createState() => _EMenuScreenState();
}

class _EMenuScreenState extends State<EMenuScreen> {
  int _activeCategoryIdx = 1; // Mặc định hiển thị danh mục Đồ Nhúng Lẩu (Index 1)
  MenuItem? _selectedItem; // Món ăn đang được nhấp chọn xem chi tiết
  int _quantity = 1; // Số lượng món đang chọn để thêm vào giỏ hàng
  int _activeTab = 0; // Tab hiển thị chính (0: Thực đơn, 1: Giỏ hàng, 2: Lịch sử gọi món của phiên này)
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  /// Format giá tiền theo kiểu Việt Nam (thêm dấu chấm ngăn cách hàng nghìn)
  String _formatPrice(int price) {
    final str = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return '${buffer.toString()} đ';
  }

  /// Icon tương ứng cho từng loại danh mục
  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'soup':
        return Icons.soup_kitchen;
      case 'beef':
        return Icons.set_meal;
      case 'utensils':
        return Icons.restaurant;
      case 'chef-hat':
        return Icons.restaurant_menu;
      case 'ice-cream':
        return Icons.icecream;
      case 'cup-soda':
        return Icons.local_cafe;
      default:
        return Icons.fastfood;
    }
  }

  /// Lấy icon dựa theo tên danh mục tiếng Việt
  IconData _getCategoryIconByName(String categoryName) {
    switch (categoryName) {
      case 'Nước Lẩu':
        return Icons.soup_kitchen;
      case 'Đồ Nhúng Lẩu':
        return Icons.set_meal;
      case 'Món Khai Vị':
        return Icons.ramen_dining;
      case 'Món Cuốn':
        return Icons.restaurant;
      case 'Món Tráng Miệng':
        return Icons.icecream;
      case 'Đồ Uống':
        return Icons.local_cafe;
      default:
        return Icons.fastfood;
    }
  }

  void _openDetail(MenuItem item) {
    setState(() {
      _selectedItem = item;
      _quantity = 1;
    });
  }

  void _closeDetail() {
    setState(() {
      _selectedItem = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _updateTableStatusToOccupied();
  }

  Future<void> _updateTableStatusToOccupied() async {
    try {
      final normalizedId = widget.tableInfo.replaceAll('-', '');
      final tableRef = FirebaseFirestore.instance.collection('tables').doc(normalizedId);
      
      final doc = await tableRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final currentStatus = data['status'] ?? 'empty';
        if (currentStatus != 'occupied') {
          await tableRef.update({
            'status': 'occupied',
            'entryTime': FieldValue.serverTimestamp(),
          });
        }
      } else {
        String area = 'A';
        int number = 1;
        if (widget.tableInfo.contains('-')) {
          final parts = widget.tableInfo.split('-');
          area = parts.first;
          number = int.tryParse(parts.last) ?? 1;
        } else if (widget.tableInfo.length >= 2) {
          area = widget.tableInfo.substring(0, 1);
          number = int.tryParse(widget.tableInfo.substring(1)) ?? 1;
        }
        await tableRef.set({
          'area': area,
          'number': number,
          'status': 'occupied',
          'entryTime': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error updating table status to occupied: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ═══════ 1. TOP NAVIGATION BAR ═══════
            _buildTopBar(),

            // ═══════ MAIN BODY ═══════
            Expanded(
              child: _activeTab == 1
                  ? CartViewWidget(tableInfo: widget.tableInfo)
                  : _activeTab == 2
                      ? OrderHistoryWidget(tableInfo: widget.tableInfo)
                      : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('menu').snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final allItems = snapshot.data?.docs.map((doc) => MenuItem.fromMap(doc.id, doc.data() as Map<String, dynamic>)).where((item) => item.isAvailable).toList() ?? [];

                            // Group items by category
                            final Map<String, List<MenuItem>> grouped = {};
                            for (var item in allItems) {
                              if (!grouped.containsKey(item.category)) grouped[item.category] = [];
                              grouped[item.category]!.add(item);
                            }

                            final categories = grouped.keys.toList();
                            if (categories.isEmpty) {
                              return const Center(child: Text('Chưa có thực đơn'));
                            }

                            if (_activeCategoryIdx >= categories.length) {
                              _activeCategoryIdx = 0; // Reset if out of bounds
                            }

                            final currentCategoryItems = grouped[categories[_activeCategoryIdx]]!;

                            return Row(
                              children: [
                                // ═══════ 2. LEFT CATEGORY SIDEBAR ═══════
                                _buildCategorySidebarDynamic(categories),

                                // ═══════ 3. CENTER FOOD GRID ═══════
                                Expanded(child: _buildFoodGridDynamic(categories[_activeCategoryIdx], currentCategoryItems)),

                                // ═══════ 4. RIGHT DETAIL PANEL ═══════
                                if (_selectedItem != null)
                                  _buildDetailPanel(_selectedItem!),
                              ],
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  TOP NAVIGATION BAR
  // ═══════════════════════════════════════════════
  Widget _buildTopBar() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // ── Left: Logo & Bàn số ──
            Row(
              children: [
                const Icon(Icons.restaurant_menu,
                    color: AppColors.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Sen Vàng Indochine',
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 16),
                Container(width: 1, height: 24, color: Colors.grey[300]),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Bàn số: ${widget.tableInfo}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // ── Center: Tabs ──
            Row(
              children: [
                _buildTabButton(
                  icon: Icons.book,
                  label: 'Thực đơn chính',
                  isActive: _activeTab == 0,
                  onTap: () => setState(() => _activeTab = 0),
                ),
                const SizedBox(width: 32),
                _buildTabButton(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Giỏ hàng hiện tại',
                  isActive: _activeTab == 1,
                  onTap: () => setState(() => _activeTab = 1),
                ),
                const SizedBox(width: 32),
                _buildTabButton(
                  icon: Icons.access_time,
                  label: 'Lịch sử gọi món',
                  isActive: _activeTab == 2,
                  onTap: () => setState(() => _activeTab = 2),
                ),
              ],
            ),

            const Spacer(),

            // ── Right: Gọi nhân viên ──
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Đã gọi nhân viên! Vui lòng chờ...'),
                    backgroundColor: AppColors.secondary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_active, size: 20),
              label: const Text(
                'Gọi nhân viên',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tab button trong top bar
  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? AppColors.primary : Colors.grey[400],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : Colors.grey[400],
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  LEFT CATEGORY SIDEBAR DYNAMIC
  // ═══════════════════════════════════════════════
  Widget _buildCategorySidebarDynamic(List<String> categories) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 24),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == _activeCategoryIdx;
          return GestureDetector(
            onTap: () {
              setState(() {
                _activeCategoryIdx = index;
                _searchQuery = '';
                _searchController.clear();
              });
            },
            child: Container(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.05)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getCategoryIconByName(categories[index]),
                      color: isSelected ? Colors.white : Colors.grey[400],
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    categories[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.grey[400],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  CENTER FOOD GRID DYNAMIC
  // ═══════════════════════════════════════════════
  Widget _buildFoodGridDynamic(String categoryName, List<MenuItem> rawItems) {
    List<MenuItem> items = List.from(rawItems);
    if (_searchQuery.isNotEmpty) {
      items = items.where((item) => item.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    return Container(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Header: Tên danh mục + Ô tìm kiếm ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  categoryName,
                  style: const TextStyle(
                    fontFamily: 'Playfair Display',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                // Search bar
                Container(
                  width: 260,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Tìm món ăn...',
                      hintStyle:
                          TextStyle(fontSize: 13, color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search,
                          size: 20, color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Grid món ăn ──
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            'Không tìm thấy món ăn',
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.6,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return _buildFoodCard(items[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card món ăn
  Widget _buildFoodCard(MenuItem item) {
    return GestureDetector(
      onTap: () => _openDetail(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Ảnh món ──
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.restaurant,
                              size: 40, color: Colors.grey[400]),
                        ),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: Colors.grey[100],
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        },
                      ),
                      // Overlay "Hết món"
                      if (!item.isAvailable)
                        Container(
                          color: Colors.white.withValues(alpha: 0.7),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red[500],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Hết món',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Tên + Giá ──
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontFamily: 'Playfair Display',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.text,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatPrice(item.price),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Nút "+" thêm nhanh ──
            Positioned(
              bottom: 10,
              right: 10,
              child: GestureDetector(
                onTap: () => _openDetail(item),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  RIGHT DETAIL PANEL (slide-in)
  // ═══════════════════════════════════════════════
  Widget _buildDetailPanel(MenuItem item) {
    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(-10, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Ảnh lớn + nút đóng ──
          SizedBox(
            height: 280,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.restaurant,
                        size: 60, color: Colors.grey[400]),
                  ),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                ),
                // Nút đóng
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: _closeDetail,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Thông tin chi tiết ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontFamily: 'Playfair Display',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatPrice(item.price),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Thanh accent
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Thành phần
                  Text(
                    'THÀNH PHẦN CHÍNH',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: item.ingredients.map((ing) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Text(
                          ing,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom: Chọn số lượng + Xác nhận ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[100]!)),
            ),
            child: Column(
              children: [
                // Bộ chọn số lượng
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildQuantityButton(
                        icon: Icons.remove,
                        onTap: () {
                          if (_quantity > 1) {
                            setState(() => _quantity--);
                          }
                        },
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(
                          '$_quantity',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildQuantityButton(
                        icon: Icons.add,
                        onTap: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Nút xác nhận
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Provider.of<CartProvider>(context, listen: false)
                          .addItem(item, quantity: _quantity);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Đã thêm $_quantity x ${item.name} vào giỏ hàng'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                      _closeDetail();
                    },
                    icon: const Icon(Icons.add_circle_outline, size: 22),
                    label: const Text(
                      'Xác nhận thêm món',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                      shadowColor: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Nút tăng/giảm số lượng
  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.grey[600], size: 20),
      ),
    );
  }
}
