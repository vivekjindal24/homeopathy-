import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Error surfaced by every ApiService call. `message` is user-displayable.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  bool get isAuthError => statusCode == 401;

  @override
  String toString() => message;
}

/// Base URL resolution:
/// 1. compile-time --dart-define=API_BASE_URL=... (recommended for deploys)
/// 2. persisted override (Settings screen)
/// 3. localhost default for dev
const String kDefaultBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000/api/v1',
);

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String _baseUrl = kDefaultBaseUrl;
  String? _token;
  String? _refreshToken;
  String? _role;
  String? _userId;
  String? _fullName;
  bool _loadedPrefs = false;
  final _http = http.Client();
  Completer<bool>? _refreshing;

  Future<void> _ensurePrefsLoaded() async {
    if (_loadedPrefs) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _baseUrl = prefs.getString('hcms_base_url') ?? _baseUrl;
      _token = prefs.getString('hcms_token');
      _refreshToken = prefs.getString('hcms_refresh');
      _role = prefs.getString('hcms_role');
      _userId = prefs.getString('hcms_user_id');
      _fullName = prefs.getString('hcms_full_name');
    } catch (_) {}
    _loadedPrefs = true;
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hcms_base_url', _baseUrl);
  }

  String get baseUrl => _baseUrl;
  String? get token => _token;
  String? get role => _role;
  String? get userId => _userId;
  String? get fullName => _fullName;
  bool get isLoggedIn => _token != null;

  Map<String, String> _headers() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    return headers;
  }

  Future<Map<String, dynamic>?> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool authRequired = true,
  }) async {
    await _ensurePrefsLoaded();
    var res = await _dispatch(method, path, query: query, body: body);
    if (res.statusCode == 401 && _refreshToken != null) {
      final ok = await _tryRefresh();
      if (ok) {
        res = await _dispatch(method, path, query: query, body: body);
      } else {
        throw ApiException('Session expired. Please log in again.', statusCode: 401);
      }
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return {};
      return jsonDecode(res.body) as dynamic;
    }
    String detail;
    try {
      final decoded = jsonDecode(res.body);
      detail = decoded is Map ? (decoded['detail']?.toString() ?? res.body) : res.body;
    } catch (_) {
      detail = res.body.isEmpty ? 'Request failed (${res.statusCode})' : res.body;
    }
    throw ApiException(detail, statusCode: res.statusCode);
  }

  Future<http.Response> _dispatch(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
  }) {
    var uri = Uri.parse('$_baseUrl$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: {...uri.queryParameters, ...query});
    }
    final headers = _headers();
    switch (method) {
      case 'POST':
        return _http.post(uri, headers: headers, body: body == null ? null : jsonEncode(body));
      case 'PUT':
        return _http.put(uri, headers: headers, body: body == null ? null : jsonEncode(body));
      case 'PATCH':
        return _http.patch(uri, headers: headers, body: body == null ? null : jsonEncode(body));
      case 'DELETE':
        return _http.delete(uri, headers: headers);
      default:
        return _http.get(uri, headers: headers);
    }
  }

  Future<List<dynamic>> _sendList(String method, String path,
      {Map<String, String>? query}) async {
    final result = await _send(method, path, query: query);
    return (result as List?) ?? <dynamic>[];
  }

  /// Like [_send] but for endpoints guaranteed to return a JSON object.
  Future<Map<String, dynamic>> _sendMap(
    String method,
    String path, {
    Map<String, String>? query,
    Object? body,
    bool authRequired = true,
  }) async =>
      (await _send(method, path, query: query, body: body, authRequired: authRequired)) ??
      <String, dynamic>{};

  // --- Token refresh (single-flight) ---
  Future<bool> _tryRefresh() async {
    if (_refreshing != null) return _refreshing!.future;
    final completer = Completer<bool>();
    _refreshing = completer;
    try {
      final res = await _http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': _refreshToken}),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _token = data['access_token'];
        _refreshToken = data['refresh_token'];
        _role = data['role'];
        _userId = data['user_id'];
        _fullName = data['full_name'];
        await _persistSession();
        completer.complete(true);
      } else {
        await clearSession();
        completer.complete(false);
      }
    } catch (_) {
      completer.complete(false);
    } finally {
      _refreshing = null;
    }
    return completer.future;
  }

  Future<void> _persistSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null) await prefs.setString('hcms_token', _token!);
      if (_refreshToken != null) await prefs.setString('hcms_refresh', _refreshToken!);
      if (_role != null) await prefs.setString('hcms_role', _role!);
      if (_userId != null) await prefs.setString('hcms_user_id', _userId!);
      if (_fullName != null) await prefs.setString('hcms_full_name', _fullName!);
    } catch (_) {}
  }

  Future<void> clearSession() async {
    _token = null;
    _refreshToken = null;
    _role = null;
    _userId = null;
    _fullName = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('hcms_token');
      await prefs.remove('hcms_refresh');
      await prefs.remove('hcms_role');
      await prefs.remove('hcms_user_id');
      await prefs.remove('hcms_full_name');
    } catch (_) {}
  }

  /// Restore a persisted session on app start.
  Future<bool> restoreSession() async {
    await _ensurePrefsLoaded();
    if (_token == null) return false;
    if (_refreshToken != null) {
      final ok = await _tryRefresh(); // access tokens live 15 min; always rotate on restore
      return ok;
    }
    return true;
  }

  void logoutRemote() {
    final rt = _refreshToken;
    if (rt != null) {
      _http.post(Uri.parse('$_baseUrl/auth/logout'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'refresh_token': rt}));
    }
    clearSession();
  }

  // --- Auth ---
  Future<bool> login(String email, String password) async {
    await _ensurePrefsLoaded();
    try {
      final data = await _send('POST', '/auth/login',
          body: {'email': email, 'password': password}, authRequired: false);
      _token = data!['access_token'];
      _refreshToken = data['refresh_token'];
      _role = data['role'];
      _userId = data['user_id'];
      _fullName = data['full_name'];
      await _persistSession();
      return true;
    } on ApiException catch (e) {
      if (e.isAuthError) return false; // wrong credentials
      rethrow; // network/server problems must surface
    }
  }

  // --- Clinics ---
  Future<List<dynamic>> getClinics() => _sendList('GET', '/clinics');

  // --- Patients ---
  Future<List<dynamic>> getPatients({String? search}) =>
      _sendList('GET', '/patients', query: search != null && search.isNotEmpty ? {'search': search} : null);

  Future<Map<String, dynamic>?> createPatient(Map<String, dynamic> patientData) =>
      _send('POST', '/patients', body: patientData);

  Future<Map<String, dynamic>> getPatient(String patientId) =>
      _sendMap('GET', '/patients/$patientId');

  Future<List<dynamic>> getPatientPrescriptions(String patientId) =>
      _sendList('GET', '/patients/$patientId/prescriptions');

  Future<bool> check7dayWaiver(String patientId, String dateStr) async {
    try {
      final data = await _send('GET', '/patients/$patientId/7day-waiver',
          query: {'appt_date': dateStr});
      return data?['eligible'] ?? false;
    } on ApiException {
      return false;
    }
  }

  // --- Appointments ---
  Future<List<dynamic>> getAppointments({String? clinicId, String? date}) {
    final params = <String, String>{};
    if (clinicId != null) params['clinic_id'] = clinicId;
    if (date != null) params['appt_date'] = date;
    return _sendList('GET', '/appointments', query: params);
  }

  Future<Map<String, dynamic>?> createAppointment(Map<String, dynamic> apptData) =>
      _send('POST', '/appointments', body: apptData);

  Future<Map<String, dynamic>> updateAppointmentStatus(String apptId, String status,
      {String? reason}) =>
      _sendMap('PUT', '/appointments/$apptId/status', body: {
        'status': status,
        if (reason != null) 'reason': reason,
      });

  Future<Map<String, dynamic>> rescheduleAppointment(String apptId, String date, String time) =>
      _sendMap('PUT', '/appointments/$apptId/reschedule',
          body: {'appt_date': date, 'appt_time': time});

  // --- Prescriptions ---
  Future<Map<String, dynamic>> createPrescription(Map<String, dynamic> rxData) =>
      _sendMap('POST', '/prescriptions', body: rxData);

  // --- Invoices & Payments ---
  Future<Map<String, dynamic>> createInvoice(Map<String, dynamic> invoiceData) =>
      _sendMap('POST', '/invoices', body: invoiceData);

  Future<List<dynamic>> getInvoices({String? patientId}) => _sendList('GET', '/invoices',
      query: patientId != null ? {'patient_id': patientId} : null);

  Future<Map<String, dynamic>> getInvoice(String invoiceId) => _sendMap('GET', '/invoices/$invoiceId');

  Future<Map<String, dynamic>> issueInvoice(String invoiceId) =>
      _sendMap('PUT', '/invoices/$invoiceId/issue');

  Future<Map<String, dynamic>> recordPayment(String invoiceId, double amount, String mode,
      {String? txId}) =>
      _sendMap('POST', '/invoices/$invoiceId/payments', body: {
        'amount': amount,
        'payment_mode': mode,
        if (txId != null) 'transaction_id': txId,
      });

  // --- Dashboard KPIs ---
  Future<Map<String, dynamic>> getKpis(String clinicId, String dateStr) =>
      _sendMap('GET', '/dashboard/kpis', query: {'clinic_id': clinicId, 'date_str': dateStr});

  // --- Audit Logs ---
  Future<List<dynamic>> getAuditLogs({String? entityType, String? action}) {
    final q = <String, String>{};
    if (entityType != null) q['entity_type'] = entityType;
    if (action != null) q['action'] = action;
    return _sendList('GET', '/audit-logs', query: q);
  }

  // --- Notifications ---
  Future<List<dynamic>> getNotifications() => _sendList('GET', '/notifications');

  // --- Admin: users & reports ---
  Future<List<dynamic>> adminListUsers() => _sendList('GET', '/admin/users');

  Future<Map<String, dynamic>> adminUpdateUser(String userId, Map<String, dynamic> patch) =>
      _sendMap('PATCH', '/admin/users/$userId', body: patch);

  Future<void> adminResetPassword(String userId, String newPassword) =>
      _send('POST', '/admin/users/$userId/reset-password', body: {'new_password': newPassword});

  Future<void> adminDeleteUser(String userId) => _send('DELETE', '/admin/users/$userId');

  Future<List<dynamic>> adminRevenueReport(String fromDate, String toDate, {String? clinicId}) {
    final q = {'from_date': fromDate, 'to_date': toDate, if (clinicId != null) 'clinic_id': clinicId};
    return _sendList('GET', '/admin/reports/revenue', query: q);
  }

  Future<Map<String, dynamic>> adminAppointmentReport(String fromDate, String toDate, {String? clinicId}) {
    final q = {'from_date': fromDate, 'to_date': toDate, if (clinicId != null) 'clinic_id': clinicId};
    return _sendMap('GET', '/admin/reports/appointments', query: q);
  }

  Future<List<dynamic>> adminRegistrationsReport({int months = 6}) =>
      _sendList('GET', '/admin/reports/registrations', query: {'months': '$months'});

  // --- Patient Portal ---
  Future<List<dynamic>> portalClinics() => _sendList('GET', '/portal/clinics');

  Future<Map<String, dynamic>> portalBook(Map<String, dynamic> booking) =>
      _sendMap('POST', '/portal/book', body: booking, authRequired: false);

  Future<Map<String, dynamic>> portalRequestOtp(String mobile) =>
      _sendMap('POST', '/portal/otp/request', body: {'mobile': mobile}, authRequired: false);

  Future<Map<String, dynamic>> portalVerifyOtp(String mobile, String code) async {
    final data = await _sendMap('POST', '/portal/otp/verify',
        body: {'mobile': mobile, 'code': code}, authRequired: false);
    _token = data['access_token'];
    _refreshToken = data['refresh_token'];
    _role = 'Patient';
    _userId = data['patient_id'];
    _fullName = data['full_name'];
    await _persistSession();
    return data;
  }

  Future<List<dynamic>> portalMyAppointments() => _sendList('GET', '/portal/me/appointments');

  Future<Map<String, dynamic>> portalCancel(String apptId, {String? reason}) =>
      _sendMap('PUT', '/portal/appointments/$apptId/cancel', body: {'reason': reason});

  Future<Map<String, dynamic>> portalReschedule(String apptId, String date, String time) =>
      _sendMap('PUT', '/portal/appointments/$apptId/reschedule',
          body: {'appt_date': date, 'appt_time': time});

  Future<List<dynamic>> portalMyInvoices() => _sendList('GET', '/portal/me/invoices');

  // --- Inventory ---
  Future<List<dynamic>> getInventory({String? clinicId, String? search, bool? lowStock, bool? nearExpiry}) {
    final q = <String, String>{};
    if (clinicId != null) q['clinic_id'] = clinicId;
    if (search != null && search.isNotEmpty) q['search'] = search;
    if (lowStock == true) q['low_stock'] = 'true';
    if (nearExpiry == true) q['near_expiry'] = 'true';
    return _sendList('GET', '/inventory', query: q);
  }

  Future<Map<String, dynamic>> createMedicine(Map<String, dynamic> data) =>
      _sendMap('POST', '/inventory', body: data);

  Future<Map<String, dynamic>> updateMedicine(String id, Map<String, dynamic> data) =>
      _sendMap('PUT', '/inventory/$id', body: data);

  Future<Map<String, dynamic>> stockInward(String id, int quantity) =>
      _sendMap('POST', '/inventory/$id/stock-inward', body: {'quantity': quantity});

  Future<Map<String, dynamic>> getInventoryStats(String clinicId) =>
      _sendMap('GET', '/inventory/stats', query: {'clinic_id': clinicId});
}
