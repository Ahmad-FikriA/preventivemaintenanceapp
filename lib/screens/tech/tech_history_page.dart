import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/auth_helpers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TechHistoryPage extends StatefulWidget {
  const TechHistoryPage({super.key});
  @override
  State<TechHistoryPage> createState() => _TechHistoryPageState();
}

class _TechHistoryPageState extends State<TechHistoryPage> {
  String _range = '7d'; // 7d | 30d | all
  final _q = TextEditingController();

  // Local caches to resolve denormalized labels when missing
  final Map<String, String> _templateTitles = {};
  final Map<String, String> _equipmentNames = {};
  final Set<String> _fetchingTemplates = {};
  final Set<String> _fetchingEquipments = {};

  DateTime? _from() {
    final now = DateTime.now();
    if (_range == '7d') return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
    if (_range == '30d') return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
    return null; // all
  }

  @override
  void dispose() { _q.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
  final uid = requireUidOrRedirect(context);
  if (uid == null) return const Scaffold(body: Center(child: Text('Please sign in')));
    Query<Map<String, dynamic>> q = FirebaseFirestore.instance
      .collection('checklist_instances')
      .where('assignees', arrayContains: uid)
      .where('status', isEqualTo: 'submitted')
      .orderBy('submittedAt', descending: true); // make sure you write this field on submit

    final from = _from();
    if (from != null) {
      q = q.where('submittedAt', isGreaterThanOrEqualTo: from);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _range,
            onSelected: (v) => setState(() => _range = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: '7d',  child: Text('Last 7 days')),
              PopupMenuItem(value: '30d', child: Text('Last 30 days')),
              PopupMenuItem(value: 'all', child: Text('All')),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _q,
              decoration: const InputDecoration(
                hintText: 'Search template/equipment…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: q.limit(200).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final text = _q.text.toLowerCase().trim();
                final docs = snap.data!.docs.where((d) {
                  if (text.isEmpty) return true;
                  final x = d.data();
                  final a = (x['templateTitle'] ?? x['templateId'] ?? '').toString().toLowerCase();
                  final b = (x['equipmentName'] ?? x['equipmentId'] ?? '').toString().toLowerCase();
                  return a.contains(text) || b.contains(text);
                }).toList();

                if (docs.isEmpty) return const Center(child: Text('No records'));

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final d = docs[i]; final x = d.data();
                                final rawTplId = (x['templateId'] as String?) ?? '';
                                final rawEqId = (x['equipmentId'] as String?) ?? '';
                                final title = (x['templateTitle'] as String?) ?? _templateTitles[rawTplId] ?? (rawTplId.isNotEmpty ? rawTplId : 'Checklist');
                                final equip = (x['equipmentName'] as String?) ?? _equipmentNames[rawEqId] ?? (rawEqId.isNotEmpty ? rawEqId : '');

                                // Kick off fetches if denormalized labels are missing and not already fetching
                                if ((x['templateTitle'] as String?) == null && rawTplId.isNotEmpty && !_fetchingTemplates.contains(rawTplId)) {
                                  _fetchingTemplates.add(rawTplId);
                                  FirebaseFirestore.instance.collection('checklist_templates').doc(rawTplId).get().then((td) {
                                    final t = td.data()?['title'] as String?;
                                    if (t != null) setState(() => _templateTitles[rawTplId] = t);
                                  }).whenComplete(() => _fetchingTemplates.remove(rawTplId));
                                }
                                if ((x['equipmentName'] as String?) == null && rawEqId.isNotEmpty && !_fetchingEquipments.contains(rawEqId)) {
                                  _fetchingEquipments.add(rawEqId);
                                  FirebaseFirestore.instance.collection('equipment').doc(rawEqId).get().then((ed) {
                                    final n = ed.data()?['name'] as String?;
                                    if (n != null) setState(() => _equipmentNames[rawEqId] = n);
                                  }).whenComplete(() => _fetchingEquipments.remove(rawEqId));
                                }
                    final ts = x['submittedAt']; // Timestamp set when user submits
                    final submitted = ts is Timestamp ? ts.toDate() : null;

                    return ListTile(
                      leading: const Icon(Icons.history_toggle_off),
                      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text([
                        if (equip.isNotEmpty) equip,
                        if (submitted != null) _fmt(submitted),
                      ].join(' • '), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/t/fill/${d.id}'), // opens read-only (status=submitted)
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')} '
      '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
}
