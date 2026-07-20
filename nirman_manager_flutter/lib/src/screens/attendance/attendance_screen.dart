import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/attendance.dart';
import '../../models/worker.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

/// Daily hazri register: pick a date, mark every worker
/// Present / Half Day / Absent with one tap.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _date = DateTime.now();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final db = FirestoreService.instance;
    return Column(
      children: [
        // Date selector bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(
                    () => _date = _date.subtract(const Duration(days: 1))),
              ),
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEEE').format(_date),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.inkSoft),
                      ),
                      Text(
                        DateFormat('d MMMM yyyy').format(_date),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _isToday
                    ? null
                    : () => setState(
                        () => _date = _date.add(const Duration(days: 1))),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<Worker>>(
            stream: db.watchWorkers(),
            builder: (context, workerSnap) {
              if (workerSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final workers = workerSnap.data ?? [];
              if (workers.isEmpty) {
                return const Center(
                  child: Text(
                    'Pehle Workers tab se worker add karein.',
                    style: TextStyle(color: AppColors.inkSoft),
                  ),
                );
              }
              return StreamBuilder<List<AttendanceRecord>>(
                stream: db.watchAttendanceForDate(_date),
                builder: (context, attSnap) {
                  final byWorker = {
                    for (final r in attSnap.data ?? <AttendanceRecord>[])
                      r.workerId: r.status,
                  };
                  return ListView.builder(
                    padding: const EdgeInsets.all(14),
                    itemCount: workers.length,
                    itemBuilder: (context, i) {
                      final w = workers[i];
                      return _AttendanceCard(
                        worker: w,
                        status: byWorker[w.id],
                        onMark: (status) =>
                            db.markAttendance(worker: w, date: _date, status: status),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  bool get _isToday {
    final now = DateTime.now();
    return _date.year == now.year &&
        _date.month == now.month &&
        _date.day == now.day;
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({
    required this.worker,
    required this.status,
    required this.onMark,
  });

  final Worker worker;
  final AttendanceStatus? status;
  final void Function(AttendanceStatus) onMark;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.navy,
                  child: Text(
                    worker.name.isEmpty ? '?' : worker.name[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(worker.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      Text(worker.role,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.inkSoft)),
                    ],
                  ),
                ),
                if (status != null)
                  _StatusChip(status: status!),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MarkButton(
                  label: 'Present',
                  color: AppColors.green,
                  selected: status == AttendanceStatus.present,
                  onTap: () => onMark(AttendanceStatus.present),
                ),
                const SizedBox(width: 8),
                _MarkButton(
                  label: 'Half',
                  color: AppColors.amber,
                  selected: status == AttendanceStatus.halfDay,
                  onTap: () => onMark(AttendanceStatus.halfDay),
                ),
                const SizedBox(width: 8),
                _MarkButton(
                  label: 'Absent',
                  color: AppColors.red,
                  selected: status == AttendanceStatus.absent,
                  onTap: () => onMark(AttendanceStatus.absent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, bg, text) = switch (status) {
      AttendanceStatus.present => (
          AppColors.green,
          AppColors.greenLight,
          'P'
        ),
      AttendanceStatus.halfDay => (AppColors.amber, AppColors.amberLight, '½'),
      AttendanceStatus.absent => (AppColors.red, AppColors.redLight, 'A'),
    };
    return Container(
      width: 30,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(text,
          style: TextStyle(color: color, fontWeight: FontWeight.w800)),
    );
  }
}

class _MarkButton extends StatelessWidget {
  const _MarkButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? color : Colors.transparent,
          foregroundColor: selected ? Colors.white : color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
