import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';

class OrderItem {
  final String id;
  final String name;
  final int price;
  final int quantity;
  final double total;
  final int tfp;
  final String status; // 'pending', 'cooking', 'done'

  OrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.total,
    this.tfp = 10,
    this.status = 'pending',
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      price: map['price']?.toInt() ?? 0,
      quantity: map['quantity']?.toInt() ?? 0,
      total: map['total']?.toDouble() ?? 0.0,
      tfp: map['tfp']?.toInt() ?? 10,
      status: map['status'] ?? 'pending',
    );
  }
}

class OrderModel {
  final String? id;
  final String tableInfo;
  final List<CartItem> cartItems; // Items when placing order
  final List<OrderItem>? orderItems; // Items when fetching history
  final double totalAmount;
  final DateTime createdAt;
  final String status;

  OrderModel({
    this.id,
    required this.tableInfo,
    this.cartItems = const [],
    this.orderItems,
    required this.totalAmount,
    required this.createdAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      'tableInfo': tableInfo,
      'items': cartItems.map((cartItem) => {
        'id': cartItem.item.id,
        'name': cartItem.item.name,
        'price': cartItem.item.price,
        'quantity': cartItem.quantity,
        'total': cartItem.totalPrice,
        'tfp': cartItem.item.tfp,
        'status': 'pending',
      }).toList(),
      'totalAmount': totalAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      id: id,
      tableInfo: map['tableInfo'] ?? 'Unknown',
      orderItems: (map['items'] as List<dynamic>?)
          ?.map((itemMap) => OrderItem.fromMap(itemMap as Map<String, dynamic>))
          .toList() ?? [],
      totalAmount: map['totalAmount']?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: map['status'] ?? 'pending',
    );
  }
}
