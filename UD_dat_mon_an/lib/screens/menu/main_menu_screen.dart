import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/menu_category.dart';
import '../../models/menu_item.dart';
import '../../services/database_seeder.dart';
import '../../services/menu_repository.dart';
import '../../widgets/category_list_widget.dart';
import '../../widgets/food_card_widget.dart';
import '../../widgets/food_detail_panel.dart';

/// ============================================================
/// MAIN MENU SCREEN — Màn hình Thực Đơn 3 Cột
/// ============================================================
/// Tối ưu cho tablet ở chế độ Landscape.
/// Bố cục: [Cột Trái 20%] | [Cột Giữa 45%] | [Cột Phải 35%]
/// ============================================================
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  // ── Repository duy nhất cho màn hình này ──
  final MenuRepository _repository = MenuRepository();

  // ── State: Category đang được chọn ──
  MenuCategory? _selectedCategory;

  // ── State: Món ăn đang được xem chi tiết ──
  MenuItem? _selectedItem;

  // ─────────────────────────────────────────────────────────────
  // Callbacks
  // ─────────────────────────────────────────────────────────────

  /// Khi người dùng chọn một category.
  void _onCategorySelected(MenuCategory category) {
    if (_selectedCategory?.id == category.id) return; // Không đổi nếu đã chọn
    setState(() {
      _selectedCategory = category;
      _selectedItem = null; // Reset detail panel khi đổi category
    });
  }

  /// Khi người dùng tap vào một món ăn.
  void _onItemSelected(MenuItem item) {
    setState(() {
      _selectedItem = item;
    });
  }

  /// Khi người dùng nhấn "Thêm vào giỏ hàng".
  void _onAddToCart() {
    if (_selectedItem == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '✅ Đã thêm "${_selectedItem!.name}" vào giỏ hàng!',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ══════════════════════════════════════
          // CỘT TRÁI (20%) — Danh sách Categories
          // ══════════════════════════════════════
          Flexible(
            flex: 20,
            child: _buildLeftColumn(),
          ),

          // ══════════════════════════════════════
          // CỘT GIỮA (45%) — Danh sách Món Ăn
          // ══════════════════════════════════════
          Flexible(
            flex: 45,
            child: _buildMiddleColumn(),
          ),

          // ══════════════════════════════════════
          // CỘT PHẢI (35%) — Chi tiết Món Ăn
          // ══════════════════════════════════════
          Flexible(
            flex: 35,
            child: FoodDetailPanel(
              selectedItem: _selectedItem,
              onAddToCart: _selectedItem != null ? _onAddToCart : null,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // AppBar
  // ─────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.restaurant, color: AppColors.secondary, size: 22),
          const SizedBox(width: 10),
          const Text(
            'SEN VÀNG INDOCHINE — Thực Đơn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
        ],
      ),
      actions: [
        // Nút Import dữ liệu mẫu (chỉ dùng lần đầu)
        TextButton.icon(
          onPressed: _runSeeder,
          icon: const Icon(Icons.cloud_upload_outlined,
              color: AppColors.secondary, size: 18),
          label: const Text(
            'Import Data',
            style: TextStyle(color: AppColors.secondary, fontSize: 12),
          ),
        ),
        const SizedBox(width: 8),
        // Icon giỏ hàng (placeholder)
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.secondary),
          onPressed: () {},
          tooltip: 'Giỏ hàng',
        ),
        const SizedBox(width: 8),
      ],
      elevation: 3,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Cột Trái: StreamBuilder lấy categories
  // ─────────────────────────────────────────────────────────────
  Widget _buildLeftColumn() {
    return StreamBuilder<List<MenuCategory>>(
      stream: _repository.watchCategories(),
      builder: (context, snapshot) {
        // Trạng thái đang tải
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingColumn(message: 'Đang tải\ndanh mục...');
        }
        // Lỗi
        if (snapshot.hasError) {
          return _ErrorColumn(error: snapshot.error.toString());
        }
        // Dữ liệu rỗng
        final categories = snapshot.data ?? [];
        if (categories.isEmpty) {
          return const _EmptyColumn(message: 'Chưa có\ndanh mục');
        }

        // Tự động chọn category đầu tiên nếu chưa có lựa chọn
        if (_selectedCategory == null && categories.isNotEmpty) {
          // Dùng addPostFrameCallback để tránh setState trong build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _selectedCategory == null) {
              setState(() {
                _selectedCategory = categories.first;
              });
            }
          });
        }

        return CategoryListWidget(
          categories: categories,
          selectedCategoryId: _selectedCategory?.id ?? '',
          onCategorySelected: _onCategorySelected,
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Cột Giữa: StreamBuilder lấy món theo category đã chọn
  // ─────────────────────────────────────────────────────────────
  Widget _buildMiddleColumn() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF0F2F0), // Nền xanh xám nhẹ
        border: Border(
          left: BorderSide(color: Color(0xFFDDE0DD), width: 1),
          right: BorderSide(color: Color(0xFFDDE0DD), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header cột giữa
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.menu_book_outlined,
                    color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedCategory?.name ?? 'Chọn danh mục...',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFDDE0DD)),

          // Danh sách món ăn
          Expanded(
            child: _selectedCategory == null
                ? const Center(
                    child: Text(
                      'Chọn danh mục để xem món ăn',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  )
                : StreamBuilder<List<MenuItem>>(
                    stream: _repository
                        .watchItemsByCategory(_selectedCategory!.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Lỗi: ${snapshot.error}',
                              style: const TextStyle(color: Colors.red)),
                        );
                      }

                      final items = snapshot.data ?? [];
                      if (items.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.no_food_outlined,
                                  size: 40, color: Colors.grey),
                              SizedBox(height: 10),
                              Text(
                                'Danh mục này chưa có món',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return FoodCardWidget(
                            item: item,
                            isSelected: _selectedItem?.id == item.id,
                            onTap: () => _onItemSelected(item),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Chạy Database Seeder
  // ─────────────────────────────────────────────────────────────
  Future<void> _runSeeder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Import Dữ Liệu Mẫu'),
          ],
        ),
        content: const Text(
          'Thao tác này sẽ ghi toàn bộ dữ liệu thực đơn mẫu lên Firebase Firestore.\n\nBạn có muốn tiếp tục không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Hiển thị loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(height: 16),
                Text('Đang import dữ liệu...'),
              ],
            ),
          ),
        ),
      ),
    );

    final success = await DatabaseSeeder.seed();

    if (!mounted) return;
    Navigator.pop(context); // Đóng loading dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success ? AppColors.primary : Colors.red,
        content: Text(
          success
              ? '✅ Import dữ liệu thành công!'
              : '❌ Import thất bại. Kiểm tra kết nối Firebase.',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HELPER WIDGETS: Loading / Error / Empty cho cột trái
// ─────────────────────────────────────────────────────────────

class _LoadingColumn extends StatelessWidget {
  final String message;
  const _LoadingColumn({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.secondary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorColumn extends StatelessWidget {
  final String error;
  const _ErrorColumn({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 30),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyColumn extends StatelessWidget {
  final String message;
  const _EmptyColumn({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ),
    );
  }
}
