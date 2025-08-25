import 'package:cloud_firestore/cloud_firestore.dart';

enum ScheduleFreq { daily, weekly, monthly, once }

ScheduleFreq _freqFrom(String? s) {
  switch (s) {
    case 'daily': return ScheduleFreq.daily;
    case 'weekly': return ScheduleFreq.weekly;
    case 'monthly': return ScheduleFreq.monthly;
    case 'once': return ScheduleFreq.once;
    default: return ScheduleFreq.weekly;
  }
}

String freqToString(ScheduleFreq f) {
  switch (f) {
    case ScheduleFreq.daily: return 'daily';
    case ScheduleFreq.weekly: return 'weekly';
    case ScheduleFreq.monthly: return 'monthly';
    case ScheduleFreq.once: return 'once';
  }
}

class Schedule {
  final String id;
  final String equipmentId;
  final String templateId;
  final List<String> assignees;
  final ScheduleFreq freq;
  final int? byDayOfWeek;   // 1..7 (Mon..Sun) for weekly
  final int? byDayOfMonth;  // 1..28 for monthly
  final int dueHour;        // 0..23
  final bool active;
  final DateTime? nextRunAt;
  final DateTime? lastRunAt;
  final String title;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Schedule({
    required this.id,
    required this.equipmentId,
    required this.templateId,
    required this.assignees,
    required this.freq,
    this.byDayOfWeek,
    this.byDayOfMonth,
    required this.dueHour,
    required this.active,
    this.nextRunAt,
    this.lastRunAt,
    required this.title,
    this.createdAt,
    this.updatedAt,
  });

  factory Schedule.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    DateTime? dt(dynamic v) => v is Timestamp ? v.toDate() : v as DateTime?;
    return Schedule(
      id: doc.id,
      equipmentId: data['equipmentId'] as String,
      templateId: data['templateId'] as String,
      assignees: ((data['assignees'] as List?) ?? const []).cast<String>(),
      freq: _freqFrom(data['freq'] as String?),
      byDayOfWeek: (data['byDayOfWeek'] as num?)?.toInt(),
      byDayOfMonth: (data['byDayOfMonth'] as num?)?.toInt(),
      dueHour: (data['dueHour'] as num?)?.toInt() ?? 9,
      active: (data['active'] as bool?) ?? true,
      nextRunAt: dt(data['nextRunAt']),
      lastRunAt: dt(data['lastRunAt']),
      title: (data['title'] as String?) ?? doc.id,
      createdAt: dt(data['createdAt']),
      updatedAt: dt(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestoreMap({
    bool forCreate = false,
  }) {
    return {
      'equipmentId': equipmentId,
      'templateId': templateId,
      'assignees': assignees,
      'freq': freqToString(freq),
      'byDayOfWeek': byDayOfWeek,
      'byDayOfMonth': byDayOfMonth,
      'dueHour': dueHour,
      'active': active,
      'nextRunAt': nextRunAt,   // DateTime is OK; Firestore stores as Timestamp
      'lastRunAt': lastRunAt,
      'title': title,
      'titleLower': title.toLowerCase(),
      if (forCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Schedule copyWith({
    String? id,
    String? equipmentId,
    String? templateId,
    List<String>? assignees,
    ScheduleFreq? freq,
    int? byDayOfWeek,
    int? byDayOfMonth,
    int? dueHour,
    bool? active,
    DateTime? nextRunAt,
    DateTime? lastRunAt,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      equipmentId: equipmentId ?? this.equipmentId,
      templateId: templateId ?? this.templateId,
      assignees: assignees ?? this.assignees,
      freq: freq ?? this.freq,
      byDayOfWeek: byDayOfWeek ?? this.byDayOfWeek,
      byDayOfMonth: byDayOfMonth ?? this.byDayOfMonth,
      dueHour: dueHour ?? this.dueHour,
      active: active ?? this.active,
      nextRunAt: nextRunAt ?? this.nextRunAt,
      lastRunAt: lastRunAt ?? this.lastRunAt,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
