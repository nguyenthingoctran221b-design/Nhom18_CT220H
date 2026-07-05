import 'package:cloud_firestore/cloud_firestore.dart';

/// Model cho một món ăn
class MenuItem {
  final String id;
  final String name;
  final int price;
  final String description;
  final List<String> ingredients;
  final String imageUrl;
  final bool isAvailable;
  final int tfp; // Time For Preparation in minutes
  final String category; // Category name

  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.ingredients,
    required this.imageUrl,
    this.isAvailable = true,
    this.tfp = 10,
    this.category = 'Khác',
  });

  factory MenuItem.fromMap(String id, Map<String, dynamic> map) {
    return MenuItem(
      id: id,
      name: map['name'] ?? '',
      price: map['price']?.toInt() ?? 0,
      description: map['description'] ?? '',
      ingredients: List<String>.from(map['ingredients'] ?? []),
      imageUrl: map['imageUrl'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      tfp: map['tfp']?.toInt() ?? 10,
      category: map['category'] ?? 'Khác',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'ingredients': ingredients,
      'imageUrl': imageUrl,
      'isAvailable': isAvailable,
      'tfp': tfp,
      'category': category,
    };
  }
}

/// Model cho một danh mục món
class MenuCategory {
  final String id;
  final String category;
  final String icon;
  final List<MenuItem> items;

  const MenuCategory({
    required this.id,
    required this.category,
    required this.icon,
    required this.items,
  });

  factory MenuCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MenuCategory(
      id: doc.id,
      category: data['name'] ?? '',
      icon: data['icon'] ?? 'category',
      items: [], // Items are fetched separately in this model
    );
  }

  String get name => category;

  /// Trả về tên ngắn (phần trước dấu ngoặc)
  String get shortName => category.split('(').first.trim();
}

