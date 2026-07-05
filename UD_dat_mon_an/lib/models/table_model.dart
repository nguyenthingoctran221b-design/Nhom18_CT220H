import 'package:cloud_firestore/cloud_firestore.dart';

class TableModel {
  final String id; // e.g., 'A01'
  final String area; // 'A', 'B', 'C'
  final int number; // 1 to 20
  final String status; // 'empty', 'occupied', 'booked'
  final DateTime? entryTime;

  TableModel({
    required this.id,
    required this.area,
    required this.number,
    this.status = 'empty',
    this.entryTime,
  });

  factory TableModel.fromMap(String id, Map<String, dynamic> map) {
    return TableModel(
      id: id,
      area: map['area'] ?? '',
      number: map['number']?.toInt() ?? 0,
      status: map['status'] ?? 'empty',
      entryTime: (map['entryTime'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'area': area,
      'number': number,
      'status': status,
      'entryTime': entryTime != null ? Timestamp.fromDate(entryTime!) : null,
    };
  }
}
