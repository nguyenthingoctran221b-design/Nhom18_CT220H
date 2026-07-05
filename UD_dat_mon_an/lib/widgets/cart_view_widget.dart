import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/cart_provider.dart';
import '../../models/order.dart';
import '../../services/order_repository.dart';

class CartViewWidget extends StatefulWidget {
  final String tableInfo;

  const CartViewWidget({super.key, required this.tableInfo});

  @override
  State<CartViewWidget> createState() => _CartViewWidgetState();
}

class _CartViewWidgetState extends State<CartViewWidget> {
  bool _isOrdering = false;

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(Icons.shopping_cart, color: AppColors.primary, size: 32),
              SizedBox(width: 12),
              Text(
                'Thực đơn gọi món',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),

          // Cart Items List
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.remove_shopping_cart_outlined, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Giỏ hàng đang trống',
                          style: TextStyle(color: Colors.grey[500], fontSize: 20),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final itemKey = cart.items.keys.toList()[index];
                      final cartItem = cart.items[itemKey]!;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // Item Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  cartItem.item.imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),

                              // Item Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cartItem.item.name,
                                      style: const TextStyle(
                                        fontFamily: 'Playfair Display',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _formatPrice(cartItem.item.price),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Quantity Controls
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      color: Colors.grey[700],
                                      onPressed: () {
                                        cart.updateQuantity(itemKey, cartItem.quantity - 1);
                                      },
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        '${cartItem.quantity}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      color: AppColors.primary,
                                      onPressed: () {
                                        cart.updateQuantity(itemKey, cartItem.quantity + 1);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              // Item total
                              SizedBox(
                                width: 120,
                                child: Text(
                                  _formatPrice(cartItem.totalPrice.toInt()),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Footer / Total
          const Divider(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng:',
                style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatPrice(cart.totalAmount.toInt()),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Order Button
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: (cart.items.isEmpty || _isOrdering)
                  ? null
                  : () => _placeOrder(cart),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isOrdering
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        color: AppColors.secondary,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      'Gọi món',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(CartProvider cart) async {
    setState(() {
      _isOrdering = true;
    });

    final order = OrderModel(
      tableInfo: widget.tableInfo,
      cartItems: cart.items.values.toList(),
      totalAmount: cart.totalAmount,
      createdAt: DateTime.now(),
    );

    final repo = OrderRepository();
    final success = await repo.placeOrder(order);

    setState(() {
      _isOrdering = false;
    });

    if (success) {
      cart.clearCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.primary,
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.secondary),
                SizedBox(width: 12),
                Text('Đặt món thành công! Vui lòng chờ phục vụ.'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: const Text('Có lỗi xảy ra khi đặt món. Vui lòng thử lại.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    }
  }

  String _formatPrice(int price) {
    final formatted = price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return '$formatted ₫';
  }
}
