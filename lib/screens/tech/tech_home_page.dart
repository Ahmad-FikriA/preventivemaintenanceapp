import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/auth_helpers.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'dart:collection';

class TechHomePage extends StatelessWidget {
  const TechHomePage({super.key});

  @override
  Widget build(BuildContext context) {
  final uid = requireUidOrRedirect(context);
  if (uid == null) return const Scaffold(body: Center(child: Text('Please sign in')));

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));
  // sevenDays not used in dashboard layout

    // --- count streams ---
    Stream<int> count(Query<Map<String, dynamic>> q) =>
        q.snapshots().map((s) => s.size);

  // Show total assigned open as the 'Overdue' card to avoid strict dueDate filtering
  final overdueCount$ = count(_qAssignedOpen(uid));
    final todayCount$ = count(_qAssignedOpen(uid)
        .where('dueDate', isGreaterThanOrEqualTo: startOfToday)
        .where('dueDate', isLessThan: startOfTomorrow));
  // next7Count$ removed; dashboard shows upcoming list instead

    // --- lists ---
    final todayList$ = _qAssignedOpen(uid)
        .where('dueDate', isGreaterThanOrEqualTo: startOfToday)
        .where('dueDate', isLessThan: startOfTomorrow)
        .orderBy('dueDate')
        .snapshots();

  // drafts$ and myIssues$ removed — sections not used in this condensed dashboard

    // extra streams for dashboard tiles
    final activeEquipment$ = FirebaseFirestore.instance.collection('equipment').snapshots().map((s) => s.size);
    final completedCount$ = FirebaseFirestore.instance
        .collection('checklist_instances')
        .where('assignees', arrayContains: uid)
        .where('status', isEqualTo: 'submitted')
        .snapshots()
        .map((s) => s.size);

    // stream for upcoming tasks (assigned open ordered by dueDate)
    final upcoming$ = _qAssignedOpen(uid).orderBy('dueDate').snapshots();
    // recent activity: recently submitted instances
    final recentSubmissions$ = FirebaseFirestore.instance
        .collection('checklist_instances')
        .where('status', isEqualTo: 'submitted')
        .orderBy('submittedAt', descending: true)
        .limit(5)
        .snapshots();

    final user = FirebaseAuth.instance.currentUser;
    final initials = (user?.displayName?.split(' ').map((s) => s.isNotEmpty ? s[0] : '').join() ?? (user?.email != null ? user!.email!.split('@').first.substring(0,1).toUpperCase() : ''));

    final displayName = user?.displayName ?? (user?.email?.split('@').first ?? 'User');

    // small in-memory caches to avoid repeated reads in short-lived widgets
    final userCache = HashMap<String, String>(); // uid -> display name
    final equipCache = HashMap<String, String>();

    Future<String> resolveUser(String uid) async {
      if (userCache.containsKey(uid)) return userCache[uid]!;
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final name = (doc.data()?['name'] as String?) ?? (doc.data()?['email'] as String?) ?? 'User';
        userCache[uid] = name;
        return name;
      } catch (_) {
        return 'User';
      }
    }

    Future<String> resolveEquipment(String id) async {
      if (equipCache.containsKey(id)) return equipCache[id]!;
      try {
        final doc = await FirebaseFirestore.instance.collection('equipment').doc(id).get();
        final name = (doc.data()?['name'] as String?) ?? (doc.data()?['title'] as String?) ?? 'Equipment';
        equipCache[id] = name;
        return name;
      } catch (_) {
        return 'Equipment';
      }
    }

    final tplCache = HashMap<String, String>();
    Future<String> resolveTemplate(String id) async {
      if (tplCache.containsKey(id)) return tplCache[id]!;
      try {
        final doc = await FirebaseFirestore.instance.collection('checklist_templates').doc(id).get();
        final title = (doc.data()?['title'] as String?) ?? id;
        tplCache[id] = title;
        return title;
      } catch (_) {
        return id;
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Welcome back, $displayName', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 2),
            const Text('Maintenance Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () => context.push('/profile'),
              child: CircleAvatar(child: Text(initials)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // greeting moved to AppBar
          const SizedBox(height: 12),
          // 4 tiles grid
          Row(children: [
            Expanded(child: StreamBuilder<int>(stream: activeEquipment$, builder: (_, s) => _DashboardTile(label: 'Active Equipment', count: s.data ?? 0, icon: Icons.precision_manufacturing_outlined, onTap: () => context.push('/t/equipment')))),
            const SizedBox(width: 12),
            Expanded(child: StreamBuilder<int>(stream: todayCount$, builder: (_, s) => _DashboardTile(label: 'Due Today', count: s.data ?? 0, icon: Icons.schedule_outlined, onTap: () => context.push('/t/work?range=today')))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: StreamBuilder<int>(stream: overdueCount$, builder: (_, s) => _DashboardTile(label: 'Overdue', count: s.data ?? 0, icon: Icons.error_outline, color: Colors.redAccent, onTap: () => context.push('/t/work?range=all')))),
            const SizedBox(width: 12),
            Expanded(child: StreamBuilder<int>(stream: completedCount$, builder: (_, s) => _DashboardTile(label: 'Completed', count: s.data ?? 0, icon: Icons.check_circle_outline, color: Colors.green, onTap: () => context.push('/t/work?range=all')))),
          ]),
          const SizedBox(height: 18),

          // Quick Actions
          const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
              onPressed: () => context.push('/t/equipment'),
              icon: const Icon(Icons.schedule_outlined),
              label: const Text('Schedule'),
            )),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
              onPressed: () => context.push('/t/equipment'),
              icon: const Icon(Icons.add_task_outlined),
              label: const Text('New Task'),
            )),
            const SizedBox(width: 8),
          ]),
          const SizedBox(height: 18),

          // Upcoming Tasks
          const Text('Upcoming Tasks', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: upcoming$,
            builder: (context, snap) {
              if (!snap.hasData) return const _CardBox(child: _Loading());
              final docs = snap.data!.docs.take(5).toList();
              if (docs.isEmpty) return const _CardBox(child: Center(child: Text('No upcoming tasks')));
              return Column(children: docs.map((d) {
                final x = d.data();
                final rawTplId = (x['templateId'] as String?);
                final titleFallback = (x['templateTitle'] as String?) ?? rawTplId ?? 'Checklist';
                final equipId = (x['equipmentId'] as String?);
                final equipName = (x['equipmentName'] as String?);
                final dueTs = x['dueDate']; DateTime? due;
                if (dueTs is Timestamp) due = dueTs.toDate();
                final when = _humanDue(due);

                // resolve template title (prefer denormalized title if present)
                final titleFuture = (x['templateTitle'] as String?) != null
                    ? Future.value(x['templateTitle'] as String)
                    : (rawTplId != null ? resolveTemplate(rawTplId) : Future.value(titleFallback));
                final equipFuture = equipName != null ? Future.value(equipName) : (equipId != null ? resolveEquipment(equipId) : Future.value(''));

                return FutureBuilder<List<String>>(
                  future: Future.wait([titleFuture, equipFuture]),
                  builder: (context, eSnap) {
                    final title = (eSnap.data != null && eSnap.data!.isNotEmpty) ? eSnap.data![0] : titleFallback;
                    final equip = (eSnap.data != null && eSnap.data!.length > 1) ? eSnap.data![1] : '';
                    return Card(margin: const EdgeInsets.symmetric(vertical:6), child: ListTile(
                      title: Text(title),
                      subtitle: Text([if (equip.isNotEmpty) equip, when].join(' • '), maxLines: 2, overflow: TextOverflow.ellipsis),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/t/fill/${d.id}'),
                    ));
                  },
                );
              }).toList());
            },
          ),
          const SizedBox(height: 18),

          // Recent Activity
          const Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: recentSubmissions$,
            builder: (context, snap) {
              if (!snap.hasData) return const _CardBox(child: _Loading());
              final docs = snap.data!.docs;
              if (docs.isEmpty) return const _CardBox(child: Center(child: Text('No recent activity')));
              return Column(children: docs.map((d) {
                final x = d.data();
                final rawTplId = (x['templateId'] as String?);
                final titleFallback = (x['templateTitle'] as String?) ?? rawTplId ?? 'Checklist';
                final submittedAt = (x['submittedAt'] is Timestamp) ? (x['submittedAt'] as Timestamp).toDate() : null;
                final submittedById = (x['submittedBy'] as String?);

                final titleFuture = (x['templateTitle'] as String?) != null
                    ? Future.value(x['templateTitle'] as String)
                    : (rawTplId != null ? resolveTemplate(rawTplId) : Future.value(titleFallback));

                return FutureBuilder<List<String>>(
                  future: Future.wait([titleFuture, submittedById != null ? resolveUser(submittedById) : Future.value('Someone')]),
                  builder: (context, userSnap) {
                    final title = (userSnap.data != null && userSnap.data!.isNotEmpty) ? userSnap.data![0] : titleFallback;
                    final who = (userSnap.data != null && userSnap.data!.length > 1) ? userSnap.data![1] : 'Someone';
                    return ListTile(
                      leading: const Icon(Icons.circle, size: 10, color: Colors.blue),
                      title: Text(title),
                      subtitle: Text('$who • ${submittedAt != null ? timeAgo(submittedAt) : ''}'),
                    );
                  },
                );
              }).toList());
            },
          ),

          const SizedBox(height: 40),
          // keep the original sections below for full functionality
          const Divider(),
          const SizedBox(height: 12),
          const _SectionTitle('My Work Today'),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: todayList$,
            builder: (context, snap) {
              if (!snap.hasData) return const _CardBox(child: _Loading());
              final docs = snap.data!.docs;
              if (docs.isEmpty) return const _CardBox(child: Center(child: Text('No work due today')));
              return _CardBox(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final x = d.data();
                    final due = (x['dueDate'] is Timestamp)
                        ? (x['dueDate'] as Timestamp).toDate()
                        : null;
                    final title = (x['templateTitle'] as String?) ?? (x['templateId'] as String? ?? 'Checklist');
                    final equip = (x['equipmentName'] as String?) ?? (x['equipmentId'] as String? ?? '');
                    return ListTile(
                      title: Text(title),
                      subtitle: Text([
                        if (equip.isNotEmpty) equip,
                        if (due != null) _fmt(due),
                      ].join(' • ')),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go('/t/fill/${d.id}'),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Base query: assigned to me, not submitted
  static Query<Map<String, dynamic>> _qAssignedOpen(String uid) =>
      FirebaseFirestore.instance
          .collection('checklist_instances')
          .where('assignees', arrayContains: uid)
          .where('status', whereIn: ['draft', 'in_progress']);

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

}

Widget _humanDue(DateTime? due) {
  if (due == null) return const Text('No due date');
  final now = DateTime.now();
  final diff = due.difference(DateTime(now.year, now.month, now.day)).inDays;
  if (diff == 0) return const Text('Today');
  if (diff == 1) return const Text('Tomorrow');
  if (diff < 0) return Text('Overdue ${-diff}d');
  return Text(DateFormat('MMM d').format(due));
}

String timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}

class _DashboardTile extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _DashboardTile({required this.label, required this.count, required this.icon, this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical:16, horizontal:12),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: (color ?? Colors.blue), child: Icon(icon, color: color ?? Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$count', style: const TextStyle(fontSize:18, fontWeight: FontWeight.bold)), const SizedBox(height:4), Text(label, style: const TextStyle(color: Colors.black54))])),
            ],
          ),
        ),
      ),
    );
  }
}

// legacy count card removed

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

class _CardBox extends StatelessWidget {
  final Widget child;
  const _CardBox({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: child,
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: CircularProgressIndicator(strokeWidth: 2),
      ));
}
