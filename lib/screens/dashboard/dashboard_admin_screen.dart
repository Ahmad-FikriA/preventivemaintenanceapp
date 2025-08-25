import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardAdminScreen extends StatelessWidget {
  final Widget child;
  const DashboardAdminScreen({super.key, required this.child});

  int _idx(String p) {
    if (p.startsWith('/admin/templates')) return 1;
    if (p.startsWith('/admin/equipment')) return 2;
    if (p.startsWith('/admin/schedules')) return 3;
    if (p.startsWith('/admin/reports')) return 4;
    return 0; // /admin/home
  }

  void _onTap(BuildContext c, int i) {
    switch (i) {
      case 0: c.go('/admin/home'); break;
      case 1: c.go('/admin/templates'); break;
      case 2: c.go('/admin/equipment'); break;
      case 3: c.go('/admin/schedules'); break;
      case 4: c.go('/admin/reports'); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx(path),
        onDestinationSelected: (i) => _onTap(context, i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.article_outlined), label: 'Templates'),
          NavigationDestination(icon: Icon(Icons.precision_manufacturing_outlined), label: 'Equipment'),
          NavigationDestination(icon: Icon(Icons.event_repeat_outlined), label: 'Schedules'),
          NavigationDestination(icon: Icon(Icons.assessment_outlined), label: 'Reports'),
        ],
      ),
    );
  }
}
