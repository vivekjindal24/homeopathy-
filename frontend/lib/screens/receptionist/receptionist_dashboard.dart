import 'package:flutter/material.dart';
import '../../services/api_service.dart';

// ─── Color System ────────────────────────────────────
const cBg       = Color(0xFFF8FAFC);   // slate-50
const cCard     = Color(0xFFFFFFFF);   // white
const cBorder   = Color(0x1A000000);   // rgba(0,0,0,0.1)
const cFg       = Color(0xFF0F172A);   // near-black
const cMuted    = Color(0xFF717182);   // muted-foreground
const cMutedBg  = Color(0xFFECECF0);   // muted bg
const cAccent   = Color(0xFFE9EBEF);   // accent
const cPrimary  = Color(0xFF0F766E);   // teal primary

// Semantic colors
const cAmber50  = Color(0xFFFFFBEB);
const cAmber100 = Color(0xFFFEF3C7);
const cAmber200 = Color(0xFFFDE68A);
const cAmber700 = Color(0xFFB45309);
const cBlue50   = Color(0xFFEFF6FF);
const cBlue100  = Color(0xFFDBEAFE);
const cBlue200  = Color(0xFFBFDBFE);
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
const cOrange100= Color(0xFFFFEDD5);
const cOrange500= Color(0xFFF97316);

class ReceptionistDashboard extends StatefulWidget {
  const ReceptionistDashboard({super.key});
  @override
  State<ReceptionistDashboard> createState() => _ReceptionistDashboardState();
}

class _ReceptionistDashboardState extends State<ReceptionistDashboard> {
  final ApiService _api = ApiService();
  String _tab = 'dashboard';
  bool _loading = false;
  List<dynamic> _clinics = [];
  String? _clinicId;
  String _date = DateTime.now().toIso8601String().split('T')[0];
  Map<String, dynamic> _kpis = {'today_patients': 0, 'active_queue': 0, 'today_revenue': 0.0, 'pending_dues': 0.0};
  List<dynamic> _appointments = [];
  List<dynamic> _patients = [];
  List<dynamic> _invoices = [];
  List<dynamic> _queue = [];
  String _searchQ = '';

  final _navGroups = [
    {
      'label': 'OVERVIEW',
      'items': [
        {'key': 'dashboard', 'label': 'Dashboard', 'icon': Icons.grid_view_rounded},
      ],
    },
    {
      'label': 'FRONT DESK',
      'items': [
        {'key': 'patients', 'label': 'Patients', 'icon': Icons.people_outline_rounded},
        {'key': 'appointments', 'label': 'Appointments', 'icon': Icons.calendar_month_outlined},
        {'key': 'queue', 'label': 'Queue Management', 'icon': Icons.format_list_numbered_rounded, 'badge': 'queue'},
      ],
    },
    {
      'label': 'FINANCE',
      'items': [
        {'key': 'billing', 'label': 'Billing & Invoices', 'icon': Icons.receipt_long_outlined},
        {'key': 'payments', 'label': 'Payments', 'icon': Icons.account_balance_wallet_outlined},
      ],
    },
    {
      'label': 'CLINIC',
      'items': [
        {'key': 'inventory', 'label': 'Inventory', 'icon': Icons.inventory_2_outlined},
        {'key': 'reports', 'label': 'Reports', 'icon': Icons.bar_chart_rounded},
        {'key': 'notifications', 'label': 'Notifications', 'icon': Icons.notifications_none_rounded, 'badge': 'notif'},
        {'key': 'settings', 'label': 'Settings', 'icon': Icons.settings_outlined},
      ],
    },
  ];

  final Map<String, Map<String, String>> _titles = {
    'dashboard':     {'title': 'Receptionist Dashboard', 'subtitle': 'Command center · Front desk overview'},
    'patients':      {'title': 'Patients', 'subtitle': 'Registry, profiles & history'},
    'appointments':  {'title': 'Appointments', 'subtitle': 'Schedule, walk-ins & calendar'},
    'queue':         {'title': 'Queue Management', 'subtitle': 'Real-time patient flow board'},
    'billing':       {'title': 'Billing & Invoices', 'subtitle': 'Invoice builder & collection'},
    'payments':      {'title': 'Payments', 'subtitle': 'Collections, modes & refund requests'},
    'inventory':     {'title': 'Inventory', 'subtitle': 'Medicine stock & movements'},
    'reports':       {'title': 'Reports', 'subtitle': 'Day-end summary & analytics'},
    'notifications': {'title': 'Notifications', 'subtitle': 'Alerts & system messages'},
    'settings':      {'title': 'Settings', 'subtitle': 'Profile & preferences'},
  };

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    final clinics = await _api.getClinics();
    if (clinics.isNotEmpty) {
      _clinicId = clinics.first['clinic_id'];
      _clinics = clinics;
    }
    if (_clinicId != null) {
      final kpis    = await _api.getKpis(_clinicId!, _date);
      final appts   = await _api.getAppointments(clinicId: _clinicId, date: _date);
      final pts     = await _api.getPatients();
      final invs    = await _api.getInvoices();
      setState(() {
        if (kpis != null) _kpis = kpis;
        _appointments = appts;
        _patients = pts;
        _invoices = invs;
        _queue = appts.where((a) => ['Waiting','In Consultation','Arrived'].contains(a['status'])).toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  void _signOut() {
    _api.logout();
    Navigator.pushReplacementNamed(context, '/');
  }

  // ─── UPDATE APPT STATUS ─────────────────────────────
  Future<void> _updateStatus(String apptId, String status) async {
    try {
      await _api.updateAppointmentStatus(apptId, status);
      _fetchData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: cRed600,
        ));
      }
    }
  }

