import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String? returnTo;
  final String? requiredRole;
  const RoleSelectionScreen({super.key, this.returnTo, this.requiredRole});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final ApiService _api = ApiService();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  String? _roleRouteFor(String? role) {
    switch (role) {
      case 'Receptionist':
        return '/receptionist';
      case 'Doctor':
        return '/doctor';
      case 'SuperAdmin':
        return '/admin';
      default:
        return null;
    }
  }

  void _showLoginDialog(String role) {
    bool dialogLoading = false;
    String? dialogError;

    showDialog(
      context: context,
      barrierDismissible: !dialogLoading,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        Future<void> doLogin() async {
          if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
            setS(() => dialogError = 'Please enter email and password.');
            return;
          }
          setS(() {
            dialogLoading = true;
            dialogError = null;
          });
          try {
            final success = await _api.login(_emailCtrl.text.trim(), _passCtrl.text);
            if (!success) {
              setS(() {
                dialogError = 'Invalid email or password.';
                dialogLoading = false;
              });
              return;
            }
            final userRole = _api.role ?? '';
            // Enforce the portal the user chose (NFR-6): no cross-role entry.
            if (widget.requiredRole != null &&
                widget.requiredRole != userRole &&
                userRole != 'SuperAdmin') {
              setS(() {
                dialogError =
                    'This account does not have access to the ${widget.requiredRole} portal.';
                dialogLoading = false;
              });
              await _api.clearSession();
              return;
            }
            if (!mounted) return;
            Navigator.pop(ctx);
            final target =
                widget.returnTo ?? _roleRouteFor(userRole) ?? '/';
            Navigator.pushReplacementNamed(context, target);
          } catch (e) {
            setS(() {
              dialogError = e.toString().replaceAll('Exception: ', '');
              dialogLoading = false;
            });
          }
        }

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 380,
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: role == 'doctor' ? const Color(0xFF0F766E) : const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          role == 'doctor' ? 'Doctor / Admin Login' : 'Receptionist Login',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        const Text('Enter your credentials to continue',
                            style: TextStyle(fontSize: 11, color: Color(0xFF717182))),
                      ]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF717182)),
                      onPressed: dialogLoading ? null : () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Email',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailCtrl,
                  enabled: !dialogLoading,
                  autofocus: true,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Enter email address',
                    hintStyle: const TextStyle(color: Color(0xFF717182), fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0x1A000000))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0x1A000000))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: role == 'doctor' ? const Color(0xFF0F766E) : const Color(0xFF3B82F6), width: 1.5)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Password',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF0F172A))),
                const SizedBox(height: 6),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  enabled: !dialogLoading,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                  onSubmitted: (_) => doLogin(),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: const TextStyle(color: Color(0xFF717182), fontSize: 13),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0x1A000000))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0x1A000000))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: role == 'doctor' ? const Color(0xFF0F766E) : const Color(0xFF3B82F6), width: 1.5)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFFFECACA))),
                    child: Text(dialogError!, style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: dialogLoading
                      ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                      : ElevatedButton(
                          onPressed: doLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: role == 'doctor' ? const Color(0xFF0F766E) : const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                          child: const Text('Sign In', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  void initState() {
    super.initState();
    _maybeResumeSession();
  }

  Future<void> _maybeResumeSession() async {
    if (widget.returnTo != null) return; // came here because guard rejected
    final ok = await _api.restoreSession();
    if (!ok || !mounted) return;
    final route = _roleRouteFor(_api.role);
    if (route != null && route != '/') {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC),
              Color(0xFFD4FFF5),
              Color(0xFFEFF6FF),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: const Color(0xFF0F766E).withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 20),
                    const Text('Verma Homeopathy Clinic', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                    const SizedBox(height: 6),
                    const Text('Clinic OS · Indore · Healthcare Management System', style: TextStyle(fontSize: 13, color: Color(0xFF717182))),
                  ],
                ),
                const SizedBox(height: 48),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final cards = <Widget>[
                        _buildRoleCard(
                          role: 'doctor',
                          title: 'Doctor / Admin',
                          description: 'Full clinical access — consultations, prescriptions, analytics, billing management, and system administration.',
                          tags: ['Consultations', 'Prescriptions', 'Analytics', 'Admin'],
                          cta: 'Open Doctor Portal',
                          accentColor: const Color(0xFF0F766E),
                          accentBg: const Color(0xFFE6FFF8),
                          icon: Icons.medical_information_outlined,
                        ),
                        _buildRoleCard(
                          role: 'receptionist',
                          title: 'Receptionist',
                          description: 'Front-desk operations — patient registration, appointments, queue management, billing, and reports.',
                          tags: ['Queue', 'Appointments', 'Billing', 'Reports'],
                          cta: 'Open Receptionist Portal',
                          accentColor: const Color(0xFF3B82F6),
                          accentBg: const Color(0xFFEFF6FF),
                          icon: Icons.person_outline_rounded,
                        ),
                      ];
                      final portalCard = InkWell(
                        onTap: () => Navigator.pushNamed(context, '/portal'),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0x1A000000)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F3FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.smartphone_outlined, color: Color(0xFF7C3AED), size: 24),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Patient Portal',
                                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                    SizedBox(height: 4),
                                    Text('Book appointments online · view invoices · reschedule or cancel visits',
                                        style: TextStyle(fontSize: 12, color: Color(0xFF717182))),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF7C3AED)),
                            ],
                          ),
                        ),
                      );

                      if (constraints.maxWidth > 720) {
                        return Column(children: [
                          Row(children: [
                            Expanded(child: cards[0]),
                            const SizedBox(width: 24),
                            Expanded(child: cards[1]),
                          ]),
                          const SizedBox(height: 24),
                          ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: portalCard),
                        ]);
                      }
                      return Column(children: [...cards, const SizedBox(height: 24), portalCard]);
                    }),
                  ),
                ),
                const SizedBox(height: 48),
                const Text('HCMS v2.0 · Verma Homeopathy · Indore', style: TextStyle(fontSize: 11, color: Color(0xFF717182))),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String description,
    required List<String> tags,
    required String cta,
    required Color accentColor,
    required Color accentBg,
    required IconData icon,
  }) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setS) {
        return MouseRegion(
          onEnter: (_) => setS(() => isHovered = true),
          onExit: (_) => setS(() => isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _showLoginDialog(role),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isHovered ? accentColor.withOpacity(0.4) : const Color(0x1A000000)),
                boxShadow: isHovered
                    ? [BoxShadow(color: accentColor.withOpacity(0.1), blurRadius: 28, spreadRadius: 2, offset: const Offset(0, 8))]
                    : [const BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isHovered ? accentColor : accentBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: isHovered ? Colors.white : accentColor, size: 28),
                  ),
                  const SizedBox(height: 20),
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  Text(description, style: const TextStyle(fontSize: 13, color: Color(0xFF717182), height: 1.5)),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentBg,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accentColor)),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Flexible(
                        child: Text(cta,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: accentColor),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1),
                      ),
                      const SizedBox(width: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        transform: isHovered ? (Matrix4.identity()..translateByDouble(4.0, 0, 0, 1)) : Matrix4.identity(),
                        child: Icon(Icons.arrow_forward_rounded, size: 16, color: accentColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}
