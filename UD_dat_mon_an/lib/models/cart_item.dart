import '../core/models/menu_data.dart';

class CartItem {
  final MenuItem item;
  int quantity;

  CartItem({
    required this.item,
    this.quantity = 1,
  });

  double get totalPrice => item.price * quantity.toDouble();
}
