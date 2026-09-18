import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/worker.dart';
import '../../services/firestore_service.dart';
import '../../theme.dart';

class WorkersScreen extends StatelessWidget {
  const WorkersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<Worker>>(
        stream: FirestoreService.instance.watchWorkers(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final workers = snap.data ?? [];
          if (workers.isEmpty) {
            return const Center(
              child: Text(
                'Koi worker nahi.\n+ button se worker add karein.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.inkSoft),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: workers.length,
            itemBuilder: (context, i) {
              final w = workers[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.navy,
                    child: Text(
                      w.name.isEmpty ? '?' : w.name[0].toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(w.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                      '${w.role} • ₹${w.dailyWage.toStringAsFixed(0)}/din'
                      '${w.phone.isNotEmpty ? ' • ${w.phone}' : ''}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.red),
                    onPressed: () => _confirmDelete(context, w),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWorkerSheet(context),
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add Worker'),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Worker w) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete worker?'),
        content: Text('${w.name} ko delete karein? '
            'Attendance aur payment records delete nahi honge.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (yes == true) {
      await FirestoreService.instance.deleteWorker(w.id);
    }
  }

  void _showAddWorkerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const _AddWorkerForm(),
    );
  }
}

class _AddWorkerForm extends StatefulWidget {
  const _AddWorkerForm();

  @override
  State<_AddWorkerForm> createState() => _AddWorkerFormState();
}

class _AddWorkerFormState extends State<_AddWorkerForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _wage = TextEditingController();
  String _role = 'Labour';
  bool _saving = false;

  static const _roles = ['Labour', 'Mistri', 'Helper', 'Supervisor', 'Driver'];

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _wage.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await FirestoreService.instance.addWorker(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        role: _role,
        dailyWage: double.parse(_wage.text.trim()),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Naya Worker',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Naam *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Naam zaroori hai' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                  labelText: 'Mobile (optional)', counterText: ''),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: [
                for (final r in _roles)
                  DropdownMenuItem(value: r, child: Text(r)),
              ],
              onChanged: (v) => setState(() => _role = v ?? 'Labour'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _wage,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                  labelText: 'Daily Wage (₹) *', prefixText: '₹ '),
              validator: (v) {
                final n = double.tryParse(v?.trim() ?? '');
                if (n == null || n <= 0) return 'Sahi wage daalein';
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : const Text('Save Worker'),
            ),
          ],
        ),
      ),
    );
  }
}
