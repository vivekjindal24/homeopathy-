import 'package:flutter/material.dart';
import 'constants.dart';
import '../services/api_service.dart';

Future<void> showBookingDialog({
  required BuildContext context,
  required ApiService api,
  required String? doctorId,
  required String? clinicId,
  required VoidCallback onBooked,
  String? preselectedPatientId,
}) async {
  final formKey = GlobalKey<FormState>();
  final dateCtrl = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
  final timeCtrl = TextEditingController(text: '10:00');
  String visitType = 'New';
  String? selectedPatientId = preselectedPatientId;

  List<dynamic> patients = [];
  if (selectedPatientId == null) {
    try {
      patients = await api.getPatients();
    } catch (_) {}
  }

  if (!context.mounted) return;

  Future<void> pickDate(StateSetter setDialogState) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(dateCtrl.text) ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setDialogState(() => dateCtrl.text = picked.toIso8601String().substring(0, 10));
  }

  Future<void> pickTime(StateSetter setDialogState) async {
    final parts = timeCtrl.text.split(':');
    final initial = TimeOfDay(hour: int.tryParse(parts.isNotEmpty ? parts[0] : '10') ?? 10, minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) setDialogState(() => timeCtrl.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
  }

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) {
      return AlertDialog(
        title: const Text('Book Appointment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 340,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                if (selectedPatientId == null) ...[
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Patient', labelStyle: TextStyle(fontSize: 12)),
                    items: patients.map<DropdownMenuItem<String>>((p) => DropdownMenuItem(
                      value: p['unique_patient_id'] as String?,
                      child: Text('${p['full_name']} (${p['unique_patient_id']})', style: const TextStyle(fontSize: 11)),
                    )).toList(),
                    onChanged: (v) => selectedPatientId = v,
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                ] else
                  Text('Patient: $selectedPatientId', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                TextFormField(
                  controller: dateCtrl,
                  readOnly: true,
                  onTap: () => pickDate(setDialogState),
                  decoration: const InputDecoration(labelText: 'Date', suffixIcon: Icon(Icons.calendar_today, size: 18), labelStyle: TextStyle(fontSize: 12)),
                  style: const TextStyle(fontSize: 12),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) return 'Use YYYY-MM-DD';
                    if (DateTime.tryParse(v) == null) return 'Invalid date';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: timeCtrl,
                  readOnly: true,
                  onTap: () => pickTime(setDialogState),
                  decoration: const InputDecoration(labelText: 'Time', suffixIcon: Icon(Icons.access_time, size: 18), labelStyle: TextStyle(fontSize: 12)),
                  style: const TextStyle(fontSize: 12),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(v)) return 'Use HH:MM';
                    final parts = v.split(':');
                    final h = int.tryParse(parts[0]) ?? -1;
                    final m = int.tryParse(parts[1]) ?? -1;
                    if (h < 0 || h > 23 || m < 0 || m > 59) return 'Invalid time';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: visitType,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Visit Type', labelStyle: TextStyle(fontSize: 12)),
                  items: ['New', 'Follow-up'].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 11)))).toList(),
                  onChanged: (v) => setDialogState(() => visitType = v ?? 'New'),
                ),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (selectedPatientId == null || !(formKey.currentState?.validate() ?? false)) return;
              try {
                await api.createAppointment({
                  'patient_id': selectedPatientId,
                  'doctor_id': doctorId,
                  'clinic_id': clinicId,
                  'appt_date': dateCtrl.text.trim(),
                  'appt_time': timeCtrl.text.trim(),
                  'visit_type': visitType,
                });
                if (context.mounted) Navigator.pop(ctx);
                onBooked();
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: cPrimary, foregroundColor: Colors.white),
            child: const Text('Book', style: TextStyle(fontSize: 12)),
          ),
        ],
      );
    }),
  );
}
