import 'package:cloud_firestore/cloud_firestore.dart';

class Worker {
  final String id;
  final String name;
  final String phone;
  final String role; // e.g. Mistri, Labour, Helper
  final double dailyWage;
  final DateTime createdAt;

  const Worker({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.dailyWage,
    required this.createdAt,
  });

  factory Worker.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Worker(
      id: doc.id,
      name: (d['name'] ?? '') as String,
      phone: (d['phone'] ?? '') as String,
      role: (d['role'] ?? 'Labour') as String,
      dailyWage: ((d['dailyWage'] ?? 0) as num).toDouble(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'role': role,
        'dailyWage': dailyWage,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
