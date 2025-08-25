// lib/screens/dashboard/dashboard_user_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

String _displayNameOrEmailPrefix(User? u) {
  if (u == null) return 'User';
  if (u.displayName != null && u.displayName!.isNotEmpty) return u.displayName!;
  if (u.email != null && u.email!.isNotEmpty) return u.email!.split('@').first;
  return 'User';
}

class DashboardUserScreen extends StatelessWidget {
  final Widget child; // ShellRoute will inject the active page here
  const DashboardUserScreen({super.key, required this.child});

  int _indexFromPath(String path) {
    if (path.startsWith('/u/equipment')) return 1;
    if (path.startsWith('/u/history')) return 2;
    return 0; // default = /u/home
  }

  void _onTap(BuildContext context, int i) {
    switch (i) {
      case 0: context.go('/u/home'); break;
      case 1: context.go('/u/equipment'); break;
      case 2: context.go('/u/history'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final current = _indexFromPath(path);
    final user = FirebaseAuth.instance.currentUser;
    final name = _displayNameOrEmailPrefix(user);

    return Scaffold(
      body: Column(
        children: [
          // Header shared across user pages
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Row(
              children: [
                Expanded(child: Text('Welcome back, $name', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
                CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U')),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: current,
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.precision_manufacturing_outlined), selectedIcon: Icon(Icons.precision_manufacturing), label: 'Equipment'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}
