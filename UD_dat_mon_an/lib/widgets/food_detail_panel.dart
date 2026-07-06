import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../core/models/menu_data.dart';

/// ============================================================
/// FOOD DETAIL PANEL — Cột Phải (35% màn hình)
/// ============================================================
/// Hiển thị thông tin chi tiết của món ăn được chọn.
/// Nếu chưa chọn món nào → hiển thị placeholder.
/// ============================================================
class FoodDetailPanel extends StatelessWidget {
  /// Món đang được chọn. Null = chưa chọn.
  final MenuItem? selectedItem;

  /// Callback khi nhấn "Thêm vào giỏ hàng".
  final VoidCallback? onAddToCart;

  const FoodDetailPanel({
    super.key,
    this.selectedItem,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          left: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: selectedItem == null
            ? _PlaceholderView(key: const ValueKey('placeholder'))
            : _DetailView(
                key: ValueKey(selectedItem!.id),
                item: selectedItem!,
                onAddToCart: onAddToCart,
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PRIVATE: Placeholder khi chưa chọn món
// ─────────────────────────────────────────────────────────────
class _PlaceholderView extends StatelessWidget {
  const _PlaceholderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.touch_app_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Vui lòng chọn món ăn',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              'để xem thông tin chi tiết',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PRIVATE: Chi tiết món ăn
// ─────────────────────────────────────────────────────────────
class _DetailView extends StatelessWidget {
  final MenuItem item;
  final VoidCallback? onAddToCart;

  const _DetailView({
    super.key,
    required this.item,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Ảnh lớn phía trên ──
        Flexible(
          flex: 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported,
                      size: 60, color: Colors.grey),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                },
              ),
              // Gradient overlay để đọc tên dễ hơn
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Tên món ăn đè lên ảnh
              Positioned(
                bottom: 12,
                left: 14,
                right: 14,
                child: Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    height: 1.35,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Thông tin chi tiết phía dưới ──
        Flexible(
          flex: 5,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Giá tiền
                Row(
                  children: [
                    const Icon(Icons.payments_outlined,
                        color: AppColors.secondary, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Giá tiền: ',
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _formatPrice(item.price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Mô tả
                const Row(
                  children: [
                    Icon(Icons.description_outlined,
                        color: AppColors.secondary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Mô tả chi tiết',
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Nguyên liệu — FilterChips
                const Row(
                  children: [
                    Icon(Icons.eco_outlined,
                        color: AppColors.secondary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Nguyên liệu',
                      style: TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.ingredients.map((ingredient) {
                    return FilterChip(
                      label: Text(
                        ingredient,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.primary),
                      ),
                      selected: false,
                      onSelected: (_) {},
                      backgroundColor: AppColors.primary.withValues(alpha: 0.07),
                      side: const BorderSide(
                          color: AppColors.primary, width: 0.8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 0),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),

        // ── Nút Thêm vào giỏ hàng ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onAddToCart,
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
              label: const Text(
                'Thêm vào giỏ hàng',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Format giá tiền theo định dạng Việt Nam: 189.000 ₫
  String _formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$formatted ₫';
  }
}
