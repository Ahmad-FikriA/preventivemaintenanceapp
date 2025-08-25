// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_instance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChecklistInstanceImpl _$$ChecklistInstanceImplFromJson(
        Map<String, dynamic> json) =>
    _$ChecklistInstanceImpl(
      id: json['id'] as String,
      templateId: json['templateId'] as String,
      equipmentId: json['equipmentId'] as String,
      status: $enumDecodeNullable(_$ChecklistStatusEnumMap, json['status']) ??
          ChecklistStatus.draft,
      answers:
          json['answers'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      assignees: (json['assignees'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      dueDate: const TimestampConverter().fromJson(json['dueDate']),
      createdBy: json['createdBy'] as String,
      updatedAt: const TimestampConverter().fromJson(json['updatedAt']),
      createdAt: const TimestampConverter().fromJson(json['createdAt']),
    );

Map<String, dynamic> _$$ChecklistInstanceImplToJson(
        _$ChecklistInstanceImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'templateId': instance.templateId,
      'equipmentId': instance.equipmentId,
      'status': _$ChecklistStatusEnumMap[instance.status]!,
      'answers': instance.answers,
      'images': instance.images,
      'assignees': instance.assignees,
      'dueDate': const TimestampConverter().toJson(instance.dueDate),
      'createdBy': instance.createdBy,
      'updatedAt': const TimestampConverter().toJson(instance.updatedAt),
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
    };

const _$ChecklistStatusEnumMap = {
  ChecklistStatus.draft: 'draft',
  ChecklistStatus.in_progress: 'in_progress',
  ChecklistStatus.submitted: 'submitted',
};
