import 'dart:convert';
import 'dart:html' as html;
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../services/api_service.dart';

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

double _parseAmount(dynamic v) => double.tryParse('${v ?? 0}') ?? 0.0;

String _shortId(dynamic id) {
  final s = '${id ?? ''}';
  return s.length > 8 ? s.substring(0, 8).toUpperCase() : s.toUpperCase();
}

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
  List<dynamic> _notifications = [];
  List<dynamic> _auditLogs = [];
  Map<String, dynamic>? _activeConsultAppt;
  String _searchQ = '';
  String _billingFilter = 'All';
  String? _error;
  DateTime? _lastFetched;

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final clinics = await _api.getClinics();
      if (!mounted) return;
      if (clinics.isNotEmpty) _clinicId = clinics.first['clinic_id'];
      if (_clinicId == null) {
        setState(() => _loading = false);
        return;
      }
      final results = await Future.wait([
        _api.getKpis(_clinicId!, _date),
        _api.getAppointments(clinicId: _clinicId, date: _date),
        _api.getPatients(),
        _api.getInvoices(),
        _api.getAuditLogs(),
        _api.getNotifications().catchError((_) => <dynamic>[]),
      ]);
      if (!mounted) return;
      final kpis = results[0] as Map<String, dynamic>;
      final appts = results[1] as List<dynamic>;
      Map<String, dynamic>? activeConsult;
      for (final a in appts) {
        if (a['status'] == AppointmentStatus.inConsultation) {
          activeConsult = a;
          break;
        }
      }
      setState(() {
        _kpis = kpis;
        _appointments = appts;
        _patients = results[2] as List<dynamic>;
        _invoices = results[3] as List<dynamic>;
        _auditLogs = results[4] as List<dynamic>;
        _notifications = results[5] as List<dynamic>;
        _activeConsultAppt = activeConsult;
        _lastFetched = DateTime.now();
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load dashboard data. $e';
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(String apptId, String status) async {
    try {
      await _api.updateAppointmentStatus(apptId, status);
      if (!mounted) return;
      _fetchData();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: cRed600));
    }
  }

  void _signOut() {
    _api.logoutRemote();
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
          Expanded(child: _loading
              ? const Center(child: CircularProgressIndicator(color: cPrimary))
              : _error != null ? _buildErrorState() : _buildBody()),
        ])),
      ]),
    );
  }

  Widget _buildErrorState() {
    return Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.cloud_off_rounded, size: 40, color: cMuted),
        const SizedBox(height: 12),
        Text(_error ?? 'Something went wrong', style: const TextStyle(fontSize: 13, color: cFg), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        _primaryBtn('Retry', Icons.refresh_rounded, _fetchData),
      ]),
    ));
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
            Padding(padding: EdgeInsets.only(left: 8, top: 4), child: Row(children: [
              CircleAvatar(backgroundColor: cEm600, radius: 3),
              SizedBox(width: 6),
              Text(_lastFetched == null ? 'Not synced' : 'Synced ${_lastFetched!.toIso8601String().substring(11, 19)}', style: TextStyle(fontSize: 11, color: cMuted)),
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
          IconButton(onPressed: () => setState(() => _tab = 'notifications'), icon: Icon(Icons.notifications_none_rounded, size: 20, color: _notifications.isNotEmpty ? cPrimary : cMuted)),
          if (_notifications.isNotEmpty)
            Positioned(top: 8, right: 8, child: Container(
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              padding: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(color: cRed600, borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white, width: 1.2)),
              child: Center(child: Text('${_notifications.length}', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white))),
            )),
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
    final todayRevenue = (_kpis['today_revenue'] as num?)?.toDouble() ?? 0.0;
    final todayPts     = (_kpis['today_patients'] as num?)?.toInt() ?? 0;
    final pendingDues  = (_kpis['pending_dues'] as num?)?.toDouble() ?? 0.0;
    final apptCount    = _appointments.length;
    final completed    = _appointments.where((a) => a['status'] == AppointmentStatus.completed).length;
    final noShow       = _appointments.where((a) => a['status'] == AppointmentStatus.noShow).length;
    final walkIns      = _appointments.where((a) => a['visit_type'] == VisitType.walkIn).length;
    final followUps    = _appointments.where((a) => a['visit_type'] == VisitType.followUp).length;
    final newVisits    = _appointments.where((a) => a['visit_type'] == VisitType.newVisit).length;
    final duesCount    = _invoices.where((i) => ((i['due_amount'] ?? 0) as num) > 0).length;

    final kpis = [
      {'label': 'Daily Revenue', 'value': '₹${todayRevenue.toStringAsFixed(0)}', 'delta': '', 'up': true, 'hint': 'Collections recorded today', 'icon': Icons.currency_rupee_rounded, 'iconColor': cPrimary, 'iconBg': cEm50},
      {'label': 'Patients Today', 'value': '$todayPts', 'delta': '$walkIns walk-ins', 'up': true, 'hint': '$followUps follow-ups · $newVisits new', 'icon': Icons.people_outline_rounded, 'iconColor': cMuted, 'iconBg': cMutedBg},
      {'label': 'Appointments', 'value': '$apptCount', 'delta': '$noShow no-show', 'up': false, 'hint': '$completed completed · ${apptCount - completed} remaining', 'icon': Icons.calendar_month_outlined, 'iconColor': cMuted, 'iconBg': cMutedBg},
      {'label': 'Pending Dues', 'value': '₹${pendingDues.toStringAsFixed(0)}', 'delta': '$duesCount invoices', 'up': false, 'hint': 'Across all unpaid invoices', 'icon': Icons.warning_amber_rounded, 'iconColor': cAmber700, 'iconBg': cAmber50},
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
          _outlineBtn('Refresh', Icons.refresh_rounded, _fetchData),
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
                if ((k['delta'] as String).isNotEmpty) const SizedBox(width: 6),
                if ((k['delta'] as String).isNotEmpty) Padding(
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

  /// Daily revenue for the last 7 days, derived from real invoices
  /// (grouped by invoice updated_at date).
  List<Map<String, dynamic>> _revenueSeries() {
    final now = DateTime.now();
    final keys = <String>[];
    final buckets = <String, double>{};
    for (int i = 6; i >= 0; i--) {
      final key = now.subtract(Duration(days: i)).toIso8601String().split('T')[0];
      keys.add(key);
      buckets[key] = 0.0;
    }
    for (final inv in _invoices) {
      final raw = inv['updated_at'] ?? inv['issued_at'];
      if (raw == null) continue;
      final key = raw.toString().split('T').first;
      if (buckets.containsKey(key)) {
        buckets[key] = buckets[key]! + ((inv['total_amount'] ?? 0) as num).toDouble();
      }
    }
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return [
      for (final key in keys)
        {
          'label': dayNames[DateTime.parse(key).weekday % 7],
          'value': buckets[key]!,
        }
    ];
  }

  Widget _buildRevenueChart() {
    final series = _revenueSeries();
    final data = series.map((s) => s['value'] as double).toList();
    final days = series.map((s) => s['label'] as String).toList();
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Revenue', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
            Text('Last 7 days · from invoices', style: TextStyle(fontSize: 11, color: cMuted)),
          ]),
          Row(children: [
            Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: cPrimary, borderRadius: BorderRadius.circular(2))), const SizedBox(width: 4), const Text('Revenue', style: TextStyle(fontSize: 10, color: cMuted))]),
          ]),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          height: 140,
          child: maxVal == 0
              ? const Center(child: Text('No revenue recorded in the last 7 days', style: TextStyle(fontSize: 11, color: cMuted)))
              : Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (int i = 0; i < data.length; i++) ...[
                    Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Container(height: (data[i] / maxVal) * 120, decoration: BoxDecoration(color: cPrimary.withOpacity(0.85), borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))),
                      const SizedBox(height: 6),
                      Text(days[i], style: const TextStyle(fontSize: 9, color: cMuted)),
                    ])),
                    if (i < data.length - 1) const SizedBox(width: 4),
                  ],
                ],
              ),
        ),
      ]),
    );
  }

  Widget _buildModeDonut() {
    // Aggregate real payment modes from invoice payments.
    final today = DateTime.now().toIso8601String().split('T')[0];
    final totals = <String, double>{};
    double grandTotal = 0;
    for (final inv in _invoices) {
      for (final p in (inv['payments'] ?? []) as List) {
        final paidAt = p['paid_at']?.toString().split('T').first;
        if (paidAt != null && paidAt != today) continue;
        final mode = (p['payment_mode'] ?? 'Unknown') as String;
        final amt = ((p['amount'] ?? 0) as num).toDouble();
        totals[mode] = (totals[mode] ?? 0) + amt;
        grandTotal += amt;
      }
    }
    const modeColors = {
      PaymentMode.cash: cPrimary,
      PaymentMode.upi: Color(0xFF14B8A6),
      PaymentMode.card: Color(0xFF5EEAD4),
      PaymentMode.online: Color(0xFF99F6E4),
    };
    final modes = [
      for (final mode in PaymentMode.all)
        if (totals.containsKey(mode))
          {
            'name': mode,
            'pct': grandTotal > 0 ? (totals[mode]! / grandTotal * 100) : 0.0,
            'amount': '₹${totals[mode]!.toStringAsFixed(0)}',
            'color': modeColors[mode] ?? cSlate400,
          },
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Collections by Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
        Text('Today · ₹${grandTotal.toStringAsFixed(0)} total', style: const TextStyle(fontSize: 11, color: cMuted)),
        const SizedBox(height: 16),
        if (modes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text('No payments recorded today', style: TextStyle(fontSize: 11, color: cMuted))),
          )
        else ...[
          // Stacked progress bar as donut substitute
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: SizedBox(
              height: 16,
              child: Row(
                children: modes.map((m) => Expanded(
                  flex: ((m['pct'] as double).toInt() + 1),
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
                Text('${(m['pct'] as double).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cFg)),
                Text(m['amount'] as String, style: const TextStyle(fontSize: 9, color: cMuted)),
              ]),
            ]),
          )),
        ],
      ]),
    );
  }

  Widget _buildRecentInvoicesCard(List<dynamic> invs) {
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
            Expanded(flex: 2, child: Text('Due', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
            Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
            SizedBox(width: 16),
          ]),
        ),
        const Divider(height: 1, color: cBorder),
        if (invs.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: Text('No invoices found', style: TextStyle(fontSize: 12, color: cMuted))),
          )
        else
          ...invs.map((inv) {
            final status = (inv['status'] ?? InvoiceStatus.draft) as String;
            final total = ((inv['total_amount'] ?? 0) as num).toDouble();
            final due = ((inv['due_amount'] ?? 0) as num).toDouble();
            final patientName = inv['patient']?['full_name'] ?? '—';
            final invId = inv['invoice_id']?.toString() ?? '';
            return InkWell(
              onTap: () => _showInvoiceDetail(inv),
              child: Container(
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: cBorder))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(children: [
                    Expanded(flex: 2, child: Text(_shortId(invId).isEmpty ? '—' : _shortId(invId), style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: cPrimary, fontWeight: FontWeight.w600))),
                    Expanded(flex: 3, child: Text(patientName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cFg))),
                    Expanded(flex: 2, child: Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cFg))),
                    Expanded(flex: 2, child: Text('₹${due.toStringAsFixed(0)}', style: TextStyle(fontSize: 11, color: due > 0 ? cRed600 : cEm700))),
                    Expanded(flex: 2, child: _statusPill(status)),
                  ]),
                ),
              ),
            );
          }),
      ]),
    );
  }

  void _showInvoiceDetail(Map<String, dynamic> inv) {
    showDialog(context: context, builder: (ctx) {
      String fmt(Object? v) => v == null ? '—' : v.toString();
      final rows = <Map<String, String>>[
        {'k': 'Invoice ID', 'v': fmt(inv['invoice_id'])},
        {'k': 'Status', 'v': fmt(inv['status'])},
        {'k': 'Patient', 'v': fmt(inv['patient']?['full_name'] ?? inv['patient_id'])},
        {'k': 'Consultation Fee', 'v': '₹${fmt(inv['consultation_fee'])}'},
        {'k': 'Medicine Charges', 'v': '₹${fmt(inv['medicine_charges'])}'},
        {'k': 'Misc Charges', 'v': '₹${fmt(inv['misc_charges'])}'},
        {'k': 'Discount', 'v': '₹${fmt(inv['discount'])}'},
        {'k': 'Total Amount', 'v': '₹${fmt(inv['total_amount'])}'},
        {'k': 'Paid Amount', 'v': '₹${fmt(inv['paid_amount'])}'},
        {'k': 'Due Amount', 'v': '₹${fmt(inv['due_amount'])}'},
        {'k': 'Issued At', 'v': fmt(inv['issued_at'])},
        {'k': 'Last Updated', 'v': fmt(inv['updated_at'])},
      ];
      return AlertDialog(
        title: const Text('Invoice Detail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cFg)),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              for (final r in rows) Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 140, child: Text(r['k']!, style: const TextStyle(fontSize: 11, color: cMuted))),
                  Expanded(child: Text(r['v']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cFg))),
                ]),
              ),
            ]),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      );
    });
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
          _outlineBtn('Export', Icons.download_rounded, _exportPatientsCsv),
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
                              Expanded(flex: 2, child: _smallBtn('View Profile', cPrimary.withOpacity(0.1), cPrimary, () => _showPatientProfile(p))),
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
                          final status = (a['status'] ?? AppointmentStatus.scheduled) as String;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(children: [
                              Expanded(flex: 2, child: Text(a['appt_time'] ?? '—', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cFg))),
                              Expanded(flex: 3, child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cFg))),
                              Expanded(flex: 2, child: Text(a['visit_type'] ?? '—', style: const TextStyle(fontSize: 11, color: cMuted))),
                              Expanded(flex: 2, child: _statusPill(status)),
                              Expanded(flex: 2, child: Row(children: [
                                if (status == AppointmentStatus.arrived) _smallBtn('Start', cPrimary.withOpacity(0.1), cPrimary, () { _updateStatus(a['appt_id'], AppointmentStatus.inConsultation); setState(() { _activeConsultAppt = a; _tab = 'consultations'; }); }),
                                if (status == AppointmentStatus.inConsultation) _smallBtn('Resume', cBlue50, cBlue700, () => setState(() { _activeConsultAppt = a; _tab = 'consultations'; })),
                                if (status == AppointmentStatus.inConsultation) ...[const SizedBox(width: 4), _smallBtn('Complete', cEm50, cEm700, () => _updateStatus(a['appt_id'], AppointmentStatus.completed))],
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
    final appt = _activeConsultAppt;

    // No active consultation: honest empty state instead of demo data.
    if (appt == null) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.medical_services_outlined, size: 40, color: cMuted),
        const SizedBox(height: 12),
        const Text('No consultation in progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cFg)),
        const SizedBox(height: 6),
        Text('Start an ${AppointmentStatus.arrived} appointment from the Appointments tab.', style: const TextStyle(fontSize: 12, color: cMuted), textAlign: TextAlign.center),
      ]));
    }

    // Case-taking fields are filled in by the doctor during the visit.
    final sections = [
      {'label': 'Chief complaints', 'value': 'To be recorded during consultation'},
      {'label': 'Modalities', 'value': 'To be recorded during consultation'},
      {'label': 'Mental symptoms', 'value': 'To be recorded during consultation'},
      {'label': 'Physical generals', 'value': 'To be recorded during consultation'},
      {'label': 'Cravings / aversions', 'value': 'To be recorded during consultation'},
      {'label': 'Past history', 'value': 'To be recorded during consultation'},
      {'label': 'Family history', 'value': 'To be recorded during consultation'},
    ];

    final patientName = appt['patient']?['full_name'] ?? 'Walk-In';
    final token = 'T-${appt['token_number'] ?? '--'}';
    final visitType = (appt['visit_type'] ?? VisitType.newVisit) as String;
    final apptTime = appt['appt_time'] ?? '—';
    final apptDate = appt['appt_date'] ?? _date;

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
                _statusPill(AppointmentStatus.inConsultation),
              ]),
              Row(children: [
                Text('Token $token · $apptDate · Started $apptTime · $visitType', style: const TextStyle(fontSize: 11, color: cMuted)),
              ]),
            ])),
            _primaryBtn('Finalize & Prescribe', Icons.description_outlined, () {
              Navigator.pushNamed(context, '/prescription', arguments: appt);
            }),
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
                      Text('Case Taking · Visit on $apptDate', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cFg)),
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
                        child: Text((appt['notes'] ?? 'No appointment notes.') as String, style: const TextStyle(fontSize: 12, color: cFg, height: 1.5)),
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
                      child: const Row(children: [
                        Icon(Icons.history_rounded, size: 16, color: cMuted),
                        SizedBox(width: 6),
                        Text('Previous visits', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cFg)),
                      ]),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('Prescription history is available in the patient record.', style: TextStyle(fontSize: 11, color: cMuted), textAlign: TextAlign.center)),
                    ),
                  ]),
                ),

                // Quick remedies (reference labels)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Common remedies', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cFg)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6, runSpacing: 6,
                      children: ['Belladonna 200', 'Bryonia 30', 'Nat. Mur 200', 'Pulsatilla 30', 'Sepia 200', 'Ignatia 1M'].map((r) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: cMutedBg, borderRadius: BorderRadius.circular(6)), child: Text(r, style: const TextStyle(fontSize: 10, color: cFg)))).toList(),
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
  static const _overdueFilter = 'Overdue';

  Widget _buildBillingTab() {
    final isOverdue = (dynamic inv) =>
        inv['status'] == InvoiceStatus.issued && _parseAmount(inv['due_amount']) > 0;
    final statusFilters = ['All', InvoiceStatus.paid, InvoiceStatus.partiallyPaid, _overdueFilter, InvoiceStatus.draft];
    final metrics = [
      {'label': 'Total Invoices', 'value': '${_invoices.length}', 'icon': Icons.receipt_long_outlined, 'ic': cPrimary, 'ibg': cEm50},
      {'label': 'Paid', 'value': '${_invoices.where((i) => i['status'] == InvoiceStatus.paid).length}', 'icon': Icons.check_circle_outline_rounded, 'ic': cEm600, 'ibg': cEm50},
      {'label': 'Partially Paid', 'value': '${_invoices.where((i) => i['status'] == InvoiceStatus.partiallyPaid).length}', 'icon': Icons.pending_outlined, 'ic': cAmber700, 'ibg': cAmber50},
      {'label': 'Overdue', 'value': '${_invoices.where(isOverdue).length}', 'icon': Icons.warning_amber_rounded, 'ic': cRed600, 'ibg': cRed50},
      {'label': 'Draft', 'value': '${_invoices.where((i) => i['status'] == InvoiceStatus.draft).length}', 'icon': Icons.edit_note_rounded, 'ic': cSlate600, 'ibg': cSlate50},
    ];

    return StatefulBuilder(builder: (ctx, setS) {
      final filtered = _invoices.where((inv) {
        switch (_billingFilter) {
          case 'All':
            return true;
          case _overdueFilter:
            return isOverdue(inv);
          default:
            return inv['status'] == _billingFilter;
        }
      }).toList();
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
                        onTap: () => setS(() => _billingFilter = f),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: _billingFilter == f ? cPrimary : cMutedBg, borderRadius: BorderRadius.circular(6)), child: Text(f, style: TextStyle(fontSize: 11, color: _billingFilter == f ? Colors.white : cMuted))),
                      ),
                    )).toList())),
                    _primaryBtn('New Invoice', Icons.add_rounded, _openNewInvoiceDialog),
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
                    final status = inv['status'] ?? InvoiceStatus.draft;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(children: [
                        Expanded(flex: 2, child: Text(_shortId(inv['invoice_id']), style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: cPrimary, fontWeight: FontWeight.w600))),
                        Expanded(flex: 3, child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cFg))),
                        Expanded(flex: 2, child: Text('₹${(amount ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cFg))),
                        Expanded(flex: 2, child: Text('₹${(amount ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: cEm700))),
                        Expanded(flex: 2, child: _statusPill(status.toLowerCase())),
                        Expanded(flex: 2, child: _smallBtn('View', cSlate100, cSlate600, () => _showInvoiceDetail(inv))),
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
  Widget _buildNotificationsTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cFg)),
            Text('System alerts & messages', style: TextStyle(fontSize: 12, color: cMuted)),
          ]),
          Text('${_notifications.length} total', style: const TextStyle(fontSize: 12, color: cMuted)),
        ]),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
            child: _notifications.isEmpty
                ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.notifications_none_rounded, size: 32, color: cMuted),
                    SizedBox(height: 8),
                    Text('No notifications', style: TextStyle(fontSize: 12, color: cMuted)),
                  ]))
                : ListView.separated(
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: cBorder),
                    itemBuilder: (_, i) {
                      final n = _notifications[i];
                      final body = '${n['body'] ?? ''}';
                      final channel = '${n['channel'] ?? ''}';
                      final status = '${n['status'] ?? ''}';
                      final createdAt = '${n['created_at'] ?? ''}';
                      final shortTime = createdAt.length > 16 ? createdAt.substring(0, 16).replaceFirst('T', ' ') : createdAt;
                      final iconData = channel == 'SMS' ? Icons.sms_rounded : channel == 'WhatsApp' ? Icons.chat_rounded : Icons.email_rounded;
                      final iconColor = channel == 'SMS' ? cPrimary : channel == 'WhatsApp' ? cEm600 : cBlue700;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(width: 32, height: 32, decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(iconData, size: 16, color: iconColor)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(body, style: const TextStyle(fontSize: 12, color: cFg), maxLines: 3, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(children: [
                              Text(channel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: iconColor)),
                              const SizedBox(width: 8),
                              Text('·', style: const TextStyle(fontSize: 10, color: cMuted)),
                              const SizedBox(width: 8),
                              Text(shortTime, style: const TextStyle(fontSize: 10, color: cMuted)),
                            ]),
                          ])),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: status == 'Sent' ? cEm50 : status == 'Failed' ? cRed50 : cAmber50,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: status == 'Sent' ? cEm600 : status == 'Failed' ? cRed600 : cAmber700)),
                          ),
                        ]),
                      );
                    },
                  ),
          ),
        ),
      ]),
    );
  }

  Widget _buildReportsTab() {
    // Compute real revenue data from invoices/payments already fetched
    final Map<String, double> dailyRevenue = {};
    for (final inv in _invoices) {
      for (final p in (inv['payments'] ?? []) as List) {
        final paidAt = '${p['paid_at'] ?? ''}';
        if (paidAt.length >= 10) {
          final day = paidAt.substring(0, 10);
          final amt = ((p['amount'] ?? 0) as num).toDouble();
          dailyRevenue[day] = (dailyRevenue[day] ?? 0) + amt;
        }
      }
    }
    // Sort by date descending, take last 7
    final sortedDays = dailyRevenue.keys.toList()..sort();
    final last7 = sortedDays.length > 7 ? sortedDays.sublist(sortedDays.length - 7) : sortedDays;
    final data = last7.map((d) => dailyRevenue[d]!).toList();
    final days = last7.map((d) {
      try {
        final dt = DateTime.parse(d);
        return ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][dt.weekday % 7];
      } catch (_) { return d.substring(5); }
    }).toList();
    final maxVal = data.isNotEmpty ? data.reduce((a, b) => a > b ? a : b) : 1.0;

    // Compute total stats
    double totalRevenue = 0;
    int totalPaid = 0;
    int totalPending = 0;
    for (final inv in _invoices) {
      final paidAmt = ((inv['paid_amount'] ?? 0) as num).toDouble();
      final dueAmt = ((inv['due_amount'] ?? 0) as num).toDouble();
      totalRevenue += paidAmt;
      if (dueAmt > 0) totalPending++;
      else totalPaid++;
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cFg)),
            Text('Analytics & financial oversight', style: TextStyle(fontSize: 12, color: cMuted)),
          ]),
        ]),
        const SizedBox(height: 16),
        // Summary cards
        Row(children: [
          _reportMetric('Total Collected', '₹${totalRevenue.toStringAsFixed(0)}', cEm600),
          const SizedBox(width: 12),
          _reportMetric('Paid Invoices', '$totalPaid', cPrimary),
          const SizedBox(width: 12),
          _reportMetric('Pending Invoices', '$totalPending', cAmber700),
        ]),
        const SizedBox(height: 20),
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 2, child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Revenue Trend', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
                const Text('Last 7 days with payments · in ₹', style: TextStyle(fontSize: 11, color: cMuted)),
                const SizedBox(height: 16),
                if (data.isEmpty)
                  const Expanded(child: Center(child: Text('No revenue data yet', style: TextStyle(fontSize: 12, color: cMuted))))
                else
                  Expanded(child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    for (int i = 0; i < data.length; i++) ...[
                      Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Tooltip(
                          message: '₹${data[i].toStringAsFixed(0)}',
                          child: Container(height: (data[i] / maxVal) * 200, decoration: BoxDecoration(color: cPrimary.withOpacity(0.85), borderRadius: const BorderRadius.vertical(top: Radius.circular(6)))),
                        ),
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

  Widget _reportMetric(String label, String value, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 10, color: cMuted)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
      ]),
    ),
  );

  Widget _buildAuditTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Audit Logs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cFg)),
            Text('Immutable event trail', style: TextStyle(fontSize: 12, color: cMuted)),
          ]),
          Text('${_auditLogs.length} entries', style: const TextStyle(fontSize: 12, color: cMuted)),
        ]),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
            child: _auditLogs.isEmpty
                ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.verified_user_outlined, size: 32, color: cMuted),
                    SizedBox(height: 8),
                    Text('No audit logs', style: TextStyle(fontSize: 12, color: cMuted)),
                  ]))
                : Column(children: [
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
                        itemCount: _auditLogs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: cBorder),
                        itemBuilder: (_, i) {
                          final log = _auditLogs[i];
                          final ts = '${log['timestamp'] ?? ''}';
                          final timeStr = ts.length > 16 ? ts.substring(11, 16) : ts;
                          final action = '${log['action'] ?? ''}';
                          final entityType = '${log['entity_type'] ?? ''}';
                          final entityId = '${log['entity_id'] ?? ''}';
                          final changes = log['changes_json'] as Map<String, dynamic>?;
                          final after = changes?['after'] as Map<String, dynamic>?;
                          String detail = '';
                          if (after != null && after.isNotEmpty) {
                            final keys = after.keys.where((k) => k != 'password_hash' && k != 'password').take(2).toList();
                            detail = keys.map((k) => '$k: ${after[k]}').join(', ');
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(children: [
                              Expanded(flex: 1, child: Text(timeStr, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: cMuted))),
                              Expanded(flex: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: cSlate100, borderRadius: BorderRadius.circular(4)), child: Text(action, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, fontFamily: 'monospace', color: cSlate600)))),
                              Expanded(flex: 2, child: Text(entityType, style: const TextStyle(fontSize: 11, color: cFg))),
                              Expanded(flex: 2, child: Text(_shortId(entityId), style: const TextStyle(fontSize: 11, color: cPrimary, fontFamily: 'monospace'))),
                              Expanded(flex: 3, child: Text(detail, style: const TextStyle(fontSize: 11, color: cMuted), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
      AppointmentStatus.scheduled.toLowerCase(): [cSlate100, cSlate600],
      AppointmentStatus.arrived.toLowerCase(): [cBlue50, cBlue700],
      AppointmentStatus.inConsultation.toLowerCase(): [cAmber50, cAmber700],
      AppointmentStatus.completed.toLowerCase(): [cEm50, cEm700],
      AppointmentStatus.cancelled.toLowerCase(): [cRed50, cRed600],
      AppointmentStatus.noShow.toLowerCase(): [cSlate100, cSlate600],
      InvoiceStatus.paid.toLowerCase(): [cEm50, cEm700],
      InvoiceStatus.partiallyPaid.toLowerCase(): [cAmber50, cAmber700],
      InvoiceStatus.draft.toLowerCase(): [cSlate100, cSlate600],
      InvoiceStatus.issued.toLowerCase(): [cBlue50, cBlue700],
      VisitType.followUp.toLowerCase(): [cPurple50, cPurple700],
      VisitType.newVisit.toLowerCase(): [cEm50, cEm700],
      VisitType.walkIn.toLowerCase(): [cOrange50, cOrange500],
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

  void _showPatientProfile(Map<String, dynamic> p) {
    showDialog(context: context, builder: (ctx) {
      String fmt(Object? v) => v == null ? '—' : v.toString();
      final rows = <Map<String, String>>[
        {'k': 'Patient ID', 'v': fmt(p['unique_patient_id'])},
        {'k': 'Full Name', 'v': fmt(p['full_name'])},
        {'k': 'Age', 'v': fmt(p['age'])},
        {'k': 'Gender', 'v': fmt(p['gender'])},
        {'k': 'Phone', 'v': fmt(p['mobile_number'])},
        {'k': 'Email', 'v': fmt(p['email'])},
        {'k': 'Address', 'v': fmt(p['address'])},
        {'k': 'Blood Group', 'v': fmt(p['blood_group'])},
        {'k': 'Allergies', 'v': fmt(p['allergies'])},
        {'k': 'Medical History', 'v': fmt(p['medical_history'])},
        {'k': 'Registered', 'v': fmt(p['created_at'])},
      ];
      return AlertDialog(
        title: Text(fmt(p['full_name']), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cFg)),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              for (final r in rows) Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 120, child: Text(r['k']!, style: const TextStyle(fontSize: 11, color: cMuted))),
                  Expanded(child: Text(r['v']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cFg))),
                ]),
              ),
            ]),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      );
    });
  }

  void _exportPatientsCsv() async {
    try {
      final patients = _patients;
      final excel = Excel.createExcel();
      final sheet = excel['Patients'];
      excel.setDefaultSheet('Patients');

      // Header row
      sheet.appendRow([TextCellValue('Patient ID'), TextCellValue('Name'), TextCellValue('Age'), TextCellValue('Gender'), TextCellValue('Phone'), TextCellValue('Email'), TextCellValue('Address'), TextCellValue('Blood Group')]);

      // Data rows
      for (final p in patients) {
        sheet.appendRow([
          TextCellValue('${p['unique_patient_id'] ?? ''}'),
          TextCellValue('${p['full_name'] ?? ''}'),
          TextCellValue('${p['age'] ?? ''}'),
          TextCellValue('${p['gender'] ?? ''}'),
          TextCellValue('${p['mobile_number'] ?? ''}'),
          TextCellValue('${p['email'] ?? ''}'),
          TextCellValue('${p['address'] ?? ''}'),
          TextCellValue('${p['blood_group'] ?? ''}'),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)..setAttribute('download', 'patients_export.xlsx')..click();
        html.Url.revokeObjectUrl(url);
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient list exported as Excel')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  void _openNewInvoiceDialog() {
    final patientCtrl = TextEditingController();
    final consultationFeeCtrl = TextEditingController(text: '500');
    final medicineChargesCtrl = TextEditingController(text: '0');
    final miscChargesCtrl = TextEditingController(text: '0');
    final discountCtrl = TextEditingController(text: '0');

    showDialog(context: context, builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setDialogState) {
        return AlertDialog(
          title: const Text('New Invoice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cFg)),
          content: SizedBox(
            width: 340,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Patient ID', labelStyle: TextStyle(fontSize: 12)),
                  items: _patients.map((p) => DropdownMenuItem(value: p['unique_patient_id'] as String?, child: Text('${p['full_name']} (${p['unique_patient_id']})', style: const TextStyle(fontSize: 11)))).toList(),
                  onChanged: (v) => patientCtrl.text = v ?? '',
                ),
                const SizedBox(height: 12),
                _dialogField('Consultation Fee', consultationFeeCtrl),
                const SizedBox(height: 12),
                _dialogField('Medicine Charges', medicineChargesCtrl),
                const SizedBox(height: 12),
                _dialogField('Misc Charges', miscChargesCtrl),
                const SizedBox(height: 12),
                _dialogField('Discount', discountCtrl),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (patientCtrl.text.isEmpty) return;
                try {
                  await _api.createInvoice({
                    'patient_id': patientCtrl.text,
                    'consultation_fee': double.tryParse(consultationFeeCtrl.text) ?? 0,
                    'medicine_charges': double.tryParse(medicineChargesCtrl.text) ?? 0,
                    'misc_charges': double.tryParse(miscChargesCtrl.text) ?? 0,
                    'discount': double.tryParse(discountCtrl.text) ?? 0,
                  });
                  if (mounted) Navigator.pop(ctx);
                  _fetchData();
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice created')));
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: cPrimary, foregroundColor: Colors.white),
              child: const Text('Create', style: TextStyle(fontSize: 12)),
            ),
          ],
        );
      });
    });
  }

  Widget _dialogField(String label, TextEditingController ctrl) => TextField(
    controller: ctrl,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 12), isDense: true),
    style: const TextStyle(fontSize: 12),
  );
}
