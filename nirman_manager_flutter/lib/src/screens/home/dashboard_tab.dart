import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/attendance.dart';
import '../../models/payment.dart';
import '../../models/worker.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

/// Overview: today's hazri summary, worker count, recent payments total.
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService.instance;
    final today = DateTime.now();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.navy, AppColors.navy2],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, d MMMM yyyy').format(today),
                style: const TextStyle(color: Color(0xFFAEB9CE), fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                'Namaste! 🙏',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Aaj ki hazri aur payments ek jagah.',
                style: TextStyle(color: Color(0xFFAEB9CE), fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        StreamBuilder<List<Worker>>(
          stream: db.watchWorkers(),
          builder: (context, workerSnap) {
            final workerCount = workerSnap.data?.length ?? 0;
            return StreamBuilder<List<AttendanceRecord>>(
              stream: db.watchAttendanceForDate(today),
              builder: (context, attSnap) {
                final records = attSnap.data ?? [];
                final present = records
                    .where((r) => r.status == AttendanceStatus.present)
                    .length;
                final half = records
                    .where((r) => r.status == AttendanceStatus.halfDay)
                    .length;
                final absent = records
                    .where((r) => r.status == AttendanceStatus.absent)
                    .length;
                return Row(
                  children: [
                    _StatCard(
                        label: 'Workers',
                        value: '$workerCount',
                        color: AppColors.navy),
                    _StatCard(
                        label: 'Present',
                        value: '$present',
                        color: AppColors.green),
                    _StatCard(
                        label: 'Half Day',
                        value: '$half',
                        color: AppColors.amber),
                    _StatCard(
                        label: 'Absent',
                        value: '$absent',
                        color: AppColors.red),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 18),
        const Text(
          'Recent Payments',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<Payment>>(
          stream: db.watchPayments(limit: 5),
          builder: (context, snap) {
            final payments = snap.data ?? [];
            if (payments.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Abhi tak koi payment record nahi hai.'),
                ),
              );
            }
            return Column(
              children: [
                for (final p in payments)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.greenLight,
                        child: const Icon(Icons.currency_rupee,
                            color: AppColors.green, size: 20),
                      ),
                      title: Text(p.workerName,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          '${p.type.label} • ${p.method.label} • ${DateFormat('d MMM').format(p.date)}'),
                      trailing: Text(
                        '₹${p.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.only(right: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.inkSoft)),
            ],
          ),
        ),
      ),
    );
  }
}
