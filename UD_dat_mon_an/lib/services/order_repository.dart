import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart';

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'orders';

  Future<bool> placeOrder(OrderModel order) async {
    try {
      await _firestore.collection(_collectionPath).add(order.toMap());
      
      final normalizedId = order.tableInfo.replaceAll('-', '');
      final tableRef = _firestore.collection('tables').doc(normalizedId);
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
        if (order.tableInfo.contains('-')) {
          final parts = order.tableInfo.split('-');
          area = parts.first;
          number = int.tryParse(parts.last) ?? 1;
        } else if (order.tableInfo.length >= 2) {
          area = order.tableInfo.substring(0, 1);
          number = int.tryParse(order.tableInfo.substring(1)) ?? 1;
        }
        await tableRef.set({
          'area': area,
          'number': number,
          'status': 'occupied',
          'entryTime': FieldValue.serverTimestamp(),
        });
      }
      
      return true;
    } catch (e) {
      print('Error placing order: $e');
      return false;
    }
  }


  Stream<List<OrderModel>> watchActiveOrders(String tableInfo) {
    final normalizedId = tableInfo.replaceAll('-', '');
    return _firestore
        .collection(_collectionPath)
        .where('tableInfo', isEqualTo: normalizedId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => OrderModel.fromMap(doc.id, doc.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
