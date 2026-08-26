import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class PatientManagement extends StatefulWidget {
  final String? clinicId;
  const PatientManagement({super.key, this.clinicId});

  @override
  State<PatientManagement> createState() => _PatientManagementState();
}

class _PatientManagementState extends State<PatientManagement> {
  final ApiService _apiService = ApiService();
  final _searchController = TextEditingController();
  
  List<dynamic> _patients = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  Future<void> _fetchPatients() async {
    setState(() => _isLoading = true);
    final results = await _apiService.getPatients(search: _searchController.text.trim());
    setState(() {
      _patients = results;
      _isLoading = false;
    });
  }

  void _openRegistrationDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final dobController = TextEditingController();
    final mobileController = TextEditingController();
    final addressController = TextEditingController();
    final occupationController = TextEditingController();
    final emailController = TextEditingController();
    final allergiesController = TextEditingController();
    final chronicController = TextEditingController();
    final referralController = TextEditingController();
    
    String gender = "M";
    String bloodGroup = "A+";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Register New Patient', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Container(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full Name *'),
                      validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: dobController,
                            decoration: const InputDecoration(
                              labelText: 'DOB (YYYY-MM-DD) *',
                              suffixIcon: Icon(Icons.calendar_today, size: 18),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required field';
                              if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) return 'Use YYYY-MM-DD';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: gender,
                            decoration: const InputDecoration(labelText: 'Gender *'),
                            items: const [
                              DropdownMenuItem(value: 'M', child: Text('Male')),
                              DropdownMenuItem(value: 'F', child: Text('Female')),
                              DropdownMenuItem(value: 'Other', child: Text('Other')),
                            ],
                            onChanged: (val) => gender = val ?? 'M',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: mobileController,
                            decoration: const InputDecoration(labelText: 'Mobile Number *'),
                            validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: bloodGroup,
                            decoration: const InputDecoration(labelText: 'Blood Group'),
                            items: const ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                                .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                                .toList(),
                            onChanged: (val) => bloodGroup = val ?? 'A+',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(labelText: 'Address *'),
                      validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: occupationController,
                      decoration: const InputDecoration(labelText: 'Occupation *'),
                      validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email (Optional)'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: allergiesController,
                      decoration: const InputDecoration(labelText: 'Known Allergies'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: chronicController,
                      decoration: const InputDecoration(labelText: 'Chronic Conditions'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: referralController,
                      decoration: const InputDecoration(labelText: 'Referred By'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final result = await _apiService.createPatient({
                    'full_name': nameController.text.trim(),
                    'dob': dobController.text,
                    'gender': gender,
                    'mobile': mobileController.text.trim(),
                    'address': addressController.text.trim(),
                    'occupation': occupationController.text.trim(),
                    'email': emailController.text.isNotEmpty ? emailController.text.trim() : null,
                    'blood_group': bloodGroup,
                    'allergies': allergiesController.text.isNotEmpty ? allergiesController.text : null,
                    'chronic_conditions': chronicController.text.isNotEmpty ? chronicController.text : null,
                    'referred_by': referralController.text.isNotEmpty ? referralController.text : null,
                  });
                  if (result != null) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Patient registered successfully.')),
                    );
                    _fetchPatients();
                  }
                }
              },
              child: const Text('Register'),
            ),
          ],
        );
      },
    );
  }

  void _openBookingDialog(Map<String, dynamic> patient) {
    if (widget.clinicId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a clinic first.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final dateController = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    final timeController = TextEditingController(text: "10:00");
    
    String visitType = "New"; // "New", "Follow-Up", "Walk-In"
    String doctorId = _apiService.userId ?? ""; // Single doctor, default is active user

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Book Appointment for ${patient['full_name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD) *'),
                  validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: timeController,
                  decoration: const InputDecoration(labelText: 'Time (HH:MM) *'),
                  validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: visitType,
                  decoration: const InputDecoration(labelText: 'Visit Type *'),
                  items: const [
                    DropdownMenuItem(value: 'New', child: Text('New Consultation')),
                    DropdownMenuItem(value: 'Follow-Up', child: Text('Follow-Up Visit')),
                    DropdownMenuItem(value: 'Walk-In', child: Text('Walk-In Conversion')),
                  ],
                  onChanged: (val) => visitType = val ?? 'New',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  // If doctorId is empty, fetch doctors or set a mock one
                  if (doctorId.isEmpty) {
                    // Try to use the first doctor in system or placeholder
                    doctorId = "doctor-uuid-placeholder";
                  }
                  
                  final result = await _apiService.createAppointment({
                    'patient_id': patient['patient_id'],
                    'doctor_id': doctorId,
                    'clinic_id': widget.clinicId,
                    'appt_date': dateController.text,
                    'appt_time': timeController.text,
                    'visit_type': visitType,
                  });
                  
                  if (result != null) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Appointment booked successfully.')),
                    );
                  }
                }
              },
              child: const Text('Book Slot'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Registry'),
        actions: [
          ElevatedButton.icon(
            onPressed: _openRegistrationDialog,
            icon: const Icon(Icons.person_add_alt_1, size: 16),
            label: const Text('New Patient'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Search box
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by patient name, mobile number, or ID...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _fetchPatients(),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _fetchPatients,
                  child: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Patient list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _patients.isEmpty
                      ? const Center(child: Text('No patients found.'))
                      : Card(
                          child: ListView.separated(
                            itemCount: _patients.length,
                            separatorBuilder: (context, index) => const Divider(color: Color(0xFFE2E8F0)),
                            itemBuilder: (context, index) {
                              final p = _patients[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFE0F2FE),
                                  foregroundColor: const Color(0xFF0369A1),
                                  child: const Icon(Icons.person_outline),
                                ),
                                title: Text(
                                  p['full_name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Text(
                                  'ID: ${p['unique_patient_id']}  ·  Phone: ${p['mobile']}  ·  DOB: ${p['dob']}',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => _openBookingDialog(p),
                                      icon: const Icon(Icons.calendar_today, size: 14),
                                      label: const Text('Book Appointment', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
