import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminTemplateListPage extends StatefulWidget {
  const AdminTemplateListPage({super.key});
  @override
  State<AdminTemplateListPage> createState() => _AdminTemplateListPageState();
}

class _AdminTemplateListPageState extends State<AdminTemplateListPage> {
  final _search = TextEditingController();
  String _statusFilter = 'all'; // all|draft|published|archived

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Query<Map<String, dynamic>> _baseQuery() {
    var q = FirebaseFirestore.instance.collection('checklist_templates').orderBy('updatedAt', descending: true);
    if (_statusFilter != 'all') {
      q = q.where('status', isEqualTo: _statusFilter);
    }
    return q;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Templates')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16,12,16,4),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search title...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty ? null : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () { setState(() => _search.clear()); },
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16,0,16,8),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: _statusFilter,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(value: 'published', child: Text('Published')),
                    DropdownMenuItem(value: 'archived', child: Text('Archived')),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => context.push('/admin/templates/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('New'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _baseQuery().snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snap.data!.docs;
          final query = _search.text.trim().toLowerCase();
          if (query.isNotEmpty) {
            docs = docs.where((d) => ((d.data()['titleLower'] ?? d.data()['title'] ?? '').toString().toLowerCase()).contains(query)).toList();
          }
          if (docs.isEmpty) return const Center(child: Text('No templates'));
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final d = docs[i]; final data = d.data();
              final status = (data['status'] as String?) ?? 'draft';
              final version = (data['version'] as int?) ?? 1;
              return ListTile(
                title: Text(data['title'] ?? d.id),
                subtitle: Text('v$version • $status'),
                onTap: () => context.push('/admin/templates/edit/${d.id}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    final id = d.id;
                    final ref = FirebaseFirestore.instance.collection('checklist_templates').doc(id);
                    if (v == 'publish') ref.update({'status': 'published', 'updatedAt': FieldValue.serverTimestamp()});
                    if (v == 'archive') ref.update({'status': 'archived',  'updatedAt': FieldValue.serverTimestamp()});
                    if (v == 'draft')   ref.update({'status': 'draft',     'updatedAt': FieldValue.serverTimestamp()});
                    if (v == 'delete') {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Delete template?'),
                          content: Text('This will permanently remove "${data['title'] ?? 'template'}". You cannot undo.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () {
                                // Close the dialog first, then run the delete in a microtask/post-frame
                                Navigator.pop(dialogContext);
                                Future<void>.delayed(Duration.zero, () async {
                                  try {
                                    await ref.delete();
                                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Template deleted')));
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                                    }
                                  }
                                });
                              },
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'publish', child: Text('Publish')),
                    PopupMenuItem(value: 'archive', child: Text('Archive')),
                    PopupMenuItem(value: 'draft',   child: Text('Move to Draft')),
                    PopupMenuDivider(),
                    PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                  ],
                ),

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
}
