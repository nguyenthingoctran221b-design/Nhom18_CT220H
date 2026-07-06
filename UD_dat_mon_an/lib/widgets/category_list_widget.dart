import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../core/models/menu_data.dart';

/// ============================================================
/// CATEGORY LIST WIDGET — Cột Trái (20% màn hình)
/// ============================================================
/// Hiển thị danh sách danh mục theo chiều dọc.
/// Highlight category đang được chọn với màu primary.
/// ============================================================
class CategoryListWidget extends StatelessWidget {
  final List<MenuCategory> categories;
  final String selectedCategoryId;
  final ValueChanged<MenuCategory> onCategorySelected;

  const CategoryListWidget({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        // Nền xanh đại ngàn đậm cho sidebar
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header của cột trái ──
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
            ),
            child: const Column(
              children: [
                Icon(Icons.restaurant_menu, color: AppColors.secondary, size: 32),
                SizedBox(height: 6),
                Text(
                  'THỰC ĐƠN',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white24, height: 1),

          // ── Danh sách Categories ──
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: categories.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: Colors.white12, height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                final category = categories[index];
                final bool isSelected = category.id == selectedCategoryId;

                return _CategoryTile(
                  category: category,
                  isSelected: isSelected,
                  onTap: () => onCategorySelected(category),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PRIVATE: Category Tile Item
// ─────────────────────────────────────────────────────────────
class _CategoryTile extends StatelessWidget {
  final MenuCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.secondary.withValues(alpha: 0.25)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(color: AppColors.secondary, width: 1.5)
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              // Chấm chỉ báo đang chọn
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.secondary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    color: isSelected ? AppColors.secondary : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.secondary,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
