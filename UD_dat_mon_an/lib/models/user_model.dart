import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String role; // 'customer', 'cashier', 'chef', 'manager'
  final String name;

  UserModel({
    required this.id,
    required this.role,
    required this.name,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    return UserModel(
      id: id,
      role: map['role'] ?? 'customer',
      name: map['name'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'name': name,
    };
  }
}
