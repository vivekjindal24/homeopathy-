import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/shared_widgets.dart';
import '../../services/api_service.dart';

/// PRD §5.4.3/§5.4.5 — working invoice creation + issuance + payment hook.
///
/// Used by the queue board ("Process Billing") and reusable from the
/// receptionist dashboard billing tab. When [patientId] is null a patient
/// picker is shown. If [waiverEligible] is true the consultation fee defaults
/// to ₹0 (7-day fee waiver), otherwise ₹500.
Future<void> showProcessBillingDialog(
  BuildContext context, {
  required ApiService api,
  String? patientId,
  String? patientName,
  String? apptId,
  bool waiverEligible = false,
  VoidCallback? onDone,
}) async {
  List<dynamic> patients = [];
  String? selectedPatientId = patientId;

  if (patientId == null) {
    try {
      patients = await api.getPatients();
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
      return;
    }
    if (patients.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No patients registered yet.'),
        backgroundColor: Colors.red,
      ));
      return;
    }
  }

  if (!context.mounted) return;
  await showDialog(
    context: context,
    builder: (dialogCtx) {
      final consController =
          TextEditingController(text: waiverEligible ? '0' : '500');
      final medController = TextEditingController(text: '0');
      final miscController = TextEditingController(text: '0');
      final discController = TextEditingController(text: '0');
      double total = waiverEligible ? 0 : 500;
      bool submitting = false;

      void recalc(void Function(void Function()) setD) {
        setD(() {
          total = parseAmount(consController.text) +
              parseAmount(medController.text) +
              parseAmount(miscController.text) -
              parseAmount(discController.text);
        });
      }

      NumberInput field(String label, TextEditingController c,
              {required void Function() onChanged}) =>
          NumberInput(label: label, controller: c, onChanged: onChanged);

      return StatefulBuilder(builder: (ctx, setD) {
        return AlertDialog(
          title: const Text('Create & Issue Invoice',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (patientId != null)
                  Text(patientName ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14))
                else
                  DropdownButtonFormField<String>(
                    value: selectedPatientId,
                    decoration: const InputDecoration(
                        labelText: 'Select Patient *'),
                    items: patients.map<DropdownMenuItem<String>>((p) {
                      return DropdownMenuItem<String>(
                        value: p['patient_id'],
                        child: Text('${p['full_name']} (${p['mobile'] ?? ''})'),
                      );
                    }).toList(),
                    onChanged: (v) => setD(() => selectedPatientId = v),
                  ),
                if (waiverEligible) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.amber[200]!),
                    ),
                    child: const Row(children: [
                      Icon(Icons.stars, color: Colors.amber, size: 14),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text('7-Day Fee Waiver applied (₹0 consult)',
                            style: TextStyle(
                                color: Color(0xFF92400E),
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ]),
                  ),
                ],
                const SizedBox(height: 12),
                field('Consultation Fee (₹)', consController,
                    onChanged: () => recalc(setD)),
                const SizedBox(height: 10),
                field('Medicine Charges (₹)', medController,
                    onChanged: () => recalc(setD)),
                const SizedBox(height: 10),
                field('Misc Charges (₹)', miscController,
                    onChanged: () => recalc(setD)),
                const SizedBox(height: 10),
                field('Discount / Waiver (₹)', discController,
                    onChanged: () => recalc(setD)),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('₹${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF0F766E))),
                      ]),
                ),
                if (submitting) ...[
                  const SizedBox(height: 12),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  submitting ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: submitting ||
                      (patientId == null && selectedPatientId == null)
                  ? null
                  : () async {
                      setD(() => submitting = true);
                      try {
                        final created = await api.createInvoice({
                          'patient_id': selectedPatientId,
                          if (apptId != null) 'appt_id': apptId,
                          'consultation_fee':
                              parseAmount(consController.text),
                          'medicine_charges': parseAmount(medController.text),
                          'misc_charges': parseAmount(miscController.text),
                          'discount': parseAmount(discController.text),
                        });
                        final invoiceId = created['invoice_id'];
                        await api.issueInvoice(invoiceId);
                        if (!ctx.mounted) return;
                        Navigator.pop(dialogCtx);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'Invoice #${shortId(invoiceId)} issued.')));
                        final inv = await api.getInvoice(invoiceId);
                        if (context.mounted &&
                            parseAmount(inv['due_amount']) > 0) {
                          final paidNow =
                              await showRecordPaymentDialog(
                                  context, api, inv);
                          if (paidNow && onDone != null) onDone();
                        }
                        if (onDone != null) onDone();
                      } on ApiException catch (e) {
                        if (!ctx.mounted) return;
                        setD(() => submitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(e.message),
                            backgroundColor: Colors.red));
                      }
                    },
              child: const Text('Create & Issue'),
            ),
          ],
        );
      });
    },
  );
}

