import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'orders';

  Future<bool> placeOrder(OrderModel order) async {
    try {
      await _firestore.collection(_collectionPath).add(order.toMap());
      return true;
    } catch (e) {
      print('Error placing order: $e');
      return false;
    }
  }

  Stream<List<OrderModel>> watchOrders(String tableInfo) {
    return _firestore
        .collection(_collectionPath)
        .where('tableInfo', isEqualTo: tableInfo)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => OrderModel.fromMap(doc.id, doc.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
