import 'dart:convert';

import 'package:flutter/material.dart';

import '../../core/csv_export.dart';

import '../../core/constants.dart';
import '../../services/api_service.dart';

// ─── Color System ────────────────────────────────────
const cBg       = Color(0xFFF8FAFC);
const cCard     = Color(0xFFFFFFFF);
const cBorder   = Color(0x1A000000);
const cFg       = Color(0xFF0F172A);
const cMuted    = Color(0xFF717182);
const cMutedBg  = Color(0xFFECECF0);
const cPrimary  = Color(0xFF0F766E);

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _api = ApiService();
  final TextEditingController _baseUrlCtrl = TextEditingController();

  String _tab = 'overview';
  bool _loading = true;

  // Overview
  int _patientCount = 0;
  double _todayRevenue = 0;
  int _activeUsers = 0;
  int _todayAppointments = 0;
  List<dynamic> _clinics = [];
  final Map<String, num> _clinicRevenue = {};

  // Users
  List<dynamic> _users = [];

  // Audit logs
  List<dynamic> _logs = [];
  bool _logsLoading = false;
  String? _entityFilter;
  String? _actionFilter;

  static const _entityOptions = ['All', 'Patient', 'Appointment', 'Invoice', 'Payment', 'User', 'Clinic'];
  static const _actionOptions = ['All', 'CREATE', 'UPDATE', 'DELETE'];

  // Reports
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _toDate = DateTime.now();
  String? _reportClinicId;
  List<dynamic> _revenue = [];
  Map<String, dynamic> _apptReport = {};
  List<dynamic> _registrations = [];
  bool _reportsLoading = false;

  final List<Map<String, dynamic>> _navItems = [
    {'key': 'overview', 'label': 'Overview', 'icon': Icons.grid_view_rounded},
    {'key': 'users', 'label': 'Users', 'icon': Icons.people_outline_rounded},
    {'key': 'audit', 'label': 'Audit Logs', 'icon': Icons.receipt_long_outlined},
    {'key': 'reports', 'label': 'Reports', 'icon': Icons.bar_chart_rounded},
    {'key': 'clinics', 'label': 'Clinics', 'icon': Icons.local_hospital_outlined},
    {'key': 'settings', 'label': 'Settings', 'icon': Icons.settings_outlined},
  ];

  final Map<String, Map<String, String>> _titles = {
    'overview': {'title': 'Admin Dashboard', 'subtitle': 'Organization-wide overview'},
    'users':    {'title': 'User Management', 'subtitle': 'Accounts, roles & access'},
    'audit':    {'title': 'Audit Logs', 'subtitle': 'System activity trail'},
    'reports':  {'title': 'Reports', 'subtitle': 'Revenue, appointments & growth'},
    'clinics':  {'title': 'Clinics', 'subtitle': 'Locations & timings'},
    'settings': {'title': 'Settings', 'subtitle': 'Configuration & session'},
  };

  @override
  void initState() {
    super.initState();
    _baseUrlCtrl.text = _api.baseUrl;
    _loadOverview();
  }

  @override
  void dispose() {
    _baseUrlCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(e.toString().replaceAll('Exception: ', '')),
      backgroundColor: AppColors.red600,
    ));
  }

  // ─── DATA LOADING ────────────────────────────────────
  Future<void> _loadOverview() async {
    setState(() => _loading = true);
    try {
      final today = _fmt(DateTime.now());
      final results = await Future.wait([
        _api.getPatients(),
        _api.getClinics(),
        _api.adminListUsers(),
      ]);
      final patients = results[0];
      final clinics = results[1];
      final users = results[2];

      num totalRevenue = 0;
      final revByClinic = <String, num>{};
      for (final c in clinics) {
        try {
          final kpis = await _api.getKpis(c['clinic_id'], today);
          final rev = (kpis['today_revenue'] as num?) ?? 0;
          revByClinic[c['clinic_id']] = rev;
          totalRevenue += rev;
        } on ApiException catch (e) {
          if (!e.isAuthError) rethrow;
        }
      }
      final appts = await _api.getAppointments(date: today);

      if (!mounted) return;
      setState(() {
        _patientCount = patients.length;
        _clinics = clinics;
        _clinicRevenue
          ..clear()
          ..addAll(revByClinic);
        _todayRevenue = totalRevenue.toDouble();
        _activeUsers = users.where((u) => u['is_active'] == true).length;
        _todayAppointments = appts.length;
        _users = users;
        _loading = false;
      });
    } catch (e) {
      _showError(e);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final users = await _api.adminListUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      _showError(e);
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadLogs() async {
    setState(() => _logsLoading = true);
    try {
      final logs = await _api.getAuditLogs(
        entityType: (_entityFilter == null || _entityFilter == 'All') ? null : _entityFilter,
        action: (_actionFilter == null || _actionFilter == 'All') ? null : _actionFilter,
      );
      if (!mounted) return;
      setState(() {
        _logs = logs;
        _logsLoading = false;
      });
    } catch (e) {
      _showError(e);
      if (mounted) setState(() => _logsLoading = false);
    }
  }

  Future<void> _loadReports() async {
    setState(() => _reportsLoading = true);
    try {
      final from = _fmt(_fromDate);
      final to = _fmt(_toDate);
      final revenue = await _api.adminRevenueReport(from, to, clinicId: _reportClinicId);
      final apptReport = await _api.adminAppointmentReport(from, to, clinicId: _reportClinicId);
      final registrations = await _api.adminRegistrationsReport(months: 6);
      if (!mounted) return;
      setState(() {
        _revenue = revenue;
        _apptReport = apptReport;
        _registrations = registrations;
        _reportsLoading = false;
      });
    } catch (e) {
      _showError(e);
      if (mounted) setState(() => _reportsLoading = false);
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
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator(color: cPrimary))
                      : _buildBody(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SIDEBAR (dark) ──────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: AppColors.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)))),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: cPrimary, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Verma Homeopathy',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      Text('Super Admin Portal',
                          style: TextStyle(fontSize: 10, color: AppColors.slate400)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 4),
                    child: Text('ADMINISTRATION',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.slate400, letterSpacing: 0.8)),
                  ),
                  ..._navItems.map((item) {
                    final key = item['key'] as String;
                    final active = _tab == key;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: InkWell(
                        onTap: () {
                          setState(() => _tab = key);
                          if (key == 'overview') _loadOverview();
                          if (key == 'users') _loadUsers();
                          if (key == 'audit') _loadLogs();
                          if (key == 'reports') _loadReports();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                          decoration: BoxDecoration(
                            color: active ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(item['icon'] as IconData,
                                  size: 16, color: active ? AppColors.primaryLight : AppColors.slate400),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(item['label'] as String,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: active ? Colors.white : Colors.white.withValues(alpha: 0.72),
                                        fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08)))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: cPrimary,
                      child: Text(
                        (_api.fullName?.isNotEmpty == true ? _api.fullName![0] : 'A'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_api.fullName ?? 'Administrator',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                          const Text('SuperAdmin', style: TextStyle(fontSize: 10, color: AppColors.slate400)),
                        ],
                      ),
                    ),
                  ],
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
    return Container(
      height: 56,
      decoration: BoxDecoration(color: cCard, border: Border(bottom: BorderSide(color: cBorder))),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(meta['title']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cFg)),
                Text(meta['subtitle']!, style: const TextStyle(fontSize: 11, color: cMuted)),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              switch (_tab) {
                case 'overview':
                  _loadOverview();
                case 'users':
                  _loadUsers();
                case 'audit':
                  _loadLogs();
                case 'reports':
                  _loadReports();
              }
            },
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, size: 20, color: cMuted),
          ),
        ],
      ),
    );
  }

  // ─── BODY ROUTER ─────────────────────────────────────
  Widget _buildBody() {
    switch (_tab) {
      case 'overview':
        return _buildOverviewTab();
      case 'users':
        return _buildUsersTab();
      case 'audit':
        return _buildAuditTab();
      case 'reports':
        return _buildReportsTab();
      case 'clinics':
        return _buildClinicsTab();
      case 'settings':
        return _buildSettingsTab();
      default:
        return _buildOverviewTab();
    }
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cBorder),
      ),
      child: child,
    );
  }

  Widget _kpiCard({required String label, required String value, required String sub, required IconData icon, required Color iconColor, required Color iconBg}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: cMuted)),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 15, color: iconColor),
              ),
            ],
          ),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: cFg)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 10, color: cMuted)),
        ],
      ),
    );
  }

  // ─── TAB: OVERVIEW ───────────────────────────────────
  Widget _buildOverviewTab() {
    final kpis = [
      {'label': 'Total Patients', 'value': '$_patientCount', 'sub': 'Across all clinics', 'icon': Icons.people_outline_rounded, 'iconColor': AppColors.blue700, 'iconBg': AppColors.blue100},
      {'label': "Today's Revenue", 'value': '₹${_todayRevenue.toStringAsFixed(0)}', 'sub': '${_clinics.length} clinics combined', 'icon': Icons.currency_rupee_rounded, 'iconColor': AppColors.green600, 'iconBg': AppColors.green100},
      {'label': 'Active Users', 'value': '$_activeUsers', 'sub': '${_users.length} accounts total', 'icon': Icons.badge_outlined, 'iconColor': AppColors.primary, 'iconBg': AppColors.violet100},
      {'label': "Today's Appointments", 'value': '$_todayAppointments', 'sub': _fmt(DateTime.now()), 'icon': Icons.calendar_month_outlined, 'iconColor': AppColors.amber700, 'iconBg': AppColors.amber100},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.9,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: kpis
                .map((k) => _kpiCard(
                      label: k['label'] as String,
                      value: k['value'] as String,
                      sub: k['sub'] as String,
                      icon: k['icon'] as IconData,
                      iconColor: k['iconColor'] as Color,
                      iconBg: k['iconBg'] as Color,
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
          const Text('Per-Clinic Snapshot',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
          const SizedBox(height: 10),
          if (_clinics.isEmpty)
            _sectionCard(child: Text('No clinics configured yet.', style: TextStyle(fontSize: 12, color: cMuted)))
          else
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: _clinics.map<Widget>((c) {
                final id = c['clinic_id'];
                final rev = (_clinicRevenue[id] ?? 0).toDouble();
                return SizedBox(
                  width: 260,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(color: AppColors.violet100, borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.local_hospital_outlined, size: 15, color: AppColors.violet700),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(c['name']?.toString() ?? 'Clinic',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('₹${rev.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.green600)),
                        const SizedBox(height: 2),
                        Text("Today's revenue · ${c['timezone'] ?? ''}",
                            style: const TextStyle(fontSize: 10, color: cMuted)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ─── TAB: USERS ──────────────────────────────────────
  Color _roleChipColor(String role) {
    switch (role) {
      case UserRoles.superAdmin:
        return AppColors.violet700;
      case UserRoles.doctor:
        return AppColors.blue700;
      case UserRoles.receptionist:
        return AppColors.amber700;
      case UserRoles.patient:
        return AppColors.green600;
      default:
        return AppColors.textMuted;
    }
  }

  Color _roleChipBg(String role) {
    switch (role) {
      case UserRoles.superAdmin:
        return AppColors.violet100;
      case UserRoles.doctor:
        return AppColors.blue100;
      case UserRoles.receptionist:
        return AppColors.amber100;
      case UserRoles.patient:
        return AppColors.green100;
      default:
        return AppColors.slate200;
    }
  }

  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _sectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('User Accounts',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cFg)),
                ),
                Text('${_users.length} users', style: const TextStyle(fontSize: 11, color: cMuted)),
              ],
            ),
            const SizedBox(height: 12),
            // Header row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: Text('Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  Expanded(flex: 4, child: Text('Email', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  Expanded(flex: 2, child: Text('Role', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  Expanded(flex: 2, child: Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                  Expanded(flex: 4, child: Text('Actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cMuted))),
                ],
              ),
            ),
            const SizedBox(height: 4),
            ..._users.map((u) {
              final userId = u['user_id']?.toString() ?? '';
              final isSelf = userId == _api.userId;
              final role = u['role']?.toString() ?? '';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: cBorder))),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(u['full_name']?.toString() ?? '—',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cFg),
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (isSelf) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(color: cMutedBg, borderRadius: BorderRadius.circular(100)),
                              child: const Text('You', style: TextStyle(fontSize: 9, color: cMuted)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(u['email']?.toString() ?? '—',
                          style: const TextStyle(fontSize: 12, color: cMuted), overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: _roleChipBg(role), borderRadius: BorderRadius.circular(100)),
                          child: Text(role,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _roleChipColor(role))),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Transform.scale(
                        scale: 0.75,
                        child: Switch(
                          value: u['is_active'] == true,
                          activeColor: AppColors.green600,
                          onChanged: (v) => _toggleUserActive(userId, v),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _resetPasswordDialog(u),
                            icon: const Icon(Icons.key_outlined, size: 13),
                            label: const Text('Reset Password', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.blue700,
                              side: BorderSide(color: cBorder),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: isSelf ? null : () => _deleteUserDialog(u),
                            icon: const Icon(Icons.delete_outline_rounded, size: 13),
                            label: Text(isSelf ? 'Self' : 'Delete', style: const TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.red600,
                              side: BorderSide(color: cBorder),
                              disabledForegroundColor: AppColors.slate400,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleUserActive(String userId, bool active) async {
    try {
      await _api.adminUpdateUser(userId, {'is_active': active});
      await _loadUsers();
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _resetPasswordDialog(Map<String, dynamic> user) async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset Password — ${user['full_name'] ?? ''}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'New password',
              hintText: 'Minimum 6 characters',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.adminResetPassword(user['user_id'].toString(), ctrl.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password reset successfully.'),
        backgroundColor: AppColors.green600,
      ));
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _deleteUserDialog(Map<String, dynamic> user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        content: Text(
            'This will permanently delete "${user['full_name'] ?? user['email']}". This action cannot be undone.',
            style: const TextStyle(fontSize: 12)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red600),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.adminDeleteUser(user['user_id'].toString());
      await _loadUsers();
    } catch (e) {
      _showError(e);
    }
  }

  // ─── TAB: AUDIT LOGS ─────────────────────────────────
  Widget _filterDropdown(String value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: cBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: const TextStyle(fontSize: 12, color: cFg),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Color _actionChipColor(String action) {
    switch (action.toUpperCase()) {
      case 'CREATE':
        return AppColors.green600;
      case 'UPDATE':
        return AppColors.blue700;
      case 'DELETE':
        return AppColors.red600;
      default:
        return AppColors.textMuted;
    }
  }

  Widget _buildAuditTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: _sectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Activity Trail', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cFg)),
                const Spacer(),
                _filterDropdown(_entityFilter ?? 'All', _entityOptions, (v) {
                  setState(() => _entityFilter = v);
                  _loadLogs();
                }),
                const SizedBox(width: 8),
                _filterDropdown(_actionFilter ?? 'All', _actionOptions, (v) {
                  setState(() => _actionFilter = v);
                  _loadLogs();
                }),
              ],
            ),
            const SizedBox(height: 12),
            if (_logsLoading)
              const Center(
                child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: cPrimary)),
              )
            else if (_logs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(child: Text('No audit entries found.', style: TextStyle(fontSize: 12, color: cMuted))),
              )
            else
              ..._logs.map((log) {
                final action = log['action']?.toString() ?? '';
                final changes = log['changes_json']?.toString();
                String pretty = changes ?? '';
                if (pretty.isNotEmpty) {
                  try {
                    pretty = const JsonEncoder.withIndent('  ').convert(jsonDecode(pretty));
                  } catch (_) {}
                }
                final ts = log['created_at']?.toString() ?? log['timestamp']?.toString() ?? '';
                return Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                    childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                    title: Row(
                      children: [
                        SizedBox(
                          width: 170,
                          child: Text(ts,
                              style: const TextStyle(fontSize: 11, color: cMuted), overflow: TextOverflow.ellipsis),
                        ),
                        SizedBox(
                          width: 180,
                          child: Text(log['actor_name']?.toString() ?? log['actor']?.toString() ?? 'System',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: cFg),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _actionChipColor(action).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(action.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700, color: _actionChipColor(action))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${log['entity_type']?.toString() ?? ''} ${log['entity_id']?.toString() ?? ''}'.trim(),
                            style: const TextStyle(fontSize: 12, color: cMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    children: [
                      if (pretty.isEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('No change payload recorded.', style: TextStyle(fontSize: 11, color: cMuted)),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: cBg, borderRadius: BorderRadius.circular(8)),
                          child: SelectableText(pretty,
                              style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: cFg)),
                        ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ─── TAB: REPORTS ────────────────────────────────────
  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (_toDate.isBefore(_fromDate)) _toDate = _fromDate;
      } else {
        _toDate = picked.isAfter(DateTime.now()) ? DateTime.now() : picked;
        if (_toDate.isBefore(_fromDate)) _fromDate = _toDate;
      }
    });
    _loadReports();
  }

  Widget _dateField(String label, DateTime value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: cBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 13, color: cMuted),
            const SizedBox(width: 6),
            Text('$label · ${_fmt(value)}', style: const TextStyle(fontSize: 12, color: cFg)),
          ],
        ),
      ),
    );
  }

  void _exportRevenueCsv() {
    final buf = StringBuffer('date,revenue,payments_count\n');
    for (final r in _revenue) {
      buf.writeln('${r['date'] ?? ''},${r['revenue'] ?? 0},${r['payments_count'] ?? 0}');
    }
    downloadTextFile('revenue_${_fmt(_fromDate)}_${_fmt(_toDate)}.csv', buf.toString());
  }

  Widget _statChip(String label, num value, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$value', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 1),
          Text(label, style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.85))),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    final totalRev = _revenue.fold<num>(0, (s, r) => s + ((r['revenue'] as num?) ?? 0));
    final appt = _apptReport;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionCard(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _dateField('From', _fromDate, () => _pickDate(true)),
                _dateField('To', _toDate, () => _pickDate(false)),
                Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: cBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: cBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _reportClinicId ?? '__all__',
                      isDense: true,
                      style: const TextStyle(fontSize: 12, color: cFg),
                      items: [
                        const DropdownMenuItem(value: '__all__', child: Text('All Clinics')),
                        ..._clinics.map((c) => DropdownMenuItem(
                            value: c['clinic_id'].toString(), child: Text(c['name']?.toString() ?? 'Clinic'))),
                      ],
                      onChanged: (v) {
                        setState(() => _reportClinicId = (v == '__all__') ? null : v);
                        _loadReports();
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _revenue.isEmpty ? null : _exportRevenueCsv,
                  icon: const Icon(Icons.download_rounded, size: 14),
                  label: const Text('Export CSV', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.green600,
                    side: BorderSide(color: cBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (_reportsLoading)
            const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator(color: cPrimary)))
          else ...[
            // Revenue bar chart
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Daily Revenue',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
                      ),
                      Text('Total ₹${totalRev.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.green600)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_revenue.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text('No revenue data for this range.', style: TextStyle(fontSize: 12, color: cMuted))),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: LayoutBuilder(builder: (context, constraints) {
                        final maxRev = _revenue.fold<num>(
                            0, (m, r) => (r['revenue'] as num?) != null && (r['revenue'] as num) > m ? r['revenue'] : m);
                        final n = _revenue.length;
                        final barW = n > 0 ? (constraints.maxWidth / n).clamp(4.0, 36.0) : 4.0;
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: n,
                          separatorBuilder: (_, __) => const SizedBox(width: 4),
                          itemBuilder: (context, i) {
                            final row = _revenue[i];
                            final rev = (row['revenue'] as num?) ?? 0;
                            final h = maxRev > 0 ? (rev / maxRev * 180).clamp(2.0, 180.0) : 2.0;
                            final d = DateTime.tryParse(row['date']?.toString() ?? '');
                            return Tooltip(
                              message: '${row['date']}\n₹${rev.toStringAsFixed(0)} · ${row['payments_count'] ?? 0} payments',
                              child: SizedBox(
                                width: barW,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: barW,
                                      height: h,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.85),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                      ),
                                    ),
                                    if (n <= 20 && d != null) ...[
                                      const SizedBox(height: 4),
                                      Text('${d.day}/${d.month}',
                                          style: TextStyle(fontSize: 8, color: cMuted)),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Appointment summary chips
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Appointment Summary',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _statChip('Total', (appt['total'] as num?) ?? 0, cFg, cMutedBg),
                      _statChip(AppointmentStatus.completed.toLowerCase().capitalize(), (appt['completed'] as num?) ?? 0, AppColors.green600, AppColors.green100),
                      _statChip(AppointmentStatus.cancelled.toLowerCase().capitalize(), (appt['cancelled'] as num?) ?? 0, AppColors.red600, AppColors.red100),
                      _statChip(AppointmentStatus.noShow.toLowerCase().capitalize(), (appt['no_show'] as num?) ?? 0, AppColors.amber700, AppColors.amber100),
                      _statChip(AppointmentStatus.scheduled.toLowerCase().capitalize(), (appt['scheduled'] as num?) ?? 0, AppColors.slate400, AppColors.slate200),
                      _statChip(AppointmentStatus.confirmed.toLowerCase().capitalize(), (appt['confirmed'] as num?) ?? 0, AppColors.blue700, AppColors.blue100),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Registrations trend
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Registrations Trend (last 6 months)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
                  const SizedBox(height: 8),
                  if (_registrations.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('No registration data.', style: TextStyle(fontSize: 12, color: cMuted)),
                    )
                  else
                    ..._registrations.map((r) {
                      final reg = (r['registrations'] as num?) ?? 0;
                      final maxReg = _registrations.fold<num>(
                          0, (m, x) => ((x['registrations'] as num?) ?? 0) > m ? x['registrations'] : m);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 90,
                              child: Text(r['month']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 12, color: cFg)),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: maxReg > 0 ? reg / maxReg : 0,
                                  minHeight: 8,
                                  backgroundColor: cMutedBg,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Text('$reg',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cFg)),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── TAB: CLINICS (read-only) ────────────────────────
  Widget _buildClinicsTab() {
    return FutureBuilder<List<dynamic>>(
      future: _api.getClinics(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: cPrimary));
        }
        if (snap.hasError) {
          return Center(
            child: Text('Failed to load clinics: ${snap.error}',
                style: const TextStyle(fontSize: 12, color: AppColors.red600)),
          );
        }
        final clinics = snap.data ?? [];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: clinics.map<Widget>((c) {
              return SizedBox(
                width: 320,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(color: AppColors.violet100, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.local_hospital_outlined, size: 16, color: AppColors.violet700),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(c['name']?.toString() ?? 'Clinic',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cFg)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: cMuted),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(c['address']?.toString() ?? '—',
                                style: const TextStyle(fontSize: 12, color: cMuted)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.schedule_outlined, size: 14, color: cMuted),
                          const SizedBox(width: 6),
                          Text('${c['timing_start'] ?? '?'} – ${c['timing_end'] ?? '?'}',
                              style: const TextStyle(fontSize: 12, color: cFg)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.public_outlined, size: 14, color: cMuted),
                          const SizedBox(width: 6),
                          Text(c['timezone']?.toString() ?? '—',
                              style: const TextStyle(fontSize: 12, color: cMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // ─── TAB: SETTINGS ───────────────────────────────────
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('API Configuration',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cFg)),
                  const SizedBox(height: 4),
                  const Text('Base URL of the backend API server.',
                      style: TextStyle(fontSize: 11, color: cMuted)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _baseUrlCtrl,
                    style: const TextStyle(fontSize: 12, color: cFg),
                    decoration: InputDecoration(
                      hintText: 'http://localhost:8000/api/v1',
                      hintStyle: const TextStyle(fontSize: 12, color: cMuted),
                      filled: true,
                      fillColor: cBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: cPrimary)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      try {
                        await _api.setBaseUrl(_baseUrlCtrl.text.trim());
                        if (!mounted) return;
                        setState(() => _baseUrlCtrl.text = _api.baseUrl);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('API base URL saved.'),
                          backgroundColor: AppColors.green600,
                        ));
                      } catch (e) {
                        _showError(e);
                      }
                    },
                    icon: const Icon(Icons.save_outlined, size: 15),
                    label: const Text('Save'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _sectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Session',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cFg)),
                  const SizedBox(height: 4),
                  Text('Signed in as ${_api.fullName ?? 'Administrator'} (SuperAdmin).',
                      style: const TextStyle(fontSize: 11, color: cMuted)),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await _api.clearSession();
                      if (!mounted) return;
                      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                    },
                    icon: const Icon(Icons.logout_rounded, size: 15),
                    label: const Text('Log out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red600,
                      side: const BorderSide(color: AppColors.red600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension _StringCasingX on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