  // ─── MAIN BUILD ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBg,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _loading
                    ? const Center(child: CircularProgressIndicator(color: cPrimary))
                    : _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SIDEBAR ─────────────────────────────────────────
  Widget _buildSidebar() {
    final waitingCount = _appointments.where((a) => a['status'] == 'Waiting' || a['status'] == 'Arrived').length;

    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: cCard,
        border: Border(right: BorderSide(color: cBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand block
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: cBorder))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: cPrimary, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Verma Homeopathy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cFg)),
                  Text('Receptionist Portal', style: TextStyle(fontSize: 10, color: cMuted)),
                ])),
              ]),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: cBlue50,
                  border: Border.all(color: cBlue100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(100)),
                    child: const Center(child: Text('P', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white))),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_api.fullName ?? 'Receptionist', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1E3A5F))),
                    const Text('Receptionist', style: TextStyle(fontSize: 10, color: Color(0xFF3B82F6))),
                  ])),
                ]),
              ),
            ]),
          ),

          // Nav
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _navGroups.map((group) {
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
                        final key    = item['key'] as String;
                        final lbl    = item['label'] as String;
                        final ico    = item['icon'] as IconData;
                        final badgeK = item['badge'] as String?;
                        final active = _tab == key;

                        int badgeCount = 0;
                        if (badgeK == 'queue') badgeCount = waitingCount;
                        if (badgeK == 'notif') badgeCount = 3;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1),
                          child: InkWell(
                            onTap: () => setState(() => _tab = key),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                              decoration: BoxDecoration(
                                color: active ? cPrimary.withOpacity(0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(children: [
                                Icon(ico, size: 16, color: active ? cPrimary : cMuted),
                                const SizedBox(width: 10),
                                Expanded(child: Text(lbl, style: TextStyle(fontSize: 13, color: active ? cPrimary : cFg.withOpacity(0.75), fontWeight: active ? FontWeight.w600 : FontWeight.w400))),
                                if (badgeCount > 0) Container(
                                  width: 18, height: 18,
                                  decoration: BoxDecoration(
                                    color: badgeK == 'queue' ? const Color(0xFFF59E0B) : cRed600,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Center(child: Text('$badgeCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white))),
                                ),
                              ]),
                            ),
                          ),
                        );
                      }),
                    ]),
                  );
                }).toList(),
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: cBorder))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: _signOut,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(children: [
                      Icon(Icons.logout_rounded, size: 14, color: cMuted),
                      SizedBox(width: 8),
                      Text('Switch Role', style: TextStyle(fontSize: 12, color: cMuted)),
                    ]),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 4),
                  child: Row(children: [
                    CircleAvatar(backgroundColor: cEm600, radius: 3),
                    SizedBox(width: 6),
                    Text('Synced · 2s ago', style: TextStyle(fontSize: 11, color: cMuted)),
                  ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TOPBAR ──────────────────────────────────────────
  Widget _buildTopBar() {
    final meta = _titles[_tab]!;
    final today = DateTime.now();
    final dateStr = '${['Sun','Mon','Tue','Wed','Thu','Fri','Sat'][today.weekday % 7]}, '
        '${today.day} ${['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][today.month - 1]} ${today.year}';
    return Container(
      height: 56,
      decoration: const BoxDecoration(color: cCard, border: Border(bottom: BorderSide(color: cBorder))),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(meta['title']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cFg)),
          Text(meta['subtitle']!, style: const TextStyle(fontSize: 11, color: cMuted)),
        ])),
        // Search
        SizedBox(
          width: 240,
          height: 34,
          child: TextField(
            onChanged: (v) => setState(() => _searchQ = v),
            style: const TextStyle(fontSize: 12, color: cFg),
            decoration: InputDecoration(
              hintText: 'Search patients, invoices…',
              hintStyle: const TextStyle(fontSize: 12, color: cMuted),
              prefixIcon: const Icon(Icons.search_rounded, size: 16, color: cMuted),
              filled: true, fillColor: cMutedBg,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: cBorder)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(dateStr, style: const TextStyle(fontSize: 11, color: cMuted)),
        const SizedBox(width: 8),
        // Bell
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(onPressed: () => setState(() => _tab = 'notifications'), icon: const Icon(Icons.notifications_none_rounded, size: 20, color: cMuted)),
            Positioned(top: 8, right: 8, child: Container(width: 7, height: 7, decoration: BoxDecoration(color: cRed600, borderRadius: BorderRadius.circular(100), border: Border.all(color: Colors.white, width: 1.2)))),
          ],
        ),
        const SizedBox(width: 4),
        // Avatar chip
        InkWell(
          onTap: _signOut,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(100)),
                child: const Center(child: Text('P', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
              ),
              const SizedBox(width: 6),
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_api.fullName?.split(' ').first ?? 'Priya', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cFg)),
                const Text('Receptionist', style: TextStyle(fontSize: 10, color: cMuted)),
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
      case 'dashboard':     return _buildDashboardTab();
      case 'patients':      return _buildPatientsTab();
      case 'appointments':  return _buildAppointmentsTab();
      case 'queue':         return _buildQueueTab();
      case 'billing':       return _buildBillingTab();
      case 'payments':      return _buildPaymentsTab();
      case 'inventory':     return _buildInventoryTab();
      case 'reports':       return _buildReportsTab();
      case 'notifications': return _buildNotificationsTab();
      case 'settings':      return _buildSettingsTab();
      default:              return _buildDashboardTab();
    }
  }

  // ─── TAB 1: DASHBOARD ────────────────────────────────
  Widget _buildDashboardTab() {
    final waiting = _appointments.where((a) => a['status'] == 'Waiting' || a['status'] == 'Arrived').length;
    final inConsult = _appointments.where((a) => a['status'] == 'In Consultation').length;
    final completed = _appointments.where((a) => a['status'] == 'Completed').length;

    final kpis = [
      {'label': "Today's Patients", 'value': '${_kpis['today_patients'] ?? 0}', 'delta': '+4 vs yesterday', 'up': true, 'icon': Icons.people_outline_rounded, 'iconColor': const Color(0xFF2563EB), 'iconBg': cBlue50},
      {'label': 'Active Queue', 'value': '$waiting', 'delta': '$waiting waiting · $inConsult in consult', 'up': null, 'icon': Icons.format_list_numbered_rounded, 'iconColor': cAmber700, 'iconBg': cAmber50},
      {'label': "Today's Revenue", 'value': '₹${(_kpis['today_revenue'] ?? 0.0).toStringAsFixed(0)}', 'delta': '+₹2,100 vs avg', 'up': true, 'icon': Icons.currency_rupee_rounded, 'iconColor': cEm600, 'iconBg': cEm50},
      {'label': 'Pending Payments', 'value': '₹${(_kpis['pending_dues'] ?? 0.0).toStringAsFixed(0)}', 'delta': '${_invoices.where((i) => i['status'] == 'Partial' || i['status'] == 'Draft').length} invoices due', 'up': false, 'icon': Icons.warning_amber_rounded, 'iconColor': cRed600, 'iconBg': cRed50},
      {'label': 'Low Stock Medicines', 'value': '7', 'delta': 'Reorder needed', 'up': false, 'icon': Icons.inventory_2_outlined, 'iconColor': cOrange500, 'iconBg': cOrange50},
      {'label': 'Near Expiry', 'value': '3', 'delta': 'Expiring in 30 days', 'up': false, 'icon': Icons.calendar_today_outlined, 'iconColor': cPurple700, 'iconBg': cPurple50},
    ];

    final recentPts = _patients.take(3).toList();
    final recentPays = _invoices.take(4).toList();
    final quickActions = [
      {'label': 'Register Patient', 'icon': Icons.person_add_outlined, 'color': const Color(0xFF2563EB), 'bg': cBlue50, 'tab': 'patients'},
      {'label': 'Book Appointment', 'icon': Icons.calendar_month_outlined, 'color': cPrimary, 'bg': cEm50, 'tab': 'appointments'},
      {'label': 'Walk-In', 'icon': Icons.directions_walk_rounded, 'color': cAmber700, 'bg': cAmber50, 'tab': 'queue'},
      {'label': 'Generate Invoice', 'icon': Icons.receipt_long_outlined, 'color': cSlate600, 'bg': cSlate100, 'tab': 'billing'},
      {'label': 'Record Payment', 'icon': Icons.payments_outlined, 'color': cEm600, 'bg': cEm50, 'tab': 'payments'},
      {'label': 'Add Stock', 'icon': Icons.add_box_outlined, 'color': cPurple700, 'bg': cPurple50, 'tab': 'inventory'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        // KPI Grid
        _sectionWrap(
          child: GridView.count(
            crossAxisCount: 6, mainAxisSpacing: 16, crossAxisSpacing: 16,
            childAspectRatio: 1.1, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            children: kpis.map((k) {
              final up = k['up'];
              return _kpiCard(
                label: k['label'] as String,
                value: k['value'] as String,
                delta: k['delta'] as String,
                deltaUp: up as bool?,
                icon: k['icon'] as IconData,
                iconColor: k['iconColor'] as Color,
                iconBg: k['iconBg'] as Color,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Queue board preview + Appointments overview
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 2, child: _buildQueuePreview(waiting, inConsult, completed)),
          const SizedBox(width: 20),
          SizedBox(width: 260, child: _buildApptOverview()),
        ]),
        const SizedBox(height: 20),

        // Bottom row: Recent Payments, Patients, Inventory, Quick Actions
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _buildRecentPaymentsCard(recentPays)),
          const SizedBox(width: 16),
          Expanded(child: _buildRecentPatientsCard(recentPts)),
          const SizedBox(width: 16),
          Expanded(child: _buildInventoryActivityCard()),
          const SizedBox(width: 16),
          Expanded(child: _buildQuickActionsCard(quickActions)),
        ]),
      ]),
    );
  }

  Widget _kpiCard({required String label, required String value, required String delta, required bool? deltaUp, required IconData icon, required Color iconColor, required Color iconBg}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: iconColor)),
          if (deltaUp == true) const Icon(Icons.trending_up_rounded, size: 14, color: cEm600)
          else if (deltaUp == false) const Icon(Icons.trending_down_rounded, size: 14, color: cRed600),
        ]),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: cFg, height: 1)),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 10, color: cMuted)),
        const SizedBox(height: 4),
        Text(delta, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: deltaUp == true ? cEm600 : deltaUp == false ? cRed600 : cMuted)),
      ]),
    );
  }

  Widget _buildQueuePreview(int waiting, int inConsult, int completed) {
    final noShow = _appointments.where((a) => a['status'] == 'No Show').length;
    final cols = [
      {'label': 'Waiting', 'count': waiting, 'color': cAmber700, 'bg': cAmber50, 'border': cAmber200},
      {'label': 'In Consultation', 'count': inConsult, 'color': cBlue700, 'bg': cBlue50, 'border': cBlue200},
      {'label': 'Completed', 'count': completed, 'color': cEm700, 'bg': cEm50, 'border': cEm200},
      {'label': 'No Show', 'count': noShow, 'color': cSlate600, 'bg': cSlate50, 'border': cSlate200},
    ];

    return Container(
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Live Queue Board', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
              Text('Real-time patient flow', style: TextStyle(fontSize: 11, color: cMuted)),
            ]),
            TextButton(
              onPressed: () => setState(() => _tab = 'queue'),
              child: const Row(children: [
                Text('Full Queue', style: TextStyle(fontSize: 11, color: cPrimary)),
                Icon(Icons.chevron_right_rounded, size: 16, color: cPrimary),
              ]),
            ),
          ]),
        ),
        const Divider(height: 1, color: cBorder),
        IntrinsicHeight(
          child: Row(
            children: cols.asMap().entries.map((e) {
              final i = e.key; final col = e.value;
              final appts = _appointments.where((a) {
                final s = a['status'];
                if (i == 0) return s == 'Waiting' || s == 'Arrived';
                if (i == 1) return s == 'In Consultation';
                if (i == 2) return s == 'Completed';
                return s == 'No Show';
              }).take(2).toList();

              return Expanded(
                child: Container(
                  decoration: BoxDecoration(border: i < 3 ? const Border(right: BorderSide(color: cBorder)) : null),
                  padding: const EdgeInsets.all(10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text((col['label'] as String).toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: col['color'] as Color, letterSpacing: 0.5)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: col['bg'] as Color, border: Border.all(color: col['border'] as Color), borderRadius: BorderRadius.circular(100)),
                        child: Text('${col['count']}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: col['color'] as Color)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    ...appts.map((a) {
                      final name = a['patient']?['full_name'] ?? 'Walk-In';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: col['bg'] as Color, border: Border.all(color: col['border'] as Color), borderRadius: BorderRadius.circular(8)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text('T-${a['token_number'] ?? '--'}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: col['color'] as Color)),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), border: Border.all(color: cBorder), borderRadius: BorderRadius.circular(100)), child: Text(a['visit_type'] ?? 'Visit', style: const TextStyle(fontSize: 9, color: cMuted))),
                          ]),
                          const SizedBox(height: 3),
                          Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cFg)),
                          Row(children: [const Icon(Icons.access_time_rounded, size: 10, color: cMuted), const SizedBox(width: 3), Text(a['appt_time'] ?? '', style: const TextStyle(fontSize: 9, color: cMuted))]),
                        ]),
                      );
                    }),
                    if ((col['count'] as int) == 0) const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Center(child: Text('Empty', style: TextStyle(fontSize: 10, color: cMuted)))),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }

  Widget _buildApptOverview() {
    final total = _appointments.length;
    final walkIns = _appointments.where((a) => a['visit_type'] == 'Walk-In').length;
    final followUps = _appointments.where((a) => a['visit_type'] == 'Follow Up').length;
    final completed = _appointments.where((a) => a['status'] == 'Completed').length;
    final cancelled = _appointments.where((a) => a['status'] == 'Cancelled').length;
    final completionPct = total > 0 ? (completed / total * 100).round() : 0;
    final stats = [
      {'label': 'Total Today', 'value': total, 'color': cPrimary},
      {'label': 'Walk-Ins', 'value': walkIns, 'color': const Color(0xFF60A5FA)},
      {'label': 'Follow Ups', 'value': followUps, 'color': cPurple700},
      {'label': 'Cancelled', 'value': cancelled, 'color': cRed600},
    ];
    return Container(
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, 4), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Today's Appointments", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
          Text('Overview by type', style: TextStyle(fontSize: 11, color: cMuted)),
        ])),
        const Divider(height: 1, color: cBorder),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            ...stats.map((s) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: s['color'] as Color, borderRadius: BorderRadius.circular(100))),
                const SizedBox(width: 10),
                Expanded(child: Text(s['label'] as String, style: const TextStyle(fontSize: 12, color: cFg))),
                Text('${s['value']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cFg)),
              ]),
            )),
            const Divider(height: 16, color: cBorder),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Completion Rate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cFg)),
              Text('$completionPct%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cEm600)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: LinearProgressIndicator(value: completionPct / 100, backgroundColor: cMutedBg, color: cEm600, minHeight: 6),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() => _tab = 'appointments'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cPrimary, side: const BorderSide(color: Color(0xFF99F6E4)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(fontSize: 11),
                ),
                child: const Text('View All Appointments'),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildRecentPaymentsCard(List<dynamic> payments) {
    return Container(
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Recent Payments', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cFg)),
            TextButton(onPressed: () => setState(() => _tab = 'payments'), child: const Text('View all', style: TextStyle(fontSize: 11, color: cPrimary))),
          ]),
        ),
        const Divider(height: 1, color: cBorder),
        if (payments.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No payments today', style: TextStyle(fontSize: 11, color: cMuted))),
        ...payments.map((inv) {
          final name = inv['patient']?['full_name'] ?? inv['patient_id'] ?? '—';
          final amount = inv['total_amount'] ?? 0;
          final status = inv['status'] ?? 'Draft';
          final modeColors = {'UPI': cPurple50, 'Cash': cEm50, 'Card': cBlue50};
          final modeTextColors = {'UPI': cPurple700, 'Cash': cEm700, 'Card': cBlue700};
          final mode = 'UPI';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: cBorder))),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cFg)),
                Text('INV · Today', style: const TextStyle(fontSize: 10, color: cMuted)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cEm700)),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: modeColors[mode] ?? cSlate100, borderRadius: BorderRadius.circular(100)), child: Text(mode, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: modeTextColors[mode] ?? cSlate600))),
              ]),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildRecentPatientsCard(List<dynamic> patients) {
    return Container(
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Recent Patients', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cFg)),
            TextButton(onPressed: () => setState(() => _tab = 'patients'), child: const Text('View all', style: TextStyle(fontSize: 11, color: cPrimary))),
          ]),
        ),
        const Divider(height: 1, color: cBorder),
        if (patients.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No recent patients', style: TextStyle(fontSize: 11, color: cMuted))),
        ...patients.map((p) {
          final name = p['full_name'] ?? '—';
          final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
          final phone = p['mobile_number'] ?? '—';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: cBorder))),
            child: Row(children: [
              Container(width: 32, height: 32, decoration: BoxDecoration(color: cPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(100)), child: Center(child: Text(initial, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cPrimary)))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cFg)),
                Text(phone, style: const TextStyle(fontSize: 10, color: cMuted)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: cBlue50, borderRadius: BorderRadius.circular(100)), child: const Text('New', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: cBlue700))),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildInventoryActivityCard() {
    final items = [
      {'medicine': 'Arnica Montana 200C', 'action': 'Stock In', 'qty': '+50 units', 'by': 'Priya', 'time': '09:00 AM'},
      {'medicine': 'Belladonna 30C', 'action': 'Dispensed', 'qty': '-2 units', 'by': 'Dr. Verma', 'time': '10:22 AM'},
      {'medicine': 'Nux Vomica 1M', 'action': 'Low Stock Alert', 'qty': '3 left', 'by': 'System', 'time': '10:00 AM'},
    ];
    return Container(
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Inventory Activity', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cFg)),
            TextButton(onPressed: () => setState(() => _tab = 'inventory'), child: const Text('View all', style: TextStyle(fontSize: 11, color: cPrimary))),
          ]),
        ),
        const Divider(height: 1, color: cBorder),
        ...items.map((it) {
          final qty = it['qty'] as String;
          Color qtyColor = qty.startsWith('+') ? cEm600 : qty.startsWith('-') ? cRed600 : cAmber700;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: cBorder))),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(it['medicine'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cFg), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('${it['by']} · ${it['time']}', style: const TextStyle(fontSize: 10, color: cMuted)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(qty, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: qtyColor)),
                Text(it['action'] as String, style: const TextStyle(fontSize: 9, color: cMuted)),
              ]),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _buildQuickActionsCard(List<Map<String, dynamic>> actions) {
    return Container(
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(padding: EdgeInsets.fromLTRB(16, 12, 16, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Quick Actions', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cFg)),
          Text('Common front-desk tasks', style: TextStyle(fontSize: 10, color: cMuted)),
        ])),
        const Divider(height: 12, color: cBorder),
        Padding(
          padding: const EdgeInsets.all(12),
          child: GridView.count(
            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.6,
            children: actions.map((a) => InkWell(
              onTap: () => setState(() => _tab = a['tab'] as String),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(color: a['bg'] as Color, borderRadius: BorderRadius.circular(8), border: Border.all(color: (a['bg'] as Color).withOpacity(0.5))),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(a['icon'] as IconData, size: 20, color: a['color'] as Color),
                  const SizedBox(height: 5),
                  Text(a['label'] as String, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: a['color'] as Color)),
                ]),
              ),
            )).toList(),
          ),
        ),
      ]),
    );
  }

  // ─── TAB 2: PATIENTS ─────────────────────────────────
  Widget _buildPatientsTab() {
    final filters = ['All', 'Active', 'Follow-up due', 'New this week'];
    String activeFilter = 'All';
    return StatefulBuilder(builder: (ctx, setS) {
      final filtered = _patients.where((p) {
        if (_searchQ.isNotEmpty) {
          final name = (p['full_name'] ?? '').toLowerCase();
          final mobile = (p['mobile_number'] ?? '').toLowerCase();
          if (!name.contains(_searchQ.toLowerCase()) && !mobile.contains(_searchQ.toLowerCase())) return false;
        }
        return true;
      }).toList();

      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Patients', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cFg)),
              Text('${filtered.length} total · ${_patients.where((p) => (p['created_at'] ?? '').contains(DateTime.now().toString().split(' ')[0])).length} added today', style: const TextStyle(fontSize: 12, color: cMuted)),
            ]),
            Row(children: [
              _outlineBtn('Export', Icons.download_rounded, () {}),
              const SizedBox(width: 8),
              _primaryBtn('New Patient', Icons.add_rounded, () => _showAddPatientDialog()),
            ]),
          ]),
          const SizedBox(height: 16),

          // Filters
          Row(children: [
            ...filters.map((f) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () => setS(() => activeFilter = f),
                borderRadius: BorderRadius.circular(100),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: activeFilter == f ? cAccent : cCard,
                    border: Border.all(color: activeFilter == f ? cEm200 : cBorder),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(f, style: TextStyle(fontSize: 11, color: activeFilter == f ? cFg : cMuted, fontWeight: activeFilter == f ? FontWeight.w600 : FontWeight.w400)),
                ),
              ),
            )),
          ]),
          const SizedBox(height: 16),

          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
              child: Column(children: [
                // Table header
                Container(
                  decoration: BoxDecoration(color: cMutedBg.withOpacity(0.6), borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
                  child: const Row(children: [
                    SizedBox(width: 16),
                    Expanded(flex: 3, child: Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Patient', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted)))),
                    Expanded(flex: 2, child: Text('Code', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                    Expanded(flex: 2, child: Text('Phone', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                    Expanded(flex: 2, child: Text('Last Visit', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                    Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
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
                            return InkWell(
                              onTap: () {},
                              child: Padding(
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
                                  Expanded(flex: 2, child: Text('Today', style: const TextStyle(fontSize: 11, color: cMuted))),
                                  Expanded(flex: 2, child: _statusPill('active')),
                                  const Icon(Icons.chevron_right_rounded, size: 16, color: cMuted),
                                ]),
                              ),
                            );
                          },
                        ),
                ),
              ]),
            ),
          ),
        ]),
      );
    });
  }

  // ─── TAB 3: APPOINTMENTS ─────────────────────────────
  Widget _buildAppointmentsTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Appointments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cFg)),
            Text('Schedule, walk-ins & calendar', style: TextStyle(fontSize: 12, color: cMuted)),
          ]),
          Row(children: [
            _outlineBtn('Export', Icons.download_rounded, () {}),
            const SizedBox(width: 8),
            _primaryBtn('Book Appointment', Icons.add_rounded, () => _showBookApptDialog()),
          ]),
        ]),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
            child: Column(children: [
              Container(
                decoration: BoxDecoration(color: cMutedBg.withOpacity(0.6), borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))),
                child: const Row(children: [
                  SizedBox(width: 16),
                  Expanded(flex: 2, child: Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted)))),
                  Expanded(flex: 1, child: Text('Time', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
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
                              Expanded(flex: 2, child: Text(a['appt_date'] ?? _date, style: const TextStyle(fontSize: 11, color: cFg))),
                              Expanded(flex: 1, child: Text(a['appt_time'] ?? '—', style: const TextStyle(fontSize: 11, color: cMuted))),
                              Expanded(flex: 3, child: Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cFg))),
                              Expanded(flex: 2, child: Text(a['visit_type'] ?? '—', style: const TextStyle(fontSize: 11, color: cMuted))),
                              Expanded(flex: 2, child: _statusPill(status.toLowerCase())),
                              Expanded(flex: 2, child: Row(children: [
                                if (status == 'Scheduled' || status == 'Confirmed') _smallBtn('Confirm', cEm50, cEm700, () => _updateStatus(a['appt_id'], 'Arrived')),
                                const SizedBox(width: 4),
                                _smallBtn('Arrive', cBlue50, cBlue700, () => _updateStatus(a['appt_id'], 'Arrived')),
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

  // ─── TAB 4: QUEUE ────────────────────────────────────
  Widget _buildQueueTab() {
    final waiting    = _appointments.where((a) => a['status'] == 'Waiting' || a['status'] == 'Arrived').toList();
    final consult    = _appointments.where((a) => a['status'] == 'In Consultation').toList();
    final completed  = _appointments.where((a) => a['status'] == 'Completed').toList();
    final noShow     = _appointments.where((a) => a['status'] == 'No Show').toList();
    final activeC    = consult.isNotEmpty ? consult.first : null;
    final avgWait    = waiting.isNotEmpty ? '${(waiting.length * 8)} min avg' : '0 min';

    final summaryStats = [
      {'label': 'Total Waiting', 'value': '${waiting.length}', 'icon': Icons.format_list_numbered_rounded, 'color': cAmber700},
      {'label': 'Avg Wait Time', 'value': avgWait, 'icon': Icons.timer_outlined, 'color': cBlue700},
      {'label': 'Completed Today', 'value': '${completed.length}', 'icon': Icons.check_circle_outline_rounded, 'color': cEm600},
      {'label': 'Total Seen', 'value': '${_appointments.length}', 'icon': Icons.people_outline_rounded, 'color': cPrimary},
      {'label': 'No Shows', 'value': '${noShow.length}', 'icon': Icons.person_off_outlined, 'color': cSlate600},
      {'label': 'In Progress', 'value': '${consult.length}', 'icon': Icons.medical_services_outlined, 'color': cPurple700},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        // Summary stats
        GridView.count(
          crossAxisCount: 6, mainAxisSpacing: 12, crossAxisSpacing: 12,
          childAspectRatio: 1.4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          children: summaryStats.map((s) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(s['label'] as String, style: const TextStyle(fontSize: 9, color: cMuted)),
                Icon(s['icon'] as IconData, size: 14, color: s['color'] as Color),
              ]),
              const SizedBox(height: 6),
              Align(alignment: Alignment.centerLeft, child: Text(s['value'] as String, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: s['color'] as Color))),
            ]),
          )).toList(),
        ),
        const SizedBox(height: 20),

        // 4 Kanban columns
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Waiting
          Expanded(child: _queueColumn(
            label: 'Waiting', color: cAmber700, bg: cAmber50, borderColor: cAmber200,
            badge: '${waiting.length}', dotColor: const Color(0xFFF59E0B),
            child: Column(children: [
              if (waiting.isEmpty) _emptyColumnMsg('No patients waiting', Icons.people_outline_rounded),
              ...waiting.map((a) => _waitingCard(a)),
            ]),
          )),
          const SizedBox(width: 16),
          // In Consultation
          Expanded(child: _queueColumn(
            label: 'In Consultation', color: cBlue700, bg: cBlue50, borderColor: cBlue200,
            badge: '${consult.length}/1', dotColor: const Color(0xFF3B82F6), pulseDot: true,
            child: Column(children: [
              if (activeC == null) _emptyColumnMsg('No active consultation\nStart a patient from the waiting queue', Icons.medical_services_outlined)
              else _activeConsultCard(activeC),
            ]),
          )),
          const SizedBox(width: 16),
          // Completed
          Expanded(child: _queueColumn(
            label: 'Completed', color: cEm700, bg: cEm50, borderColor: cEm200,
            badge: '${completed.length}', dotColor: cEm600,
            child: Column(children: [
              if (completed.isEmpty) _emptyColumnMsg('No completions yet', Icons.check_circle_outline_rounded),
              ...completed.map((a) => _completedCard(a)),
            ]),
          )),
          const SizedBox(width: 16),
          // No Show
          Expanded(child: _queueColumn(
            label: 'No Show', color: cSlate600, bg: cSlate50, borderColor: cSlate200,
            badge: '${noShow.length}', dotColor: cSlate400,
            child: Column(children: [
              if (noShow.isEmpty) _emptyColumnMsg('None', Icons.person_off_outlined),
              ...noShow.map((a) => _noShowCard(a)),
            ]),
          )),
        ]),
      ]),
    );
  }

  Widget _queueColumn({required String label, required Color color, required Color bg, required Color borderColor, required String badge, required Color dotColor, required Widget child, bool pulseDot = false}) {
    return Container(
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)), border: Border(bottom: BorderSide(color: borderColor))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, borderRadius: BorderRadius.circular(100))),
              const SizedBox(width: 6),
              Text(label.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.6)),
            ]),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: bg, border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(100)), child: Text(badge, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color))),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(10), child: child),
      ]),
    );
  }

  Widget _emptyColumnMsg(String msg, IconData ico) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Center(child: Column(children: [
      Icon(ico, size: 28, color: cMuted.withOpacity(0.4)),
      const SizedBox(height: 8),
      Text(msg, style: const TextStyle(fontSize: 10, color: cMuted), textAlign: TextAlign.center),
    ])),
  );

  Widget _waitingCard(dynamic a) {
    final name = a['patient']?['full_name'] ?? 'Walk-In';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder), boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('T-${a['token_number'] ?? '--'}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: cAmber700, height: 1)),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            _tagBadge(a['visit_type'] ?? 'New', cBlue50, cBlue700),
            const SizedBox(height: 4),
            _tagBadge('Pending', cAmber50, cAmber700),
          ]),
        ]),
        const SizedBox(height: 6),
        Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cFg)),
        const SizedBox(height: 4),
        Row(children: [const Icon(Icons.access_time_rounded, size: 10, color: cMuted), const SizedBox(width: 4), Text(a['appt_time'] ?? '—', style: const TextStyle(fontSize: 10, color: cMuted))]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: InkWell(
            onTap: () => _updateStatus(a['appt_id'], 'In Consultation'),
            borderRadius: BorderRadius.circular(8),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 7), decoration: BoxDecoration(color: cPrimary, borderRadius: BorderRadius.circular(8)), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.play_arrow_rounded, size: 14, color: Colors.white), SizedBox(width: 4), Text('Start', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white))])),
          )),
          const SizedBox(width: 6),
          Expanded(child: InkWell(
            onTap: () => _updateStatus(a['appt_id'], 'No Show'),
            borderRadius: BorderRadius.circular(8),
            child: Container(padding: const EdgeInsets.symmetric(vertical: 7), decoration: BoxDecoration(border: Border.all(color: cBorder), borderRadius: BorderRadius.circular(8)), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.person_off_outlined, size: 14, color: cMuted), SizedBox(width: 4), Text('No Show', style: TextStyle(fontSize: 11, color: cMuted))])),
          )),
        ]),
      ]),
    );
  }

  Widget _activeConsultCard(dynamic a) {
    final name = a['patient']?['full_name'] ?? 'Walk-In';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cBlue50, border: Border.all(color: cBlue200, width: 2), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(100))),
          const SizedBox(width: 6),
          const Text('ACTIVE CONSULTATION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: cBlue700, letterSpacing: 0.6)),
        ]),
        const SizedBox(height: 10),
        Text('T-${a['token_number'] ?? '--'}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: cBlue700, height: 1)),
        const SizedBox(height: 6),
        Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cFg)),
        const SizedBox(height: 3),
        Text('${a['appt_time'] ?? '—'} · ${a['visit_type'] ?? '—'}', style: const TextStyle(fontSize: 11, color: cMuted)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _updateStatus(a['appt_id'], 'Completed'),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
            label: const Text('Complete Consultation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(backgroundColor: cEm600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
          ),
        ),
      ]),
    );
  }

  Widget _completedCard(dynamic a) {
    final name = a['patient']?['full_name'] ?? 'Walk-In';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: cBorder)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('T-${a['token_number'] ?? '--'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cEm600, height: 1)),
          Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cFg)),
          Text(a['appt_time'] ?? '—', style: const TextStyle(fontSize: 10, color: cMuted)),
        ])),
        Column(children: [
          IconButton(icon: const Icon(Icons.receipt_long_outlined, size: 16, color: cMuted), onPressed: () => setState(() => _tab = 'billing'), tooltip: 'View Invoice'),
          IconButton(icon: const Icon(Icons.currency_rupee_rounded, size: 16, color: cMuted), onPressed: () => setState(() => _tab = 'payments'), tooltip: 'Record Payment'),
        ]),
      ]),
    );
  }

  Widget _noShowCard(dynamic a) {
    final name = a['patient']?['full_name'] ?? 'Walk-In';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: cBorder)),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('T-${a['token_number'] ?? '--'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cSlate400, height: 1)),
          Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cFg)),
          Text(a['appt_time'] ?? '—', style: const TextStyle(fontSize: 10, color: cMuted)),
        ])),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 16, color: cMuted),
          onPressed: () => _updateStatus(a['appt_id'], 'Waiting'),
          tooltip: 'Requeue',
        ),
      ]),
    );
  }

  // ─── TAB 5: BILLING ──────────────────────────────────
  Widget _buildBillingTab() {
    final statusFilters = ['All', 'Paid', 'Partial', 'Overdue', 'Draft'];
    String activeStatus = 'All';
    final metrics = [
      {'label': 'Total Invoices', 'value': '${_invoices.length}', 'icon': Icons.receipt_long_outlined, 'iconColor': cPrimary, 'iconBg': cEm50},
      {'label': 'Paid', 'value': '${_invoices.where((i) => i['status'] == 'Paid').length}', 'icon': Icons.check_circle_outline_rounded, 'iconColor': cEm600, 'iconBg': cEm50},
      {'label': 'Partial', 'value': '${_invoices.where((i) => i['status'] == 'Partial').length}', 'icon': Icons.pending_outlined, 'iconColor': cAmber700, 'iconBg': cAmber50},
      {'label': 'Overdue', 'value': '${_invoices.where((i) => i['status'] == 'Issued' || i['status'] == 'Draft').length}', 'icon': Icons.warning_amber_rounded, 'iconColor': cRed600, 'iconBg': cRed50},
    ];

    return StatefulBuilder(builder: (ctx, setS) {
      final filtered = _invoices.where((inv) {
        if (activeStatus == 'All') return true;
        return (inv['status'] ?? '') == activeStatus;
      }).toList();

      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          // Metrics
          Row(children: metrics.map((m) => Expanded(child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
              child: Row(children: [
                Container(width: 36, height: 36, decoration: BoxDecoration(color: m['iconBg'] as Color, borderRadius: BorderRadius.circular(8)), child: Icon(m['icon'] as IconData, size: 18, color: m['iconColor'] as Color)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m['label'] as String, style: const TextStyle(fontSize: 10, color: cMuted)),
                  Text(m['value'] as String, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: m['iconColor'] as Color)),
                ]),
              ]),
            ),
          ))).toList()),
          const SizedBox(height: 16),

          // Table
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: activeStatus == f ? cPrimary : cMutedBg, borderRadius: BorderRadius.circular(6)),
                          child: Text(f, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: activeStatus == f ? Colors.white : cMuted)),
                        ),
                      ),
                    )).toList())),
                    _primaryBtn('New Invoice', Icons.add_rounded, () => _showCreateInvoiceDialog()),
                  ]),
                ),
                const Divider(height: 1, color: cBorder),
                Container(
                  color: cMutedBg.withOpacity(0.6),
                  child: const Row(children: [
                    SizedBox(width: 16),
                    Expanded(flex: 2, child: Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Invoice #', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted)))),
                    Expanded(flex: 3, child: Text('Patient', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                    Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                    Expanded(flex: 2, child: Text('Paid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                    Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                    Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                    SizedBox(width: 16),
                  ]),
                ),
                const Divider(height: 1, color: cBorder),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No invoices found', style: TextStyle(fontSize: 12, color: cMuted)))
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: cBorder),
                          itemBuilder: (_, i) {
                            final inv = filtered[i];
                            final patient = inv['patient']?['full_name'] ?? inv['patient_id'] ?? '—';
                            final amount = inv['total_amount'] ?? 0;
                            final paid = (inv['payments'] as List?)?.fold<double>(0, (s, p) => s + (p['amount'] ?? 0)) ?? 0;
                            final status = inv['status'] ?? 'Draft';
                            return InkWell(
                              onTap: () {},
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(children: [
                                  Expanded(flex: 2, child: Text(inv['invoice_id']?.toString().substring(0, 8).toUpperCase() ?? '—', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: cPrimary, fontWeight: FontWeight.w600))),
                                  Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(patient, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cFg)),
                                  ])),
                                  Expanded(flex: 2, child: Text('₹${(amount ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cFg))),
                                  Expanded(flex: 2, child: Text('₹${paid.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: cEm700))),
                                  Expanded(flex: 2, child: _statusPill(status.toLowerCase())),
                                  Expanded(flex: 2, child: Row(children: [
                                    _smallBtn('View', cSlate100, cSlate600, () {}),
                                    const SizedBox(width: 4),
                                    if (status != 'Paid') _smallBtn('Pay', cEm100, cEm700, () => _showPaymentDialog(inv)),
                                  ])),
                                ]),
                              ),
                            );
                          },
                        ),
                ),
              ]),
            ),
          ),
        ]),
      );
    });
  }

  // ─── TAB 6: PAYMENTS ─────────────────────────────────
  Widget _buildPaymentsTab() {
    final payMetrics = [
      {'label': 'Cash Collections', 'value': '₹8,200', 'icon': Icons.payments_outlined, 'iconColor': cEm600, 'iconBg': cEm50},
      {'label': 'UPI Collections', 'value': '₹6,400', 'icon': Icons.phone_android_rounded, 'iconColor': cPurple700, 'iconBg': cPurple50},
      {'label': 'Card Collections', 'value': '₹3,850', 'icon': Icons.credit_card_rounded, 'iconColor': const Color(0xFF2563EB), 'iconBg': cBlue50},
      {'label': 'Pending Dues', 'value': '₹5,200', 'icon': Icons.warning_amber_rounded, 'iconColor': cRed600, 'iconBg': cRed50},
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Row(children: payMetrics.map((m) => Expanded(child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
            child: Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: m['iconBg'] as Color, borderRadius: BorderRadius.circular(8)), child: Icon(m['icon'] as IconData, size: 18, color: m['iconColor'] as Color)),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m['label'] as String, style: const TextStyle(fontSize: 10, color: cMuted)),
                Text(m['value'] as String, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: m['iconColor'] as Color)),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Payment Records', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
                  _primaryBtn('Record Payment', Icons.add_rounded, () {}),
                ]),
              ),
              const Divider(height: 1, color: cBorder),
              Container(
                color: cMutedBg.withOpacity(0.6),
                child: const Row(children: [
                  SizedBox(width: 16),
                  Expanded(flex: 2, child: Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Receipt No', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted)))),
                  Expanded(flex: 3, child: Text('Patient', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  Expanded(flex: 2, child: Text('Invoice', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  Expanded(flex: 2, child: Text('Mode', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  Expanded(flex: 2, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  SizedBox(width: 16),
                ]),
              ),
              const Divider(height: 1, color: cBorder),
              const Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.account_balance_wallet_outlined, size: 32, color: cMuted),
                SizedBox(height: 8),
                Text('Payment records appear here', style: TextStyle(fontSize: 12, color: cMuted)),
              ]))),
            ]),
          ),
        ),
      ]),
    );
  }

  // ─── TAB 7: INVENTORY ────────────────────────────────
  Widget _buildInventoryTab() {
    final mockInventory = [
      {'name': 'Arnica Montana 200C', 'cat': 'Polychrest', 'qty': 48, 'unit': 'ml', 'expiry': '2025-12-31', 'batch': 'BT-2241', 'status': 'ok'},
      {'name': 'Belladonna 30C', 'cat': 'Polychrest', 'qty': 6, 'unit': 'ml', 'expiry': '2025-04-15', 'batch': 'BT-2198', 'status': 'low'},
      {'name': 'Nux Vomica 1M', 'cat': 'Constitutional', 'qty': 3, 'unit': 'ml', 'expiry': '2025-06-30', 'batch': 'BT-2201', 'status': 'low'},
      {'name': 'Pulsatilla 30C', 'cat': 'Constitutional', 'qty': 22, 'unit': 'ml', 'expiry': '2025-05-10', 'batch': 'BT-2215', 'status': 'expiring'},
      {'name': 'Sulphur 200C', 'cat': 'Polychrest', 'qty': 35, 'unit': 'ml', 'expiry': '2026-02-28', 'batch': 'BT-2250', 'status': 'ok'},
    ];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Inventory', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cFg)),
            Text('Medicine stock & movements', style: TextStyle(fontSize: 12, color: cMuted)),
          ]),
          _primaryBtn('Stock Inward', Icons.add_box_outlined, () => _showStockInwardDialog()),
        ]),
        const SizedBox(height: 16),
        // Warning banners
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: cAmber50, border: Border.all(color: cAmber200), borderRadius: BorderRadius.circular(10)),
          child: const Row(children: [
            Icon(Icons.warning_amber_rounded, size: 16, color: cAmber700),
            SizedBox(width: 8),
            Text('7 medicines are low on stock and 3 are expiring within 30 days. Please reorder immediately.', style: TextStyle(fontSize: 11, color: cAmber700)),
          ]),
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
            child: Column(children: [
              Container(
                color: cMutedBg.withOpacity(0.6),
                child: const Row(children: [
                  SizedBox(width: 16),
                  Expanded(flex: 3, child: Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Text('Medicine', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted)))),
                  Expanded(flex: 2, child: Text('Category', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  Expanded(flex: 1, child: Text('Qty', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  Expanded(flex: 2, child: Text('Expiry', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  Expanded(flex: 1, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  Expanded(flex: 2, child: Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  SizedBox(width: 16),
                ]),
              ),
              const Divider(height: 1, color: cBorder),
              Expanded(
                child: ListView.separated(
                  itemCount: mockInventory.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: cBorder),
                  itemBuilder: (_, i) {
                    final it = mockInventory[i];
                    final status = it['status'] as String;
                    Color statusColor = status == 'ok' ? cEm700 : status == 'low' ? cAmber700 : cRed600;
                    Color statusBg = status == 'ok' ? cEm50 : status == 'low' ? cAmber50 : cRed50;
                    String statusLabel = status == 'ok' ? 'OK' : status == 'low' ? 'Low Stock' : 'Near Expiry';
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(children: [
                        Expanded(flex: 3, child: Text(it['name'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cFg))),
                        Expanded(flex: 2, child: Text(it['cat'] as String, style: const TextStyle(fontSize: 11, color: cMuted))),
                        Expanded(flex: 1, child: Text('${it['qty']} ${it['unit']}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: (it['qty'] as int) < 10 ? cRed600 : cFg))),
                        Expanded(flex: 2, child: Text(it['expiry'] as String, style: const TextStyle(fontSize: 11, color: cMuted))),
                        Expanded(flex: 1, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(100)), child: Text(statusLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor)))),
                        Expanded(flex: 2, child: _smallBtn('Stock In', cPrimary.withOpacity(0.1), cPrimary, () => _showStockInwardDialog())),
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

  // ─── TAB 8: REPORTS ──────────────────────────────────
  Widget _buildReportsTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cFg)),
            Text('Day-end summary & analytics', style: TextStyle(fontSize: 12, color: cMuted)),
          ]),
          _outlineBtn('Export Report', Icons.download_rounded, () {}),
        ]),
        const SizedBox(height: 20),
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 2, child: _buildRevenueChart()),
            const SizedBox(width: 16),
            Expanded(child: _buildCollectionChart()),
          ]),
        ),
      ]),
    );
  }

  Widget _buildRevenueChart() {
    final data = [12400.0, 14800.0, 11200.0, 16900.0, 18450.0, 22100.0, 9800.0];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Revenue vs. Expenses', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
            Text('Last 7 days · in ₹', style: TextStyle(fontSize: 11, color: cMuted)),
          ]),
          Row(children: [
            Row(children: [SizedBox(width: 10, height: 10, child: DecoratedBox(decoration: BoxDecoration(color: cPrimary))), SizedBox(width: 5), Text('Revenue', style: TextStyle(fontSize: 10, color: cMuted))]),
            SizedBox(width: 12),
            Row(children: [SizedBox(width: 10, height: 10, child: DecoratedBox(decoration: BoxDecoration(color: cSlate200))), SizedBox(width: 5), Text('Expenses', style: TextStyle(fontSize: 10, color: cMuted))]),
          ]),
        ]),
        const SizedBox(height: 20),
        SizedBox(
          height: 160,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (int i = 0; i < data.length; i++) ...[
              Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Container(height: (data[i] / maxVal) * 140, decoration: BoxDecoration(color: cPrimary.withOpacity(0.85), borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))),
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

  Widget _buildCollectionChart() {
    final modes = [
      {'name': 'UPI', 'pct': 48.0, 'color': cPrimary},
      {'name': 'Cash', 'pct': 26.0, 'color': const Color(0xFF14B8A6)},
      {'name': 'Card', 'pct': 18.0, 'color': const Color(0xFF5EEAD4)},
      {'name': 'Net Banking', 'pct': 8.0, 'color': const Color(0xFF99F6E4)},
    ];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Collections by Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
        const Text("Today · ₹18,450 collected", style: TextStyle(fontSize: 11, color: cMuted)),
        const SizedBox(height: 16),
        // Simple stacked bar
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: modes.map((m) => Expanded(
              flex: (m['pct'] as double).toInt(),
              child: Container(height: 14, color: m['color'] as Color),
            )).toList(),
          ),
        ),
        const SizedBox(height: 16),
        ...modes.map((m) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: m['color'] as Color, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Expanded(child: Text(m['name'] as String, style: const TextStyle(fontSize: 11, color: cMuted))),
            Text('${(m['pct'] as double).toInt()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cFg)),
          ]),
        )),
      ]),
    );
  }

  // ─── TAB 9: NOTIFICATIONS ────────────────────────────
  Widget _buildNotificationsTab() {
    final notifs = [
      {'title': 'Low Stock Alert', 'body': 'Belladonna 30C stock is critically low (6 units). Reorder immediately.', 'time': '10:00 AM', 'type': 'warning', 'read': false},
      {'title': 'New Patient Registered', 'body': 'Raj Patel (VHC-2042) has been registered by Priya Sharma.', 'time': '11:00 AM', 'type': 'info', 'read': false},
      {'title': 'Consultation Completed', 'body': 'Anita Verma\'s consultation has been completed. Invoice pending.', 'time': '10:52 AM', 'type': 'success', 'read': true},
    ];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Notifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cFg)),
        const Text('Alerts & system messages', style: TextStyle(fontSize: 12, color: cMuted)),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: notifs.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: cBorder),
              itemBuilder: (_, i) {
                final n = notifs[i];
                final isRead = n['read'] as bool;
                final type = n['type'] as String;
                final typeColor = type == 'warning' ? cAmber700 : type == 'success' ? cEm600 : cBlue700;
                final typeBg = type == 'warning' ? cAmber50 : type == 'success' ? cEm50 : cBlue50;
                return Container(
                  color: isRead ? null : typeBg.withOpacity(0.3),
                  padding: const EdgeInsets.all(16),
                  child: Row(children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: typeBg, borderRadius: BorderRadius.circular(100)), child: Icon(type == 'warning' ? Icons.warning_amber_rounded : type == 'success' ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded, size: 18, color: typeColor)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(n['title'] as String, style: TextStyle(fontSize: 12, fontWeight: isRead ? FontWeight.w500 : FontWeight.w700, color: cFg)),
                      const SizedBox(height: 3),
                      Text(n['body'] as String, style: const TextStyle(fontSize: 11, color: cMuted)),
                    ])),
                    Text(n['time'] as String, style: const TextStyle(fontSize: 10, color: cMuted)),
                    if (!isRead) Container(margin: const EdgeInsets.only(left: 8), width: 7, height: 7, decoration: BoxDecoration(color: cPrimary, borderRadius: BorderRadius.circular(100))),
                  ]),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }

  // ─── TAB 10: SETTINGS ────────────────────────────────
  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cFg)),
        const Text('Profile & preferences', style: TextStyle(fontSize: 12, color: cMuted)),
        const SizedBox(height: 24),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: cCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: cBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Profile Information', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
              const Divider(height: 20, color: cBorder),
              _settingsRow('Full Name', _api.fullName ?? 'Receptionist'),
              _settingsRow('Role', 'Receptionist'),
              _settingsRow('Email', _api.baseUrl.contains('localhost') ? 'receptionist@vermahomeopathy.com' : '—'),
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
              const Text('System Preferences', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
              const Divider(height: 20, color: cBorder),
              _settingsRow('API Endpoint', _api.baseUrl),
              _settingsRow('Theme', 'Light (Default)'),
              _settingsRow('Language', 'English (India)'),
            ]),
          )),
        ]),
      ]),
    );
  }

  Widget _settingsRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: cMuted)),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cFg)),
    ]),
  );

  // ─── DIALOGS ─────────────────────────────────────────
  void _showAddPatientDialog() {
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: cCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480, padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Add New Patient', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cFg)),
              Text('Register a new patient in the system', style: TextStyle(fontSize: 11, color: cMuted)),
            ]),
            IconButton(icon: const Icon(Icons.close_rounded, size: 18, color: cMuted), onPressed: () => Navigator.pop(ctx)),
          ]),
          const Divider(height: 24, color: cBorder),
          const Text('REQUIRED INFORMATION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: cMuted, letterSpacing: 1.0)),
          const SizedBox(height: 12),
          _formField('Full Name *', 'e.g. Ramesh Kumar'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _formField('Date of Birth *', 'YYYY-MM-DD')),
            const SizedBox(width: 10),
            Expanded(child: _formField('Gender *', 'Male / Female')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _formField('Mobile *', '98765-43210')),
            const SizedBox(width: 10),
            Expanded(child: _formField('Occupation *', 'e.g. Teacher')),
          ]),
          const SizedBox(height: 10),
          _formField('Address *', 'Full address'),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            _outlineBtn('Cancel', null, () => Navigator.pop(ctx)),
            const SizedBox(width: 8),
            _primaryBtn('Save Patient', null, () => Navigator.pop(ctx)),
          ]),
        ]),
      ),
    ));
  }

  void _showBookApptDialog() {
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: cCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400, padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Book Appointment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cFg)),
            IconButton(icon: const Icon(Icons.close_rounded, size: 18, color: cMuted), onPressed: () => Navigator.pop(ctx)),
          ]),
          const Divider(height: 20, color: cBorder),
          _formField('Search Patient', 'Name or mobile number'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _formField('Date', _date)),
            const SizedBox(width: 10),
            Expanded(child: _formField('Time', 'HH:MM')),
          ]),
          const SizedBox(height: 10),
          _formField('Visit Type', 'New / Follow Up'),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            _outlineBtn('Cancel', null, () => Navigator.pop(ctx)),
            const SizedBox(width: 8),
            _primaryBtn('Book Appointment', null, () => Navigator.pop(ctx)),
          ]),
        ]),
      ),
    ));
  }

  void _showCreateInvoiceDialog() {
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: cCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600, padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Create Invoice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cFg)),
            IconButton(icon: const Icon(Icons.close_rounded, size: 18, color: cMuted), onPressed: () => Navigator.pop(ctx)),
          ]),
          const Divider(height: 20, color: cBorder),
          _formField('Search Patient', 'Name or patient ID'),
          const SizedBox(height: 10),
          _formField('Service Description', 'Consultation Fee, Medicine Charges…'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _formField('Amount (₹)', '500')),
            const SizedBox(width: 10),
            Expanded(child: _formField('Date', _date)),
          ]),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            _outlineBtn('Save Draft', null, () => Navigator.pop(ctx)),
            const SizedBox(width: 8),
            _primaryBtn('Issue Invoice', null, () { Navigator.pop(ctx); _fetchData(); }),
          ]),
        ]),
      ),
    ));
  }

  void _showPaymentDialog(dynamic inv) {
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: cCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 360, padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Collect Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cFg)),
            IconButton(icon: const Icon(Icons.close_rounded, size: 18, color: cMuted), onPressed: () => Navigator.pop(ctx)),
          ]),
          const Divider(height: 20, color: cBorder),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: cMutedBg, borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Balance Due', style: TextStyle(fontSize: 11, color: cMuted)),
              Text('₹${(inv['total_amount'] ?? 0).toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: cRed600)),
            ]),
          ),
          const SizedBox(height: 12),
          _formField('Amount (₹)', '${inv['total_amount'] ?? 0}'),
          const SizedBox(height: 10),
          const Text('Payment Mode', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cMuted)),
          const SizedBox(height: 6),
          Row(children: [
            for (final mode in ['Cash', 'UPI', 'Card']) Expanded(child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(border: Border.all(color: cBorder), borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  Icon(mode == 'Cash' ? Icons.payments_outlined : mode == 'UPI' ? Icons.phone_android_rounded : Icons.credit_card_rounded, size: 16, color: cMuted),
                  const SizedBox(height: 4),
                  Text(mode, style: const TextStyle(fontSize: 10, color: cMuted)),
                ]),
              ),
            )),
          ]),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () { Navigator.pop(ctx); _fetchData(); },
              style: ElevatedButton.styleFrom(backgroundColor: cEm600, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
              child: const Text('Record Payment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    ));
  }

  void _showStockInwardDialog() {
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: cCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420, padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Stock Inward', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cFg)),
            IconButton(icon: const Icon(Icons.close_rounded, size: 18, color: cMuted), onPressed: () => Navigator.pop(ctx)),
          ]),
          const Divider(height: 20, color: cBorder),
          _formField('Search Medicine', 'Medicine name or code'),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _formField('Batch No', 'BT-XXXX')),
            const SizedBox(width: 10),
            Expanded(child: _formField('Quantity', 'Units received')),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _formField('Expiry Date', 'YYYY-MM-DD')),
            const SizedBox(width: 10),
            Expanded(child: _formField('Supplier', 'Supplier name')),
          ]),
          const SizedBox(height: 10),
          _formField('Cost per Unit (₹)', '0.00'),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            _outlineBtn('Cancel', null, () => Navigator.pop(ctx)),
            const SizedBox(width: 8),
            _primaryBtn('Record Inward', null, () => Navigator.pop(ctx)),
          ]),
        ]),
      ),
    ));
  }

  // ─── HELPER WIDGETS ──────────────────────────────────
  Widget _statusPill(String status) {
    final Map<String, List<Color>> pillMap = {
      'scheduled':     [const Color(0xFFF1F5F9), const Color(0xFF475569)],
      'arrived':       [cBlue50, cBlue700],
      'waiting':       [cAmber50, cAmber700],
      'in consultation': [cAmber50, cAmber700],
      'completed':     [cEm50, cEm700],
      'cancelled':     [cRed50, cRed600],
      'no show':       [cSlate100, cSlate600],
      'paid':          [cEm50, cEm700],
      'partial':       [cAmber50, cAmber700],
      'draft':         [cSlate100, cSlate600],
      'issued':        [cBlue50, cBlue700],
      'active':        [cEm50, cEm700],
      'follow-up':     [cPurple50, cPurple700],
      'low':           [cAmber50, cAmber700],
      'expiring':      [cRed50, cRed600],
      'ok':            [cEm50, cEm700],
    };
    final colors = pillMap[status.toLowerCase()] ?? [cSlate100, cMuted];
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

  Widget _tagBadge(String label, Color bg, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(100)),
    child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
  );

  Widget _smallBtn(String label, Color bg, Color fg, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
    ),
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

  Widget _sectionWrap({required Widget child}) => child;

  Widget _formField(String label, String hint) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cFg)),
    const SizedBox(height: 5),
    TextField(
      style: const TextStyle(fontSize: 12, color: cFg),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: cMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: cBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: cBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: cPrimary, width: 1.5)),
        filled: true, fillColor: cCard,
      ),
    ),
  ]);
}