/// Dữ liệu menu mẫu (chuyển đổi từ JSON trong HTML)
final List<MenuCategory> menuData = [
  MenuCategory(
    id: "cat_lau",
    category: "Nước Lẩu (Broth)",
    icon: "soup",
    items: [
      MenuItem(
        id: "lau_01",
        name: "Nước Lẩu Riêu Cua Đồng Đặc Sánh",
        price: 189000,
        description:
            "Nước lẩu vị thanh chua nhẹ từ giấm bỗng nếp, thơm nồng hương hành phi và béo ngậy từ gạch cua đồng tự nhiên.",
        ingredients: [
          "Cua đồng giã nhỏ",
          "Giấm bỗng nếp",
          "Cà chua",
          "Hành tăm phi",
          "Mẻ"
        ],
        imageUrl:
            "https://images.unsplash.com/photo-1626700051175-6518c4793f4f?w=600&q=80",
        isAvailable: true,
      ),
      MenuItem(
        id: "lau_02",
        name: "Nước Lẩu Gà Lá É Phú Yên",
        price: 179000,
        description:
            "Vị ngọt đậm đà từ nước cốt xương gà hòa quyện cùng vị cay nồng ấm đặc trưng của lá é trắng và ớt xiêm xanh.",
        ingredients: [
          "Nước cốt xương gà",
          "Lá é trắng",
          "Ớt xiêm xanh",
          "Măng chua",
          "Nấm bào ngư"
        ],
        imageUrl:
            "https://images.unsplash.com/photo-1547928576-a4a33237ecd3?w=600&q=80",
        isAvailable: true,
      ),
    ],
  ),
  MenuCategory(
    id: "cat_nhung",
    category: "Đồ Nhúng Lẩu (Toppings)",
    icon: "beef",
    items: [
      MenuItem(
        id: "nhung_01",
        name: "Bắp Bò Tươi Hoa Nhúng Lẩu",
        price: 155000,
        description:
            "Thịt bắp bò tươi thái mỏng, có các vân gân xen kẽ, khi nhúng giữ được độ giòn sần sật và vị ngọt tự nhiên.",
        ingredients: ["100% Thịt bắp hoa bò Việt tươi"],
        imageUrl:
            "https://images.unsplash.com/photo-1551028372-e93b48227b3b?w=600&q=80",
        isAvailable: true,
      ),
      MenuItem(
        id: "nhung_02",
        name: "Mọc Cua Biển Ngon Ngậy",
        price: 125000,
        description:
            "Mọc tự chế biến từ thịt heo loại một trộn lẫn thịt cua biển tươi, nêm nếm gia vị vừa vặn, viên tròn thả lẩu.",
        ingredients: [
          "Thịt cua biển",
          "Giò sống",
          "Mộc nhĩ",
          "Tiêu sọ Phú Quốc"
        ],
        imageUrl:
            "https://images.unsplash.com/photo-1582450871972-ab5ca641643d?w=600&q=80",
        isAvailable: true,
      ),
    ],
  ),
  MenuCategory(
    id: "cat_cuon",
    category: "Món Cuốn Khai Vị",
    icon: "utensils",
    items: [
      MenuItem(
        id: "cuon_01",
        name: "Bánh Tráng Cuốn Thịt Heo Tộc",
        price: 149000,
        description:
            "Món ăn đặc sản miền Trung với thịt heo luộc khéo léo lấy được hai đầu da, cuốn kèm rau rừng và chấm mắm nêm đậm đà.",
        ingredients: [
          "Thịt heo luộc",
          "Bánh tráng phơi sương",
          "Bánh phở",
          "Rau thơm rừng",
          "Mắm nêm"
        ],
        imageUrl:
            "https://images.unsplash.com/photo-1529563021463-5499298455ca?w=600&q=80",
        isAvailable: true,
      ),
      MenuItem(
        id: "cuon_02",
        name: "Gỏi Cuốn Tôm Thịt Sài Gòn",
        price: 85000,
        description:
            "Món ăn thanh mát với tôm luộc đỏ au, thịt ba chỉ, bún tươi và hẹ, chấm cùng tương đậu phộng bùi béo.",
        ingredients: [
          "Tôm thẻ luộc",
          "Thịt ba chỉ",
          "Bún tươi",
          "Rau hẹ",
          "Tương đen đậu phộng"
        ],
        imageUrl:
            "https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?w=600&q=80",
        isAvailable: true,
      ),
    ],
  ),
  MenuCategory(
    id: "cat_chinh",
    category: "Món Chính Đặc Sắc",
    icon: "chef-hat",
    items: [
      MenuItem(
        id: "chinh_01",
        name: "Cơm Chiên Trái Thơm Hải Sản",
        price: 135000,
        description:
            "Cơm chiên hạt tơi xốp, vàng ruộm quyện cùng tôm, mực tươi và hạt sen bùi bùi, được trình bày bắt mắt bên trong trái thơm khoét rỗng.",
        ingredients: [
          "Cơm nguội",
          "Tôm tươi",
          "Mực ống",
          "Hạt sen",
          "Trái thơm"
        ],
        imageUrl:
            "https://images.unsplash.com/photo-1600891964599-f61ba0e24092?w=600&q=80",
        isAvailable: true,
      ),
    ],
  ),
  MenuCategory(
    id: "cat_tm",
    category: "Món Tráng Miệng",
    icon: "ice-cream",
    items: [
      MenuItem(
        id: "tm_01",
        name: "Chè Ba Màu Sương Sa",
        price: 45000,
        description:
            "Món chè giải nhiệt truyền thống với sự kết hợp của đậu xanh đánh mịn, thạch sương sa giòn sần sật, hạt lựu dẻo bùi và nước cốt dừa béo ngậy.",
        ingredients: [
          "Đậu xanh",
          "Sương sa",
          "Hạt lựu củ năng",
          "Nước cốt dừa"
        ],
        imageUrl:
            "https://images.unsplash.com/photo-1563729784474-d77dbb933a9e?w=600&q=80",
        isAvailable: true,
      ),
    ],
  ),
  MenuCategory(
    id: "cat_nuoc",
    category: "Đồ Uống Giải Nhiệt",
    icon: "cup-soda",
    items: [
      MenuItem(
        id: "nuoc_01",
        name: "Trà Măng Cụt Hoa Atiso",
        price: 49000,
        description:
            "Sự kết hợp hiện đại giữa vị chua thanh của hoa Atiso đỏ và vị ngọt thanh của măng cụt.",
        ingredients: ["Hoa Atiso đỏ", "Măng cụt tươi", "Chanh"],
        imageUrl:
            "https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?w=600&q=80",
        isAvailable: true,
      ),
    ],
  ),
];
