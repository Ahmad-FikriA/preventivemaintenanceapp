import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/timestamp_converter.dart';

part 'checklist_instance.freezed.dart';
part 'checklist_instance.g.dart';

enum ChecklistStatus { draft, in_progress, submitted }

@freezed
class ChecklistInstance with _$ChecklistInstance {
  const factory ChecklistInstance({
    required String id,
    required String templateId,
    required String equipmentId,
    @Default(ChecklistStatus.draft) ChecklistStatus status,
    @Default(<String, dynamic>{}) Map<String, dynamic> answers, // fieldKey -> value/URL
    @Default(<String>[]) List<String> images, // extra photos
    @Default(<String>[]) List<String> assignees, // uids
    @TimestampConverter() DateTime? dueDate,
    required String createdBy,
    @TimestampConverter() DateTime? updatedAt,
    @TimestampConverter() DateTime? createdAt,
  }) = _ChecklistInstance;

  factory ChecklistInstance.fromJson(Map<String, dynamic> json) => _$ChecklistInstanceFromJson(json);

  static ChecklistInstance fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    // enum from string fallback
    final raw = data['status'];
    final status = raw is String
        ? ChecklistStatus.values.firstWhere(
            (e) => e.name == raw,
            orElse: () => ChecklistStatus.draft,
          )
        : ChecklistStatus.draft;
    return ChecklistInstance.fromJson({...data, 'id': doc.id, 'status': status.name});
  }
}
