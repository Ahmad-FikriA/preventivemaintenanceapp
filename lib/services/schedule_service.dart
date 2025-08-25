import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/sources/firestore_instance_repo.dart';

class ScheduleService {
  final _db = FirebaseFirestore.instance;
  final _instanceRepo = FirestoreInstanceRepo();

  Future<void> generateNow(String scheduleId) async {
    final doc = await _db.collection('schedules').doc(scheduleId).get();
    if (!doc.exists) throw Exception('Schedule not found');
    final s = doc.data()!;
    if (!(s['active'] as bool? ?? true)) throw Exception('Schedule inactive');

    final templateId = s['templateId'] as String;
    final equipmentId = s['equipmentId'] as String;
    final assignees = ((s['assignees'] as List?) ?? const []).cast<String>();
    final dueHour = (s['dueHour'] as num?)?.toInt() ?? 9;
    final nextRunAtTs = s['nextRunAt'];
    final nextRunAt = (nextRunAtTs is Timestamp) ? nextRunAtTs.toDate() : DateTime.now();

    // create the work
  final uid = FirebaseAuth.instance.currentUser?.uid; // admin who triggers
  if (uid == null) throw Exception('Not authenticated');
    final inst = await _instanceRepo.createFromTemplateAssigned(
      templateId: templateId,
      equipmentId: equipmentId,
      createdBy: uid,
      assignees: assignees.isEmpty ? [uid] : assignees,
      dueDate: DateTime(nextRunAt.year, nextRunAt.month, nextRunAt.day, dueHour),
    );

    // compute next
    final freq = (s['freq'] as String?) ?? 'weekly';
    final next = _computeNext(nextRunAt, freq,
      byDayOfWeek: s['byDayOfWeek'] as int?,
      byDayOfMonth: s['byDayOfMonth'] as int?,
    );

    await doc.reference.update({
      'lastRunAt': nextRunAt,
      'nextRunAt': next,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastInstanceId': inst.id,
    });
  }

  DateTime _computeNext(DateTime from, String freq, {int? byDayOfWeek, int? byDayOfMonth}) {
    final base = DateTime(from.year, from.month, from.day);
    switch (freq) {
      case 'daily':
        return base.add(const Duration(days: 1));
      case 'weekly':
        final target = (byDayOfWeek ?? 1).clamp(1, 7);
        int add = (target - (base.weekday)) % 7;
        if (add <= 0) add += 7;
        return base.add(Duration(days: add));
      case 'monthly':
        final dom = (byDayOfMonth ?? 1).clamp(1, 28);
        final nextMonth = DateTime(base.year, base.month + 1, dom);
        return nextMonth;
      case 'once':
      default:
        return base; // no change; admin can deactivate after generation
    }
  }
}
