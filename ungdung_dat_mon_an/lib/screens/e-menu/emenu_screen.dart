import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/menu_data.dart';

/// Màn hình E-Menu chính — bố cục landscape cho iPad
/// Gồm: Top Nav Bar, Left Category Sidebar, Center Food Grid, Right Detail Panel
class EMenuScreen extends StatefulWidget {
  const EMenuScreen({super.key});

  @override
  State<EMenuScreen> createState() => _EMenuScreenState();
}

class _EMenuScreenState extends State<EMenuScreen> {
  int _activeCategoryIdx = 1; // Default: Đồ Nhúng Lẩu
  MenuItem? _selectedItem;
  int _quantity = 1;
  int _activeTab = 0; // 0: Thực đơn, 1: Giỏ hàng, 2: Lịch sử
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

  /// Lọc items theo search query
  List<MenuItem> get _filteredItems {
    final items = menuData[_activeCategoryIdx].items;
    if (_searchQuery.isEmpty) return items;
    return items
        .where((item) =>
            item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
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
              child: Row(
                children: [
                  // ═══════ 2. LEFT CATEGORY SIDEBAR ═══════
                  _buildCategorySidebar(),

                  // ═══════ 3. CENTER FOOD GRID ═══════
                  Expanded(child: _buildFoodGrid()),

                  // ═══════ 4. RIGHT DETAIL PANEL ═══════
                  if (_selectedItem != null)
                    _buildDetailPanel(_selectedItem!),
                ],
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
            color: Colors.black.withOpacity(0.05),
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
                  'Sen Vàng Food',
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
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Bàn số: 05',
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
  //  LEFT CATEGORY SIDEBAR
  // ═══════════════════════════════════════════════
  Widget _buildCategorySidebar() {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey[200]!)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: menuData.length,
        itemBuilder: (context, index) {
          final cat = menuData[index];
          final isActive = index == _activeCategoryIdx;

          return GestureDetector(
            onTap: () {
              setState(() {
                _activeCategoryIdx = index;
                _selectedItem = null;
                _searchQuery = '';
                _searchController.clear();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary.withOpacity(0.05)
                    : Colors.transparent,
                border: Border(
                  right: BorderSide(
                    color:
                        isActive ? AppColors.primary : Colors.transparent,
                    width: 4,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getCategoryIcon(cat.icon),
                    size: 20,
                    color: isActive ? AppColors.primary : Colors.grey[400],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cat.shortName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive
                            ? AppColors.primary
                            : Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  CENTER FOOD GRID
  // ═══════════════════════════════════════════════
  Widget _buildFoodGrid() {
    final items = _filteredItems;

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
                  menuData[_activeCategoryIdx].category,
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
              color: Colors.black.withOpacity(0.04),
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
                          color: Colors.white.withOpacity(0.7),
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
                        color: AppColors.secondary.withOpacity(0.4),
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
            color: Colors.black.withOpacity(0.08),
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
                          Colors.black.withOpacity(0.5),
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
                        color: Colors.black.withOpacity(0.4),
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
                      shadowColor: AppColors.primary.withOpacity(0.3),
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
