import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/attendance.dart';
import '../models/payment.dart';
import '../models/worker.dart';

/// All app data lives under users/{uid}/... so each account's data
/// is private to that account.
class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _workers =>
      _db.collection('users').doc(_uid).collection('workers');
  CollectionReference<Map<String, dynamic>> get _attendance =>
      _db.collection('users').doc(_uid).collection('attendance');
  CollectionReference<Map<String, dynamic>> get _payments =>
      _db.collection('users').doc(_uid).collection('payments');

  // ---------- Workers ----------

  Stream<List<Worker>> watchWorkers() => _workers
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map(Worker.fromDoc).toList());

  Future<void> addWorker({
    required String name,
    required String phone,
    required String role,
    required double dailyWage,
  }) =>
      _workers.add({
        'name': name,
        'phone': phone,
        'role': role,
        'dailyWage': dailyWage,
        'createdAt': Timestamp.now(),
      });

  Future<void> deleteWorker(String workerId) => _workers.doc(workerId).delete();

  // ---------- Attendance ----------

  Stream<List<AttendanceRecord>> watchAttendanceForDate(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return _attendance
        .where('date', isEqualTo: Timestamp.fromDate(day))
        .snapshots()
        .map((s) => s.docs.map(AttendanceRecord.fromDoc).toList());
  }

  Future<void> markAttendance({
    required Worker worker,
    required DateTime date,
    required AttendanceStatus status,
  }) {
    final day = DateTime(date.year, date.month, date.day);
    final id = AttendanceRecord.docId(worker.id, day);
    return _attendance.doc(id).set(
          AttendanceRecord(
            id: id,
            workerId: worker.id,
            workerName: worker.name,
            date: day,
            status: status,
          ).toMap(),
        );
  }

  /// Attendance records for one worker in a date range (for wage totals).
  Future<List<AttendanceRecord>> attendanceForWorker({
    required String workerId,
    required DateTime from,
    required DateTime to,
  }) async {
    final snap = await _attendance
        .where('workerId', isEqualTo: workerId)
        .where('date',
            isGreaterThanOrEqualTo:
                Timestamp.fromDate(DateTime(from.year, from.month, from.day)))
        .where('date',
            isLessThanOrEqualTo:
                Timestamp.fromDate(DateTime(to.year, to.month, to.day)))
        .get();
    return snap.docs.map(AttendanceRecord.fromDoc).toList();
  }

  // ---------- Payments ----------

  Stream<List<Payment>> watchPayments({int limit = 100}) => _payments
      .orderBy('date', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(Payment.fromDoc).toList());

  Future<void> addPayment(Payment payment) => _payments.add(payment.toMap());

  Future<void> deletePayment(String paymentId) =>
      _payments.doc(paymentId).delete();

  /// Total paid to a worker (all time).
  Future<double> totalPaidToWorker(String workerId) async {
    final snap = await _payments.where('workerId', isEqualTo: workerId).get();
    return snap.docs
        .map(Payment.fromDoc)
        .fold<double>(0, (sum, p) => sum + p.amount);
  }
}
