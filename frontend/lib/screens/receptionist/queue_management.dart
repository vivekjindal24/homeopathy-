import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'billing_invoice.dart';

class QueueManagement extends StatefulWidget {
  final String? clinicId;
  final String dateStr;
  const QueueManagement({super.key, this.clinicId, required this.dateStr});

  @override
  State<QueueManagement> createState() => _QueueManagementState();
}

class _QueueManagementState extends State<QueueManagement> {
  final ApiService _apiService = ApiService();
  List<dynamic> _appointments = [];
  bool _isLoading = false;
  
  // Track waiver eligibility for waiting patients
  final Map<String, bool> _waiverEligible = {};

  @override
  void initState() {
    super.initState();
    _fetchQueue();
  }

  Future<void> _fetchQueue() async {
    if (widget.clinicId == null) return;
    setState(() => _isLoading = true);
    
    final results = await _apiService.getAppointments(clinicId: widget.clinicId, date: widget.dateStr);
    
    setState(() {
      _appointments = results;
      _isLoading = false;
    });

    // Check waiver eligibility for waiting patients
    for (var a in results) {
      if (a['status'] == 'Arrived' || a['status'] == 'Waiting') {
        _checkWaiver(a['patient_id']);
      }
    }
  }

  Future<void> _checkWaiver(String patientId) async {
    if (_waiverEligible.containsKey(patientId)) return;
    final eligible = await _apiService.check7dayWaiver(patientId, widget.dateStr);
    setState(() {
      _waiverEligible[patientId] = eligible;
    });
  }

  Future<void> _transitionStatus(String apptId, String nextStatus) async {
    try {
      await _apiService.updateAppointmentStatus(apptId, nextStatus);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Queue status updated to $nextStatus.')),
      );
      _fetchQueue();
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Single Consultation Block'),
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.clinicId == null) {
      return const Center(child: Text('Please select a clinic first.'));
    }

    // Filter appointments into states
    final waiting = _appointments.where((a) => a['status'] == 'Arrived' || a['status'] == 'Waiting').toList();
    final inConsultation = _appointments.where((a) => a['status'] == 'In Consultation').toList();
    final completed = _appointments.where((a) => a['status'] == 'Completed').toList();
    final noShow = _appointments.where((a) => a['status'] == 'No-Show' || a['status'] == 'Cancelled').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Queue Management Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchQueue,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Waiting Column
                  Expanded(
                    child: _buildQueueColumn(
                      title: "Waiting Queue",
                      count: waiting.length,
                      color: Colors.teal[700]!,
                      items: waiting,
                      buildItemCard: (appt) => _buildPatientCard(appt, isWaiting: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // In Consultation Column
                  Expanded(
                    child: _buildQueueColumn(
                      title: "In Consultation",
                      count: inConsultation.length,
                      color: Colors.purple[700]!,
                      items: inConsultation,
                      buildItemCard: (appt) => _buildPatientCard(appt, isInConsultation: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Completed Column
                  Expanded(
                    child: _buildQueueColumn(
                      title: "Completed Visits",
                      count: completed.length,
                      color: Colors.green[700]!,
                      items: completed,
                      buildItemCard: (appt) => _buildPatientCard(appt, isCompleted: true),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // No-Show Column
                  Expanded(
                    child: _buildQueueColumn(
                      title: "No-Show / Cancelled",
                      count: noShow.length,
                      color: Colors.red[700]!,
                      items: noShow,
                      buildItemCard: (appt) => _buildPatientCard(appt, isNoShow: true),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildQueueColumn({
    required String title,
    required int count,
    required Color color,
    required List<dynamic> items,
    required Widget Function(dynamic) buildItemCard,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Column Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Cards List
        Expanded(
          child: items.isEmpty
              ? Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.none), // Custom dash border concept
                  ),
                  child: Center(
                    child: Text(
                      'Empty',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13, fontStyle: FontStyle.italic),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) => buildItemCard(items[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildPatientCard(
    dynamic appt, {
    bool isWaiting = false,
    bool isInConsultation = false,
    bool isCompleted = false,
    bool isNoShow = false,
  }) {
    final patient = appt['patient'] ?? {};
    final patientName = patient['full_name'] ?? 'Walk-In';
    final patientId = appt['patient_id'];
    final uniqueId = patient['unique_patient_id'] ?? '—';
    final time = appt['appt_time'];
    final type = appt['visit_type'];
    
    final hasWaiver = _waiverEligible[patientId] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  time,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F766E)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    type,
                    style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              patientName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
            ),
            Text(
              'ID: $uniqueId',
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            
            // Waiver Highlight
            if (isWaiting && hasWaiver) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.stars, color: Colors.amber, size: 14),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Eligible for 7-Day Fee Waiver',
                        style: TextStyle(color: Color(0xFF92400E), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Quick action buttons
            if (isWaiting) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: () => _transitionStatus(appt['appt_id'], 'No-Show'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      side: BorderSide(color: Colors.red[200]!),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    child: const Text('No-Show', style: TextStyle(fontSize: 11)),
                  ),
                  ElevatedButton(
                    onPressed: () => _transitionStatus(appt['appt_id'], 'In Consultation'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Start Visit', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ],
            if (isInConsultation) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _transitionStatus(appt['appt_id'], 'Completed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Mark Completed', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
            if (isCompleted) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to billing with selected patient/appointment
                    // In a production app, state management would be used.
                    // For this prototype, we show a success dialog or launch a billing hook
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Billing Action Handoff'),
                        content: Text('Handoff patient $patientName to Invoice generation.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Simple notification to receptionist
                            },
                            child: const Text('Generate Invoice'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_outlined, size: 14),
                  label: const Text('Process Billing', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
