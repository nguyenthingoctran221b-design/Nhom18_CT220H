import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
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


        int tfp = 10;

        final menuItem = MenuItem(
          tfp: tfp,
        );

      }
    }
  }
}
