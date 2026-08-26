import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class InventoryManagement extends StatefulWidget {
  final String? clinicId;
  const InventoryManagement({super.key, this.clinicId});

  @override
  State<InventoryManagement> createState() => _InventoryManagementState();
}

class _InventoryManagementState extends State<InventoryManagement> {
  // Static list of medicines mock data as requested by the React design file
  final List<Map<String, dynamic>> _medicines = [
    { "name": "Arnica Montana 200C", "potency": "200C", "form": "Pellets", "qty": 50, "unit": "g", "batch": "B2401", "expiry": "2026-12-31", "alert": false },
    { "name": "Belladonna 30C", "potency": "30C", "form": "Drops", "qty": 8, "unit": "ml", "batch": "B2389", "expiry": "2026-03-15", "alert": true },
    { "name": "Nux Vomica 1M", "potency": "1M", "form": "Pellets", "qty": 3, "unit": "g", "batch": "B2392", "expiry": "2025-06-30", "alert": true },
    { "name": "Sulphur 6C", "potency": "6C", "form": "Pellets", "qty": 120, "unit": "g", "batch": "B2415", "expiry": "2027-09-01", "alert": false },
    { "name": "Rhus Tox 30C", "potency": "30C", "form": "Liquid", "qty": 5, "unit": "ml", "batch": "B2401", "expiry": "2025-07-15", "alert": true },
    { "name": "Pulsatilla 200C", "potency": "200C", "form": "Pellets", "qty": 45, "unit": "g", "batch": "B2420", "expiry": "2027-01-20", "alert": false },
  ];

  String _filterTab = "all"; // "all", "low", "expiry"

  void _openStockInwardDialog() {
    final formKey = GlobalKey<FormState>();
    String selectedMedicine = _medicines.first['name'];
    final supplierController = TextEditingController();
    final qtyController = TextEditingController();
    final batchController = TextEditingController();
    final expiryController = TextEditingController(text: "2026-12-31");
    final rateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Stock Inward Registration', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Container(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedMedicine,
                      decoration: const InputDecoration(labelText: 'Select Medicine *'),
                      items: _medicines.map<DropdownMenuItem<String>>((m) {
                        return DropdownMenuItem<String>(
                          value: m['name'],
                          child: Text(m['name']),
                        );
                      }).toList(),
                      onChanged: (val) => selectedMedicine = val ?? _medicines.first['name'],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: supplierController,
                      decoration: const InputDecoration(labelText: 'Supplier Name *'),
                      validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: qtyController,
                            decoration: const InputDecoration(labelText: 'Quantity *'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: batchController,
                            decoration: const InputDecoration(labelText: 'Batch Number *'),
                            validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: expiryController,
                            decoration: const InputDecoration(labelText: 'Expiry (YYYY-MM-DD) *'),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: rateController,
                            decoration: const InputDecoration(labelText: 'Purchase Rate (₹) *'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // Simulate updating stock
                  final index = _medicines.indexWhere((m) => m['name'] == selectedMedicine);
                  if (index != -1) {
                    setState(() {
                      _medicines[index]['qty'] += int.parse(qtyController.text);
                      _medicines[index]['batch'] = batchController.text.trim();
                      _medicines[index]['expiry'] = expiryController.text.trim();
                    });
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stock inward recorded successfully.')),
                  );
                }
              },
              child: const Text('Save Stock Inward'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Stats calculation
    final int totalMedicines = _medicines.length;
    final int lowStock = _medicines.where((m) => m['qty'] <= 10).length;
    final int nearExpiry = _medicines.where((m) => m['expiry'].toString().contains('2025')).length;

    // Filter logic
    final List<Map<String, dynamic>> filteredList = _medicines.where((m) {
      if (_filterTab == 'low') return m['qty'] <= 10;
      if (_filterTab == 'expiry') return m['expiry'].toString().contains('2025');
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Inventory Control & Stock'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          ElevatedButton.icon(
            onPressed: _openStockInwardDialog,
            icon: const Icon(Icons.playlist_add_rounded, size: 18),
            label: const Text('Stock Inward'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF1D4ED8), size: 18),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Adding new medicines, editing pricing structures, or deleting stock records requires Doctor/Admin secure credentials.',
                      style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Metrics Grid
            Row(
              children: [
                Expanded(child: _buildMetricCard("Total Medicines", "$totalMedicines", Colors.teal[700]!)),
                const SizedBox(width: 14),
                Expanded(child: _buildMetricCard("Low Stock Batches", "$lowStock", Colors.orange[600]!)),
                const SizedBox(width: 14),
                Expanded(child: _buildMetricCard("Near Expiry (30d)", "$nearExpiry", Colors.amber[600]!)),
                const SizedBox(width: 14),
                Expanded(child: _buildMetricCard("Expired Batches", "0", Colors.red[500]!)),
              ],
            ),
            const SizedBox(height: 24),

            // Toggle filter tabs
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildFilterToggle("all", "All Stock"),
                      _buildFilterToggle("low", "Low Stock"),
                      _buildFilterToggle("expiry", "Near Expiry"),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stock Table Card
            Card(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Table(
                    columnWidths: const {
                      0: FlexColumnWidth(2.0),
                      1: FlexColumnWidth(1.0),
                      2: FlexColumnWidth(1.0),
                      3: FlexColumnWidth(1.0),
                      4: FlexColumnWidth(1.0),
                      5: FlexColumnWidth(1.0),
                      6: FlexColumnWidth(1.2),
                      7: FlexColumnWidth(1.2),
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                        ),
                        children: [
                          _buildTableHeader("Medicine Name"),
                          _buildTableHeader("Potency"),
                          _buildTableHeader("Form"),
                          _buildTableHeader("Qty"),
                          _buildTableHeader("Unit"),
                          _buildTableHeader("Batch"),
                          _buildTableHeader("Expiry Date"),
                          _buildTableHeader("Status"),
                        ],
                      ),
                      ...filteredList.map((m) {
                        final qty = m['qty'] as int;
                        final String expiry = m['expiry'];
                        final isLow = qty <= 10;
                        final isExpiry = expiry.contains('2025');

                        Color statusBg = const Color(0xFFECFDF5);
                        Color statusFg = const Color(0xFF047857);
                        String statusLabel = "OK";

                        if (isLow) {
                          statusBg = const Color(0xFFFEF2F2);
                          statusFg = const Color(0xFFDC2626);
                          statusLabel = "Low Stock";
                        } else if (isExpiry) {
                          statusBg = const Color(0xFFFEF3C7);
                          statusFg = const Color(0xFFD97706);
                          statusLabel = "Near Expiry";
                        }

                        return TableRow(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(m['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(m['potency'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'monospace')),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(m['form'], style: const TextStyle(fontSize: 12)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Text('$qty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isLow ? Colors.red : const Color(0xFF0F172A))),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(m['unit'], style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(m['batch'], style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF64748B))),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(expiry, style: TextStyle(fontSize: 12, color: isExpiry ? Colors.red : const Color(0xFF0F172A), fontWeight: isExpiry ? FontWeight.bold : FontWeight.normal)),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: UnconstrainedBox(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(color: statusFg, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
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

  Widget _buildFilterToggle(String tab, String label) {
    final active = _filterTab == tab;
    return InkWell(
      onTap: () => setState(() => _filterTab = tab),
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
}
