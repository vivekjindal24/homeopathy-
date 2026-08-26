import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../services/api_service.dart';

enum _PortalView { home, book, login, account }
enum _BookStep { slot, details, confirmation }

class PatientPortalHome extends StatefulWidget {
  const PatientPortalHome({super.key});

  @override
  State<PatientPortalHome> createState() => _PatientPortalHomeState();
}

class _PatientPortalHomeState extends State<PatientPortalHome> {
  final ApiService _api = ApiService();

  _PortalView _view = _PortalView.home;
  bool _busy = false;

  // Booking flow
  _BookStep _bookStep = _BookStep.slot;
  List<dynamic> _portalClinics = [];
  Map<String, dynamic>? _selectedClinic;
  DateTime? _selectedDate;
  String? _selectedTime;
  Map<String, dynamic>? _bookingResult;

  final _fullNameCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  DateTime? _dob;
  String _gender = 'M';
  String _visitType = VisitType.newVisit;

  // Login flow
  String _loginStage = 'mobile'; // mobile | otp
  final _otpCtrl = TextEditingController();
  String? _devOtp;
  String _loginMobile = '';

  // Account data
  List<dynamic> _myAppointments = [];
  List<dynamic> _myInvoices = [];

  @override
  void initState() {
    super.initState();
    _tryRestore();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _mobileCtrl.dispose();
    _otpCtrl.dispose();
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

  Future<void> _tryRestore() async {
    try {
      final ok = await _api.restoreSession();
      if (ok && mounted) {
        setState(() => _view = _PortalView.account);
        await _loadAccount();
      }
    } catch (_) {
      // Session restore is best-effort; stay on public home.
    }
  }

  Future<void> _loadAccount() async {
    setState(() => _busy = true);
    try {
      final appts = await _api.portalMyAppointments();
      final invoices = await _api.portalMyInvoices();
      if (!mounted) return;
      setState(() {
        _myAppointments = appts;
        _myInvoices = invoices;
        _busy = false;
      });
    } catch (e) {
      _showError(e);
      if (mounted) setState(() => _busy = false);
    }
  }

  num _asNum(dynamic v) => v is num ? v : num.tryParse(v?.toString() ?? '') ?? 0;

  // ─── TIME SLOTS ──────────────────────────────────────
  int _parseTimeToMinutes(dynamic s) {
    if (s == null) return 9 * 60;
    final parts = s.toString().split(':');
    final h = int.tryParse(parts.isNotEmpty ? parts[0] : '') ?? 9;
    final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return h * 60 + m;
  }

  List<String> _slotsFor(Map<String, dynamic> clinic) {
    final start = _parseTimeToMinutes(clinic['timing_start']);
    final end = _parseTimeToMinutes(clinic['timing_end']);
    final slots = <String>[];
    for (var t = start; t + 20 <= end; t += 20) {
      slots.add('${(t ~/ 60).toString().padLeft(2, '0')}:${(t % 60).toString().padLeft(2, '0')}');
    }
    return slots;
  }

  List<DateTime> _nextDays(int n) =>
      List.generate(n, (i) => DateTime.now().add(Duration(days: i)));

  // ─── MAIN BUILD ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    switch (_view) {
      case _PortalView.home:
        return _buildHome();
      case _PortalView.book:
        return _buildBookFlow();
      case _PortalView.login:
        return _buildLogin();
      case _PortalView.account:
        return _buildAccount();
    }
  }

  Widget _topChrome({required Widget child, bool showAuthActions = true}) {
    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cCard,
        surfaceTintColor: cCard,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: cFg),
          onPressed: () => setState(() {
            _view = _view == _PortalView.book ? _PortalView.home : _PortalView.home;
            _bookStep = _BookStep.slot;
          }),
        ),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: cPrimary, borderRadius: BorderRadius.circular(7)),
              child: const Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text('Verma Homeopathy',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
          ],
        ),
        actions: [
          if (showAuthActions)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: TextButton(
                  onPressed: () => setState(() => _view = _PortalView.login),
                  child: const Text('Login', style: TextStyle(fontSize: 12, color: cPrimary)),
                ),
              ),
            ),
        ],
      ),
      body: _busy
          ? const Center(child: CircularProgressIndicator(color: cPrimary))
          : child,
    );
  }

  // ─── A. LOGGED-OUT HOME ──────────────────────────────
  Widget _buildHome() {
    return Scaffold(
      backgroundColor: cBg,
      body: Column(
        children: [
          // Header
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(color: cCard, border: Border(bottom: BorderSide(color: cBorder))),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: cPrimary, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 17),
                ),
                const SizedBox(width: 10),
                const Text('Verma Homeopathy',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cFg)),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _view = _PortalView.login),
                  child: const Text('Login to view my visits',
                      style: TextStyle(fontSize: 12, color: cPrimary)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(color: AppColors.violet100, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.event_available_rounded, size: 28, color: AppColors.violet700),
                      ),
                      const SizedBox(height: 20),
                      const Text('Book an appointment online',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: cFg)),
                      const SizedBox(height: 8),
                      const Text(
                        'Choose your clinic, pick a convenient time slot and confirm — no account needed for booking. You will receive an SMS confirmation.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: cMuted, height: 1.5),
                      ),
                      const SizedBox(height: 28),
                      FilledButton.icon(
                        onPressed: _startBooking,
                        icon: const Icon(Icons.calendar_month_outlined, size: 17),
                        label: const Text('Book Appointment'),
                        style: FilledButton.styleFrom(
                          backgroundColor: cPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _view = _PortalView.login),
                        icon: const Icon(Icons.person_outline_rounded, size: 17),
                        label: const Text('Login to view my visits'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cFg,
                          side: BorderSide(color: AppColors.slate200),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOOKING FLOW ────────────────────────────────────
  Future<void> _startBooking() async {
    setState(() {
      _view = _PortalView.book;
      _bookStep = _BookStep.slot;
      _selectedClinic = null;
      _selectedDate = null;
      _selectedTime = null;
      _bookingResult = null;
      _busy = true;
    });
    try {
      final clinics = await _api.portalClinics();
      if (!mounted) return;
      setState(() {
        _portalClinics = clinics;
        if (clinics.isNotEmpty) _selectedClinic = clinics.first as Map<String, dynamic>;
        _busy = false;
      });
    } catch (e) {
      _showError(e);
      if (mounted) {
        setState(() {
          _busy = false;
          _view = _PortalView.home;
        });
      }
    }
  }

  Widget _stepIndicator() {
    final steps = ['Clinic & Time', 'Your Details', 'Confirmation'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(height: 2, color: i ~/ 2 < _bookStep.index ? cPrimary : AppColors.slate200),
            );
          }
          final idx = i ~/ 2;
          final active = idx <= _bookStep.index;
          return Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: active ? cPrimary : cMutedBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('${idx + 1}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white : cMuted)),
                ),
              ),
              const SizedBox(width: 6),
              Text(steps[idx],
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: active ? cPrimary : cMuted)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildBookFlow() {
    return _topChrome(
      showAuthActions: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _stepIndicator(),
                switch (_bookStep) {
                  _BookStep.slot => _buildSlotStep(),
                  _BookStep.details => _buildDetailsStep(),
                  _BookStep.confirmation => _buildConfirmationStep(),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotStep() {
    final days = _nextDays(14);
    final slots = _selectedClinic != null ? _slotsFor(_selectedClinic!) : <String>[];
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Clinic',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
          const SizedBox(height: 10),
          if (_portalClinics.isEmpty)
            Text('No clinics available for online booking right now.',
                style: TextStyle(fontSize: 12, color: cMuted))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _portalClinics.map<Widget>((c) {
                final selected = _selectedClinic?['clinic_id'] == c['clinic_id'];
                return InkWell(
                  onTap: () => setState(() {
                    _selectedClinic = c as Map<String, dynamic>;
                    _selectedTime = null;
                  }),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 180),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected ? cPrimary.withValues(alpha: 0.06) : cCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? cPrimary : AppColors.slate200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['name']?.toString() ?? 'Clinic',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected ? cPrimary : cFg)),
                        const SizedBox(height: 3),
                        Text('${c['timing_start'] ?? ''} – ${c['timing_end'] ?? ''}',
                            style: const TextStyle(fontSize: 10, color: cMuted)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 20),
          const Text('Pick a Date (next 14 days)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
          const SizedBox(height: 10),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final d = days[i];
                final selected =
                    _selectedDate != null && _fmt(_selectedDate!) == _fmt(d);
                final wd = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][d.weekday % 7];
                return InkWell(
                  onTap: () => setState(() => _selectedDate = d),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 56,
                    decoration: BoxDecoration(
                      color: selected ? cPrimary : cCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? cPrimary : AppColors.slate200),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(wd,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: selected ? Colors.white70 : cMuted)),
                        const SizedBox(height: 4),
                        Text('${d.day}',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: selected ? Colors.white : cFg)),
                        Text(_monthAbbr(d.month),
                            style: TextStyle(fontSize: 10, color: selected ? Colors.white70 : cMuted)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          const Text('Available Slots (20 min)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
          const SizedBox(height: 10),
          if (_selectedDate == null || _selectedClinic == null)
            Text('Select a clinic and date to see time slots.',
                style: TextStyle(fontSize: 12, color: cMuted))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots
                  .map((s) => ChoiceChip(
                        label: Text(s, style: const TextStyle(fontSize: 11)),
                        selected: _selectedTime == s,
                        selectedColor: cPrimary,
                        labelStyle: TextStyle(color: _selectedTime == s ? Colors.white : cFg),
                        checkmarkColor: Colors.white,
                        side: BorderSide(color: _selectedTime == s ? cPrimary : AppColors.slate200),
                        onSelected: (_) => setState(() => _selectedTime = s),
                      ))
                  .toList(),
            ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: (_selectedClinic != null && _selectedDate != null && _selectedTime != null)
                  ? () => setState(() => _bookStep = _BookStep.details)
                  : null,
              style: FilledButton.styleFrom(backgroundColor: cPrimary),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return _card(
      child: Form(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Patient Details',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
            const SizedBox(height: 14),
            TextFormField(
              controller: _fullNameCtrl,
              decoration: _inputDecoration('Full name'),
              validator: (v) => (v == null || v.trim().length < 3) ? 'Please enter the full name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mobileCtrl,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: _inputDecoration('Mobile number').copyWith(
                counterText: '',
                helperText: 'Indian mobile: 10 digits starting with 6–9',
              ),
              validator: (v) =>
                  RegExp(r'^[6-9]\d{9}$').hasMatch(v ?? '') ? null : 'Enter a valid 10-digit Indian mobile number',
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dob ?? DateTime(now.year - 30, now.month, now.day),
                  firstDate: DateTime(now.year - 120),
                  lastDate: now,
                );
                if (picked != null) setState(() => _dob = picked);
              },
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: _inputDecoration('Date of birth'),
                child: Text(
                  _dob != null ? _fmt(_dob!) : 'Select date of birth',
                  style: TextStyle(fontSize: 13, color: _dob != null ? cFg : cMuted),
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: _inputDecoration('Gender'),
              items: const [
                DropdownMenuItem(value: 'M', child: Text('Male')),
                DropdownMenuItem(value: 'F', child: Text('Female')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (v) => setState(() => _gender = v ?? 'M'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _visitType,
              decoration: _inputDecoration('Visit type'),
              items: VisitType.all
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _visitType = v ?? VisitType.newVisit),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () => setState(() => _bookStep = _BookStep.slot),
                  child: const Text('Back'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: cPrimary),
                  onPressed: _submitBooking,
                  child: const Text('Confirm Booking'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12, color: cMuted),
      filled: true,
      fillColor: cCard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.slate200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.slate200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: cPrimary)),
    );
  }

  Future<void> _submitBooking() async {
    FocusScope.of(context).unfocus();
    final formValid = Form.maybeOf(context)?.validate() ?? false;
    if (!formValid) return;
    setState(() => _busy = true);
    try {
      final res = await _api.portalBook({
        'full_name': _fullNameCtrl.text.trim(),
        'mobile': _mobileCtrl.text.trim(),
        'dob': _dob != null ? _fmt(_dob!) : '',
        'gender': _gender,
        'clinic_id': _selectedClinic!['clinic_id'],
        'appt_date': _fmt(_selectedDate!),
        'appt_time': _selectedTime!,
        'visit_type': _visitType,
      });
      if (!mounted) return;
      setState(() {
        _bookingResult = res;
        _bookStep = _BookStep.confirmation;
        _busy = false;
      });
    } catch (e) {
      _showError(e);
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _buildConfirmationStep() {
    final token = _bookingResult?['token_number']?.toString() ?? '—';
    final clinicName = _bookingResult?['clinic_name']?.toString() ?? _selectedClinic?['name']?.toString() ?? '';
    return _card(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: AppColors.green100, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline_rounded, size: 34, color: AppColors.green600),
          ),
          const SizedBox(height: 16),
          const Text('Appointment Confirmed!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cFg)),
          const SizedBox(height: 4),
          const Text('Please arrive a few minutes before your slot.',
              style: TextStyle(fontSize: 12, color: cMuted)),
          const SizedBox(height: 20),
          const Text('YOUR TOKEN NUMBER', style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: cMuted)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
            decoration: BoxDecoration(
              color: cPrimary.withValues(alpha: 0.06),
              border: Border.all(color: cPrimary),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(token,
                style: const TextStyle(
                    fontSize: 40, fontWeight: FontWeight.w800, color: cPrimary, letterSpacing: 2)),
          ),
          const SizedBox(height: 18),
          Text('$clinicName · ${_selectedClinic?['address'] ?? ''}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
          const SizedBox(height: 4),
          Text('${_fmt(_selectedDate!)} at ${_selectedTime ?? ''}',
              style: const TextStyle(fontSize: 12, color: cMuted)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.amber100, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sms_outlined, size: 15, color: AppColors.amber700),
                const SizedBox(width: 8),
                Flexible(
                  child: Text('You will receive an SMS confirmation.',
                      style: TextStyle(fontSize: 11, color: AppColors.amber700.withValues(alpha: 1))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => setState(() {
              _view = _PortalView.home;
              _bookStep = _BookStep.slot;
            }),
            style: FilledButton.styleFrom(backgroundColor: cPrimary),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // ─── LOGIN (OTP) ─────────────────────────────────────
  Widget _buildLogin() {
    return _topChrome(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _loginStage == 'mobile' ? 'Login with Mobile' : 'Enter OTP',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cFg),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _loginStage == 'mobile'
                        ? "We'll send a one-time code to verify your number."
                        : 'Sent to $_loginMobile. Enter the 6-digit code.',
                    style: const TextStyle(fontSize: 12, color: cMuted),
                  ),
                  const SizedBox(height: 16),
                  if (_loginStage == 'mobile')
                    TextFormField(
                      controller: _mobileCtrl,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      decoration: _inputDecoration('Mobile number').copyWith(
                        counterText: '',
                        helperText: 'Indian mobile: 10 digits starting with 6–9',
                      ),
                    )
                  else ...[
                    TextFormField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofocus: true,
                      decoration: _inputDecoration('6-digit OTP').copyWith(counterText: ''),
                    ),
                    if (_devOtp != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.blue100, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.developer_mode_rounded, size: 14, color: AppColors.blue700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Dev OTP: $_devOtp (SMS gateway not configured)',
                                  style: const TextStyle(fontSize: 11, color: AppColors.blue700)),
                            ),
                            TextButton(
                              onPressed: () {
                                _otpCtrl.text = _devOtp!;
                              },
                              child: const Text('Fill', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => setState(() {
                          if (_loginStage == 'otp') {
                            _loginStage = 'mobile';
                            _otpCtrl.clear();
                            _devOtp = null;
                          } else {
                            _view = _PortalView.home;
                          }
                        }),
                        child: const Text('Back', style: TextStyle(fontSize: 12, color: cMuted)),
                      ),
                      const Spacer(),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: cPrimary),
                        onPressed: _busy ? null : (_loginStage == 'mobile' ? _requestOtp : _verifyOtp),
                        child: _busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(_loginStage == 'mobile' ? 'Send OTP' : 'Verify & Login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestOtp() async {
    final mobile = _mobileCtrl.text.trim();
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(mobile)) {
      _showError('Enter a valid 10-digit Indian mobile number');
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await _api.portalRequestOtp(mobile);
      if (!mounted) return;
      setState(() {
        _loginMobile = mobile;
        _loginStage = 'otp';
        _devOtp = res['dev_otp']?.toString();
        _busy = false;
      });
    } catch (e) {
      _showError(e);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpCtrl.text.trim();
    if (code.length != 6) {
      _showError('Enter the 6-digit OTP');
      return;
    }
    setState(() => _busy = true);
    try {
      await _api.portalVerifyOtp(_loginMobile, code);
      if (!mounted) return;
      setState(() {
        _view = _PortalView.account;
        _busy = false;
      });
      await _loadAccount();
    } catch (e) {
      _showError(e);
      if (mounted) setState(() => _busy = false);
    }
  }

  // ─── B. LOGGED-IN ACCOUNT ────────────────────────────
  Widget _statusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: statusBg(status), borderRadius: BorderRadius.circular(100)),
      child: Text(status,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor(status))),
    );
  }

  Widget _buildAccount() {
    final todayStr = _fmt(DateTime.now());
    final upcoming = _myAppointments.where((a) {
      final date = a['appt_date']?.toString() ?? '';
      final status = a['status']?.toString() ?? '';
      return date.compareTo(todayStr) >= 0 &&
          status != AppointmentStatus.cancelled &&
          status != AppointmentStatus.completed;
    }).toList();
    final past = _myAppointments.where((a) => !upcoming.contains(a)).toList();

    return Scaffold(
      backgroundColor: cBg,
      appBar: AppBar(
        backgroundColor: cCard,
        surfaceTintColor: cCard,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: cPrimary, borderRadius: BorderRadius.circular(7)),
              child: const Icon(Icons.monitor_heart_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            Text('Hello, ${_api.fullName ?? 'Patient'}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadAccount,
            icon: const Icon(Icons.refresh_rounded, size: 20, color: cMuted),
          ),
          TextButton.icon(
            onPressed: () async {
              await _api.clearSession();
              if (!mounted) return;
              setState(() {
                _view = _PortalView.home;
                _loginStage = 'mobile';
                _otpCtrl.clear();
                _devOtp = null;
              });
            },
            icon: const Icon(Icons.logout_rounded, size: 15, color: cMuted),
            label: const Text('Logout', style: TextStyle(fontSize: 12, color: cMuted)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: cCard,
              child: const TabBar(
                labelColor: cPrimary,
                unselectedLabelColor: cMuted,
                indicatorColor: cPrimary,
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'My Appointments'),
                  Tab(text: 'My Invoices'),
                ],
              ),
            ),
            Expanded(
              child: _busy
                  ? const Center(child: CircularProgressIndicator(color: cPrimary))
                  : TabBarView(
                      children: [
                        RefreshIndicator(
                          onRefresh: _loadAccount,
                          child: _appointmentsTab(upcoming, past),
                        ),
                        RefreshIndicator(
                          onRefresh: _loadAccount,
                          child: _invoicesTab(),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String message) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(icon, size: 44, color: AppColors.slate400),
        const SizedBox(height: 12),
        Center(child: Text(message, style: const TextStyle(fontSize: 12, color: cMuted))),
      ],
    );
  }

  Widget _appointmentsTab(List<dynamic> upcoming, List<dynamic> past) {
    if (_myAppointments.isEmpty) {
      return _emptyState(Icons.event_busy_outlined, 'No appointments yet.');
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text('Upcoming', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
        const SizedBox(height: 10),
        if (upcoming.isEmpty)
          Text('No upcoming appointments.', style: TextStyle(fontSize: 12, color: cMuted))
        else
          ...upcoming.map((a) => _appointmentCard(a, canManage: true)),
        const SizedBox(height: 20),
        const Text('Past Visits', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
        const SizedBox(height: 10),
        if (past.isEmpty)
          Text('No past visits yet.', style: TextStyle(fontSize: 12, color: cMuted))
        else
          ...past.map((a) => _appointmentCard(a, canManage: false)),
      ],
    );
  }

  Widget _appointmentCard(Map<String, dynamic> a, {required bool canManage}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: AppColors.violet100, borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(a['token_number']?.toString() ?? '—',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.violet700)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['clinic_name']?.toString() ?? 'Clinic visit',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
                const SizedBox(height: 3),
                Text('${a['appt_date'] ?? ''} · ${a['appt_time'] ?? ''}',
                    style: const TextStyle(fontSize: 11, color: cMuted)),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _statusChip(a['status']?.toString() ?? AppointmentStatus.scheduled),
                    if (a['visit_type'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: cMutedBg, borderRadius: BorderRadius.circular(100)),
                        child: Text(a['visit_type'].toString(),
                            style: const TextStyle(fontSize: 10, color: cMuted)),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (canManage) ...[
            IconButton(
              tooltip: 'Reschedule',
              onPressed: () => _rescheduleDialog(a),
              icon: const Icon(Icons.edit_calendar_outlined, size: 19, color: AppColors.blue700),
            ),
            IconButton(
              tooltip: 'Cancel',
              onPressed: () => _cancelDialog(a),
              icon: const Icon(Icons.cancel_outlined, size: 19, color: AppColors.red600),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _rescheduleDialog(Map<String, dynamic> appt) async {
    DateTime? newDate;
    String? newTime;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Reschedule Appointment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pick a new date:', style: TextStyle(fontSize: 12, color: cMuted)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 68,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 14,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, i) {
                      final d = DateTime.now().add(Duration(days: i));
                      final sel = newDate != null && _fmt(newDate!) == _fmt(d);
                      return InkWell(
                        onTap: () => setDialogState(() {
                          newDate = d;
                          newTime = null;
                        }),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 50,
                          decoration: BoxDecoration(
                            color: sel ? cPrimary : cBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: sel ? cPrimary : AppColors.slate200),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('${d.day}/${d.month}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: sel ? Colors.white : cFg)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Pick a new time:', style: TextStyle(fontSize: 12, color: cMuted)),
                const SizedBox(height: 8),
                if (newDate == null || _selectedClinic == null)
                  Text('Select a date first.', style: TextStyle(fontSize: 11, color: cMuted))
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _slotsFor(_selectedClinic!)
                        .map((s) => ChoiceChip(
                              label: Text(s, style: const TextStyle(fontSize: 10)),
                              selected: newTime == s,
                              selectedColor: cPrimary,
                              labelStyle: TextStyle(color: newTime == s ? Colors.white : cFg),
                              visualDensity: VisualDensity.compact,
                              onSelected: (_) => setDialogState(() => newTime = s),
                            ))
                        .toList(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: cPrimary),
              onPressed: (newDate != null && newTime != null) ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || newDate == null || newTime == null) return;
    setState(() => _busy = true);
    try {
      await _api.portalReschedule(appt['appointment_id']?.toString() ?? appt['id'].toString(), _fmt(newDate!), newTime!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Appointment rescheduled.'),
        backgroundColor: AppColors.green600,
      ));
      await _loadAccount();
    } catch (e) {
      _showError(e);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelDialog(Map<String, dynamic> appt) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Token ${appt['token_number'] ?? ''} on ${appt['appt_date'] ?? ''} will be cancelled.',
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep it')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red600),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Appointment'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final id = appt['appointment_id']?.toString() ?? appt['id'].toString();
      await _api.portalCancel(id, reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Appointment cancelled.'),
        backgroundColor: AppColors.green600,
      ));
      await _loadAccount();
    } catch (e) {
      _showError(e);
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _invoicesTab() {
    if (_myInvoices.isEmpty) {
      return _emptyState(Icons.receipt_long_outlined, 'No invoices found.');
    }
    return ListView(
      padding: const EdgeInsets.all(24),
      children: _myInvoices.map<Widget>((inv) {
        final total = _asNum(inv['total_amount'] ?? inv['total']);
        final paid = _asNum(inv['paid_amount'] ?? inv['paid']);
        final due = _asNum(inv['due_amount'] ?? inv['due'] ?? (total - paid));
        final status = inv['status']?.toString() ?? InvoiceStatus.draft;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: cMutedBg, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.receipt_long_outlined, size: 20, color: cMuted),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inv['invoice_number']?.toString() ?? inv['invoice_id']?.toString() ?? 'Invoice',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cFg)),
                    const SizedBox(height: 3),
                    Text(inv['invoice_date']?.toString() ?? inv['created_at']?.toString() ?? '',
                        style: const TextStyle(fontSize: 11, color: cMuted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${total.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cFg)),
                  const SizedBox(height: 3),
                  Text('Paid ₹${paid.toStringAsFixed(0)} · Due ₹${due.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 10, color: due > 0 ? AppColors.red600 : AppColors.green600)),
                  const SizedBox(height: 5),
                  _statusChip(status),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cBorder),
      ),
      child: child,
    );
  }

  String _monthAbbr(int m) =>
      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][m - 1];
}
