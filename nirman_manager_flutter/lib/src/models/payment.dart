import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentMethod { cash, upi, bankTransfer }

extension PaymentMethodX on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash (नकद)';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  static PaymentMethod fromCode(String? code) => PaymentMethod.values
      .firstWhere((m) => m.name == code, orElse: () => PaymentMethod.cash);
}

enum PaymentType { wage, advance }

extension PaymentTypeX on PaymentType {
  String get label {
    switch (this) {
      case PaymentType.wage:
        return 'Wage (मज़दूरी)';
      case PaymentType.advance:
        return 'Advance (खर्ची)';
    }
  }

  static PaymentType fromCode(String? code) => PaymentType.values
      .firstWhere((t) => t.name == code, orElse: () => PaymentType.wage);
}

class Payment {
  final String id;
  final String workerId;
  final String workerName;
  final double amount;
  final PaymentMethod method;
  final PaymentType type;
  final String note;
  final DateTime date;

  const Payment({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.amount,
    required this.method,
    required this.type,
    required this.note,
    required this.date,
  });

  factory Payment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Payment(
      id: doc.id,
      workerId: (d['workerId'] ?? '') as String,
      workerName: (d['workerName'] ?? '') as String,
      amount: ((d['amount'] ?? 0) as num).toDouble(),
      method: PaymentMethodX.fromCode(d['method'] as String?),
      type: PaymentTypeX.fromCode(d['type'] as String?),
      note: (d['note'] ?? '') as String,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'workerId': workerId,
        'workerName': workerName,
        'amount': amount,
        'method': method.name,
        'type': type.name,
        'note': note,
        'date': Timestamp.fromDate(date),
      };
}
