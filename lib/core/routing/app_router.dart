import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Screens
import '../../screens/loginpage/splash_screen.dart';
import '../../screens/loginpage/login_screen.dart';
import '../../screens/loginpage/register_screen.dart';
// Tech Screens
import '../../screens/tech/work_list_page.dart';
import '../../screens/tech/template_picker_page.dart';
import '../../screens/tech/checklist_fill_page.dart';
import '../../screens/tech/equipment_detail_page.dart';
import '../../screens/tech/checklist_draft_page.dart';
import '../../screens/tech/issue_create_page.dart';
import '../../screens/tech/issue_detail_page.dart';
import '../../screens/tech/tech_home_page.dart';
import '../../screens/tech/equipment_list_page.dart';
import '../../screens/tech/tech_history_page.dart';
// Admin Screens
import '../../screens/admin/admin_equipment_edit_page.dart';
import '../../screens/account/profile_account_screen.dart';
import '../../screens/admin/admin_home_page.dart';
import '../../screens/admin/admin_template_list_page.dart';
import '../../screens/admin/admin_equipment_list_page.dart';
import '../../screens/admin/admin_schedules_page.dart';
import '../../screens/admin/admin_reports_page.dart';
import '../../screens/admin/template_builder_page.dart';
import '../../screens/admin/admin_work_create_page.dart';
import '../../screens/dashboard/dashboard_admin_screen.dart';
import '../../screens/dev/template_seeder_page.dart';

//Services
import '../../services/user_profile_service.dart';

class AppRouter {
	AppRouter({required Listenable authListenable})
			: _router = GoRouter(
					navigatorKey: _rootKey,
					initialLocation: '/splash',
					refreshListenable: authListenable,
					routes: _routes,
					redirect: _redirect,
					errorBuilder: (_, __) => const Scaffold(body: Center(child: Text('Route not found'))),
				);

	static final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
	static final _techShellKey = GlobalKey<NavigatorState>(debugLabel: 'tech-shell');
	static final _adminShellKey = GlobalKey<NavigatorState>(debugLabel: 'admin-shell');

	static final _routes = <RouteBase>[
		GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
		GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
		GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
		GoRoute(path: '/', builder: (_, __) => const _RoleGate()),

		ShellRoute(
			navigatorKey: _techShellKey,
			builder: (context, state, child) => UserShell(child: child),
			routes: [
				GoRoute(path: '/t/home', builder: (_, __) => const TechHomePage()),
				GoRoute(path: '/t/equipment', builder: (_, __) => const EquipmentListPage()),
				GoRoute(path: '/t/equipment/:id', builder: (_, s) => EquipmentDetailPage(equipmentId: s.pathParameters['id']!)),
				GoRoute(path: '/t/history', builder: (_, __) => const TechHistoryPage()),
			],
		),
			GoRoute(
				path: '/t/fill/new',
				parentNavigatorKey: _rootKey,
				builder: (_, s) => ChecklistDraftPage(
					templateId: s.uri.queryParameters['templateId']!,
					equipmentId: s.uri.queryParameters['equipmentId']!),
			),

		// Neutral profile route (accessible by any authenticated role)
		GoRoute(
			path: '/profile',
			parentNavigatorKey: _rootKey,
			builder: (_, __) => const ProfileAccountScreen(),
		),

		// Removed technician equipment create/edit routes (admin only now)
		GoRoute(
			path: '/t/templates/:equipmentId',
			parentNavigatorKey: _rootKey,
			builder: (_, s) => TemplatePickerPage(equipmentId: s.pathParameters['equipmentId']!),
		),
				GoRoute(
						path: '/t/fill/:instanceId',
						parentNavigatorKey: _rootKey,
						builder: (_, s) => ChecklistFillPage(
							instanceId: s.pathParameters['instanceId']!,
							transient: s.uri.queryParameters['transient'] == '1',
						),
				),
		GoRoute(
			path: '/t/issues/new',
			parentNavigatorKey: _rootKey,
			builder: (_, s) => IssueCreatePage(
				equipmentId: s.uri.queryParameters['equipmentId']!,
				instanceId: s.uri.queryParameters['instanceId'],
			),
		),
		GoRoute(
			path: '/t/issues/:id',
			parentNavigatorKey: _rootKey,
			builder: (_, s) => IssueDetailPage(issueId: s.pathParameters['id']!),
		),
    GoRoute(
        path: '/t/work',
        builder: (_, s) => WorkListPage(range: s.uri.queryParameters['range'] ?? 'today'),
    ),

		ShellRoute(
			navigatorKey: _adminShellKey,
			builder: (context, state, child) => DashboardAdminScreen(child: child),
			routes: [
				GoRoute(path: '/admin/home', builder: (_, __) => const AdminHomePage()),
				GoRoute(path: '/admin/templates', builder: (_, __) => const AdminTemplateListPage()),
				GoRoute(path: '/admin/equipment', builder: (_, __) => const AdminEquipmentListPage()),
				GoRoute(path: '/admin/schedules', builder: (_, __) => const AdminSchedulesPage()),
				GoRoute(path: '/admin/reports', builder: (_, __) => const AdminReportsPage()),
			],
		),
		GoRoute(path: '/admin', redirect: (_, __) => '/admin/home'),
		GoRoute(
			path: '/admin/templates/new',
			parentNavigatorKey: _rootKey,
			builder: (_, __) => const TemplateBuilderPage(),
		),
		GoRoute(
			path: '/admin/templates/edit/:id',
			parentNavigatorKey: _rootKey,
			builder: (_, s) => TemplateBuilderPage(templateId: s.pathParameters['id']),
		),
		GoRoute(
			path: '/admin/equipment/add',
			parentNavigatorKey: _rootKey,
			builder: (_, __) => const AdminEquipmentEditPage(),
		),
		GoRoute(
			path: '/admin/equipment/edit/:id',
			parentNavigatorKey: _rootKey,
			builder: (_, s) => AdminEquipmentEditPage(equipmentId: s.pathParameters['id']),
		),
    GoRoute(
      path: '/admin/work/new',
      parentNavigatorKey: _rootKey,
      builder: (_, __) => const AdminWorkCreatePage(),
    ),

		GoRoute(path: '/dev/seed-template', builder: (_, __) => const TemplateSeederPage()),
	];

