import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class BillingInvoice extends StatefulWidget {
  final String? clinicId;
  const BillingInvoice({super.key, this.clinicId});

  @override
  State<BillingInvoice> createState() => _BillingInvoiceState();
}

class _BillingInvoiceState extends State<BillingInvoice> {
  final ApiService _apiService = ApiService();
  List<dynamic> _invoices = [];
  List<dynamic> _patients = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchInvoices();
    _fetchPatients();
  }

  Future<void> _fetchInvoices() async {
    setState(() => _isLoading = true);
    final results = await _apiService.getInvoices();
    setState(() {
      _invoices = results;
      _isLoading = false;
    });
  }

  Future<void> _fetchPatients() async {
    final results = await _apiService.getPatients();
    setState(() {
      _patients = results;
    });
  }

  void _openCreateInvoiceDialog() {
    final formKey = GlobalKey<FormState>();
    String? selectedPatientId;
    
    final consultationController = TextEditingController(text: "500.0");
    final medicineController = TextEditingController(text: "0.0");
    final miscController = TextEditingController(text: "0.0");
    final discountController = TextEditingController(text: "0.0");

    double totalAmount = 500.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void calculateTotal() {
              final cons = double.tryParse(consultationController.text) ?? 0.0;
              final med = double.tryParse(medicineController.text) ?? 0.0;
              final misc = double.tryParse(miscController.text) ?? 0.0;
              final disc = double.tryParse(discountController.text) ?? 0.0;
              
              setDialogState(() {
                totalAmount = cons + med + misc - disc;
              });
            }

            return AlertDialog(
              title: const Text('Create New Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: Container(
                  width: 450,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Select Patient
                      DropdownButtonFormField<String>(
                        value: selectedPatientId,
                        decoration: const InputDecoration(labelText: 'Select Patient *'),
                        items: _patients.map<DropdownMenuItem<String>>((p) {
                          return DropdownMenuItem<String>(
                            value: p['patient_id'],
                            child: Text(p['full_name']),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            selectedPatientId = val;
                          });
                        },
                        validator: (v) => v == null ? 'Please select a patient' : null,
                      ),
                      const SizedBox(height: 12),
                      
                      // Consultation Fee
                      TextFormField(
                        controller: consultationController,
                        decoration: const InputDecoration(labelText: 'Consultation Fee (₹) *'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => calculateTotal(),
                        validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                      ),
                      const SizedBox(height: 12),
                      
                      // Medicine Charges
                      TextFormField(
                        controller: medicineController,
                        decoration: const InputDecoration(labelText: 'Medicine Charges (₹) *'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => calculateTotal(),
                        validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                      ),
                      const SizedBox(height: 12),
                      
                      // Misc Charges
                      TextFormField(
                        controller: miscController,
                        decoration: const InputDecoration(labelText: 'Miscellaneous Charges (₹)'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => calculateTotal(),
                      ),
                      const SizedBox(height: 12),
                      
                      // Discount
                      TextFormField(
                        controller: discountController,
                        decoration: const InputDecoration(labelText: 'Discount / Waiver (₹)'),
                        keyboardType: TextInputType.number,
                        onChanged: (_) => calculateTotal(),
                      ),
                      const SizedBox(height: 16),
                      
                      // Total Highlight
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
                            const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text('₹${totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F766E))),
                          ],
                        ),
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
                  onPressed: () async {
                    if (formKey.currentState!.validate() && selectedPatientId != null) {
                      final result = await _apiService.createInvoice({
                        'patient_id': selectedPatientId,
                        'consultation_fee': double.tryParse(consultationController.text) ?? 0.0,
                        'medicine_charges': double.tryParse(medicineController.text) ?? 0.0,
                        'misc_charges': double.tryParse(miscController.text) ?? 0.0,
                        'discount': double.tryParse(discountController.text) ?? 0.0,
                      });
                      if (result != null) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Draft invoice created successfully.')),
                        );
                        _fetchInvoices();
                      }
                    }
                  },
                  child: const Text('Save Draft'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openPaymentDialog(Map<String, dynamic> inv) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(text: inv['due_amount'].toString());
    final txController = TextEditingController();
    
    String mode = "UPI"; // Cash, Card, UPI, Online

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Collect Payment: Invoice #${inv['invoice_id'].substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total: ₹${inv['total_amount']}  ·  Due: ₹${inv['due_amount']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount to Pay (₹) *'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required field';
                    final amt = double.tryParse(v) ?? 0.0;
                    if (amt <= 0) return 'Must be greater than 0';
                    if (amt > inv['due_amount']) return 'Cannot exceed due amount';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: mode,
                  decoration: const InputDecoration(labelText: 'Payment Mode *'),
                  items: const [
                    DropdownMenuItem(value: 'UPI', child: Text('UPI / QR Code')),
                    DropdownMenuItem(value: 'Cash', child: Text('Cash Payment')),
                    DropdownMenuItem(value: 'Card', child: Text('POS Card Swipe')),
                    DropdownMenuItem(value: 'Online', child: Text('Razorpay Gateway')),
                  ],
                  onChanged: (val) => mode = val ?? 'UPI',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: txController,
                  decoration: const InputDecoration(labelText: 'Transaction ID / Ref (Optional)'),
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
                  final result = await _apiService.recordPayment(
                    inv['invoice_id'],
                    double.parse(amountController.text),
                    mode,
                    txId: txController.text.isNotEmpty ? txController.text.trim() : null,
                  );
                  if (result != null) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Payment of ₹${amountController.text} recorded successfully.')),
                    );
                    _fetchInvoices();
                  }
                }
              },
              child: const Text('Record Pay'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _issueInvoice(String invoiceId) async {
    final result = await _apiService.issueInvoice(invoiceId);
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice issued successfully.')),
      );
      _fetchInvoices();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Summarize invoices
    double totalPaid = 0.0;
    double totalDue = 0.0;
    int paidCount = 0;
    int unpaidCount = 0;

    for (var inv in _invoices) {
      totalPaid += inv['paid_amount'];
      totalDue += inv['due_amount'];
      if (inv['status'] == 'Paid') {
        paidCount++;
      } else {
        unpaidCount++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing & Invoicing Panel'),
        actions: [
          ElevatedButton.icon(
            onPressed: _openCreateInvoiceDialog,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Invoice'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Row
            Row(
              children: [
                Expanded(
                  child: _buildBillingStatCard(
                    title: "Total Paid",
                    value: "₹${totalPaid.toStringAsFixed(0)}",
                    hint: "$paidCount Invoices Settled",
                    icon: Icons.check_circle_outline,
                    color: Colors.green[700]!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildBillingStatCard(
                    title: "Total Due Outstanding",
                    value: "₹${totalDue.toStringAsFixed(0)}",
                    hint: "$unpaidCount Invoices Outstanding",
                    icon: Icons.error_outline,
                    color: Colors.red[700]!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Invoices Listing
            const Text(
              "Recent Transactions & Invoices",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _invoices.isEmpty
                      ? const Center(child: Text('No invoices recorded yet.'))
                      : Card(
                          child: ListView.separated(
                            itemCount: _invoices.length,
                            separatorBuilder: (context, index) => const Divider(color: Color(0xFFE2E8F0)),
                            itemBuilder: (context, index) {
                              final inv = _invoices[index];
                              final patientName = inv['patient']?['full_name'] ?? 'Walk-In';
                              final total = inv['total_amount'];
                              final due = inv['due_amount'];
                              final status = inv['status'];
                              final invId = inv['invoice_id'].substring(0, 8).toUpperCase();
                              
                              return ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFFF1F5F9),
                                  child: Icon(Icons.receipt_outlined, color: Color(0xFF475569)),
                                ),
                                title: Text(
                                  'Invoice #$invId — Patient: $patientName',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                subtitle: Text(
                                  'Total: ₹$total  ·  Due: ₹$due  ·  Status: $status',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (status == 'Draft')
                                      TextButton(
                                        onPressed: () => _issueInvoice(inv['invoice_id']),
                                        child: const Text('Issue'),
                                      ),
                                    if (status == 'Issued' || status == 'Partially Paid')
                                      ElevatedButton(
                                        onPressed: () => _openPaymentDialog(inv),
                                        child: const Text('Pay'),
                                      ),
                                    if (status == 'Paid')
                                      const Icon(Icons.verified, color: Colors.green, size: 20),
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

  Widget _buildBillingStatCard({
    required String title,
    required String value,
    required String hint,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                Text(
                  hint,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
