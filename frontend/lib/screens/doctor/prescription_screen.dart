import 'package:flutter/material.dart';
import '../../services/api_service.dart';

/// Entry point for the named route '/prescription' (see main.dart).
Widget buildPrescriptionScreen(Map<String, dynamic> appointmentArgs) =>
    PrescriptionScreen(appointment: appointmentArgs);

class PrescriptionScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;
  const PrescriptionScreen({super.key, required this.appointment});

  @override
  State<PrescriptionScreen> createState() => _PrescriptionScreenState();
}

class _PrescriptionScreenState extends State<PrescriptionScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  final _complaintController = TextEditingController();
  final _diagnosisController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _followUpController = TextEditingController();

  final List<Map<String, String>> _medicines = [
    {"name": "", "potency": "", "dosage": "", "frequency": "", "duration": ""}
  ];

  bool _isWaiverEligible = false;
  bool _applyWaiver = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkWaiverEligibility();
  }

  Future<void> _checkWaiverEligibility() async {
    final patientId = widget.appointment['patient_id'];
    final date = widget.appointment['appt_date'];
    final eligible = await _apiService.check7dayWaiver(patientId, date);
    if (!mounted) return;
    setState(() {
      _isWaiverEligible = eligible;
      _applyWaiver = eligible; // Automatically opt-in if eligible
    });
  }

  void _addMedicineRow() {
    setState(() {
      _medicines.add({
        "name": "",
        "potency": "",
        "dosage": "",
        "frequency": "",
        "duration": ""
      });
    });
  }

  void _removeMedicineRow(int index) {
    if (_medicines.length <= 1) return;
    setState(() {
      _medicines.removeAt(index);
    });
  }

  Future<void> _savePrescription() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate medicines are not completely empty
    for (var m in _medicines) {
      if (m['name']!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter name for all medicines in the list.')),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      // Invoice/billing is the receptionist's job after the visit (PRD §5.4.5);
      // saving a prescription only records clinical data + fee-waiver flag.
      await _apiService.createPrescription({
        'appt_id': widget.appointment['appt_id'],
        'patient_id': widget.appointment['patient_id'],
        'chief_complaint': _complaintController.text.trim(),
        'diagnosis': _diagnosisController.text.trim(),
        'medicines': _medicines,
        'instructions': _instructionsController.text.isNotEmpty ? _instructionsController.text.trim() : null,
        'follow_up_date': _followUpController.text.isNotEmpty ? _followUpController.text : null,
        'is_fee_waived': _applyWaiver,
      });

      if (!mounted) return;
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription finalized and consultation marked Completed.')),
      );
      Navigator.pop(context); // Go back to schedule
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to finalize prescription: ${e.message}')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to finalize prescription. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.appointment['patient'] ?? {};
    final patientName = patient['full_name'] ?? 'Walk-In';

    return Scaffold(
      appBar: AppBar(
        title: Text('New Prescription: $patientName'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Waiver Alert Banner
                    if (_isWaiverEligible) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars, color: Colors.amber, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '7-Day Fee Waiver Eligible',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E), fontSize: 14),
                                  ),
                                  Text(
                                    'This patient is returning within 7 days of their last visit. Consultation fee will be automatically waived.',
                                    style: TextStyle(color: Colors.amber[800], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Case Details Group
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Clinical Notes & Diagnosis',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F766E)),
                            ),
                            const Divider(height: 20),
                            
                            TextFormField(
                              controller: _complaintController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Chief Complaints *',
                                hintText: 'Enter symptoms, duration, modalities...',
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              controller: _diagnosisController,
                              decoration: const InputDecoration(
                                labelText: 'Clinical Diagnosis *',
                                hintText: 'Enter diagnostic term...',
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Medicines Table Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Homeopathic Medicine Prescription List',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F766E)),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _addMedicineRow,
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add Drug', style: TextStyle(fontSize: 12)),
                                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            
                            // Dynamic medicine forms
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _medicines.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 16),
                              itemBuilder: (context, idx) {
                                return Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: TextFormField(
                                        decoration: const InputDecoration(labelText: 'Medicine Name *', contentPadding: EdgeInsets.all(12)),
                                        onChanged: (v) => _medicines[idx]['name'] = v,
                                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        decoration: const InputDecoration(labelText: 'Potency / Dilution', contentPadding: EdgeInsets.all(12)),
                                        onChanged: (v) => _medicines[idx]['potency'] = v,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        decoration: const InputDecoration(labelText: 'Dosage / Drops', contentPadding: EdgeInsets.all(12)),
                                        onChanged: (v) => _medicines[idx]['dosage'] = v,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        decoration: const InputDecoration(labelText: 'Frequency', contentPadding: EdgeInsets.all(12)),
                                        onChanged: (v) => _medicines[idx]['frequency'] = v,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        decoration: const InputDecoration(labelText: 'Duration', contentPadding: EdgeInsets.all(12)),
                                        onChanged: (v) => _medicines[idx]['duration'] = v,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _removeMedicineRow(idx),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Additional metadata card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Waiver & Follow-up Settings',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F766E)),
                            ),
                            const Divider(height: 20),
                            
                            TextFormField(
                              controller: _instructionsController,
                              decoration: const InputDecoration(
                                labelText: 'Special Instructions / Dietary Restrictions',
                                hintText: 'Avoid onion/garlic/coffee during treatment, etc.',
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _followUpController,
                                    decoration: const InputDecoration(
                                      labelText: 'Follow-up Date (YYYY-MM-DD)',
                                      suffixIcon: Icon(Icons.calendar_today, size: 18),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                
                                // Fee Waiver checkbox
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _applyWaiver,
                                      onChanged: (val) {
                                        setState(() {
                                          _applyWaiver = val ?? false;
                                        });
                                      },
                                    ),
                                    const Text(
                                      'Waive consultation fee for this visit',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Final Submission actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Discard Draft'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _savePrescription,
                          child: const Text('Finalize & Complete Visit'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
