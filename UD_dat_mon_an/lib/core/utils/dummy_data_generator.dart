import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../models/table_model.dart';
import '../models/menu_data.dart';
import 'vietnamese_menu_data.dart';

class DummyDataGenerator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> seedData() async {
    // 1. Seed Users
    await _seedUsers();
    
    // 2. Seed Tables
    await _seedTables();

    // 3. Seed Menu
    await _seedMenu();
  }

  static Future<void> _seedUsers() async {
    final usersCol = _firestore.collection('users');
    
    // Check if users exist
    final snapshot = await usersCol.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    // Create 40 customer accounts (A01-A20, B01-B20)
    for (String area in ['A', 'B']) {
      for (int i = 1; i <= 20; i++) {
        String id = '$area${i.toString().padLeft(2, '0')}';
        await usersCol.doc(id).set({
          'role': 'customer',
          'name': 'Bàn $id',
          'password': 'abc1', // In a real app, hash passwords
        });
      }
    }

    // Cashiers
    await usersCol.doc('cashier1').set({'role': 'cashier', 'name': 'Thu ngân 1', 'password': '123'});
    await usersCol.doc('cashier2').set({'role': 'cashier', 'name': 'Thu ngân 2', 'password': '123'});

    // Chefs
    await usersCol.doc('chef1').set({'role': 'chef', 'name': 'Bếp trưởng', 'password': '123'});
    await usersCol.doc('chef2').set({'role': 'chef', 'name': 'Bếp phó', 'password': '123'});

    // Manager
    await usersCol.doc('manager1').set({'role': 'manager', 'name': 'Quản lý', 'password': 'admin'});
  }

  static Future<void> _seedTables() async {
    final tablesCol = _firestore.collection('tables');
    
    final snapshot = await tablesCol.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    for (String area in ['A', 'B', 'C']) {
      for (int i = 1; i <= 20; i++) {
        String id = '$area${i.toString().padLeft(2, '0')}';
        final table = TableModel(id: id, area: area, number: i);
        await tablesCol.doc(id).set(table.toMap());
      }
    }
  }

  static Future<void> _seedMenu() async {
    final menuCol = _firestore.collection('menu');
    final categoriesCol = _firestore.collection('categories');

    // Check if we already have the new Vietnamese menu seeded
    final checkSnapshot = await menuCol.where('name', isEqualTo: 'Lẩu Riêu Cua Sườn Sụn').get();
    if (checkSnapshot.docs.isNotEmpty) {
      print('🌱 [DummyDataGenerator] New Vietnamese menu is already seeded.');
      return;
    }

    print('🌱 [DummyDataGenerator] Overwriting old menu with new Vietnamese menu...');

    // 1. Delete all existing items in 'menu' collection
    final menuSnapshot = await menuCol.get();
    for (var doc in menuSnapshot.docs) {
      await doc.reference.delete();
    }

    // 2. Delete all existing categories in 'categories' collection
    final categoriesSnapshot = await categoriesCol.get();
    for (var doc in categoriesSnapshot.docs) {
      await doc.reference.delete();
    }

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
      await categoriesCol.doc(spec['id'] as String).set({
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

        final menuItem = MenuItem(
          id: id,
          name: name,
          price: price,
          description: description,
          ingredients: ingredients,
          imageUrl: imageUrl,
          isAvailable: true,
          tfp: tfp,
          category: categoryName,
        );

        await menuCol.doc(id).set(menuItem.toMap());
      }
    }

    print('🌱 [DummyDataGenerator] New Vietnamese menu successfully seeded!');
  }
}
