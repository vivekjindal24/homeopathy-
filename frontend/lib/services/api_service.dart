import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Change this to your production Render backend URL when deployed
  String _baseUrl = "http://localhost:8000/api/v1";
  
  String? _token;
  String? _role;
  String? _userId;
  String? _fullName;

  void setBaseUrl(String url) {
    _baseUrl = url;
  }

  String get baseUrl => _baseUrl;
  String? get token => _token;
  String? get role => _role;
  String? get userId => _userId;
  String? get fullName => _fullName;

  Map<String, String> _headers() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // --- Auth ---
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['access_token'];
        _role = data['role'];
        _userId = data['user_id'];
        _fullName = data['full_name'];
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void logout() {
    _token = null;
    _role = null;
    _userId = null;
    _fullName = null;
  }

  // --- Clinics ---
  Future<List<dynamic>> getClinics() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/clinics'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  // --- Patients ---
  Future<List<dynamic>> getPatients({String? search}) async {
    try {
      final uri = Uri.parse('$_baseUrl/patients').replace(
        queryParameters: search != null ? {'search': search} : {},
      );
      final response = await http.get(uri, headers: _headers());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> createPatient(Map<String, dynamic> patientData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/patients'),
        headers: _headers(),
        body: jsonEncode(patientData),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> check7dayWaiver(String patientId, String dateStr) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/patients/$patientId/7day-waiver?appt_date=$dateStr'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['eligible'] ?? false;
      }
    } catch (_) {}
    return false;
  }

  // --- Appointments ---
  Future<List<dynamic>> getAppointments({String? clinicId, String? date}) async {
    try {
      final params = <String, String>{};
      if (clinicId != null) params['clinic_id'] = clinicId;
      if (date != null) params['appt_date'] = date;
      
      final uri = Uri.parse('$_baseUrl/appointments').replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> createAppointment(Map<String, dynamic> apptData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/appointments'),
        headers: _headers(),
        body: jsonEncode(apptData),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> updateAppointmentStatus(String apptId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/appointments/$apptId/status'),
        headers: _headers(),
        body: jsonEncode({'status': status}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Return error details to surface validation blocks (like single consultation block)
        final body = jsonDecode(response.body);
        throw Exception(body['detail'] ?? 'Failed to update status');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> rescheduleAppointment(String apptId, String date, String time) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/appointments/$apptId/reschedule'),
        headers: _headers(),
        body: jsonEncode({'appt_date': date, 'appt_time': time}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  // --- Prescriptions ---
  Future<Map<String, dynamic>?> createPrescription(Map<String, dynamic> rxData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/prescriptions'),
        headers: _headers(),
        body: jsonEncode(rxData),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  Future<List<dynamic>> getPatientPrescriptions(String patientId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/patients/$patientId/prescriptions'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  // --- Invoices & Payments ---
  Future<Map<String, dynamic>?> createInvoice(Map<String, dynamic> invoiceData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/invoices'),
        headers: _headers(),
        body: jsonEncode(invoiceData),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  Future<List<dynamic>> getInvoices({String? patientId}) async {
    try {
      final params = <String, String>{};
      if (patientId != null) params['patient_id'] = patientId;
      final uri = Uri.parse('$_baseUrl/invoices').replace(queryParameters: params);
      
      final response = await http.get(uri, headers: _headers());
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> issueInvoice(String invoiceId) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/invoices/$invoiceId/issue'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> recordPayment(String invoiceId, double amount, String mode, {String? txId}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/invoices/$invoiceId/payments'),
        headers: _headers(),
        body: jsonEncode({
          'amount': amount,
          'payment_mode': mode,
          'transaction_id': txId,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  // --- Dashboard KPIs ---
  Future<Map<String, dynamic>?> getKpis(String clinicId, String dateStr) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/dashboard/kpis?clinic_id=$clinicId&date_str=$dateStr'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return null;
  }

  // --- Audit Logs ---
  Future<List<dynamic>> getAuditLogs() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/audit-logs'),
        headers: _headers(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (_) {}
    return [];
  }
}
