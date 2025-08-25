import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});
  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final _db = FirebaseFirestore.instance;
  // simple in-memory cache for user display names
  static final Map<String, String> _userCache = {};

  // Default to current month
  late DateTimeRange _range = _currentMonth();
  bool _loading = true;
  String? _error;
  _ReportData? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTimeRange _currentMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
    return DateTimeRange(start: start, end: end);
  }

  Future<void> _pickRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _range,
    );
    if (r != null) {
      setState(() => _range = r);
      await _load();
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final start = DateTime(_range.start.year, _range.start.month, _range.start.day);
      // make the end exclusive (add 1 day)
      final endExclusive = DateTime(_range.end.year, _range.end.month, _range.end.day).add(const Duration(days: 1));

      // 1) Instances created in range
      final createdQ = _db.collection('checklist_instances')
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThan: endExclusive);
      final createdSnap = await createdQ.get();
      final created = createdSnap.docs;

      // 2) Submissions completed in range
      final completedQ = _db.collection('checklist_instances')
        .where('status', isEqualTo: 'submitted')
        .where('submittedAt', isGreaterThanOrEqualTo: start)
        .where('submittedAt', isLessThan: endExclusive)
        .orderBy('submittedAt', descending: true);
      final completedSnap = await completedQ.get();
      final completed = completedSnap.docs;

      // 3) Open overdue now (not limited to the range; it's "right now")
      final openOverdueQ = _db.collection('checklist_instances')
        .where('status', whereIn: ['draft','in_progress'])
        .where('dueDate', isLessThan: DateTime.now());
      final openOverdueSnap = await openOverdueQ.get();

      // ---- Compute metrics on client ----
      final completedCount = completed.length;
      final createdCount = created.length;
      final completionRate = createdCount == 0 ? 0.0 : (completedCount / createdCount);

      int overdueClosed = 0;
      Duration totalCycle = Duration.zero;
      final perDay = <String,int>{}; // yyyy-mm-dd -> count
      for (final d in completed) {
        final x = d.data();
        final dueTs = x['dueDate'];
        final subTs = x['submittedAt'];
        final crtTs = x['createdAt'];
        DateTime? due, sub, crt;
        if (dueTs is Timestamp) due = dueTs.toDate();
        if (subTs is Timestamp) sub = subTs.toDate();
        if (crtTs is Timestamp) crt = crtTs.toDate();
        if (sub != null) {
          final key = _dayKey(sub);
          perDay[key] = (perDay[key] ?? 0) + 1;
        }
        if (sub != null && due != null && sub.isAfter(due)) overdueClosed++;
        if (sub != null && crt != null) totalCycle += sub.difference(crt);
      }
      final avgCycleHrs = completedCount == 0 ? 0.0 : totalCycle.inMinutes / 60.0 / completedCount;

      // 4) Issues by equipment within range
      final issuesQ = _db.collection('issues')
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThan: endExclusive);
      final issuesSnap = await issuesQ.get();
      final issuesByEq = <String,int>{};
      for (final d in issuesSnap.docs) {
        final x = d.data();
        final eq = (x['equipmentName'] as String?) ?? (x['equipmentId'] as String?) ?? 'Unknown equipment';
        issuesByEq[eq] = (issuesByEq[eq] ?? 0) + 1;
      }
      final topIssues = issuesByEq.entries.toList()
        ..sort((a,b)=>b.value.compareTo(a.value));
      final topIssues5 = topIssues.take(5).toList();

      setState(() {
        _data = _ReportData(
          createdCount: createdCount,
          completedCount: completedCount,
          completionRate: completionRate,
          closedOverdueCount: overdueClosed,
          openOverdueNow: openOverdueSnap.size,
          avgCycleHours: avgCycleHrs,
          perDayCompletions: perDay,
          topIssueEquipments: topIssues5,
          recentSubmissions: completed.take(12).toList(), // show most recent 12
        );
        _loading = false;
      });
    } on FirebaseException catch (e) {
      setState(() { _error = e.message ?? e.code; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _showSubmission(QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data();
    final title = (data['templateTitle'] as String?) ?? (data['templateId'] as String? ?? 'Checklist');
    final eq = (data['equipmentName'] as String?) ?? (data['equipmentId'] as String? ?? '');
    DateTime? created, submitted;
    final crt = data['createdAt']; if (crt is Timestamp) created = crt.toDate();
    final sub = data['submittedAt']; if (sub is Timestamp) submitted = sub.toDate();

    final answers = data['answers'] as Map<String,dynamic>?;
  final assignees = (data['assignees'] as List<dynamic>?)?.cast<String>() ?? <String>[];
  final assigneeNames = assignees.isEmpty ? <String>[] : await _getUserNames(assignees);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                if (eq.isNotEmpty) Text('Equipment: $eq'),
                if (created != null) Text('Created: ${_fmt(created)}'),
                if (submitted != null) Text('Submitted: ${_fmt(submitted)}'),
                const SizedBox(height: 8),
                Text('Assignees: ${assigneeNames.isEmpty ? (assignees.join(', ') ) : assigneeNames.join(', ')}'),
                const SizedBox(height: 8),
                const Text('Answers:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                if (answers == null || answers.isEmpty)
                  const Text('(no answers)')
                else
                  ...answers.entries.map((e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('${e.key}: ${e.value}'),
                  ))
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
          ],
        );
      },
    );
  }

  // Resolve user display names for a list of uids, using the in-memory cache.
  Future<List<String>> _getUserNames(List<String> uids) async {
    final out = <String>[];
    final missing = <String>[];
    for (final u in uids) {
      final cached = _userCache[u];
      if (cached != null) {
        out.add(cached);
      } else {
        missing.add(u);
      }
    }
    if (missing.isEmpty) return out;

    try {
      // fetch missing user docs in parallel
      final futures = missing.map((u) => _db.collection('users').doc(u).get());
      final docs = await Future.wait(futures);
      for (var i = 0; i < missing.length; i++) {
        final u = missing[i];
        final doc = docs[i];
        final name = (doc.data()?['displayName'] as String?) ?? (doc.data()?['email'] as String?) ?? u;
        _userCache[u] = name;
        out.add(name);
      }
    } catch (_) {
      // on error, fall back to raw uids
      out.addAll(missing);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final title = '${_range.start.year}-${_range.start.month.toString().padLeft(2,'0')}-${_range.start.day.toString().padLeft(2,'0')}'
                  ' → ${_range.end.year}-${_range.end.month.toString().padLeft(2,'0')}-${_range.end.day.toString().padLeft(2,'0')}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          IconButton(icon: const Icon(Icons.date_range), onPressed: _pickRange),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _data == null
                  ? const Center(child: Text('No data'))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      children: [
                        Text('Range: $title', style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 12),

                        // KPI cards
                        Wrap(
                          spacing: 12, runSpacing: 12,
                          children: [
                            _metric('Created', _data!.createdCount.toString(), Icons.playlist_add),
                            _metric('Completed', _data!.completedCount.toString(), Icons.task_alt),
                            _metric('Completion', '${(_data!.completionRate*100).toStringAsFixed(0)}%', Icons.percent),
                            _metric('Open overdue (now)', _data!.openOverdueNow.toString(), Icons.warning_amber_outlined),
                            _metric('Closed overdue', _data!.closedOverdueCount.toString(), Icons.history_toggle_off),
                            _metric('Avg cycle (hrs)', _data!.avgCycleHours.toStringAsFixed(1), Icons.timer_outlined),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Completions by day (simple list)
                        _sectionTitle('Completions by day'),
                        _card(
                          child: _data!.perDayCompletions.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('No completions in range'),
                                )
                              : Column(
                                  children: (() {
                                    final entries = _data!.perDayCompletions.entries.toList()
                                      ..sort((a, b) => a.key.compareTo(b.key));
                                    return entries.map((e) => ListTile(
                                          dense: true,
                                          title: Text(e.key),
                                          trailing: Text('${e.value}'),
                                        )).toList();
                                  })(),
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Top equipment by issues
                        _sectionTitle('Top equipment by issues'),
                        _card(
                          child: _data!.topIssueEquipments.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('No issues in range'),
                                )
                              : Column(
                                  children: _data!.topIssueEquipments.map((e) =>
                                    ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.report_problem_outlined),
                                      title: Text(e.key),
                                      trailing: Text('${e.value}'),
                                    ),
                                  ).toList(),
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Recent submissions (open read-only)
                        _sectionTitle('Recent submissions'),
                        _card(
                          child: _data!.recentSubmissions.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('No submissions in range'),
                                )
                              : Column(
                                  children: _data!.recentSubmissions.map((d) {
                                    final x = d.data();
                                    final title = (x['templateTitle'] as String?) ?? (x['templateId'] as String? ?? 'Checklist');
                                    final eq = (x['equipmentName'] as String?) ?? (x['equipmentId'] as String? ?? '');
                                    final subTs = x['submittedAt'];
                                    DateTime? sub; if (subTs is Timestamp) sub = subTs.toDate();
                                    return ListTile(
                                      leading: const Icon(Icons.description_outlined),
                                      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                                      subtitle: Text([
                                        if (eq.isNotEmpty) eq,
                                        if (sub != null) _fmt(sub),
                                      ].join(' • ')),
                                      onTap: () => _showSubmission(d),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ],
                    ),
    );
  }

  // ---------- small UI helpers ----------
  static Widget _metric(String label, String value, IconData icon) {
    return SizedBox(
      width: 180,
      child: _card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 12),
              // make the text area flexible so the Row can't overflow
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(color: Color(0xFF6B7280)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(value,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _card({required Widget child}) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE5E7EB)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: child,
  );

  static Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
  );

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')} '
      '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
}

// simple holder
class _ReportData {
  final int createdCount;
  final int completedCount;
  final double completionRate;
  final int openOverdueNow;
  final int closedOverdueCount;
  final double avgCycleHours;
  final Map<String,int> perDayCompletions;
  final List<MapEntry<String,int>> topIssueEquipments;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> recentSubmissions;

  _ReportData({
    required this.createdCount,
    required this.completedCount,
    required this.completionRate,
    required this.openOverdueNow,
    required this.closedOverdueCount,
    required this.avgCycleHours,
    required this.perDayCompletions,
    required this.topIssueEquipments,
    required this.recentSubmissions,
  });
}

// (removed unused helper)
