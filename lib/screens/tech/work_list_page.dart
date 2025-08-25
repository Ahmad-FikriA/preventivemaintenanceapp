import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WorkListPage extends StatefulWidget {
  final String range; // overdue | today | next7d | all
  const WorkListPage({super.key, required this.range});

  @override
  State<WorkListPage> createState() => _WorkListPageState();
}

class _WorkListPageState extends State<WorkListPage> {
  // simple in-memory caches to avoid refetching titles repeatedly
  static final Map<String, String> _templateCache = {};
  static final Map<String, String> _equipmentCache = {};

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      // If somehow reached without an authenticated user, avoid crash and prompt to login.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        context.go('/login');
      });
      return const Scaffold(body: Center(child: Text('Please sign in')));
    }
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));
    final sevenDays = startOfToday.add(const Duration(days: 7));

    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
        .collection('checklist_instances')
        .where('assignees', arrayContains: uid)
        .where('status', whereIn: ['draft', 'in_progress'])
        .orderBy('dueDate');

    final range = widget.range;
    if (range == 'overdue') {
      q = q.where('dueDate', isLessThan: startOfToday);
    } else if (range == 'today') {
      q = q
        .where('dueDate', isGreaterThanOrEqualTo: startOfToday)
        .where('dueDate', isLessThan: startOfTomorrow);
    } else if (range == 'next7d') {
      q = q
        .where('dueDate', isGreaterThanOrEqualTo: startOfTomorrow)
        .where('dueDate', isLessThan: sevenDays);
    }

    return Scaffold(
      appBar: AppBar(title: Text(_title(range))),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No work'));
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final d = docs[i]; final x = d.data();
              final dueTs = x['dueDate']; DateTime? due;
              if (dueTs is Timestamp) due = dueTs.toDate();

              // Resolve missing labels asynchronously and cache them
              return FutureBuilder<Map<String, String>>(
                future: _resolveLabels(x),
                builder: (context, snap2) {
                  final labels = snap2.data ?? {};
                  final title = labels['templateTitle'] ?? x['templateTitle'] ?? x['templateId'] ?? 'Checklist';
                  final eq = labels['equipmentName'] ?? x['equipmentName'] ?? x['equipmentId'] ?? '';
                  final subtitle = [
                    if (eq.isNotEmpty) eq,
                    if (due != null) 'due: ${_fmt(due)}',
                  ].where((e) => e != null && e.isNotEmpty).join(' • ');

                  return ListTile(
                    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: subtitle.isEmpty ? null : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.go('/t/fill/${d.id}'),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _title(String r) => r == 'overdue' ? 'Overdue'
      : r == 'next7d' ? 'Next 7 days'
      : r == 'all' ? 'All assigned'
      : 'Today';

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')} '
      '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
}

extension on _WorkListPageState {
  Future<Map<String, String>> _resolveLabels(Map<String, dynamic> x) async {
    final out = <String, String>{};

    // Template title
    final tplId = x['templateId'] as String?;
    final tplTitle = x['templateTitle'] as String?;
    if (tplTitle != null && tplTitle.isNotEmpty) {
      out['templateTitle'] = tplTitle;
    } else if (tplId != null && tplId.isNotEmpty) {
  final cached = _WorkListPageState._templateCache[tplId];
      if (cached != null) {
        out['templateTitle'] = cached;
      } else {
        try {
          final doc = await FirebaseFirestore.instance.collection('checklist_templates').doc(tplId).get();
          final t = (doc.data()?['title'] as String?) ?? '';
          if (t.isNotEmpty) _WorkListPageState._templateCache[tplId] = t;
          out['templateTitle'] = t;
        } catch (_) {
          // ignore and fallback to id
        }
      }
    }

    // Equipment name
    final eqId = x['equipmentId'] as String?;
    final eqName = x['equipmentName'] as String?;
    if (eqName != null && eqName.isNotEmpty) {
      out['equipmentName'] = eqName;
    } else if (eqId != null && eqId.isNotEmpty) {
  final cached = _WorkListPageState._equipmentCache[eqId];
      if (cached != null) {
        out['equipmentName'] = cached;
      } else {
        try {
          final doc = await FirebaseFirestore.instance.collection('equipment').doc(eqId).get();
          final e = (doc.data()?['name'] as String?) ?? '';
          if (e.isNotEmpty) _WorkListPageState._equipmentCache[eqId] = e;
          out['equipmentName'] = e;
        } catch (_) {
          // ignore
        }
      }
    }

    return out;
  }
}
