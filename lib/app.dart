import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AccountRole { patient, doctor, hospital }

class MedifixApp extends StatefulWidget {
  const MedifixApp({super.key, required this.controller});

  final HealthAppController controller;

  @override
  State<MedifixApp> createState() => _MedifixAppState();
}

class _MedifixAppState extends State<MedifixApp> {
  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: widget.controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Medifix',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F766E),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: const Color(0xFFF4F8F7),
          useMaterial3: true,
          textTheme: const TextTheme(
            displaySmall: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
            headlineMedium: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
            titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
            titleMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
            bodyLarge: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Color(0xFF334155),
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF475569),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        home: const AppRouter(),
      ),
    );
  }
}

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppStateScope.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.currentAccount == null) {
          return const AuthScreen();
        }
        if (controller.currentAccount!.role == AccountRole.doctor) {
          return const DoctorHomeShell();
        }
        if (controller.currentAccount!.role == AccountRole.hospital) {
          return const HospitalHomeShell();
        }
        return const HomeShell();
      },
    );
  }
}

class AppStateScope extends InheritedNotifier<HealthAppController> {
  const AppStateScope({
    super.key,
    required HealthAppController notifier,
    required super.child,
  }) : super(notifier: notifier);

  static HealthAppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    assert(scope != null, 'AppStateScope not found in widget tree.');
    return scope!.notifier!;
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _registering = false;
  bool _submitting = false;
  AccountRole _loginRole = AccountRole.patient;

  final _loginEmailController = TextEditingController(
    text: 'akash123@gmail.com',
  );
  final _loginPasswordController = TextEditingController(text: 'Pass@123');

  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerHospitalController = TextEditingController(
    text: 'Sree Buddha Medical Network',
  );
  final _registerSpecialtyController = TextEditingController(
    text: 'General Medicine',
  );

  @override
  void dispose() {
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerHospitalController.dispose();
    _registerSpecialtyController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final controller = AppStateScope.of(context);
    setState(() => _submitting = true);
    final message = await controller.login(
      _loginEmailController.text.trim(),
      _loginPasswordController.text.trim(),
      role: _loginRole,
    );
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _setLoginRole(AccountRole role) {
    setState(() {
      _loginRole = role;
      _registering = false;
      if (role == AccountRole.patient) {
        _loginEmailController.text = 'akash123@gmail.com';
        _loginPasswordController.text = 'Pass@123';
      } else if (role == AccountRole.doctor) {
        _loginEmailController.text = 'dr.luffy@medibridge.app';
        _loginPasswordController.text = 'Doctor@123';
      } else {
        _loginEmailController.text = 'records@greenvalleyhospital.com';
        _loginPasswordController.text = 'Hospital@123';
      }
    });
  }

  Future<void> _handleRegister() async {
    final controller = AppStateScope.of(context);
    setState(() => _submitting = true);
    final message = await switch (_loginRole) {
      AccountRole.patient => controller.register(
        fullName: _registerNameController.text.trim(),
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text.trim(),
        hospitalNetwork: _registerHospitalController.text.trim(),
      ),
      AccountRole.doctor => controller.registerDoctor(
        fullName: _registerNameController.text.trim(),
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text.trim(),
        hospitalNetwork: _registerHospitalController.text.trim(),
        specialty: _registerSpecialtyController.text.trim(),
      ),
      AccountRole.hospital => controller.registerHospital(
        portalName: _registerNameController.text.trim(),
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text.trim(),
        hospitalNetwork: _registerHospitalController.text.trim(),
      ),
    };
    if (!mounted) {
      return;
    }
    setState(() => _submitting = false);
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(switch (_loginRole) {
          AccountRole.patient => 'Patient account created and secured.',
          AccountRole.doctor => 'Doctor account created successfully.',
          AccountRole.hospital => 'Hospital portal created successfully.',
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final isWide = screenWidth >= 980;
    final isCompact = screenWidth < 720;
    final useCompactHero = isCompact || screenHeight < 860;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF071A26),
                  Color(0xFF0B2F3D),
                  Color(0xFFDCF2EC),
                  Color(0xFFF7FAFC),
                ],
                stops: [0, 0.34, 0.72, 1],
              ),
            ),
          ),
          Positioned(
            top: -140,
            left: -80,
            child: _AmbientGlow(
              size: 320,
              color: const Color(0xFF22C55E).withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            top: 120,
            right: -110,
            child: _AmbientGlow(
              size: 280,
              color: const Color(0xFF38BDF8).withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            bottom: -160,
            left: MediaQuery.sizeOf(context).width * 0.25,
            child: _AmbientGlow(
              size: 360,
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.all(screenHeight < 760 ? 16 : 24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1240),
                        child: isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: _AuthHero(
                                      registering: _registering,
                                      loginRole: _loginRole,
                                      compact: useCompactHero,
                                    ),
                                  ),
                                  const SizedBox(width: 28),
                                  SizedBox(
                                    width: 430,
                                    child: _AuthPanel(
                                      registering: _registering,
                                      submitting: _submitting,
                                      loginRole: _loginRole,
                                      loginEmailController:
                                          _loginEmailController,
                                      loginPasswordController:
                                          _loginPasswordController,
                                      registerNameController:
                                          _registerNameController,
                                      registerEmailController:
                                          _registerEmailController,
                                      registerPasswordController:
                                          _registerPasswordController,
                                      registerHospitalController:
                                          _registerHospitalController,
                                      registerSpecialtyController:
                                          _registerSpecialtyController,
                                      onToggleMode: () {
                                        setState(
                                          () => _registering = !_registering,
                                        );
                                      },
                                      onRoleChanged: _setLoginRole,
                                      onLogin: _handleLogin,
                                      onRegister: _handleRegister,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _AuthPanel(
                                    registering: _registering,
                                    submitting: _submitting,
                                    loginRole: _loginRole,
                                    loginEmailController: _loginEmailController,
                                    loginPasswordController:
                                        _loginPasswordController,
                                    registerNameController:
                                        _registerNameController,
                                    registerEmailController:
                                        _registerEmailController,
                                    registerPasswordController:
                                        _registerPasswordController,
                                    registerHospitalController:
                                        _registerHospitalController,
                                    registerSpecialtyController:
                                        _registerSpecialtyController,
                                    onToggleMode: () {
                                      setState(
                                        () => _registering = !_registering,
                                      );
                                    },
                                    onRoleChanged: _setLoginRole,
                                    onLogin: _handleLogin,
                                    onRegister: _handleRegister,
                                  ),
                                  const SizedBox(height: 24),
                                  _AuthHero(
                                    registering: _registering,
                                    loginRole: _loginRole,
                                    compact: useCompactHero,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthHero extends StatelessWidget {
  const _AuthHero({
    required this.registering,
    required this.loginRole,
    this.compact = false,
  });

  final bool registering;
  final AccountRole loginRole;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(34),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF06131F), Color(0xFF0B3141), Color(0xFF114E58)],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2606172A),
            blurRadius: 40,
            offset: Offset(0, 22),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'MEDIFIX',
                  style: TextStyle(
                    color: Colors.white,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const StatusPill(
                label: 'Secure Interoperability Cloud',
                color: Color(0xFF0EA5A4),
                foreground: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            registering
                ? 'Provision trusted access into a premium digital care network.'
                : loginRole == AccountRole.doctor
                ? 'Clinical access for doctors managing records, tasks, and patient treatment.'
                : loginRole == AccountRole.hospital
                ? 'Enterprise hospital workspace for coordinated data exchange and care operations.'
                : 'A professional patient portal for records, consent, and connected care.',
            style: theme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Medifix brings hospitals, clinicians, and patients into one secure operating layer with role-based access, centralized medical records, audit visibility, and fast data exchange.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFFCBD5E1),
            ),
          ),
          const SizedBox(height: 28),
          if (compact) ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                _FeatureBadge(label: 'FHIR + HL7'),
                _FeatureBadge(label: 'Encrypted Records'),
                _FeatureBadge(label: 'Consent Controls'),
              ],
            ),
            const SizedBox(height: 20),
            ResponsiveGrid(
              minTileWidth: 150,
              children: const [
                _TrustMetric(value: '12', label: 'Hospitals'),
                _TrustMetric(value: '4,280', label: 'Records'),
                _TrustMetric(value: '24/7', label: 'Availability'),
              ],
            ),
          ] else ...[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: const [
                _FeatureBadge(label: 'FHIR + HL7 Exchange'),
                _FeatureBadge(label: 'Encrypted Record Vault'),
                _FeatureBadge(label: 'Consent-Based Sharing'),
                _FeatureBadge(label: 'Audit Logging'),
              ],
            ),
            const SizedBox(height: 28),
            ResponsiveGrid(
              minTileWidth: 220,
              children: const [
                _AuthCapabilityCard(
                  title: 'Patient Access',
                  detail:
                      'Self-service login, profile controls, consent toggles, emergency contacts, and connected hospital discovery.',
                  icon: Icons.person_outlined,
                ),
                _AuthCapabilityCard(
                  title: 'Doctor Workspace',
                  detail:
                      'Doctor onboarding, patient creation, chart editing, record attachments, and clinical review workflows.',
                  icon: Icons.medical_services_outlined,
                ),
                _AuthCapabilityCard(
                  title: 'Hospital Operations',
                  detail:
                      'Share discharge summaries, manage hospital doctors, review patient queues, and coordinate care teams.',
                  icon: Icons.local_hospital_outlined,
                ),
              ],
            ),
            const SizedBox(height: 28),
            ResponsiveGrid(
              minTileWidth: 180,
              children: const [
                _TrustMetric(value: '12', label: 'Hospitals Connected'),
                _TrustMetric(value: '4,280', label: 'Records Secured'),
                _TrustMetric(value: '1.2s', label: 'Average Sync Time'),
                _TrustMetric(value: '24/7', label: 'Portal Availability'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _AuthCapabilityCard extends StatelessWidget {
  const _AuthCapabilityCard({
    required this.title,
    required this.detail,
    required this.icon,
  });

  final String title;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFCBD5E1)),
          ),
        ],
      ),
    );
  }
}

class _TrustMetric extends StatelessWidget {
  const _TrustMetric({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFCBD5E1)),
          ),
        ],
      ),
    );
  }
}

class _AuthRoleChip extends StatelessWidget {
  const _AuthRoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : const Color(0xFF475569),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  const _FeatureBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({
    required this.registering,
    required this.submitting,
    required this.loginRole,
    required this.loginEmailController,
    required this.loginPasswordController,
    required this.registerNameController,
    required this.registerEmailController,
    required this.registerPasswordController,
    required this.registerHospitalController,
    required this.registerSpecialtyController,
    required this.onToggleMode,
    required this.onRoleChanged,
    required this.onLogin,
    required this.onRegister,
  });

  final bool registering;
  final bool submitting;
  final AccountRole loginRole;
  final TextEditingController loginEmailController;
  final TextEditingController loginPasswordController;
  final TextEditingController registerNameController;
  final TextEditingController registerEmailController;
  final TextEditingController registerPasswordController;
  final TextEditingController registerHospitalController;
  final TextEditingController registerSpecialtyController;
  final VoidCallback onToggleMode;
  final ValueChanged<AccountRole> onRoleChanged;
  final Future<void> Function() onLogin;
  final Future<void> Function() onRegister;

