import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/equipment.dart';
import '../repositories/equipment_repo.dart';

class FirestoreEquipmentRepo implements EquipmentRepo {
  final _db = FirebaseFirestore.instance;
  // local-only: save uploaded images to app documents directory for presentation/demo

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('equipment');

  @override
  Stream<List<Equipment>> watchAll() {
    return _col.orderBy('updatedAt', descending: true).snapshots().map(
          (snap) => snap.docs.map(Equipment.fromDoc).toList(),
        );
  }

  @override
  Future<Equipment?> getById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return Equipment.fromDoc(doc);
  }

  @override
  Future<Equipment> create(Equipment e) async {
    final doc = e.id.isEmpty ? _col.doc() : _col.doc(e.id); // ✅
    final data = e.copyWith(
      id: doc.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ).toJson();
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
  // Denormalized search helpers
  data['nameLower'] = (e.name).toLowerCase();
  data['codeLower'] = (e.code).toLowerCase();
    await doc.set(data);
    final saved = await doc.get();
    return Equipment.fromDoc(saved);
  }

  @override
  Future<void> update(Equipment e) async {
    await _col.doc(e.id).update({
      ...e.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
  'nameLower': e.name.toLowerCase(),
  'codeLower': e.code.toLowerCase(),
    });
  }

  @override
  Future<void> delete(String id) => _col.doc(id).delete();

  @override
  Future<String> uploadImage({required String equipmentId, required File file}) async {
  final ext = p.extension(file.path);
  final fname = '${DateTime.now().millisecondsSinceEpoch}$ext';
  final dir = await getApplicationDocumentsDirectory();
  final destDir = Directory(p.join(dir.path, 'equipment', equipmentId));
  if (!await destDir.exists()) await destDir.create(recursive: true);
  final dest = File(p.join(destDir.path, fname));
  await dest.writeAsBytes(await file.readAsBytes());
  // return local file path (file:// URI form)
  return dest.path;
  }
}
