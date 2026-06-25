import 'package:cloud_firestore/cloud_firestore.dart';

/// Model đại diện cho một món ăn trong thực đơn.
class MenuItem {
  final String id;
  final String name;
  final int price;
  final String description;
  final List<String> ingredients;
  final String imageUrl;
  final bool isAvailable;
  final String categoryId; // Tham chiếu đến category cha

  const MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.ingredients,
    required this.imageUrl,
    required this.isAvailable,
    required this.categoryId,
  });

  /// Chuyển từ Firestore DocumentSnapshot sang MenuItem.
  factory MenuItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MenuItem(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toInt(),
      description: data['description'] ?? '',
      ingredients: List<String>.from(data['ingredients'] ?? []),
      imageUrl: data['image_url'] ?? '',
      isAvailable: data['is_available'] ?? true,
      categoryId: data['category_id'] ?? '',
    );
  }

  /// Chuyển MenuItem sang Map để lưu lên Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'description': description,
      'ingredients': ingredients,
      'image_url': imageUrl,
      'is_available': isAvailable,
      'category_id': categoryId,
    };
  }
}
