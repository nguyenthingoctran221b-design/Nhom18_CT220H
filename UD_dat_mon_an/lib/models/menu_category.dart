import 'package:cloud_firestore/cloud_firestore.dart';

/// Model đại diện cho một danh mục (category) trong thực đơn.
class MenuCategory {
  final String id;
  final String name;
  final int sortOrder; // Thứ tự hiển thị trong danh sách

  const MenuCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  /// Chuyển từ Firestore DocumentSnapshot sang MenuCategory.
  factory MenuCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MenuCategory(
      id: doc.id,
      name: data['name'] ?? '',
      sortOrder: (data['sort_order'] ?? 0).toInt(),
    );
  }

  /// Chuyển MenuCategory sang Map để lưu lên Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'sort_order': sortOrder,
    };
  }
}
