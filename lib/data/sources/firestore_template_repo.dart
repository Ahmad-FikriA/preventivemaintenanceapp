import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/checklist_template.dart';
import '../repositories/template_repo.dart';

class FirestoreTemplateRepo implements TemplateRepo {
  final FirebaseFirestore _db;
  FirestoreTemplateRepo({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('checklist_templates');

  @override
  Stream<List<ChecklistTemplate>> watchAll() {
    return _col.orderBy('updatedAt', descending: true).snapshots().map(
      (snap) => snap.docs.map(ChecklistTemplate.fromDoc).toList(),
    );
  }

  @override
  Stream<List<ChecklistTemplate>> watchPublished() {
    return _col
      .where('status', isEqualTo: 'published')
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(ChecklistTemplate.fromDoc).toList());
  }

  @override
  Future<ChecklistTemplate?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ChecklistTemplate.fromDoc(doc);
  }

  @override
  Future<ChecklistTemplate> create(ChecklistTemplate t) async {
    final doc = _col.doc(t.id.isEmpty ? null : t.id); // let Firestore create ID if empty
    final id = doc.id;
    final data = t.copyWith(
      id: id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ).toJson();

    // prefer server timestamps so indexes/sorting are consistent
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await doc.set(data);
    final saved = await doc.get();
    return ChecklistTemplate.fromDoc(saved);
  }

  @override
  Future<void> update(ChecklistTemplate t) async {
    final map = t.toJson();
    map['updatedAt'] = FieldValue.serverTimestamp();
    await _col.doc(t.id).update(map);
  }
}
