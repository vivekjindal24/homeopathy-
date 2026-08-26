import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class PaymentsManagement extends StatefulWidget {
  final String? clinicId;
  const PaymentsManagement({super.key, this.clinicId});

  @override
  State<PaymentsManagement> createState() => _PaymentsManagementState();
}

class _PaymentsManagementState extends State<PaymentsManagement> {
  final ApiService _apiService = ApiService();
  List<dynamic> _invoices = [];
  List<dynamic> _paymentsList = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPaymentsData();
  }

  @override
  void didUpdateWidget(covariant PaymentsManagement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clinicId != widget.clinicId) {
      _fetchPaymentsData();
    }
  }

  Future<void> _fetchPaymentsData() async {
    setState(() => _isLoading = true);
    final invoices = await _apiService.getInvoices();
    
    // Flatten payments from invoices
    final List<dynamic> localPayments = [];
    for (var inv in invoices) {
      final payments = inv['payments'] ?? [];
      final patientName = inv['patient']?['full_name'] ?? 'Walk-In';
      
      for (var pay in payments) {
        localPayments.add({
          'payment_id': pay['payment_id'],
          'invoice_id': inv['invoice_id'],
          'patient_name': patientName,
          'amount': pay['amount'],
          'payment_mode': pay['payment_mode'],
          'transaction_id': pay['transaction_id'] ?? '—',
          'paid_at': pay['paid_at'] ?? inv['updated_at'] ?? '—',
          'status': pay['status'] ?? 'Success',
        });
      }
    }

    // Sort by date (descending)
    localPayments.sort((a, b) => b['paid_at'].toString().compareTo(a['paid_at'].toString()));

    setState(() {
      _invoices = invoices;
      _paymentsList = localPayments;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Financial breakdowns
    double totalRevenue = 0.0;
    double cashRev = 0.0;
    double upiRev = 0.0;
    double cardRev = 0.0;

    for (var p in _paymentsList) {
      final amt = (p['amount'] as num).toDouble();
      totalRevenue += amt;
      if (p['payment_mode'] == 'Cash') {
        cashRev += amt;
      } else if (p['payment_mode'] == 'UPI') {
        upiRev += amt;
      } else if (p['payment_mode'] == 'Card') {
        cardRev += amt;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Payments Ledger & Collections'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchPaymentsData),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard("Total Collected", "₹${totalRevenue.toStringAsFixed(0)}", Icons.account_balance_wallet_outlined, const Color(0xFF0F766E), const Color(0xFFECFDF5)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricCard("UPI Payments", "₹${upiRev.toStringAsFixed(0)}", Icons.qr_code_scanner_rounded, Colors.purple[700]!, Colors.purple[50]!),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricCard("Cash Collection", "₹${cashRev.toStringAsFixed(0)}", Icons.payments_outlined, Colors.green[700]!, const Color(0xFFECFDF5)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildMetricCard("Card Collections", "₹${cardRev.toStringAsFixed(0)}", Icons.credit_card_rounded, Colors.blue[700]!, Colors.blue[50]!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Payments Table Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Transaction History Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                          const SizedBox(height: 12),
                          if (_paymentsList.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Center(child: Text('No payment transactions recorded yet.', style: TextStyle(fontStyle: FontStyle.italic))),
                            )
                          else
                            Table(
                              columnWidths: const {
                                0: FlexColumnWidth(1.2),
                                1: FlexColumnWidth(1.8),
                                2: FlexColumnWidth(1.2),
                                3: FlexColumnWidth(1.0),
                                4: FlexColumnWidth(1.5),
                                5: FlexColumnWidth(1.2),
                              },
                              children: [
                                TableRow(
                                  decoration: const BoxDecoration(
                                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                                  ),
                                  children: [
                                    _buildTableHeader("Receipt ID"),
                                    _buildTableHeader("Patient Name"),
                                    _buildTableHeader("Mode"),
                                    _buildTableHeader("Amount"),
                                    _buildTableHeader("Transaction ID"),
                                    _buildTableHeader("Timestamp"),
                                  ],
                                ),
                                ..._paymentsList.map((p) {
                                  final pId = p['payment_id'].toString().substring(0, 8).toUpperCase();
                                  final double amt = (p['amount'] as num).toDouble();
                                  
                                  // Formatting timestamp
                                  String timeStr = p['paid_at'].toString().split('.').first;
                                  if (timeStr.contains('T')) {
                                    final parts = timeStr.split('T');
                                    timeStr = "${parts[0]} ${parts[1]}";
                                  }

                                  return TableRow(
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                                        child: Text('RCP-$pId', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                                        child: Text(p['patient_name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                                        child: _buildModePill(p['payment_mode']),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                                        child: Text('₹${amt.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                                        child: Text(p['transaction_id'], style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                                        child: Text(timeStr, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, Color bg) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModePill(String mode) {
    Color bg = const Color(0xFFF1F5F9);
    Color fg = const Color(0xFF475569);

    if (mode == 'UPI') {
      bg = Colors.purple[50]!;
      fg = Colors.purple[700]!;
    } else if (mode == 'Cash') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF047857);
    } else if (mode == 'Card') {
      bg = Colors.blue[50]!;
      fg = Colors.blue[700]!;
    }

    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          mode,
          style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
