import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/timestamp_converter.dart';

part 'checklist_template.freezed.dart';
part 'checklist_template.g.dart';

@freezed
class ChecklistTemplate with _$ChecklistTemplate {
  const factory ChecklistTemplate({
    required String id,
    required String title,
    @Default(1) int version,
    @Default(<String>[]) List<String> tags,
    @Default(<String, dynamic>{}) Map<String, dynamic> schema, // sections/fields JSON
    String? createdBy,
    @TimestampConverter() DateTime? updatedAt,
    @TimestampConverter() DateTime? createdAt,
  }) = _ChecklistTemplate;

  factory ChecklistTemplate.fromJson(Map<String, dynamic> json) => _$ChecklistTemplateFromJson(json);

  static ChecklistTemplate fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ChecklistTemplate.fromJson({...data, 'id': doc.id});
  }
}
