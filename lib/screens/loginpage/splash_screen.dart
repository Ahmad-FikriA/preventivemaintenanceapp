import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
  
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  StreamSubscription<User?>? _sub;

  @override
  void initState() {
    super.initState();
    // Small delay so the splash is visible
    Future.delayed(const Duration(milliseconds: 900), _listenAuth);
  }

  void _listenAuth() {
    _sub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (!mounted) return;
      // Let the global redirect + RoleGate decide routing; we only go to /login or /.
      if (user == null) {
        context.go('/login');
      } else {
        context.go('/'); // RoleGate will forward to /u/home or /admin
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Gradient without .withOpacity()
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F172A), // slate-900
              Color(0xFF1E3A8A), // blue-900
              Color(0xFF2563EB), // blue-600
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: const SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo badge
                _LogoBadge(),
                SizedBox(height: 24),
                Text(
                  'Sistem Maintenance',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFFFFF),
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Preventif • Prediktif • Proaktif',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xCCFFFFFF), // 80% white without .withOpacity
                  ),
                ),
                SizedBox(height: 32),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFFFFF)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFFFFF),   // white
            Color(0xFFE0F2FE),   // sky-100
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000), // black 20%
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.precision_manufacturing_outlined,
        size: 64,
        color: Color(0xFF1D4ED8), // blue-700
      ),
    );
  }
}
