import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/table_model.dart';
import '../models/menu_data.dart';

class DummyDataGenerator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> seedData() async {
    // 1. Seed Users
    await _seedUsers();
    
    // 2. Seed Tables
    await _seedTables();

    // 3. Seed Menu
    await _seedMenu();

    // 4. Seed Real Invoices (historical data for graphs)
    await seedRealInvoicesToDatabase();
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
          'password': 'abc1', 
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
    
    final snapshot = await menuCol.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    for (var category in menuData) {
      for (var item in category.items) {
        int tfp = 10;
        if (category.icon == 'soup' || category.icon == 'cup-soda') tfp = 5;
        if (category.icon == 'chef-hat') tfp = 20;

        final menuItem = MenuItem(
          id: item.id,
          name: item.name,
          price: item.price,
          description: item.description,
          ingredients: item.ingredients,
          imageUrl: item.imageUrl,
          isAvailable: item.isAvailable,
          tfp: tfp,
          category: category.category,
        );

        await menuCol.doc(item.id).set(menuItem.toMap());
      }
    }
  }

  static Future<void> seedRealInvoicesToDatabase() async {
    final invoicesCol = _firestore.collection('invoices');

    // Check if we already have sufficient invoices
    final snapshot = await invoicesCol.limit(15).get();
    if (snapshot.docs.length >= 15) return;

    // Get list of dishes from Firestore menu collection (or fallback if empty)
    final menuSnapshot = await _firestore.collection('menu').get();
    List<Map<String, dynamic>> dishes = [];

    if (menuSnapshot.docs.isNotEmpty) {
      for (var doc in menuSnapshot.docs) {
        dishes.add({
          'name': doc['name'],
          'price': doc['price'],
        });
      }
    } else {
      // Fallback standard dishes
      dishes = [
        {'name': 'Nước Lẩu Riêu Cua Đồng', 'price': 189000},
        {'name': 'Bắp Bò Tươi Hoa Nhúng Lẩu', 'price': 155000},
        {'name': 'Mọc Cua Biển Ngon Ngậy', 'price': 125000},
        {'name': 'Bánh Tráng Cuốn Thịt Heo Tộc', 'price': 149000},
        {'name': 'Gỏi Cuốn Tôm Thịt Sài Gòn', 'price': 85000},
        {'name': 'Cơm Chiên Trái Thơm Hải Sản', 'price': 135000},
        {'name': 'Chè Ba Màu Sương Sa', 'price': 45000},
        {'name': 'Trà Măng Cụt Atiso Đỏ', 'price': 49000},
      ];
    }

    final random = Random();
    final tables = ['A01', 'A02', 'A03', 'A04', 'A05', 'B01', 'B02', 'B03', 'B04', 'C01', 'C02'];
    final paymentMethods = ['cash', 'ewallet', 'bank'];

    // We want to generate historical revenue for two months: June 2026 (last month) and July 2026 (this month)
    final int currentYear = 2026; // Match project baseline year
    final int lastMonth = 6;
    final int thisMonth = 7;

    final List<Map<String, dynamic>> generatedInvoices = [];

    // 1. Generate 25 invoices for June 2026 (last month) distributed across 30 days
    for (int i = 0; i < 25; i++) {
      final day = random.nextInt(30) + 1;
      final hour = random.nextInt(12) + 10; // 10:00 to 22:00
      final minute = random.nextInt(60);

      final checkoutTime = DateTime(currentYear, lastMonth, day, hour, minute);
      final startedTime = checkoutTime.subtract(Duration(minutes: random.nextInt(60) + 40));

      final invoice = _createRandomInvoice(random, tables, dishes, paymentMethods, checkoutTime, startedTime);
      generatedInvoices.add(invoice);
    }

    // 2. Generate 25 invoices for July 2026 (this month) distributed across days 1 to 6 (current time)
    for (int i = 0; i < 25; i++) {
      // Assuming today is July 6, distribute randomly from July 1 to July 6
      final day = random.nextInt(6) + 1;
      final hour = random.nextInt(12) + 10; // 10:00 to 22:00
      final minute = random.nextInt(60);

      final checkoutTime = DateTime(currentYear, thisMonth, day, hour, minute);
      final startedTime = checkoutTime.subtract(Duration(minutes: random.nextInt(60) + 40));

      final invoice = _createRandomInvoice(random, tables, dishes, paymentMethods, checkoutTime, startedTime);
      generatedInvoices.add(invoice);
    }

    // Write all to Firestore using batch
    final WriteBatch batch = _firestore.batch();
    for (var inv in generatedInvoices) {
      final docRef = invoicesCol.doc(); // Auto-generated ID
      batch.set(docRef, inv);
    }

    await batch.commit();
  }

  static Map<String, dynamic> _createRandomInvoice(
    Random random,
    List<String> tables,
    List<Map<String, dynamic>> dishes,
    List<String> paymentMethods,
    DateTime checkoutTime,
    DateTime startedTime,
  ) {
    final tableId = tables[random.nextInt(tables.length)];
    final paymentMethod = paymentMethods[random.nextInt(paymentMethods.length)];

    final numItems = random.nextInt(4) + 2; // 2 to 5 dishes
    final List<Map<String, dynamic>> itemsList = [];
    double grandTotal = 0;

    // Pick unique dishes
    final shuffledDishes = List<Map<String, dynamic>>.from(dishes)..shuffle(random);
    for (int j = 0; j < numItems; j++) {
      final dish = shuffledDishes[j];
      final qty = random.nextInt(2) + 1; // 1 or 2 parts
      final price = (dish['price'] as num).toDouble();
      final total = price * qty;
      grandTotal += total;

      itemsList.add({
        'name': dish['name'],
        'price': price,
        'quantity': qty,
        'total': total,
        'status': 'done', // realistic cooked status
      });
    }

    return {
      'tableId': tableId,
      'paymentMethod': paymentMethod,
      'grandTotal': grandTotal,
      'startedAt': Timestamp.fromDate(startedTime),
      'createdAt': Timestamp.fromDate(checkoutTime),
      'orders': [
        {
          'items': itemsList,
        }
      ],
    };
  }
}
