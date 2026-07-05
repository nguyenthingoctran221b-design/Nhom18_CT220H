import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/menu_data.dart';

/// ============================================================
/// MENU REPOSITORY
/// ============================================================
/// Tách biệt hoàn toàn logic truy vấn Firebase khỏi UI.
/// Cung cấp các Stream để UI lắng nghe real-time updates.
/// ============================================================
class MenuRepository {
  final FirebaseFirestore _db;

  MenuRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────────────────
  // CATEGORIES
  // ─────────────────────────────────────────────────────────────

  /// Stream trả về danh sách tất cả categories, sắp xếp theo sort_order.
  Stream<List<MenuCategory>> watchCategories() {
    return _db
        .collection('categories')
        .orderBy('sort_order')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MenuCategory.fromFirestore(doc))
              .toList(),
        );
  }

  // ─────────────────────────────────────────────────────────────
  // MENU ITEMS
  // ─────────────────────────────────────────────────────────────

  /// Stream trả về danh sách các món thuộc một category cụ thể.
  /// [categoryId]: ID của category cần lọc.
  Stream<List<MenuItem>> watchItemsByCategory(String categoryId) {
    String categoryName = categoryId;
    switch (categoryId) {
      case 'cat_lau':
        categoryName = 'Nước Lẩu';
        break;
      case 'cat_nhung':
        categoryName = 'Đồ Nhúng Lẩu';
        break;
      case 'cat_khaivi':
        categoryName = 'Món Khai Vị';
        break;
      case 'cat_cuon':
        categoryName = 'Món Cuốn';
        break;
      case 'cat_trangmieng':
        categoryName = 'Món Tráng Miệng';
        break;
      case 'cat_douong':
        categoryName = 'Đồ Uống';
        break;
    }

    return _db
        .collection('menu')
        .where('category', isEqualTo: categoryName)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MenuItem.fromMap(doc.id, doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  /// Future lấy thông tin chi tiết một món theo ID.
  /// Dùng khi chỉ cần đọc một lần (không cần real-time).
  Future<MenuItem?> fetchItemById(String itemId) async {
    final doc = await _db.collection('menu').doc(itemId).get();
    if (!doc.exists) return null;
    return MenuItem.fromMap(doc.id, doc.data()!);
  }
}
