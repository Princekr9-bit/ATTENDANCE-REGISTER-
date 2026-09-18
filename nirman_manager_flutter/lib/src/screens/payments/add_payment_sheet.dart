import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/payment.dart';
import '../../models/worker.dart';
import '../../services/firestore_service.dart';
import '../../services/upi_service.dart';
import '../../theme.dart';

/// Bottom sheet to record a payment (wage or advance/kharchi) with
/// Cash / UPI / Bank Transfer as the payment method. Choosing UPI can
/// also launch the user's UPI app with the amount pre-filled.
class AddPaymentSheet extends StatefulWidget {
  const AddPaymentSheet({super.key});

  @override
  State<AddPaymentSheet> createState() => _AddPaymentSheetState();
}

class _AddPaymentSheetState extends State<AddPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _upiId = TextEditingController();

  Worker? _worker;
  PaymentMethod _method = PaymentMethod.cash;
  PaymentType _type = PaymentType.wage;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    _upiId.dispose();
    super.dispose();
  }

  Future<void> _save({required bool launchUpi}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_worker == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker select karein')),
      );
      return;
    }
    setState(() => _saving = true);
    final amount = double.parse(_amount.text.trim());

    try {
      if (launchUpi) {
        final ok = await UpiService.pay(
          payeeVpa: _upiId.text.trim(),
          payeeName: _worker!.name,
          amount: amount,
          note: _note.text.trim().isEmpty
              ? '${_type.label} - Nirman Manager'
              : _note.text.trim(),
        );
        if (!ok && mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Koi UPI app nahi mila. Payment record manually save karein.')),
          );
          return;
        }
      }

      await FirestoreService.instance.addPayment(
        Payment(
          id: '',
          workerId: _worker!.id,
          workerName: _worker!.name,
          amount: amount,
          method: _method,
          type: _type,
          note: _note.text.trim(),
          date: DateTime.now(),
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Nayi Payment',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),

              // Worker selector
              StreamBuilder<List<Worker>>(
                stream: FirestoreService.instance.watchWorkers(),
                builder: (context, snap) {
                  final workers = snap.data ?? [];
                  return DropdownButtonFormField<Worker>(
                    value: _worker,
                    decoration: const InputDecoration(labelText: 'Worker *'),
                    items: [
                      for (final w in workers)
                        DropdownMenuItem(value: w, child: Text(w.name)),
                    ],
                    onChanged: (w) => setState(() => _worker = w),
                    validator: (w) => w == null ? 'Worker chunein' : null,
                  );
                },
              ),
              const SizedBox(height: 12),

              // Amount
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    labelText: 'Amount (₹) *', prefixText: '₹ '),
                validator: (v) {
                  final n = double.tryParse(v?.trim() ?? '');
                  if (n == null || n <= 0) return 'Sahi amount daalein';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Payment type
              SegmentedButton<PaymentType>(
                segments: [
                  for (final t in PaymentType.values)
                    ButtonSegment(value: t, label: Text(t.label)),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 16),

              // Payment method
              const Text('Payment Method',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              SegmentedButton<PaymentMethod>(
                segments: const [
                  ButtonSegment(
                      value: PaymentMethod.cash,
                      icon: Icon(Icons.payments_outlined, size: 18),
                      label: Text('Cash')),
                  ButtonSegment(
                      value: PaymentMethod.upi,
                      icon: Icon(Icons.qr_code, size: 18),
                      label: Text('UPI')),
                  ButtonSegment(
                      value: PaymentMethod.bankTransfer,
                      icon: Icon(Icons.account_balance, size: 18),
                      label: Text('Bank')),
                ],
                selected: {_method},
                onSelectionChanged: (s) => setState(() => _method = s.first),
              ),

              if (_method == PaymentMethod.upi) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _upiId,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Worker ki UPI ID',
                    hintText: 'name@upi',
                    helperText:
                        'UPI ID daalne par GPay/PhonePe/Paytm se seedha pay kar sakte hain',
                  ),
                ),
              ],

              const SizedBox(height: 12),
              TextFormField(
                controller: _note,
                decoration:
                    const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 20),

              if (_method == PaymentMethod.upi &&
                  _upiId.text.trim().isNotEmpty) ...[
                ElevatedButton.icon(
                  onPressed: _saving ? null : () => _save(launchUpi: true),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Pay via UPI App & Save'),
                ),
                const SizedBox(height: 10),
              ],
              ElevatedButton(
                onPressed: _saving ? null : () => _save(launchUpi: false),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text('Save Payment Record'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
