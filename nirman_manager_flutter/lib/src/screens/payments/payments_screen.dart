import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/payment.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';
import 'add_payment_sheet.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<Payment>>(
        stream: FirestoreService.instance.watchPayments(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final payments = snap.data ?? [];
          if (payments.isEmpty) {
            return const Center(
              child: Text(
                'Koi payment record nahi.\n+ button se payment add karein.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkSoft),
              ),
            );
          }
          final total =
              payments.fold<double>(0, (sum, p) => sum + p.amount);
          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Card(
                child: ListTile(
                  title: const Text('Total Paid',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  trailing: Text(
                    '₹${NumberFormat('#,##,###').format(total)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.green),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              for (final p in payments)
                Dismissible(
                  key: ValueKey(p.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppColors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.delete, color: Colors.white),
                  ),
                  confirmDismiss: (_) => _confirmDelete(context, p),
                  onDismissed: (_) =>
                      FirestoreService.instance.deletePayment(p.id),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: p.type == PaymentType.advance
                            ? AppColors.amberLight
                            : AppColors.greenLight,
                        child: Icon(
                          p.method == PaymentMethod.upi
                              ? Icons.qr_code
                              : p.method == PaymentMethod.bankTransfer
                                  ? Icons.account_balance
                                  : Icons.payments_outlined,
                          size: 20,
                          color: p.type == PaymentType.advance
                              ? AppColors.amber
                              : AppColors.green,
                        ),
                      ),
                      title: Text(p.workerName,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                        '${p.type.label} • ${p.method.label}\n'
                        '${DateFormat('d MMM yyyy, h:mm a').format(p.date)}'
                        '${p.note.isNotEmpty ? ' • ${p.note}' : ''}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        '₹${p.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => const AddPaymentSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Payment'),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, Payment p) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete payment?'),
        content: Text(
            '${p.workerName} ka ₹${p.amount.toStringAsFixed(0)} record delete karein?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    return yes == true;
  }
}
