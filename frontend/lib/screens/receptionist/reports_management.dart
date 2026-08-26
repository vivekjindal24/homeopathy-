import 'package:flutter/material.dart';
import '../components/charts.dart';
import '../../services/api_service.dart';

class ReportsManagement extends StatefulWidget {
  final String? clinicId;
  const ReportsManagement({super.key, this.clinicId});

  @override
  State<ReportsManagement> createState() => _ReportsManagementState();
}

class _ReportsManagementState extends State<ReportsManagement> {
  final List<Map<String, dynamic>> _weeklyRevenue = [
    { "day": "Mon", "revenue": 14200.0 },
    { "day": "Tue", "revenue": 16800.0 },
    { "day": "Wed", "revenue": 12500.0 },
    { "day": "Thu", "revenue": 18450.0 },
    { "day": "Fri", "revenue": 20100.0 },
    { "day": "Sat", "revenue": 9800.0 },
  ];

  final List<Map<String, dynamic>> _modeCollections = [
    { "name": "UPI", "value": 6400.0, "color": Colors.purple[400]! },
    { "name": "Cash", "value": 8200.0, "color": const Color(0xFF10B981) },
    { "name": "Card", "value": 3850.0, "color": Colors.blue[400]! },
  ];

  @override
  Widget build(BuildContext context) {
    // Total calculation
    double totalCollected = 0.0;
    for (var m in _modeCollections) {
      totalCollected += m['value'];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF report exported successfully.')),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title block
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Day-End Operations Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                    Text('Operational snapshot for Vijay Nagar branch', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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
                Expanded(child: _buildMetricCard("Today's Revenue", "₹18,450", Colors.green[700]!)),
                const SizedBox(width: 14),
                Expanded(child: _buildMetricCard("Total Collections", "₹${totalCollected.toStringAsFixed(0)}", const Color(0xFF0F766E))),
                const SizedBox(width: 14),
                Expanded(child: _buildMetricCard("Outstanding Dues", "₹5,200", Colors.red[700]!)),
                const SizedBox(width: 14),
                Expanded(child: _buildMetricCard("Refund Requests", "₹1,500", Colors.amber[700]!)),
              ],
            ),
            const SizedBox(height: 24),

            // Charts Grid
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Revenue Trend Area Chart
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Weekly Revenue Trend (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          const Text('Historical flow over the last 6 days', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 200,
                            child: AreaChartWidget(
                              data: _weeklyRevenue,
                              xKey: 'day',
                              yKey: 'revenue',
                            ),
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
                          const Text('Active channels usage', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 120,
                            child: PieChartWidget(
                              data: _modeCollections,
                              valueKey: 'value',
                              colorKey: 'color',
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Legends
                          Column(
                            children: _modeCollections.map((m) {
                              final double share = totalCollected == 0 ? 0 : (m['value'] / totalCollected) * 100;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(color: m['color'], shape: BoxShape.circle),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(m['name'], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                    const Spacer(),
                                    Text('₹${m['value'].toStringAsFixed(0)} (${share.toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
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
