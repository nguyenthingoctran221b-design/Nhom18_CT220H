import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../core/models/menu_data.dart';

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;
  
  int get totalQuantity {
    int total = 0;
    _items.forEach((key, cartItem) {
      total += cartItem.quantity;
    });
    return total;
  }

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.item.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(MenuItem item, {int quantity = 1}) {
    if (_items.containsKey(item.id)) {
      _items.update(
        item.id,
        (existingCartItem) => CartItem(
          item: existingCartItem.item,
          quantity: existingCartItem.quantity + quantity,
        ),
      );
    } else {
      _items.putIfAbsent(
        item.id,
        () => CartItem(item: item, quantity: quantity),
      );
    }
    notifyListeners();
  }

  void removeItem(String itemId) {
    _items.remove(itemId);
    notifyListeners();
  }

  void updateQuantity(String itemId, int quantity) {
    if (_items.containsKey(itemId)) {
      if (quantity > 0) {
        _items.update(
          itemId,
          (existingCartItem) => CartItem(
            item: existingCartItem.item,
            quantity: quantity,
          ),
        );
      } else {
        _items.remove(itemId);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
