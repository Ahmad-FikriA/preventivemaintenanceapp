import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ================== PAGE ==================
class AdminSchedulesPage extends StatefulWidget {
  const AdminSchedulesPage({super.key});
  @override
  State<AdminSchedulesPage> createState() => _AdminSchedulesPageState();
}

class _AdminSchedulesPageState extends State<AdminSchedulesPage> {
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final q = _db.collection('schedules').orderBy('nextRunAt');
    return Scaffold(
      appBar: AppBar(title: const Text('Schedules')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: q.snapshots(),
        builder: (_, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No schedules'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final d = docs[i];
              final s = d.data();
              final title = (s['title'] as String?) ?? d.id;
              final freq = (s['freq'] as String?) ?? 'weekly';
              final active = (s['active'] as bool?) ?? true;
              final nextTs = s['nextRunAt'];
              final next = nextTs is Timestamp ? nextTs.toDate() : null;
              final tpl = (s['templateTitle'] as String?) ?? (s['templateId'] as String? ?? '');
              final eq  = (s['equipmentName'] as String?) ?? (s['equipmentId'] as String? ?? '');

              return ListTile(
                title: Text(title),
                subtitle: Text([
                  'freq: $freq',
                  if (next != null) 'next: ${_fmt(next)}',
                  if (tpl.isNotEmpty) 'tpl: $tpl',
                  if (eq.isNotEmpty)  'eq: $eq',
                ].join(' • ')),
                trailing: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: active ? () => _generateNow(d.id, s) : null,
                      child: const Text('Generate now'),
                    ),
                    Switch(
                      value: active,
                      onChanged: (v) => d.reference.update({
                        'active': v,
                        'updatedAt': FieldValue.serverTimestamp(),
                      }),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const _ScheduleCreateSheet(),
        ),
        icon: const Icon(Icons.add),
        label: const Text('New Schedule'),
      ),
    );
  }

