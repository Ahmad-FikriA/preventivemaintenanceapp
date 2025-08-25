import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/sources/firestore_instance_repo.dart';

class AdminWorkCreatePage extends StatefulWidget {
  const AdminWorkCreatePage({super.key});
  @override
  State<AdminWorkCreatePage> createState() => _AdminWorkCreatePageState();
}

class _AdminWorkCreatePageState extends State<AdminWorkCreatePage> {
  final _db = FirebaseFirestore.instance;
  final _repo = FirestoreInstanceRepo();

  String? _templateId;   String? _templateTitle;
  String? _equipmentId;  String? _equipmentName;
  final List<_UserPick> _assignees = [];

  DateTime _due = DateTime.now().add(const Duration(days: 1));
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Work Now')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _pickerTile(
            icon: Icons.article_outlined,
            label: 'Template',
            value: _templateTitle ?? '(choose)',
            onTap: _pickTemplate,
          ),
          const SizedBox(height: 8),
          _pickerTile(
            icon: Icons.precision_manufacturing_outlined,
            label: 'Equipment',
            value: _equipmentName ?? '(choose)',
            onTap: _pickEquipment,
          ),
          const SizedBox(height: 8),
          _assigneesTile(),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.event_outlined),
            title: const Text('Due date & time'),
            subtitle: Text(_due.toString()),
            onTap: _pickDue,
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _saving ? null : _create,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create'),
            ),
          )
        ],
      ),
    );
  }

  Widget _pickerTile({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    return ListTile(
      shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8)),
      leading: Icon(icon),
      title: Text(label), subtitle: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }

  Widget _assigneesTile() {
    return ListTile(
      shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8)),
      leading: const Icon(Icons.group_outlined),
      title: const Text('Assignees'),
      subtitle: _assignees.isEmpty
          ? const Text('(choose technicians)')
          : Wrap(
              spacing: 6, runSpacing: -8,
              children: _assignees.map((u) => Chip(
                label: Text(u.display),
                onDeleted: () => setState(() => _assignees.remove(u)),
              )).toList(),
            ),
      onTap: _pickUsers,
    );
  }

  Future<void> _pickTemplate() async {
    final result = await _pickDoc(
      title: 'Choose Template',
      queryBuilder: (String q) {
        // Only published for work creation, ordered for prefix search
        var ref = _db.collection('checklist_templates')
            .where('status', isEqualTo: 'published')
            .orderBy('titleLower');
        if (q.isNotEmpty) ref = ref.startAt([q]).endAt(['$q\uf8ff']);
        return ref.limit(50);
      },
      labelField: 'title',
    );
    if (result == null) return;
    setState(() { _templateId = result.id; _templateTitle = result.label; });
  }

  Future<void> _pickEquipment() async {
    final result = await _pickDoc(
      title: 'Choose Equipment',
      queryBuilder: (String q) {
        var ref = _db.collection('equipment').orderBy('nameLower');
        if (q.isNotEmpty) ref = ref.startAt([q]).endAt(['$q\uf8ff']);
        return ref.limit(50);
      },
      labelField: 'name',
      subtitleField: 'code', // optional second line
    );
    if (result == null) return;
    setState(() { _equipmentId = result.id; _equipmentName = result.label; });
  }

  Future<void> _pickUsers() async {
    final picked = await _pickUsersMulti(
      title: 'Choose Technicians',
      queryBuilder: (String q) {
        // you can filter role == 'user' if you want (requires composite index with emailLower)
        var ref = _db.collection('users').orderBy('emailLower');
        if (q.isNotEmpty) ref = ref.startAt([q]).endAt(['$q\uf8ff']);
        return ref.limit(50);
      },
      labelBuilder: (data) => (data['name'] as String?)?.isNotEmpty == true
          ? '${data['name']} • ${data['email']}'
          : (data['email'] as String?) ?? 'unknown',
      idFrom: (snap) => snap.id,
    );
    if (picked == null) return;
    setState(() {
      _assignees
        ..clear()
        ..addAll(picked);
    });
  }

  Future<void> _pickDue() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _due,
    );
    if (d == null) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_due));
    setState(() => _due = DateTime(d.year, d.month, d.day, t?.hour ?? 9, t?.minute ?? 0));
  }

  Future<void> _create() async {
    if (_templateId == null || _equipmentId == null || _assignees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose template, equipment, assignees')));
      return;
    }
    setState(() => _saving = true);
    try {
      final inst = await _repo.createFromTemplateAssigned(
        templateId: _templateId!,
        equipmentId: _equipmentId!,
  createdBy: FirebaseAuth.instance.currentUser?.uid ?? 'system',
        assignees: _assignees.map((e) => e.uid).toList(),
        dueDate: _due,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Work created: ${inst.id}')));
      context.pop();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.code}')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------- generic pickers ----------

  Future<_PickResult?> _pickDoc({
    required String title,
    required Query<Map<String, dynamic>> Function(String q) queryBuilder,
    required String labelField,
    String? subtitleField,
  }) async {
    final controller = TextEditingController();
    _PickResult? result;
    await showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (_) => StatefulBuilder(builder: (_, setSt) {
        Stream<QuerySnapshot<Map<String, dynamic>>> stream(String q) => queryBuilder(q).snapshots();
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search…'),
                onChanged: (_) => setSt(() {}),
              ),
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream(controller.text.trim().toLowerCase()),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Padding(
                  padding: EdgeInsets.all(16), child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                return SizedBox(
                  height: 420,
                  child: ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final d = docs[i]; final data = d.data();
                      final label = (data[labelField] as String?) ?? d.id;
                      final sub = subtitleField == null ? null : (data[subtitleField] as String?);
                      return ListTile(
                        title: Text(label),
                        subtitle: sub == null ? null : Text(sub),
                        onTap: () { result = _PickResult(d.id, label); Navigator.pop(context); },
                      );
                    },
                  ),
                );
              },
            ),
          ]),
        );
      }),
    );
    return result;
  }

  Future<List<_UserPick>?> _pickUsersMulti({
    required String title,
    required Query<Map<String, dynamic>> Function(String q) queryBuilder,
    required String Function(Map<String, dynamic> data) labelBuilder,
    required String Function(DocumentSnapshot<Map<String, dynamic>> snap) idFrom,
  }) async {
    final controller = TextEditingController();
    final selected = <String, _UserPick>{};
    List<_UserPick>? result;

    await showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (_) => StatefulBuilder(builder: (_, setSt) {
        Stream<QuerySnapshot<Map<String, dynamic>>> stream(String q) => queryBuilder(q).snapshots();
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12,12,12,0),
              child: Row(children: [
                Expanded(child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search email/name…'),
                  onChanged: (_) => setSt(() {}),
                )),
                TextButton(onPressed: () { result = selected.values.toList(); Navigator.pop(context); }, child: const Text('Done')),
              ]),
            ),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: stream(controller.text.trim().toLowerCase()),
              builder: (_, snap) {
                if (!snap.hasData) {
                  return const Padding(
                  padding: EdgeInsets.all(16), child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                return SizedBox(
                  height: 420,
                  child: ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final d = docs[i]; final data = d.data();
                      final uid = idFrom(d);
                      final label = labelBuilder(data);
                      final picked = selected.containsKey(uid);
                      return CheckboxListTile(
                        value: picked,
                        title: Text(label),
                        onChanged: (v) => setSt(() {
                          if (v == true) { selected[uid] = _UserPick(uid, label); }
                          else { selected.remove(uid); }
                        }),
                      );
                    },
                  ),
                );
              },
            ),
          ]),
        );
      }),
    );
    return result;
  }
}

class _PickResult { _PickResult(this.id, this.label); final String id; final String label; }
class _UserPick  { _UserPick(this.uid, this.display); final String uid; final String display; }