/// Returns true when a payment was successfully recorded.
/// Only offered on Issued / Partially Paid invoices; server rejects overpay.
Future<bool> showRecordPaymentDialog(
  BuildContext context,
  ApiService api,
  Map<String, dynamic> inv,
) async {
  final due = parseAmount(inv['due_amount']);
  final amountCtrl = TextEditingController(text: due.toStringAsFixed(2));
  final txCtrl = TextEditingController();
  String mode = PaymentMode.cash;
  bool submitting = false;

  if (!context.mounted) return false;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (ctx, setD) => AlertDialog(
        title: Text('Collect Payment · #${shortId(inv['invoice_id'])}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Total: ₹${parseAmount(inv['total_amount']).toStringAsFixed(0)}  ·  Due: ₹${due.toStringAsFixed(0)}',
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount (₹) *'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: mode,
              decoration: const InputDecoration(labelText: 'Payment Mode *'),
              items: PaymentMode.all
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setD(() => mode = v ?? PaymentMode.cash),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: txCtrl,
              decoration: const InputDecoration(
                  labelText: 'Transaction ID / Ref (Optional)'),
            ),
            if (submitting) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: submitting ? null : () => Navigator.pop(dialogCtx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: submitting
                ? null
                : () async {
                    final amt = parseAmount(amountCtrl.text);
                    if (amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Enter an amount greater than 0.'),
                          backgroundColor: Colors.red));
                      return;
                    }
                    if (amt > due + 0.001) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Cannot exceed due amount ₹${due.toStringAsFixed(2)}.'),
                          backgroundColor: Colors.red));
                      return;
                    }
                    setD(() => submitting = true);
                    try {
                      await api.recordPayment(inv['invoice_id'], amt, mode,
                          txId: txCtrl.text.trim().isNotEmpty
                              ? txCtrl.text.trim()
                              : null);
                      if (!ctx.mounted) return;
                      Navigator.pop(dialogCtx, true);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'Payment of ₹${amt.toStringAsFixed(0)} recorded.')));
                    } on ApiException catch (e) {
                      if (!ctx.mounted) return;
                      setD(() => submitting = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(e.message),
                          backgroundColor: Colors.red));
                    }
                  },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    ),
  );
  return result == true;
}

class NumberInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final VoidCallback onChanged;
  const NumberInput(
      {super.key,
      required this.label,
      required this.controller,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }
}

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
  String? _error;

  // Track waiver eligibility for waiting patients
  final Map<String, bool> _waiverEligible = {};

  @override
  void initState() {
    super.initState();
    _fetchQueue();
  }

  Future<void> _fetchQueue() async {
    if (widget.clinicId == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _waiverEligible.clear();
    });

    try {
      final results = await _apiService.getAppointments(
          clinicId: widget.clinicId, date: widget.dateStr);
      if (!mounted) return;
      setState(() {
        _appointments = results;
        _isLoading = false;
      });

      // Check waiver eligibility for waiting patients
      for (var a in results) {
        if (a['status'] == AppointmentStatus.arrived) {
          _checkWaiver(a['patient_id']);
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _checkWaiver(String patientId) async {
    if (_waiverEligible.containsKey(patientId)) return;
    try {
      final eligible =
          await _apiService.check7dayWaiver(patientId, widget.dateStr);
      if (!mounted) return;
      setState(() {
        _waiverEligible[patientId] = eligible;
      });
    } on ApiException {
      // Waiver is an enhancement signal only — treat failure as ineligible.
      if (!mounted) return;
      _waiverEligible[patientId] = false;
    }
  }

  Future<void> _transitionStatus(String apptId, String nextStatus) async {
    try {
      final updated = await _apiService.updateAppointmentStatus(apptId, nextStatus);
      if (!mounted) return;
      setState(() {
        final idx = _appointments.indexWhere((a) => a['appt_id'] == apptId);
        if (idx != -1) _appointments[idx] = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Queue status updated to $nextStatus.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Update Status'),
          content: Text(e.message),
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

    // Filter appointments into states ("Waiting" column == Arrived, §5.4.1)
    final waiting = _appointments
        .where((a) => a['status'] == QueueColumn.waiting)
        .toList();
    final inConsultation = _appointments
        .where((a) => a['status'] == QueueColumn.inConsultation)
        .toList();
    final completed = _appointments
        .where((a) => a['status'] == QueueColumn.completed)
        .toList();
    final noShow = _appointments
        .where(
            (a) => a['status'] == QueueColumn.noShow || a['status'] == AppointmentStatus.cancelled)
        .toList();

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
      body: _error != null
          ? _buildErrorState()
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 700) {
                        return Wrap(
                          spacing: 16, runSpacing: 16,
                          children: [
                            SizedBox(
                              width: constraints.maxWidth,
                              child: _buildQueueColumn(
                                title: "Waiting Queue",
                                count: waiting.length,
                                color: Colors.teal[700]!,
                                items: waiting,
                                buildItemCard: (appt) =>
                                    _buildPatientCard(appt, isWaiting: true),
                              ),
                            ),
                            SizedBox(
                              width: constraints.maxWidth,
                              child: _buildQueueColumn(
                                title: AppointmentStatus.inConsultation,
                                count: inConsultation.length,
                                color: Colors.purple[700]!,
                                items: inConsultation,
                                buildItemCard: (appt) =>
                                    _buildPatientCard(appt, isInConsultation: true),
                              ),
                            ),
                            SizedBox(
                              width: constraints.maxWidth,
                              child: _buildQueueColumn(
                                title: "Completed Visits",
                                count: completed.length,
                                color: Colors.green[700]!,
                                items: completed,
                                buildItemCard: (appt) =>
                                    _buildPatientCard(appt, isCompleted: true),
                              ),
                            ),
                            SizedBox(
                              width: constraints.maxWidth,
                              child: _buildQueueColumn(
                                title: "No-Show / Cancelled",
                                count: noShow.length,
                                color: Colors.red[700]!,
                                items: noShow,
                                buildItemCard: (appt) =>
                                    _buildPatientCard(appt, isNoShow: true),
                              ),
                            ),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Waiting Column
                          Expanded(
                            child: _buildQueueColumn(
                              title: "Waiting Queue",
                              count: waiting.length,
                              color: Colors.teal[700]!,
                              items: waiting,
                              buildItemCard: (appt) =>
                                  _buildPatientCard(appt, isWaiting: true),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // In Consultation Column
                          Expanded(
                            child: _buildQueueColumn(
                              title: AppointmentStatus.inConsultation,
                              count: inConsultation.length,
                              color: Colors.purple[700]!,
                              items: inConsultation,
                              buildItemCard: (appt) =>
                                  _buildPatientCard(appt, isInConsultation: true),
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
                              buildItemCard: (appt) =>
                                  _buildPatientCard(appt, isCompleted: true),
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
                              buildItemCard: (appt) =>
                                  _buildPatientCard(appt, isNoShow: true),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 40, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text('Failed to load queue\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _fetchQueue,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
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
                    border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.none),
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
    final time = '${appt['appt_time'] ?? '--:--'}';
    final type = '${appt['visit_type'] ?? 'Visit'}';
    final token = appt['token_number'];

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
                  token != null ? 'T-$token · $time' : time,
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
                    onPressed: () => _transitionStatus(
                        appt['appt_id'], AppointmentStatus.noShow),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      side: BorderSide(color: Colors.red[200]!),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    child: const Text('No-Show', style: TextStyle(fontSize: 11)),
                  ),
                  ElevatedButton(
                    onPressed: () => _transitionStatus(
                        appt['appt_id'], AppointmentStatus.inConsultation),
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
                  onPressed: () => _transitionStatus(
                      appt['appt_id'], AppointmentStatus.completed),
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
                  onPressed: () => showProcessBillingDialog(
                    context,
                    api: _apiService,
                    patientId: patientId,
                    patientName: patientName,
                    apptId: appt['appt_id'],
                    waiverEligible: hasWaiver,
                    onDone: _fetchQueue,
                  ),
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
