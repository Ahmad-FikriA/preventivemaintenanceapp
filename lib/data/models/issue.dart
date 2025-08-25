import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/timestamp_converter.dart';

part 'issue.freezed.dart';
part 'issue.g.dart';

enum IssueSeverity { low, medium, high, critical }
enum IssueStatus { open, closed }

@freezed
class Issue with _$Issue {
  const factory Issue({
    required String id,
    required String equipmentId,
    String? instanceId,
    @Default(IssueSeverity.low) IssueSeverity severity,
    @Default(IssueStatus.open) IssueStatus status,
    required String description,
    @Default(<String>[]) List<String> images,
    required String createdBy,
    @TimestampConverter() DateTime? createdAt,
    @TimestampConverter() DateTime? updatedAt,
  }) = _Issue;

  factory Issue.fromJson(Map<String, dynamic> json) => _$IssueFromJson(json);

  static Issue fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Issue.fromJson({...data, 'id': doc.id});
  }
}
