import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/shared_widgets.dart';
import '../../services/api_service.dart';

class ReportsManagement extends StatefulWidget {
  final String? clinicId;
  const ReportsManagement({super.key, this.clinicId});

  @override
  State<ReportsManagement> createState() => _ReportsManagementState();
}

class _ReportsManagementState extends State<ReportsManagement> {
  final ApiService _api = ApiService();
  bool _loading = true;
  String? _error;

  List<dynamic> _invoices = [];
  List<Map<String, dynamic>> _revenueData = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() { _loading = true; _error = null; });
    try {
      final invoices = await _api.getInvoices().catchError((_) => <dynamic>[]);
      if (!mounted) return;
      setState(() {
        _invoices = invoices;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalCollected = 0;
    int totalAppointments = 0;
    int completedAppointments = 0;
    int pendingDuesCount = 0;

    // Aggregate from invoices
    final Map<String, double> dailyRevenue = {};
    for (final inv in _invoices) {
      final dueAmt = parseAmount(inv['due_amount']);
      if (dueAmt > 0) pendingDuesCount++;
      totalAppointments++;
      final status = '${inv['status'] ?? ''}';
      if (status == 'Paid') completedAppointments++;
      // Revenue by day from payments
      for (final p in (inv['payments'] as List? ?? [])) {
        final paidAt = '${p['paid_at'] ?? ''}';
        if (paidAt.length >= 10) {
          final day = paidAt.substring(0, 10);
          final amt = parseAmount(p['amount']);
          dailyRevenue[day] = (dailyRevenue[day] ?? 0) + amt;
        }
      }
    }

    // Sort revenue data by date
    final sortedDays = dailyRevenue.keys.toList()..sort();
    _revenueData = sortedDays.map((d) => {'date': d, 'revenue': dailyRevenue[d]}).toList();

    for (final inv in _invoices) {
      final dueAmt = parseAmount(inv['due_amount']);
      if (dueAmt > 0) pendingDuesCount++;
    }

    // Aggregate payment modes from real data
    final Map<String, double> modeTotals = {};
    for (final inv in _invoices) {
      for (final p in (inv['payments'] as List? ?? [])) {
        final mode = '${p['payment_mode'] ?? 'Unknown'}';
        final amt = parseAmount(p['amount']);
        modeTotals[mode] = (modeTotals[mode] ?? 0) + amt;
        totalCollected += amt;
      }
    }
    final modeColors = {
      'UPI': Colors.purple[400]!,
      'Cash': const Color(0xFF10B981),
      'Card': Colors.blue[400]!,
      'Online': Colors.teal[400]!,
    };
    final modeCollections = modeTotals.entries.map((e) => {
      'name': e.key,
      'value': e.value,
      'color': modeColors[e.key] ?? Colors.grey[400]!,
    }).toList();

    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(title: const Text('Reports & Analytics'), backgroundColor: Colors.white, surfaceTintColor: Colors.white),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(title: const Text('Reports & Analytics'), backgroundColor: Colors.white, surfaceTintColor: Colors.white),
        body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.slate400),
          const SizedBox(height: 12),
          Text('Failed to load reports\n$_error', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: _fetchReports, icon: const Icon(Icons.refresh_rounded, size: 16), label: const Text('Retry'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white)),
        ])),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Day-End Operations Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                    Text('Operational snapshot', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
                Text(
                  DateTime.now().toLocal().toString().split(' ').first,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Metric boxes
            Row(
              children: [
                Expanded(child: _buildMetricCard("Total Collected", "₹${totalCollected.toStringAsFixed(0)}", Colors.green[700]!)),
                const SizedBox(width: 14),
                Expanded(child: _buildMetricCard("Appointments (30d)", "$totalAppointments", const Color(0xFF0F766E))),
                const SizedBox(width: 14),
                Expanded(child: _buildMetricCard("Completed", "$completedAppointments", const Color(0xFF059669))),
                const SizedBox(width: 14),
                Expanded(child: _buildMetricCard("Pending Invoices", "$pendingDuesCount", Colors.amber[700]!)),
              ],
            ),
            const SizedBox(height: 24),

            // Charts Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Revenue Trend
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Revenue Trend (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          const Text('Daily revenue over last 30 days', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: _revenueData.isEmpty
                                ? const Center(child: Text('No revenue data yet', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))))
                                : _buildRevenueBarChart(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Collections pie chart
                Expanded(
                  flex: 1,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Collection by Payment Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('Total: ₹${totalCollected.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 24),
                          if (modeCollections.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: Text('No payments recorded', style: TextStyle(fontSize: 11, color: Color(0xFF64748B)))),
                            )
                          else
                            ...modeCollections.map((m) {
                              final double share = totalCollected == 0 ? 0 : ((m['value'] as double) / totalCollected) * 100;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  children: [
                                    Container(width: 10, height: 10, decoration: BoxDecoration(color: m['color'] as Color, shape: BoxShape.circle)),
                                    const SizedBox(width: 8),
                                    Text(m['name'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                    const Spacer(),
                                    Text('₹${(m['value'] as double).toStringAsFixed(0)} (${share.toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueBarChart() {
    // Show up to last 14 days of revenue data
    final displayData = _revenueData.length > 14 ? _revenueData.sublist(_revenueData.length - 14) : _revenueData;
    final maxVal = displayData.fold<double>(0, (max, p) {
      final rev = parseAmount(p['revenue']);
      return rev > max ? rev : max;
    });
    if (maxVal == 0) return const Center(child: Text('No data', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: displayData.map((p) {
        final rev = parseAmount(p['revenue']);
        final day = '${p['date'] ?? ''}';
        final label = day.length >= 10 ? day.substring(8, 10) : day;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Tooltip(
                message: '₹${rev.toStringAsFixed(0)}',
                child: Container(
                  height: (rev / maxVal) * 180,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.85),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B))),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }
}
