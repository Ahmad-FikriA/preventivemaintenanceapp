import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class AdminEquipmentListPage extends StatefulWidget {
  const AdminEquipmentListPage({super.key});
  @override
  State<AdminEquipmentListPage> createState() => _AdminEquipmentListPageState();
}

class _AdminEquipmentListPageState extends State<AdminEquipmentListPage> {
  final _search = TextEditingController();
  String _locationFilter = 'all';
  List<String> _locations = [];

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Query<Map<String, dynamic>> _query() => FirebaseFirestore.instance
      .collection('equipment')
      .orderBy('updatedAt', descending: true);

  void _buildLocations(List<QueryDocumentSnapshot<Map<String,dynamic>>> docs) {
    final set = <String>{};
    for (final d in docs) {
      final loc = (d.data()['location'] as String?)?.trim();
      if (loc != null && loc.isNotEmpty) set.add(loc);
    }
    final sorted = set.toList()..sort();
    if (sorted.join('|') != _locations.join('|')) {
      _locations = sorted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equipment')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16,12,16,4),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search name/code/location...',
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
            child: Row(children: [
              DropdownButton<String>(
                value: _locationFilter,
                items: [
                  const DropdownMenuItem(value: 'all', child: Text('All locations')),
                  ..._locations.map((l) => DropdownMenuItem(value: l, child: Text(l)))
                ],
                onChanged: (v) => setState(() => _locationFilter = v ?? 'all'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => context.push('/admin/equipment/add'),
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              )
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _query().snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snap.data!.docs;
          _buildLocations(docs);
          final q = _search.text.trim().toLowerCase();
            if (_locationFilter != 'all') {
              docs = docs.where((d) => (d.data()['location'] ?? '') == _locationFilter).toList();
            }
            if (q.isNotEmpty) {
              docs = docs.where((d) {
                final e = d.data();
                final name = (e['name'] ?? '').toString().toLowerCase();
                final code = (e['code'] ?? '').toString().toLowerCase();
                final loc = (e['location'] ?? '').toString().toLowerCase();
                return name.contains(q) || code.contains(q) || loc.contains(q);
              }).toList();
            }
          if (docs.isEmpty) return const Center(child: Text('No equipment'));
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final d = docs[i]; final e = d.data();
                final subtitle = [e['code'], e['location']].where((x) => x != null && (x as String).isNotEmpty).join(' • ');

                // local bundled asset placeholder (add file at assets/images/placeholder.png)
                Widget placeholderThumb = ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/placeholder.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                );

                Widget thumb;
                final img = (e['imageUrl'] as String?)?.trim();
                if (img != null && img.isNotEmpty) {
                  thumb = ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      img,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => placeholderThumb,
                      loadingBuilder: (_, child, progress) => progress == null
                          ? child
                          : Container(width: 56, height: 56, alignment: Alignment.center, child: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                    ),
                  );
                } else {
                  thumb = placeholderThumb;
                }

                return ListTile(
                  leading: SizedBox(width: 56, height: 56, child: thumb),
                  title: Text(e['name'] ?? d.id),
                  subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (v) {
                      if (v == 'edit') {
                        context.push('/admin/equipment/edit/${d.id}');
                      } else if (v == 'delete') {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete equipment?'),
                            content: Text('This will permanently remove "${e['name'] ?? d.id}". Continue?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  try {
                                    await FirebaseFirestore.instance.collection('equipment').doc(d.id).delete();
                                  } catch (err) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Delete failed: $err')),
                                      );
                                    }
                                  }
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
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuDivider(),
                      PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                  onTap: () => context.push('/admin/equipment/edit/${d.id}'),
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