  @override
  Widget build(BuildContext context) {
    final title = registering
        ? switch (loginRole) {
            AccountRole.patient => 'Create patient account',
            AccountRole.doctor => 'Create doctor account',
            AccountRole.hospital => 'Create hospital portal',
          }
        : switch (loginRole) {
            AccountRole.patient => 'Sign in',
            AccountRole.doctor => 'Doctor sign in',
            AccountRole.hospital => 'Hospital sign in',
          };
    final description = registering
        ? switch (loginRole) {
            AccountRole.patient =>
              'Create a secure patient portal account for records, consent, and personal healthcare access.',
            AccountRole.doctor =>
              'Register a doctor workspace with hospital affiliation and specialty-based access.',
            AccountRole.hospital =>
              'Provision a hospital operations portal for records exchange, doctor management, and patient coordination.',
          }
        : loginRole == AccountRole.doctor
        ? 'Use doctor credentials to manage patients, update medical records, and review clinical activity.'
        : loginRole == AccountRole.hospital
        ? 'Use the hospital portal to coordinate doctor teams, share records, and operate the hospital command center.'
        : 'Use patient credentials to access records, nearby hospitals, consent controls, and the personal care dashboard.';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0F172A),
            blurRadius: 34,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: const Text(
                'Enterprise-grade access',
                style: TextStyle(
                  color: Color(0xFF065F46),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                TextButton(
                  onPressed: submitting ? null : onToggleMode,
                  child: Text(
                    registering
                        ? 'Use demo login'
                        : loginRole == AccountRole.doctor
                        ? 'New doctor'
                        : loginRole == AccountRole.hospital
                        ? 'New hospital'
                        : 'New patient',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _AuthRoleChip(
                  label: 'Patient',
                  icon: Icons.person,
                  selected: loginRole == AccountRole.patient,
                  onTap: submitting
                      ? null
                      : () => onRoleChanged(AccountRole.patient),
                ),
                _AuthRoleChip(
                  label: 'Doctor',
                  icon: Icons.medical_services,
                  selected: loginRole == AccountRole.doctor,
                  onTap: submitting
                      ? null
                      : () => onRoleChanged(AccountRole.doctor),
                ),
                _AuthRoleChip(
                  label: 'Hospital',
                  icon: Icons.local_hospital,
                  selected: loginRole == AccountRole.hospital,
                  onTap: submitting
                      ? null
                      : () => onRoleChanged(AccountRole.hospital),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const SizedBox(height: 6),
            if (!registering) ...[
              TextField(
                controller: loginEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: loginPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: submitting ? null : () => onLogin(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFF0F766E),
                ),
                child: Text(
                  submitting ? 'Signing in...' : 'Sign in to dashboard',
                ),
              ),
              const SizedBox(height: 20),
              _HintPanel(
                title: 'Demo Credentials',
                lines: loginRole == AccountRole.doctor
                    ? const [
                        'Doctor email: dr.luffy@medibridge.app',
                        'Doctor password: Doctor@123',
                      ]
                    : loginRole == AccountRole.hospital
                    ? const [
                        'Hospital email: records@greenvalleyhospital.com',
                        'Hospital password: Hospital@123',
                      ]
                    : const [
                        'Patient email: akash123@gmail.com',
                        'Patient password: Pass@123',
                      ],
              ),
            ] else ...[
              TextField(
                controller: registerNameController,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: registerEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: registerPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: registerHospitalController,
                decoration: const InputDecoration(
                  labelText: 'Hospital or healthcare network',
                ),
              ),
              if (loginRole == AccountRole.doctor) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: registerSpecialtyController,
                  decoration: const InputDecoration(labelText: 'Specialty'),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton(
                onPressed: submitting ? null : () => onRegister(),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFF0F766E),
                ),
                child: Text(
                  submitting
                      ? 'Creating account...'
                      : loginRole == AccountRole.doctor
                      ? 'Register doctor account'
                      : loginRole == AccountRole.hospital
                      ? 'Register hospital portal'
                      : 'Register secure account',
                ),
              ),
              const SizedBox(height: 20),
              _HintPanel(
                title: 'Provisioned By Default',
                lines: loginRole == AccountRole.doctor
                    ? const [
                        'Doctor portal access',
                        'Hospital-linked profile',
                        'Ability to manage patient records',
                      ]
                    : loginRole == AccountRole.hospital
                    ? const [
                        'Hospital sharing portal',
                        'Doctor management features',
                        'Patient treatment overview',
                      ]
                    : const [
                        'Encrypted patient vault',
                        'FHIR/HL7 interoperability profile',
                        'Audit logging and consent controls',
                      ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HintPanel extends StatelessWidget {
  const _HintPanel({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final line in lines) ...[Text(line), const SizedBox(height: 4)],
        ],
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final controller = AppStateScope.of(context);
    final patient = controller.patientSnapshot;
    if (patient == null) {
      return const SizedBox.shrink();
    }

    final pages = <Widget>[
      OverviewScreen(patient: patient),
      RecordsScreen(patient: patient),
      TrendsScreen(patient: patient),
      InteroperabilityScreen(patient: patient),
      ProfileScreen(patient: patient),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 82,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Medifix', style: Theme.of(context).textTheme.titleLarge),
            Text(
              'Last platform sync: ${formatDateTime(patient.lastGlobalSync)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFD1FAE5),
                  child: Text(
                    patient.profile.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF065F46),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      patient.profile.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      patient.profile.memberId,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (value) {
          setState(() => _selectedIndex = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_open_outlined),
            selectedIcon: Icon(Icons.folder_open),
            label: 'Records',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: 'Trends',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_hospital_outlined),
            selectedIcon: Icon(Icons.local_hospital),
            label: 'Hospitals',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user),
            label: 'Security',
          ),
        ],
      ),
    );
  }
}

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key, required this.patient});

  final PatientSnapshot patient;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 950;
    final summaryCards = [
      SummaryStat(
        title: 'Records in vault',
        value: patient.records.length.toString(),
        subtitle:
            'consolidated from ${patient.sources.length} connected systems',
        accent: const Color(0xFF0F766E),
        icon: Icons.lock,
      ),
      SummaryStat(
        title: 'Upcoming tasks',
        value: patient.tasks.where((task) => !task.completed).length.toString(),
        subtitle: 'care actions that still require attention',
        accent: const Color(0xFF1D4ED8),
        icon: Icons.assignment_turned_in,
      ),
      SummaryStat(
        title: 'Audit events',
        value: patient.auditTrail.length.toString(),
        subtitle: 'visibility into every access and sync action',
        accent: const Color(0xFF7C3AED),
        icon: Icons.fact_check,
      ),
      SummaryStat(
        title: 'Consent-enabled feeds',
        value: patient.sources
            .where((source) => source.consentGranted)
            .length
            .toString(),
        subtitle: 'active interoperability channels',
        accent: const Color(0xFFEA580C),
        icon: Icons.sync_lock,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeroPanel(patient: patient),
          const SizedBox(height: 20),
          ResponsiveGrid(
            minTileWidth: 220,
            children: summaryCards
                .map((stat) => SummaryCard(stat: stat))
                .toList(growable: false),
          ),
          const SizedBox(height: 20),
          wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: SectionCard(
                        title: 'Care plan timeline',
                        subtitle:
                            'Track the next actions generated from your aggregated health data.',
                        child: Column(
                          children: patient.tasks
                              .map((task) => CareTaskTile(task: task))
                              .toList(growable: false),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 4,
                      child: SectionCard(
                        title: 'Recent clinical documents',
                        subtitle:
                            'The latest records synchronized across hospitals, labs, and clinics.',
                        child: Column(
                          children: patient.records
                              .take(4)
                              .map((record) => RecordPreview(record: record))
                              .toList(growable: false),
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    SectionCard(
                      title: 'Care plan timeline',
                      subtitle:
                          'Track the next actions generated from your aggregated health data.',
                      child: Column(
                        children: patient.tasks
                            .map((task) => CareTaskTile(task: task))
                            .toList(growable: false),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SectionCard(
                      title: 'Recent clinical documents',
                      subtitle:
                          'The latest records synchronized across hospitals, labs, and clinics.',
                      child: Column(
                        children: patient.records
                            .take(4)
                            .map((record) => RecordPreview(record: record))
                            .toList(growable: false),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({super.key, required this.patient});

  final PatientSnapshot patient;

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      'All',
      ...{for (final record in widget.patient.records) record.category},
    ];
    final query = _searchController.text.trim().toLowerCase();
    final filtered = widget.patient.records
        .where((record) {
          final matchesCategory =
              _selectedCategory == 'All' ||
              record.category == _selectedCategory;
          final matchesQuery =
              query.isEmpty ||
              record.title.toLowerCase().contains(query) ||
              record.source.toLowerCase().contains(query) ||
              record.summary.toLowerCase().contains(query);
          return matchesCategory && matchesQuery;
        })
        .toList(growable: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: 'Centralized health overview',
            subtitle:
                'Search and inspect encrypted records from every connected healthcare system.',
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Search records, source systems, or summaries',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: categories
                        .map((category) {
                          return ChoiceChip(
                            label: Text(category),
                            selected: category == _selectedCategory,
                            onSelected: (_) {
                              setState(() => _selectedCategory = category);
                            },
                          );
                        })
                        .toList(growable: false),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ResponsiveGrid(
            minTileWidth: 300,
            children: filtered
                .map((record) {
                  return SectionCard(
                    title: record.title,
                    subtitle:
                        '${record.category} • ${record.source} • ${formatDate(record.recordedAt)}',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            StatusPill(
                              label: record.status,
                              color: record.status == 'Reviewed'
                                  ? const Color(0xFF0F766E)
                                  : const Color(0xFFEA580C),
                            ),
                            StatusPill(
                              label: record.standard,
                              color: const Color(0xFF1D4ED8),
                            ),
                            StatusPill(
                              label: record.secureId,
                              color: const Color(0xFF7C3AED),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(record.summary),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: record.tags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                        if (record.attachments.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            'Images and scans',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 92,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: record.attachments.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (context, index) {
                                final attachment = record.attachments[index];
                                return GestureDetector(
                                  onTap: () => _showAttachmentViewer(
                                    context,
                                    attachment,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Container(
                                      width: 110,
                                      color: const Color(0xFFF1F5F9),
                                      child: Image.memory(
                                        attachment.bytes,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        FilledButton.tonalIcon(
                          onPressed: () => _showRecordSheet(context, record),
                          icon: const Icon(Icons.visibility),
                          label: const Text('View details'),
                        ),
                      ],
                    ),
                  );
                })
                .toList(growable: false),
          ),
          if (filtered.isEmpty) ...[
            const SizedBox(height: 20),
            const Center(child: Text('No records match the selected filters.')),
          ],
        ],
      ),
    );
  }

  void _showRecordSheet(BuildContext context, HealthRecord record) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(record.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '${record.category} from ${record.source} on ${formatDate(record.recordedAt)}',
              ),
              const SizedBox(height: 18),
              Text(record.details),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  StatusPill(
                    label: 'Encrypted',
                    color: const Color(0xFF0F766E),
                  ),
                  StatusPill(
                    label: record.standard,
                    color: const Color(0xFF1D4ED8),
                  ),
                  StatusPill(
                    label: record.status,
                    color: const Color(0xFF7C3AED),
                  ),
                ],
              ),
              if (record.attachments.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  'Scans and images',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: record.attachments
                      .map((attachment) {
                        return GestureDetector(
                          onTap: () =>
                              _showAttachmentViewer(context, attachment),
                          child: SizedBox(
                            width: 140,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: AspectRatio(
                                    aspectRatio: 1.2,
                                    child: Image.memory(
                                      attachment.bytes,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        color: const Color(0xFFF1F5F9),
                                        child: const Icon(
                                          Icons.image_not_supported,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  attachment.fileName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showAttachmentViewer(
    BuildContext context,
    RecordAttachment attachment,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.memory(
                    attachment.bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Container(
                      height: 220,
                      color: const Color(0xFFF1F5F9),
                      child: const Center(
                        child: Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({super.key, required this.patient});

  final PatientSnapshot patient;

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> {
  late TrendSeries _selectedSeries;

  @override
  void initState() {
    super.initState();
    _selectedSeries = widget.patient.trends.first;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: 'Data visualization and health trends',
            subtitle:
                'Monitor standardized clinical metrics captured from interoperable systems.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: widget.patient.trends
                      .map((series) {
                        return ChoiceChip(
                          selected: series.label == _selectedSeries.label,
                          label: Text(series.label),
                          onSelected: (_) {
                            setState(() => _selectedSeries = series);
                          },
                        );
                      })
                      .toList(growable: false),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 240,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: TrendChartPainter(series: _selectedSeries),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ResponsiveGrid(
            minTileWidth: 280,
            children: [
              SectionCard(
                title: '${_selectedSeries.label} insight',
                subtitle: 'Most recent measurement intelligence',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedSeries.points.last.value.toStringAsFixed(1)} ${_selectedSeries.unit}',
                      style: Theme.of(
                        context,
                      ).textTheme.displaySmall?.copyWith(fontSize: 38),
                    ),
                    const SizedBox(height: 8),
                    Text(_selectedSeries.interpretation),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _selectedSeries.normalizedLatestValue,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Trend range: ${_selectedSeries.minDisplay.toStringAsFixed(0)} - ${_selectedSeries.maxDisplay.toStringAsFixed(0)} ${_selectedSeries.unit}',
                    ),
                  ],
                ),
              ),
              SectionCard(
                title: 'Medication adherence',
                subtitle: 'Patient engagement and daily follow-through',
                child: Column(
                  children: widget.patient.adherence
                      .map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.label,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                  Text('${entry.value.toInt()}%'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: entry.value / 100,
                                  minHeight: 12,
                                  color: entry.color,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
              ),
              SectionCard(
                title: 'Clinical observations',
                subtitle: 'How the platform interprets your data',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widget.patient.insights
                      .map((insight) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: insight.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      insight.title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(insight.detail),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class InteroperabilityScreen extends StatelessWidget {
  const InteroperabilityScreen({super.key, required this.patient});

  final PatientSnapshot patient;

  @override
  Widget build(BuildContext context) {
    final controller = AppStateScope.of(context);
    final recentVisits = [...patient.sources]
      ..sort((a, b) => b.lastSync.compareTo(a.lastSync));
    final nearbyHospitals = [
      ...patient.sources,
    ]..sort((a, b) => distanceFromPatient(a).compareTo(distanceFromPatient(b)));
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: 'Nearby hospitals map',
            subtitle:
                'Find nearby providers around your saved area and share your records when needed.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: NearbyHospitalsMap(),
                ),
                const SizedBox(height: 16),
                Column(
                  children: nearbyHospitals
                      .take(4)
                      .map((source) {
                        final distance = distanceFromPatient(
                          source,
                        ).toStringAsFixed(1);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        source.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${source.type} • $distance km away',
                                      ),
                                    ],
                                  ),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final message = await controller
                                        .sharePatientDataWithHospital(
                                          sourceId: source.id,
                                        );
                                    if (!context.mounted) {
                                      return;
                                    }
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          message ??
                                              'Shared your data access with ${source.name}.',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.share),
                                  label: const Text('Share data'),
                                ),
                              ],
                            ),
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Connected healthcare providers',
            subtitle:
                'This page shows where your records come from and whether sharing is turned on.',
            child: ResponsiveGrid(
              minTileWidth: 230,
              children: [
                SummaryCard(
                  stat: SummaryStat(
                    title: 'Connected places',
                    value: patient.sources.length.toString(),
                    subtitle: 'hospitals, clinics, labs, and pharmacies',
                    accent: const Color(0xFF0F766E),
                    icon: Icons.local_hospital,
                  ),
                ),
                SummaryCard(
                  stat: SummaryStat(
                    title: 'Sharing turned on',
                    value: patient.sources
                        .where((source) => source.consentGranted)
                        .length
                        .toString(),
                    subtitle: 'places allowed to send new updates',
                    accent: const Color(0xFF1D4ED8),
                    icon: Icons.share,
                  ),
                ),
                SummaryCard(
                  stat: SummaryStat(
                    title: 'Last update',
                    value: formatDate(patient.lastGlobalSync),
                    subtitle: 'most recent record refresh across the app',
                    accent: const Color(0xFF7C3AED),
                    icon: Icons.update,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Hospitals and providers last visited',
            subtitle:
                'Most recent visits or updates from your connected providers.',
            child: Column(
              children: recentVisits
                  .map((source) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.local_hospital,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    source.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${source.type} • Last visited/updated ${formatDateTime(source.lastSync)}',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Data sharing settings',
            subtitle:
                'Turn sharing on or off for each provider in simple terms.',
            child: Column(
              children: patient.sources
                  .map((source) {
                    final syncing = controller.syncingSourceIds.contains(
                      source.id,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        source.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        source.consentGranted
                                            ? 'Sharing is on. This provider can send you new records.'
                                            : 'Sharing is off. No new records will be pulled from this provider.',
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: source.consentGranted,
                                  onChanged: (value) {
                                    controller.toggleConsent(source.id, value);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Records available: ${source.recordsAvailable} • Last sync: ${formatDateTime(source.lastSync)}',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.tonalIcon(
                                  onPressed: () async {
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final message = await controller
                                        .sharePatientDataWithHospital(
                                          sourceId: source.id,
                                        );
                                    if (!context.mounted) {
                                      return;
                                    }
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          message ??
                                              'Sharing enabled for ${source.name}.',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.share),
                                  label: const Text('Share'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.tonalIcon(
                                  onPressed: syncing || !source.consentGranted
                                      ? null
                                      : () async {
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          await controller.syncSource(
                                            source.id,
                                          );
                                          if (!context.mounted) {
                                            return;
                                          }
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${source.name} refreshed successfully.',
                                              ),
                                            ),
                                          );
                                        },
                                  icon: syncing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.refresh),
                                  label: Text(
                                    syncing ? 'Refreshing...' : 'Refresh now',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.patient});

  final PatientSnapshot patient;

  @override
  Widget build(BuildContext context) {
    final controller = AppStateScope.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: 'Patient identity and access',
            subtitle:
                'Centralized profile details used across the interoperable network.',
            child: ResponsiveGrid(
              minTileWidth: 220,
              children: [
                ProfileFact(label: 'Patient name', value: patient.profile.name),
                ProfileFact(
                  label: 'Member ID',
                  value: patient.profile.memberId,
                ),
                ProfileFact(
                  label: 'Blood group',
                  value: patient.profile.bloodGroup,
                ),
                ProfileFact(
                  label: 'Primary network',
                  value: patient.profile.hospitalNetwork,
                ),
                ProfileFact(label: 'Phone', value: patient.profile.phone),
                ProfileFact(label: 'Address', value: patient.profile.address),
                ProfileFact(
                  label: 'Allergies',
                  value: patient.profile.allergies.join(', '),
                ),
                ProfileFact(
                  label: 'Emergency contacts',
                  value: patient.profile.emergencyContacts.join('\n'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Edit personal details',
            subtitle:
                'Update your profile, contact details, and emergency contacts.',
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (context) =>
                        PatientProfileEditorSheet(profile: patient.profile),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Edit details'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ResponsiveGrid(
            minTileWidth: 280,
            children: [
              SectionCard(
                title: 'Access policy',
                subtitle: 'Authorization controls available in the app',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SecurityLine(
                      title: 'Patient owned',
                      detail:
                          'Patients control consent across hospital, lab, and clinic feeds.',
                    ),
                    SecurityLine(
                      title: 'Least privilege',
                      detail:
                          'Only the required healthcare system receives scoped data exchange access.',
                    ),
                    SecurityLine(
                      title: 'Immutable trace',
                      detail:
                          'Every data transfer event is timestamped and visible in the audit history.',
                    ),
                  ],
                ),
              ),
              SectionCard(
                title: 'Record distribution',
                subtitle: 'Where your centralized health data originates',
                child: Column(
                  children: patient.sources
                      .map((source) {
                        final ratio =
                            source.recordsAvailable / patient.records.length;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      source.name,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                  Text('${source.recordsAvailable}'),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 12,
                                  color: const Color(0xFF0F766E),
                                  backgroundColor: const Color(0xFFE2E8F0),
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Session control',
            subtitle: 'Exit the current secure patient session.',
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: controller.logout,
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorHomeShell extends StatefulWidget {
  const DoctorHomeShell({super.key});

  @override
  State<DoctorHomeShell> createState() => _DoctorHomeShellState();
}

class _DoctorHomeShellState extends State<DoctorHomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final controller = AppStateScope.of(context);
    final doctor = controller.currentAccount;
    if (doctor == null) {
      return const SizedBox.shrink();
    }

    final pages = const [
      DoctorPatientsScreen(),
      DoctorActivityScreen(),
      DoctorProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 82,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medifix Doctor Console',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '${doctor.specialty ?? 'Clinical access'} • ${doctor.hospitalNetwork ?? 'Hospital network'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFDBEAFE),
                  child: Text(
                    doctor.fullName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      doctor.fullName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Doctor access',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (value) {
          setState(() => _selectedIndex = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Patients',
          ),
          NavigationDestination(
            icon: Icon(Icons.timeline_outlined),
            selectedIcon: Icon(Icons.timeline),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class DoctorPatientsScreen extends StatefulWidget {
  const DoctorPatientsScreen({super.key});

  @override
  State<DoctorPatientsScreen> createState() => _DoctorPatientsScreenState();
}

class _DoctorPatientsScreenState extends State<DoctorPatientsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppStateScope.of(context);
    final query = _searchController.text.trim().toLowerCase();
    final patients = controller.allPatients
        .where((patient) {
          return query.isEmpty ||
              patient.profile.name.toLowerCase().contains(query) ||
              patient.profile.memberId.toLowerCase().contains(query) ||
              patient.profile.hospitalNetwork.toLowerCase().contains(query);
        })
        .toList(growable: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1E3A8A),
                  Color(0xFF0F766E),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DOCTOR WORKSPACE',
                  style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Add patients and maintain their medical records.',
                  style: Theme.of(
                    context,
                  ).textTheme.displaySmall?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  'This workspace lets doctors onboard patients, review centralized charts, and edit clinical records in the shared vault.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _openAddPatientSheet(context),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Add patient'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Patient directory',
            subtitle:
                'Search the current patient registry and open record management.',
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Search patients by name, member ID, or network',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 18),
                ResponsiveGrid(
                  minTileWidth: 320,
                  children: patients
                      .map((patient) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        patient.profile.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
                                      ),
                                    ),
                                    StatusPill(
                                      label: patient.profile.memberId,
                                      color: const Color(0xFF1D4ED8),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${patient.profile.hospitalNetwork} • ${patient.profile.bloodGroup}',
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${patient.records.length} records • ${patient.auditTrail.length} audit events • ${patient.sources.length} connected sources',
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Emergency contact: ${patient.profile.emergencyContact}',
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    FilledButton.tonalIcon(
                                      onPressed: () => _openManageRecordsSheet(
                                        context,
                                        patient,
                                      ),
                                      icon: const Icon(Icons.edit_note),
                                      label: const Text('Manage records'),
                                    ),
                                    FilledButton.tonalIcon(
                                      onPressed: () => _openEditRecordSheet(
                                        context,
                                        patient,
                                        null,
                                      ),
                                      icon: const Icon(Icons.note_add),
                                      label: const Text('Add record'),
                                    ),
                                    FilledButton.tonalIcon(
                                      onPressed: () => _confirmDeletePatient(
                                        context,
                                        patient,
                                      ),
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text('Delete patient'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      })
                      .toList(growable: false),
                ),
                if (patients.isEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('No patients match the current search.'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddPatientSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const AddPatientSheet(),
    );
  }

  Future<void> _openManageRecordsSheet(
    BuildContext context,
    PatientSnapshot patient,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          ManageRecordsSheet(patientEmail: patientEmailFor(patient)),
    );
  }

  Future<void> _openEditRecordSheet(
    BuildContext context,
    PatientSnapshot patient,
    HealthRecord? record,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => RecordEditorSheet(
        patientEmail: patientEmailFor(patient),
        existingRecord: record,
      ),
    );
  }

  Future<void> _confirmDeletePatient(
    BuildContext context,
    PatientSnapshot patient,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete patient'),
          content: Text(
            'Delete ${patient.profile.name} and all saved records from this device?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final controller = AppStateScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final message = await controller.deletePatientAsDoctor(
      patient.profile.email,
    );
    if (!context.mounted) {
      return;
    }
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text('${patient.profile.name} deleted.')),
    );
  }
}

class DoctorActivityScreen extends StatelessWidget {
  const DoctorActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppStateScope.of(context);
    final feed = controller.doctorAuditFeed;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          SectionCard(
            title: 'Clinical activity feed',
            subtitle:
                'Recent patient access, sync, and edit events across the shared platform.',
            child: Column(
              children: feed
                  .map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: item.event.severityColor.withValues(
                                alpha: 0.12,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.event.icon,
                              color: item.event.severityColor,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.patientName} • ${item.event.title}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.event.actor} • ${formatDateTime(item.event.timestamp)}',
                                ),
                                const SizedBox(height: 4),
                                Text(item.event.detail),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}

class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppStateScope.of(context);
    final doctor = controller.currentAccount!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionCard(
            title: 'Doctor identity',
            subtitle: 'Current authenticated clinical account.',
            child: ResponsiveGrid(
              minTileWidth: 240,
              children: [
                ProfileFact(label: 'Doctor name', value: doctor.fullName),
                ProfileFact(
                  label: 'Specialty',
                  value: doctor.specialty ?? 'General Medicine',
                ),
                ProfileFact(
                  label: 'Hospital network',
                  value:
                      doctor.hospitalNetwork ?? 'Sree Buddha Medical Network',
                ),
                ProfileFact(label: 'Role', value: 'Doctor'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Doctor permissions',
            subtitle: 'Actions available in the current demo implementation.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SecurityLine(
                  title: 'Patient onboarding',
                  detail:
                      'Doctors can create patient profiles and provision a secure default account.',
                ),
                SecurityLine(
                  title: 'Medical record editing',
                  detail:
                      'Doctors can add or update clinical records inside the centralized vault.',
                ),
                SecurityLine(
                  title: 'Shared audit visibility',
                  detail:
                      'Doctor actions are appended to patient audit history for traceability.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Session control',
            subtitle: 'Exit the current doctor session.',
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: controller.logout,
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HospitalHomeShell extends StatefulWidget {
  const HospitalHomeShell({super.key});

  @override
  State<HospitalHomeShell> createState() => _HospitalHomeShellState();
}

class _HospitalHomeShellState extends State<HospitalHomeShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final controller = AppStateScope.of(context);
    final hospital = controller.currentAccount;
    if (hospital == null) {
      return const SizedBox.shrink();
    }

    final page = switch (_selectedIndex) {
      0 => const HospitalOverviewScreen(),
      1 => const HospitalShareDataScreen(),
      2 => const HospitalPatientsScreen(),
      _ => const HospitalTeamScreen(),
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 74,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medifix Hospital Portal',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              hospital.hospitalNetwork ?? 'Hospital records portal',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: controller.logout,
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ),
        ],
      ),
      body: page,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (value) {
          setState(() => _selectedIndex = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_shared_outlined),
            selectedIcon: Icon(Icons.folder_shared),
            label: 'Share Data',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Patients',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services),
            label: 'Team',
          ),
        ],
      ),
    );
  }
}

class HospitalOverviewScreen extends StatelessWidget {
  const HospitalOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppStateScope.of(context);
    final snapshot = HospitalPortalSnapshot.fromController(controller);
    final hospital = snapshot.hospital;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF0F766E),
                  Color(0xFF164E63),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HOSPITAL COMMAND CENTER',
                  style: TextStyle(
                    color: Colors.white70,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${hospital.hospitalNetwork ?? 'Hospital Portal'} made simpler.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Review the essentials first: current patients, recent transfers, and doctor workload.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ResponsiveGrid(
            minTileWidth: 230,
            children: [
              SummaryCard(
                stat: SummaryStat(
                  title: 'Patients served',
                  value: snapshot.treatedPatients.length.toString(),
                  subtitle: 'patients with records from this hospital',
                  accent: const Color(0xFF0F766E),
                  icon: Icons.groups,
                ),
              ),
              SummaryCard(
                stat: SummaryStat(
                  title: 'Records shared',
                  value: snapshot.sharedRecords.toString(),
                  subtitle: 'reports, scans, summaries, and updates',
                  accent: const Color(0xFF1D4ED8),
                  icon: Icons.upload_file,
                ),
              ),
              SummaryCard(
                stat: SummaryStat(
                  title: 'Active doctors',
                  value: snapshot.doctors.length.toString(),
                  subtitle: 'doctors managed inside this portal',
                  accent: const Color(0xFF7C3AED),
                  icon: Icons.medical_services,
                ),
              ),
              SummaryCard(
                stat: SummaryStat(
                  title: 'Open care tasks',
                  value: snapshot.openTasks.toString(),
                  subtitle: 'follow-ups and pending patient actions',
                  accent: const Color(0xFFEA580C),
                  icon: Icons.assignment_late,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Priority patients',
            subtitle:
                'The patients who need attention first, without opening the full directory.',
            child: snapshot.watchlist.isEmpty
                ? const InlineEmptyState(
                    title: 'No patients need review right now.',
                    detail:
                        'Priority patients will appear here when the hospital starts sharing or assigning care.',
                  )
                : Column(
                    children: snapshot.watchlist
                        .take(4)
                        .map((patient) {
                          final assignedDoctors = doctorsTreatingPatient(
                            controller,
                            patient.profile.email,
                          );
                          return HospitalPatientSummaryTile(
                            patient: patient,
                            statusLabel: patientPriorityLabel(patient),
                            statusColor: patientPriorityColor(patient),
                            subtitle:
                                '${patient.profile.memberId} • ${patient.profile.hospitalNetwork}',
                            facts: [
                              'Open tasks: ${openTaskCount(patient)}',
                              'Adherence: ${averageAdherence(patient).round()}%',
                              assignedDoctors.isEmpty
                                  ? 'Doctor coverage pending'
                                  : 'Doctors: ${assignedDoctors.map((doctor) => doctor.fullName).join(', ')}',
                            ],
                          );
                        })
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 20),
          ResponsiveGrid(
            minTileWidth: 360,
            children: [
              SectionCard(
                title: 'Quick actions',
                subtitle:
                    'The most common hospital actions are available here first.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: snapshot.linkedPatients.isEmpty
                          ? null
                          : () async {
                              await showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                builder: (context) => RecordEditorSheet(
                                  patientEmail: snapshot
                                      .linkedPatients
                                      .first
                                      .profile
                                      .email,
                                  initialSourceOverride:
                                      hospital.hospitalNetwork ??
                                      'Hospital Portal',
                                ),
                              );
                            },
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Share data to a patient'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        await showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          showDragHandle: true,
                          builder: (context) => const AddHospitalDoctorSheet(),
                        );
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Add hospital doctor'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: snapshot.linkedPatients.isEmpty
                          ? null
                          : () async {
                              await showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                builder: (context) =>
                                    HospitalPatientSnapshotSheet(
                                      patientEmail: snapshot
                                          .linkedPatients
                                          .first
                                          .profile
                                          .email,
                                    ),
                              );
                            },
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Open a patient snapshot'),
                    ),
                  ],
                ),
              ),
              SectionCard(
                title: 'Recent transfer queue',
                subtitle: 'The latest updates shared from this hospital.',
                child: snapshot.recentTransfers.isEmpty
                    ? const InlineEmptyState(
                        title: 'No hospital transfers yet.',
                        detail:
                            'Once this portal shares records, the latest updates will appear here.',
                      )
                    : Column(
                        children: snapshot.recentTransfers
                            .take(5)
                            .map((entry) {
                              return HospitalTransferTile(
                                patient: entry.patient,
                                record: entry.record,
                              );
                            })
                            .toList(growable: false),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Doctor load',
            subtitle:
                'A short roster of the hospital team and their current capacity.',
            child: snapshot.doctors.isEmpty
                ? const InlineEmptyState(
                    title: 'No doctors added yet.',
                    detail:
                        'Add a hospital doctor to start assigning patients and tracking care load.',
                  )
                : Column(
                    children: snapshot.doctors
                        .map((doctor) {
                          final assignedPatients = doctor.assignedPatientEmails
                              .map(controller.findPatientByEmail)
                              .whereType<PatientSnapshot>()
                              .toList(growable: false);
                          return HospitalDoctorSummaryTile(
                            doctor: doctor,
                            assignedPatients: assignedPatients,
                          );
                        })
                        .toList(growable: false),
                  ),
          ),
        ],
      ),
    );
  }
}

class HospitalShareDataScreen extends StatefulWidget {
  const HospitalShareDataScreen({super.key});

  @override
  State<HospitalShareDataScreen> createState() =>
      _HospitalShareDataScreenState();
}

class _HospitalShareDataScreenState extends State<HospitalShareDataScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppStateScope.of(context);
    final snapshot = HospitalPortalSnapshot.fromController(controller);
    final hospital = snapshot.hospital;
    final query = _searchController.text.trim().toLowerCase();
    final patients = snapshot.linkedPatients
        .where((patient) {
          final matchesQuery =
              query.isEmpty ||
              patient.profile.name.toLowerCase().contains(query) ||
              patient.profile.memberId.toLowerCase().contains(query);
          final consentReady = patientHasConsentForHospital(
            patient,
            hospital.hospitalNetwork,
          );
          final matchesFilter = switch (_filter) {
            'Consent Ready' => consentReady,
            'Needs Consent' => !consentReady,
            _ => true,
          };
          return matchesQuery && matchesFilter;
        })
        .toList(growable: false);
    final consentReadyCount = snapshot.linkedPatients
        .where(
          (patient) =>
              patientHasConsentForHospital(patient, hospital.hospitalNetwork),
        )
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveGrid(
            minTileWidth: 220,
            children: [
              SummaryCard(
                stat: SummaryStat(
                  title: 'Patients',
                  value: patients.length.toString(),
                  subtitle: 'patients available for hospital sharing',
                  accent: const Color(0xFF0F766E),
                  icon: Icons.groups,
                ),
              ),
              SummaryCard(
                stat: SummaryStat(
                  title: 'Consent ready',
                  value: consentReadyCount.toString(),
                  subtitle: 'patients ready to receive shared data',
                  accent: const Color(0xFF1D4ED8),
                  icon: Icons.verified_user,
                ),
              ),
              SummaryCard(
                stat: SummaryStat(
                  title: 'Records shared',
                  value: snapshot.sharedRecords.toString(),
                  subtitle: 'records already delivered by this hospital',
                  accent: const Color(0xFF7C3AED),
                  icon: Icons.folder_shared,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Hospital data sharing',
            subtitle:
                'Search a patient, confirm consent, and send an update with fewer steps.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Search patients by name or member ID',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['All', 'Consent Ready', 'Needs Consent']
                      .map((label) {
                        return ChoiceChip(
                          label: Text(label),
                          selected: _filter == label,
                          onSelected: (_) => setState(() => _filter = label),
                        );
                      })
                      .toList(growable: false),
                ),
                const SizedBox(height: 18),
                if (patients.isEmpty)
                  const InlineEmptyState(
                    title: 'No patients match this filter.',
                    detail:
                        'Try a different search or switch back to all patients.',
                  )
                else
                  ...patients.map((patient) {
                    final consentReady = patientHasConsentForHospital(
                      patient,
                      hospital.hospitalNetwork,
                    );
                    return HospitalPatientSummaryTile(
                      patient: patient,
                      statusLabel: consentReady
                          ? 'Sharing enabled'
                          : 'Consent required',
                      statusColor: consentReady
                          ? const Color(0xFF0F766E)
                          : const Color(0xFFEA580C),
                      subtitle:
                          '${patient.profile.memberId} • ${patient.profile.hospitalNetwork}',
                      facts: [
                        'Records: ${patient.records.length}',
                        'Attachments: ${patientAttachmentCount(patient)}',
                        'Last update: ${formatDateTime(patient.lastGlobalSync)}',
                      ],
                      actions: [
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            await showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              builder: (context) => RecordEditorSheet(
                                patientEmail: patient.profile.email,
                                initialSourceOverride:
                                    hospital.hospitalNetwork ??
                                    'Hospital Portal',
                              ),
                            );
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Share hospital data'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              builder: (context) =>
                                  HospitalPatientSnapshotSheet(
                                    patientEmail: patient.profile.email,
                                  ),
                            );
                          },
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('Open snapshot'),
                        ),
                      ],
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HospitalPatientsScreen extends StatefulWidget {
  const HospitalPatientsScreen({super.key});

  @override
  State<HospitalPatientsScreen> createState() => _HospitalPatientsScreenState();
}

class _HospitalPatientsScreenState extends State<HospitalPatientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppStateScope.of(context);
    final snapshot = HospitalPortalSnapshot.fromController(controller);
    final hospital = snapshot.hospital;
    final query = _searchController.text.trim().toLowerCase();
    final patients =
        snapshot.linkedPatients
            .where((patient) {
              final matchesQuery =
                  query.isEmpty ||
                  patient.profile.name.toLowerCase().contains(query) ||
                  patient.profile.memberId.toLowerCase().contains(query) ||
                  patient.profile.email.toLowerCase().contains(query);
              final assigned = snapshot.assignedPatientEmails.contains(
                patient.profile.email.toLowerCase(),
              );
              final matchesFilter = switch (_filter) {
                'Assigned' => assigned,
                'Needs Follow-up' => patientNeedsFollowUp(patient),
                _ => true,
              };
              return matchesQuery && matchesFilter;
            })
            .toList(growable: false)
          ..sort(
            (a, b) =>
                patientPriorityScore(b).compareTo(patientPriorityScore(a)),
          );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveGrid(
            minTileWidth: 220,
            children: [
              SummaryCard(
                stat: SummaryStat(
                  title: 'Linked patients',
                  value: snapshot.linkedPatients.length.toString(),
                  subtitle: 'patients visible to this hospital portal',
                  accent: const Color(0xFF0F766E),
                  icon: Icons.groups,
                ),
              ),
              SummaryCard(
                stat: SummaryStat(
                  title: 'Needs follow-up',
                  value: snapshot.needsFollowUpCount.toString(),
                  subtitle: 'patients with active tasks or low adherence',
                  accent: const Color(0xFFEA580C),
                  icon: Icons.notification_important,
                ),
              ),
              SummaryCard(
                stat: SummaryStat(
                  title: 'Emergency contacts',
                  value: snapshot.emergencyContactCount.toString(),
                  subtitle: 'patient profiles with emergency details',
                  accent: const Color(0xFF1D4ED8),
                  icon: Icons.emergency,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Patient directory',
            subtitle:
                'Review patients quickly, then open details only when needed.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Search by patient name, email, or member ID',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['All', 'Assigned', 'Needs Follow-up']
                      .map((label) {
                        return ChoiceChip(
                          label: Text(label),
                          selected: _filter == label,
                          onSelected: (_) => setState(() => _filter = label),
                        );
                      })
                      .toList(growable: false),
                ),
                const SizedBox(height: 18),
                if (patients.isEmpty)
                  const InlineEmptyState(
                    title: 'No patients match this filter.',
                    detail:
                        'Try a different search or switch the filter to review the full directory.',
                  )
                else
                  ...patients.map((patient) {
                    final assignedDoctors = doctorsTreatingPatient(
                      controller,
                      patient.profile.email,
                    );
                    return HospitalPatientSummaryTile(
                      patient: patient,
                      statusLabel: patientPriorityLabel(patient),
                      statusColor: patientPriorityColor(patient),
                      subtitle:
                          '${patient.profile.memberId} • ${patient.profile.bloodGroup} • ${patient.profile.phone}',
                      facts: [
                        'Emergency: ${patient.profile.emergencyContacts.isEmpty ? 'Not added' : patient.profile.emergencyContacts.first}',
                        'Doctors: ${assignedDoctors.isEmpty ? 'None yet' : assignedDoctors.map((doctor) => doctor.fullName).join(', ')}',
                        'Open tasks: ${openTaskCount(patient)} • Adherence: ${averageAdherence(patient).round()}%',
                      ],
                      actions: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            await showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              builder: (context) =>
                                  HospitalPatientSnapshotSheet(
                                    patientEmail: patient.profile.email,
                                  ),
                            );
                          },
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('View snapshot'),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            await showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              builder: (context) => RecordEditorSheet(
                                patientEmail: patient.profile.email,
                                initialSourceOverride:
                                    hospital.hospitalNetwork ??
                                    'Hospital Portal',
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_chart),
                          label: const Text('Add update'),
                        ),
                      ],
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HospitalTeamScreen extends StatelessWidget {
  const HospitalTeamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppStateScope.of(context);
    final snapshot = HospitalPortalSnapshot.fromController(controller);
    final hospital = snapshot.hospital;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveGrid(
            minTileWidth: 220,
            children: [
              SummaryCard(
                stat: SummaryStat(
                  title: 'Hospital doctors',
                  value: snapshot.doctors.length.toString(),
                  subtitle: 'clinical accounts managed from this portal',
                  accent: const Color(0xFF7C3AED),
                  icon: Icons.medical_services,
                ),
              ),
              SummaryCard(
                stat: SummaryStat(
                  title: 'Patients in care',
                  value: snapshot.patientsInCare.length.toString(),
                  subtitle: 'patients assigned to hospital doctors',
                  accent: const Color(0xFF1D4ED8),
                  icon: Icons.groups_2,
                ),
              ),
              SummaryCard(
                stat: SummaryStat(
                  title: 'Coverage gaps',
                  value: snapshot.unassignedPatientsCount.toString(),
                  subtitle: 'patients with no hospital doctor assigned',
                  accent: const Color(0xFFEA580C),
                  icon: Icons.person_search,
                ),
              ),
              SummaryCard(
                stat: SummaryStat(
                  title: 'Urgent follow-up',
                  value: snapshot.urgentPatientsCount.toString(),
                  subtitle: 'patients requiring immediate review',
                  accent: const Color(0xFFBE123C),
                  icon: Icons.crisis_alert,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Team workspace',
            subtitle:
                'Manage doctor access, patient assignments, and active hospital care from one place.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveGrid(
                  minTileWidth: 220,
                  children: [
                    ProfileFact(label: 'Portal name', value: hospital.fullName),
                    ProfileFact(
                      label: 'Hospital',
                      value:
                          hospital.hospitalNetwork ?? 'Green Valley Hospital',
                    ),
                    ProfileFact(
                      label: 'Assignments',
                      value: snapshot.totalAssignments.toString(),
                    ),
                    ProfileFact(
                      label: 'Avg. adherence',
                      value: snapshot.patientsInCare.isEmpty
                          ? '0%'
                          : '${(snapshot.patientsInCare.fold<double>(0, (sum, patient) => sum + averageAdherence(patient)) / snapshot.patientsInCare.length).round()}%',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () async {
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (context) => const AddHospitalDoctorSheet(),
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add doctor'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Doctor roster',
            subtitle:
                'Review current doctors and the patients already assigned to them.',
            child: snapshot.doctors.isEmpty
                ? const InlineEmptyState(
                    title: 'No doctors in this hospital portal yet.',
                    detail:
                        'Add a doctor to start managing assignments and treatment updates.',
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: snapshot.doctors
                        .map((doctor) {
                          final patients = doctor.assignedPatientEmails
                              .map(controller.findPatientByEmail)
                              .whereType<PatientSnapshot>()
                              .toList(growable: false);
                          return HospitalDoctorSummaryTile(
                            doctor: doctor,
                            assignedPatients: patients,
                          );
                        })
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            title: 'Patients in active care',
            subtitle:
                'See the highest-pressure assigned patients without leaving the team workspace.',
            child: snapshot.patientsInCare.isEmpty
                ? const InlineEmptyState(
                    title: 'No patients are assigned yet.',
                    detail:
                        'Assigned patients will appear here once a doctor starts treating them.',
                  )
                : Column(
                    children: snapshot.patientsInCare
                        .map((patient) {
                          final assignedDoctors = doctorsTreatingPatient(
                            controller,
                            patient.profile.email,
                          );
                          return HospitalPatientSummaryTile(
                            patient: patient,
                            statusLabel: patientPriorityLabel(patient),
                            statusColor: patientPriorityColor(patient),
                            subtitle:
                                '${patient.profile.memberId} • ${patient.profile.hospitalNetwork}',
                            facts: [
                              'Doctors: ${assignedDoctors.isEmpty ? 'Not assigned' : assignedDoctors.map((doctor) => doctor.fullName).join(', ')}',
                              'Open tasks: ${openTaskCount(patient)}',
                              'Adherence: ${averageAdherence(patient).round()}% • Last update: ${formatDateTime(patient.lastGlobalSync)}',
                            ],
                            actions: [
                              OutlinedButton.icon(
                                onPressed: () async {
                                  await showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    showDragHandle: true,
                                    builder: (context) =>
                                        HospitalPatientSnapshotSheet(
                                          patientEmail: patient.profile.email,
                                        ),
                                  );
                                },
                                icon: const Icon(Icons.visibility_outlined),
                                label: const Text('Open care snapshot'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: () async {
                                  await showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    showDragHandle: true,
                                    builder: (context) => RecordEditorSheet(
                                      patientEmail: patient.profile.email,
                                      initialSourceOverride:
                                          hospital.hospitalNetwork ??
                                          'Hospital Portal',
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.post_add),
                                label: const Text('Add treatment update'),
                              ),
                            ],
                          );
                        })
                        .toList(growable: false),
                  ),
          ),
        ],
      ),
    );
  }
}

class HospitalPortalSnapshot {
  HospitalPortalSnapshot._({
    required this.hospital,
    required this.doctors,
    required this.assignedPatientEmails,
    required this.linkedPatients,
    required this.treatedPatients,
    required this.patientsInCare,
    required this.watchlist,
    required this.recentTransfers,
    required this.sharedRecords,
    required this.openTasks,
    required this.needsFollowUpCount,
    required this.emergencyContactCount,
    required this.unassignedPatientsCount,
    required this.urgentPatientsCount,
    required this.totalAssignments,
  });

  final UserAccount hospital;
  final List<UserAccount> doctors;
  final Set<String> assignedPatientEmails;
  final List<PatientSnapshot> linkedPatients;
  final List<PatientSnapshot> treatedPatients;
  final List<PatientSnapshot> patientsInCare;
  final List<PatientSnapshot> watchlist;
  final List<({PatientSnapshot patient, HealthRecord record})> recentTransfers;
  final int sharedRecords;
  final int openTasks;
  final int needsFollowUpCount;
  final int emergencyContactCount;
  final int unassignedPatientsCount;
  final int urgentPatientsCount;
  final int totalAssignments;

  factory HospitalPortalSnapshot.fromController(
    HealthAppController controller,
  ) {
    final hospital = controller.currentAccount!;
    final hospitalName = hospital.hospitalNetwork ?? '';
    final doctors = controller.hospitalDoctors;
    final assignedPatientEmails = doctors
        .expand((doctor) => doctor.assignedPatientEmails)
        .map((email) => email.toLowerCase())
        .toSet();
    final linkedPatients = controller.allPatients
        .where((patient) {
          final email = patient.profile.email.toLowerCase();
          return patient.profile.hospitalNetwork == hospital.hospitalNetwork ||
              assignedPatientEmails.contains(email) ||
              patient.records.any((record) => record.source == hospitalName);
        })
        .toList(growable: false);
    final treatedPatients = linkedPatients
        .where((patient) {
          final email = patient.profile.email.toLowerCase();
          return assignedPatientEmails.contains(email) ||
              patient.records.any((record) => record.source == hospitalName);
        })
        .toList(growable: false);
    final patientsInCare =
        assignedPatientEmails
            .map(controller.findPatientByEmail)
            .whereType<PatientSnapshot>()
            .toList(growable: false)
          ..sort(
            (a, b) =>
                patientPriorityScore(b).compareTo(patientPriorityScore(a)),
          );
    final watchlist = [...treatedPatients]
      ..sort(
        (a, b) => patientPriorityScore(b).compareTo(patientPriorityScore(a)),
      );
    final recentTransfers =
        treatedPatients
            .expand(
              (patient) => patient.records
                  .where((record) => record.source == hospitalName)
                  .map((record) => (patient: patient, record: record)),
            )
            .toList()
          ..sort((a, b) => b.record.recordedAt.compareTo(a.record.recordedAt));
    final sharedRecords = treatedPatients.fold<int>(
      0,
      (sum, patient) =>
          sum +
          patient.records
              .where((record) => record.source == hospitalName)
              .length,
    );
    final openTasks = treatedPatients.fold<int>(
      0,
      (sum, patient) => sum + openTaskCount(patient),
    );
    final totalAssignments = doctors.fold<int>(
      0,
      (sum, doctor) => sum + doctor.assignedPatientEmails.length,
    );

    return HospitalPortalSnapshot._(
      hospital: hospital,
      doctors: doctors,
      assignedPatientEmails: assignedPatientEmails,
      linkedPatients: linkedPatients,
      treatedPatients: treatedPatients,
      patientsInCare: patientsInCare,
      watchlist: watchlist,
      recentTransfers: recentTransfers,
      sharedRecords: sharedRecords,
      openTasks: openTasks,
      needsFollowUpCount: linkedPatients
          .where((patient) => patientNeedsFollowUp(patient))
          .length,
      emergencyContactCount: linkedPatients
          .where((patient) => patient.profile.emergencyContacts.isNotEmpty)
          .length,
      unassignedPatientsCount: linkedPatients
          .where(
            (patient) => !assignedPatientEmails.contains(
              patient.profile.email.toLowerCase(),
            ),
          )
          .length,
      urgentPatientsCount: patientsInCare
          .where((patient) => patientPriorityLabel(patient) == 'Urgent')
          .length,
      totalAssignments: totalAssignments,
    );
  }
}

class HospitalPatientSummaryTile extends StatelessWidget {
  const HospitalPatientSummaryTile({
    super.key,
    required this.patient,
    required this.statusLabel,
    required this.statusColor,
    required this.subtitle,
    required this.facts,
    this.actions = const [],
  });

  final PatientSnapshot patient;
  final String statusLabel;
  final Color statusColor;
  final String subtitle;
  final List<String> facts;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patient.profile.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle),
                  ],
                ),
              ),
              StatusPill(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 10),
          ...facts.map(
            (fact) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(fact),
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 10, runSpacing: 10, children: actions),
          ],
        ],
      ),
    );
  }
}

class HospitalDoctorSummaryTile extends StatelessWidget {
  const HospitalDoctorSummaryTile({
    super.key,
    required this.doctor,
    required this.assignedPatients,
  });

  final UserAccount doctor;
  final List<PatientSnapshot> assignedPatients;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  doctor.fullName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              StatusPill(
                label: assignedPatients.length >= 4 ? 'High load' : 'Balanced',
                color: assignedPatients.length >= 4
                    ? const Color(0xFFEA580C)
                    : const Color(0xFF0F766E),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${doctor.specialty ?? 'General Medicine'} • ${doctor.email}'),
          const SizedBox(height: 12),
          if (assignedPatients.isEmpty)
            const Text('No assigned patients yet.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: assignedPatients
                  .map(
                    (patient) => StatusPill(
                      label: patient.profile.name,
                      color: const Color(0xFFDBEAFE),
                      foreground: const Color(0xFF1D4ED8),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class HospitalTransferTile extends StatelessWidget {
  const HospitalTransferTile({
    super.key,
    required this.patient,
    required this.record,
  });

  final PatientSnapshot patient;
  final HealthRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.folder_shared, color: Color(0xFF1D4ED8)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${patient.profile.name} • ${record.title}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.category} • ${formatDateTime(record.recordedAt)}',
                ),
                const SizedBox(height: 4),
                Text(record.summary),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class InlineEmptyState extends StatelessWidget {
  const InlineEmptyState({
    super.key,
    required this.title,
    required this.detail,
  });

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(detail),
        ],
      ),
    );
  }
}

bool patientNeedsFollowUp(PatientSnapshot patient) {
  return openTaskCount(patient) > 0 || averageAdherence(patient) < 80;
}

bool patientHasConsentForHospital(
  PatientSnapshot patient,
  String? hospitalName,
) {
  final source = sourceForHospital(patient, hospitalName);
  return source?.consentGranted == true;
}

int patientAttachmentCount(PatientSnapshot patient) {
  return patient.records.fold<int>(
    0,
    (sum, record) => sum + record.attachments.length,
  );
}

class HospitalPatientSnapshotSheet extends StatelessWidget {
  const HospitalPatientSnapshotSheet({super.key, required this.patientEmail});

  final String patientEmail;

  @override
  Widget build(BuildContext context) {
    final controller = AppStateScope.of(context);
    final patient = controller.findPatientByEmail(patientEmail);
    if (patient == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              patient.profile.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${patient.profile.memberId} • ${patient.profile.hospitalNetwork}',
            ),
            const SizedBox(height: 18),
            ResponsiveGrid(
              minTileWidth: 220,
              children: [
                ProfileFact(
                  label: 'Blood group',
                  value: patient.profile.bloodGroup,
                ),
                ProfileFact(label: 'Phone', value: patient.profile.phone),
                ProfileFact(
                  label: 'Emergency contact',
                  value: patient.profile.emergencyContacts.isEmpty
                      ? 'Not added'
                      : patient.profile.emergencyContacts.first,
                ),
                ProfileFact(
                  label: 'Average adherence',
                  value: '${averageAdherence(patient).round()}%',
                ),
              ],
            ),
            const SizedBox(height: 20),
            SectionCard(
              title: 'Open care tasks',
              subtitle:
                  'Tasks that may require hospital attention or follow-up.',
              child: Column(
                children: patient.tasks
                    .where((task) => !task.completed)
                    .map((task) => CareTaskTile(task: task))
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 20),
            SectionCard(
              title: 'Latest insights',
              subtitle:
                  'Recent clinical interpretation attached to this patient.',
              child: Column(
                children: patient.insights
                    .map((insight) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: insight.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: insight.color.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              insight.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(insight.detail),
                          ],
                        ),
                      );
                    })
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddHospitalDoctorSheet extends StatefulWidget {
  const AddHospitalDoctorSheet({super.key});

  @override
  State<AddHospitalDoctorSheet> createState() => _AddHospitalDoctorSheetState();
}

class _AddHospitalDoctorSheetState extends State<AddHospitalDoctorSheet> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _specialtyController = TextEditingController(text: 'General Medicine');
  final Set<String> _selectedPatientEmails = <String>{};
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppStateScope.of(context);
    final patients = controller.allPatients;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add hospital doctor',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Doctor name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Doctor email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _specialtyController,
              decoration: const InputDecoration(labelText: 'Specialty'),
            ),
            const SizedBox(height: 16),
            Text(
              'Assign patients',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: patients
                  .map((patient) {
                    final selected = _selectedPatientEmails.contains(
                      patient.profile.email,
                    );
                    return FilterChip(
                      label: Text(patient.profile.name),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _selectedPatientEmails.add(patient.profile.email);
                          } else {
                            _selectedPatientEmails.remove(
                              patient.profile.email,
                            );
                          }
                        });
                      },
                    );
                  })
                  .toList(growable: false),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Add doctor'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final controller = AppStateScope.of(context);
    setState(() => _saving = true);
    final message = await controller.addDoctorAsHospital(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      specialty: _specialtyController.text.trim(),
      assignedPatientEmails: _selectedPatientEmails.toList(growable: false),
    );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Doctor added. Default password: Doctor@123'),
      ),
    );
  }
}

class PatientProfileEditorSheet extends StatefulWidget {
  const PatientProfileEditorSheet({super.key, required this.profile});

  final PatientProfile profile;

  @override
  State<PatientProfileEditorSheet> createState() =>
      _PatientProfileEditorSheetState();
}

class _PatientProfileEditorSheetState extends State<PatientProfileEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _bloodGroupController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _emergencyContactsController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _bloodGroupController = TextEditingController(
      text: widget.profile.bloodGroup,
    );
    _phoneController = TextEditingController(text: widget.profile.phone);
    _addressController = TextEditingController(text: widget.profile.address);
    _allergiesController = TextEditingController(
      text: widget.profile.allergies.join(', '),
    );
    _emergencyContactsController = TextEditingController(
      text: widget.profile.emergencyContacts.join('\n'),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bloodGroupController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _allergiesController.dispose();
    _emergencyContactsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit personal details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bloodGroupController,
              decoration: const InputDecoration(labelText: 'Blood group'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _allergiesController,
              decoration: const InputDecoration(
                labelText: 'Allergies (comma separated)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emergencyContactsController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Emergency contacts (one per line)',
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save details'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final controller = AppStateScope.of(context);
    setState(() => _saving = true);
    final message = await controller.updateCurrentPatientProfile(
      name: _nameController.text.trim(),
      bloodGroup: _bloodGroupController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      allergies: _allergiesController.text.trim(),
      emergencyContacts: _emergencyContactsController.text
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(growable: false),
    );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Personal details updated.')));
  }
}

class AddPatientSheet extends StatefulWidget {
  const AddPatientSheet({super.key});

  @override
  State<AddPatientSheet> createState() => _AddPatientSheetState();
}

class _AddPatientSheetState extends State<AddPatientSheet> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _hospitalController = TextEditingController(
    text: 'Sree Buddha Medical Network',
  );
  final _bloodGroupController = TextEditingController(text: 'O+');
  final _emergencyContactController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _hospitalController.dispose();
    _bloodGroupController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add patient', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Create a patient profile and default portal account. New patients use the default password `Pass@123`.',
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Patient full name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Patient email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hospitalController,
              decoration: const InputDecoration(labelText: 'Hospital network'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bloodGroupController,
              decoration: const InputDecoration(labelText: 'Blood group'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emergencyContactController,
              decoration: const InputDecoration(labelText: 'Emergency contact'),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _saving ? null : _savePatient,
              child: Text(_saving ? 'Saving...' : 'Save patient'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePatient() async {
    final controller = AppStateScope.of(context);
    setState(() => _saving = true);
    final message = await controller.addPatientAsDoctor(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      hospitalNetwork: _hospitalController.text.trim(),
      bloodGroup: _bloodGroupController.text.trim(),
      emergencyContact: _emergencyContactController.text.trim(),
    );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Patient created successfully.')),
    );
  }
}

class ManageRecordsSheet extends StatelessWidget {
  const ManageRecordsSheet({super.key, required this.patientEmail});

  final String patientEmail;

  @override
  Widget build(BuildContext context) {
    final controller = AppStateScope.of(context);
    final patient = controller.findPatientByEmail(patientEmail);
    if (patient == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${patient.profile.name} records',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (context) =>
                          RecordEditorSheet(patientEmail: patientEmail),
                    );
                  },
                  icon: const Icon(Icons.note_add),
                  label: const Text('Add record'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Doctors can add new records or edit existing entries for this patient.',
            ),
            const SizedBox(height: 18),
            for (final record in patient.records) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              showDragHandle: true,
                              builder: (context) => RecordEditorSheet(
                                patientEmail: patientEmail,
                                existingRecord: record,
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                        ),
                        if (record.attachments.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          StatusPill(
                            label: '${record.attachments.length} image(s)',
                            color: const Color(0xFF0F766E),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${record.category} • ${record.source} • ${formatDate(record.recordedAt)}',
                    ),
                    const SizedBox(height: 8),
                    Text(record.summary),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class RecordEditorSheet extends StatefulWidget {
  const RecordEditorSheet({
    super.key,
    required this.patientEmail,
    this.existingRecord,
    this.initialSourceOverride,
  });

  final String patientEmail;
  final HealthRecord? existingRecord;
  final String? initialSourceOverride;

  @override
  State<RecordEditorSheet> createState() => _RecordEditorSheetState();
}

class _RecordEditorSheetState extends State<RecordEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _categoryController;
  late final TextEditingController _sourceController;
  late final TextEditingController _summaryController;
  late final TextEditingController _detailsController;
  late final TextEditingController _statusController;
  late final TextEditingController _standardController;
  late final TextEditingController _tagsController;
  late final List<RecordAttachment> _attachments;
  bool _saving = false;
  bool _pickingImage = false;

  @override
  void initState() {
    super.initState();
    final record = widget.existingRecord;
    _titleController = TextEditingController(text: record?.title ?? '');
    _categoryController = TextEditingController(
      text: record?.category ?? 'Visit Summary',
    );
    _sourceController = TextEditingController(
      text:
          record?.source ??
          widget.initialSourceOverride ??
          'Doctor Workstation',
    );
    _summaryController = TextEditingController(text: record?.summary ?? '');
    _detailsController = TextEditingController(text: record?.details ?? '');
    _statusController = TextEditingController(
      text: record?.status ?? 'Reviewed',
    );
    _standardController = TextEditingController(
      text: record?.standard ?? 'FHIR',
    );
    _tagsController = TextEditingController(
      text: record == null ? 'doctor-entry, updated' : record.tags.join(', '),
    );
    _attachments = [...?record?.attachments];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _sourceController.dispose();
    _summaryController.dispose();
    _detailsController.dispose();
    _statusController.dispose();
    _standardController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existingRecord == null
                  ? 'Add medical record'
                  : 'Edit medical record',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Record title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sourceController,
              decoration: const InputDecoration(labelText: 'Source system'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _statusController,
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _standardController,
              decoration: const InputDecoration(labelText: 'Standard'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _summaryController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Summary'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Details'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: _pickingImage ? null : _pickImage,
                  icon: _pickingImage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(
                    _pickingImage ? 'Uploading...' : 'Upload scan/image',
                  ),
                ),
                const SizedBox(width: 12),
                Text('${_attachments.length} attachment(s)'),
              ],
            ),
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachments.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final attachment = _attachments[index];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: 112,
                            child: Image.memory(
                              attachment.bytes,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: const Color(0xFFF1F5F9),
                                child: const Center(
                                  child: Icon(Icons.image_not_supported),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: InkWell(
                            onTap: () {
                              setState(() => _attachments.removeAt(index));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _saving ? null : _saveRecord,
              child: Text(_saving ? 'Saving...' : 'Save record'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRecord() async {
    final controller = AppStateScope.of(context);
    setState(() => _saving = true);
    final message = await controller.savePatientRecord(
      patientEmail: widget.patientEmail,
      existingRecord: widget.existingRecord,
      title: _titleController.text.trim(),
      category: _categoryController.text.trim(),
      source: _sourceController.text.trim(),
      summary: _summaryController.text.trim(),
      details: _detailsController.text.trim(),
      status: _statusController.text.trim(),
      standard: _standardController.text.trim(),
      tags: _tagsController.text.trim(),
      attachments: _attachments,
    );
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.existingRecord == null
              ? 'Medical record added.'
              : 'Medical record updated.',
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    setState(() => _pickingImage = true);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
    );
    if (!mounted) {
      return;
    }
    setState(() => _pickingImage = false);
    final files = result?.files;
    final file = files == null || files.isEmpty ? null : files.first;
    if (file == null || file.bytes == null) {
      return;
    }
    setState(() {
      _attachments.add(
        RecordAttachment(
          id: 'ATT-${DateTime.now().microsecondsSinceEpoch}',
          fileName: file.name,
          mimeType: _mimeTypeFor(file.extension),
          base64Data: base64Encode(file.bytes!),
        ),
      );
    });
  }

  String _mimeTypeFor(String? extension) {
    switch ((extension ?? '').toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        return 'application/octet-stream';
    }
  }
}

class HeroPanel extends StatelessWidget {
  const HeroPanel({super.key, required this.patient});

  final PatientSnapshot patient;

  @override
  Widget build(BuildContext context) {
    final nextTask = patient.tasks.firstWhere(
      (task) => !task.completed,
      orElse: () => patient.tasks.first,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F766E), Color(0xFF14B8A6), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PATIENT DASHBOARD',
            style: TextStyle(
              color: Colors.white70,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome back, ${patient.profile.name.split(' ').first}.',
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            'All medical records are available in one place, with interoperability services connecting ${patient.sources.length} healthcare systems.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: const Color(0xFFE0F2FE)),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              StatusPill(
                label: 'Next action: ${nextTask.title}',
                color: const Color(0xFF0F172A),
                foreground: Colors.white,
              ),
              StatusPill(
                label: 'Vault status: encrypted',
                color: const Color(0xFF134E4A),
                foreground: Colors.white,
              ),
              StatusPill(
                label: 'Standards: FHIR • HL7 • JSON',
                color: const Color(0xFF1E3A8A),
                foreground: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(subtitle),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.minTileWidth,
    required this.children,
  });

  final double minTileWidth;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const spacing = 16.0;
        final count = math.max(1, (width / minTileWidth).floor());
        final tileWidth = (width - (math.max(0, count - 1) * spacing)) / count;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) {
                return SizedBox(width: tileWidth, child: child);
              })
              .toList(growable: false),
        );
      },
    );
  }
}

class SummaryStat {
  const SummaryStat({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.stat});

  final SummaryStat stat;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: stat.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(stat.icon, color: stat.accent),
            ),
            const SizedBox(height: 16),
            Text(stat.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              stat.value,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontSize: 34),
            ),
            const SizedBox(height: 8),
            Text(stat.subtitle),
          ],
        ),
      ),
    );
  }
}

class CareTaskTile extends StatelessWidget {
  const CareTaskTile({super.key, required this.task});

  final CareTask task;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: task.completed
                  ? const Color(0xFF0F766E)
                  : const Color(0xFFEA580C),
              shape: BoxShape.circle,
            ),
            child: task.completed
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(task.detail),
                const SizedBox(height: 6),
                Text(
                  'Due ${formatDate(task.dueDate)} • ${task.priority}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RecordPreview extends StatelessWidget {
  const RecordPreview({super.key, required this.record});

  final HealthRecord record;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(record.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('${record.source} • ${formatDate(record.recordedAt)}'),
            const SizedBox(height: 10),
            Text(record.summary),
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.foreground,
  });

  final String label;
  final Color color;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = foreground == null
        ? color.withValues(alpha: 0.12)
        : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground ?? color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SecurityLine extends StatelessWidget {
  const SecurityLine({super.key, required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF0F766E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(detail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileFact extends StatelessWidget {
  const ProfileFact({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(value),
        ],
      ),
    );
  }
}

class TrendChartPainter extends CustomPainter {
  TrendChartPainter({required this.series});

  final TrendSeries series;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final grid = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    final line = Paint()
      ..color = series.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = series.color;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(24),
    );
    canvas.drawRRect(rect, background);
    canvas.drawRRect(rect, border);

    const padding = EdgeInsets.fromLTRB(20, 20, 20, 28);
    final chartRect = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.left - padding.right,
      size.height - padding.top - padding.bottom,
    );

    for (var i = 0; i < 4; i++) {
      final dy = chartRect.top + (chartRect.height / 3) * i;
      canvas.drawLine(
        Offset(chartRect.left, dy),
        Offset(chartRect.right, dy),
        grid,
      );
    }

    final values = series.points
        .map((point) => point.value)
        .toList(growable: false);
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final spread = math.max(1, maxValue - minValue);

    final path = Path();
    for (var i = 0; i < series.points.length; i++) {
      final point = series.points[i];
      final dx =
          chartRect.left +
          (chartRect.width / math.max(1, series.points.length - 1)) * i;
      final normalized = (point.value - minValue) / spread;
      final dy = chartRect.bottom - (chartRect.height * normalized);
      if (i == 0) {
        path.moveTo(dx, dy);
      } else {
        path.lineTo(dx, dy);
      }
      canvas.drawCircle(Offset(dx, dy), 4.5, dot);

      final labelPainter = TextPainter(
        text: TextSpan(
          text: point.label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(
        canvas,
        Offset(dx - labelPainter.width / 2, chartRect.bottom + 8),
      );
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant TrendChartPainter oldDelegate) {
    return oldDelegate.series != series;
  }
}

class NearbyHospitalsMap extends StatelessWidget {
  const NearbyHospitalsMap({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppStateScope.of(context);
    final patient = controller.patientSnapshot;
    if (patient == null) {
      return const SizedBox.shrink();
    }
    final supportsGoogleMap =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!supportsGoogleMap) {
      return CustomPaint(
        painter: NearbyHospitalsMapPainter(sources: patient.sources),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
        ),
      );
    }
    final markers = <Marker>{
      const Marker(
        markerId: MarkerId('patient-home'),
        position: LatLng(patientHomeLatitude, patientHomeLongitude),
        infoWindow: InfoWindow(title: 'Your saved area'),
      ),
      ...patient.sources.map(
        (source) => Marker(
          markerId: MarkerId(source.id),
          position: LatLng(source.latitude, source.longitude),
          infoWindow: InfoWindow(
            title: source.name,
            snippet:
                '${source.type} • ${distanceFromPatient(source).toStringAsFixed(1)} km away',
          ),
        ),
      ),
    };
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(patientHomeLatitude, patientHomeLongitude),
          zoom: 14,
        ),
        markers: markers,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
      ),
    );
  }
}

class NearbyHospitalsMapPainter extends CustomPainter {
  NearbyHospitalsMapPainter({required this.sources});

  final List<ConnectedSource> sources;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(24),
    );
    canvas.drawRRect(rect, Paint()..color = const Color(0xFFE0F2FE));

    final roadPaint = Paint()
      ..color = const Color(0xFFBFDBFE)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.25),
      Offset(size.width * 0.92, size.height * 0.75),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.12, size.height * 0.82),
      Offset(size.width * 0.84, size.height * 0.18),
      roadPaint,
    );

    final patientPoint = Offset(size.width * 0.5, size.height * 0.56);
    canvas.drawCircle(
      patientPoint,
      12,
      Paint()..color = const Color(0xFF0F766E),
    );

    for (final source in sources) {
      final offset = projectSourceToMap(source, size);
      canvas.drawCircle(
        offset,
        10,
        Paint()
          ..color = source.type == 'Hospital'
              ? const Color(0xFFDC2626)
              : const Color(0xFF1D4ED8),
      );
      final labelPainter = TextPainter(
        text: TextSpan(
          text: source.name,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 96);
      labelPainter.paint(canvas, Offset(offset.dx - 10, offset.dy + 12));
    }
  }

  @override
  bool shouldRepaint(covariant NearbyHospitalsMapPainter oldDelegate) {
    return oldDelegate.sources != sources;
  }
}

class HealthAppController extends ChangeNotifier {
  HealthAppController._({
    required Map<String, UserAccount> usersByEmail,
    required Map<String, PatientSnapshot> patientsByEmail,
    required MediBridgeStore store,
  }) : _usersByEmail = usersByEmail,
       _patientsByEmail = patientsByEmail,
       _store = store;

  static Future<HealthAppController> createPersistent() async {
    final store = SharedPreferencesMediBridgeStore();
    final seeded = buildSeedDatabase();
    final snapshot = await store.loadOrSeed(seeded);
    return HealthAppController._(
      usersByEmail: snapshot.usersByEmail,
      patientsByEmail: snapshot.patientsByEmail,
      store: store,
    );
  }

  factory HealthAppController.seeded() {
    final seeded = buildSeedDatabase();
    return HealthAppController._(
      usersByEmail: seeded.usersByEmail,
      patientsByEmail: seeded.patientsByEmail,
      store: MemoryMediBridgeStore(),
    );
  }

  final Map<String, UserAccount> _usersByEmail;
  final Map<String, PatientSnapshot> _patientsByEmail;
  final MediBridgeStore _store;
  final Set<String> _syncingSourceIds = <String>{};
  final Map<String, Timer> _activeRealtimeTransfers = <String, Timer>{};
  final Map<String, DateTime> _realtimeTransferTouchedAt = <String, DateTime>{};
  UserAccount? _currentAccount;

  UserAccount? get currentAccount => _currentAccount;
  bool get isDoctor => _currentAccount?.role == AccountRole.doctor;
  bool get isHospital => _currentAccount?.role == AccountRole.hospital;
  bool get isProvider => isDoctor || isHospital;

  PatientSnapshot? get patientSnapshot {
    if (_currentAccount?.role != AccountRole.patient) {
      return null;
    }
    final email = _currentAccount?.patientEmail;
    if (email == null) {
      return null;
    }
    return _patientsByEmail[email];
  }

  List<PatientSnapshot> get allPatients {
    final patients = _patientsByEmail.values.toList();
    patients.sort((a, b) => a.profile.name.compareTo(b.profile.name));
    return patients;
  }

  List<AuditEventView> get doctorAuditFeed {
    final items = <AuditEventView>[];
    for (final patient in _patientsByEmail.values) {
      for (final event in patient.auditTrail) {
        items.add(
          AuditEventView(patientName: patient.profile.name, event: event),
        );
      }
    }
    items.sort((a, b) => b.event.timestamp.compareTo(a.event.timestamp));
    return items.take(16).toList(growable: false);
  }

  Set<String> get syncingSourceIds => Set.unmodifiable(_syncingSourceIds);

  Future<String?> login(
    String email,
    String password, {
    required AccountRole role,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final user = _usersByEmail[email.toLowerCase()];
    if (user == null || user.password != password || user.role != role) {
      return 'Invalid credentials for the selected role.';
    }
    _currentAccount = user;
    if (user.role == AccountRole.patient && user.patientEmail != null) {
      _appendAudit(
        user.patientEmail!,
        AuditEvent(
          title: 'Patient session opened',
          actor: user.fullName,
          detail: 'Authenticated through the secure portal.',
          timestamp: DateTime.now(),
          severityColor: const Color(0xFF0F766E),
          icon: Icons.login,
        ),
      );
      await _persist();
    }
    notifyListeners();
    return null;
  }

  Future<String?> register({
    required String fullName,
    required String email,
    required String password,
    required String hospitalNetwork,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (fullName.isEmpty ||
        email.isEmpty ||
        password.length < 6 ||
        hospitalNetwork.isEmpty) {
      return 'Provide a name, email, hospital network, and a password with at least 6 characters.';
    }
    final normalizedEmail = email.toLowerCase();
    if (_usersByEmail.containsKey(normalizedEmail)) {
      return 'An account with that email already exists.';
    }

    final profile = PatientProfile(
      email: normalizedEmail,
      name: fullName,
      memberId: 'MB-${1000 + _usersByEmail.length}',
      bloodGroup: 'B+',
      hospitalNetwork: hospitalNetwork,
      phone: '+91 90000 00000',
      address: 'Address not added yet',
      allergies: const ['Penicillin'],
      emergencyContact: 'Emergency Contact • +91 98765 43210',
      emergencyContacts: const ['Emergency Contact • +91 98765 43210'],
    );
    final patient = buildNewPatient(profile);
    final account = UserAccount(
      email: normalizedEmail,
      password: password,
      fullName: fullName,
      role: AccountRole.patient,
      patientEmail: normalizedEmail,
    );
    _usersByEmail[normalizedEmail] = account;
    _patientsByEmail[normalizedEmail] = patient;
    _currentAccount = account;
    _appendAudit(
      normalizedEmail,
      AuditEvent(
        title: 'Patient account registered',
        actor: fullName,
        detail:
            'A new portal account and encrypted record vault were provisioned.',
        timestamp: DateTime.now(),
        severityColor: const Color(0xFF1D4ED8),
        icon: Icons.person_add_alt_1,
      ),
    );
    await _persist();
    notifyListeners();
    return null;
  }

  void logout() {
    _currentAccount = null;
    notifyListeners();
  }

  Future<String?> addPatientAsDoctor({
    required String fullName,
    required String email,
    required String hospitalNetwork,
    required String bloodGroup,
    required String emergencyContact,
  }) async {
    if (!isDoctor) {
      return 'Only doctor accounts can add patients.';
    }
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final normalizedEmail = email.toLowerCase();
    if (fullName.isEmpty ||
        normalizedEmail.isEmpty ||
        hospitalNetwork.isEmpty ||
        bloodGroup.isEmpty ||
        emergencyContact.isEmpty) {
      return 'Fill in all patient fields before saving.';
    }
    if (_usersByEmail.containsKey(normalizedEmail)) {
      return 'An account with that email already exists.';
    }

    final profile = PatientProfile(
      email: normalizedEmail,
      name: fullName,
      memberId: 'MB-${1000 + _patientsByEmail.length}',
      bloodGroup: bloodGroup,
      hospitalNetwork: hospitalNetwork,
      phone: '+91 90000 00000',
      address: 'Address not added yet',
      allergies: const ['Not provided'],
      emergencyContact: emergencyContact,
      emergencyContacts: [emergencyContact],
    );
    final patient = buildNewPatient(profile);
    final account = UserAccount(
      email: normalizedEmail,
      password: 'Pass@123',
      fullName: fullName,
      role: AccountRole.patient,
      patientEmail: normalizedEmail,
    );
    _usersByEmail[normalizedEmail] = account;
    _patientsByEmail[normalizedEmail] = patient;
    _appendAudit(
      normalizedEmail,
      AuditEvent(
        title: 'Patient added by doctor',
        actor: _currentAccount!.fullName,
        detail:
            'A doctor created the patient profile and initialized the secure record vault.',
        timestamp: DateTime.now(),
        severityColor: const Color(0xFF1D4ED8),
        icon: Icons.person_add_alt_1,
      ),
    );
    await _persist();
    notifyListeners();
    return null;
  }

  Future<String?> savePatientRecord({
    required String patientEmail,
    required HealthRecord? existingRecord,
    required String title,
    required String category,
    required String source,
    required String summary,
    required String details,
    required String status,
    required String standard,
    required String tags,
    List<RecordAttachment>? attachments,
  }) async {
    if (!isProvider) {
      return 'Only doctor or hospital accounts can modify records.';
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final normalizedEmail = patientEmail.toLowerCase();
    final patient = _patientsByEmail[normalizedEmail];
    if (patient == null) {
      return 'Patient not found.';
    }
    if (title.isEmpty ||
        category.isEmpty ||
        source.isEmpty ||
        summary.isEmpty ||
        details.isEmpty ||
        status.isEmpty ||
        standard.isEmpty) {
      return 'Complete all record fields before saving.';
    }

    final newRecord = HealthRecord(
      title: title,
      category: category,
      source: source,
      summary: summary,
      details: details,
      status: status,
      standard: standard,
      secureId:
          existingRecord?.secureId ??
          'ENC-${DateTime.now().millisecondsSinceEpoch}',
      recordedAt: DateTime.now(),
      tags: tags
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(growable: false),
      attachments: attachments ?? existingRecord?.attachments ?? const [],
    );

    final records = [...patient.records];
    if (existingRecord == null) {
      records.insert(0, newRecord);
    } else {
      final index = records.indexWhere(
        (record) => record.secureId == existingRecord.secureId,
      );
      if (index == -1) {
        records.insert(0, newRecord);
      } else {
        records[index] = newRecord;
      }
    }

    var matchedSource = false;
    final sources = patient.sources.map((item) {
      if (item.name != source) {
        return item;
      }
      matchedSource = true;
      return item.copyWith(
        recordsAvailable:
            item.recordsAvailable + (existingRecord == null ? 1 : 0),
        lastSync: DateTime.now(),
        status: 'Connected',
        standard: standard,
      );
    }).toList();
    if (!matchedSource) {
      sources.add(
        ConnectedSource(
          id: slugify(source),
          name: source,
          type: 'Hospital',
          status: 'Connected',
          standard: standard,
          recordsAvailable: 1,
          consentGranted: true,
          lastSync: DateTime.now(),
          latitude: 9.5916,
          longitude: 76.5222,
        ),
      );
    }

    _patientsByEmail[normalizedEmail] = patient.copyWith(
      records: records,
      sources: sources,
      lastGlobalSync: DateTime.now(),
    );
    _appendAudit(
      normalizedEmail,
      AuditEvent(
        title: existingRecord == null
            ? 'Record added by doctor'
            : 'Record updated by doctor',
        actor: _currentAccount!.fullName,
        detail: existingRecord == null
            ? 'A new $category entry was added to the patient vault.'
            : 'The $category entry "$title" was updated by the provider.',
        timestamp: DateTime.now(),
        severityColor: const Color(0xFF7C3AED),
        icon: existingRecord == null ? Icons.note_add : Icons.edit_note,
      ),
    );
    await _persist();
    notifyListeners();
    return null;
  }

  Future<String?> deletePatientAsDoctor(String patientEmail) async {
    if (!isDoctor) {
      return 'Only doctor accounts can delete patients.';
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final normalizedEmail = patientEmail.toLowerCase();
    if (!_patientsByEmail.containsKey(normalizedEmail)) {
      return 'Patient not found.';
    }
    _patientsByEmail.remove(normalizedEmail);
    _usersByEmail.remove(normalizedEmail);
    await _persist();
    notifyListeners();
    return null;
  }

  Future<String?> sharePatientDataWithHospital({
    required String sourceId,
  }) async {
    final email = _currentAccount?.patientEmail;
    if (email == null) {
      return 'Only patients can share data from this view.';
    }
    final patient = _patientsByEmail[email];
    if (patient == null) {
      return 'Patient not found.';
    }
    var found = false;
    final updatedSources = patient.sources
        .map((source) {
          if (source.id != sourceId) {
            return source;
          }
          found = true;
          return source.copyWith(
            consentGranted: true,
            status: 'Shared',
            lastSync: DateTime.now(),
          );
        })
        .toList(growable: false);
    if (!found) {
      return 'Hospital not found.';
    }
    _patientsByEmail[email] = patient.copyWith(
      sources: updatedSources,
      lastGlobalSync: DateTime.now(),
    );
    _appendAudit(
      email,
      AuditEvent(
        title: 'Patient shared data with hospital',
        actor: patient.profile.name,
        detail: 'The patient enabled record sharing for $sourceId.',
        timestamp: DateTime.now(),
        severityColor: const Color(0xFF0F766E),
        icon: Icons.share,
      ),
    );
    await _persist();
    notifyListeners();
    return null;
  }

  Future<String?> updateCurrentPatientProfile({
    required String name,
    required String bloodGroup,
    required String phone,
    required String address,
    required String allergies,
    required List<String> emergencyContacts,
  }) async {
    final email = _currentAccount?.patientEmail;
    if (email == null) {
      return 'Only patients can edit this profile.';
    }
    final patient = _patientsByEmail[email];
    if (patient == null) {
      return 'Patient not found.';
    }
    if (name.isEmpty ||
        bloodGroup.isEmpty ||
        phone.isEmpty ||
        address.isEmpty) {
      return 'Complete the required personal details.';
    }
    final parsedAllergies = allergies
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final cleanContacts = emergencyContacts
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final updatedProfile = patient.profile.copyWith(
      name: name,
      bloodGroup: bloodGroup,
      phone: phone,
      address: address,
      allergies: parsedAllergies.isEmpty
          ? const ['None added']
          : parsedAllergies,
      emergencyContact: cleanContacts.isNotEmpty
          ? cleanContacts.first
          : patient.profile.emergencyContact,
      emergencyContacts: cleanContacts,
    );
    _patientsByEmail[email] = patient.copyWith(profile: updatedProfile);
    final account = _usersByEmail[email];
    if (account != null) {
      _usersByEmail[email] = account.copyWith(fullName: name);
    }
    _appendAudit(
      email,
      AuditEvent(
        title: 'Patient profile updated',
        actor: name,
        detail: 'Personal details and emergency contacts were updated.',
        timestamp: DateTime.now(),
        severityColor: const Color(0xFF1D4ED8),
        icon: Icons.manage_accounts,
      ),
    );
    await _persist();
    notifyListeners();
    return null;
  }

  List<UserAccount> get hospitalDoctors {
    final hospitalName = _currentAccount?.hospitalNetwork;
    return _usersByEmail.values
        .where(
          (user) =>
              user.role == AccountRole.doctor &&
              user.hospitalNetwork == hospitalName,
        )
        .toList(growable: false);
  }

  bool isRealtimeTransferActive(String patientEmail) {
    return _activeRealtimeTransfers.containsKey(patientEmail.toLowerCase());
  }

  String realtimeTransferStatus(String patientEmail) {
    final normalizedEmail = patientEmail.toLowerCase();
    if (!_activeRealtimeTransfers.containsKey(normalizedEmail)) {
      return 'Offline';
    }
    final lastTouched = _realtimeTransferTouchedAt[normalizedEmail];
    if (lastTouched == null) {
      return 'Connecting...';
    }
    return 'Live • last packet ${formatDateTime(lastTouched)}';
  }

  Future<String?> registerDoctor({
    required String fullName,
    required String email,
    required String password,
    required String hospitalNetwork,
    required String specialty,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final normalizedEmail = email.toLowerCase();
    if (fullName.isEmpty ||
        normalizedEmail.isEmpty ||
        password.length < 6 ||
        hospitalNetwork.isEmpty ||
        specialty.isEmpty) {
      return 'Provide name, email, password, hospital, and specialty.';
    }
    if (_usersByEmail.containsKey(normalizedEmail)) {
      return 'An account with that email already exists.';
    }
    _usersByEmail[normalizedEmail] = UserAccount(
      email: normalizedEmail,
      password: password,
      fullName: fullName,
      role: AccountRole.doctor,
      hospitalNetwork: hospitalNetwork,
      specialty: specialty,
    );
    _currentAccount = _usersByEmail[normalizedEmail];
    await _persist();
    notifyListeners();
    return null;
  }

  Future<String?> registerHospital({
    required String portalName,
    required String email,
    required String password,
    required String hospitalNetwork,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final normalizedEmail = email.toLowerCase();
    if (portalName.isEmpty ||
        normalizedEmail.isEmpty ||
        password.length < 6 ||
        hospitalNetwork.isEmpty) {
      return 'Provide portal name, email, password, and hospital name.';
    }
    if (_usersByEmail.containsKey(normalizedEmail)) {
      return 'An account with that email already exists.';
    }
    _usersByEmail[normalizedEmail] = UserAccount(
      email: normalizedEmail,
      password: password,
      fullName: portalName,
      role: AccountRole.hospital,
      hospitalNetwork: hospitalNetwork,
      specialty: 'Records Portal',
    );
    _currentAccount = _usersByEmail[normalizedEmail];
    await _persist();
    notifyListeners();
    return null;
  }

  Future<String?> addDoctorAsHospital({
    required String fullName,
    required String email,
    required String specialty,
    required List<String> assignedPatientEmails,
  }) async {
    if (!isHospital) {
      return 'Only hospital accounts can add doctors here.';
    }
    final normalizedEmail = email.toLowerCase();
    if (fullName.isEmpty || normalizedEmail.isEmpty || specialty.isEmpty) {
      return 'Provide doctor name, email, and specialty.';
    }
    if (_usersByEmail.containsKey(normalizedEmail)) {
      return 'An account with that email already exists.';
    }
    _usersByEmail[normalizedEmail] = UserAccount(
      email: normalizedEmail,
      password: 'Doctor@123',
      fullName: fullName,
      role: AccountRole.doctor,
      hospitalNetwork: _currentAccount!.hospitalNetwork,
      specialty: specialty,
      assignedPatientEmails: assignedPatientEmails,
    );
    await _persist();
    notifyListeners();
    return null;
  }

  Future<String?> startRealtimeTransfer(String patientEmail) async {
    if (!isHospital) {
      return 'Only hospital accounts can start realtime transfers.';
    }
    final normalizedEmail = patientEmail.toLowerCase();
    final patient = _patientsByEmail[normalizedEmail];
    if (patient == null) {
      return 'Patient not found.';
    }
    if (_activeRealtimeTransfers.containsKey(normalizedEmail)) {
      return null;
    }
    _realtimeTransferTouchedAt[normalizedEmail] = DateTime.now();
    _activeRealtimeTransfers[normalizedEmail] = Timer.periodic(
      const Duration(seconds: 4),
      (_) {
        _realtimeTransferTouchedAt[normalizedEmail] = DateTime.now();
        _markHospitalSourceStreaming(normalizedEmail);
        notifyListeners();
      },
    );
    _appendAudit(
      normalizedEmail,
      AuditEvent(
        title: 'Realtime transfer started',
        actor: _currentAccount!.fullName,
        detail: 'Hospital live transfer channel is now streaming patient data.',
        timestamp: DateTime.now(),
        severityColor: const Color(0xFF0F766E),
        icon: Icons.wifi_tethering,
      ),
    );
    await _persist();
    notifyListeners();
    return null;
  }

  Future<void> stopRealtimeTransfer(String patientEmail) async {
    final normalizedEmail = patientEmail.toLowerCase();
    _activeRealtimeTransfers.remove(normalizedEmail)?.cancel();
    _realtimeTransferTouchedAt.remove(normalizedEmail);
    _markHospitalSourceConnected(normalizedEmail);
    if (_patientsByEmail.containsKey(normalizedEmail)) {
      _appendAudit(
        normalizedEmail,
        AuditEvent(
          title: 'Realtime transfer stopped',
          actor: _currentAccount?.fullName ?? 'Hospital Portal',
          detail: 'Hospital live transfer channel was stopped.',
          timestamp: DateTime.now(),
          severityColor: const Color(0xFFEA580C),
          icon: Icons.portable_wifi_off,
        ),
      );
      await _persist();
    }
    notifyListeners();
  }

  Future<String?> sendRealtimeTransferPacket(String patientEmail) async {
    if (!isHospital) {
      return 'Only hospital accounts can send realtime packets.';
    }
    final patient = _patientsByEmail[patientEmail.toLowerCase()];
    if (patient == null) {
      return 'Patient not found.';
    }
    _realtimeTransferTouchedAt[patientEmail.toLowerCase()] = DateTime.now();
    _markHospitalSourceStreaming(patientEmail.toLowerCase());
    final hospitalSource =
        _currentAccount!.hospitalNetwork ?? 'Hospital Portal';
    final packetTime = DateTime.now();
    final records = [
      HealthRecord(
        title: 'Realtime monitoring packet',
        category: 'Live Feed',
        source: hospitalSource,
        summary:
            'Live vitals and telemetry packet pushed from hospital portal.',
        details:
            'Realtime packet delivered at ${formatDateTime(packetTime)} with updated bedside monitoring values.',
        status: 'Streaming',
        standard: 'FHIR',
        secureId: 'ENC-RT-${packetTime.millisecondsSinceEpoch}',
        recordedAt: packetTime,
        tags: const ['realtime', 'telemetry', 'hospital-stream'],
        attachments: const [],
      ),
      ...patient.records,
    ];
    _patientsByEmail[patientEmail.toLowerCase()] = patient.copyWith(
      records: records,
      lastGlobalSync: packetTime,
    );
    _appendAudit(
      patientEmail.toLowerCase(),
      AuditEvent(
        title: 'Realtime packet delivered',
        actor: _currentAccount!.fullName,
        detail:
            'A live monitoring packet was delivered from the hospital portal.',
        timestamp: packetTime,
        severityColor: const Color(0xFF1D4ED8),
        icon: Icons.monitor_heart,
      ),
    );
    await _persist();
    notifyListeners();
    return null;
  }

  void _markHospitalSourceStreaming(String patientEmail) {
    final patient = _patientsByEmail[patientEmail];
    if (patient == null) {
      return;
    }
    final hospitalName = _currentAccount?.hospitalNetwork;
    if (hospitalName == null) {
      return;
    }
    final updatedSources = patient.sources
        .map((source) {
          if (source.name != hospitalName) {
            return source;
          }
          return source.copyWith(
            status: 'Streaming',
            lastSync: DateTime.now(),
            consentGranted: true,
          );
        })
        .toList(growable: false);
    _patientsByEmail[patientEmail] = patient.copyWith(
      sources: updatedSources,
      lastGlobalSync: DateTime.now(),
    );
  }

  void _markHospitalSourceConnected(String patientEmail) {
    final patient = _patientsByEmail[patientEmail];
    if (patient == null) {
      return;
    }
    final hospitalName = _currentAccount?.hospitalNetwork;
    if (hospitalName == null) {
      return;
    }
    final updatedSources = patient.sources
        .map((source) {
          if (source.name != hospitalName) {
            return source;
          }
          return source.copyWith(status: 'Connected', lastSync: DateTime.now());
        })
        .toList(growable: false);
    _patientsByEmail[patientEmail] = patient.copyWith(
      sources: updatedSources,
      lastGlobalSync: DateTime.now(),
    );
  }

  PatientSnapshot? findPatientByEmail(String patientEmail) {
    return _patientsByEmail[patientEmail.toLowerCase()];
  }

  void toggleConsent(String sourceId, bool enabled) {
    final email = _currentAccount?.patientEmail;
    if (email == null) {
      return;
    }
    final patient = _patientsByEmail[email];
    if (patient == null) {
      return;
    }
    final updatedSources = patient.sources
        .map((source) {
          if (source.id != sourceId) {
            return source;
          }
          return source.copyWith(consentGranted: enabled);
        })
        .toList(growable: false);
    _patientsByEmail[email] = patient.copyWith(sources: updatedSources);
    _appendAudit(
      email,
      AuditEvent(
        title: enabled ? 'Consent granted' : 'Consent revoked',
        actor: patient.profile.name,
        detail: enabled
            ? 'Patient enabled data sharing for $sourceId.'
            : 'Patient disabled data sharing for $sourceId.',
        timestamp: DateTime.now(),
        severityColor: enabled
            ? const Color(0xFF0F766E)
            : const Color(0xFFEA580C),
        icon: enabled ? Icons.verified : Icons.block,
      ),
    );
    _persistSilently();
    notifyListeners();
  }

  Future<void> syncSource(String sourceId) async {
    final email = _currentAccount?.patientEmail;
    if (email == null) {
      return;
    }
    final patient = _patientsByEmail[email];
    if (patient == null) {
      return;
    }
    _syncingSourceIds.add(sourceId);
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final now = DateTime.now();
    final updatedSources = patient.sources
        .map((source) {
          if (source.id != sourceId) {
            return source;
          }
          return source.copyWith(lastSync: now, status: 'Connected');
        })
        .toList(growable: false);
    _patientsByEmail[email] = patient.copyWith(
      lastGlobalSync: now,
      sources: updatedSources,
    );
    _appendAudit(
      email,
      AuditEvent(
        title: 'Interoperability sync completed',
        actor: 'Medifix API Gateway',
        detail:
            'RESTful exchange finished for $sourceId with encrypted payload delivery.',
        timestamp: now,
        severityColor: const Color(0xFF0F766E),
        icon: Icons.sync,
      ),
    );
    await _persist();
    _syncingSourceIds.remove(sourceId);
    notifyListeners();
  }

  void _appendAudit(String patientEmail, AuditEvent event) {
    final patient = _patientsByEmail[patientEmail];
    if (patient == null) {
      return;
    }
    _patientsByEmail[patientEmail] = patient.copyWith(
      auditTrail: [
        event,
        ...patient.auditTrail,
      ].take(8).toList(growable: false),
    );
  }

  Future<void> _persist() {
    return _store.save(
      AppDatabaseSnapshot(
        usersByEmail: _usersByEmail,
        patientsByEmail: _patientsByEmail,
      ),
    );
  }

  void _persistSilently() {
    _persist();
  }

  @override
  void dispose() {
    for (final timer in _activeRealtimeTransfers.values) {
      timer.cancel();
    }
    _activeRealtimeTransfers.clear();
    super.dispose();
  }
}

class UserAccount {
  const UserAccount({
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
    this.patientEmail,
    this.hospitalNetwork,
    this.specialty,
    this.assignedPatientEmails = const [],
  });

  final String email;
  final String password;
  final String fullName;
  final AccountRole role;
  final String? patientEmail;
  final String? hospitalNetwork;
  final String? specialty;
  final List<String> assignedPatientEmails;

  UserAccount copyWith({
    String? email,
    String? password,
    String? fullName,
    AccountRole? role,
    String? patientEmail,
    String? hospitalNetwork,
    String? specialty,
    List<String>? assignedPatientEmails,
  }) {
    return UserAccount(
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      patientEmail: patientEmail ?? this.patientEmail,
      hospitalNetwork: hospitalNetwork ?? this.hospitalNetwork,
      specialty: specialty ?? this.specialty,
      assignedPatientEmails:
          assignedPatientEmails ?? this.assignedPatientEmails,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'email': email,
      'password': password,
      'fullName': fullName,
      'role': role.name,
      'patientEmail': patientEmail,
      'hospitalNetwork': hospitalNetwork,
      'specialty': specialty,
      'assignedPatientEmails': assignedPatientEmails,
    };
  }

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      email: map['email'] as String,
      password: map['password'] as String,
      fullName: map['fullName'] as String,
      role: AccountRole.values.byName(map['role'] as String),
      patientEmail: map['patientEmail'] as String?,
      hospitalNetwork: map['hospitalNetwork'] as String?,
      specialty: map['specialty'] as String?,
      assignedPatientEmails:
          ((map['assignedPatientEmails'] as List<dynamic>?) ?? const [])
              .map((item) => item as String)
              .toList(growable: false),
    );
  }
}

class AuditEventView {
  const AuditEventView({required this.patientName, required this.event});

  final String patientName;
  final AuditEvent event;
}

class PatientSnapshot {
  const PatientSnapshot({
    required this.profile,
    required this.records,
    required this.trends,
    required this.sources,
    required this.auditTrail,
    required this.tasks,
    required this.adherence,
    required this.insights,
    required this.lastGlobalSync,
  });

  final PatientProfile profile;
  final List<HealthRecord> records;
  final List<TrendSeries> trends;
  final List<ConnectedSource> sources;
  final List<AuditEvent> auditTrail;
  final List<CareTask> tasks;
  final List<AdherenceMetric> adherence;
  final List<ClinicalInsight> insights;
  final DateTime lastGlobalSync;

  PatientSnapshot copyWith({
    PatientProfile? profile,
    List<HealthRecord>? records,
    List<TrendSeries>? trends,
    List<ConnectedSource>? sources,
    List<AuditEvent>? auditTrail,
    List<CareTask>? tasks,
    List<AdherenceMetric>? adherence,
    List<ClinicalInsight>? insights,
    DateTime? lastGlobalSync,
  }) {
    return PatientSnapshot(
      profile: profile ?? this.profile,
      records: records ?? this.records,
      trends: trends ?? this.trends,
      sources: sources ?? this.sources,
      auditTrail: auditTrail ?? this.auditTrail,
      tasks: tasks ?? this.tasks,
      adherence: adherence ?? this.adherence,
      insights: insights ?? this.insights,
      lastGlobalSync: lastGlobalSync ?? this.lastGlobalSync,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'profile': profile.toMap(),
      'records': records
          .map((record) => record.toMap())
          .toList(growable: false),
      'trends': trends.map((trend) => trend.toMap()).toList(growable: false),
      'sources': sources
          .map((source) => source.toMap())
          .toList(growable: false),
      'auditTrail': auditTrail
          .map((event) => event.toMap())
          .toList(growable: false),
      'tasks': tasks.map((task) => task.toMap()).toList(growable: false),
      'adherence': adherence
          .map((item) => item.toMap())
          .toList(growable: false),
      'insights': insights.map((item) => item.toMap()).toList(growable: false),
      'lastGlobalSync': lastGlobalSync.toIso8601String(),
    };
  }

  factory PatientSnapshot.fromMap(Map<String, dynamic> map) {
    return PatientSnapshot(
      profile: PatientProfile.fromMap(map['profile'] as Map<String, dynamic>),
      records: (map['records'] as List<dynamic>)
          .map((item) => HealthRecord.fromMap(item as Map<String, dynamic>))
          .toList(growable: false),
      trends: (map['trends'] as List<dynamic>)
          .map((item) => TrendSeries.fromMap(item as Map<String, dynamic>))
          .toList(growable: false),
      sources: (map['sources'] as List<dynamic>)
          .map((item) => ConnectedSource.fromMap(item as Map<String, dynamic>))
          .toList(growable: false),
      auditTrail: (map['auditTrail'] as List<dynamic>)
          .map((item) => AuditEvent.fromMap(item as Map<String, dynamic>))
          .toList(growable: false),
      tasks: (map['tasks'] as List<dynamic>)
          .map((item) => CareTask.fromMap(item as Map<String, dynamic>))
          .toList(growable: false),
      adherence: (map['adherence'] as List<dynamic>)
          .map((item) => AdherenceMetric.fromMap(item as Map<String, dynamic>))
          .toList(growable: false),
      insights: (map['insights'] as List<dynamic>)
          .map((item) => ClinicalInsight.fromMap(item as Map<String, dynamic>))
          .toList(growable: false),
      lastGlobalSync: DateTime.parse(map['lastGlobalSync'] as String),
    );
  }
}

class PatientProfile {
  const PatientProfile({
    required this.email,
    required this.name,
    required this.memberId,
    required this.bloodGroup,
    required this.hospitalNetwork,
    required this.phone,
    required this.address,
    required this.allergies,
    required this.emergencyContact,
    required this.emergencyContacts,
  });

  final String email;
  final String name;
  final String memberId;
  final String bloodGroup;
  final String hospitalNetwork;
  final String phone;
  final String address;
  final List<String> allergies;
  final String emergencyContact;
  final List<String> emergencyContacts;

  PatientProfile copyWith({
    String? email,
    String? name,
    String? memberId,
    String? bloodGroup,
    String? hospitalNetwork,
    String? phone,
    String? address,
    List<String>? allergies,
    String? emergencyContact,
    List<String>? emergencyContacts,
  }) {
    return PatientProfile(
      email: email ?? this.email,
      name: name ?? this.name,
      memberId: memberId ?? this.memberId,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      hospitalNetwork: hospitalNetwork ?? this.hospitalNetwork,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      allergies: allergies ?? this.allergies,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'email': email,
      'name': name,
      'memberId': memberId,
      'bloodGroup': bloodGroup,
      'hospitalNetwork': hospitalNetwork,
      'phone': phone,
      'address': address,
      'allergies': allergies,
      'emergencyContact': emergencyContact,
      'emergencyContacts': emergencyContacts,
    };
  }

  factory PatientProfile.fromMap(Map<String, dynamic> map) {
    return PatientProfile(
      email: map['email'] as String,
      name: map['name'] as String,
      memberId: map['memberId'] as String,
      bloodGroup: map['bloodGroup'] as String,
      hospitalNetwork: map['hospitalNetwork'] as String,
      phone: map['phone'] as String? ?? '',
      address: map['address'] as String? ?? '',
      allergies: (map['allergies'] as List<dynamic>)
          .map((item) => item as String)
          .toList(growable: false),
      emergencyContact: map['emergencyContact'] as String? ?? '',
      emergencyContacts:
          ((map['emergencyContacts'] as List<dynamic>?) ?? const [])
              .map((item) => item as String)
              .toList(growable: false),
    );
  }
}

class HealthRecord {
  const HealthRecord({
    required this.title,
    required this.category,
    required this.source,
    required this.summary,
    required this.details,
    required this.status,
    required this.standard,
    required this.secureId,
    required this.recordedAt,
    required this.tags,
    this.attachments = const [],
  });

  final String title;
  final String category;
  final String source;
  final String summary;
  final String details;
  final String status;
  final String standard;
  final String secureId;
  final DateTime recordedAt;
  final List<String> tags;
  final List<RecordAttachment> attachments;

  Map<String, Object?> toMap() {
    return {
      'title': title,
      'category': category,
      'source': source,
      'summary': summary,
      'details': details,
      'status': status,
      'standard': standard,
      'secureId': secureId,
      'recordedAt': recordedAt.toIso8601String(),
      'tags': tags,
      'attachments': attachments
          .map((attachment) => attachment.toMap())
          .toList(growable: false),
    };
  }

  factory HealthRecord.fromMap(Map<String, dynamic> map) {
    return HealthRecord(
      title: map['title'] as String,
      category: map['category'] as String,
      source: map['source'] as String,
      summary: map['summary'] as String,
      details: map['details'] as String,
      status: map['status'] as String,
      standard: map['standard'] as String,
      secureId: map['secureId'] as String,
      recordedAt: DateTime.parse(map['recordedAt'] as String),
      tags: (map['tags'] as List<dynamic>)
          .map((item) => item as String)
          .toList(growable: false),
      attachments: ((map['attachments'] as List<dynamic>?) ?? const [])
          .map((item) => RecordAttachment.fromMap(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class RecordAttachment {
  const RecordAttachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.base64Data,
  });

  final String id;
  final String fileName;
  final String mimeType;
  final String base64Data;

  Uint8List get bytes => base64Decode(base64Data);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'fileName': fileName,
      'mimeType': mimeType,
      'base64Data': base64Data,
    };
  }

  factory RecordAttachment.fromMap(Map<String, dynamic> map) {
    return RecordAttachment(
      id: map['id'] as String,
      fileName: map['fileName'] as String,
      mimeType: map['mimeType'] as String,
      base64Data: map['base64Data'] as String,
    );
  }
}

class TrendSeries {
  const TrendSeries({
    required this.label,
    required this.unit,
    required this.color,
    required this.points,
    required this.minDisplay,
    required this.maxDisplay,
    required this.interpretation,
  });

  final String label;
  final String unit;
  final Color color;
  final List<TrendPoint> points;
  final double minDisplay;
  final double maxDisplay;
  final String interpretation;

  double get normalizedLatestValue {
    final latest = points.last.value;
    final spread = maxDisplay - minDisplay;
    if (spread <= 0) {
      return 0;
    }
    return ((latest - minDisplay) / spread).clamp(0, 1);
  }

  Map<String, Object?> toMap() {
    return {
      'label': label,
      'unit': unit,
      'color': color.toARGB32(),
      'points': points.map((point) => point.toMap()).toList(growable: false),
      'minDisplay': minDisplay,
      'maxDisplay': maxDisplay,
      'interpretation': interpretation,
    };
  }

  factory TrendSeries.fromMap(Map<String, dynamic> map) {
    return TrendSeries(
      label: map['label'] as String,
      unit: map['unit'] as String,
      color: Color(map['color'] as int),
      points: (map['points'] as List<dynamic>)
          .map((item) => TrendPoint.fromMap(item as Map<String, dynamic>))
          .toList(growable: false),
      minDisplay: (map['minDisplay'] as num).toDouble(),
      maxDisplay: (map['maxDisplay'] as num).toDouble(),
      interpretation: map['interpretation'] as String,
    );
  }
}

class TrendPoint {
  const TrendPoint({required this.label, required this.value});

  final String label;
  final double value;

  Map<String, Object?> toMap() => {'label': label, 'value': value};

  factory TrendPoint.fromMap(Map<String, dynamic> map) {
    return TrendPoint(
      label: map['label'] as String,
      value: (map['value'] as num).toDouble(),
    );
  }
}

class ConnectedSource {
  const ConnectedSource({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.standard,
    required this.recordsAvailable,
    required this.consentGranted,
    required this.lastSync,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String type;
  final String status;
  final String standard;
  final int recordsAvailable;
  final bool consentGranted;
  final DateTime lastSync;
  final double latitude;
  final double longitude;

  ConnectedSource copyWith({
    String? id,
    String? name,
    String? type,
    String? status,
    String? standard,
    int? recordsAvailable,
    bool? consentGranted,
    DateTime? lastSync,
    double? latitude,
    double? longitude,
  }) {
    return ConnectedSource(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      standard: standard ?? this.standard,
      recordsAvailable: recordsAvailable ?? this.recordsAvailable,
      consentGranted: consentGranted ?? this.consentGranted,
      lastSync: lastSync ?? this.lastSync,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'status': status,
      'standard': standard,
      'recordsAvailable': recordsAvailable,
      'consentGranted': consentGranted,
      'lastSync': lastSync.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory ConnectedSource.fromMap(Map<String, dynamic> map) {
    return ConnectedSource(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      status: map['status'] as String,
      standard: map['standard'] as String,
      recordsAvailable: map['recordsAvailable'] as int,
      consentGranted: map['consentGranted'] as bool,
      lastSync: DateTime.parse(map['lastSync'] as String),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AuditEvent {
  const AuditEvent({
    required this.title,
    required this.actor,
    required this.detail,
    required this.timestamp,
    required this.severityColor,
    required this.icon,
  });

  final String title;
  final String actor;
  final String detail;
  final DateTime timestamp;
  final Color severityColor;
  final IconData icon;

  Map<String, Object?> toMap() {
    return {
      'title': title,
      'actor': actor,
      'detail': detail,
      'timestamp': timestamp.toIso8601String(),
      'severityColor': severityColor.toARGB32(),
      'icon': icon.codePoint,
      'iconFamily': icon.fontFamily,
      'iconPackage': icon.fontPackage,
      'matchTextDirection': icon.matchTextDirection,
    };
  }

  factory AuditEvent.fromMap(Map<String, dynamic> map) {
    return AuditEvent(
      title: map['title'] as String,
      actor: map['actor'] as String,
      detail: map['detail'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      severityColor: Color(map['severityColor'] as int),
      icon: IconData(
        map['icon'] as int,
        fontFamily: map['iconFamily'] as String?,
        fontPackage: map['iconPackage'] as String?,
        matchTextDirection: map['matchTextDirection'] as bool? ?? false,
      ),
    );
  }
}

class CareTask {
  const CareTask({
    required this.title,
    required this.detail,
    required this.dueDate,
    required this.priority,
    required this.completed,
  });

  final String title;
  final String detail;
  final DateTime dueDate;
  final String priority;
  final bool completed;

  Map<String, Object?> toMap() {
    return {
      'title': title,
      'detail': detail,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority,
      'completed': completed,
    };
  }

  factory CareTask.fromMap(Map<String, dynamic> map) {
    return CareTask(
      title: map['title'] as String,
      detail: map['detail'] as String,
      dueDate: DateTime.parse(map['dueDate'] as String),
      priority: map['priority'] as String,
      completed: map['completed'] as bool,
    );
  }
}

class AdherenceMetric {
  const AdherenceMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  Map<String, Object?> toMap() {
    return {'label': label, 'value': value, 'color': color.toARGB32()};
  }

  factory AdherenceMetric.fromMap(Map<String, dynamic> map) {
    return AdherenceMetric(
      label: map['label'] as String,
      value: (map['value'] as num).toDouble(),
      color: Color(map['color'] as int),
    );
  }
}

class ClinicalInsight {
  const ClinicalInsight({
    required this.title,
    required this.detail,
    required this.color,
  });

  final String title;
  final String detail;
  final Color color;

  Map<String, Object?> toMap() {
    return {'title': title, 'detail': detail, 'color': color.toARGB32()};
  }

  factory ClinicalInsight.fromMap(Map<String, dynamic> map) {
    return ClinicalInsight(
      title: map['title'] as String,
      detail: map['detail'] as String,
      color: Color(map['color'] as int),
    );
  }
}

class AppDatabaseSnapshot {
  AppDatabaseSnapshot({
    required Map<String, UserAccount> usersByEmail,
    required Map<String, PatientSnapshot> patientsByEmail,
  }) : usersByEmail = Map<String, UserAccount>.from(usersByEmail),
       patientsByEmail = Map<String, PatientSnapshot>.from(patientsByEmail);

  final Map<String, UserAccount> usersByEmail;
  final Map<String, PatientSnapshot> patientsByEmail;

  Map<String, Object?> toMap() {
    return {
      'usersByEmail': usersByEmail.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
      'patientsByEmail': patientsByEmail.map(
        (key, value) => MapEntry(key, value.toMap()),
      ),
    };
  }

  factory AppDatabaseSnapshot.fromMap(Map<String, dynamic> map) {
    final usersRaw = map['usersByEmail'] as Map<String, dynamic>;
    final patientsRaw = map['patientsByEmail'] as Map<String, dynamic>;
    return AppDatabaseSnapshot(
      usersByEmail: usersRaw.map(
        (key, value) =>
            MapEntry(key, UserAccount.fromMap(value as Map<String, dynamic>)),
      ),
      patientsByEmail: patientsRaw.map(
        (key, value) => MapEntry(
          key,
          PatientSnapshot.fromMap(value as Map<String, dynamic>),
        ),
      ),
    );
  }
}

abstract class MediBridgeStore {
  Future<AppDatabaseSnapshot> loadOrSeed(AppDatabaseSnapshot seeded);

  Future<void> save(AppDatabaseSnapshot snapshot);
}

class MemoryMediBridgeStore implements MediBridgeStore {
  AppDatabaseSnapshot? _snapshot;

  @override
  Future<AppDatabaseSnapshot> loadOrSeed(AppDatabaseSnapshot seeded) async {
    _snapshot ??= AppDatabaseSnapshot(
      usersByEmail: seeded.usersByEmail,
      patientsByEmail: seeded.patientsByEmail,
    );
    return _snapshot!;
  }

  @override
  Future<void> save(AppDatabaseSnapshot snapshot) async {
    _snapshot = AppDatabaseSnapshot(
      usersByEmail: snapshot.usersByEmail,
      patientsByEmail: snapshot.patientsByEmail,
    );
  }
}

class SharedPreferencesMediBridgeStore implements MediBridgeStore {
  static const _storageKey = 'medibridge_snapshot_v1';

  @override
  Future<AppDatabaseSnapshot> loadOrSeed(AppDatabaseSnapshot seeded) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      await save(seeded);
      return AppDatabaseSnapshot(
        usersByEmail: seeded.usersByEmail,
        patientsByEmail: seeded.patientsByEmail,
      );
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return AppDatabaseSnapshot.fromMap(decoded);
  }

  @override
  Future<void> save(AppDatabaseSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(snapshot.toMap()));
  }
}

AppDatabaseSnapshot buildSeedDatabase() {
  final seededPatient = buildSeedPatient();
  final demoUser = UserAccount(
    email: 'akash123@gmail.com',
    password: 'Pass@123',
    fullName: seededPatient.profile.name,
    role: AccountRole.patient,
    patientEmail: 'akash123@gmail.com',
  );
  const demoDoctor = UserAccount(
    email: 'dr.luffy@medibridge.app',
    password: 'Doctor@123',
    fullName: 'Dr. Luffy',
    role: AccountRole.doctor,
    hospitalNetwork: 'Sree Buddha Medical Network',
    specialty: 'General Medicine',
  );
  const demoHospital = UserAccount(
    email: 'records@greenvalleyhospital.com',
    password: 'Hospital@123',
    fullName: 'Green Valley Hospital Records Desk',
    role: AccountRole.hospital,
    hospitalNetwork: 'Green Valley Hospital',
    specialty: 'Records Portal',
  );

  return AppDatabaseSnapshot(
    usersByEmail: {
      demoUser.email: demoUser,
      demoDoctor.email: demoDoctor,
      demoHospital.email: demoHospital,
    },
    patientsByEmail: {demoUser.patientEmail!: seededPatient},
  );
}

PatientSnapshot buildSeedPatient() {
  return PatientSnapshot(
    profile: const PatientProfile(
      email: 'akash123@gmail.com',
      name: 'Akash',
      memberId: 'MB-1024',
      bloodGroup: 'O+',
      hospitalNetwork: 'Sree Buddha Medical Network',
      phone: '+91 99999 22222',
      address: 'Kottayam, Kerala',
      allergies: ['Peanuts', 'Amoxicillin'],
      emergencyContact: 'Daniel Gomez • +91 99999 12345',
      emergencyContacts: [
        'Daniel Gomez • Husband • +91 99999 12345',
        'Asha Joseph • Sister • +91 98888 45454',
      ],
    ),
    records: [
      HealthRecord(
        title: 'HbA1c laboratory result',
        category: 'Lab Report',
        source: 'Aster Laboratory Exchange',
        summary: 'HbA1c measured at 6.7%, indicating improved glucose control.',
        details:
            'The laboratory report was transmitted over the FHIR API, normalized into the centralized patient vault, and marked for physician review.',
        status: 'Reviewed',
        standard: 'FHIR',
        secureId: 'ENC-AX12',
        recordedAt: DateTime(2026, 3, 18),
        tags: const ['glucose', 'diabetes', 'trend-ready'],
      ),
      HealthRecord(
        title: 'Cardiology follow-up note',
        category: 'Visit Summary',
        source: 'City Heart Clinic',
        summary:
            'Follow-up completed with stable rhythm and no medication changes.',
        details:
            'The clinic visit note includes vitals, ECG summary, and updated physician comments synchronized via a RESTful JSON exchange.',
        status: 'Reviewed',
        standard: 'JSON',
        secureId: 'ENC-CV33',
        recordedAt: DateTime(2026, 3, 16),
        tags: const ['cardiology', 'follow-up', 'stable'],
      ),
      HealthRecord(
        title: 'Prescription renewal',
        category: 'Prescription',
        source: 'MedPlus Pharmacy Hub',
        summary:
            'Metformin 500mg renewed for 30 days with adherence reminders.',
        details:
            'Prescription data from the pharmacy exchange was matched to the patient identity and stored with the existing medication plan.',
        status: 'Ready',
        standard: 'HL7',
        secureId: 'ENC-RX88',
        recordedAt: DateTime(2026, 3, 14),
        tags: const ['medication', 'renewal', 'adherence'],
      ),
      HealthRecord(
        title: 'Radiology chest imaging summary',
        category: 'Imaging',
        source: 'Regional Diagnostics',
        summary: 'No acute findings reported in the shared imaging summary.',
        details:
            'Imaging metadata and summary were attached to the interoperable chart, allowing providers to review the latest report without duplicate uploads.',
        status: 'Reviewed',
        standard: 'FHIR',
        secureId: 'ENC-IM42',
        recordedAt: DateTime(2026, 3, 10),
        tags: const ['radiology', 'imaging', 'summary'],
      ),
    ],
    trends: const [
      TrendSeries(
        label: 'Blood Glucose',
        unit: 'mg/dL',
        color: Color(0xFF0F766E),
        minDisplay: 80,
        maxDisplay: 180,
        interpretation:
            'The latest value remains within the personalized target range.',
        points: [
          TrendPoint(label: 'Mon', value: 148),
          TrendPoint(label: 'Tue', value: 142),
          TrendPoint(label: 'Wed', value: 138),
          TrendPoint(label: 'Thu', value: 133),
          TrendPoint(label: 'Fri', value: 129),
          TrendPoint(label: 'Sat', value: 126),
          TrendPoint(label: 'Sun', value: 124),
        ],
      ),
      TrendSeries(
        label: 'Heart Rate',
        unit: 'bpm',
        color: Color(0xFF1D4ED8),
        minDisplay: 55,
        maxDisplay: 110,
        interpretation:
            'Heart rate variability is stable with no acute anomalies.',
        points: [
          TrendPoint(label: 'Mon', value: 82),
          TrendPoint(label: 'Tue', value: 79),
          TrendPoint(label: 'Wed', value: 84),
          TrendPoint(label: 'Thu', value: 77),
          TrendPoint(label: 'Fri', value: 76),
          TrendPoint(label: 'Sat', value: 78),
          TrendPoint(label: 'Sun', value: 74),
        ],
      ),
      TrendSeries(
        label: 'Systolic BP',
        unit: 'mmHg',
        color: Color(0xFF7C3AED),
        minDisplay: 90,
        maxDisplay: 160,
        interpretation:
            'Blood pressure shows a downward trend after medication adherence.',
        points: [
          TrendPoint(label: 'Mon', value: 142),
          TrendPoint(label: 'Tue', value: 138),
          TrendPoint(label: 'Wed', value: 136),
          TrendPoint(label: 'Thu', value: 132),
          TrendPoint(label: 'Fri', value: 130),
          TrendPoint(label: 'Sat', value: 128),
          TrendPoint(label: 'Sun', value: 126),
        ],
      ),
    ],
    sources: [
      ConnectedSource(
        id: 'aster-lab',
        name: 'Aster Laboratory Exchange',
        type: 'Laboratory',
        status: 'Connected',
        standard: 'FHIR',
        recordsAvailable: 2,
        consentGranted: true,
        lastSync: DateTime(2026, 3, 22, 11, 15),
        latitude: 9.5930,
        longitude: 76.5210,
      ),
      ConnectedSource(
        id: 'city-heart',
        name: 'City Heart Clinic',
        type: 'Clinic',
        status: 'Connected',
        standard: 'JSON',
        recordsAvailable: 1,
        consentGranted: true,
        lastSync: DateTime(2026, 3, 22, 10, 10),
        latitude: 9.5885,
        longitude: 76.5265,
      ),
      ConnectedSource(
        id: 'medplus',
        name: 'MedPlus Pharmacy Hub',
        type: 'Pharmacy',
        status: 'Pending sync',
        standard: 'HL7',
        recordsAvailable: 1,
        consentGranted: false,
        lastSync: DateTime(2026, 3, 20, 18, 0),
        latitude: 9.5908,
        longitude: 76.5285,
      ),
      ConnectedSource(
        id: 'green-valley-hospital',
        name: 'Green Valley Hospital',
        type: 'Hospital',
        status: 'Available',
        standard: 'FHIR',
        recordsAvailable: 0,
        consentGranted: false,
        lastSync: DateTime(2026, 3, 19, 9, 30),
        latitude: 9.5968,
        longitude: 76.5198,
      ),
      ConnectedSource(
        id: 'sunrise-medical-center',
        name: 'Sunrise Medical Center',
        type: 'Hospital',
        status: 'Available',
        standard: 'FHIR',
        recordsAvailable: 0,
        consentGranted: false,
        lastSync: DateTime(2026, 3, 15, 14, 45),
        latitude: 9.5862,
        longitude: 76.5312,
      ),
    ],
    auditTrail: [
      AuditEvent(
        title: 'Clinical data normalized',
        actor: 'Medifix API Gateway',
        detail:
            'The latest cardiology visit note was transformed into the unified patient schema.',
        timestamp: DateTime(2026, 3, 22, 11, 18),
        severityColor: const Color(0xFF1D4ED8),
        icon: Icons.data_object,
      ),
      AuditEvent(
        title: 'Patient consent updated',
        actor: 'Akash',
        detail: 'Consent was granted for laboratory data sharing.',
        timestamp: DateTime(2026, 3, 21, 16, 40),
        severityColor: const Color(0xFF0F766E),
        icon: Icons.verified,
      ),
      AuditEvent(
        title: 'Vault encryption verified',
        actor: 'Security Monitor',
        detail: 'Encrypted record integrity check completed successfully.',
        timestamp: DateTime(2026, 3, 20, 8, 30),
        severityColor: const Color(0xFF7C3AED),
        icon: Icons.lock_clock,
      ),
    ],
    tasks: [
      CareTask(
        title: 'Upload fasting glucose reading',
        detail:
            'Add the latest home reading so clinicians can compare it with the synchronized laboratory trend.',
        dueDate: DateTime(2026, 3, 24),
        priority: 'High priority',
        completed: false,
      ),
      CareTask(
        title: 'Review prescription renewal',
        detail:
            'Confirm medication adherence reminders for the renewed Metformin plan.',
        dueDate: DateTime(2026, 3, 25),
        priority: 'Medium priority',
        completed: false,
      ),
      CareTask(
        title: 'Cardiology follow-up shared',
        detail:
            'Visit summary has already been synchronized with the patient record.',
        dueDate: DateTime(2026, 3, 16),
        priority: 'Completed',
        completed: true,
      ),
    ],
    adherence: const [
      AdherenceMetric(
        label: 'Medication adherence',
        value: 92,
        color: Color(0xFF0F766E),
      ),
      AdherenceMetric(
        label: 'Appointment attendance',
        value: 88,
        color: Color(0xFF1D4ED8),
      ),
      AdherenceMetric(
        label: 'Home data submission',
        value: 73,
        color: Color(0xFFEA580C),
      ),
    ],
    insights: const [
      ClinicalInsight(
        title: 'Improving glucose stability',
        detail:
            'Weekly values show a consistent downward trend after treatment adjustment.',
        color: Color(0xFF0F766E),
      ),
      ClinicalInsight(
        title: 'No acute cardiac concern',
        detail:
            'Latest cardiology note and vitals remain aligned with the expected baseline.',
        color: Color(0xFF1D4ED8),
      ),
      ClinicalInsight(
        title: 'Pharmacy feed still restricted',
        detail:
            'Enable consent to include refill history in the unified patient timeline.',
        color: Color(0xFFEA580C),
      ),
    ],
    lastGlobalSync: DateTime(2026, 3, 22, 11, 18),
  );
}

PatientSnapshot buildNewPatient(PatientProfile profile) {
  return PatientSnapshot(
    profile: profile,
    records: [
      HealthRecord(
        title: 'Account onboarding summary',
        category: 'Visit Summary',
        source: profile.hospitalNetwork,
        summary:
            'A patient account was created and linked to the interoperable care platform.',
        details:
            'This starter record confirms that the patient identity was provisioned successfully and the encrypted vault is ready to receive clinical data.',
        status: 'Reviewed',
        standard: 'JSON',
        secureId: 'ENC-NEW01',
        recordedAt: DateTime.now(),
        tags: const ['onboarding', 'identity', 'secure'],
      ),
    ],
    trends: const [
      TrendSeries(
        label: 'Blood Glucose',
        unit: 'mg/dL',
        color: Color(0xFF0F766E),
        minDisplay: 80,
        maxDisplay: 180,
        interpretation:
            'Initial tracking started. Add more observations to build a reliable trend.',
        points: [
          TrendPoint(label: 'Mon', value: 120),
          TrendPoint(label: 'Tue', value: 118),
          TrendPoint(label: 'Wed', value: 122),
          TrendPoint(label: 'Thu', value: 119),
          TrendPoint(label: 'Fri', value: 121),
          TrendPoint(label: 'Sat', value: 117),
          TrendPoint(label: 'Sun', value: 116),
        ],
      ),
      TrendSeries(
        label: 'Heart Rate',
        unit: 'bpm',
        color: Color(0xFF1D4ED8),
        minDisplay: 55,
        maxDisplay: 110,
        interpretation:
            'A baseline resting heart rate profile has been created.',
        points: [
          TrendPoint(label: 'Mon', value: 78),
          TrendPoint(label: 'Tue', value: 76),
          TrendPoint(label: 'Wed', value: 79),
          TrendPoint(label: 'Thu', value: 77),
          TrendPoint(label: 'Fri', value: 78),
          TrendPoint(label: 'Sat', value: 75),
          TrendPoint(label: 'Sun', value: 74),
        ],
      ),
    ],
    sources: [
      ConnectedSource(
        id: 'primary-network',
        name: profile.hospitalNetwork,
        type: 'Hospital',
        status: 'Connected',
        standard: 'FHIR',
        recordsAvailable: 1,
        consentGranted: true,
        lastSync: DateTime.now(),
        latitude: 9.5916,
        longitude: 76.5222,
      ),
      ConnectedSource(
        id: 'community-lab',
        name: 'Community Lab Gateway',
        type: 'Laboratory',
        status: 'Pending sync',
        standard: 'HL7',
        recordsAvailable: 0,
        consentGranted: false,
        lastSync: DateTime.now().subtract(const Duration(days: 2)),
        latitude: 9.5942,
        longitude: 76.5204,
      ),
      ConnectedSource(
        id: 'green-valley-hospital',
        name: 'Green Valley Hospital',
        type: 'Hospital',
        status: 'Available',
        standard: 'FHIR',
        recordsAvailable: 0,
        consentGranted: false,
        lastSync: DateTime.now().subtract(const Duration(days: 5)),
        latitude: 9.5968,
        longitude: 76.5198,
      ),
    ],
    auditTrail: [
      AuditEvent(
        title: 'Encrypted vault created',
        actor: 'Provisioning Service',
        detail:
            'Patient storage, exchange profile, and audit monitoring were initialized.',
        timestamp: DateTime.now(),
        severityColor: const Color(0xFF1D4ED8),
        icon: Icons.enhanced_encryption,
      ),
    ],
    tasks: [
      CareTask(
        title: 'Connect laboratory records',
        detail:
            'Grant consent to begin collecting laboratory reports automatically.',
        dueDate: DateTime.now().add(const Duration(days: 2)),
        priority: 'High priority',
        completed: false,
      ),
      CareTask(
        title: 'Complete first consultation',
        detail:
            'Share the onboarding profile with a physician for the first visit.',
        dueDate: DateTime.now().add(const Duration(days: 5)),
        priority: 'Medium priority',
        completed: false,
      ),
    ],
    adherence: const [
      AdherenceMetric(
        label: 'Medication adherence',
        value: 80,
        color: Color(0xFF0F766E),
      ),
      AdherenceMetric(
        label: 'Appointment attendance',
        value: 75,
        color: Color(0xFF1D4ED8),
      ),
      AdherenceMetric(
        label: 'Home data submission',
        value: 68,
        color: Color(0xFFEA580C),
      ),
    ],
    insights: const [
      ClinicalInsight(
        title: 'Profile ready for first sync',
        detail:
            'Connect more sources to improve the completeness of the unified record.',
        color: Color(0xFF0F766E),
      ),
      ClinicalInsight(
        title: 'Consent controls inactive on lab feed',
        detail:
            'Enable the community laboratory source to receive the first external reports.',
        color: Color(0xFFEA580C),
      ),
    ],
    lastGlobalSync: DateTime.now(),
  );
}

String formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String formatDateTime(DateTime date) {
  final hour = date.hour == 0
      ? 12
      : (date.hour > 12 ? date.hour - 12 : date.hour);
  final minute = date.minute.toString().padLeft(2, '0');
  final suffix = date.hour >= 12 ? 'PM' : 'AM';
  return '${formatDate(date)} • $hour:$minute $suffix';
}

String patientEmailFor(PatientSnapshot patient) => patient.profile.email;

ConnectedSource? sourceForHospital(
  PatientSnapshot patient,
  String? hospitalName,
) {
  if (hospitalName == null || hospitalName.isEmpty) {
    return null;
  }
  for (final source in patient.sources) {
    if (source.name == hospitalName) {
      return source;
    }
  }
  return null;
}

double averageAdherence(PatientSnapshot patient) {
  if (patient.adherence.isEmpty) {
    return 0;
  }
  final total = patient.adherence.fold<double>(
    0,
    (sum, item) => sum + item.value,
  );
  return total / patient.adherence.length;
}

int openTaskCount(PatientSnapshot patient) {
  return patient.tasks.where((task) => !task.completed).length;
}

int highPriorityTaskCount(PatientSnapshot patient) {
  return patient.tasks.where((task) {
    return !task.completed && task.priority.toLowerCase().contains('high');
  }).length;
}

int patientPriorityScore(PatientSnapshot patient) {
  return (highPriorityTaskCount(patient) * 5) +
      (openTaskCount(patient) * 2) +
      ((100 - averageAdherence(patient)).round() ~/ 8);
}

String patientPriorityLabel(PatientSnapshot patient) {
  if (highPriorityTaskCount(patient) > 0 || averageAdherence(patient) < 72) {
    return 'Urgent';
  }
  if (openTaskCount(patient) > 0 || averageAdherence(patient) < 85) {
    return 'Monitor';
  }
  return 'Stable';
}

Color patientPriorityColor(PatientSnapshot patient) {
  return switch (patientPriorityLabel(patient)) {
    'Urgent' => const Color(0xFFEA580C),
    'Monitor' => const Color(0xFF1D4ED8),
    _ => const Color(0xFF0F766E),
  };
}

List<UserAccount> doctorsTreatingPatient(
  HealthAppController controller,
  String patientEmail,
) {
  final normalizedEmail = patientEmail.toLowerCase();
  return controller.hospitalDoctors
      .where((doctor) {
        return doctor.assignedPatientEmails
            .map((email) => email.toLowerCase())
            .contains(normalizedEmail);
      })
      .toList(growable: false);
}

const double patientHomeLatitude = 9.5914;
const double patientHomeLongitude = 76.5241;

double distanceFromPatient(ConnectedSource source) {
  const scale = 111.0;
  final dx = (source.latitude - patientHomeLatitude) * scale;
  final dy = (source.longitude - patientHomeLongitude) * scale;
  return math.sqrt((dx * dx) + (dy * dy));
}

Offset projectSourceToMap(ConnectedSource source, Size size) {
  const xScale = 7000.0;
  const yScale = 7000.0;
  final dx =
      ((source.longitude - patientHomeLongitude) * xScale) + (size.width * 0.5);
  final dy =
      ((source.latitude - patientHomeLatitude) * -yScale) +
      (size.height * 0.56);
  return Offset(
    dx.clamp(24, size.width - 120).toDouble(),
    dy.clamp(20, size.height - 40).toDouble(),
  );
}

String slugify(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}
