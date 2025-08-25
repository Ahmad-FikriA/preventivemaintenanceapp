import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/issue.dart';
import '../repositories/issue_repo.dart';

class FirestoreIssueRepo implements IssueRepo {
  final FirebaseFirestore _db;
  FirestoreIssueRepo({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('issues');

  @override
  Future<Issue> create({
    required String equipmentId,
    String? instanceId,
    required String description,
    required IssueSeverity severity,
    required String createdBy,
    List<String> imageUrls = const [],
  }) async {
    final doc = _col.doc();
    final now = FieldValue.serverTimestamp();
    await doc.set({
      'equipmentId': equipmentId,
      'instanceId': instanceId,
      'description': description,
      'severity': severity.name,
      'status': IssueStatus.open.name,
      'images': imageUrls,
      'createdBy': createdBy,
      'createdAt': now,
      'updatedAt': now,
    });
    final saved = await doc.get();
    return Issue.fromDoc(saved);
  }
}
