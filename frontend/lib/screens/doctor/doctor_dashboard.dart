import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'prescription_screen.dart';

// ─── Shared Color System (same as receptionist) ───────
const cBg       = Color(0xFFF8FAFC);
const cCard     = Color(0xFFFFFFFF);
const cBorder   = Color(0x1A000000);
const cFg       = Color(0xFF0F172A);
const cMuted    = Color(0xFF717182);
const cMutedBg  = Color(0xFFECECF0);
const cAccent   = Color(0xFFE9EBEF);
const cPrimary  = Color(0xFF0F766E);
const cAmber50  = Color(0xFFFFFBEB);
const cAmber100 = Color(0xFFFEF3C7);
const cAmber200 = Color(0xFFFDE68A);
const cAmber700 = Color(0xFFB45309);
const cBlue50   = Color(0xFFEFF6FF);
const cBlue100  = Color(0xFFDBEAFE);
const cBlue700  = Color(0xFF1D4ED8);
const cEm50     = Color(0xFFECFDF5);
const cEm100    = Color(0xFFD1FAE5);
const cEm200    = Color(0xFFA7F3D0);
const cEm600    = Color(0xFF059669);
const cEm700    = Color(0xFF047857);
const cRed50    = Color(0xFFFEF2F2);
const cRed100   = Color(0xFFFEE2E2);
const cRed600   = Color(0xFFDC2626);
const cSlate50  = Color(0xFFF8FAFC);
const cSlate100 = Color(0xFFF1F5F9);
const cSlate200 = Color(0xFFE2E8F0);
const cSlate400 = Color(0xFF94A3B8);
const cSlate600 = Color(0xFF475569);
const cPurple50 = Color(0xFFFAF5FF);
const cPurple100= Color(0xFFEDE9FE);
const cPurple700= Color(0xFF7E22CE);
const cOrange50 = Color(0xFFFFF7ED);
const cOrange500= Color(0xFFF97316);

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});
  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final ApiService _api = ApiService();
  String _tab = 'dashboard';
  bool _loading = false;
  String? _clinicId;
  String _date = DateTime.now().toIso8601String().split('T')[0];
  Map<String, dynamic> _kpis = {};
  List<dynamic> _appointments = [];
  List<dynamic> _patients = [];
  List<dynamic> _invoices = [];
  Map<String, dynamic>? _activeConsultAppt;
  String _searchQ = '';

  final _navGroups = [
    {
      'label': 'OVERVIEW',
      'items': [
        {'key': 'dashboard', 'label': 'Dashboard', 'icon': Icons.grid_view_rounded},
      ],
    },
    {
      'label': 'CLINICAL',
      'items': [
        {'key': 'patients', 'label': 'Patients', 'icon': Icons.people_outline_rounded},
        {'key': 'appointments', 'label': 'Appointments', 'icon': Icons.calendar_month_outlined},
        {'key': 'consultations', 'label': 'Consultations', 'icon': Icons.medical_services_outlined},
        {'key': 'prescriptions', 'label': 'Prescriptions', 'icon': Icons.description_outlined},
      ],
    },
    {
      'label': 'FINANCE',
      'items': [
        {'key': 'billing', 'label': 'Billing / Invoices', 'icon': Icons.receipt_long_outlined},
        {'key': 'payments', 'label': 'Payments / Refunds', 'icon': Icons.account_balance_wallet_outlined},
        {'key': 'inventory', 'label': 'Inventory', 'icon': Icons.inventory_2_outlined},
        {'key': 'expenses', 'label': 'Expenses', 'icon': Icons.trending_down_rounded},
      ],
    },
    {
      'label': 'OPERATIONS',
      'items': [
        {'key': 'reports', 'label': 'Reports', 'icon': Icons.bar_chart_rounded},
        {'key': 'notifications', 'label': 'Notifications', 'icon': Icons.notifications_none_rounded},
        {'key': 'audit', 'label': 'Audit Logs', 'icon': Icons.verified_user_outlined},
        {'key': 'settings', 'label': 'Settings', 'icon': Icons.settings_outlined},
      ],
    },
  ];

  final Map<String, Map<String, String>> _titles = {
    'dashboard':     {'title': 'Admin Dashboard', 'subtitle': 'Operations overview'},
    'patients':      {'title': 'Patients', 'subtitle': 'Registry & profiles'},
    'appointments':  {'title': 'Appointments', 'subtitle': 'Schedule & queue'},
    'consultations': {'title': 'Consultation', 'subtitle': 'Case taking · Visit in progress'},
    'prescriptions': {'title': 'Prescriptions', 'subtitle': 'Digital Rx · A5 print-ready'},
    'billing':       {'title': 'Billing', 'subtitle': 'Invoice & payment collection'},
    'payments':      {'title': 'Payments', 'subtitle': 'Collections & refunds'},
    'inventory':     {'title': 'Inventory', 'subtitle': 'Pharmacy stock & batches'},
    'expenses':      {'title': 'Expenses', 'subtitle': 'Operational ledger'},
    'reports':       {'title': 'Reports', 'subtitle': 'Analytics & financial oversight'},
    'notifications': {'title': 'Notifications', 'subtitle': 'Alerts & system messages'},
    'audit':         {'title': 'Audit Logs', 'subtitle': 'Immutable event trail'},
    'settings':      {'title': 'Settings', 'subtitle': 'Configuration & user management'},
  };

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    final clinics = await _api.getClinics();
    if (clinics.isNotEmpty) _clinicId = clinics.first['clinic_id'];
    if (_clinicId != null) {
      final kpis  = await _api.getKpis(_clinicId!, _date);
      final appts = await _api.getAppointments(clinicId: _clinicId, date: _date);
      final pts   = await _api.getPatients();
      final invs  = await _api.getInvoices();
      setState(() {
        if (kpis != null) _kpis = kpis;
        _appointments = appts;
        _patients = pts;
        _invoices = invs;
        _activeConsultAppt = appts.isNotEmpty ? appts.firstWhere((a) => a['status'] == 'In Consultation', orElse: () => appts.first) : null;
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String apptId, String status) async {
    try {
      await _api.updateAppointmentStatus(apptId, status);
      _fetchData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: cRed600));
    }
  }

  void _signOut() {
    _api.logout();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      body: Row(children: [
        _buildSidebar(),
        Expanded(child: Column(children: [
          _buildTopBar(),
          Expanded(child: _loading ? const Center(child: CircularProgressIndicator(color: cPrimary)) : _buildBody()),
        ])),
      ]),
    );
  }

  // ─── SIDEBAR ─────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(color: cCard, border: Border(right: BorderSide(color: cBorder))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Brand
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: cBorder))),
          child: Row(children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(color: cPrimary, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 18)),
            const SizedBox(width: 10),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Verma Homeopathy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cFg)),
              Text('Clinic OS · Indore', style: TextStyle(fontSize: 10, color: cMuted)),
            ]),
          ]),
        ),

        // Nav
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _navGroups.map((group) {
              final label = group['label'] as String;
              final items = group['items'] as List;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: cMuted, letterSpacing: 0.8)),
                  ),
                  ...items.map((item) {
                    final key = item['key'] as String;
                    final lbl = item['label'] as String;
                    final ico = item['icon'] as IconData;
                    final active = _tab == key;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: InkWell(
                        onTap: () => setState(() => _tab = key),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                          decoration: BoxDecoration(
                            color: active ? cAccent : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(children: [
                            Icon(ico, size: 16, color: active ? cPrimary : cMuted),
                            const SizedBox(width: 10),
                            Text(lbl, style: TextStyle(fontSize: 13, color: active ? cFg : cFg.withOpacity(0.7), fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
                          ]),
                        ),
                      ),
                    );
                  }),
                ]),
              );
            }).toList()),
          ),
        ),

        // Footer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: cBorder))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            InkWell(
              onTap: _signOut,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Row(children: [
                Icon(Icons.logout_rounded, size: 14, color: cMuted),
                SizedBox(width: 8),
                Text('Sign Out', style: TextStyle(fontSize: 12, color: cMuted)),
              ])),
            ),
            const Padding(padding: EdgeInsets.only(left: 8, top: 4), child: Row(children: [
              CircleAvatar(backgroundColor: cEm600, radius: 3),
              SizedBox(width: 6),
              Text('Synced · 2s ago', style: TextStyle(fontSize: 11, color: cMuted)),
            ])),
          ]),
        ),
      ]),
    );
  }

  // ─── TOPBAR ──────────────────────────────────────────
  Widget _buildTopBar() {
    final meta = _titles[_tab]!;
    final today = DateTime.now();
    final dateStr = '${['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][today.weekday % 7]}, ${today.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][today.month - 1]} ${today.year}';
    return Container(
      height: 56,
      decoration: const BoxDecoration(color: cCard, border: Border(bottom: BorderSide(color: cBorder))),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(meta['title']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cFg)),
          Text(meta['subtitle']!, style: const TextStyle(fontSize: 11, color: cMuted)),
        ])),
        SizedBox(
          width: 240, height: 34,
          child: TextField(
            onChanged: (v) => setState(() => _searchQ = v),
            style: const TextStyle(fontSize: 12, color: cFg),
            decoration: InputDecoration(
              hintText: 'Search patients, records…',
              hintStyle: const TextStyle(fontSize: 12, color: cMuted),
              prefixIcon: const Icon(Icons.search_rounded, size: 16, color: cMuted),
              filled: true, fillColor: cMutedBg,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(dateStr, style: const TextStyle(fontSize: 11, color: cMuted)),
        const SizedBox(width: 8),
        Stack(alignment: Alignment.center, children: [
          IconButton(onPressed: () => setState(() => _tab = 'notifications'), icon: const Icon(Icons.notifications_none_rounded, size: 20, color: cMuted)),
          Positioned(top: 8, right: 8, child: Container(width: 7, height: 7, decoration: BoxDecoration(color: cRed600, borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white, width: 1.2)))),
        ]),
        const SizedBox(width: 4),
        InkWell(
          onTap: _signOut,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(children: [
              Container(width: 28, height: 28, decoration: BoxDecoration(color: cPrimary, borderRadius: BorderRadius.circular(100)), child: const Center(child: Text('V', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)))),
              const SizedBox(width: 6),
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_api.fullName?.split(' ').first ?? 'Dr. Verma', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cFg)),
                const Text('Administrator', style: TextStyle(fontSize: 10, color: cMuted)),
              ]),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: cMuted),
            ]),
          ),
        ),
      ]),
    );
  }

  // ─── BODY ROUTER ─────────────────────────────────────
  Widget _buildBody() {
    switch (_tab) {
      case 'dashboard':     return _buildAdminDashboard();
      case 'patients':      return _buildPatientsTab();
      case 'appointments':  return _buildAppointmentsTab();
      case 'consultations': return _buildConsultationTab();
      case 'prescriptions': return _buildPrescriptionsTab();
      case 'billing':       return _buildBillingTab();
      case 'payments':      return _buildPaymentsTab();
      case 'inventory':     return _buildInventoryTab();
      case 'expenses':      return _buildExpensesTab();
      case 'reports':       return _buildReportsTab();
      case 'notifications': return _buildNotificationsTab();
      case 'audit':         return _buildAuditTab();
      case 'settings':      return _buildSettingsTab();
      default:              return _buildAdminDashboard();
    }
  }

  // ─── TAB 1: ADMIN DASHBOARD ──────────────────────────
  Widget _buildAdminDashboard() {
    final todayRevenue = _kpis['today_revenue'] ?? 18450.0;
    final todayPts     = _kpis['today_patients'] ?? 46;
    final pendingDues  = _kpis['pending_dues'] ?? 24860.0;
    final apptCount    = _appointments.length;
    final completed    = _appointments.where((a) => a['status'] == 'Completed').length;
    final noShow       = _appointments.where((a) => a['status'] == 'No Show').length;

    final kpis = [
      {'label': 'Daily Revenue', 'value': '₹${(todayRevenue as num).toStringAsFixed(0)}', 'delta': '↑ 12.4%', 'up': true, 'hint': 'vs. 7-day average', 'icon': Icons.currency_rupee_rounded, 'iconColor': cPrimary, 'iconBg': cEm50},
      {'label': 'Patients Today', 'value': '$todayPts', 'delta': '6 walk-ins', 'up': true, 'hint': '${completed > 0 ? completed : "--"} follow-ups · 14 new', 'icon': Icons.people_outline_rounded, 'iconColor': cMuted, 'iconBg': cMutedBg},
      {'label': 'Appointments', 'value': '$apptCount', 'delta': '$noShow no-show', 'up': false, 'hint': '$completed completed · ${apptCount - completed} in queue', 'icon': Icons.calendar_month_outlined, 'iconColor': cMuted, 'iconBg': cMutedBg},
      {'label': 'Pending Dues', 'value': '₹${(pendingDues as num).toStringAsFixed(0)}', 'delta': '↑ ₹3,200', 'up': false, 'hint': '9 invoices · 2 overdue', 'icon': Icons.warning_amber_rounded, 'iconColor': cAmber700, 'iconBg': cAmber50},
    ];

    final recentInvs = _invoices.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        // Date header + actions
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Today · ${DateTime.now().weekday == 1 ? "Monday" : DateTime.now().weekday == 2 ? "Tuesday" : DateTime.now().weekday == 3 ? "Wednesday" : DateTime.now().weekday == 4 ? "Thursday" : DateTime.now().weekday == 5 ? "Friday" : DateTime.now().weekday == 6 ? "Saturday" : "Sunday"}, ${_date}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cFg)),
            const Text('Operational snapshot for Vijay Nagar branch', style: TextStyle(fontSize: 12, color: cMuted)),
          ]),
          Row(children: [
            _outlineBtn('Export EOD', Icons.download_rounded, () {}),
            const SizedBox(width: 8),
            _primaryBtn('Open Reconciliation', null, () {}),
          ]),
        ]),
        const SizedBox(height: 20),

        // 4 KPIs
        GridView.count(
          crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 12,
          childAspectRatio: 1.8, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          children: kpis.map((k) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(k['label'] as String, style: const TextStyle(fontSize: 11, color: cMuted)),
                Container(width: 28, height: 28, decoration: BoxDecoration(color: k['iconBg'] as Color, borderRadius: BorderRadius.circular(8)), child: Icon(k['icon'] as IconData, size: 14, color: k['iconColor'] as Color)),
              ]),
              const SizedBox(height: 8),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(k['value'] as String, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: cFg, height: 1)),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(children: [
                    Icon((k['up'] as bool) ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 11, color: (k['up'] as bool) ? cEm600 : cRed600),
                    Text(k['delta'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: (k['up'] as bool) ? cEm600 : cRed600)),
                  ]),
                ),
              ]),
              Text(k['hint'] as String, style: const TextStyle(fontSize: 10, color: cMuted)),
            ]),
          )).toList(),
        ),
        const SizedBox(height: 20),

        // Revenue chart (2/3) + Mode donut (1/3)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 2, child: _buildRevenueChart()),
          const SizedBox(width: 16),
          Expanded(child: _buildModeDonut()),
        ]),
        const SizedBox(height: 20),

        // Recent invoices (2/3) + Appt trend (1/3)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 2, child: _buildRecentInvoicesCard(recentInvs)),
          const SizedBox(width: 16),
          Expanded(child: _buildApptTrendCard()),
        ]),
      ]),
    );
  }

  Widget _buildRevenueChart() {
    final data = [12400.0, 14800.0, 11200.0, 16900.0, 18450.0, 22100.0, 9800.0];
    final expenses = [4200.0, 3800.0, 4600.0, 5100.0, 4800.0, 5400.0, 2900.0];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Revenue vs. Expenses', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
            Text('Last 7 days · in ₹', style: TextStyle(fontSize: 11, color: cMuted)),
          ]),
          Row(children: [
            Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: cPrimary, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 4), const Text('Revenue', style: TextStyle(fontSize: 10, color: cMuted))]),
            const SizedBox(width: 12),
            Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: cSlate200, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 4), const Text('Expenses', style: TextStyle(fontSize: 10, color: cMuted))]),
          ]),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          height: 140,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (int i = 0; i < data.length; i++) ...[
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(child: Container(height: (data[i] / maxVal) * 120, decoration: BoxDecoration(color: cPrimary.withOpacity(0.85), borderRadius: const BorderRadius.vertical(top: Radius.circular(4))))),
                  const SizedBox(width: 2),
                  Expanded(child: Container(height: (expenses[i] / maxVal) * 120, decoration: BoxDecoration(color: cSlate200, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))))),
                ]),
                const SizedBox(height: 6),
                Text(days[i], style: const TextStyle(fontSize: 9, color: cMuted)),
              ])),
              if (i < data.length - 1) const SizedBox(width: 4),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _buildModeDonut() {
    final modes = [
      {'name': 'UPI', 'pct': 48.0, 'amount': '₹8,856', 'color': cPrimary},
      {'name': 'Cash', 'pct': 26.0, 'amount': '₹4,797', 'color': const Color(0xFF14B8A6)},
      {'name': 'Card', 'pct': 18.0, 'amount': '₹3,321', 'color': const Color(0xFF5EEAD4)},
      {'name': 'Net Banking', 'pct': 8.0, 'amount': '₹1,476', 'color': const Color(0xFF99F6E4)},
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Collections by Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
        const Text('Today · ₹18,450 total', style: TextStyle(fontSize: 11, color: cMuted)),
        const SizedBox(height: 16),
        // Stacked progress bar as donut substitute
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: SizedBox(
            height: 16,
            child: Row(
              children: modes.map((m) => Expanded(
                flex: (m['pct'] as double).toInt(),
                child: Container(color: m['color'] as Color),
              )).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...modes.map((m) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: m['color'] as Color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Expanded(child: Text(m['name'] as String, style: const TextStyle(fontSize: 11, color: cMuted))),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${(m['pct'] as double).toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cFg)),
              Text(m['amount'] as String, style: const TextStyle(fontSize: 9, color: cMuted)),
            ]),
          ]),
        )),
      ]),
    );
  }

  Widget _buildRecentInvoicesCard(List<dynamic> invs) {
    final statusColors = {'paid': [cEm50, cEm700], 'partial': [cAmber50, cAmber700], 'due': [cRed50, cRed600], 'draft': [cSlate100, cSlate600]};
    final mockInvs = [
      {'id': 'INV-2041', 'patient': 'Anita Sharma', 'amount': '₹1,250', 'status': 'paid', 'mode': 'UPI'},
      {'id': 'INV-2042', 'patient': 'Rohit Mehra', 'amount': '₹860', 'status': 'partial', 'mode': 'Cash'},
      {'id': 'INV-2043', 'patient': 'Sunita Tiwari', 'amount': '₹2,400', 'status': 'paid', 'mode': 'Card'},
      {'id': 'INV-2044', 'patient': 'Vikas Yadav', 'amount': '₹540', 'status': 'due', 'mode': '—'},
      {'id': 'INV-2045', 'patient': 'Priya Nair', 'amount': '₹1,180', 'status': 'paid', 'mode': 'UPI'},
    ];
    return Container(
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Recent Invoices', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
              Text('Latest billing activity', style: TextStyle(fontSize: 11, color: cMuted)),
            ]),
            TextButton(onPressed: () => setState(() => _tab = 'billing'), child: const Row(children: [Text('View all', style: TextStyle(fontSize: 11, color: cPrimary)), Icon(Icons.arrow_forward_rounded, size: 14, color: cPrimary)])),
          ]),
        ),
        Container(
          color: cMutedBg.withOpacity(0.6),
          child: const Row(children: [
            SizedBox(width: 16),
            Expanded(flex: 2, child: Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Invoice', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted)))),
            Expanded(flex: 3, child: Text('Patient', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
            Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
            Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
            Expanded(flex: 2, child: Text('Mode', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
            SizedBox(width: 16),
          ]),
        ),
        const Divider(height: 1, color: cBorder),
        ...mockInvs.map((inv) {
          final status = inv['status'] as String;
          final sColors = statusColors[status] ?? [cSlate100, cMuted];
          return Container(
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: cBorder))),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                Expanded(flex: 2, child: Text(inv['id'] as String, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: cPrimary, fontWeight: FontWeight.w600))),
                Expanded(flex: 3, child: Text(inv['patient'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cFg))),
                Expanded(flex: 2, child: Text(inv['amount'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cFg))),
                Expanded(flex: 2, child: _statusPill(status)),
                Expanded(flex: 2, child: Text(inv['mode'] as String, style: const TextStyle(fontSize: 11, color: cMuted))),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  Widget _buildApptTrendCard() {
    final trend = [142.0, 168.0, 156.0, 191.0, 204.0, 188.0];
    final weeks = ['W1', 'W2', 'W3', 'W4', 'W5', 'W6'];
    final maxVal = trend.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Appointment Trend', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
        const Text('Weekly · last 6 weeks', style: TextStyle(fontSize: 11, color: cMuted)),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (int i = 0; i < trend.length; i++) ...[
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(height: (trend[i] / maxVal) * 80, decoration: BoxDecoration(color: cPrimary.withOpacity(0.8), borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))),
                const SizedBox(height: 4),
                Text(weeks[i], style: const TextStyle(fontSize: 9, color: cMuted)),
              ])),
              if (i < trend.length - 1) const SizedBox(width: 4),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: cBorder),
        const SizedBox(height: 12),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(children: [
            Text('204', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cPrimary)),
            Text('Peak Week', style: TextStyle(fontSize: 10, color: cMuted)),
          ]),
          Column(children: [
            Text('+43.7%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cEm600)),
            Text('Growth', style: TextStyle(fontSize: 10, color: cMuted)),
          ]),
        ]),
      ]),
    );
  }

  // ─── TAB 2: PATIENTS ─────────────────────────────────
  Widget _buildPatientsTab() {
    final filtered = _patients.where((p) {
      if (_searchQ.isEmpty) return true;
      final name = (p['full_name'] ?? '').toLowerCase();
      final mobile = (p['mobile_number'] ?? '').toLowerCase();
      return name.contains(_searchQ.toLowerCase()) || mobile.contains(_searchQ.toLowerCase());
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Patients', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cFg)),
            Text('${filtered.length} total patients', style: const TextStyle(fontSize: 12, color: cMuted)),
          ]),
          _outlineBtn('Export', Icons.download_rounded, () {}),
        ]),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
            child: Column(children: [
              Container(
                color: cMutedBg.withOpacity(0.6),
                child: const Row(children: [
                  SizedBox(width: 16),
                  Expanded(flex: 3, child: Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Patient', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted)))),
                  Expanded(flex: 2, child: Text('Code', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  Expanded(flex: 2, child: Text('Phone', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  SizedBox(width: 16),
                ]),
              ),
              const Divider(height: 1, color: cBorder),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('No patients found', style: TextStyle(fontSize: 12, color: cMuted)))
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: cBorder),
                        itemBuilder: (_, i) {
                          final p = filtered[i];
                          final name = p['full_name'] ?? '—';
                          final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(children: [
                              Expanded(flex: 3, child: Row(children: [
                                Container(width: 32, height: 32, decoration: BoxDecoration(color: cMutedBg, borderRadius: BorderRadius.circular(100)), child: Center(child: Text(initial, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cMuted)))),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cFg)),
                                  Text('${p['age'] ?? '?'}y · ${p['gender'] ?? ''}', style: const TextStyle(fontSize: 10, color: cMuted)),
                                ])),
                              ])),
                              Expanded(flex: 2, child: Text(p['unique_patient_id'] ?? '—', style: const TextStyle(fontSize: 11, color: cPrimary, fontFamily: 'monospace'))),
                              Expanded(flex: 2, child: Text(p['mobile_number'] ?? '—', style: const TextStyle(fontSize: 11, color: cFg))),
                              Expanded(flex: 2, child: _statusPill('active')),
                              Expanded(flex: 2, child: _smallBtn('View Profile', cPrimary.withOpacity(0.1), cPrimary, () {})),
                            ]),
                          );
                        },
                      ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ─── TAB 3: APPOINTMENTS ─────────────────────────────
  Widget _buildAppointmentsTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Appointments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cFg)),
            Text('Schedule & queue', style: TextStyle(fontSize: 12, color: cMuted)),
          ]),
        ]),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
            child: Column(children: [
              Container(
                color: cMutedBg.withOpacity(0.6),
                child: const Row(children: [
                  SizedBox(width: 16),
                  Expanded(flex: 2, child: Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted)))),
                  Expanded(flex: 3, child: Text('Patient', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  Expanded(flex: 2, child: Text('Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  SizedBox(width: 16),
                ]),
              ),
              const Divider(height: 1, color: cBorder),
              Expanded(
                child: _appointments.isEmpty
                    ? const Center(child: Text('No appointments for today', style: TextStyle(fontSize: 12, color: cMuted)))
                    : ListView.separated(
                        itemCount: _appointments.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: cBorder),
                        itemBuilder: (_, i) {
                          final a = _appointments[i];
                          final name = a['patient']?['full_name'] ?? 'Walk-In';
                          final status = a['status'] ?? 'Scheduled';
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(children: [
                              Expanded(flex: 2, child: Text(a['appt_time'] ?? '—', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cFg))),
                              Expanded(flex: 3, child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cFg))),
                              Expanded(flex: 2, child: Text(a['visit_type'] ?? '—', style: const TextStyle(fontSize: 11, color: cMuted))),
                              Expanded(flex: 2, child: _statusPill(status.toLowerCase())),
                              Expanded(flex: 2, child: Row(children: [
                                if (status == 'Arrived' || status == 'Waiting') _smallBtn('Start', cPrimary.withOpacity(0.1), cPrimary, () { _updateStatus(a['appt_id'], 'In Consultation'); setState(() { _activeConsultAppt = a; _tab = 'consultations'; }); }),
                                if (status == 'In Consultation') _smallBtn('Resume', cBlue50, cBlue700, () => setState(() { _activeConsultAppt = a; _tab = 'consultations'; })),
                                if (status == 'In Consultation') ...[const SizedBox(width: 4), _smallBtn('Complete', cEm50, cEm700, () => _updateStatus(a['appt_id'], 'Completed'))],
                              ])),
                            ]),
                          );
                        },
                      ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ─── TAB 4: CONSULTATION ─────────────────────────────
  Widget _buildConsultationTab() {
    final sections = [
      {'label': 'Chief complaints', 'value': 'Recurrent migraine, throbbing left temporal region. Onset: 4 years. Aggravated by sun exposure, mental exertion.'},
      {'label': 'Modalities', 'value': 'Worse: heat, light, noise. Better: dark room, cold application, sleep.'},
      {'label': 'Mental symptoms', 'value': 'Anxious, irritable during episodes. Wants to be alone. Aversion to consolation.'},
      {'label': 'Physical generals', 'value': 'Thermal: hot patient. Thirst: large quantity, infrequent. Perspiration: scanty. Sleep: disturbed during episodes.'},
      {'label': 'Cravings / aversions', 'value': 'Cravings: salty, cold drinks. Aversions: sweets.'},
      {'label': 'Past history', 'value': 'Tonsillectomy (2008). Recurrent UTI 2018-19.'},
      {'label': 'Family history', 'value': 'Mother — migraine. Father — hypertension.'},
    ];

    final previous = [
      {'date': '28 Apr 2026', 'remedy': 'Belladonna 200, OD × 7d', 'note': 'Frequency reduced from 5 → 2 episodes/week', 'visit': '#4'},
      {'date': '14 Apr 2026', 'remedy': 'Bryonia 30, BD × 5d', 'note': 'Initial — partial relief', 'visit': '#3'},
    ];

    final appt = _activeConsultAppt;
    final patientName = appt?['patient']?['full_name'] ?? 'Anita Sharma';
    final token = appt != null ? 'T-${appt['token_number'] ?? '--'}' : 'T-12';
    final visitType = appt?['visit_type'] ?? 'Follow Up';
    final apptTime = appt?['appt_time'] ?? '10:04';

    return Column(
      children: [
        // Sub-header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: const BoxDecoration(color: cCard, border: Border(bottom: BorderSide(color: cBorder))),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(patientName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cFg)),
                const SizedBox(width: 8),
                _statusPill('in consultation'),
                const SizedBox(width: 8),
                Text('VHC-00821 · 42F · Visit #5', style: const TextStyle(fontSize: 11, color: cMuted)),
              ]),
              Row(children: [
                Text('Token $token · Started $apptTime · $visitType', style: const TextStyle(fontSize: 11, color: cMuted)),
              ]),
            ])),
            Row(children: [
              _outlineBtn('Distraction-free', Icons.fullscreen_rounded, () {}),
              const SizedBox(width: 6),
              _outlineBtn('Handwritten', Icons.edit_outlined, () {}),
              const SizedBox(width: 6),
              _outlineBtn('Save draft', Icons.save_outlined, () {}),
              const SizedBox(width: 6),
              _primaryBtn('Finalize & Prescribe', Icons.description_outlined, () {
                if (appt != null) {
                  Navigator.pushNamed(context, '/prescription', arguments: appt);
                }
              }),
            ]),
          ]),
        ),

        // Main content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Case taking (2/3)
              Expanded(flex: 2, child: Container(
                decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
                child: Column(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: cBorder))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Case Taking · Visit on 14 May 2026', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cFg)),
                      const Text('Template: Migraine — Chronic', style: TextStyle(fontSize: 11, color: cMuted)),
                    ]),
                  ),
                  ...sections.map((s) => Container(
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: cBorder))),
                    padding: const EdgeInsets.all(14),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      SizedBox(width: 140, child: Text(s['label']!, style: const TextStyle(fontSize: 11, color: cMuted))),
                      const SizedBox(width: 12),
                      Expanded(child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: cMutedBg.withOpacity(0.5), borderRadius: BorderRadius.circular(8), border: Border.all(color: cBorder)),
                        child: Text(s['value']!, style: const TextStyle(fontSize: 12, color: cFg, height: 1.5)),
                      )),
                    ]),
                  )),
                  Container(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Doctor notes', style: TextStyle(fontSize: 11, color: cMuted)),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: cMutedBg.withOpacity(0.5), borderRadius: BorderRadius.circular(8), border: Border.all(color: cBorder)),
                        child: const Text('Continue Belladonna 200; review in 14 days. Advise sleep hygiene + hydration log.', style: TextStyle(fontSize: 12, color: cFg, height: 1.5)),
                      ),
                    ]),
                  ),
                ]),
              )),
              const SizedBox(width: 20),

              // Side panel (1/3)
              SizedBox(width: 260, child: Column(children: [
                // Previous visits
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: cBorder))),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Row(children: [
                          Icon(Icons.history_rounded, size: 16, color: cMuted),
                          SizedBox(width: 6),
                          Text('Previous visits', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cFg)),
                        ]),
                        TextButton(onPressed: () {}, child: const Text('Compare', style: TextStyle(fontSize: 11, color: cPrimary))),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(children: previous.map((p) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(border: Border.all(color: cBorder), borderRadius: BorderRadius.circular(8)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text(p['date']!, style: const TextStyle(fontSize: 10, color: cMuted)),
                            Text('Visit ${p['visit']}', style: const TextStyle(fontSize: 10, color: cMuted)),
                          ]),
                          const SizedBox(height: 4),
                          Text(p['remedy']!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cFg)),
                          Text(p['note']!, style: const TextStyle(fontSize: 10, color: cMuted)),
                        ]),
                      )).toList()),
                    ),
                  ]),
                ),

                // Quick remedies
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Quick remedies', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cFg)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: ['Belladonna 200', 'Bryonia 30', 'Nat. Mur 200', 'Pulsatilla 30', 'Sepia 200', 'Ignatia 1M'].map((r) => InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(6),
                        child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: cMutedBg, borderRadius: BorderRadius.circular(6)), child: Text(r, style: const TextStyle(fontSize: 10, color: cFg))),
                      )).toList(),
                    ),
                  ]),
                ),

                // Allergy/Chronic alert
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: cAmber50, borderRadius: BorderRadius.circular(12), border: Border.all(color: cAmber200)),
                  child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.warning_amber_rounded, size: 14, color: cAmber700),
                      SizedBox(width: 6),
                      Text('Allergy & Chronic Conditions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cAmber700)),
                    ]),
                    SizedBox(height: 8),
                    Text('Allergy: Sulphonamides', style: TextStyle(fontSize: 11, color: cAmber700)),
                    SizedBox(height: 2),
                    Text('Chronic: Migraine · 4y', style: TextStyle(fontSize: 11, color: cAmber700)),
                  ]),
                ),
              ])),
            ]),
          ),
        ),
      ],
    );
  }

  // ─── TAB 5: PRESCRIPTIONS ────────────────────────────
  Widget _buildPrescriptionsTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Prescriptions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cFg)),
            Text('Digital Rx · A5 print-ready', style: TextStyle(fontSize: 12, color: cMuted)),
          ]),
          _primaryBtn('New Prescription', Icons.add_rounded, () {
            if (_activeConsultAppt != null) Navigator.pushNamed(context, '/prescription', arguments: _activeConsultAppt);
          }),
        ]),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
            child: const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.description_outlined, size: 40, color: cMuted),
              SizedBox(height: 12),
              Text('Select an appointment from the Consultations tab\nto create or view prescriptions.', style: TextStyle(fontSize: 12, color: cMuted), textAlign: TextAlign.center),
            ])),
          ),
        ),
      ]),
    );
  }

  // ─── TAB 6: BILLING ──────────────────────────────────
  Widget _buildBillingTab() {
    final statusFilters = ['All', 'Paid', 'Partial', 'Overdue', 'Draft'];
    String activeStatus = 'All';
    final metrics = [
      {'label': 'Total Invoices', 'value': '${_invoices.length}', 'icon': Icons.receipt_long_outlined, 'ic': cPrimary, 'ibg': cEm50},
      {'label': 'Paid', 'value': '${_invoices.where((i) => i['status'] == 'Paid').length}', 'icon': Icons.check_circle_outline_rounded, 'ic': cEm600, 'ibg': cEm50},
      {'label': 'Partial', 'value': '${_invoices.where((i) => i['status'] == 'Partial').length}', 'icon': Icons.pending_outlined, 'ic': cAmber700, 'ibg': cAmber50},
      {'label': 'Overdue', 'value': '${_invoices.where((i) => i['status'] == 'Draft').length}', 'icon': Icons.warning_amber_rounded, 'ic': cRed600, 'ibg': cRed50},
      {'label': 'Refunded', 'value': '0', 'icon': Icons.refresh_rounded, 'ic': cPurple700, 'ibg': cPurple50},
    ];

    return StatefulBuilder(builder: (ctx, setS) {
      final filtered = _invoices.where((inv) => activeStatus == 'All' || (inv['status'] ?? '') == activeStatus).toList();
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Row(children: metrics.map((m) => Expanded(child: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
              child: Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: m['ibg'] as Color, borderRadius: BorderRadius.circular(8)), child: Icon(m['icon'] as IconData, size: 18, color: m['ic'] as Color)),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m['label'] as String, style: const TextStyle(fontSize: 10, color: cMuted)),
                  Text(m['value'] as String, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: m['ic'] as Color)),
                ]),
              ]),
            ),
          ))).toList()),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
              child: Column(children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    Expanded(child: Row(children: statusFilters.map((f) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => setS(() => activeStatus = f),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: activeStatus == f ? cPrimary : cMutedBg, borderRadius: BorderRadius.circular(6)), child: Text(f, style: TextStyle(fontSize: 11, color: activeStatus == f ? Colors.white : cMuted))),
                      ),
                    )).toList())),
                    _primaryBtn('New Invoice', Icons.add_rounded, () {}),
                  ]),
                ),
                const Divider(height: 1, color: cBorder),
                Expanded(child: filtered.isEmpty ? const Center(child: Text('No invoices found', style: TextStyle(fontSize: 12, color: cMuted))) : ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: cBorder),
                  itemBuilder: (_, i) {
                    final inv = filtered[i];
                    final name = inv['patient']?['full_name'] ?? '—';
                    final amount = inv['total_amount'] ?? 0;
                    final status = inv['status'] ?? 'Draft';
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(children: [
                        Expanded(flex: 2, child: Text(inv['invoice_id']?.toString().substring(0, 8).toUpperCase() ?? '—', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: cPrimary, fontWeight: FontWeight.w600))),
                        Expanded(flex: 3, child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cFg))),
                        Expanded(flex: 2, child: Text('₹${(amount ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cFg))),
                        Expanded(flex: 2, child: Text('₹${(amount ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: cEm700))),
                        Expanded(flex: 2, child: _statusPill(status.toLowerCase())),
                        Expanded(flex: 2, child: _smallBtn('View', cSlate100, cSlate600, () {})),
                      ]),
                    );
                  },
                )),
              ]),
            ),
          ),
        ]),
      );
    });
  }

  // ─── SIMPLE PLACEHOLDER TABS ─────────────────────────
  Widget _buildPaymentsTab()   => _buildPlaceholderTab('Payments / Refunds', Icons.account_balance_wallet_outlined, 'Payment records and refund requests');
  Widget _buildInventoryTab()  => _buildPlaceholderTab('Inventory', Icons.inventory_2_outlined, 'Pharmacy stock & batch management');
  Widget _buildExpensesTab()   => _buildPlaceholderTab('Expenses', Icons.trending_down_rounded, 'Operational ledger & expense tracking');
  Widget _buildNotificationsTab() => _buildPlaceholderTab('Notifications', Icons.notifications_none_rounded, 'System alerts & messages');

  Widget _buildReportsTab() {
    final data = [12400.0, 14800.0, 11200.0, 16900.0, 18450.0, 22100.0, 9800.0];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cFg)),
            Text('Analytics & financial oversight', style: TextStyle(fontSize: 12, color: cMuted)),
          ]),
          _outlineBtn('Export Report', Icons.download_rounded, () {}),
        ]),
        const SizedBox(height: 20),
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 2, child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Weekly Revenue', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
                const Text('Last 7 days · in ₹', style: TextStyle(fontSize: 11, color: cMuted)),
                const SizedBox(height: 16),
                Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (int i = 0; i < data.length; i++) ...[
                    Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Container(height: (data[i] / maxVal) * 200, decoration: BoxDecoration(color: cPrimary.withOpacity(0.85), borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))),
                      const SizedBox(height: 6),
                      Text(days[i], style: const TextStyle(fontSize: 9, color: cMuted)),
                    ])),
                    if (i < data.length - 1) const SizedBox(width: 6),
                  ],
                ])),
              ]),
            )),
            const SizedBox(width: 16),
            Expanded(child: _buildModeDonut()),
          ]),
        ),
      ]),
    );
  }

  Widget _buildAuditTab() {
    final logs = [
      {'time': '10:52 AM', 'action': 'STATUS_CHANGE', 'entity': 'Appointment', 'actor': 'Dr. Verma', 'detail': 'Status: In Consultation → Completed'},
      {'time': '11:00 AM', 'action': 'INVOICE_CREATED', 'entity': 'Invoice INV-2241', 'actor': 'Priya Sharma', 'detail': 'Amount: ₹1,200 · Patient: Anita Verma'},
      {'time': '09:30 AM', 'action': 'PATIENT_REGISTERED', 'entity': 'Patient VHC-2042', 'actor': 'Priya Sharma', 'detail': 'Raj Patel registered'},
      {'time': '09:00 AM', 'action': 'LOGIN', 'entity': 'System', 'actor': 'Dr. Verma', 'detail': 'Login from 192.168.1.5'},
    ];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Audit Logs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cFg)),
        const Text('Immutable event trail', style: TextStyle(fontSize: 12, color: cMuted)),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
            child: Column(children: [
              Container(
                color: cMutedBg.withOpacity(0.6),
                child: const Row(children: [
                  SizedBox(width: 16),
                  Expanded(flex: 1, child: Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted)))),
                  Expanded(flex: 2, child: Text('Action', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  Expanded(flex: 2, child: Text('Entity', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  Expanded(flex: 2, child: Text('Actor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  Expanded(flex: 3, child: Text('Detail', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  SizedBox(width: 16),
                ]),
              ),
              const Divider(height: 1, color: cBorder),
              Expanded(
                child: ListView.separated(
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: cBorder),
                  itemBuilder: (_, i) {
                    final log = logs[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(children: [
                        Expanded(flex: 1, child: Text(log['time']!, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: cMuted))),
                        Expanded(flex: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: cSlate100, borderRadius: BorderRadius.circular(4)), child: Text(log['action']!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: cSlate600)))),
                        Expanded(flex: 2, child: Text(log['entity']!, style: const TextStyle(fontSize: 11, color: cFg))),
                        Expanded(flex: 2, child: Text(log['actor']!, style: const TextStyle(fontSize: 11, color: cPrimary))),
                        Expanded(flex: 3, child: Text(log['detail']!, style: const TextStyle(fontSize: 11, color: cMuted))),
                      ]),
                    );
                  },
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cFg)),
        const Text('Configuration & user management', style: TextStyle(fontSize: 12, color: cMuted)),
        const SizedBox(height: 24),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Profile', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
              const Divider(height: 20, color: cBorder),
              _settingsRow('Full Name', _api.fullName ?? 'Dr. V.K. Verma'),
              _settingsRow('Role', 'Doctor / Administrator'),
              _settingsRow('Clinic', 'Verma Homeopathy · Indore'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _signOut,
                style: ElevatedButton.styleFrom(backgroundColor: cRed600, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('Sign Out', style: TextStyle(fontSize: 12)),
              ),
            ]),
          )),
          const SizedBox(width: 16),
          Expanded(child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('System', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
              const Divider(height: 20, color: cBorder),
              _settingsRow('API Endpoint', _api.baseUrl),
              _settingsRow('Version', 'HCMS v2.0'),
              _settingsRow('Theme', 'Light'),
            ]),
          )),
        ]),
      ]),
    );
  }

  Widget _buildPlaceholderTab(String title, IconData icon, String sub) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Icon(icon, size: 40, color: cMuted),
    const SizedBox(height: 12),
    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: cFg)),
    Text(sub, style: const TextStyle(fontSize: 12, color: cMuted)),
  ]));

  Widget _settingsRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: cMuted)),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cFg)),
    ]),
  );

  // ─── SHARED HELPERS ──────────────────────────────────
  Widget _statusPill(String status) {
    final Map<String, List<Color>> pm = {
      'scheduled': [cSlate100, cSlate600], 'arrived': [cBlue50, cBlue700], 'waiting': [cAmber50, cAmber700],
      'in consultation': [cAmber50, cAmber700], 'completed': [cEm50, cEm700], 'cancelled': [cRed50, cRed600],
      'no show': [cSlate100, cSlate600], 'paid': [cEm50, cEm700], 'partial': [cAmber50, cAmber700],
      'draft': [cSlate100, cSlate600], 'active': [cEm50, cEm700], 'follow-up': [cPurple50, cPurple700],
    };
    final colors = pm[status.toLowerCase()] ?? [cSlate100, cMuted];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: colors[0], borderRadius: BorderRadius.circular(100), border: Border.all(color: colors[1].withOpacity(0.2))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 5, height: 5, decoration: BoxDecoration(color: colors[1].withOpacity(0.8), borderRadius: BorderRadius.circular(100))),
        const SizedBox(width: 5),
        Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colors[1])),
      ]),
    );
  }

  Widget _smallBtn(String label, Color bg, Color fg, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)), child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg))),
  );

  Widget _primaryBtn(String label, IconData? icon, VoidCallback onTap) => ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(backgroundColor: cPrimary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    child: icon != null ? Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14), const SizedBox(width: 5), Text(label)]) : Text(label),
  );

  Widget _outlineBtn(String label, IconData? icon, VoidCallback onTap) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(foregroundColor: cFg, side: const BorderSide(color: cBorder), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
    child: icon != null ? Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 14), const SizedBox(width: 5), Text(label)]) : Text(label),
  );
}
