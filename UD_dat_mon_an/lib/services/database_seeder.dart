import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/vietnamese_menu_data.dart';

/// ============================================================
/// DATABASE SEEDER
/// ============================================================
/// Chịu trách nhiệm đẩy toàn bộ dữ liệu thực đơn mẫu lên
/// Firebase Firestore theo cấu trúc:
///
///   /categories/{categoryId}        → thông tin danh mục
///   /menu_items/{itemId}            → thông tin món ăn (có trường category_id)
///
/// Cách dùng: gọi DatabaseSeeder.seed() một lần duy nhất
/// (ví dụ sau khi nhấn nút trên màn hình Admin).
/// ============================================================
class DatabaseSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Dữ liệu thực đơn đầy đủ theo cấu trúc JSON gốc.
  static final List<Map<String, dynamic>> _menuData = [
    {
      "category_id": "cat_lau",
      "category_name": "Nước Lẩu (Broth)",
      "sort_order": 1,
      "items": [
        {
          "id": "lau_01",
          "name": "Nước Lẩu Riêu Cua Đồng Đặc Sánh",
          "price": 189000,
          "description":
              "Nước lẩu vị thanh chua nhẹ từ giấm bỗng nếp, thơm nồng hương hành phi và béo ngậy từ gạch cua đồng tự nhiên.",
          "ingredients": [
            "Cua đồng giã nhỏ",
            "Giấm bỗng nếp",
            "Cà chua",
            "Hành tăm phi",
            "Mẻ",
          ],
          "image_url":
              "https://images.unsplash.com/photo-1626700051175-6518c4793f4f?w=500",
          "is_available": true,
        },
        {
          "id": "lau_02",
          "name": "Nước Lẩu Gà Lá É Phú Yên",
          "price": 179000,
          "description":
              "Vị ngọt đậm đà từ nước cốt xương gà hòa quyện cùng vị cay nồng ấm đặc trưng của lá é trắng và ớt xiêm xanh.",
          "ingredients": [
            "Nước cốt xương gà",
            "Lá é trắng",
            "Ớt xiêm xanh",
            "Măng chua",
            "Nấm bào ngư",
          ],
          "image_url":
              "https://images.unsplash.com/photo-1547928576-a4a33237ecd3?w=500",
          "is_available": true,
        },
      ],
    },
    {
      "category_id": "cat_nhung",
      "category_name": "Đồ Nhúng Lẩu (Hotpot Toppings)",
      "sort_order": 2,
      "items": [
        {
          "id": "nhung_01",
          "name": "Bắp Bò Tươi Hoa Nhúng Lẩu",
          "price": 155000,
          "description":
              "Thịt bắp bò tươi thái mỏng, có các vân gân xen kẽ, khi nhúng giữ được độ giòn sần sật và vị ngọt tự nhiên.",
          "ingredients": ["100% Thịt bắp hoa bò Việt tươi"],
          "image_url":
              "https://images.unsplash.com/photo-1551028372-e93b48227b3b?w=500",
          "is_available": true,
        },
        {
          "id": "nhung_02",
          "name": "Mọc Cua Biển Ngon Ngậy",
          "price": 125000,
          "description":
              "Mọc tự chế biến từ thịt heo loại một trộn lẫn thịt cua biển tươi, nêm nếm gia vị vừa vặn, viên tròn thả lẩu.",
          "ingredients": [
            "Thịt cua biển",
            "Giò sống",
            "Mộc nhĩ",
            "Tiêu sọ Phú Quốc",
          ],
          "image_url":
              "https://images.unsplash.com/photo-1582450871972-ab5ca641643d?w=500",
          "is_available": true,
        },
      ],
    },
    {
      "category_id": "cat_cuon",
      "category_name": "Món Cuốn Khai Vị (Vietnamese Rolls)",
      "sort_order": 3,
      "items": [
        {
          "id": "cuon_01",
          "name": "Bánh Tráng Cuốn Thịt Heo Tộc",
          "price": 149000,
          "description":
              "Món ăn đặc sản miền Trung với thịt heo luộc khéo léo lấy được hai đầu da, cuốn kèm rau rừng và chấm mắm nêm đậm đà.",
          "ingredients": [
            "Thịt heo luộc",
            "Bánh tráng phơi sương",
            "Bánh phở",
            "Rau thơm rừng",
            "Dưa chuột",
            "Chuối chát",
            "Mắm nêm",
          ],
          "image_url":
              "https://images.unsplash.com/photo-1529563021463-5499298455ca?w=500",
          "is_available": true,
        },
        {
          "id": "cuon_02",
          "name": "Gỏi Cuốn Tôm Thịt Sài Gòn (4 Cuốn)",
          "price": 85000,
          "description":
              "Món ăn thanh mát với tôm luộc đỏ au, thịt ba chỉ, bún tươi và hẹ, chấm cùng tương đậu phộng bùi béo.",
          "ingredients": [
            "Tôm thẻ luộc",
            "Thịt ba chỉ",
            "Bún tươi",
            "Rau hẹ",
            "Xà lách",
            "Tương đen đậu phộng",
          ],
          "image_url":
              "https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?w=500",
          "is_available": true,
        },
      ],
    },
    {
      "category_id": "cat_chinh",
      "category_name": "Món Chính Đặc Sắc (Main Dishes)",
      "sort_order": 4,
      "items": [
        {
          "id": "chinh_01",
          "name": "Cơm Chiên Trái Thơm Hải Sản",
          "price": 135000,
          "description":
              "Cơm chiên hạt tơi xốp, vàng ruộm quyện cùng tôm, mực tươi và hạt sen bùi bùi, được trình bày bắt mắt bên trong trái thơm khoét rỗng.",
          "ingredients": [
            "Cơm nguội",
            "Tôm tươi",
            "Mực ống",
            "Hạt sen",
            "Trái thơm",
            "Hành lá",
            "Trứng gà",
          ],
          "image_url":
              "https://images.unsplash.com/photo-1600891964599-f61ba0e24092?w=500",
          "is_available": true,
        },
        {
          "id": "chinh_02",
          "name": "Mẹt Gà Cánh Tiên Lên Mâm (Nửa con)",
          "price": 245000,
          "description":
              "Gà ta thả vườn thịt chắc ngọt được chế biến thành các vị: Gà hấp lá chanh, gà chiên mắm và lòng mề xào, ăn kèm xôi nếp nương cốt dừa.",
          "ingredients": [
            "Gà ta đi bộ",
            "Lá chanh",
            "Xôi nếp nương",
            "Nước mắm Phú Quốc",
            "Cốt dừa",
          ],
          "image_url":
              "https://images.unsplash.com/photo-1565557623262-b51c2513a641?w=500",
          "is_available": true,
        },
      ],
    },
    {
      "category_id": "cat_rau",
      "category_name": "Rau & Nấm Sạch (Veggies & Mushrooms)",
      "sort_order": 5,
      "items": [
        {
          "id": "rau_01",
          "name": "Mẹt Rau Đồng Quê (Tổng hợp)",
          "price": 65000,
          "description":
              "Sự kết hợp hoàn hảo các loại rau bản địa Việt Nam, rất hợp khi ăn kèm với lẩu riêu cua.",
          "ingredients": [
            "Rau muống chẻ",
            "Hoa chuối thái mỏng",
            "Mồng tơi",
            "Rau má",
            "Xà lách",
          ],
          "image_url":
              "https://images.unsplash.com/photo-1540420773420-3366772f4999?w=500",
          "is_available": true,
        },
      ],
    },
    {
      "category_id": "cat_trangmieng",
      "category_name": "Món Tráng Miệng (Desserts)",
      "sort_order": 6,
      "items": [
        {
          "id": "tm_01",
          "name": "Chè Ba Màu Sương Sa Hạt Lựu",
          "price": 45000,
          "description":
              "Món chè giải nhiệt truyền thống với sự kết hợp của đậu xanh đánh mịn, thạch sương sa giòn sần sật, hạt lựu dẻo bùi và nước cốt dừa béo ngậy.",
          "ingredients": [
            "Đậu xanh",
            "Sương sa",
            "Hạt lựu làm từ củ năng",
            "Nước cốt dừa",
            "Lá dứa tạo màu",
          ],
          "image_url":
              "https://images.unsplash.com/photo-1563729784474-d77dbb933a9e?w=500",
          "is_available": true,
        },
        {
          "id": "tm_02",
          "name": "Bánh Flan Nước Cốt Dừa Cà Phê",
          "price": 35000,
          "description":
              "Bánh flan mềm mịn, tan ngay trong miệng, kết hợp giữa vị đắng nhẹ của cà phê phin Việt Nam và vị béo đặc trưng của nước cốt dừa xứ Dừa.",
          "ingredients": [
            "Trứng gà",
            "Sữa tươi",
            "Cà phê phin",
            "Nước cốt dừa",
            "Caramel",
          ],
          "image_url":
              "https://images.unsplash.com/photo-1511018556340-d16986a1c194?w=500",
          "is_available": true,
        },
      ],
    },
    {
      "category_id": "cat_nuoc",
      "category_name": "Đồ Uống Giải Nhiệt (Beverages)",
      "sort_order": 7,
      "items": [
        {
          "id": "nuoc_01",
          "name": "Trà Măng Cụt Hoa Atiso Đỏ",
          "price": 49000,
          "description":
              "Sự kết hợp hiện đại giữa vị chua thanh của hoa Atiso đỏ (Hibiscus) và vị ngọt thanh, thơm dịu của những múi măng cụt tươi.",
          "ingredients": [
            "Hoa Atiso đỏ ngâm",
            "Măng cụt tươi",
            "Nước cốt chanh",
            "Đường phèn",
          ],
          "image_url":
              "https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=500",
          "is_available": true,
        },
        {
          "id": "nuoc_02",
          "name": "Nước Ép Cóc Bao Tử Muối Ớt",
          "price": 42000,
          "description":
              "Nước ép nguyên chất từ những trái cóc bao tử xanh mướt, vị chua giòn sảng khoái, viền miệng ly được phủ một lớp muối ớt cay mặn.",
          "ingredients": [
            "Cóc bao tử tươi",
            "Muối ớt Tây Ninh",
            "Đường nước",
          ],
          "image_url":
              "https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=500",
          "is_available": true,
        },
      ],
    },
  ];

  // ─────────────────────────────────────────────────────────────
  // PUBLIC METHOD: seed()
  // ─────────────────────────────────────────────────────────────

  /// Đẩy toàn bộ dữ liệu thực đơn lên Firestore.
  /// Sử dụng WriteBatch để tối ưu số lần gọi network.
  /// Trả về [true] nếu thành công, [false] nếu có lỗi.
  static Future<bool> seed() async {
    try {
      debugPrint('🌱 [DatabaseSeeder] Bắt đầu import dữ liệu...');

      // 1. Delete all existing items in 'menu' collection
      final menuSnapshot = await _db.collection('menu').get();
      for (var doc in menuSnapshot.docs) {
        await doc.reference.delete();
      }

      // 2. Delete all existing categories in 'categories' collection
      final categoriesSnapshot = await _db.collection('categories').get();
      for (var doc in categoriesSnapshot.docs) {
        await doc.reference.delete();
      }

      final WriteBatch batch = _db.batch();

      // 3. Seed 'categories' collection with correct IDs and display names
      final categorySpecs = [
        {"id": "cat_lau", "name": "Nước Lẩu", "sort_order": 1, "icon": "soup"},
        {"id": "cat_nhung", "name": "Đồ Nhúng Lẩu", "sort_order": 2, "icon": "beef"},
        {"id": "cat_khaivi", "name": "Món Khai Vị", "sort_order": 3, "icon": "utensils"},
        {"id": "cat_cuon", "name": "Món Cuốn", "sort_order": 4, "icon": "utensils"},
        {"id": "cat_trangmieng", "name": "Món Tráng Miệng", "sort_order": 5, "icon": "ice-cream"},
        {"id": "cat_douong", "name": "Đồ Uống", "sort_order": 6, "icon": "cup-soda"},
      ];

      for (var spec in categorySpecs) {
        final categoryRef = _db.collection('categories').doc(spec['id'] as String);
        batch.set(categoryRef, {
          'name': spec['name'],
          'sort_order': spec['sort_order'],
          'icon': spec['icon'],
        });
      }

      // 4. Seed 'menu' collection with items from vietnameseMenuData
      final Map<String, String> categoryNames = {
        "cat_lau": "Nước Lẩu",
        "cat_nhung": "Đồ Nhúng Lẩu",
        "cat_khaivi": "Món Khai Vị",
        "cat_cuon": "Món Cuốn",
        "cat_trangmieng": "Món Tráng Miệng",
        "cat_douong": "Đồ Uống"
      };

      int itemCounter = 1;
      int totalItems = 0;
      for (var entry in vietnameseMenuData.entries) {
        final categoryId = entry.key;
        final items = entry.value;
        final categoryName = categoryNames[categoryId] ?? "Khác";

        for (var item in items) {
          final name = item['name'] as String;
          final description = item['description'] as String;
          final price = item['price'] as int;
          final imageUrl = item['image'] as String;
          final ingredientsStr = item['ingredients'] as String;

          // Split ingredients by comma
          final List<String> ingredients = ingredientsStr
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

          // Assign preparation time (TFP)
          int tfp = 10;
          if (categoryId == 'cat_lau' || categoryId == 'cat_douong') {
            tfp = 5;
          } else if (categoryId == 'cat_khaivi' || categoryId == 'cat_cuon') {
            tfp = 10;
          } else if (categoryId == 'cat_trangmieng') {
            tfp = 8;
          } else {
            tfp = 15;
          }

          // Generate a unique ID for the item, e.g. lau_01, nhung_02, etc.
          final prefix = categoryId.replaceAll('cat_', '');
          final id = '${prefix}_${itemCounter.toString().padLeft(2, '0')}';
          itemCounter++;
          totalItems++;

          final itemRef = _db.collection('menu').doc(id);
          batch.set(itemRef, {
            'name': name,
            'price': price,
            'description': description,
            'ingredients': ingredients,
            'imageUrl': imageUrl,
            'isAvailable': true,
            'tfp': tfp,
            'category': categoryName,
          });
        }
      }

      // Commit toàn bộ batch một lần
      await batch.commit();

      debugPrint(
        '✅ [DatabaseSeeder] Import thành công! '
        '${categorySpecs.length} categories và '
        '$totalItems món ăn.',
      );
      return true;
    } catch (e) {
      debugPrint('❌ [DatabaseSeeder] Lỗi: $e');
      return false;
    }
  }
}
