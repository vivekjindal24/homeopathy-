import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';

class AppointmentsManagement extends StatefulWidget {
  final String? clinicId;
  final String dateStr;
  const AppointmentsManagement({super.key, this.clinicId, required this.dateStr});

  @override
  State<AppointmentsManagement> createState() => _AppointmentsManagementState();
}

class _AppointmentsManagementState extends State<AppointmentsManagement> {
  final ApiService _apiService = ApiService();
  List<dynamic> _appointments = [];
  bool _isLoading = false;
  String? _error;
  String _viewMode = "table"; // "table" or "calendar"

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  @override
  void didUpdateWidget(covariant AppointmentsManagement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clinicId != widget.clinicId || oldWidget.dateStr != widget.dateStr) {
      _fetchAppointments();
    }
  }

  Future<void> _fetchAppointments() async {
    if (widget.clinicId == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await _apiService.getAppointments(clinicId: widget.clinicId, date: widget.dateStr);
      if (!mounted) return;
      setState(() {
        _appointments = results;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmAppointment(String apptId) async {
    try {
      await _apiService.updateAppointmentStatus(apptId, AppointmentStatus.confirmed);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient appointment confirmed successfully.')),
      );
      _fetchAppointments();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.message);
    }
  }

  Future<void> _cancelAppointment(String apptId) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Cancel Appointment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('A cancellation reason is required.'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason *',
                hintText: 'e.g. Patient requested reschedule',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Appointment'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _apiService.updateAppointmentStatus(apptId, AppointmentStatus.cancelled,
          reason: reasonController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment has been cancelled.')),
      );
      _fetchAppointments();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.message);
    }
  }

  void _openRescheduleDialog(dynamic appt) {
    final formKey = GlobalKey<FormState>();
    final dateController = TextEditingController(text: appt['appt_date']);
    final timeController = TextEditingController(text: appt['appt_time']);
    final token = appt['token_number'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(token != null
              ? 'Reschedule Appointment: T-$token'
              : 'Reschedule Appointment'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: 'New Date (YYYY-MM-DD) *'),
                  validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: timeController,
                  decoration: const InputDecoration(labelText: 'New Time (HH:MM) *'),
                  validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
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
                  try {
                    await _apiService.rescheduleAppointment(
                      appt['appt_id'],
                      dateController.text.trim(),
                      timeController.text.trim(),
                    );
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Appointment rescheduled to ${dateController.text} at ${timeController.text}.')),
                    );
                    _fetchAppointments();
                  } on ApiException catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text(e.message), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _openWalkInFlow() {
    showDialog(
      context: context,
      builder: (context) => _WalkInIntakeModal(
        clinicId: widget.clinicId,
        onComplete: () {
          _fetchAppointments();
        },
      ),
    );
  }

  void _openBookAppointmentDialog() {
    final formKey = GlobalKey<FormState>();
    String? selectedPatientId;
    final dateController = TextEditingController(text: widget.dateStr);
    final timeController = TextEditingController(text: "10:00");
    String visitType = VisitType.newVisit;
    List<dynamic> localPatients = [];
    bool localLoading = true;
    String? loadError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> load() async {
              setDialogState(() => localLoading = true);
              try {
                final res = await _apiService.getPatients();
                setDialogState(() {
                  localPatients = res;
                  localLoading = false;
                });
              } on ApiException catch (e) {
                setDialogState(() {
                  loadError = e.message;
                  localLoading = false;
                });
              }
            }

            if (localPatients.isEmpty && localLoading && loadError == null) {
              load();
            }

            return AlertDialog(
              title: const Text('Book Appointment Slot', style: TextStyle(fontWeight: FontWeight.bold)),
              content: localLoading
                  ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
                  : loadError != null
                      ? SizedBox(
                          width: 450,
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Text('Failed to load patients: $loadError',
                                style: const TextStyle(color: Colors.red, fontSize: 12)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: load, child: const Text('Retry')),
                          ]),
                        )
                      : Form(
                          key: formKey,
                          child: Container(
                            width: 450,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DropdownButtonFormField<String>(
                                  value: selectedPatientId,
                                  decoration: const InputDecoration(labelText: 'Select Patient *'),
                                  items: localPatients.map<DropdownMenuItem<String>>((p) {
                                    return DropdownMenuItem<String>(
                                      value: p['patient_id'],
                                      child: Text('${p['full_name']} (${p['mobile'] ?? p['mobile_number'] ?? ''})'),
                                    );
                                  }).toList(),
                                  onChanged: (val) => setDialogState(() => selectedPatientId = val),
                                  validator: (v) => v == null ? 'Please select patient' : null,
                                ),
                                const SizedBox(height: 12),
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
                                    DropdownMenuItem(value: VisitType.newVisit, child: Text('New Consultation')),
                                    DropdownMenuItem(value: VisitType.followUp, child: Text('Follow-Up Visit')),
                                  ],
                                  onChanged: (val) => visitType = val ?? VisitType.newVisit,
                                ),
                              ],
                            ),
                          ),
                        ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: localLoading
                      ? null
                      : () async {
                          if (formKey.currentState!.validate() && selectedPatientId != null) {
                            if (_apiService.userId == null) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(content: Text('Please log in to book appointments.'), backgroundColor: Colors.red),
                              );
                              return;
                            }
                            try {
                              await _apiService.createAppointment({
                                'patient_id': selectedPatientId,
                                'doctor_id': _apiService.userId!,
                                'clinic_id': widget.clinicId,
                                'appt_date': dateController.text.trim(),
                                'appt_time': timeController.text.trim(),
                                'visit_type': visitType,
                              });
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(content: Text('Appointment booked successfully.')),
                              );
                              _fetchAppointments();
                            } on ApiException catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(content: Text(e.message), backgroundColor: Colors.red),
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
      },
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(error),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, Color> apptStatusStyle = {
      AppointmentStatus.scheduled: Colors.amber[700]!,
      AppointmentStatus.arrived: Colors.amber[700]!,
      AppointmentStatus.confirmed: Colors.green[700]!,
      AppointmentStatus.inConsultation: Colors.purple[700]!,
      AppointmentStatus.completed: Colors.teal[700]!,
      AppointmentStatus.cancelled: Colors.red[700]!,
      AppointmentStatus.noShow: Colors.grey[700]!,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Appointments Dashboard'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          // View Toggle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildToggleButton("table", "Table View"),
                _buildToggleButton("calendar", "Week Calendar"),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _openWalkInFlow,
            icon: const Icon(Icons.flash_on_rounded, size: 16, color: Colors.white),
            label: const Text('Walk-In Intake'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _openBookAppointmentDialog,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Book Appointment'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: widget.clinicId == null
          ? const Center(child: Text('Please select a clinic first.'))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 40, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 12),
                      Text('Failed to load appointments\n$_error',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFF64748B))),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _fetchAppointments,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: _viewMode == "calendar" ? _buildCalendarView(apptStatusStyle) : _buildTableView(apptStatusStyle),
                    ),
    );
  }

  Widget _buildToggleButton(String key, String label) {
    final active = _viewMode == key;
    return InkWell(
      onTap: () => setState(() => _viewMode = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: active ? const Color(0xFF0F172A) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildTableView(Map<String, Color> styles) {
    if (_appointments.isEmpty) {
      return const Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(48.0),
            child: Text('No appointments scheduled for this date.', style: TextStyle(fontStyle: FontStyle.italic)),
          ),
        ),
      );
    }

    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: _appointments.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final a = _appointments[index];
                  final patientName = a['patient']?['full_name'] ?? 'Walk-In';
                  final tokenNum = a['token_number'];
                  final tokenStr = tokenNum != null ? "T-$tokenNum" : "--";
                  final status = '${a['status'] ?? ''}';
                  final styleColor = styles[status] ?? const Color(0xFF64748B);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Text(
                          tokenStr,
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F766E)),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text(
                                'Time: ${a['appt_time'] ?? '--:--'}  ·  Type: ${a['visit_type'] ?? '--'}  ·  Doc: Dr. Verma',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: styleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(color: styleColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Row(
                          children: [
                            if (status == AppointmentStatus.scheduled)
                              ElevatedButton(
                                onPressed: () => _confirmAppointment(a['appt_id']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                child: const Text('Confirm', style: TextStyle(fontSize: 11)),
                              ),
                            if (status == AppointmentStatus.confirmed)
                              ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await _apiService.updateAppointmentStatus(
                                        a['appt_id'], AppointmentStatus.arrived);
                                    if (!mounted) return;
                                    _fetchAppointments();
                                  } on ApiException catch (e) {
                                    if (!mounted) return;
                                    _showErrorDialog(e.message);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD97706),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                child: const Text('Arrive', style: TextStyle(fontSize: 11)),
                              ),
                            if (status == AppointmentStatus.arrived ||
                                status == AppointmentStatus.noShow)
                              const SizedBox(width: 8),
                            if (status == AppointmentStatus.arrived)
                              OutlinedButton(
                                onPressed: () async {
                                  try {
                                    await _apiService.updateAppointmentStatus(
                                        a['appt_id'], AppointmentStatus.inConsultation);
                                    if (!mounted) return;
                                    _fetchAppointments();
                                  } on ApiException catch (e) {
                                    if (!mounted) return;
                                    _showErrorDialog(e.message);
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                child: const Text('Start', style: TextStyle(fontSize: 11)),
                              ),
                            if (status == AppointmentStatus.arrived)
                              OutlinedButton(
                                onPressed: () async {
                                  try {
                                    await _apiService.updateAppointmentStatus(
                                        a['appt_id'], AppointmentStatus.noShow);
                                    if (!mounted) return;
                                    _fetchAppointments();
                                  } on ApiException catch (e) {
                                    if (!mounted) return;
                                    _showErrorDialog(e.message);
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                child: const Text('No-Show', style: TextStyle(fontSize: 11)),
                              ),
                            if (status != AppointmentStatus.cancelled &&
                                status != AppointmentStatus.completed &&
                                status != AppointmentStatus.inConsultation &&
                                status != AppointmentStatus.noShow) ...[
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => _openRescheduleDialog(a),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                child: const Text('Reschedule', style: TextStyle(fontSize: 11)),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton(
                                onPressed: () => _cancelAppointment(a['appt_id']),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red[600],
                                  side: BorderSide(color: Colors.red[200]!),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                ),
                                child: const Text('Cancel', style: TextStyle(fontSize: 11)),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarView(Map<String, Color> styles) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1)); // Monday
    final dates = List.generate(6, (i) => startOfWeek.add(Duration(days: i)));
    final dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    final todayStr = now.toIso8601String().split('T')[0];

    final dayAppts = <int, List<dynamic>>{};
    for (final a in _appointments) {
      final apptDate = (a['appt_date'] ?? '').toString().split('T')[0];
      for (int i = 0; i < dates.length; i++) {
        if (dates[i].toIso8601String().split('T')[0] == apptDate) {
          dayAppts.putIfAbsent(i, () => []).add(a);
          break;
        }
      }
    }

    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Schedule Flow: Weekly Overview', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Week of ${dates.first.toIso8601String().split('T')[0]}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: List.generate(dates.length, (index) {
                final dayName = dayNames[index];
                final dateStr = dates[index].toIso8601String().split('T')[0];
                final isToday = dateStr == todayStr;
                final apptsForDay = dayAppts[index] ?? [];

                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isToday ? const Color(0xFF0F766E).withOpacity(0.03) : Colors.transparent,
                      border: Border(
                        right: index < dates.length - 1
                            ? const BorderSide(color: Color(0xFFE2E8F0))
                            : BorderSide.none,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text(
                          '$dayName ${dates[index].day}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: isToday ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: apptsForDay.isEmpty
                              ? Center(
                                  child: Text('—', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                                )
                              : ListView.builder(
                                  itemCount: apptsForDay.length,
                                  itemBuilder: (context, idx) {
                                    final a = apptsForDay[idx];
                                    final status = '${a['status'] ?? ''}';
                                    final styleColor = styles[status] ?? const Color(0xFF64748B);

                                    return Container(
                                      margin: const.only(bottom: 8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: styleColor.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: styleColor.withOpacity(0.2)),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${a['appt_time'] ?? '--:--'}',
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: styleColor),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${a['patient']?['full_name'] ?? 'Patient'}',
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: styleColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(status, style: TextStyle(fontSize: 8, color: styleColor)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// --- MULTI-STEP WALK-IN INTAKE MODAL ---
class _WalkInIntakeModal extends StatefulWidget {
  final String? clinicId;
  final VoidCallback onComplete;
  const _WalkInIntakeModal({required this.clinicId, required this.onComplete});

  @override
  State<_WalkInIntakeModal> createState() => _WalkInIntakeModalState();
}

class _WalkInIntakeModalState extends State<_WalkInIntakeModal> {
  final ApiService _apiService = ApiService();
  int _currentStep = 0; // 0: Search, 1: Register, 2: Create Slot, 3: Success Token Card

  final _searchController = TextEditingController();
  List<dynamic> _foundPatients = [];
  bool _searchLoading = false;
  String? _searchError;
  Map<String, dynamic>? _selectedPatient;

  // New Registration fields
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController(text: "1990-01-01");
  final _mobileController = TextEditingController();
  final _addressController = TextEditingController(text: "Indore, MP");
  final _occupationController = TextEditingController(text: "Business");
  String _gender = "M";

  // Appointment fields
  String _visitType = VisitType.newVisit;
  String _generatedToken = "";
  bool _creating = false;

  Future<void> _searchPatients(String query) async {
    if (query.isEmpty) return;
    setState(() {
      _searchLoading = true;
      _searchError = null;
    });
    try {
      final res = await _apiService.getPatients(search: query);
      if (!mounted) return;
      setState(() {
        _foundPatients = res;
        _searchLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _searchError = e.message;
        _searchLoading = false;
      });
    }
  }

  Future<void> _registerPatient() async {
    if (_formKey.currentState!.validate()) {
      setState(() {});
      try {
        final res = await _apiService.createPatient({
          'full_name': _nameController.text.trim(),
          'dob': _dobController.text.trim(),
          'gender': _gender,
          'mobile': _mobileController.text.trim(),
          'address': _addressController.text.trim(),
          'occupation': _occupationController.text.trim(),
          'blood_group': 'O+',
        });
        if (!mounted) return;
        setState(() {
          _selectedPatient = res;
          _currentStep = 2; // Jump to Create Slot
        });
      } on ApiException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _createWalkInAppointment() async {
    if (_selectedPatient == null) return;
    if (_apiService.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to create walk-in appointments.'), backgroundColor: Colors.red),
      );
      return;
    }
    final timeStr = "${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}";
    final dateStr = DateTime.now().toIso8601String().split('T')[0];

    setState(() => _creating = true);
    try {
      final res = await _apiService.createAppointment({
        'patient_id': _selectedPatient!['patient_id'],
        'doctor_id': _apiService.userId!,
        'clinic_id': widget.clinicId,
        'appt_date': dateStr,
        'appt_time': timeStr,
        'visit_type': _visitType,
      });

      // Transition immediately to Waiting state ("Waiting" == Arrived)
      try {
        await _apiService.updateAppointmentStatus(res!['appt_id'], QueueColumn.waiting);
      } on ApiException {
        // Non-fatal: appointment exists even if the auto-transition fails.
      }

      if (!mounted) return;
      setState(() {
        // Use the server-assigned queue token (PRD §5.4.2)
        _generatedToken = "T-${res?['token_number'] ?? '--'}";
        _currentStep = 3; // Success Token
      });
      widget.onComplete();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Walk-In Patient Intake', style: TextStyle(fontWeight: FontWeight.bold)),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress Bar Indicator
            Row(
              children: List.generate(4, (index) {
                final active = index <= _currentStep;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 4,
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            _buildStepContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Search Patient Registry', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Enter name, mobile, or ID...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchPatients,
            ),
            const SizedBox(height: 12),
            if (_searchLoading)
              const Center(child: CircularProgressIndicator())
            else if (_searchError != null) ...[
              Text('Search failed: $_searchError', style: const TextStyle(color: Colors.red, fontSize: 11)),
              const SizedBox(height: 8),
            ] else if (_foundPatients.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _foundPatients.length,
                  itemBuilder: (context, idx) {
                    final p = _foundPatients[idx];
                    return ListTile(
                      dense: true,
                      title: Text(p['full_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Mobile: ${p['mobile'] ?? p['mobile_number'] ?? ''} · ID: ${p['unique_patient_id']}'),
                      trailing: const Icon(Icons.chevron_right, size: 16),
                      onTap: () {
                        setState(() {
                          _selectedPatient = p;
                          _currentStep = 2; // Jump to Create Slot
                        });
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _currentStep = 1),
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Register New Patient'),
              ),
            ),
          ],
        );
      case 1:
        return Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Register New Patient Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name *'),
                validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _mobileController,
                      decoration: const InputDecoration(labelText: 'Mobile Number *'),
                      validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      decoration: const InputDecoration(labelText: 'Gender *'),
                      items: const [
                        DropdownMenuItem(value: 'M', child: Text('Male')),
                        DropdownMenuItem(value: 'F', child: Text('Female')),
                      ],
                      onChanged: (val) => _gender = val ?? 'M',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(labelText: 'DOB (YYYY-MM-DD) *'),
                validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _currentStep = 0),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _registerPatient,
                      child: const Text('Save & Continue'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Confirm Walk-In Visit Slot', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedPatient?['full_name'] ?? 'Patient', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'ID: ${_selectedPatient?['unique_patient_id']}  ·  Phone: ${_selectedPatient?['mobile'] ?? _selectedPatient?['mobile_number'] ?? ''}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _visitType,
              decoration: const InputDecoration(labelText: 'Visit Type *'),
              items: const [
                DropdownMenuItem(value: VisitType.newVisit, child: Text('New Consultation')),
                DropdownMenuItem(value: VisitType.followUp, child: Text('Follow-Up Visit')),
              ],
              onChanged: (val) => _visitType = val ?? VisitType.newVisit,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _creating ? null : () => setState(() => _currentStep = 0),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _creating ? null : _createWalkInAppointment,
                    child: _creating
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Create Visit & Token'),
                  ),
                ),
              ],
            ),
          ],
        );
      case 3:
        return Column(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
            const SizedBox(height: 12),
            const Text(
              'Walk-In Successfully Registered!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E).withOpacity(0.04),
                border: Border.all(color: const Color(0xFF0F766E), width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'QUEUE TOKEN',
                    style: TextStyle(color: Color(0xFF64748B), letterSpacing: 2, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _generatedToken,
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFF0F766E)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_selectedPatient?['full_name']} · $_visitType',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 45)),
              child: const Text('Close Workspace'),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }
}