		static String? _redirect(BuildContext context, GoRouterState state) {
			final user = FirebaseAuth.instance.currentUser;
			final path = state.uri.path;
			if (path.startsWith('/u/')) return path.replaceFirst('/u/', '/t/');

			final isAuthScreen = path == '/login' || path == '/register' || path == '/splash';
			if (user == null) return isAuthScreen ? null : '/login';
			if (isAuthScreen) return '/';

			// Simple in-memory role cache lookup (optional; if not loaded yet we skip granular guard)
			// We reuse user doc (no global cache here), so do lightweight guard only after role fetched in RoleGate.
			// Extra guard: block technician from /admin/* and admin from /t/* profile area if needed.
			// Because RoleGate routes users first, these are mainly for deep-link protection.
			// (Optional spot to enforce role-based deep link restrictions later.)
			return null;
		}

	GoRouter get router => _router;
	final GoRouter _router;
}

class _RoleGate extends StatefulWidget { const _RoleGate(); @override State<_RoleGate> createState() => _RoleGateState(); }
class _RoleGateState extends State<_RoleGate> {
	final _ups = UserProfileService();

	Future<String> _getRole() async {
		final user = FirebaseAuth.instance.currentUser;
		if (user == null) return 'guest';
		// Ensure user doc exists / normalized (e.g., lowercase searchable fields)
		await _ups.ensureUserDoc(user);
		final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
		return (doc.data()?['role'] as String?) ?? 'user';
	}
	@override
	Widget build(BuildContext context) {
		final user = FirebaseAuth.instance.currentUser;
		if (user == null) return const _MiniSplash();
		return FutureBuilder<String>(
			future: _getRole(),
			builder: (context, snap) {
				if (snap.connectionState != ConnectionState.done) return const _MiniSplash();
				final role = snap.data ?? 'technician';
				WidgetsBinding.instance.addPostFrameCallback((_) {
					if (!context.mounted) return;
					if (role == 'admin') {
						context.go('/admin/home');
					} else {
						context.go('/t/home');
					}
				});
				return const _MiniSplash();
			},
		);
	}
}

class _MiniSplash extends StatelessWidget { const _MiniSplash(); @override Widget build(BuildContext c)=> const Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 2))); }

class UserShell extends StatelessWidget {
	final Widget child; const UserShell({super.key, required this.child});
	int _index(String path){ if(path.startsWith('/t/equipment')) return 1; if(path.startsWith('/t/history')) return 2; return 0; }
	@override Widget build(BuildContext context){ final path=GoRouterState.of(context).uri.path; final current=_index(path); return Scaffold(
		body: child,
		bottomNavigationBar: NavigationBar(
			selectedIndex: current,
			onDestinationSelected: (i){ switch(i){ case 0: context.go('/t/home'); break; case 1: context.go('/t/equipment'); break; case 2: context.go('/t/history'); break; }},
			destinations: const [
				NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
				NavigationDestination(icon: Icon(Icons.precision_manufacturing_outlined), selectedIcon: Icon(Icons.precision_manufacturing), label: 'Equipment'),
				NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'History'),
			],
		),
	); }
}

class AdminShell extends StatelessWidget { final Widget child; const AdminShell({super.key, required this.child}); @override Widget build(BuildContext c)=> Scaffold(body: child); }