  // ---- generate now (no external service needed) ----
  Future<void> _generateNow(String scheduleId, Map<String, dynamic> s) async {
    try {
      // read fresh snapshot in case UI is stale
      final ref = _db.collection('schedules').doc(scheduleId);
      final snap = await ref.get();
      if (!snap.exists) throw Exception('Schedule not found');
      s = snap.data()!;

      final templateId = s['templateId'] as String?;
      final equipmentId = s['equipmentId'] as String?;
      if (templateId == null || equipmentId == null) {
        throw Exception('Missing template/equipment in schedule');
      }
      final assignees = ((s['assignees'] as List?) ?? const []).cast<String>();
      final dueHour   = (s['dueHour'] as num?)?.toInt() ?? 9;
      final nextRunAtTs = s['nextRunAt'];
      final nextRunAt = nextRunAtTs is Timestamp ? nextRunAtTs.toDate() : DateTime.now();

      // create instance
      final instRef = _db.collection('checklist_instances').doc();
      final dueDate = DateTime(nextRunAt.year, nextRunAt.month, nextRunAt.day, dueHour);
      final now = FieldValue.serverTimestamp();
      await instRef.set({
        'templateId': templateId,
        'templateTitle': s['templateTitle'] ?? templateId,  // nice for UI
        'equipmentId': equipmentId,
        'equipmentName': s['equipmentName'] ?? equipmentId, // nice for UI
        'assignees': assignees.isEmpty
            ? [FirebaseAuth.instance.currentUser?.uid ?? '']
            : assignees,
        'status': 'draft',
        'answers': <String, dynamic>{},
        'images': <String>[],
        'dueDate': dueDate,
  'createdBy': FirebaseAuth.instance.currentUser?.uid ?? '',
        'createdAt': now,
        'updatedAt': now,
        'scheduleId': scheduleId,
      });

      // compute and write next
      final freq = (s['freq'] as String?) ?? 'weekly';
      final byDOW = (s['byDayOfWeek'] as num?)?.toInt();
      final byDOM = (s['byDayOfMonth'] as num?)?.toInt();
      final next = _computeNext(nextRunAt, freq, byDayOfWeek: byDOW, byDayOfMonth: byDOM);

      await ref.update({
        'lastRunAt': nextRunAt,
        'lastInstanceId': instRef.id,
        'nextRunAt': next,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Work generated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  DateTime _computeNext(DateTime from, String freq, {int? byDayOfWeek, int? byDayOfMonth}) {
    final base = DateTime(from.year, from.month, from.day);
    switch (freq) {
      case 'daily':
        return base.add(const Duration(days: 1));
      case 'weekly':
        final target = (byDayOfWeek ?? 1).clamp(1, 7);
        int add = (target - base.weekday) % 7;
        if (add <= 0) add += 7;
        return base.add(Duration(days: add));
      case 'monthly':
        final dom = (byDayOfMonth ?? 1).clamp(1, 28);
        final next = DateTime(base.year, base.month + 1, dom);
        return next;
      case 'once':
      default:
        return base; // unchanged
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:00';
}

// ================== NEW SCHEDULE SHEET (pickers) ==================
class _ScheduleCreateSheet extends StatefulWidget {
  const _ScheduleCreateSheet();
  @override
  State<_ScheduleCreateSheet> createState() => _ScheduleCreateSheetState();
}

class _ScheduleCreateSheetState extends State<_ScheduleCreateSheet> {
  final _db = FirebaseFirestore.instance;

  final _title = TextEditingController();
  String? _equipmentId, _equipmentName;
  String? _templateId,  _templateTitle;
  final List<_UserPick> _assignees = [];

  String _freq = 'weekly';
  int _dow = 1;   // 1..7
  int _dom = 1;   // 1..28
  int _hour = 9;  // 0..23
  bool _saving = false;

  @override
  void dispose() { _title.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('New Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title (e.g., AC-01 Weekly)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            _pickerTile(icon: Icons.precision_manufacturing_outlined, label: 'Equipment',
              value: _equipmentName ?? '(choose)', onTap: _pickEquipment),
            const SizedBox(height: 8),
            _pickerTile(icon: Icons.article_outlined, label: 'Template',
              value: _templateTitle ?? '(choose)', onTap: _pickTemplate),
            const SizedBox(height: 8),
            _assigneesTile(),
            const SizedBox(height: 8),
            Row(children: [
              DropdownButton<String>(
                value: _freq, onChanged:(v)=>setState(()=>_freq=v??'weekly'),
                items: const [
                  DropdownMenuItem(value:'daily',   child: Text('Daily')),
                  DropdownMenuItem(value:'weekly',  child: Text('Weekly')),
                  DropdownMenuItem(value:'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value:'once',    child: Text('Once')),
                ],
              ),
              const SizedBox(width: 12),
              if (_freq=='weekly')
                DropdownButton<int>(
                  value: _dow, onChanged:(v)=>setState(()=>_dow=v??1),
                  items: const [
                    DropdownMenuItem(value:1, child: Text('Mon')),
                    DropdownMenuItem(value:2, child: Text('Tue')),
                    DropdownMenuItem(value:3, child: Text('Wed')),
                    DropdownMenuItem(value:4, child: Text('Thu')),
                    DropdownMenuItem(value:5, child: Text('Fri')),
                    DropdownMenuItem(value:6, child: Text('Sat')),
                    DropdownMenuItem(value:7, child: Text('Sun')),
                  ],
                ),
              if (_freq=='monthly') ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 110,
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Day (1..28)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v)=>_dom = int.tryParse(v)?.clamp(1,28) ?? 1,
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: 110,
                child: TextField(
                  decoration: const InputDecoration(labelText: 'Hour (0..23)'),
                  keyboardType: TextInputType.number,
                  onChanged: (v)=>_hour = int.tryParse(v)?.clamp(0,23) ?? 9,
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                  ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2))
                  : const Text('Save'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _pickerTile({required IconData icon, required String label, required String value, required VoidCallback onTap}) {
    return ListTile(
      shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFFE5E7EB)), borderRadius: BorderRadius.circular(8)),
      leading: Icon(icon), title: Text(label),
      subtitle: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
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
        : Wrap(spacing: 6, runSpacing: -8,
            children: _assignees.map((u)=>Chip(label: Text(u.display), onDeleted: ()=>setState(()=>_assignees.remove(u)))).toList(),
          ),
      onTap: _pickUsers,
    );
  }

  Future<void> _pickEquipment() async {
    final r = await _pickDoc(
      title: 'Choose Equipment',
      queryBuilder: (q) {
        var ref = _db.collection('equipment').orderBy('nameLower');
        if (q.isNotEmpty) ref = ref.startAt([q]).endAt(['$q\uf8ff']);
        return ref.limit(50);
      },
      labelField: 'name',
      subtitleField: 'code',
    );
    if (r == null) return;
    setState(() { _equipmentId = r.id; _equipmentName = r.label; });
  }

  Future<void> _pickTemplate() async {
    final r = await _pickDoc(
      title: 'Choose Template',
      queryBuilder: (q) {
        var ref = _db.collection('checklist_templates')
          .where('status', isEqualTo: 'published')
          .orderBy('titleLower');
        if (q.isNotEmpty) ref = ref.startAt([q]).endAt(['$q\uf8ff']);
        return ref.limit(50);
      },
      labelField: 'title',
    );
    if (r == null) return;
    setState(() { _templateId = r.id; _templateTitle = r.label; });
  }

  Future<void> _pickUsers() async {
    final picked = await _pickUsersMulti(
      title: 'Choose Technicians',
      queryBuilder: (q) {
        // If you want only role==user, add a where('role','==','user') and accept the composite index prompt.
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
    setState(() { _assignees..clear()..addAll(picked); });
  }

  Future<void> _save() async {
    if (_equipmentId == null || _templateId == null || _assignees.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choose equipment, template, assignees')));
      return;
    }
    setState(()=>_saving = true);
    try {
      final today = DateTime.now();
      DateTime next = DateTime(today.year, today.month, today.day);
      if (_freq=='weekly') {
        int add = (_dow - next.weekday) % 7; if (add <= 0) add += 7;
        next = next.add(Duration(days: add));
      } else if (_freq=='monthly') {
        final dom = _dom.clamp(1, 28);
        next = DateTime(today.year, today.month, dom);
        if (!next.isAfter(today)) next = DateTime(today.year, today.month + 1, dom);
      } else if (_freq=='daily') {
        next = next.add(const Duration(days: 1));
      }

      final doc = _db.collection('schedules').doc();
      final title = _title.text.trim().isEmpty
          ? '${_equipmentName ?? _equipmentId} $_freq'
          : _title.text.trim();
      await doc.set({
        'title': title,
        'titleLower': title.toLowerCase(),
        'equipmentId': _equipmentId,
        'equipmentName': _equipmentName,
        'templateId': _templateId,
        'templateTitle': _templateTitle,
        'assignees': _assignees.map((e)=>e.uid).toList(),
        'freq': _freq,
        'byDayOfWeek': _freq=='weekly'? _dow : null,
        'byDayOfMonth': _freq=='monthly'? _dom : null,
        'dueHour': _hour,
        'active': true,
        'nextRunAt': DateTime(next.year, next.month, next.day, _hour),
        'lastRunAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule created')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(()=>_saving=false);
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
                  return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
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
                  return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
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
