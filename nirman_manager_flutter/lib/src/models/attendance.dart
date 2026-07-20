import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, halfDay, absent }

extension AttendanceStatusX on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present (हाज़िर)';
      case AttendanceStatus.halfDay:
        return 'Half Day (आधा दिन)';
      case AttendanceStatus.absent:
        return 'Absent (गैर-हाज़िर)';
    }
  }

  String get code => name;

  /// Fraction of a full day's wage earned for this status.
  double get wageFactor {
    switch (this) {
      case AttendanceStatus.present:
        return 1.0;
      case AttendanceStatus.halfDay:
        return 0.5;
      case AttendanceStatus.absent:
        return 0.0;
    }
  }

  static AttendanceStatus fromCode(String? code) =>
      AttendanceStatus.values.firstWhere(
        (s) => s.name == code,
        orElse: () => AttendanceStatus.absent,
      );
}

class AttendanceRecord {
  final String id;
  final String workerId;
  final String workerName;
  final DateTime date; // date-only, stored at midnight
  final AttendanceStatus status;
  final double overtimeHours;

  const AttendanceRecord({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.date,
    required this.status,
    this.overtimeHours = 0,
  });

  /// Deterministic doc id: one record per worker per day.
  static String docId(String workerId, DateTime date) =>
      '${workerId}_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  factory AttendanceRecord.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AttendanceRecord(
      id: doc.id,
      workerId: (d['workerId'] ?? '') as String,
      workerName: (d['workerName'] ?? '') as String,
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: AttendanceStatusX.fromCode(d['status'] as String?),
      overtimeHours: ((d['overtimeHours'] ?? 0) as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'workerId': workerId,
        'workerName': workerName,
        'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
        'status': status.code,
        'overtimeHours': overtimeHours,
      };
}
