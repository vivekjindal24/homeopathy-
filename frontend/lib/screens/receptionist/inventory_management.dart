import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';

class InventoryManagement extends StatefulWidget {
  final String? clinicId;
  const InventoryManagement({super.key, this.clinicId});

  @override
  State<InventoryManagement> createState() => _InventoryManagementState();
}

class _InventoryManagementState extends State<InventoryManagement> {
  final _api = ApiService();
  List<dynamic> _medicines = [];
  bool _loading = true;
  String? _error;
  String _filterTab = 'all';
  int? _totalMedicines;
  int? _lowStockCount;
  int? _nearExpiryCount;

  String get _effectiveClinicId => widget.clinicId ?? '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    try {
      final meds = await _api.getInventory(clinicId: _effectiveClinicId);
      if (!mounted) return;
      final stats = await _api.getInventoryStats(_effectiveClinicId);
      if (!mounted) return;
      setState(() {
        _medicines = meds;
        _totalMedicines = stats['total_medicines'] ?? meds.length;
        _lowStockCount = stats['low_stock_count'] ?? 0;
        _nearExpiryCount = stats['near_expiry_count'] ?? 0;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _error = e.message; _loading = false; });
    }
  }

  bool _isNearExpiry(String? expiryDate) {
    if (expiryDate == null || expiryDate.isEmpty) return false;
    try {
      final exp = DateTime.parse(expiryDate);
      return exp.isBefore(DateTime.now().add(const Duration(days: 90)));
    } catch (_) {
      return false;
    }
  }

  Future<void> _openAddDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final mfrCtrl = TextEditingController();
    final batchCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '0');
    final priceCtrl = TextEditingController(text: '0');
    final expiryCtrl = TextEditingController();
    final thresholdCtrl = TextEditingController(text: '10');
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add New Medicine', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Medicine Name *'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(controller: mfrCtrl, decoration: const InputDecoration(labelText: 'Manufacturer')),
                    const SizedBox(height: 12),
                    TextFormField(controller: batchCtrl, decoration: const InputDecoration(labelText: 'Batch Number')),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: qtyCtrl,
                            decoration: const InputDecoration(labelText: 'Quantity *'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: priceCtrl,
                            decoration: const InputDecoration(labelText: 'Unit Price (₹) *'),
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: expiryCtrl,
                            decoration: const InputDecoration(labelText: 'Expiry (YYYY-MM-DD)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: thresholdCtrl,
                            decoration: const InputDecoration(labelText: 'Low Stock Threshold'),
                            keyboardType: TextInputType.number,
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => saving = true);
                try {
                  await _api.createMedicine({
                    'name': nameCtrl.text.trim(),
                    'manufacturer': mfrCtrl.text.trim().isEmpty ? null : mfrCtrl.text.trim(),
                    'batch_number': batchCtrl.text.trim().isEmpty ? null : batchCtrl.text.trim(),
                    'quantity': int.tryParse(qtyCtrl.text) ?? 0,
                    'unit_price': double.tryParse(priceCtrl.text) ?? 0,
                    'expiry_date': expiryCtrl.text.trim().isEmpty ? null : expiryCtrl.text.trim(),
                    'low_stock_threshold': int.tryParse(thresholdCtrl.text) ?? 10,
                    'clinic_id': _effectiveClinicId,
                  });
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medicine added.')),
                  );
                  _loadData();
                } on ApiException catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.message}')),
                  );
                  setDialogState(() => saving = false);
                }
              },
              child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add Medicine'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStockInwardDialog(dynamic med) async {
    final qtyCtrl = TextEditingController();
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Stock Inward: ${med['name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Current stock: ${med['quantity']}', style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  decoration: const InputDecoration(labelText: 'Quantity to add *'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: saving ? null : () async {
                final qty = int.tryParse(qtyCtrl.text);
                if (qty == null || qty <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enter a valid positive quantity')),
                  );
                  return;
                }
                setDialogState(() => saving = true);
                try {
                  await _api.stockInward(med['medicine_id'], qty);
                  if (!mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added $qty units to ${med['name']}')),
                  );
                  _loadData();
                } on ApiException catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.message}')),
                  );
                  setDialogState(() => saving = false);
                }
              },
              child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Add Stock'),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> get _filteredList {
    return _medicines.where((m) {
      if (_filterTab == 'low') return (m['quantity'] ?? 0) <= (m['low_stock_threshold'] ?? 10);
      if (_filterTab == 'expiry') return _isNearExpiry(m['expiry_date']);
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Inventory Control & Stock'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          ElevatedButton.icon(
            onPressed: _openAddDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Medicine'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, style: const TextStyle(color: AppColors.red600)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
                  ],
                ))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Warning banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.blue100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, color: AppColors.blue700, size: 18),
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

                      // KPI row
                      Row(
                        children: [
                          Expanded(child: _buildMetricCard("Total Medicines", "${_totalMedicines ?? _medicines.length}", AppColors.primary)),
                          const SizedBox(width: 14),
                          Expanded(child: _buildMetricCard("Low Stock Batches", "${_lowStockCount ?? 0}", AppColors.amber700)),
                          const SizedBox(width: 14),
                          Expanded(child: _buildMetricCard("Near Expiry (90d)", "${_nearExpiryCount ?? 0}", const Color(0xFFD97706))),
                          const SizedBox(width: 14),
                          Expanded(child: _buildMetricCard("Expired Batches", "0", AppColors.red600)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Filter tabs
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
                                _buildFilterToggle('all', 'All Stock'),
                                _buildFilterToggle('low', 'Low Stock'),
                                _buildFilterToggle('expiry', 'Near Expiry'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Stock table
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
                                4: FlexColumnWidth(1.2),
                                5: FlexColumnWidth(1.2),
                                6: FlexColumnWidth(1.0),
                                7: FlexColumnWidth(1.0),
                              },
                              children: [
                                TableRow(
                                  decoration: const BoxDecoration(
                                    border: Border(bottom: BorderSide(color: AppColors.slate200)),
                                  ),
                                  children: [
                                    _buildTableHeader('Medicine Name'),
                                    _buildTableHeader('Batch'),
                                    _buildTableHeader('Qty'),
                                    _buildTableHeader('Price'),
                                    _buildTableHeader('Expiry'),
                                    _buildTableHeader('Status'),
                                    _buildTableHeader(''),
                                    _buildTableHeader(''),
                                  ],
                                ),
                                ..._filteredList.map((m) {
                                  final qty = (m['quantity'] ?? 0) as int;
                                  final threshold = (m['low_stock_threshold'] ?? 10) as int;
                                  final expiry = m['expiry_date'] as String? ?? '-';
                                  final isLow = qty <= threshold;
                                  final isExpiry = _isNearExpiry(m['expiry_date']);

                                  Color sBg = AppColors.green100;
                                  Color sFg = AppColors.green600;
                                  String sLabel = 'OK';
                                  if (isLow) {
                                    sBg = AppColors.red100;
                                    sFg = AppColors.red600;
                                    sLabel = 'Low Stock';
                                  } else if (isExpiry) {
                                    sBg = AppColors.amber100;
                                    sFg = AppColors.amber700;
                                    sLabel = 'Near Expiry';
                                  }

                                  return TableRow(
                                    decoration: const BoxDecoration(
                                      border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                                    ),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(m['name'] ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            if (m['manufacturer'] != null)
                                              Text(m['manufacturer'], style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                                        child: Text(m['batch_number'] ?? '-', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.textMuted)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                                        child: Text('$qty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isLow ? AppColors.red600 : AppColors.textDark)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                                        child: Text('₹${m['unit_price'] ?? 0}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                                        child: Text(expiry, style: TextStyle(fontSize: 12, color: isExpiry ? AppColors.red600 : AppColors.textDark, fontWeight: isExpiry ? FontWeight.bold : FontWeight.normal)),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                                        child: UnconstrainedBox(
                                          alignment: Alignment.centerLeft,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(color: sBg, borderRadius: BorderRadius.circular(4)),
                                            child: Text(sLabel, style: TextStyle(color: sFg, fontSize: 10, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                                        child: TextButton(
                                          onPressed: () => _openStockInwardDialog(m),
                                          child: const Text('Inward', style: TextStyle(fontSize: 11)),
                                        ),
                                      ),
                                      const SizedBox(),
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
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted)),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
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
            color: active ? AppColors.textDark : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
