import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/checklist_instance.dart';
import '../repositories/instance_repo.dart';

class FirestoreInstanceRepo implements InstanceRepo {
  final FirebaseFirestore _db;
  FirestoreInstanceRepo({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('checklist_instances');

  @override
  Stream<List<ChecklistInstance>> watchMyWorkToday(String uid, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    // status in draft|in_progress, assignee contains uid, dueDate within day
    // (Firestore will likely ask for a composite index; click the link it prints)
    return _col
        .where('assignees', arrayContains: uid)
        .where('status', whereIn: ['draft', 'in_progress'])
        .where('dueDate', isGreaterThanOrEqualTo: start, isLessThan: end)
        .orderBy('dueDate')
        .snapshots()
        .map((s) => s.docs.map(ChecklistInstance.fromDoc).toList());
  }

  @override
  Stream<List<ChecklistInstance>> watchDrafts(String uid) {
    return _col
        .where('createdBy', isEqualTo: uid)
        .where('status', isEqualTo: 'draft')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(ChecklistInstance.fromDoc).toList());
  }

  @override
  Future<ChecklistInstance?> getById(String id) async {
    final d = await _col.doc(id).get();
    if (!d.exists) return null;
    return ChecklistInstance.fromDoc(d);
  }

  @override
  Future<ChecklistInstance> createFromTemplate({
    required String templateId,
    required String equipmentId,
    required String createdBy,
    DateTime? dueDate,
  }) async {
    return createFromTemplateAssigned(
      templateId: templateId,
      equipmentId: equipmentId,
      createdBy: createdBy,
      assignees: [createdBy],
      dueDate: dueDate,
    );
  }
  
  @override
  Future<ChecklistInstance> createFromTemplateAssigned({
    required String templateId,
    required String equipmentId,
    required String createdBy,
    required List<String> assignees,
    DateTime? dueDate,
  }) async {
    final doc = _col.doc();
    final now = FieldValue.serverTimestamp();
    await doc.set({
      'templateId': templateId,
      'equipmentId': equipmentId,
      'status': 'draft',
      'answers': <String, dynamic>{},
      'images': <String>[],
      'assignees': assignees,
      'dueDate': dueDate,
      'createdBy': createdBy,
      'createdAt': now,
      'updatedAt': now,
    });
    final saved = await doc.get();
    return ChecklistInstance.fromDoc(saved);
  }
  

  @override
  Future<void> saveAnswers(String instanceId, Map<String, dynamic> patch) async {
    // Build dot-updates for partial answers: answers.fieldKey -> value
    final updates = <String, dynamic>{};
    patch.forEach((k, v) => updates['answers.$k'] = v);
    updates['updatedAt'] = FieldValue.serverTimestamp();

    await _col.doc(instanceId).update(updates);
  }

  @override
  Future<void> attachImage(String instanceId, String fieldKey, String url) async {
    await _col.doc(instanceId).update({
      'answers.$fieldKey': url,                 // for field-bound image
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> delete(String instanceId) async {
    await _col.doc(instanceId).delete();
  }

  @override
  Future<void> submit(String instanceId, {String? templateTitle, String? equipmentName}) async {
    final updates = {
      'status': 'submitted',
      'updatedAt': FieldValue.serverTimestamp(),
      'submittedAt': FieldValue.serverTimestamp(),
    };
    if (templateTitle != null) updates['templateTitle'] = templateTitle;
    if (equipmentName != null) updates['equipmentName'] = equipmentName;
    await _col.doc(instanceId).update(updates);
  }
  
  @override
  Future<void> updateAssignees(String instanceId, List<String> assignees) async {
    await _col.doc(instanceId).update({
      'assignees': assignees,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
