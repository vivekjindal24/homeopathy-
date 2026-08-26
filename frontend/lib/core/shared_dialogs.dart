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
                  decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', labelStyle: TextStyle(fontSize: 12)),
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: timeCtrl,
                  decoration: const InputDecoration(labelText: 'Time (HH:MM)', labelStyle: TextStyle(fontSize: 12)),
                  style: const TextStyle(fontSize: 12),
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
              if (selectedPatientId == null) { formKey.currentState?.validate(); return; }
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
