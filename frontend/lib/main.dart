import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'services/api_service.dart';
import 'screens/role_selection_screen.dart';
import 'screens/receptionist/receptionist_dashboard.dart';
import 'screens/doctor/doctor_dashboard.dart';
import 'screens/doctor/prescription_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/portal/patient_portal.dart';

void main() {
  runApp(const HcmsApp());
}

class HcmsApp extends StatelessWidget {
  const HcmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Verma Homeopathy Clinic OS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: Color(0xFF0D9488),
          surface: Colors.white,
          surfaceContainerHighest: AppColors.bg,
        ),
        scaffoldBackgroundColor: AppColors.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textDark),
          titleTextStyle: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final args = settings.arguments;
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const RoleSelectionScreen());
          case '/receptionist':
            return _guarded(context, settings, UserRoles.receptionist,
                (_) => const ReceptionistDashboard());
          case '/doctor':
            return _guarded(context, settings, UserRoles.doctor,
                (_) => const DoctorDashboard());
          case '/admin':
            return _guarded(context, settings, UserRoles.superAdmin,
                (_) => const AdminDashboard());
          case '/prescription':
            // PrescriptionScreen requires the appointment payload (PRD §5.8.3).
            if (args is Map<String, dynamic>) {
              return MaterialPageRoute(builder: (_) => buildPrescriptionScreen(args));
            }
            return _errorRoute('No appointment selected.');
          case '/portal':
            return MaterialPageRoute(builder: (_) => const PatientPortalHome());
          default:
            return _errorRoute('Route not found: ${settings.name}');
        }
      },
    );
  }

  /// Route guard: staff portals require an authenticated session with the
  /// matching role (NFR-6). Patients are redirected to login instead.
  Route<dynamic> _guarded(
      BuildContext context, RouteSettings settings, String requiredRole,
      WidgetBuilder builder) {
    final api = ApiService();
    final allowed = {
      requiredRole,
      if (requiredRole != UserRoles.superAdmin) UserRoles.superAdmin,
    };
    if (api.isLoggedIn && (allowed.contains(api.role))) {
      return MaterialPageRoute(builder: builder);
    }
    return MaterialPageRoute(
      builder: (_) => RoleSelectionScreen(returnTo: settings.name, requiredRole: requiredRole),
    );
  }

  Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(message)),
      ),
    );
  }
}
